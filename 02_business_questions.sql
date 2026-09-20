-- Q1: How many customers are in each city, and what is the average income?
SELECT 
    city,
    COUNT(*) AS total_customers,
    ROUND(AVG(monthly_income_pkr), 0) AS avg_income
FROM customers
GROUP BY city
ORDER BY total_customers DESC;

-- Q2: Which loan product has the highest default rate?

SELECT 
    product,
    COUNT(*) AS total_loans,
    SUM(CASE WHEN loan_status = 'DEFAULT' THEN 1 ELSE 0 END) AS total_defaults,
    ROUND(100 * SUM(CASE WHEN loan_status = 'DEFAULT' THEN 1 ELSE 0 END) / COUNT(*), 2) AS default_rate_pct
FROM loans
GROUP BY product
ORDER BY default_rate_pct DESC;

-- Q3: How does default rate change with debt-to-income ratio bands?

SELECT
    CASE
        WHEN (l.monthly_installment_pkr / c.monthly_income_pkr) < 0.20 THEN 'A. Under 20%'
        WHEN (l.monthly_installment_pkr / c.monthly_income_pkr) < 0.35 THEN 'B. 20-35%'
        WHEN (l.monthly_installment_pkr / c.monthly_income_pkr) < 0.50 THEN 'C. 35-50%'
        WHEN (l.monthly_installment_pkr / c.monthly_income_pkr) < 0.75 THEN 'D. 50-75%'
        ELSE 'E. Over 75%'
    END AS dti_band,
    COUNT(*) AS total_loans,
    ROUND(100.0 * SUM(CASE WHEN l.loan_status = 'DEFAULT' THEN 1 ELSE 0 END) / COUNT(*), 2) AS default_rate_pct
FROM loans l
JOIN customers c ON l.customer_id = c.customer_id
GROUP BY dti_band
ORDER BY dti_band;

-- Q4: Rank branches by total deposits within their own province
SELECT
    b.branch_name,
    b.city,
    b.province,
    ROUND(SUM(a.current_balance_pkr), 0) AS total_deposits,
    RANK() OVER (PARTITION BY b.province ORDER BY SUM(a.current_balance_pkr) DESC) AS rank_in_province
FROM branches b
JOIN accounts a ON a.branch_id = b.branch_id
WHERE a.status = 'ACTIVE'
GROUP BY b.branch_id, b.branch_name, b.city, b.province
ORDER BY b.province, rank_in_province;

-- Q5: What share of total deposits does the top 10% of customers hold?

WITH customer_totals AS (
    SELECT
        c.customer_id,
        SUM(a.current_balance_pkr) AS total_balance
    FROM customers c
    JOIN accounts a ON a.customer_id = c.customer_id
    WHERE a.status = 'ACTIVE'
    GROUP BY c.customer_id
),
ranked AS (
    SELECT
        total_balance,
        NTILE(10) OVER (ORDER BY total_balance DESC) AS decile
    FROM customer_totals
)
SELECT
    decile,
    COUNT(*) AS customers,
    ROUND(SUM(total_balance), 0) AS total_deposits,
    ROUND(100.0 * SUM(total_balance) / SUM(SUM(total_balance)) OVER (), 1) AS pct_of_all_deposits
FROM ranked
GROUP BY decile
ORDER BY decile;

-- Q6: Which channel handles the most transaction volume and value?
SELECT
    channel,
    COUNT(*) AS txn_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_volume,
    ROUND(SUM(amount_pkr_capped), 0) AS total_value,
    ROUND(AVG(amount_pkr_capped), 0) AS avg_ticket_size
FROM transactions
GROUP BY channel
ORDER BY txn_count DESC;


-- Q7: How many deposit customers have never taken a loan? (cross-sell gap)
SELECT
    c.occupation,
    COUNT(DISTINCT c.customer_id) AS total_customers,
    COUNT(DISTINCT l.customer_id) AS customers_with_loan,
    COUNT(DISTINCT c.customer_id) - COUNT(DISTINCT l.customer_id) AS no_loan_customers,
    ROUND(100.0 * (COUNT(DISTINCT c.customer_id) - COUNT(DISTINCT l.customer_id)) / COUNT(DISTINCT c.customer_id), 1) AS pct_no_loan
FROM customers c
LEFT JOIN loans l ON l.customer_id = c.customer_id
GROUP BY c.occupation
ORDER BY pct_no_loan DESC;

-- Q8: How is total transaction value trending month over month?
SELECT
    DATE_FORMAT(transaction_date, '%Y-%m') AS txn_month,
    ROUND(SUM(amount_pkr_capped), 0) AS monthly_value,
    ROUND(100.0 * (SUM(amount_pkr_capped) - LAG(SUM(amount_pkr_capped)) OVER (ORDER BY DATE_FORMAT(transaction_date, '%Y-%m'))) 
          / LAG(SUM(amount_pkr_capped)) OVER (ORDER BY DATE_FORMAT(transaction_date, '%Y-%m')), 1) AS mom_growth_pct
FROM transactions
GROUP BY txn_month
ORDER BY txn_month;

-- Q9: How many days since each customer's last transaction? (recency check)
SELECT
    c.customer_id,
    c.city,
    MAX(t.transaction_date) AS last_transaction_date,
    DATEDIFF('2026-01-01', MAX(t.transaction_date)) AS days_since_last_txn
FROM customers c
JOIN accounts a ON a.customer_id = c.customer_id
JOIN transactions t ON t.account_id = a.account_id
GROUP BY c.customer_id, c.city
ORDER BY days_since_last_txn DESC
LIMIT 20;


-- Q10: What is the 3-month rolling average of transaction value?
WITH monthly AS (
    SELECT
        DATE_FORMAT(transaction_date, '%Y-%m') AS txn_month,
        SUM(amount_pkr_capped) AS monthly_value
    FROM transactions
    GROUP BY txn_month
)
SELECT
    txn_month,
    ROUND(monthly_value, 0) AS monthly_value,
    ROUND(AVG(monthly_value) OVER (ORDER BY txn_month ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 0) AS rolling_3m_avg
FROM monthly
ORDER BY txn_month;


-- Q11: Does branch tier relate to loan default rate?
SELECT
    b.branch_tier,
    COUNT(DISTINCT l.loan_id) AS total_loans,
    ROUND(100.0 * SUM(CASE WHEN l.loan_status = 'DEFAULT' THEN 1 ELSE 0 END) / COUNT(DISTINCT l.loan_id), 2) AS default_rate_pct,
    ROUND(AVG(l.credit_utilisation), 3) AS avg_credit_utilisation
FROM branches b
JOIN accounts a ON a.branch_id = b.branch_id
JOIN loans l ON l.customer_id = a.customer_id
GROUP BY b.branch_tier
ORDER BY default_rate_pct DESC;