--
-- Database schema, basic constraints and relations
--

CREATE TABLE BRANCH (
	BRANCH_ID SERIAL PRIMARY KEY,
	ADDRESS VARCHAR(512) NOT NULL,
	CITY VARCHAR(64) NOT NULL
);

CREATE TABLE BRANCH_PHONE (
	BRANCH_ID INTEGER REFERENCES BRANCH ON DELETE CASCADE,
	PHONE VARCHAR(32) PRIMARY KEY,
	FAX BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE EMPLOYEE (
	EMPLOYEE_ID SERIAL PRIMARY KEY,
	FIRST_NAME VARCHAR(128) NOT NULL,
	LAST_NAME VARCHAR(128) NOT NULL
);

CREATE TABLE POSITION (
	POSITION_ID SERIAL PRIMARY KEY,
	PROMOTION_ID INTEGER REFERENCES POSITION(POSITION_ID) ON DELETE SET NULL,
	NAME VARCHAR(64) NOT NULL,
	BASE_WAGE NUMERIC(6,2) NOT NULL,
	SALESMAN BOOLEAN NOT NULL DEFAULT FALSE,

	-- Minimum wage check
	CHECK(BASE_WAGE > 6.06)
);

CREATE TABLE EMPLOYEE_POSITION (
	EMPLOYEE_ID INTEGER NOT NULL REFERENCES EMPLOYEE ON DELETE CASCADE,
	POSITION_ID INTEGER NOT NULL REFERENCES POSITION,
	SUPERIOR_ID INTEGER REFERENCES EMPLOYEE(EMPLOYEE_ID),
	BRANCH_ID INTEGER NOT NULL REFERENCES BRANCH,
	EXTRA_WAGE NUMERIC(6,2) NOT NULL DEFAULT 0,
	HOURS_PER_WEEK INTEGER NOT NULL DEFAULT 40,
	SINCE DATE NOT NULL DEFAULT NOW()
);

CREATE TABLE CLIENT (
	CLIENT_ID SERIAL PRIMARY KEY,
	DEFAULT_SHIPMENT_ADDRESS_ID INTEGER NOT NULL,
	DEFAULT_BILLING_ADDRESS_ID INTEGER NOT NULL
);

CREATE TABLE CLIENT_ADDRESS (
	CLIENT_ADDRESS_ID SERIAL PRIMARY KEY,
	CLIENT_ID INTEGER NOT NULL REFERENCES CLIENT ON DELETE CASCADE,
	FIRST_NAME VARCHAR(128) NOT NULL,
	LAST_NAME VARCHAR(128) NOT NULL,
	COMPANY VARCHAR(128),
	ADDRESS VARCHAR(512) NOT NULL,
	CITY VARCHAR(64)  NOT NULL,
	EMAIL VARCHAR(128) NOT NULL,
	PHONE VARCHAR(32),
	FAX VARCHAR(32)
);

ALTER TABLE CLIENT ADD FOREIGN KEY(DEFAULT_SHIPMENT_ADDRESS_ID) REFERENCES CLIENT_ADDRESS(CLIENT_ADDRESS_ID) INITIALLY DEFERRED;
ALTER TABLE CLIENT ADD FOREIGN KEY(DEFAULT_BILLING_ADDRESS_ID) REFERENCES CLIENT_ADDRESS(CLIENT_ADDRESS_ID) INITIALLY DEFERRED;

CREATE TABLE CATEGORY (
	CATEGORY_ID SERIAL PRIMARY KEY,
	PARENT_ID INTEGER REFERENCES CATEGORY(CATEGORY_ID),
	NAME VARCHAR(255) NOT NULL
);

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

CREATE TRIGGER category_cycle_insert BEFORE INSERT ON CATEGORY
FOR EACH ROW WHEN (NEW.PARENT_ID IS NOT NULL)
EXECUTE PROCEDURE category_find_cycles();
-- Inefficient for inserts (because the only forbidden case is self-reference)

CREATE TRIGGER category_cycle_update BEFORE UPDATE ON CATEGORY
FOR EACH ROW WHEN (NEW.PARENT_ID IS DISTINCT FROM OLD.PARENT_ID)
EXECUTE PROCEDURE category_find_cycles();

--------------------------------------------------

CREATE TABLE PRODUCT (
	PRODUCT_ID SERIAL PRIMARY KEY,
	CATEGORY_ID INTEGER REFERENCES CATEGORY(CATEGORY_ID),
	NAME VARCHAR(128) NOT NULL,
	WEIGHT NUMERIC(6,2)
);

CREATE TABLE PRODUCT_PRICE (
	PRODUCT_ID INTEGER NOT NULL REFERENCES PRODUCT(PRODUCT_ID),
	CREATED_AT TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
	PRICE NUMERIC(6,2) NOT NULL,
	PRIMARY KEY(PRODUCT_ID, CREATED_AT)
);

CREATE TABLE PRODUCT_STOCK (
	PRODUCT_ID INTEGER NOT NULL REFERENCES PRODUCT(PRODUCT_ID),
	BRANCH_ID INTEGER NOT NULL REFERENCES BRANCH(BRANCH_ID),
	QUANTITY INTEGER NOT NULL,
	PRIMARY KEY (PRODUCT_ID, BRANCH_ID)
);

CREATE TABLE SHIPMENT_TYPE (
	SHIPMENT_TYPE_ID SERIAL PRIMARY KEY,
	NAME VARCHAR(128) NOT NULL,
	MIN_ORDER_VALUE NUMERIC(6,2) NOT NULL DEFAULT 0,
	MAX_WEIGHT NUMERIC(6,2),
	COST NUMERIC(6,2) NOT NULL,
	PAYMENT_ON_DELIVERY BOOLEAN NOT NULL
);

CREATE TABLE COUPON (
	COUPON_ID VARCHAR(128) PRIMARY KEY,
	CLIENT_ID INTEGER REFERENCES CLIENT(CLIENT_ID),
	CATEGORY_ID INTEGER REFERENCES CATEGORY(CATEGORY_ID),
	PRODUCT_ID INTEGER REFERENCES PRODUCT(PRODUCT_ID),
	VALID_FROM TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
	VALID_TO TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW() + interval '7 days',
	CLAIM_LIMIT INTEGER,
	DISCOUNT NUMERIC(3,2) NOT NULL,
	CHECK(VALID_FROM < VALID_TO),
	CHECK(DISCOUNT > 0),
	CHECK(DISCOUNT <= 1)
);

CREATE TABLE "ORDER" (
	ORDER_ID SERIAL PRIMARY KEY,
	CLIENT_ID INTEGER REFERENCES CLIENT(CLIENT_ID),
	BILLING_ADDRESS_ID INTEGER REFERENCES CLIENT_ADDRESS(CLIENT_ADDRESS_ID),
	CREATED_AT TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
	SALESMAN_ID INTEGER NOT NULL REFERENCES EMPLOYEE(EMPLOYEE_ID),
	PAID BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE ORDER_SHIPMENT (
	ORDER_ID INTEGER PRIMARY KEY REFERENCES "ORDER"(ORDER_ID),
	SHIPMENT_TYPE_ID INTEGER NOT NULL REFERENCES SHIPMENT_TYPE(SHIPMENT_TYPE_ID),
	SHIPPING_ADDRESS_ID INTEGER NOT NULL REFERENCES CLIENT_ADDRESS(CLIENT_ADDRESS_ID),
	SHIPPED BOOLEAN NOT NULL DEFAULT FALSE,
	TRACKING VARCHAR(128)
);

CREATE TABLE ORDER_PRODUCT (
	ORDER_ID INTEGER NOT NULL REFERENCES "ORDER"(ORDER_ID),
	PRODUCT_ID INTEGER NOT NULL REFERENCES PRODUCT(PRODUCT_ID),
	QUANTITY INTEGER NOT NULL DEFAULT 1,
	CHECK(QUANTITY > 0),
	PRIMARY KEY(ORDER_ID, PRODUCT_ID)
);

CREATE TABLE ORDER_COUPON (
	ORDER_ID INTEGER NOT NULL REFERENCES "ORDER"(ORDER_ID),
	COUPON_ID VARCHAR(128) NOT NULL REFERENCES COUPON(COUPON_ID),
	PRIMARY KEY(ORDER_ID, COUPON_ID)
);
