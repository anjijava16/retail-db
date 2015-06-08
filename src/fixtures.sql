--
-- Fixtures (examples)
--

BEGIN;

COPY BRANCH (ADDRESS, CITY) FROM STDIN;
ul. Bracka 9	Kraków
ul. Marszałkowska 10	Warszawa
ul. Pawia 11	Białystok
\.

COPY BRANCH_PHONE(BRANCH_ID, PHONE, FAX) FROM STDIN;
\N	0-800-100-800 	FALSE
1 	(0-12) 342-24-23 	FALSE
1 	(0-12) 343-34-34 	TRUE
2 	(0-22) 443-34-53 	FALSE
2 	(0-22) 657-66-66 	FALSE
3 	(0-32) 454-54-45 	TRUE
3 	(0-32) 136-64-25 	FALSE
\.

COPY POSITION(NAME, BASE_WAGE, SALESMAN) FROM STDIN;
Prezes	100.00	FALSE
Dyrektor handlowy	50.0	FALSE
Dyrektor finansowy	50.0	FALSE
Dyrektor marketingowy	50.0	FALSE
Kierownik oddziału	30.0	FALSE
Starszy sprzedawca	15.0	TRUE
Młodszy sprzedawca	8.00	TRUE
\.

COPY EMPLOYEE(FIRST_NAME, LAST_NAME) FROM STDIN;
Adam 	Nowak
Ewa 	Lis 
Marek 	Migalski
Piotr 	Duda 
Tomasz 	Wilk
Krystyna 	Czubówna
Dariusz 	Żubr 
Tadeusz 	Sznuk
Paweł 	Marszałek
Sebastian 	Baryła
Karol 	Walasek 
\.

COPY EMPLOYEE_POSITION(EMPLOYEE_ID, POSITION_ID, SUPERIOR_ID, BRANCH_ID, SINCE) FROM STDIN;
1	1	\N	2	2000-01-01
2	2	1	2	2000-01-12
3	3	1	2	2000-01-20
4	4	1	2	2001-04-30
5	5	2	1	2002-05-05
6	5	2	2	2002-05-05
7	5	2	3	2002-05-05
8	6	5	1	2002-05-05
9	6	6	2	2002-05-05
10	6	7	3	2002-05-05
10	7	7	3	2000-02-01
11	7	5	1	2002-05-05
\.

COPY CLIENT (DEFAULT_SHIPMENT_ADDRESS_ID, DEFAULT_BILLING_ADDRESS_ID) FROM STDIN;
1	1
2	2
\.

COPY CLIENT_ADDRESS (CLIENT_ID, FIRST_NAME, LAST_NAME, COMPANY, ADDRESS, CITY, EMAIL, PHONE, FAX) FROM STDIN;
1	Adam	Jarocki	\N	Plac Zbawiciela 4	Warszawa	jarocki@gmail.com	(22) 344-45-45	\N
2	Dariusz	Dobrzański	\N	ul. Traugutta 24	Żywiec	dardob@gmail.com	(34) 744-45-45	\N
\.

COPY CATEGORY(PARENT_ID, NAME) FROM STDIN;
\N	Komputery
1	Podzespoły bazowe
2	Procesory
2	Płyty główne
2	Karty graficzne
2	Pamięć RAM
2	Pamięć masowa
\N	AGD
8	Lodówki
8	Kuchenki mikrofalowe
8	Pralki
8	Piekarniki
8	Płyty kuchenne
13	Indukcyjne
13	Konwencjonalne
\.

COPY PRODUCT(CATEGORY_ID, NAME, WEIGHT) FROM STDIN;
3	Intel i5 3440	0.2
3	Intel i3 3220	0.2
4	ASRock Q97	0.5
5	MSI GTX970	0.3
6	Goodram 2x8GB	0.1
7	Intel 530 64GB	0.1
9	Amica BV234bc	50
10	Electrolux Fg23	10
11	BEKO VBC2452FG	50
12	BEKO VCB34	20
14	Amica IND34	5
15	Amica KON2135	7
\.

COPY PRODUCT_PRICE(PRODUCT_ID, CREATED_AT, PRICE) FROM STDIN;
1	2014-10-25 15:05:10	1000
1	2014-09-04 21:48:32	500
2	2015-04-05 04:13:38	550
3	2014-07-10 07:18:47	200
4	2015-03-09 14:39:13	400
5	2014-07-07 10:54:16	400
6	2014-06-03 16:08:43	345
7	2014-12-07 06:01:19	253
8	2015-02-22 05:14:42	352
9	2015-05-22 03:01:46	1000
10	2013-05-23 00:00:00	1000
11	2014-03-30 00:00:00	800
12	2014-01-23 00:00:00	500
\.

COPY PRODUCT_STOCK(PRODUCT_ID, BRANCH_ID, QUANTITY) FROM STDIN;
9	1	71
8	2	34
7	1	59
4	2	59
11	2	9
1	1	18
5	2	21
7	2	2
10	2	15
10	1	85
3	2	32
12	3	46
4	3	64
5	1	49
1	3	1
5	3	64
11	3	63
2	3	47
7	3	51
2	1	53
3	1	22
8	1	60
12	1	5
\.

COPY SHIPMENT_TYPE(NAME, MIN_ORDER_VALUE, MAX_WEIGHT, COST, PAYMENT_ON_DELIVERY) FROM STDIN;
DHL Express	0	10	15	FALSE
DHL Express (promocja)	100	10	0	FALSE
FedEx	0	10	13	FALSE
FedEx (promocja)	100	10	0	FALSE
Paczkomaty	0	10	7.99	FALSE
Paczkomaty (promocja)	100	10	0	FALSE
DHL Express (gabaryt)	0	\N	50	FALSE
DHL Express (pobranie)	20	10	25	TRUE
\.

COPY COUPON(COUPON_ID, CLIENT_ID, CATEGORY_ID, PRODUCT_ID, VALID_FROM, VALID_TO, CLAIM_LIMIT, DISCOUNT) FROM STDIN;
CINCODEMAYO	\N	\N	\N	2015-05-05 00:00:00	2015-05-05 23:59:59	\N	0.05
AXV45CV	\N	\N	\N	2014-12-12 00:00:00	2015-12-31 23:59:59	1	0.1
CLIENT_LIMITED	1	\N	\N	2014-12-20 00:00:00	2015-12-20 23:59:59	1	0.4
KUPONAGD	\N	8	\N	2015-01-01 00:00:00	2015-12-31 23:59:59	9999	0.5
\.

COPY "order"(CLIENT_ID, CREATED_AT, SHIPMENT_TYPE_ID, SHIPMENT_ADDRESS_ID) FROM STDIN;
1	2015-05-05 06:21:34	1	1
2	2014-12-23 04:45:45	7	2
\N	NOW()	\N	\N
\.

COPY ORDER_PRODUCT(ORDER_ID, PRODUCT_ID, QUANTITY) FROM STDIN;
1	5	1
1	6	1
1	2	1
1	12	1
2	10	1
3	10	2
\.

COPY ORDER_COUPON(ORDER_ID, COUPON_ID) FROM STDIN;
1	CINCODEMAYO
1	KUPONAGD
\.

END;
