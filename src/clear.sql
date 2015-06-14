DROP TABLE IF EXISTS order_product CASCADE;
DROP TABLE IF EXISTS order_coupon CASCADE;
DROP TABLE IF EXISTS product_price CASCADE;
DROP TABLE IF EXISTS product_stock CASCADE;
DROP TABLE IF EXISTS branch_phone CASCADE;
DROP TABLE IF EXISTS employee_position CASCADE;
DROP TABLE IF EXISTS branch CASCADE;
DROP TABLE IF EXISTS employee CASCADE;
DROP TABLE IF EXISTS position CASCADE;
DROP TABLE IF EXISTS coupon CASCADE;
DROP TABLE IF EXISTS shipment_type CASCADE;
DROP TABLE IF EXISTS client_address CASCADE;
DROP TABLE IF EXISTS client CASCADE;
DROP TABLE IF EXISTS product CASCADE;
DROP TABLE IF EXISTS category CASCADE;
DROP TABLE IF EXISTS "order" CASCADE;
DROP AGGREGATE IF EXISTS multiply(NUMERIC) CASCADE;
DROP VIEW IF EXISTS product_price_detail CASCADE;
DROP VIEW IF EXISTS employee_detail CASCADE;
DROP VIEW IF EXISTS remote_order CASCADE;
DROP VIEW IF EXISTS local_order CASCADE;
DROP VIEW IF EXISTS pending_order CASCADE;
DROP FUNCTION IF EXISTS category_find_cycles() CASCADE;
DROP FUNCTION IF EXISTS category_ancestors(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS category_descendants(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS category_leaves() CASCADE;
DROP FUNCTION IF EXISTS numeric_multiply(NUMERIC, NUMERIC) CASCADE;
DROP FUNCTION IF EXISTS order_coupon_validate(INTEGER, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS order_information(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS order_products(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS order_coupon_validate_trigger() CASCADE;
DROP FUNCTION IF EXISTS order_coupon_after_order_product_delete() CASCADE;
DROP FUNCTION IF EXISTS find_best_salesman(INTEGER) CASCADE;
DROP FUNCTION IF EXISTS order_not_null_salesman() CASCADE;
DROP FUNCTION IF EXISTS order_nonempty_cart() CASCADE;
DROP FUNCTION IF EXISTS order_address_check() CASCADE;
DROP FUNCTION IF EXISTS order_shipment_check() CASCADE;
DROP FUNCTION IF EXISTS order_quantity_check() CASCADE;
DROP FUNCTION IF EXISTS product_has_price() CASCADE;
DROP FUNCTION IF EXISTS price_sequence_point() CASCADE;
