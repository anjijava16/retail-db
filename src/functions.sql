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
