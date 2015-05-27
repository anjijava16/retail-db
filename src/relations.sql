---- BRANCH
-- Stores information about two types of company subunits i.e. storehouses
-- and non-storehouses (perhaps offices and headquaters).
CREATE TABLE BRANCH (
	BRANCH_ID  SERIAL,
	ADDRESS    VARCHAR(512) NOT NULL,
	CITY       VARCHAR(64) NOT NULL,
	STOREHOUSE BOOLEAN NOT NULL DEFAULT FALSE
);
----

---- BRANCH_PHONE
-- In many-to-many relation with BRANCH table. A large company may own
-- a nationwide helpdesk (0-800) that can be used to contact any company
-- subunit - such phone numbers have BRANCH_ID set to null.
CREATE TABLE BRANCH_PHONE (
	BRANCH_ID INTEGER,
	PHONE     VARCHAR(32),
	FAX       BOOLEAN NOT NULL DEFAULT FALSE
);
----

---- EMPLOYEE
-- Information about employees working in all branches of the company.
-- Deleting branches or superior employees does not cascade. We need to
-- fire, relocate employee, or change its superior first.
CREATE TABLE EMPLOYEE (
	EMPLOYEE_ID  SERIAL,
	SUPERIOR_ID  INTEGER,
	BRANCH_ID    INTEGER NOT NULL,
	FIRST_NAME   VARCHAR(128) NOT NULL,
	LAST_NAME    VARCHAR(128) NOT NULL,
	EXTRA_WAGE   NUMERIC(4,2) NOT NULL DEFAULT 0
);
----

---- POSITION
-- Many-to-many relationship with EMPLOYEE relation. Defines basic wage for
-- all employees working on this position. Field SALESMAN specifies whether
-- employees on this position may be assigned to process orders.
CREATE TABLE POSITION (
	POSITION_ID SERIAL,
	NAME        VARCHAR(64) NOT NULL,
	BASE_WAGE   NUMERIC(4,2) NOT NULL,
	SALESMAN    BOOLEAN NOT NULL DEFAULT FALSE
);
----

---- EMPLOYEE_POSITION
-- Proxy between EMPLOYEE and POSITION relations.
CREATE TABLE EMPLOYEE_POSITION (
	EMPLOYEE_ID INTEGER NOT NULL,
	POSITION_ID INTEGER NOT NULL,
	CREATED_AT  DATE NOT NULL DEFAULT NOW()
);
----

---- CLIENT
-- Relation that contains all essential data about client.
CREATE TABLE CLIENT (
	CLIENT_ID                   SERIAL,
	DEFAULT_SHIPMENT_ADDRESS_ID INTEGER NOT NULL,
	DEFAULT_BILLING_ADDRESS_ID  INTEGER NOT NULL
);
----

---- CLIENT_ADDRESS
-- Relation that contains address data for billing and shipment.
CREATE TABLE CLIENT_ADDRESS (
	CLIENT_ADDRESS_ID SERIAL,
	CLIENT_ID         INTEGER NOT NULL,
	FIRST_NAME        VARCHAR(128) NOT NULL,
	LAST_NAME         VARCHAR(128) NOT NULL,
	COMPANY           VARCHAR(128),
	ADDRESS           VARCHAR(512) NOT NULL,
	CITY              VARCHAR(64)  NOT NULL,
	EMAIL             VARCHAR(128) NOT NULL UNIQUE,
	PHONE             VARCHAR(32),
	FAX               VARCHAR(32)
);
----

---- ORDER
CREATE TABLE "ORDER" (
	ORDER_ID            SERIAL,
	CLIENT_ID           INTEGER,
	SHIPMENT_ADDRESS_ID INTEGER,
	BILLING_ADDRESS_ID  INTEGER,
	CREATED_AT          TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW()
);
----

---- PRODUCT
CREATE TABLE PRODUCT (
	PRODUCT_ID  SERIAL,
	CATEGORY_ID INTEGER,
	NAME        VARCHAR(128)
);
----

---- PRODUCT_PRICE
CREATE TABLE PRODUCT_PRICE (
	PRODUCT_ID INTEGER,
	CREATED_AT TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
	PRICE      NUMERIC(6,2) NOT NULL
);
----

---- PRODUCT_STOCK
CREATE TABLE PRODUCT_STOCK (
	PRODUCT_ID INTEGER,
	BRANCH_ID  INTEGER,
	QUANTITY   INTEGER NOT NULL
);
----
