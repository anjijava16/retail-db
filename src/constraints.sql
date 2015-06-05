--
-- constraints.sql
--

--
-- Trigger for detecting cycle presence
--
CREATE TRIGGER category_cycle_insert BEFORE INSERT ON CATEGORY
FOR EACH ROW WHEN (NEW.PARENT_ID IS NOT NULL)
EXECUTE PROCEDURE category_find_cycles();

CREATE TRIGGER category_cycle_update BEFORE UPDATE ON CATEGORY
FOR EACH ROW WHEN (NEW.PARENT_ID IS DISTINCT FROM OLD.PARENT_ID)
EXECUTE PROCEDURE category_find_cycles();

--
-- Trigger validating coupons
--
CREATE TRIGGER order_coupon_insert BEFORE INSERT ON ORDER_COUPON
FOR EACH ROW EXECUTE PROCEDURE order_coupon_validate_trigger();

CREATE TRIGGER order_coupon_update BEFORE UPDATE ON ORDER_COUPON
FOR EACH ROW EXECUTE PROCEDURE order_coupon_validate_trigger();

CREATE TRIGGER order_product_removal AFTER DELETE ON ORDER_PRODUCT
FOR EACH ROW EXECUTE PROCEDURE order_coupon_after_order_product_delete();
