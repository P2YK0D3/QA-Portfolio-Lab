-- ====================================================================
-- QA DATABASE VERIFICATION EXERCISE
-- Target Schema: E-Commerce Orders, Items & Payments
-- ====================================================================

-- 1. CLEANUP PREVIOUS TABLES
DROP TABLE IF EXISTS payments;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS users;

-- 2. CREATE SCHEMAS
CREATE TABLE users (
    user_id INTEGER PRIMARY KEY,
    username VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE orders (
    order_id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    order_number VARCHAR(30) UNIQUE NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL, -- PENDING, COMPLETED, CANCELLED
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE payments (
    payment_id INTEGER PRIMARY KEY,
    order_id INTEGER NOT NULL,
    transaction_ref VARCHAR(64) NOT NULL,
    amount DECIMAL(10, 2) NOT NULL,
    payment_status VARCHAR(20) NOT NULL, -- SUCCESS, FAILED
    processed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

-- 3. INSERT REALISTIC TEST DATA
INSERT INTO users (user_id, username, email, status) VALUES
(101, 'alex_tester', 'alex.qa@example.com', 'ACTIVE'),
(102, 'maria_dev', 'maria.dev@example.com', 'ACTIVE'),
(103, 'ghost_user', 'ghost@example.com', 'PENDING');

INSERT INTO orders (order_id, user_id, order_number, total_amount, status) VALUES
(5001, 101, 'ORD-2026-001', 129.99, 'COMPLETED'),
(5002, 101, 'ORD-2026-002', 45.00,  'COMPLETED'),
(5003, 102, 'ORD-2026-003', 250.00, 'PENDING');

-- Notice order 5001 has TWO payment records inserted (simulating an idempotency double-charge bug)
INSERT INTO payments (payment_id, order_id, transaction_ref, amount, payment_status) VALUES
(9001, 5001, 'tx_live_981a', 129.99, 'SUCCESS'),
(9002, 5001, 'tx_live_981b', 129.99, 'SUCCESS'), -- DUPLICATE CHARGE BUG
(9003, 5002, 'tx_live_982c', 45.00,  'SUCCESS');
-- ====================================================================
-- QA TEST QUERY 1: Basic Verification (Data Presence & State)
-- Objective: Confirm user registration marked the account ACTIVE.
-- ====================================================================
SELECT user_id, username, email, status
FROM users
WHERE email = 'alex.qa@example.com';
-- Expected: Exactly 1 row returned with status = 'ACTIVE'.


-- ====================================================================
-- QA TEST QUERY 2: Multi-Table Relational Integrity (3-Table JOIN)
-- Objective: Confirm that every COMPLETED order has an associated user and payment.
-- ====================================================================
SELECT
    u.username,
    u.email,
    o.order_number,
    o.total_amount AS order_total,
    o.status AS order_status,
    p.transaction_ref,
    p.amount AS amount_paid,
    p.payment_status
FROM orders o
JOIN users u ON o.user_id = u.user_id
JOIN payments p ON o.order_id = p.order_id
WHERE o.status = 'COMPLETED';


-- ====================================================================
-- QA TEST QUERY 3: Catching Financial Integrity Bugs (Duplicate Payments)
-- Objective: Find any order that was billed more than once.
-- ====================================================================
SELECT
    order_id,
    COUNT(payment_id) AS total_transactions,
    SUM(amount) AS total_billed
FROM payments
WHERE payment_status = 'SUCCESS'
GROUP BY order_id
HAVING COUNT(payment_id) > 1;
-- QA Result: Returns order_id 5001 with total_transactions = 2 (CONFIRMS BUG-SOFT-001!).


-- ====================================================================
-- QA TEST QUERY 4: Finding Orphaned Records (LEFT JOIN check)
-- Objective: Detect orders stuck in PENDING with no recorded payment attempt.
-- ====================================================================
SELECT
    o.order_id,
    o.order_number,
    o.total_amount,
    o.status
FROM orders o
LEFT JOIN payments p ON o.order_id = p.order_id
WHERE p.payment_id IS NULL;
-- QA Result: Returns order 5003 (Identifies abandoned or unpaid carts).
