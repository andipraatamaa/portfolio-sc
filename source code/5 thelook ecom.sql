-- Question 5 Monthly Groth Analysis
WITH monthly_inventory AS (
  SELECT
    DATE_TRUNC(DATE(i.created_at), MONTH) AS month,
    p.category,
    COUNT(i.id) AS inventory_count
  FROM
    `fsda-sql-01.TheLook_Ecommerce.inventory_items` i
  INNER JOIN
    `fsda-sql-01.TheLook_Ecommerce.products` p
  ON
    i.product_id = p.id
  GROUP BY
    month, p.category
),
previous_month_inventory AS (
  SELECT
    month,
    category,
    LAG(inventory_count) OVER (PARTITION BY category ORDER BY month) AS previous_inventory_count
  FROM
    monthly_inventory
)

SELECT
  mi.month,
  mi.category,
  mi.inventory_count,
  pmi.previous_inventory_count,
  IFNULL(ROUND(((mi.inventory_count - IFNULL(pmi.previous_inventory_count, 0)) / NULLIF(pmi.previous_inventory_count, 0) * 100), 2), 0) AS growth_percentage
FROM
  monthly_inventory mi
LEFT JOIN
  previous_month_inventory pmi
ON
  mi.category = pmi.category AND mi.month = DATE_ADD(pmi.month, INTERVAL 1 MONTH)
ORDER BY
  mi.month DESC, mi.category;



-- QUESTION 6 CORHORT
WITH first_purchase AS (
  SELECT
    user_id,
    MIN(DATE(created_at)) AS first_purchase_date
  FROM
    `fsda-sql-01.TheLook_Ecommerce.orders`
  GROUP BY
    user_id
),
monthly_purchases AS (
  SELECT
    o.user_id,
    DATE_TRUNC(DATE(o.created_at), MONTH) AS purchase_month,
    fp.first_purchase_date
  FROM
    `fsda-sql-01.TheLook_Ecommerce.orders` o
  JOIN
    first_purchase fp ON o.user_id = fp.user_id
),
cohorts AS (
  SELECT
    first_purchase_date,
    purchase_month,
    COUNT(DISTINCT user_id) AS user_count
  FROM
    monthly_purchases
  GROUP BY
    first_purchase_date, purchase_month
),
retention AS (
  SELECT
    first_purchase_date,
    purchase_month,
    user_count,
    LEAD(user_count) OVER (PARTITION BY first_purchase_date ORDER BY purchase_month) AS next_month_user_count
  FROM
    cohorts
),
retention_rates AS (
  SELECT
    first_purchase_date,
    purchase_month,
    user_count,
    next_month_user_count,
    IFNULL(ROUND((next_month_user_count / NULLIF(user_count, 0) * 100), 2), 0) AS retention_rate
  FROM
    retention
)
SELECT
  *,
  CASE
    WHEN purchase_month = first_purchase_date THEN 'Initial Purchase'
    ELSE 'Returning User'
  END AS cohort_type
FROM
  retention_rates
ORDER BY
  first_purchase_date, purchase_month;

-- QUESTION 6 
WITH first_purchase AS (
  SELECT
    user_id,
    MIN(DATE(created_at)) AS first_purchase_date
  FROM
    `fsda-sql-01.TheLook_Ecommerce.orders`
  GROUP BY
    user_id
),
monthly_purchases AS (
  SELECT
    o.user_id,
    DATE_TRUNC(DATE(o.created_at), MONTH) AS purchase_month,
    fp.first_purchase_date
  FROM
    `fsda-sql-01.TheLook_Ecommerce.orders` o
  JOIN
    first_purchase fp ON o.user_id = fp.user_id
),
cohorts AS (
  SELECT
    first_purchase_date,
    purchase_month,
    COUNT(DISTINCT user_id) AS user_count
  FROM
    monthly_purchases
  GROUP BY
    first_purchase_date, purchase_month
),
retention AS (
  SELECT
    first_purchase_date,
    purchase_month,
    user_count,
    LEAD(user_count) OVER (PARTITION BY first_purchase_date ORDER BY purchase_month) AS next_month_user_count
  FROM
    cohorts
),
retention_rates AS (
  SELECT
    first_purchase_date,
    purchase_month,
    user_count,
    next_month_user_count,
    IFNULL(ROUND((next_month_user_count / NULLIF(user_count, 0) * 100), 2), 0) AS retention_rate
  FROM
    retention
)
SELECT
  *,
  CASE
    WHEN purchase_month = first_purchase_date THEN 'Initial Purchase'
    ELSE 'Returning User'
  END AS cohort_type
FROM
  retention_rates
ORDER BY
  first_purchase_date, purchase_month;
