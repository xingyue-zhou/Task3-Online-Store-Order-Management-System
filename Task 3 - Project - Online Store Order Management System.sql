-- Task 3 - Project: Online Store Order Management System (

-- Create database
CREATE DATABASE OnlineStore;
USE OnlineStore;

CREATE TABLE Customers (
    CUSTOMER_ID INT PRIMARY KEY,
    NAME VARCHAR(100),
    EMAIL VARCHAR(100),
    PHONE VARCHAR(20),
    ADDRESS VARCHAR(255)
);

CREATE TABLE Products (
    PRODUCT_ID INT PRIMARY KEY,
    PRODUCT_NAME VARCHAR(100),
    CATEGORY VARCHAR(50),
    PRICE DECIMAL(10,2),
    STOCK INT
);

CREATE TABLE Orders (
    ORDER_ID INT PRIMARY KEY,
    CUSTOMER_ID INT,
    PRODUCT_ID INT,
    QUANTITY INT,
    ORDER_DATE DATE,
    FOREIGN KEY (CUSTOMER_ID) REFERENCES Customers(CUSTOMER_ID),
    FOREIGN KEY (PRODUCT_ID) REFERENCES Products(PRODUCT_ID)
);

INSERT INTO Customers (CUSTOMER_ID, NAME, EMAIL, PHONE, ADDRESS)
VALUES
(1, 'Alice Johnson', 'alice@example.com', '9123456780', '123 Maple St'),
(2, 'Bob Smith', 'bob@example.com', '9234567890', '456 Oak Ave'),
(3, 'Charlie Lee', 'charlie@example.com', '9345678901', '789 Pine Rd'),
(4, 'Helen Zhang', 'helen.zhang@example.com', '9890123456', '101 Maple St'),
(5, 'Ian Thomas', 'ian.thomas@example.com', '9901234567', '112 Maple St'),
(6, 'Jenny Liu', 'jenny.liu@example.com', '9012345678', '131 Maple St'),
(7, 'David Kim', 'david.kim@example.com', '9456789012', '415 Maple St');

INSERT INTO Products (PRODUCT_ID, PRODUCT_NAME, CATEGORY, PRICE, STOCK)
VALUES
(101, 'Wireless Mouse', 'Electronics', 25.99, 60),
(102, 'Bluetooth Headphones', 'Electronics', 59.99, 50),
(103, 'Running Shoes', 'Footwear', 89.99, 30),
(104, 'Coffee Mug', 'Home', 12.50, 200),
(105, 'Table', 'Home', 199.00, 2),
(106, 'Slipper', 'Footwear', 19.9, 200),
(107, 'Kettle', 'Home', 39.99, 10);

INSERT INTO Orders (ORDER_ID, CUSTOMER_ID, PRODUCT_ID, QUANTITY, ORDER_DATE)
VALUES
(1001, 7, 102, 1, '2025-01-20'),
(1002, 1, 101, 20, '2025-05-01'),
(1003, 2, 103, 1, '2025-05-26'),
(1004, 3, 104, 1, '2025-06-10'),
(1005, 2, 101, 50, '2025-06-16'),
(1006, 3, 102, 1, '2025-06-27'),
(1007, 1, 104, 4, '2025-07-03'),
(1008, 2, 105, 3, '2025-07-13'),
(1009, 4, 104, 2, '2025-07-14'),
(1010, 5, 104, 5, '2025-07-14'),
(1011, 4, 102, 2, '2025-07-14'),
(1012, 2, 107, 1, '2025-07-26');


-- Order Management:
-- a) Retrieve all orders placed by a specific customer.
SELECT
c.*
, o.*
FROM Customers c
  LEFT JOIN Orders o
  ON c.CUSTOMER_ID = o.CUSTOMER_ID
;

-- b) Find products that are out of stock.
WITH quantity_total AS(
  SELECT
    PRODUCT_ID
    , sum(QUANTITY) AS QUANTITY_TOTAL
  FROM Orders
  GROUP BY PRODUCT_ID
)

SELECT
    p.*
FROM Products p
  LEFT JOIN quantity_total qt
  ON p.PRODUCT_ID = qt.PRODUCT_ID
WHERE p.STOCK < qt.QUANTITY_TOTAL
;

-- c) Calculate the total revenue generated per product.
WITH quantity_total AS(
  SELECT
    PRODUCT_ID
    , sum(QUANTITY) AS QUANTITY_TOTAL
  FROM Orders
  GROUP BY PRODUCT_ID
)

SELECT
  p.PRODUCT_ID
  , p.PRODUCT_NAME
  , p.CATEGORY
  , sum(p.PRICE * o.QUANTITY) as REVENUE_GENERATED
FROM Products p
  LEFT JOIN Orders o
  ON p.PRODUCT_ID = o.PRODUCT_ID
  LEFT JOIN quantity_total qt
  ON p.PRODUCT_ID = qt.PRODUCT_ID
WHERE p.STOCK > qt.QUANTITY_TOTAL
GROUP BY 1,2,3
;

-- d) Retrieve the top 5 customers by total purchase amount.
WITH quantity_total AS(
  SELECT
    PRODUCT_ID
    , sum(QUANTITY) AS QUANTITY_TOTAL
  FROM Orders
  GROUP BY PRODUCT_ID
)

, amount_rank AS(
  SELECT
    o.CUSTOMER_ID
    , sum(p.PRICE * o.QUANTITY) as AMOUNT
    , RANK() OVER(ORDER BY sum(p.PRICE * o.QUANTITY) DESC) as AMOUNT_RANK
  FROM Products p
    LEFT JOIN Orders o
    ON p.PRODUCT_ID = o.PRODUCT_ID
    LEFT JOIN quantity_total qt
    ON p.PRODUCT_ID = qt.PRODUCT_ID
  WHERE p.STOCK > qt.QUANTITY_TOTAL
  GROUP BY o.CUSTOMER_ID
)

SELECT
  c.*
  , ar.AMOUNT
FROM Customers c
  LEFT JOIN amount_rank ar
  ON c.CUSTOMER_ID = ar.CUSTOMER_ID
WHERE ar.amount_rank <=5
ORDER BY ar.AMOUNT DESC
;

-- e) Find customers who placed orders in at least two different product categories.
WITH category_cnt AS(
  SELECT
    o.CUSTOMER_ID
    , count(distinct p.CATEGORY) as CATEGORY_CNT
  FROM Orders o
    LEFT JOIN Products p
    ON p.PRODUCT_ID = o.PRODUCT_ID
  GROUP BY o.CUSTOMER_ID
)

SELECT * FROM Customers
WHERE CUSTOMER_ID IN (SELECT distinct CUSTOMER_ID FROM category_cnt WHERE CATEGORY_CNT >=2)
;

-- Analytics:
-- a) Find the month with the highest total sales.
WITH quantity_total AS(
  SELECT
    PRODUCT_ID
    , sum(QUANTITY) AS QUANTITY_TOTAL
  FROM Orders
  GROUP BY PRODUCT_ID
)

, amount_rank AS(
  SELECT
    extract(month FROM ORDER_DATE) AS ORDER_MONTH
    , sum(p.PRICE * o.QUANTITY) as AMOUNT
    , RANK() OVER(ORDER BY sum(p.PRICE * o.QUANTITY) DESC) as AMOUNT_RANK
  FROM Orders o
    LEFT JOIN Products p
    ON p.PRODUCT_ID = o.PRODUCT_ID
    LEFT JOIN quantity_total qt
    ON p.PRODUCT_ID = qt.PRODUCT_ID
  WHERE p.STOCK > qt.QUANTITY_TOTAL
  GROUP BY 1
)

SELECT
  ar.ORDER_MONTH
  , ar.AMOUNT
FROM amount_rank ar
WHERE ar.amount_rank = 1
ORDER BY ar.AMOUNT DESC
;

-- b) Identify products with no orders in the last 6 months.
SELECT
  p.*
FROM Products p
  LEFT JOIN Orders o
  ON p.PRODUCT_ID = o.PRODUCT_ID
WHERE o.ORDER_DATE < DATE_ADD(current_date, interval -6 month)

UNION all
SELECT
  p.*
FROM Products p
  LEFT JOIN Orders o
  ON p.PRODUCT_ID = o.PRODUCT_ID
WHERE o.PRODUCT_ID IS NULL
;

-- c) Retrieve customers who have never placed an order.
SELECT
  c.*
FROM Customers c
  LEFT JOIN Orders o
  ON c.CUSTOMER_ID = o.CUSTOMER_ID
WHERE o.CUSTOMER_ID IS NULL
;

-- d) Calculate the average order value across all orders.
WITH amount_total AS(
SELECT
  o.ORDER_ID
  , o.QUANTITY * p.PRICE AS AMOUNT
FROM Orders o
  LEFT JOIN Products p
  ON o.PRODUCT_ID = p.PRODUCT_ID
)

SELECT
  round(sum(AMOUNT)/count(ORDER_ID),2) AS avg_order_amount
FROM amount_total
;
