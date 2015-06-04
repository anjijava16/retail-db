--
-- functions.sql
--

--------------------------------------------------
--	Trigger for detecting cycle presence		--

CREATE OR REPLACE FUNCTION category_find_cycles() RETURNS trigger AS
$$
DECLARE
	cr	INTEGER;	--	variable to traverse category
BEGIN
	cr = NEW.PARENT_ID;
	WHILE (cr IS NOT NULL) LOOP
		IF (cr = NEW.CATEGORY_ID) THEN
			RAISE EXCEPTION 'Cycle in categories detected. Violated by %.', NEW.NAME;
		ELSE
			SELECT PARENT_ID INTO cr FROM CATEGORY WHERE CATEGORY_ID = cr;
		END IF;
	END LOOP;
	--	Reached the end - OK
	RETURN NEW;
END
$$	LANGUAGE plpgsql;

--------------------------------------------------
--	Function returning all ancestor categories	--

CREATE OR REPLACE FUNCTION anc_category(id INTEGER) RETURNS 
TABLE 
(
	ID 		INTEGER, 
	NAME 	VARCHAR(255)
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

$$	LANGUAGE sql;
--------------------------------------------------
--Function returning all descendants categories	--

CREATE OR REPLACE FUNCTION desc_category(id INTEGER) RETURNS 
TABLE 
(
	ID 		INTEGER, 
	NAME 	VARCHAR(255)
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

$$	LANGUAGE sql;

--------------------------------------------------
--	Function returning all leaf categories		--

CREATE OR REPLACE FUNCTION leaf_category() RETURNS 
TABLE
(
	ID		INTEGER,
	NAME 	VARCHAR(255)
)
AS
$$

WITH cat(ID, ct) AS
(
	SELECT c.CATEGORY_ID, COUNT(ct.CATEGORY_ID) FROM category c LEFT JOIN category ct ON c.CATEGORY_ID = ct.PARENT_ID GROUP BY c.CATEGORY_ID
)

SELECT c.CATEGORY_ID, c.NAME FROM CATEGORY c JOIN cat ON c.CATEGORY_ID = cat.ID WHERE cat.ct = 0;

$$	LANGUAGE sql;


--------------------------------------------------
--	Aggregate multiplication function (makes
--	calculating the total discount easier)		--

CREATE OR REPLACE FUNCTION numeric_multiply(a NUMERIC, b NUMERIC) RETURNS NUMERIC AS
$$
	BEGIN

	RETURN a * b;

	END
$$	LANGUAGE plpgsql;

CREATE AGGREGATE multiply(NUMERIC)
(
	sfunc = numeric_multiply,
	stype = numeric,
	initcond = 1
);

--------------------------------------------------
--	Function fetching current price for product	--

CREATE OR REPLACE FUNCTION current_price(id INTEGER) RETURNS NUMERIC(6, 2) AS

$$

	SELECT price FROM product_price 
	WHERE PRODUCT_ID = id AND CREATED_AT = (SELECT MAX(CREATED_AT) FROM product_price WHERE PRODUCT_ID = id);

$$	LANGUAGE sql;

--------------------------------------------------
--	Function returning information about order.
--	Fetching the discounts is ugly but works
--	(under assumption that validity of said 
--	discounts is guaranteed by order-coupon
--	relation).									--

CREATE OR REPLACE FUNCTION order_information(id INTEGER) RETURNS 
TABLE
(
	NO				bigint,
	NAME			VARCHAR(128),
	QUANTITY		INTEGER,
	"UNIT PRICE" 	NUMERIC(6, 2),
	"TOTAL PRICE" 	NUMERIC(6,2),
	DISCOUNT 		NUMERIC(3, 2)
)
AS

$$
	WITH 
	tp(total, product_id) AS
	(
		SELECT multiply(1 - DISCOUNT), PRODUCT_ID 
		FROM 
		(
		SELECT * FROM ORDER_COUPON oc JOIN COUPON co USING (COUPON_ID)
		WHERE oc.ORDER_ID = id AND PRODUCT_ID IS NOT NULL
		) x
		GROUP BY PRODUCT_ID
	),
	tk(total, category_id) AS
	(
		SELECT multiply(1 - DISCOUNT), CATEGORY_ID FROM
		(
		SELECT * FROM ORDER_COUPON oc JOIN COUPON co USING (COUPON_ID) 
		WHERE oc.ORDER_ID = id AND CATEGORY_ID IS NOT NULL
		) x 
		GROUP BY CATEGORY_ID
	),
	tc(total) AS
	(
		SELECT multiply(1 - DISCOUNT) FROM ORDER_COUPON OC JOIN COUPON co USING (COUPON_ID)
		WHERE oc.ORDER_ID = id AND co.PRODUCT_ID IS NULL AND CATEGORY_ID IS NULL
	)
	

	SELECT row_number() over (), p.NAME, op.QUANTITY, current_price(p.PRODUCT_ID), 
	current_price(p.PRODUCT_ID) * op.QUANTITY, 1 - COALESCE(tp.total, 1) * COALESCE(tk.total, 1) * COALESCE(tc.total, 1)
	FROM ORDER_PRODUCT op JOIN PRODUCT p USING (PRODUCT_ID) 
	LEFT OUTER JOIN tp ON p.PRODUCT_ID = tp.PRODUCT_ID 
	LEFT OUTER JOIN tk ON p.CATEGORY_ID = tk.CATEGORY_ID 
	CROSS JOIN tc WHERE ORDER_ID = id;

$$	LANGUAGE sql;


--------------------------------------------------
