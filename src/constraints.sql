--
-- constraints.sql
--

--
-- Triggers for detecting cycle presence
--

CREATE TRIGGER category_cycle_insert BEFORE INSERT ON category
FOR EACH ROW WHEN (NEW.parent_id IS NOT NULL)
EXECUTE PROCEDURE category_find_cycles();

CREATE TRIGGER category_cycle_update BEFORE UPDATE ON category
FOR EACH ROW WHEN (NEW.parent_id IS DISTINCT FROM OLD.parent_id)
EXECUTE PROCEDURE category_find_cycles();

--
-- Triggers validating coupons
--

CREATE TRIGGER order_coupon_insert BEFORE INSERT ON order_coupon
FOR EACH ROW EXECUTE PROCEDURE order_coupon_validate_trigger();

CREATE TRIGGER order_coupon_update BEFORE UPDATE ON order_coupon
FOR EACH ROW EXECUTE PROCEDURE order_coupon_validate_trigger();

CREATE TRIGGER order_product_removal AFTER DELETE ON order_coupon
FOR EACH ROW EXECUTE PROCEDURE order_coupon_after_order_product_delete();

--
-- Triggers validating orders
--

-- order must have a NOT NULL valid salesman assigned before the end of transaction
CREATE CONSTRAINT TRIGGER order_not_null_salesman AFTER INSERT OR UPDATE ON "order"
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE order_not_null_salesman();

-- order must have at least one product
CREATE CONSTRAINT TRIGGER order_nonempty_cart AFTER INSERT ON "order"
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE order_nonempty_cart();

CREATE CONSTRAINT TRIGGER order_nonempty_cart AFTER UPDATE OR DELETE ON order_product
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE order_nonempty_cart();

-- order shipping/billing addresses must belong to the client behind the order
CREATE CONSTRAINT TRIGGER order_address_check AFTER INSERT OR UPDATE ON "order"
FOR EACH ROW EXECUTE PROCEDURE order_address_check();

-- update product stock information
CREATE CONSTRAINT TRIGGER order_quantity_update AFTER INSERT OR UPDATE OR DELETE ON order_product
DEFERRABLE INITIALLY DEFERRED FOR EACH ROW EXECUTE PROCEDURE order_quantity_check();
