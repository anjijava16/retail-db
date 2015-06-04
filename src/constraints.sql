--
-- constraints.sql
--

--------------------------------------------------
--	Trigger for detecting cycle presence		--

CREATE TRIGGER category_cycle_insert BEFORE INSERT ON CATEGORY
FOR EACH ROW WHEN (NEW.PARENT_ID IS NOT NULL)
EXECUTE PROCEDURE category_find_cycles();
-- Inefficient for inserts (because the only forbidden case is self-reference)

CREATE TRIGGER category_cycle_update BEFORE UPDATE ON CATEGORY
FOR EACH ROW WHEN (NEW.PARENT_ID IS DISTINCT FROM OLD.PARENT_ID)
EXECUTE PROCEDURE category_find_cycles();

--------------------------------------------------
