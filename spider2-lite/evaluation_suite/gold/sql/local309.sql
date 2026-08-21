WITH latest_driver_round AS (
    SELECT race.year, MAX(race.round) AS final_round
    FROM driver_standings AS standing
    JOIN races AS race ON standing.race_id = race.race_id
    GROUP BY race.year
),
final_driver_standings AS (
    SELECT
        race.year,
        standing.driver_id,
        standing.points,
        RANK() OVER (
            PARTITION BY race.year
            ORDER BY standing.points DESC
        ) AS points_rank
    FROM driver_standings AS standing
    JOIN races AS race ON standing.race_id = race.race_id
    JOIN latest_driver_round AS final
      ON race.year = final.year
     AND race.round = final.final_round
),
latest_constructor_round AS (
    SELECT race.year, MAX(race.round) AS final_round
    FROM constructor_standings AS standing
    JOIN races AS race ON standing.race_id = race.race_id
    GROUP BY race.year
),
final_constructor_standings AS (
    SELECT
        race.year,
        standing.constructor_id,
        standing.points,
        RANK() OVER (
            PARTITION BY race.year
            ORDER BY standing.points DESC
        ) AS points_rank
    FROM constructor_standings AS standing
    JOIN races AS race ON standing.race_id = race.race_id
    JOIN latest_constructor_round AS final
      ON race.year = final.year
     AND race.round = final.final_round
),
constructor_totals AS (
    SELECT
        race.year,
        result.constructor_id,
        SUM(result.points) AS points,
        RANK() OVER (
            PARTITION BY race.year
            ORDER BY SUM(result.points) DESC
        ) AS points_rank
    FROM results AS result
    JOIN races AS race ON result.race_id = race.race_id
    GROUP BY race.year, result.constructor_id
),
constructor_winners AS (
    SELECT year, constructor_id
    FROM final_constructor_standings
    WHERE points_rank = 1
    UNION ALL
    SELECT total.year, total.constructor_id
    FROM constructor_totals AS total
    WHERE total.points_rank = 1
      AND NOT EXISTS (
          SELECT 1
          FROM final_constructor_standings AS final
          WHERE final.year = total.year
      )
)
SELECT
    driver.year,
    person.forename || ' ' || person.surname AS driver_full_name,
    constructor.name AS constructor_name
FROM final_driver_standings AS driver
JOIN drivers AS person ON driver.driver_id = person.driver_id
JOIN constructor_winners AS winner ON driver.year = winner.year
JOIN constructors AS constructor
  ON winner.constructor_id = constructor.constructor_id
WHERE driver.points_rank = 1
ORDER BY driver.year, driver_full_name, constructor_name;
