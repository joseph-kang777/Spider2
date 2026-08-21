WITH RECURSIVE
delivered_pizzas AS (
    SELECT
        customer.rowid AS pizza_line_id,
        customer.pizza_id,
        customer.exclusions,
        customer.extras
    FROM pizza_clean_customer_orders AS customer
    JOIN pizza_clean_runner_orders AS runner
      ON customer.order_id = runner.order_id
    WHERE runner.cancellation IS NULL
),
recipe_parts(pizza_id, topping_id, remaining) AS (
    SELECT
        pizza_id,
        TRIM(SUBSTR(toppings, 1, INSTR(toppings || ',', ',') - 1)),
        SUBSTR(toppings || ',', INSTR(toppings || ',', ',') + 1)
    FROM pizza_recipes
    UNION ALL
    SELECT
        pizza_id,
        TRIM(SUBSTR(remaining, 1, INSTR(remaining, ',') - 1)),
        SUBSTR(remaining, INSTR(remaining, ',') + 1)
    FROM recipe_parts
    WHERE remaining <> ''
),
exclusion_parts(pizza_line_id, topping_id, remaining) AS (
    SELECT
        pizza_line_id,
        TRIM(SUBSTR(exclusions, 1, INSTR(exclusions || ',', ',') - 1)),
        SUBSTR(exclusions || ',', INSTR(exclusions || ',', ',') + 1)
    FROM delivered_pizzas
    WHERE exclusions IS NOT NULL AND TRIM(exclusions) <> ''
    UNION ALL
    SELECT
        pizza_line_id,
        TRIM(SUBSTR(remaining, 1, INSTR(remaining, ',') - 1)),
        SUBSTR(remaining, INSTR(remaining, ',') + 1)
    FROM exclusion_parts
    WHERE remaining <> ''
),
extra_parts(pizza_line_id, topping_id, remaining) AS (
    SELECT
        pizza_line_id,
        TRIM(SUBSTR(extras, 1, INSTR(extras || ',', ',') - 1)),
        SUBSTR(extras || ',', INSTR(extras || ',', ',') + 1)
    FROM delivered_pizzas
    WHERE extras IS NOT NULL AND TRIM(extras) <> ''
    UNION ALL
    SELECT
        pizza_line_id,
        TRIM(SUBSTR(remaining, 1, INSTR(remaining, ',') - 1)),
        SUBSTR(remaining, INSTR(remaining, ',') + 1)
    FROM extra_parts
    WHERE remaining <> ''
),
used_ingredients AS (
    SELECT pizza.pizza_line_id, recipe.topping_id
    FROM delivered_pizzas AS pizza
    JOIN recipe_parts AS recipe ON pizza.pizza_id = recipe.pizza_id
    WHERE NOT EXISTS (
        SELECT 1
        FROM exclusion_parts AS exclusion
        WHERE exclusion.pizza_line_id = pizza.pizza_line_id
          AND exclusion.topping_id = recipe.topping_id
    )
    UNION ALL
    SELECT pizza_line_id, topping_id
    FROM extra_parts
)
SELECT
    topping.topping_name,
    COUNT(*) AS total_quantity
FROM used_ingredients AS ingredient
JOIN pizza_toppings AS topping
  ON ingredient.topping_id = topping.topping_id
GROUP BY topping.topping_id, topping.topping_name
ORDER BY topping.topping_name;
