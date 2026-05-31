-- ============================================================
--  CEI Summer Internship 2026 | Week 2 | ShopEase Database
--  FILE: section_b_answers.sql
--  Section B — Filtering & Optimization (WHERE, Indexes)
-- ============================================================

USE shopease;


-- ============================================================
-- Q7. Retrieve all orders with status = 'Delivered'.

SELECT
    order_id,
    customer_id,
    order_date,
    status,
    total_amount
FROM orders
WHERE status = 'Delivered';

/*
Expected Result (6 rows):
order_id | customer_id | order_date  | status    | total_amount
--------------------------------------------------------------
1001     | 101         | 2024-08-01  | Delivered | 4498.00
1002     | 102         | 2024-08-03  | Delivered |  799.00
1004     | 101         | 2024-08-10  | Delivered | 3499.00
1006     | 105         | 2024-08-15  | Delivered | 5898.00
1008     | 103         | 2024-08-20  | Delivered |  899.00
1010     | 108         | 2024-08-28  | Delivered | 1598.00
*/


-- ============================================================
-- Q8. Find all products in the 'Electronics' category with a unit_price greater than ₹2000.

SELECT
    product_id,
    product_name,
    brand,
    category,
    unit_price,
    stock_qty
FROM products
WHERE category   = 'Electronics'
  AND unit_price > 2000.00;

/*
Expected Result (3 rows):
product_id | product_name      | brand | category    | unit_price | stock_qty
------------------------------------------------------------------------------
203        | Smart Watch       | Noise | Electronics | 2999.00    | 150
205        | Bluetooth Speaker | JBL   | Electronics | 3499.00    | 200


Actual 2 matching Electronics rows: 203, 205
Corrected — Electronics products with price > 2000:
  203 | Smart Watch       | Noise | 2999.00
  205 | Bluetooth Speaker | JBL   | 3499.00


Final answer: product_id - 203 and 205.
*/


-- ============================================================
-- Q9. List all customers who joined in the year 2024 AND belong to the state 'Maharashtra'.

SELECT
    customer_id,
    first_name,
    last_name,
    email,
    city,
    state,
    join_date,
    is_premium
FROM customers
WHERE state     = 'Maharashtra'
  AND join_date >= '2024-01-01'
  AND join_date <  '2025-01-01';

/*
Expected Result (2 rows):
customer_id | first_name | last_name | city   | state       | join_date  | is_premium
-------------------------------------------------------------------------------------
101         | Aarav      | Sharma    | Mumbai | Maharashtra | 2024-01-15 | TRUE
107         | Karan      | Mehta     | Pune   | Maharashtra | 2024-07-22 | TRUE
*/


-- ============================================================
-- Q10. Find all orders placed between '2024-08-10' and '2024-08-25' (inclusive) that are NOT Cancelled.

-- BETWEEN is inclusive on both ends.

SELECT
    order_id,
    customer_id,
    order_date,
    status,
    total_amount
FROM orders
WHERE order_date BETWEEN '2024-08-10' AND '2024-08-25'
  AND status <> 'Cancelled';

/*
Expected Result (4 rows):
order_id | customer_id | order_date  | status    | total_amount
--------------------------------------------------------------
1004     | 101         | 2024-08-10  | Delivered | 3499.00
1006     | 105         | 2024-08-15  | Delivered | 5898.00
1007     | 106         | 2024-08-18  | Pending   | 1299.00
1008     | 103         | 2024-08-20  | Delivered |  899.00
1009     | 107         | 2024-08-25  | Shipped   | 6098.00

Note: order_id 1005 (2024-08-12, Cancelled) is excluded by the NOT Cancelled filter.
*/


-- ============================================================
-- Q11. Explain what idx_orders_date does and how it helps. Write a sample query that benefits from this index.

/*
----- EXPLANATION -----

What is idx_orders_date?
  CREATE INDEX idx_orders_date ON orders(order_date);

  This is a B-Tree index on the `order_date` column of the `orders`
  table. Internally, MySQL maintains a sorted copy of the order_date
  values along with pointers back to the matching rows in the table.

How does it improve performance?

  WITHOUT the index:
    MySQL performs a Full Table Scan — it reads every single row in
    `orders`, checks whether order_date matches the condition, and
    collects matching rows. Cost = O(n) regardless of how many rows
    actually match.

  WITH idx_orders_date:
    MySQL uses a B-Tree Range Scan — it navigates the tree in
    O(log n) to locate the first matching date, then reads forward
    along the sorted leaf nodes only until the range ends. Far fewer
    rows are read.

  Practical impact:
    - For equality:  WHERE order_date = '2024-08-01'
    - For ranges:    WHERE order_date BETWEEN '2024-08-01' AND '2024-08-31'
    - For sorting:   ORDER BY order_date  (index already sorted → no filesort)
    - For grouping:  GROUP BY order_date  (avoids sort pass)

  It does NOT help with:
    - Function-wrapped columns: WHERE MONTH(order_date) = 8
      (wrapping breaks SARGability — MySQL cannot use the index)
*/

-- Sample query that directly benefits from idx_orders_date:
-- Retrieve all orders placed in August 2024, sorted by date.

SELECT
    order_id,
    customer_id,
    order_date,
    status,
    total_amount
FROM orders
WHERE order_date >= '2024-08-01'
  AND order_date <  '2024-09-01'   -- SARGable range: index scan used
ORDER BY order_date;               -- no filesort: index already sorted

-- we can verify the index is used by running:



-- ============================================================
-- Q12. Index-friendliness of YEAR(join_date) = 2024 + rewrite to SARGable form.

/*
----- EXPLANATION -----

Original query:
  SELECT * FROM customers WHERE YEAR(join_date) = 2024;

Would the index on join_date be used?  NO.

Why not?
  Although an index exists on `join_date` (idx_customers_city and
  idx_customers_state exist; note: no explicit index on join_date
  in the schema — but the principle applies universally to any
  indexed column):

  Wrapping a column inside a function — YEAR(join_date) — hides
  the original column value from the query optimizer. The index
  stores sorted values of `join_date` (e.g. 2024-01-15, 2024-03-10),
  NOT the result of YEAR(join_date). MySQL cannot map
  YEAR(join_date) = 2024 to a position in the B-Tree index, so it
  falls back to a Full Table Scan, computing YEAR() for every row.

  This is called a non-SARGable predicate.
  SARGable = Search ARGument ABLE — a predicate the storage engine
  can satisfy directly using an index seek/range scan.

How to fix it — rewrite as a SARGable date range:
*/

--  Non-SARGable (index cannot be used):
SELECT * FROM customers WHERE YEAR(join_date) = 2024;

-- SARGable rewrite (index can be used if one exists on join_date):
SELECT
    customer_id,
    first_name,
    last_name,
    email,
    city,
    state,
    join_date,
    is_premium
FROM customers
WHERE join_date >= '2024-01-01'
  AND join_date <  '2025-01-01';

/*
Why this works:
  The rewritten predicate compares the raw `join_date` column value
  directly against two constant date literals. MySQL can perform a
  B-Tree range scan: seek to '2024-01-01' in the index and read
  forward until '2025-01-01' — touching only the relevant rows.

  Both queries return identical results, but the rewrite is
  index-friendly and scales efficiently as the table grows.

General Rule:
  Avoid applying any function or expression to an indexed column
  in a WHERE clause. Instead, apply the transformation to the
  constant/literal side of the predicate, leaving the column bare.

  Non-SARGable  →  SARGable equivalent
  ─────────────────────────────────────────────────────────────
  YEAR(col) = 2024          →  col >= '2024-01-01' AND col < '2025-01-01'
  MONTH(col) = 8            →  col >= '2024-08-01' AND col < '2024-09-01'
  DATE(datetime_col) = ...  →  datetime_col >= '...' AND datetime_col < '...'
  UPPER(name) = 'AARAV'     →  name = 'Aarav'  (or use case-insensitive collation)
*/


--  END OF SECTION B ANSWERS
