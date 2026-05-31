-- ============================================================
--  CEI Summer Internship 2026 | Week 2 | ShopEase Database
--  FILE: 03_section_d_joins.sql
--  Section D — Joins & Relationships (Q19 – Q23)
-- ============================================================

USE shopease;

-- ============================================================
-- Q19. INNER JOIN — Orders with Customer Names

-- Returns only rows where a match exists in BOTH tables.
-- Since every order has a valid customer_id (FK enforced),

SELECT
    o.order_id,
    o.order_date,
    c.first_name,
    c.last_name,
    o.total_amount
FROM orders o
INNER JOIN customers c
    ON o.customer_id = c.customer_id
ORDER BY o.order_id;

/*
Expected: 10 rows — one per order, matched with customer name.


*/


-- ============================================================
-- Q20. LEFT JOIN — ALL Customers, With Orders (if any)

-- A LEFT JOIN keeps ALL rows from the LEFT table (customers),
-- even when there is no matching row in the RIGHT table (orders).
-- Customers with no orders will show NULL in order columns.

SELECT
    c.customer_id,
    c.first_name,
    c.last_name,
    c.city,
    o.order_id,
    o.order_date,
    o.status,
    o.total_amount
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
ORDER BY c.customer_id, o.order_id;

/*
Expected: 12 rows total
  - Customers 101, 103 → 2 rows each (2 orders each)
  - Customers 102, 104, 105, 106, 107, 108 → 1 row each
*/


-- ============================================================
-- Q21. THREE-TABLE JOIN — Order Items with Product Details
-- ============================================================
-- Joins orders → order_items → products to show
-- full line-item detail for every order.

SELECT
    oi.order_id,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    oi.discount_pct,
    -- Bonus: effective line total after discount
    ROUND(oi.quantity * oi.unit_price * (1 - oi.discount_pct / 100), 2) AS line_total
FROM order_items oi
INNER JOIN orders o
    ON oi.order_id = o.order_id
INNER JOIN products p
    ON oi.product_id = p.product_id
ORDER BY oi.order_id, oi.item_id;

/*
Expected: 15 rows — one per order_item record.
Note: oi.unit_price stores the price AT TIME OF PURCHASE
      and may differ from the current products.unit_price.
      discount_pct values in the data: 0, 5, 10, 15.
*/


-- ============================================================
-- Q22. LEFT JOIN vs RIGHT JOIN — Explanation + Examples
-- ============================================================

-- ── CONCEPT ──────────────────────────────────────────────────
-- LEFT JOIN  : Returns ALL rows from the LEFT table + matching
--              rows from the right. Non-matching right rows → NULL.
--
-- RIGHT JOIN : Returns ALL rows from the RIGHT table + matching
--              rows from the left. Non-matching left rows → NULL.
--
-- A RIGHT JOIN is logically equivalent to swapping the tables
-- in a LEFT JOIN. Most developers prefer LEFT JOIN for readability.
--
-- FULL OUTER JOIN : Returns ALL rows from BOTH tables.
--   - Matched rows → combined data
--   - Unmatched left rows → NULLs for right columns
--   - Unmatched right rows → NULLs for left columns
--
-- MySQL does NOT support FULL OUTER JOIN directly.
-- Emulate it using UNION of LEFT JOIN + RIGHT JOIN (see below).

-- ── EXAMPLE A: LEFT JOIN (customers driving) ─────────────────
-- "Show all customers; include order info only if they ordered."

SELECT
    c.customer_id,
    c.first_name,
    o.order_id,
    o.total_amount
FROM customers c            -- LEFT  table → all customers kept
LEFT JOIN orders o
    ON c.customer_id = o.customer_id;

-- ── EXAMPLE B: RIGHT JOIN (orders driving) ───────────────────
-- Equivalent result to Example A but with tables swapped.
-- "Show all orders; include customer info if it exists."
-- In a schema with FK enforcement this produces the same rows,
-- but RIGHT JOIN is useful when the "must-keep" table is on
-- the right side of an existing JOIN chain.

SELECT
    c.customer_id,
    c.first_name,
    o.order_id,
    o.total_amount
FROM orders o               -- RIGHT table → all orders kept
RIGHT JOIN customers c
    ON o.customer_id = c.customer_id;

-- ── WHEN TO USE FULL OUTER JOIN ───────────────────────────────
-- Use when you need ALL rows from BOTH sides regardless of matches.
-- Example use-case: finding products never ordered AND
--                   order_items referencing a deleted product.
--
-- MySQL emulation using UNION:

SELECT
    p.product_id,
    p.product_name,
    oi.item_id,
    oi.order_id
FROM products p
LEFT JOIN order_items oi  ON p.product_id = oi.product_id

UNION

SELECT
    p.product_id,
    p.product_name,
    oi.item_id,
    oi.order_id
FROM products p
RIGHT JOIN order_items oi ON p.product_id = oi.product_id;

/*
In this dataset:
  - product_id 202 (Cotton T-Shirt / Levis) appears in only 1 order.
  - product_id 208 (Cushion Covers) appears in 2 order_items.
  - All products appear at least once; no orphaned order_items.
  A FULL OUTER JOIN is most useful for data-audit or reconciliation
  queries where gaps on either side are meaningful.
*/


-- ============================================================
-- Q23. Foreign Key Relationships + Referential Integrity
-- ============================================================

-- ── FOREIGN KEY MAP ──────────────────────────────────────────
/*
  TABLE         COLUMN        REFERENCES
  ─────────     ──────────    ────────────────────────────────
  orders        customer_id → customers(customer_id)
  order_items   order_id    → orders(order_id)
  order_items   product_id  → products(product_id)

  Cascade rules: None defined — default RESTRICT behaviour applies.
  This means:
    INSERT/UPDATE violation → query is rejected immediately.
    DELETE of a parent row  → rejected if child rows exist.
*/

-- ── WHAT HAPPENS WITH customer_id = 999? ────────────────────
-- The following INSERT would be REJECTED by MySQL with an error:
-- ERROR 1452 (23000): Cannot add or update a child row:
-- a foreign key constraint fails
-- (`shopease`.`orders`, CONSTRAINT `orders_ibfk_1`
--  FOREIGN KEY (`customer_id`) REFERENCES `customers` (`customer_id`))

-- Demonstration (intentional failure — do NOT run without a
-- surrounding transaction/rollback if we want to keep data clean):

/*
INSERT INTO orders VALUES
(9999, 999, '2024-09-01', 'Pending', 500.00);
-- ↑ Fails because customer_id 999 does not exist in customers.
*/

-- ── SAFE DEMONSTRATION using a transaction ───────────────────
START TRANSACTION;

    INSERT INTO orders VALUES
    (9999, 999, '2024-09-01', 'Pending', 500.00);
    -- MySQL will raise ERROR 1452 here and the row is NOT inserted.

ROLLBACK;  -- Ensures no partial change is committed.

-- ── VERIFY: no orphan row was created ────────────────────────
SELECT * FROM orders WHERE order_id = 9999;  -- Expected: 0 rows

-- ── REFERENTIAL INTEGRITY SUMMARY ───────────────────────────
/*
  Referential integrity guarantees that:
  1. Every orders.customer_id must exist in customers.customer_id
  2. Every order_items.order_id must exist in orders.order_id
  3. Every order_items.product_id must exist in products.product_id

  Attempting to violate any of these constraints results in an
  immediate ERROR 1452, and the offending statement is rolled back.
  No partial data is ever written to the database.

  To INSERT an order for a new customer, you must first INSERT
  that customer into the customers table.
*/




-- ============================================================
--  END OF FILE: 03_section_d_joins.sql
