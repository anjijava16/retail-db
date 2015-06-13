--
-- views.sql
--

---------------------------------------------------------------
--	View showing the current prices of products (only includes
--	products with prices)
---------------------------------------------------------------

CREATE OR REPLACE VIEW current_prices AS

	SELECT p.* FROM product_price p JOIN 
	(	
		SELECT product_id, MAX(created_at) AS "newest"
		FROM product_price GROUP BY product_id
	) x 
	ON p.product_id = x.product_id AND p.created_at = x.newest;

---------------------------------------------------------------
--	View showing information about orders placed via internet
---------------------------------------------------------------

CREATE OR REPLACE VIEW remote_order AS

	SELECT	order_id, x.client_id, created_at, SUM(pr) AS "net",
			ROUND(SUM(pr * vat), 2) AS "tax",
			ROUND(SUM(pr * dsc), 2) AS "discount",
			ROUND(SUM(pr * (1 - dsc + vat)), 2) AS "total",
			paid, SUM(wg) AS "weight", salesman_id AS "salesman",
			s.name AS "shipment_type",
			a.address || ' ' || a.city AS "shipment_address",
			b.address || ' ' || b.city AS "billing_address"
	FROM

		(SELECT 	o.order_id, o.client_id, o.created_at,
					ppd.price * op.quantity as "pr", o.paid,
					1 - multiply(1 - COALESCE(c.discount, 0)) AS "dsc",
					o.salesman_id, o.shipment_type_id,
					o.shipment_address_id, o.billing_address_id,
					p.weight * op.quantity "wg", cat.vat "vat" 
		FROM "order" o 
			JOIN order_product op USING (order_id)
			JOIN product p USING (product_id)
			JOIN category cat USING (category_id)
			JOIN product_price_detail ppd USING (product_id)
			LEFT OUTER JOIN order_coupon oc ON (oc.order_id = o.order_id)
			LEFT OUTER JOIN coupon c ON (c.coupon_id = oc.coupon_id)

		WHERE
			o.shipment_type_id IS NOT NULL AND
			ppd.created_at <= o.created_at AND
			(o.created_at < ppd.ends_at OR ppd.ends_at IS NULL) AND
			(
				c.category_id IS NULL OR p.category_id IN
				(SELECT id FROM category_descendants(c.category_id))
			) AND
			(c.product_id IS NULL OR p.product_id = c.product_id)

		GROUP BY o.order_id, ppd.price, op.quantity, p.weight, cat.vat) x
		JOIN shipment_type s USING (shipment_type_id)
		JOIN client_address a ON (x.shipment_address_id = a.client_address_id)
		LEFT OUTER JOIN client_address b ON (x.billing_address_id = b.client_address_id)
		
	GROUP BY	order_id, x.client_id, created_at, paid, salesman_id,
				s.name, a.address, a.city, b.address, b.city;

---------------------------------------------------------------
--	Information about purchases made at local branches
---------------------------------------------------------------

CREATE OR REPLACE VIEW local_order AS

	SELECT	order_id, x.client_id, created_at, SUM(pr) AS "net",
			ROUND(SUM(pr * vat), 2) AS "tax",
			ROUND(SUM(pr * dsc), 2) AS "discount",
			ROUND(SUM(pr * (1 - dsc + vat)), 2) AS "total",
			ed.branch_id,
			b.address || ' ' || b.city AS "billing_address"
	FROM

		(SELECT 	o.order_id, o.client_id, o.created_at,
					o.salesman_id, o.billing_address_id,
					ppd.price * op.quantity as "pr",
					1 - multiply(1 - COALESCE(c.discount, 0)) AS "dsc",
					p.weight * op.quantity "wg", cat.vat "vat" 
		FROM "order" o 
			JOIN order_product op USING (order_id)
			JOIN product p USING (product_id)
			JOIN category cat USING (category_id)
			JOIN product_price_detail ppd USING (product_id)
			LEFT OUTER JOIN order_coupon oc ON (oc.order_id = o.order_id)
			LEFT OUTER JOIN coupon c ON (c.coupon_id = oc.coupon_id)

		WHERE
			o.shipment_type_id IS NULL AND
			ppd.created_at <= o.created_at AND
			(o.created_at < ppd.ends_at OR ppd.ends_at IS NULL) AND
			(
				c.category_id IS NULL OR p.category_id IN
				(SELECT id FROM category_descendants(c.category_id))
			) AND
			(c.product_id IS NULL OR p.product_id = c.product_id)

		GROUP BY o.order_id, ppd.price, op.quantity, p.weight, cat.vat) x
		JOIN employee_detail ed ON (x.salesman_id = ed.employee_id)
		LEFT OUTER JOIN client_address b ON (x.billing_address_id = b.client_address_id)
		
	GROUP BY	order_id, x.client_id, created_at,
				b.address, b.city, ed.branch_id;

---------------------------------------------------------------
--	View with orders that are pending (all in name, duh)
---------------------------------------------------------------

CREATE OR REPLACE VIEW pending_order AS

	SELECT	order_id, created_at, ROUND(SUM(pr * (1 - dsc + vat)), 2)
			AS "total", SUM(wg) AS "weight", salesman_id AS "salesman",
			x.shipment_type_id AS "shipment_type",
			a.address || ' ' || a.city AS "shipment_address",
			b.address || ' ' || b.city AS "billing_address"
	FROM
	
		(SELECT 	o.*, ppd.price * op.quantity as "pr",
					1 - multiply(1 - COALESCE(c.discount, 0)) AS "dsc",
					p.weight * op.quantity "wg", cat.vat "vat" 
		FROM "order" o 
			JOIN order_product op USING (order_id)
			JOIN product p USING (product_id)
			JOIN category cat USING (category_id)
			JOIN product_price_detail ppd USING (product_id)
			LEFT OUTER JOIN order_coupon oc ON (oc.order_id = o.order_id)
			LEFT OUTER JOIN coupon c ON (c.coupon_id = oc.coupon_id)
			JOIN shipment_type s USING (shipment_type_id)

		WHERE
			(shipped_at IS NULL AND (paid OR payment_on_delivery)) AND
			ppd.created_at <= o.created_at AND
			(o.created_at < ppd.ends_at OR ppd.ends_at IS NULL) AND
			(
				c.category_id IS NULL OR p.category_id IN
				(SELECT id FROM category_descendants(c.category_id))
			) AND
			(c.product_id IS NULL OR p.product_id = c.product_id)

		GROUP BY o.order_id, ppd.price, op.quantity, p.weight, cat.vat) x
		JOIN client_address a ON (x.shipment_address_id = a.client_address_id)
		LEFT OUTER JOIN client_address b ON (x.billing_address_id = b.client_address_id)

	GROUP BY	order_id, created_at, salesman_id, shipment_type_id, a.address,
				a.city, b.address, b.city;

---------------------------------------------------------------
