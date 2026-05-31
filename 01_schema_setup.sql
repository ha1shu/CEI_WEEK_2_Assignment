--  CEI Summer Internship 2026 | Week 2 | ShopEase Database
--  FILE: 01_schema_setup.sql
-- ============================================================

-- Step 1: Create and select the database
CREATE DATABASE IF NOT EXISTS shopease;
USE shopease;

-- ============================================================
-- TABLE 1: customers

CREATE TABLE customers (
    customer_id   INT           PRIMARY KEY,
    first_name    VARCHAR(50)   NOT NULL,
    last_name     VARCHAR(50)   NOT NULL,
    email         VARCHAR(100)  UNIQUE NOT NULL,
    city          VARCHAR(50)   NOT NULL,
    state         VARCHAR(50)   NOT NULL,
    join_date     DATE          NOT NULL,
    is_premium    BOOLEAN       DEFAULT FALSE
);

-- Index for filtering by city/state
CREATE INDEX idx_customers_city ON customers(city);
CREATE INDEX idx_customers_state ON customers(state);

-- ============================================================
-- TABLE 2: products

CREATE TABLE products (
    product_id    INT           PRIMARY KEY,
    product_name  VARCHAR(100)  NOT NULL,
    category      VARCHAR(50)   NOT NULL,
    brand         VARCHAR(50)   NOT NULL,
    unit_price    DECIMAL(10,2) NOT NULL  CHECK (unit_price > 0),
    stock_qty     INT           NOT NULL  DEFAULT 0  CHECK (stock_qty >= 0)
);

-- Index for filtering by category
CREATE INDEX idx_products_category ON products(category);



-- ============================================================
-- TABLE 3: orders
CREATE TABLE orders (
    order_id      INT           PRIMARY KEY,
    customer_id   INT           NOT NULL,
    order_date    DATE          NOT NULL,
    status        VARCHAR(20)   NOT NULL  DEFAULT 'Pending'
                  CHECK (status IN ('Pending','Shipped','Delivered','Cancelled')),
    total_amount  DECIMAL(12,2) NOT NULL  CHECK (total_amount >= 0),
    
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Index for date-based filtering and sorting
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_status ON orders(status);


-- ============================================================
-- TABLE 4: order_items
CREATE TABLE order_items (
    item_id       INT           PRIMARY KEY,
    order_id      INT           NOT NULL,
    product_id    INT           NOT NULL,
    quantity      INT           NOT NULL  CHECK (quantity > 0),
    unit_price    DECIMAL(10,2) NOT NULL  CHECK (unit_price > 0),
    discount_pct  DECIMAL(5,2)  DEFAULT 0 CHECK (discount_pct BETWEEN 0 AND 100),

    FOREIGN KEY (order_id)   REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);


SHOW TABLES;