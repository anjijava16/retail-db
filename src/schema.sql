--
-- Database schema, basic constraints and relations
--

CREATE TABLE branch (
	branch_id SERIAL PRIMARY KEY,
	address VARCHAR(512) NOT NULL,
	city VARCHAR(64) NOT NULL
);

CREATE TABLE branch_phone (
	branch_id INTEGER REFERENCES branch ON DELETE CASCADE,
	phone VARCHAR(32) PRIMARY KEY,
	fax BOOLEAN NOT NULL default FALSE
);

CREATE TABLE employee (
	employee_id SERIAL PRIMARY KEY,
	first_name VARCHAR(128) NOT NULL,
	last_name VARCHAR(128) NOT NULL
);

CREATE TABLE position (
	position_id SERIAL PRIMARY KEY,
	name VARCHAR(64) NOT NULL,
	base_wage NUMERIC(6,2) NOT NULL,
	salesman BOOLEAN NOT NULL default FALSE,

	-- Minimum wage check
	CHECK(base_wage > 6.06)
);

CREATE TABLE employee_position (
	employee_id INTEGER NOT NULL REFERENCES employee ON DELETE CASCADE,
	position_id INTEGER NOT NULL REFERENCES position,
	superior_id INTEGER REFERENCES employee(employee_id),
	branch_id INTEGER NOT NULL REFERENCES branch,
	extra_wage NUMERIC(6,2) NOT NULL default 0,
	hours_per_week INTEGER NOT NULL default 40,
	since DATE NOT NULL default NOW(),
	PRIMARY KEY (employee_id, since)
);

CREATE TABLE client (
	client_id SERIAL PRIMARY KEY,
	default_shipment_address_id INTEGER NOT NULL,
	default_billing_address_id INTEGER NOT NULL
);

CREATE TABLE client_address (
	client_address_id SERIAL PRIMARY KEY,
	client_id INTEGER NOT NULL REFERENCES client ON DELETE CASCADE,
	first_name VARCHAR(128) NOT NULL,
	last_name VARCHAR(128) NOT NULL,
	company VARCHAR(128),
	address VARCHAR(512) NOT NULL,
	city VARCHAR(64)  NOT NULL,
	email VARCHAR(128) NOT NULL,
	phone VARCHAR(32),
	fax VARCHAR(32)
);

ALTER TABLE client ADD FOREIGN KEY(default_shipment_address_id) REFERENCES client_address(client_address_id) INITIALLY DEFERRED;
ALTER TABLE client ADD FOREIGN KEY(default_billing_address_id) REFERENCES client_address(client_address_id) INITIALLY DEFERRED;

CREATE TABLE category (
	category_id SERIAL PRIMARY KEY,
	parent_id INTEGER REFERENCES category(category_id),
	name VARCHAR(255) NOT NULL,
	VAT NUMERIC(3,2) NOT NULL default 0
);

CREATE TABLE product (
	product_id SERIAL PRIMARY KEY,
	category_id INTEGER REFERENCES category(category_id),
	name VARCHAR(128) NOT NULL,
	weight NUMERIC(6,2)
);

CREATE TABLE product_price (
	product_id INTEGER NOT NULL REFERENCES product(product_id) ON DELETE CASCADE,
	created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL default NOW(),
	price NUMERIC(6,2) NOT NULL,
	PRIMARY KEY(product_id, created_at)
);

CREATE TABLE product_stock (
	product_id INTEGER NOT NULL REFERENCES product(product_id) ON DELETE CASCADE,
	branch_id INTEGER NOT NULL REFERENCES branch(branch_id),
	quantity INTEGER NOT NULL,
	PRIMARY KEY (product_id, branch_id)
);

CREATE TABLE shipment_type (
	shipment_type_id SERIAL PRIMARY KEY,
	name VARCHAR(128) NOT NULL,
	min_order_value NUMERIC(6,2) NOT NULL default 0,
	max_weight NUMERIC(6,2),
	cost NUMERIC(6,2) NOT NULL,
	payment_on_delivery BOOLEAN NOT NULL
);

CREATE TABLE coupon (
	coupon_id VARCHAR(128) PRIMARY KEY,
	client_id INTEGER REFERENCES client(client_id),
	category_id INTEGER REFERENCES category(category_id),
	product_id INTEGER REFERENCES product(product_id),
	valid_from TIMESTAMP WITHOUT TIME ZONE NOT NULL default NOW(),
	valid_to TIMESTAMP WITHOUT TIME ZONE NOT NULL default NOW() + interval '7 days',
	claim_limit INTEGER,
	discount NUMERIC(3,2) NOT NULL,
	CHECK(valid_from < valid_to),
	CHECK(discount > 0),
	CHECK(discount <= 1),
	CHECK(category_id IS NULL OR product_id IS NULL)
);

CREATE TABLE "order" (
	order_id SERIAL PRIMARY KEY,
	client_id INTEGER REFERENCES client(client_id),
	billing_address_id INTEGER REFERENCES client_address(client_address_id),
	created_at TIMESTAMP WITHOUT TIME ZONE NOT NULL default NOW(),
	salesman_id INTEGER REFERENCES employee(employee_id),
	paid BOOLEAN NOT NULL default FALSE,
	shipment_type_id INTEGER REFERENCES shipment_type(shipment_type_id),
	shipment_address_id INTEGER REFERENCES client_address(client_address_id),
	shipped_at TIMESTAMP WITHOUT TIME ZONE,
	tracking VARCHAR(128)
);

CREATE TABLE order_product (
	order_id INTEGER NOT NULL REFERENCES "order"(order_id),
	product_id INTEGER NOT NULL REFERENCES product(product_id),
	quantity INTEGER NOT NULL default 1,
	CHECK(quantity > 0),
	PRIMARY KEY(order_id, product_id)
);

CREATE TABLE order_coupon (
	order_id INTEGER NOT NULL REFERENCES "order"(order_id),
	coupon_id VARCHAR(128) NOT NULL REFERENCES coupon(coupon_id),
	PRIMARY KEY(order_id, coupon_id)
);
