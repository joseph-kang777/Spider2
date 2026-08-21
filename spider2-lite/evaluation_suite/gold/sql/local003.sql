WITH customer_totals AS (
    SELECT
        customer.customer_unique_id,
        MAX(orders.order_purchase_timestamp) AS last_purchase,
        COUNT(DISTINCT orders.order_id) AS total_orders,
        SUM(item.price) AS total_spent
    FROM orders
    JOIN customers AS customer USING (customer_id)
    JOIN order_items AS item USING (order_id)
    WHERE orders.order_status = 'delivered'
    GROUP BY customer.customer_unique_id
),
rfm_scores AS (
    SELECT
        customer_unique_id,
        total_orders,
        total_spent,
        NTILE(5) OVER (
            ORDER BY last_purchase DESC, customer_unique_id
        ) AS recency,
        NTILE(5) OVER (
            ORDER BY total_orders DESC, customer_unique_id
        ) AS frequency,
        NTILE(5) OVER (
            ORDER BY total_spent DESC, customer_unique_id
        ) AS monetary
    FROM customer_totals
),
rfm AS (
    SELECT
        total_orders,
        total_spent,
        CASE
            WHEN recency = 1 AND frequency + monetary BETWEEN 1 AND 4
                THEN 'Champions'
            WHEN recency IN (4, 5) AND frequency + monetary BETWEEN 1 AND 2
                THEN 'Can''t Lose Them'
            WHEN recency IN (4, 5) AND frequency + monetary BETWEEN 3 AND 6
                THEN 'Hibernating'
            WHEN recency IN (4, 5) AND frequency + monetary BETWEEN 7 AND 10
                THEN 'Lost'
            WHEN recency IN (2, 3) AND frequency + monetary BETWEEN 1 AND 4
                THEN 'Loyal Customers'
            WHEN recency = 3 AND frequency + monetary BETWEEN 5 AND 6
                THEN 'Needs Attention'
            WHEN recency = 1 AND frequency + monetary BETWEEN 7 AND 8
                THEN 'Recent Users'
            WHEN (recency = 1 AND frequency + monetary BETWEEN 5 AND 6)
              OR (recency = 2 AND frequency + monetary BETWEEN 5 AND 8)
                THEN 'Potential Loyalists'
            WHEN recency = 1 AND frequency + monetary BETWEEN 9 AND 10
                THEN 'Price Sensitive'
            WHEN recency = 2 AND frequency + monetary BETWEEN 9 AND 10
                THEN 'Promising'
            WHEN recency = 3 AND frequency + monetary BETWEEN 7 AND 10
                THEN 'About to Sleep'
        END AS rfm_segment
    FROM rfm_scores
)
SELECT
    rfm_segment,
    AVG(total_spent / total_orders) AS avg_sales_per_customer
FROM rfm
WHERE rfm_segment IS NOT NULL
GROUP BY rfm_segment
ORDER BY rfm_segment;
