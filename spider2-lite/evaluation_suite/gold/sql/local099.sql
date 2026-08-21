WITH yash_chopra AS (
    SELECT DISTINCT TRIM(PID) AS director_id
    FROM Person
    WHERE TRIM(Name) = 'Yash Chopra'
),
actor_director_movies AS (
    SELECT
        TRIM(actor_cast.PID) AS actor_id,
        TRIM(director.PID) AS director_id,
        COUNT(DISTINCT actor_cast.MID) AS movie_count
    FROM M_Cast AS actor_cast
    JOIN M_Director AS director ON actor_cast.MID = director.MID
    GROUP BY TRIM(actor_cast.PID), TRIM(director.PID)
),
actor_collaboration_stats AS (
    SELECT
        collaboration.actor_id,
        MAX(
            CASE
                WHEN collaboration.director_id = yash.director_id
                    THEN collaboration.movie_count
            END
        ) AS yash_chopra_movies,
        MAX(
            CASE
                WHEN collaboration.director_id <> yash.director_id
                    THEN collaboration.movie_count
            END
        ) AS other_director_movies
    FROM actor_director_movies AS collaboration
    CROSS JOIN yash_chopra AS yash
    GROUP BY collaboration.actor_id
)
SELECT COUNT(*) AS num_actors
FROM actor_collaboration_stats
WHERE yash_chopra_movies > COALESCE(other_director_movies, 0);
