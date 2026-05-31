-- ============================================================
--  CEI Summer Internship 2026 | Week 2 | ShopEase Database
--  FILE: Section_E_Advanced_Concepts.sql
--  Section E — Advanced Concepts (CASE, ACID, Transactions)

USE shopease;

-- ============================================================
-- Q24. Classify products into price tiers using CASE

-- Logic:
--   'Budget'    → unit_price < 1000
--   'Mid-Range' → unit_price BETWEEN 1000 AND 3000
--   'Premium'   → unit_price > 3000
-- Display: product_name, unit_price, price_tier

SELECT
    product_name,
    unit_price,
    CASE
        WHEN unit_price < 1000               THEN 'Budget'
        WHEN unit_price BETWEEN 1000 AND 3000 THEN 'Mid-Range'
        WHEN unit_price > 3000               THEN 'Premium'
    END AS price_tier
FROM products
ORDER BY unit_price ASC;

/*
Expected Output:
+----------------------+------------+------------+
| product_name         | unit_price | price_tier |
+----------------------+------------+------------+
| Cushion Covers (Set) |     599.00 | Budget     |
| Cotton T-Shirt       |     799.00 | Budget     |
| Laptop Stand         |     899.00 | Budget     |
| Wireless Earbuds     |    1499.00 | Mid-Range  |
| Bedsheet Set         |    1299.00 | Mid-Range  |
| Smart Watch          |    2999.00 | Mid-Range  |
| Bluetooth Speaker    |    3499.00 | Premium    |
| Running Shoes        |    4599.00 | Premium    |
+----------------------+------------+------------+
8 rows in set
*/


-- ============================================================
-- Q25. Count Delivered vs Not Delivered orders in a single row using CASE inside an aggregate function

-- Logic:
--   'Delivered'     → status = 'Delivered'
--   'Not Delivered' → all other statuses (Pending, Shipped, Cancelled)

SELECT
    SUM(CASE WHEN status = 'Delivered' THEN 1 ELSE 0 END) AS delivered_count,
    SUM(CASE WHEN status != 'Delivered' THEN 1 ELSE 0 END) AS not_delivered_count
FROM orders;

/*
Expected Output:
+-----------------+---------------------+
| delivered_count | not_delivered_count |
+-----------------+---------------------+
|               6 |                   4 |
+-----------------+---------------------+
1 row in set

Breakdown of the 4 "Not Delivered":
  - Shipped   : order_id 1003, 1009
  - Cancelled : order_id 1005
  - Pending   : order_id 1007
*/


-- ============================================================
-- Q26. ACID Properties — Explanation with Real-World Example

/*
ACID stands for the four key properties that guarantee reliable database transactions. 
 Using a BANK TRANSFER as the example:
(Transferring ₹5,000 from Aarav's account to Priya's account)

--------------------------------------------------------------
A — ATOMICITY
--------------------------------------------------------------
Definition:
  A transaction is treated as a single, indivisible unit.
  Either ALL operations within it succeed, or NONE of them do.
  There is no partial completion — it's all or nothing.

Bank Transfer Example:
  Step 1: Debit ₹5,000 from Aarav's account
  Step 2: Credit ₹5,000 to Priya's account

  If Step 1 succeeds but Step 2 fails (e.g., server crash),
  without Atomicity Aarav would lose ₹5,000 and Priya gets nothing.
  With Atomicity, the entire transaction is ROLLED BACK —
  Aarav's account is restored and no money is lost.

--------------------------------------------------------------
C — CONSISTENCY
--------------------------------------------------------------
Definition:
  A transaction brings the database from one valid state to
  another valid state, always respecting all defined rules,
  constraints, and data integrity requirements.

Bank Transfer Example:
  Business Rule: Total money in the banking system must remain
  the same before and after the transfer.

  Before: Aarav = ₹10,000 | Priya = ₹2,000 | Total = ₹12,000
  After:  Aarav = ₹5,000  | Priya = ₹7,000 | Total = ₹12,000

  Consistency ensures the total never becomes ₹7,000 or ₹17,000.
  It also enforces constraints like "balance cannot go below ₹0",
  rejecting the transaction if Aarav had insufficient funds.

--------------------------------------------------------------
I — ISOLATION
--------------------------------------------------------------
Definition:
  Concurrent transactions execute as if they were running
  serially (one after another). Intermediate states of a
  transaction are invisible to other transactions.

Bank Transfer Example:
  At the same moment, two transactions run simultaneously:
  T1: Transfer ₹5,000 from Aarav to Priya
  T2: Check Aarav's balance (for a loan eligibility query)

  Without Isolation, T2 might read Aarav's balance AFTER the
  debit but BEFORE the credit completes — seeing an inconsistent
  "in-between" state, potentially leading to wrong decisions.

  With Isolation, T2 either sees the full before-state or the
  full after-state of T1, never a partial one.

--------------------------------------------------------------
D — DURABILITY
--------------------------------------------------------------
Definition:
  Once a transaction is committed, its changes are permanently
  saved — even in the event of a system crash, power failure,
  or hardware failure. Committed data is written to persistent
  storage (disk), not just RAM.

Bank Transfer Example:
  The transfer completes successfully and the system shows
  "Transaction Successful". One second later, the server
  experiences a power outage.

  Without Durability, the committed transaction could be lost
  and the accounts revert to their old balances.
  With Durability, when the server restarts, the transaction
  log (WAL — Write Ahead Log) replays the committed changes
  and both account balances reflect the transfer correctly.
*/


-- ============================================================
-- Q27. Full Transaction Block — New Order with Items & Stock Update

-- Steps:
--   1. Insert new order (order_id=1011, customer_id=102, today, 'Pending', 1598.00)
--   2. Insert two order_items for that order
--      (Bedsheet Set × 1 @ 1299.00 and Cushion Covers × 1 @ 599.00, no discount for simplicity;
--       but to reflect the stored total_amount of 1598.00:
--       Bedsheet Set product_id=206, Cushion Covers product_id=208)
--   3. Reduce stock_qty for both products
--   4. ROLLBACK on any failure; COMMIT if all succeed

-- ============================================================
-- Pre-Transaction State (run to verify before):
-- SELECT product_id, product_name, stock_qty FROM products WHERE product_id IN (206, 208);
-- Expected: product_id=206 stock=300, product_id=208 stock=400
-- ============================================================

-- MySQL approach using SAVEPOINT and error handling via a stored procedure pattern.
-- For standard MySQL session-based transaction (suitable for MySQL Workbench / CLI):

START TRANSACTION;

-- Step 1: Insert the new order
INSERT INTO orders (order_id, customer_id, order_date, status, total_amount)
VALUES (1011, 102, CURDATE(), 'Pending', 1598.00);

-- Step 2a: Insert first order item — Bedsheet Set (product_id=206), qty=1, price=1299.00
INSERT INTO order_items (item_id, order_id, product_id, quantity, unit_price, discount_pct)
VALUES (5016, 1011, 206, 1, 1299.00, 0);

-- Step 2b: Insert second order item — Cushion Covers (product_id=208), qty=1, price=599.00
INSERT INTO order_items (item_id, order_id, product_id, quantity, unit_price, discount_pct)
VALUES (5017, 1011, 208, 1, 599.00, 0);

-- Step 3a: Deduct stock for Bedsheet Set (qty purchased = 1)
UPDATE products
SET stock_qty = stock_qty - 1
WHERE product_id = 206;

-- Step 3b: Deduct stock for Cushion Covers (qty purchased = 1)
UPDATE products
SET stock_qty = stock_qty - 1
WHERE product_id = 208;

-- Step 4: If all steps succeeded — COMMIT the transaction
COMMIT;

-- If any step had failed (FK violation, duplicate PK, CHECK constraint breach, etc.)
-- you would run the following instead of COMMIT:
-- ROLLBACK;

/*
NOTE — How ROLLBACK would be triggered automatically in application code --->
In real applications (Python, Java, Node.js), the transaction block is
wrapped in a try/catch:

  try:
      cursor.execute("START TRANSACTION")
      cursor.execute("INSERT INTO orders ...")
      cursor.execute("INSERT INTO order_items ...") -- item 1
      cursor.execute("INSERT INTO order_items ...") -- item 2
      cursor.execute("UPDATE products SET stock_qty ...")
      cursor.execute("UPDATE products SET stock_qty ...")
      connection.commit()    -- all good → COMMIT
  except Exception as e:
      connection.rollback()  -- any error → ROLLBACK
      print(f"Transaction failed: {e}")

In MySQL stored procedures, DECLARE ... HANDLER FOR SQLEXCEPTION is used
to catch errors and trigger ROLLBACK automatically inside the procedure.
*/

-- ============================================================
-- Post-Transaction Verification Queries
-- ============================================================

-- Verify the new order was inserted
SELECT * FROM orders WHERE order_id = 1011;
/*
Expected Output:
+----------+-------------+------------+---------+--------------+
| order_id | customer_id | order_date | status  | total_amount |
+----------+-------------+------------+---------+--------------+
|     1011 |         102 | 2026-05-31 | Pending |      1598.00 |
+----------+-------------+------------+---------+--------------+
*/

-- Verify the two order items were inserted
SELECT * FROM order_items WHERE order_id = 1011;
/*
Expected Output:
+---------+----------+------------+----------+------------+--------------+
| item_id | order_id | product_id | quantity | unit_price | discount_pct |
+---------+----------+------------+----------+------------+--------------+
|    5016 |     1011 |        206 |        1 |    1299.00 |         0.00 |
|    5017 |     1011 |        208 |        1 |     599.00 |         0.00 |
+---------+----------+------------+----------+------------+--------------+
*/

-- Verify stock was reduced for both products
SELECT product_id, product_name, stock_qty FROM products WHERE product_id IN (206, 208);
/*
Expected Output (stock reduced by 1 each):
+------------+----------------------+-----------+
| product_id | product_name         | stock_qty |
+------------+----------------------+-----------+
|        206 | Bedsheet Set         |       299 |  -- was 300
|        208 | Cushion Covers (Set) |       399 |  -- was 400
+------------+----------------------+-----------+
*/

-- ============================================================
--  END OF SECTION E
-- ============================================================