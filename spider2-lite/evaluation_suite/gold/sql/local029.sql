WITH customer_locations AS (
    SELECT
        customer.customer_unique_id,
        customer.customer_city,
        customer.customer_state,
        COUNT(DISTINCT orders.order_id) AS location_order_count,
        SUM(payment.payment_value) AS location_payment_total,
        MAX(orders.order_purchase_timestamp) AS latest_order
    FROM olist_customers AS customer
    JOIN olist_orders AS orders ON customer.customer_id = orders.customer_id
    JOIN olist_order_payments AS payment ON orders.order_id = payment.order_id
    WHERE orders.order_status = 'delivered'
    GROUP BY
        customer.customer_unique_id,
        customer.customer_city,
        customer.customer_state
),
ranked_locations AS (
    SELECT
        customer_unique_id,
        customer_city,
        customer_state,
        SUM(location_order_count) OVER (
            PARTITION BY customer_unique_id
        ) AS delivered_orders,
        SUM(location_payment_total) OVER (
            PARTITION BY customer_unique_id
        ) / SUM(location_order_count) OVER (
            PARTITION BY customer_unique_id
        ) AS avg_payment_value,
        ROW_NUMBER() OVER (
            PARTITION BY customer_unique_id
            ORDER BY
                location_order_count DESC,
                latest_order DESC,
                customer_city,
                customer_state
        ) AS location_rank
    FROM customer_locations
)
SELECT
    customer_unique_id,
    delivered_orders,
    avg_payment_value,
    customer_city,
    customer_state
FROM ranked_locations
WHERE location_rank = 1
ORDER BY delivered_orders DESC, customer_unique_id
LIMIT 3;
