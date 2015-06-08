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
	) as ends_at,
	(p.price/product.weight)::NUMERIC(6,2) as price_per_kg
FROM product_price p
JOIN product USING (product_id);

--
-- Function returning detailed listing of products within order
--

CREATE OR REPLACE FUNCTION order_products(id INTEGER) RETURNS 
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
-- Order information
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
	SELECT * FROM order_products(id)
	UNION
	SELECT
		NULL,
		st.name,
		1,
		st.cost,
		st.cost,
		NULL,
		NULL,
		NULL
	FROM "order"
	JOIN shipment_type st USING (shipment_type_id)
	WHERE order_id = id
	ORDER BY 1;
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
	
	IF c.claim_limit <= (SELECT COUNT(*) FROM order_coupon WHERE coupon_id=c.coupon_id) THEN
		RAISE EXCEPTION 'Coupon "%" has exceeded claim limit.', c_id;
	END IF;
	
	IF NOT EXISTS (
		SELECT * FROM "order"
		WHERE
			"order".order_id=o_id AND
			created_at BETWEEN c.VALID_FROM AND
			c.VALID_TO
		) THEN RAISE EXCEPTION 'Coupon "%" has expired.', c_id;
	END IF;
	
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
-- View that shows detailed state of each employee
--

CREATE OR REPLACE VIEW employee_detail AS
SELECT 
	*,
	(
		SELECT MIN(since) FROM employee_position WHERE employee_id=e.employee_id AND since > ep.since
	) as until
FROM employee e
JOIN employee_position ep USING (employee_id)
JOIN position USING (position_id);

--
-- Function that finds the best store and seller to be assigned to the given order
--

CREATE OR REPLACE FUNCTION find_best_salesman(o_id INTEGER) RETURNS INTEGER AS
$$
DECLARE
	ord RECORD;
	emp INTEGER;
BEGIN
	SELECT * FROM "order" WHERE order_id=o_id INTO ord;
	
	SELECT employee_id FROM order_product
	JOIN product_price USING (product_id)
	JOIN product USING (product_id)
	JOIN product_stock USING (product_id)
	JOIN employee_detail ed USING (branch_id)
	LEFT JOIN "order" ON ("order".salesman_id=employee_id)
	WHERE
		order_product.order_id=o_id AND
		ed.salesman=TRUE AND
		ord.created_at BETWEEN ed.since AND coalesce(ed.until, NOW())
	GROUP BY employee_id
	ORDER BY
		sum(weight * least(order_product.quantity, product_stock.quantity)) DESC,
		count("order")
	FETCH FIRST ROW ONLY INTO emp;
	
	IF emp IS NULL THEN
		RAISE EXCEPTION 'Could not find a suitable salesman.';
	END IF;
	
	RETURN emp;
END
$$
LANGUAGE plpgsql;

--
-- Function that checks for a salesman presence in order
--

CREATE OR REPLACE FUNCTION order_not_null_salesman() RETURNS TRIGGER AS
$$
BEGIN
	IF NEW.salesman_id IS NULL THEN
		SELECT find_best_salesman(NEW.order_id) INTO NEW.salesman_id;
		UPDATE "order" SET salesman_id=NEW.salesman_id WHERE order_id=NEW.order_id;
		RAISE NOTICE 'Order #% has been assigned automatically salesman #%', NEW.order_id, NEW.salesman_id;
	ELSIF NOT EXISTS (SELECT * FROM employee_detail ed WHERE salesman=TRUE AND NEW.created_at BETWEEN ed.since AND coalesce(ed.until, NOW())) THEN
		RAISE EXCEPTION 'Order #% has been assigned an employee who is not a salesman.', NEW.order_id;
	END IF;
	
	RETURN NEW;
END
$$
LANGUAGE plpgsql;

--
-- Function that checks whether given order has enough > 0 products
--

CREATE OR REPLACE FUNCTION order_nonempty_cart() RETURNS TRIGGER AS
$$
BEGIN
	IF (TG_OP='UPDATE' OR TG_OP='DELETE') AND OLD.order_id IS NOT NULL THEN
		IF NOT EXISTS (SELECT * FROM order_product WHERE order_id=OLD.order_id) THEN
			RAISE EXCEPTION 'Order #% is missing products.', OLD.order_id;
		END IF;
	END IF;
	IF TG_OP='INSERT' AND NEW.order_id IS NOT NULL THEN
		IF NOT EXISTS (SELECT * FROM order_product WHERE order_id=NEW.order_id) THEN
			RAISE EXCEPTION 'Order #% is missing products.', NEW.order_id;
		END IF;
	END IF;
	RETURN NEW;
END
$$
LANGUAGE plpgsql;

--
-- Function that checks if order shipment/billing address belong to the client
--

CREATE OR REPLACE FUNCTION order_address_check() RETURNS TRIGGER AS
$$
BEGIN
	IF NEW.shipment_address_id IS NOT NULL THEN
		IF NOT EXISTS (
			SELECT * FROM client_address
			WHERE client_address_id=NEW.shipment_address_id AND
			client_id=NEW.client_id
			) THEN RAISE EXCEPTION 'Order #% shipment address does not belong to the client.', NEW.order_id;
		END IF;
	END IF;

	IF NEW.billing_address_id IS NOT NULL THEN
		IF NOT EXISTS (
			SELECT * FROM client_address
			WHERE client_address_id=NEW.billing_address_id AND
			client_id=NEW.client_id
			) THEN RAISE EXCEPTION 'Order #% billing address does not belong to the client.', NEW.order_id;
		END IF;
	END IF;
	
	RETURN NEW;
END
$$
LANGUAGE plpgsql;

--
-- Function that checks if shipment method is suitable for the order
-- and whether order contains required information (shipping address)
--

CREATE OR REPLACE FUNCTION order_shipment_check() RETURNS TRIGGER AS
$$
DECLARE
	total_weight NUMERIC(6,2);
	total_price  NUMERIC(6,2);
BEGIN
	IF NEW.shipment_type_id IS NULL THEN
		IF NEW.shipment_address_id IS NOT NULL THEN
			RAISE EXCEPTION 'Order #%: shipment address set but order is not meant to be shipped.', NEW.order_id;
		END IF;

		RETURN NEW;
	END IF;

	IF NEW.shipment_address_id IS NULL THEN
		RAISE EXCEPTION 'Order #%: shipment address is required', NEW.order_id;
	END IF;

	SELECT SUM(o.total_weight) FROM order_products(NEW.order_id) o INTO total_weight;
	SELECT SUM(o.total_price) FROM order_products(NEW.order_id) o INTO total_price;

	IF NOT EXISTS (
		SELECT * FROM shipment_type
		WHERE
			shipment_type_id=NEW.shipment_type_id AND
			(min_order_value IS NULL OR min_order_value <= total_price) AND
			(max_weight IS NULL OR max_weight >= total_weight)
		) THEN RAISE EXCEPTION 'Shipment type #% is unsuitable for order #%', NEW.shipment_type_id, NEW.order_id;
	END IF;
	RETURN NEW;
END
$$
LANGUAGE plpgsql;

--
-- Function that updates product stock when order changes
--

CREATE OR REPLACE FUNCTION order_quantity_check() RETURNS TRIGGER AS
$$
DECLARE
	b_id            INTEGER;
	available_units INTEGER;
	required_units  INTEGER;
	stock           RECORD;
BEGIN
	-- return items to default store
	IF TG_OP='DELETE' OR TG_OP='UPDATE' THEN
		SELECT branch_id FROM "order"
			JOIN employee_detail ed ON (employee_id=salesman_id)
			JOIN "order" ord USING (order_id)
			WHERE
				order_id=OLD.order_id AND
				ord.created_at BETWEEN ed.since AND coalesce(ed.until, NOW())
			INTO b_id;
		
		UPDATE product_stock SET quantity=quantity+OLD.quantity WHERE product_id=OLD.product_id AND branch_id=b_id;
	END IF;
	
	-- try to get items from stores
	IF TG_OP='INSERT' OR TG_OP='UPDATE' THEN
		SELECT branch_id FROM "order"
			JOIN employee_detail ed ON (employee_id=salesman_id)
			JOIN "order" ord USING (order_id)
			WHERE
				order_id=NEW.order_id AND
				ord.created_at BETWEEN ed.since AND coalesce(ed.until, NOW())
			INTO b_id;

		-- count if it is possible to meet the quantity requirement
		SELECT SUM(quantity) FROM product_stock WHERE product_id=NEW.product_id INTO available_units;
		IF available_units < NEW.quantity THEN
			RAISE EXCEPTION 'Missing % units of product #% (%) in stores', NEW.quantity-available_units, NEW.product_id, (SELECT name FROM product WHERE product_id=NEW.product_id);
		END IF;
		
		required_units := NEW.quantity;
		FOR stock IN SELECT * FROM product_stock WHERE product_id=NEW.product_id ORDER BY NULLIF(branch_id, b_id) NULLS FIRST, quantity DESC
		LOOP
			UPDATE product_stock SET quantity=GREATEST(0, quantity-required_units)
			WHERE
				branch_id=stock.branch_id AND
				product_id=NEW.product_id;

			required_units := required_units - LEAST(stock.quantity, required_units);
			IF required_units = 0 THEN
				EXIT;
			END IF;
		END LOOP;
	END IF;
	
	RETURN NEW;
END
$$
LANGUAGE plpgsql;

--
-- Function that checks if a given product has price
--

CREATE OR REPLACE FUNCTION product_has_price() RETURNS TRIGGER AS
$$
BEGIN
	IF TG_OP='INSERT' THEN
		IF NOT EXISTS (SELECT * FROM product_price WHERE product_id=NEW.product_id) THEN
			RAISE EXCEPTION 'Product #% (%) has no price.', NEW.product_id, (SELECT name FROM product WHERE product_id=NEW.product_id);
		END IF;
		RETURN NEW;
	ELSIF TG_OP='DELETE' OR TG_OP='UPDATE' THEN
		IF EXISTS (SELECT * FROM product WHERE product_id=OLD.product_id) THEN
			IF NOT EXISTS (SELECT * FROM product_price WHERE product_id=OLD.product_id) THEN
				RAISE EXCEPTION 'Product #% (%) has no price.', OLD.product_id, (SELECT name FROM product WHERE product_id=OLD.product_id);
			END IF;
		END IF;
		RETURN OLD;
	END IF;
END
$$
LANGUAGE plpgsql;

--
-- Function that checks if inserting/altering product price influences existing data (i.e. orders)
--

CREATE OR REPLACE FUNCTION price_sequence_point() RETURNS TRIGGER AS
$$
DECLARE
	next RECORD;
	current RECORD;
BEGIN
	IF TG_OP='INSERT' OR TG_OP='UPDATE' THEN
		current := NEW;
	ELSIF TG_OP='DELETE' THEN
		current := OLD;
	END IF;
	
	SELECT * FROM product_price WHERE product_id=current.product_id AND created_at > current.created_at AND created_at <= ALL (SELECT created_at FROM product_price WHERE product_id=current.product_id AND created_at > current.created_at) INTO next;

	IF EXISTS (
		SELECT * FROM "order"
		JOIN order_product USING (order_id)
		WHERE
			product_id  = current.product_id AND
			created_at >= current.created_at AND
			(next.created_at IS NULL OR next.created_at > created_at)
		) THEN RAISE EXCEPTION 'Could not change price for product #% due to possible data disintegration', current.product_id;
	END IF;
	
	RETURN NEW;
END
$$
LANGUAGE plpgsql;
