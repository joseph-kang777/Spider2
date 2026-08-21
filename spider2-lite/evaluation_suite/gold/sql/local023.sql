WITH season_runs AS (
    SELECT
        ball.striker AS player_id,
        ball.match_id,
        SUM(score.runs_scored) AS runs
    FROM ball_by_ball AS ball
    JOIN batsman_scored AS score
      ON ball.match_id = score.match_id
     AND ball.over_id = score.over_id
     AND ball.ball_id = score.ball_id
     AND ball.innings_no = score.innings_no
    JOIN match AS season_match ON ball.match_id = season_match.match_id
    WHERE season_match.season_id = 5
    GROUP BY ball.striker, ball.match_id
),
player_runs AS (
    SELECT
        player_id,
        SUM(runs) AS total_runs,
        COUNT(*) AS matches_batted,
        CAST(SUM(runs) AS REAL) / COUNT(*) AS avg_runs_per_match
    FROM season_runs
    GROUP BY player_id
),
player_dismissals AS (
    SELECT
        wicket.player_out AS player_id,
        COUNT(*) AS dismissals
    FROM wicket_taken AS wicket
    JOIN match AS season_match ON wicket.match_id = season_match.match_id
    WHERE season_match.season_id = 5
      AND wicket.kind_out NOT IN ('retired hurt', 'obstructing the field')
    GROUP BY wicket.player_out
)
SELECT
    player.player_name,
    ROUND(runs.avg_runs_per_match, 4) AS avg_runs_per_match,
    ROUND(CAST(runs.total_runs AS REAL) / dismissals.dismissals, 4)
        AS batting_average
FROM player_runs AS runs
JOIN player ON runs.player_id = player.player_id
JOIN player_dismissals AS dismissals ON runs.player_id = dismissals.player_id
ORDER BY runs.avg_runs_per_match DESC, player.player_name
LIMIT 5;
