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

COPY POSITION(PROMOTION_ID, NAME, BASE_WAGE, SALESMAN) FROM STDIN;
\N	Prezes	100.00	FALSE
\N	Dyrektor handlowy	50.0	FALSE
\N	Dyrektor finansowy	50.0	FALSE
\N	Dyrektor marketingowy	50.0	FALSE
2	Kierownik oddziału	30.0	FALSE
5	Starszy sprzedawca	15.0	TRUE
6	Młodszy sprzedawca	8.00	TRUE
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
11	7	5	1	2002-05-05
\.

END;
