WITH team_results AS (
    SELECT
        match.league_id,
        match.home_team_api_id AS team_api_id,
        CASE
            WHEN match.home_team_goal > match.away_team_goal THEN 1
            ELSE 0
        END AS win
    FROM match
    UNION ALL
    SELECT
        match.league_id,
        match.away_team_api_id AS team_api_id,
        CASE
            WHEN match.away_team_goal > match.home_team_goal THEN 1
            ELSE 0
        END AS win
    FROM match
),
team_wins AS (
    SELECT
        league.name AS league_name,
        team.team_long_name,
        SUM(result.win) AS total_wins
    FROM team_results AS result
    JOIN league ON result.league_id = league.id
    JOIN team ON result.team_api_id = team.team_api_id
    GROUP BY
        league.id,
        league.name,
        team.team_api_id,
        team.team_long_name
),
ranked_teams AS (
    SELECT
        league_name,
        team_long_name,
        total_wins,
        ROW_NUMBER() OVER (
            PARTITION BY league_name
            ORDER BY total_wins, team_long_name
        ) AS team_rank
    FROM team_wins
)
SELECT
    league_name,
    team_long_name,
    total_wins
FROM ranked_teams
WHERE team_rank = 1
ORDER BY league_name;
