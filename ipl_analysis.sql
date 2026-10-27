-- Beyond the Scoreboard: IPL Data Analysis

-- Creating Tables
CREATE TABLE "matches" (
"id" INTEGER,
  "season" INTEGER,
  "city" TEXT,
  "date" TEXT,
  "match_type" TEXT,
  "player_of_match" TEXT,
  "venue" TEXT,
  "team1" TEXT,
  "team2" TEXT,
  "toss_winner" TEXT,
  "toss_decision" TEXT,
  "winner" TEXT,
  "result" TEXT,
  "result_margin" REAL,
  "target_runs" REAL,
  "target_overs" REAL,
  "super_over" TEXT,
  "method" TEXT,
  "umpire1" TEXT,
  "umpire2" TEXT
);

CREATE TABLE "deliveries" (
"match_id" INTEGER,
  "inning" INTEGER,
  "batting_team" TEXT,
  "bowling_team" TEXT,
  "over" INTEGER,
  "ball" INTEGER,
  "batter" TEXT,
  "bowler" TEXT,
  "non_striker" TEXT,
  "batsman_runs" INTEGER,
  "extra_runs" INTEGER,
  "total_runs" INTEGER,
  "extras_type" TEXT,
  "is_wicket" INTEGER,
  "player_dismissed" TEXT,
  "dismissal_kind" TEXT,
  "fielder" TEXT
);

-- Import the Clean Files

-- Sanity Checks After Import
SELECT COUNT(*) AS total_matches FROM matches;
SELECT COUNT(*) AS total_deliveries FROM deliveries;
SELECT MIN(season) AS first_season, MAX(season) AS last_season FROM matches;

-- Constraints
ALTER TABLE matches ADD PRIMARY KEY (id);

ALTER TABLE deliveries
ADD CONSTRAINT fk_match
FOREIGN KEY (match_id) REFERENCES matches(id);

-- Q1. Does winning the toss help you win the match?
-- Concepts: CASE WHEN, GROUP BY, percentage calculation
SELECT toss_decision, COUNT(*) AS matches,
ROUND(100.0 * SUM(
CASE
WHEN toss_winner = winner
THEN 1 ELSE 0
END
) / COUNT(*), 2) AS toss_winner_win_pct
FROM matches
WHERE winner IS NOT NULL
GROUP BY toss_decision;

-- Q2. Who were the top 3 run-scorers in each season?
-- Concepts: JOIN, CTE, window function (RANK with PARTITION BY)
WITH season_runs AS (
    SELECT m.season,
           d.batter,
           SUM(d.batsman_runs) AS runs
    FROM deliveries d
    JOIN matches m ON d.match_id = m.id
    GROUP BY m.season, d.batter
)
SELECT season, batter, runs, rnk
FROM (
    SELECT season, batter, runs,
           RANK() OVER (PARTITION BY season ORDER BY runs DESC) AS rnk
    FROM season_runs
) ranked
WHERE rnk <= 3
ORDER BY season, rnk;

-- Q2b. Which batters have been most consistent across seasons?
-- (How many times has each batter finished in a season's top 3 run-scorers?)
-- Concepts: multiple CTEs, window function (RANK), GROUP BY on ranked results
WITH season_runs AS (
    SELECT m.season, d.batter, SUM(d.batsman_runs) AS runs
    FROM deliveries d JOIN matches m ON d.match_id = m.id
    GROUP BY m.season, d.batter
),
ranked AS (
    SELECT *, RANK() OVER (PARTITION BY season ORDER BY runs DESC) AS rnk
    FROM season_runs
)
SELECT batter, COUNT(*) AS top3_seasons
FROM ranked
WHERE rnk <= 3
GROUP BY batter
HAVING COUNT(*) >= 3
ORDER BY top3_seasons DESC;

-- Q3. Who are the best death-over bowlers (overs 16–20)?
-- Concepts: WHERE, GROUP BY, HAVING (minimum sample size)
-- Overs are numbered from 0 in this dataset, so overs 16–20 = 15 to 19.
-- "over" is a reserved word in PostgreSQL, so it must be in double quotes.
-- Simplification: economy uses total_runs (includes byes/leg-byes).
SELECT bowler,
       COUNT(*) AS balls,
       ROUND(6.0 * SUM(total_runs) / COUNT(*), 2) AS economy,
       SUM(is_wicket) AS wickets
FROM deliveries
WHERE "over" >= 15
GROUP BY bowler
HAVING COUNT(*) >= 300
ORDER BY economy
LIMIT 10;

-- Q4. Is IPL becoming higher-scoring?
-- Concepts: CTE, AVG, window function (LAG) for year-on-year change
WITH first_innings AS (
    SELECT m.season,
           d.match_id,
           SUM(d.total_runs) AS score
    FROM deliveries d
    JOIN matches m ON d.match_id = m.id
    WHERE d.inning = 1
    GROUP BY m.season, d.match_id
)
SELECT season,
       ROUND(AVG(score), 1) AS avg_first_innings_score,
       ROUND(AVG(score) - LAG(AVG(score)) OVER (ORDER BY season), 1)
           AS change_vs_last_season
FROM first_innings
GROUP BY season
ORDER BY season;