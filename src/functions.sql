--
-- functions.sql
--

--
-- Trigger for detecting cycle presence
--
CREATE OR REPLACE FUNCTION category_find_cycles() RETURNS TRIGGER AS
$$
DECLARE
	cr INTEGER; -- variable to traverse category
BEGIN
	cr = NEW.PARENT_ID;
	WHILE (cr IS NOT NULL) LOOP
		IF (cr = NEW.CATEGORY_ID) THEN
			RAISE EXCEPTION 'Cycle in categories detected. Violated by %.', NEW.NAME;
		ELSE
			SELECT PARENT_ID INTO cr FROM CATEGORY WHERE CATEGORY_ID = cr;
		END IF;
	END LOOP;
	-- Reached the end - OK
	RETURN NEW;
END
$$
LANGUAGE plpgsql;

--
-- Function returning all ancestor categories
--
CREATE OR REPLACE FUNCTION category_ancestors(id INTEGER) RETURNS 
TABLE 
(
	ID   INTEGER, 
	NAME VARCHAR(255)
)
AS
$$
	WITH RECURSIVE cat(ID) AS
	(
		SELECT PARENT_ID FROM CATEGORY WHERE CATEGORY_ID = id
		UNION ALL
		SELECT c.PARENT_ID FROM cat JOIN CATEGORY c ON cat.ID = c.CATEGORY_ID
	)

	SELECT cat.*, c.NAME FROM cat JOIN CATEGORY c on cat.ID = c.CATEGORY_ID;
$$
LANGUAGE sql;

--
-- Function returning all descendants categories
--
CREATE OR REPLACE FUNCTION category_descendants(id INTEGER) RETURNS 
TABLE 
(
	ID    INTEGER, 
	NAME  VARCHAR(255)
)
AS
$$
	WITH RECURSIVE cat(ID) AS
	(
		SELECT CATEGORY_ID FROM CATEGORY WHERE PARENT_ID = id
		UNION ALL
		SELECT c.CATEGORY_ID FROM cat JOIN CATEGORY c ON cat.ID = c.PARENT_ID
	)
	
	SELECT cat.*, c.NAME FROM cat JOIN CATEGORY c ON cat.ID = c.CATEGORY_ID;
$$
LANGUAGE sql;

--
-- Function returning all leaf categories
--
CREATE OR REPLACE FUNCTION category_leaves() RETURNS 
TABLE
(
	ID   INTEGER,
	NAME VARCHAR(255)
)
AS
$$
	WITH cat(ID, ct) AS
	(
		SELECT c.CATEGORY_ID, COUNT(ct.CATEGORY_ID) FROM category c LEFT JOIN category ct ON c.CATEGORY_ID = ct.PARENT_ID GROUP BY c.CATEGORY_ID
	)

	SELECT c.CATEGORY_ID, c.NAME FROM CATEGORY c JOIN cat ON c.CATEGORY_ID = cat.ID WHERE cat.ct = 0;
$$
LANGUAGE sql;

--
-- Aggregate multiplication function
-- (makes calculating the total discount easier)
--

CREATE OR REPLACE FUNCTION numeric_multiply(a NUMERIC, b NUMERIC) RETURNS NUMERIC AS
$$
BEGIN
	RETURN a * b;
END
$$
LANGUAGE plpgsql;

CREATE AGGREGATE multiply(NUMERIC)
(
	sfunc = numeric_multiply,
	stype = numeric,
	initcond = 1
);

CREATE OR REPLACE VIEW product_price_detail AS
SELECT
	p.*,
	(
		SELECT MIN(created_at) FROM product_price WHERE product_id=p.product_id AND created_at > p.created_at
	) as ends_at
FROM product_price p;

--
-- Function returning information about order.
-- Fetching the discounts is ugly but works (under assumption that validity
-- of said discounts is guaranteed by order-coupon relation)
--

CREATE OR REPLACE FUNCTION order_information(id INTEGER) RETURNS 
TABLE
(
	no             BIGINT,
	name           VARCHAR(128),
	quantity       INTEGER,
	unit_price     NUMERIC(6,2),
	total_price    NUMERIC(6,2),
	unit_weight    NUMERIC(6,2),
	total_weight   NUMERIC(6,2),
	DISCOUNT       NUMERIC(3,2)
)
AS
$$
	SELECT
		row_number() over ()                   as no,
		p.name                                 as name,
		op.quantity                            as quantity,
		ppd.price                              as unit_price,
		ppd.price * op.quantity                as total_price,
		p.weight                               as unit_weight,
		p.weight * op.quantity                 as total_weight,
		1 - multiply(1-coalesce(c.discount,0)) as discount
	FROM "order" o
	JOIN order_product op USING (order_id)
	JOIN product p USING (product_id)
	JOIN product_price_detail ppd USING (product_id)
	LEFT JOIN order_coupon oc ON (oc.order_id=o.order_id)
	LEFT JOIN coupon c ON (c.coupon_id=oc.coupon_id)
	WHERE
		o.order_id=id AND
		ppd.created_at <= o.created_at AND
		(o.created_at < ppd.ends_at OR ppd.ends_at is null) AND
		(c.category_id IS NULL OR p.category_id IN (
			SELECT id FROM category_descendants(c.category_id))) AND
		(c.product_id IS NULL OR p.product_id = c.product_id)
	GROUP BY name, quantity, unit_price, total_price, unit_weight,
		total_weight
	ORDER BY name
$$
LANGUAGE sql;

--
-- Coupon validity
--
CREATE OR REPLACE FUNCTION order_coupon_validate(o_id INTEGER, c_id VARCHAR(128)) RETURNS VOID AS
$$
DECLARE
	c RECORD;
BEGIN
	SELECT * FROM coupon WHERE coupon_id=c_id INTO c;
	
	IF c.client_id IS NOT NULL THEN
		IF NOT EXISTS (
			SELECT * FROM "order" 
			WHERE "order".order_id=o_id AND client_id=c.client_id
			) THEN RAISE EXCEPTION 'Coupon "%" does not belong to this client.', c_id;
		END IF;
	END IF;
	
	IF c.category_id IS NOT NULL THEN
		IF NOT EXISTS (
			SELECT * FROM order_product 
			JOIN product USING (product_id)
			WHERE
				order_product.order_id=o_id AND
				product.category_id IN
				(
					SELECT id FROM category_descendants(c.category_id)
				)
			) THEN RAISE EXCEPTION 'Coupon "%" cannot be applied to this order.', c_id;
		END IF;
	END IF;
	
	IF c.product_id IS NOT NULL THEN
		IF NOT EXISTS (
			SELECT * FROM order_product
			WHERE
				order_product.order_id=o_id AND
				product_id=c.product_id
			) THEN RAISE EXCEPTION 'Coupon "%" cannot be applied to this order.', c_id;
		END IF;
	END IF;
	
	IF NOT EXISTS (
		SELECT * FROM "order"
		WHERE
			"order".order_id=o_id AND
			created_at BETWEEN c.VALID_FROM AND
			c.VALID_TO
		) THEN RAISE EXCEPTION 'Coupon "%" has expired.', c_id;
	END IF;
END
$$
language plpgsql;

--
-- Trigger validating inserts in order_coupon relation
--
CREATE OR REPLACE FUNCTION order_coupon_validate_trigger() RETURNS TRIGGER AS
$$
BEGIN
	PERFORM order_coupon_validate(NEW.order_id, NEW.coupon_id);
	RETURN NEW;
END
$$
language plpgsql;

--
-- Clean unused coupon entries when removing products from order
--
CREATE OR REPLACE FUNCTION order_coupon_after_order_product_delete() RETURNS TRIGGER AS
$$
DECLARE
	coupon RECORD;
BEGIN
	FOR coupon IN (SELECT * FROM order_coupon WHERE order_id=OLD.order_id) LOOP
	BEGIN
		PERFORM order_coupon_validate(OLD.order_id, coupon.coupon_id);
	EXCEPTION WHEN OTHERS THEN
		DELETE FROM order_coupon WHERE coupon_id=coupon.coupon_id AND order_id=OLD.order_id;
	END;
	END LOOP;
	RETURN OLD;
END
$$
language plpgsql;

--
-- View that shows current state of each employee
--
CREATE OR REPLACE VIEW employee_detail AS
SELECT * FROM employee
JOIN employee_position USING (employee_id)
JOIN position USING (position_id)
WHERE since >= ALL (SELECT since FROM employee_position X WHERE X.employee_id=employee_id);
--
-- Function that finds the best store and seller to be assigned to the given order
--
CREATE OR REPLACE FUNCTION find_best_seller(order_id INTEGER) RETURNS INTEGER AS
$$
	SELECT employee_id FROM order_product
	JOIN product_price USING (product_id)
	JOIN product USING (product_id)
	JOIN product_stock USING (product_id)
	JOIN employee_detail USING (branch_id)
	-- TODO: join employee's order and count them into result
	WHERE order_id=1
	GROUP BY employee_id
	ORDER BY sum(weight * least(order_product.quantity, product_stock.quantity))
	LIMIT 1;
$$
language sql;
