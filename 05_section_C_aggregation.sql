-- ============================================================
--  CEI Summer Internship 2026 | Week 2 | ShopEase Database
--  FILE: section_c_aggregation.sql
--  Section C — Aggregation (GROUP BY, SUM, COUNT, AVG, MIN, MAX)

USE shopease;

-- ------------------------------------------------------------
-- Q13. Count the total number of orders in the orders table.

SELECT
    COUNT(*) AS total_orders
FROM orders;


/* Expected Output
| total_orders |
+--------------+
|      10      |

*/


-- ------------------------------------------------------------
-- Q14. Find the total revenue (SUM of total_amount) from all 'Delivered' orders.

SELECT
    SUM(total_amount) AS total_delivered_revenue
FROM orders
WHERE status = 'Delivered';


-- ------------------------------------------------------------
-- Q15. Calculate the average unit_price of products in each category.

SELECT
    category,
    ROUND(AVG(unit_price), 2) AS avg_unit_price
FROM products
GROUP BY category;
/*
Expected Output:


| category    | avg_unit_price |
|-------------|----------------|
| Clothing    |    2699.00     |
| Electronics |    2224.67     |
| Home        |     949.00     |

*/

-- ------------------------------------------------------------
-- Q16. For each order status, find the count of orders and the total revenue. Sort the result by total revenue in descending order.

SELECT
    status,
    COUNT(order_id)      AS order_count,
    SUM(total_amount)    AS total_revenue
FROM orders
GROUP BY status
ORDER BY total_revenue DESC;
/*
Expected Output:


| status    | order_count | total_revenue |
+-----------+-------------+---------------+
| Delivered |      6      |    17191.00   |
| Shipped   |      2      |    13596.00   |
| Pending   |      1      |     2999.00    |
| Cancelled |      1      |     1299.00   |

*/

-- ------------------------------------------------------------
-- Q17. Find the most expensive (MAX) and cheapest (MIN) product in each category.

SELECT
    category,
    MAX(unit_price) AS most_expensive,
    MIN(unit_price) AS cheapest
FROM products
GROUP BY category;
/*
Expected Output:


| category    | most_expensive_product_price | cheapest_product_price |
+-------------+------------------------------+-------------------------+
| Clothing    |            4599.00            |          799.00       |
| Electronics |            3499.00             |         899.00         |
| Home        |            1299.00            |          599.00       |

*/


-- ------------------------------------------------------------
-- Q18. List all product categories where the average unit_price is greater than ₹2000.
SELECT
    category,
    ROUND(AVG(unit_price), 2) AS avg_unit_price
FROM products
GROUP BY category
HAVING AVG(unit_price) > 2000;


/*
Expected Output:


| category    | avg_unit_price |
+-------------+----------------+
| Clothing 	|    2699.00      |
| Electronics |    2224.00	  |

*/



-- END OF FILE
-- ============================================================