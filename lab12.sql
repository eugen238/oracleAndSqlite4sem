--1
SELECT name, type 
FROM sqlite_master 
WHERE type IN ('table', 'view', 'trigger');

--2

--2.1
CREATE VIEW high_spending_customers AS
SELECT c.CUST_NUM, c.COMPANY, SUM(o.AMOUNT) AS TOTAL_SPENDING
FROM CUSTOMERS c
JOIN ORDERS o ON c.CUST_NUM = o.CUST
GROUP BY c.CUST_NUM
HAVING TOTAL_SPENDING > 10000;


select * from high_spending_customers;
--2.2
CREATE VIEW reps_and_offices AS
SELECT s.EMPL_NUM, s.NAME, o.OFFICE, o.CITY, o.REGION
FROM SALESREPS s
LEFT JOIN OFFICES o ON s.REP_OFFICE = o.OFFICE;

select * from reps_and_offices;
--2.3
CREATE VIEW orders_2008 AS
SELECT *
FROM ORDERS
WHERE strftime('%Y', ORDER_DATE) = '2008';


select * from orders_2008;
--2.4
CREATE VIEW reps_without_orders AS
SELECT *
FROM SALESREPS
WHERE EMPL_NUM NOT IN (SELECT DISTINCT REP FROM ORDERS);

select * from reps_without_orders;
--2.5
CREATE VIEW most_popular_products AS
SELECT p.MFR_ID, p.PRODUCT_ID, p.DESCRIPTION, SUM(o.QTY) AS TOTAL_QTY_SOLD
FROM PRODUCTS p
JOIN ORDERS o ON p.MFR_ID = o.MFR AND p.PRODUCT_ID = o.PRODUCT
GROUP BY p.MFR_ID, p.PRODUCT_ID, p.DESCRIPTION
ORDER BY TOTAL_QTY_SOLD DESC
LIMIT 10;

--3
CREATE TEMPORARY TABLE temp_orders (
    ORDER_NUM INTEGER PRIMARY KEY,
    ORDER_DATE DATE,
    CUST INTEGER,
    REP INTEGER,
    MFR CHAR(3),
    PRODUCT CHAR(5),
    QTY INTEGER,
    AMOUNT DECIMAL(9,2)
);

insert into temp_orders
VALUES (1,'11.11.2001',1,1,'1','1',1,5.1);

select * from temp_orders;

INSERT INTO temp_orders (ORDER_NUM, ORDER_DATE, CUST, REP, MFR, PRODUCT, QTY, AMOUNT)
VALUES (100001, '2023-05-06', 1, 101, 'ABC', '12345', 1, 10.50);

SELECT * FROM temp_orders;

--4
CREATE TEMP VIEW order_cust_view AS
SELECT *
FROM ORDERS
INNER JOIN CUSTOMERS ON ORDERS.CUST = CUSTOMERS.CUST_NUM;

-- выполняем запросы к временному представлению
SELECT * FROM order_cust_view WHERE CREDIT_LIMIT > 10000;
SELECT COUNT(*) FROM order_cust_view;

-- проверяем, существует ли временное представление
SELECT name FROM sqlite_temp_master WHERE type = 'view';


--5
CREATE INDEX idx_orders_amount ON ORDERS (AMOUNT);
drop index idx_orders_amount;

EXPLAIN QUERY PLAN SELECT DISTINCT SALESREPS.NAME 
FROM SALESREPS , ORDERS
WHERE SALESREPS.EMPL_NUM = ORDERs.REP 
AND ORDERs.AMOUNT > 1500;

CREATE INDEX idx_products_mfr_price ON PRODUCTS (MFR_ID, PRICE);
drop index idx_products_mfr_price;

EXPLAIN QUERY PLAN 
SELECT p.MFR_ID, MAX(p.PRICE) 
FROM PRODUCTS p 
GROUP BY p.MFR_ID;

CREATE INDEX idx_salesreps_age ON SALESREPS (AGE);
drop index idx_salesreps_age;

EXPLAIN QUERY PLAN SELECT * 
FROM SALESREPS 
WHERE AGE = 31;

CREATE INDEX idx_cust_num ON CUSTOMERS (CUST_NUM);
CREATE INDEX idx_products ON PRODUCTS (MFR_ID, PRODUCT_ID);
DROP INDEX idx_cust_num;
DROP INDEX idx_products;

EXPLAIN QUERY PLAN
SELECT PRODUCTS.DESCRIPTION
FROM ORDERS
JOIN PRODUCTS ON ORDERS.MFR = PRODUCTS.MFR_ID AND ORDERS.PRODUCT = PRODUCTS.PRODUCT_ID
JOIN CUSTOMERS ON ORDERS.CUST = CUSTOMERS.CUST_NUM
WHERE CUSTOMERS.COMPANY = 'First Corp';

CREATE INDEX idx_orders_rep_office ON ORDERS (REP);
DROP INDEX idx_orders_rep_;

EXPLAIN QUERY PLAN
SELECT REP, SUM(AMOUNT) AS TOTAL_AMOUNT
FROM ORDERS
GROUP BY REP
ORDER BY TOTAL_AMOUNT DESC;

CREATE INDEX idx_orders_order_date ON ORDERS (ORDER_DATE);
CREATE INDEX idx_customers_company ON CUSTOMERS (COMPANY);

EXPLAIN QUERY PLAN
SELECT DISTINCT C.COMPANY
FROM CUSTOMERS C
JOIN ORDERS O ON C.CUST_NUM = O.CUST
WHERE O.ORDER_DATE BETWEEN '2007-01-01' AND '2007-12-31'
AND C.COMPANY IN (
  SELECT DISTINCT C.COMPANY
  FROM CUSTOMERS C
  JOIN ORDERS O ON C.CUST_NUM = O.CUST
  WHERE O.ORDER_DATE BETWEEN '2008-01-01' AND '2008-12-31'
);


--6

CREATE TABLE AUDIT (
    TABLE_NAME TEXT NOT NULL,
    COLUMN_NAME TEXT NOT NULL,
    OLD_VALUE TEXT,
    NEW_VALUE TEXT,
    CHANGE_DATE TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
end;
select * from AUDIT;
select * from reps_and_offices;

update SALESREPS
set AGE = 51 where REP_OFFICE = 11;

CREATE TRIGGER SALESREPS_UPDATE_AUDIT
AFTER UPDATE ON SALESREPS
BEGIN
    INSERT INTO AUDIT(TABLE_NAME, COLUMN_NAME, OLD_VALUE, NEW_VALUE)
    VALUES('SALESREPS', 'EMPL_NUM', OLD.EMPL_NUM, NEW.EMPL_NUM);
    INSERT INTO AUDIT(TABLE_NAME, COLUMN_NAME, OLD_VALUE, NEW_VALUE)
    VALUES('SALESREPS', 'NAME', OLD.NAME, NEW.NAME);
    INSERT INTO AUDIT(TABLE_NAME, COLUMN_NAME, OLD_VALUE, NEW_VALUE)
    VALUES('SALESREPS', 'AGE', OLD.AGE, NEW.AGE);
    INSERT INTO AUDIT(TABLE_NAME, COLUMN_NAME, OLD_VALUE, NEW_VALUE)
    VALUES('SALESREPS', 'REP_OFFICE', OLD.REP_OFFICE, NEW.REP_OFFICE);
    INSERT INTO AUDIT(TABLE_NAME, COLUMN_NAME, OLD_VALUE, NEW_VALUE)
    VALUES('SALESREPS', 'TITLE', OLD.TITLE, NEW.TITLE);
    INSERT INTO AUDIT(TABLE_NAME, COLUMN_NAME, OLD_VALUE, NEW_VALUE)
    VALUES('SALESREPS', 'HIRE_DATE', OLD.HIRE_DATE, NEW.HIRE_DATE);
    INSERT INTO AUDIT(TABLE_NAME, COLUMN_NAME, OLD_VALUE, NEW_VALUE)
    VALUES('SALESREPS', 'MANAGER', OLD.MANAGER, NEW.MANAGER);
    INSERT INTO AUDIT(TABLE_NAME, COLUMN_NAME, OLD_VALUE, NEW_VALUE)
    VALUES('SALESREPS', 'QUOTA', OLD.QUOTA, NEW.QUOTA);
    INSERT INTO AUDIT(TABLE_NAME, COLUMN_NAME, OLD_VALUE, NEW_VALUE)
    VALUES('SALESREPS', 'SALES', OLD.SALES, NEW.SALES);
END;

--7
drop trigger insert_reps_and_offices;

CREATE TRIGGER insert_reps_and_offices
INSTEAD OF INSERT ON reps_and_offices
BEGIN
  INSERT INTO SALESREPS (EMPL_NUM, NAME, REP_OFFICE,HIRE_DATE,SALES)
  SELECT new.EMPL_NUM, new.NAME, new.OFFICE,'2006-06-14',361865;
  
  INSERT INTO OFFICES (OFFICE, CITY, REGION,SALES)
  SELECT new.OFFICE, new.CITY, new.REGION,361865;
END;
select * from reps_and_offices;

INSERT INTO reps_and_offices (EMPL_NUM, NAME, OFFICE, CITY, REGION)
VALUES (157, 'Ban Smith', 75, 'New York', 'East');



--8
BEGIN TRANSACTION;
INSERT INTO "main"."ORDERS" ("ORDER_NUM", "ORDER_DATE", "CUST", "REP", "MFR", "PRODUCT", "QTY", "AMOUNT") VALUES ('11306765', '2008-02-15', '2108', '101', 'ACI', '4100X', '6', '150');
UPDATE SALESREPS SET SALES = SALES + 1 WHERE EMPL_NUM = 103;
COMMIT;


--9
BEGIN TRANSACTION;
INSERT INTO "main"."SALESREPS" ("EMPL_NUM", "NAME", "AGE", "REP_OFFICE", "TITLE", "HIRE_DATE", "MANAGER", "QUOTA", "SALES") VALUES ('185', 'Mary Jones', '31', '11', 'Sales Rep', '2007-10-12', '106', '300000', '392725');
SAVEPOINT sp1;
INSERT INTO "main"."ORDERS" ("ORDER_NUM", "ORDER_DATE", "CUST", "REP", "MFR", "PRODUCT", "QTY", "AMOUNT") VALUES ('11305658', '2008-02-15', '2108', '101', 'ACI', '4100X', '6', '150');
INSERT INTO "main"."ORDERS" ("ORDER_NUM", "ORDER_DATE", "CUST", "REP", "MFR", "PRODUCT", "QTY", "AMOUNT") VALUES ('11305658578', '2008-02-15', '2108', '101', 'ACI', '4100X', '6', '150');
COMMIT;

--10
BEGIN TRANSACTION;
INSERT INTO "main"."SALESREPS" ("EMPL_NUM", "NAME", "AGE", "REP_OFFICE", "TITLE", "HIRE_DATE", "MANAGER", "QUOTA", "SALES") VALUES ('165', 'Mary Jones', '31', '11', 'Sales Rep', '2007-10-12', '106', '300000', '392725');
SAVEPOINT sp1;
INSERT INTO "main"."ORDERS" ("ORDER_NUM", "ORDER_DATE", "CUST", "REP", "MFR", "PRODUCT", "QTY", "AMOUNT") VALUES ('11305668', '2008-02-15', '2108', '101', 'ACI', '4100X', '6', '150');
INSERT INTO "main"."ORDERS" ("ORDER_NUM", "ORDER_DATE", "CUST", "REP", "MFR", "PRODUCT", "QTY", "AMOUNT") VALUES ('11305658588', '2008-02-15', '2108', '101', 'ACI', '4100X', '6', '150');
ROLLBACK TO SAVEPOINT sp1;
COMMIT;