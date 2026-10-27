# Beyond the Scoreboard: IPL Data Analysis

*Analyzing 17 seasons of IPL data (2008–2024) using Python for cleaning and SQL in PostgreSQL for analysis.*

A data analysis project that looks past the usual scoreboard stats to find what actually drives IPL match results and which players deliver consistent value.

## Business Questions

The analysis is framed from the point of view of a franchise analyst preparing for an auction:

1. Does winning the toss actually help a team win?
2. Who were the top run-scorers each season, and who stayed consistent?
3. Who are the most economical bowlers in the death overs (overs 16–20)?
4. Are IPL scores getting higher over the years?

## Dataset

[IPL Complete Dataset (2008–2024)](https://www.kaggle.com/datasets/patrickb1912/ipl-complete-dataset-20082020) from Kaggle, with two tables:

- **matches.csv**: 1,095 matches, one row per match (teams, toss, venue, winner)
- **deliveries.csv**: 260,920 rows, one row per ball (batter, bowler, runs, wickets)

The two tables are linked through the match ID.

## Data Cleaning (Python)

- **Inconsistent season labels:** seasons were stored as "2007/08", "2009/10", "2020/21" and so on. Since every IPL season is played within one calendar year (this was verified), the season was taken from the match date instead.
- **Renamed franchises:** teams like Delhi Daredevils → Delhi Capitals and Kings XI Punjab → Punjab Kings were merged so each team's history stays together, leaving 15 unique teams.
- **Super overs removed:** super overs are stored as innings 3 and 4. These 161 deliveries were removed because they are tie-breakers and would distort run and bowling stats.
- **Missing cities:** 51 missing city values were filled using the most common city for the same venue.
- **No-result matches:** 5 matches had no winner (mostly rain) and were left out of the toss analysis.
- **Structural nulls kept:** some missing values are expected, such as `dismissal_kind` being empty when no wicket fell, so these were left as they are.
- **No duplicates** were found, and the cleaned data was saved as separate files so the raw data stays untouched.

After cleaning, the deliveries table has 260,759 rows.

## Loading into PostgreSQL

- Created the two tables and imported the cleaned CSVs
- Ran sanity checks on row counts and the season range
- Added a primary key on `matches.id` and a foreign key from `deliveries.match_id`, confirming there are no duplicate matches and no deliveries linked to a missing match
- As an extra check, the season-wise top run-scorers match the official Orange Cap records

## Findings & Insights

### 1. Scores have jumped sharply since 2023
- From 2008 to 2022, the average first-innings score stayed between roughly 150 and 172 runs.
- It rose to **182.7 in 2023** and **189.6 in 2024**, the two highest seasons on record.
- The 2024 average is about 17 runs above any season before 2023.
- This coincides with the introduction of the Impact Player rule in 2023, though other factors may also play a part.

![Average first-innings score by IPL season](images/scoring_trend.png?v=2)

### 2. The toss itself matters little, but the decision after it shows a pattern
- Toss winners won about **51%** of matches overall, close to a coin flip.
- Teams that chose to **field first won 53.9%** of the time.
- Teams that chose to **bat first won 45.4%** of the time.
- Captains chose to field in **64%** of matches.

![Toss winner's match win percentage by decision](images/toss_decision.png?v=2)

### 3. Spinners stand out in death-over economy
- Among bowlers with at least 300 death-over balls, **5 of the top 10** by economy are spinners.
- **Sunil Narine** has the best economy at **7.40** runs per over.
- **Lasith Malinga** took the most wickets in this group (122, about one every 9.6 balls).
- **Jasprit Bumrah** bowled the most death-over deliveries in the top 10.

![Most economical death-over bowlers](images/death_over_bowlers.png?v=2)

### 4. Consistency at the top is rare
- Only **6 batters** finished among a season's top 3 run-scorers three or more times.
- **KL Rahul** and **David Warner** did it 5 times each, followed by **Virat Kohli** with 4.
- The runs needed to top the charts rose from around 600 in early seasons to **740–890** in recent seasons.

![Seasons finishing in the top 3 run-scorers](images/consistent_batters.png?v=2)

## Recommendations & Limitations

### Recommendations
- **Plan for higher totals:** recent seasons point to par scores closer to 190, so batting depth and power-hitting are worth prioritizing.
- **Treat fielding first as a starting point, not a rule:** the data shows a better win rate when fielding first, but the final call should also consider venue, pitch and conditions like dew.
- **Pick death bowlers by role:** some bowlers are better at controlling runs (like Narine) while others are better at taking wickets (like Malinga), and a balanced attack benefits from both.
- **Look beyond one strong season:** players who perform across several seasons are a lower-risk choice at auction than one-season standouts.

### Limitations
- The results show patterns, not proof of cause. For example, the fielding-first advantage could be influenced by evening dew or venue.
- The spinner result is likely affected by selection bias, since captains tend to bowl spinners at the death only when conditions suit them.
- In the bowling stats, "balls" includes wides and no-balls, "wickets" includes run-outs, and economy includes byes and leg-byes.
- Venue, pitch conditions and opposition strength were not considered.
- The scoring jump after 2023 lines up with the Impact Player rule, but the rule's exact effect was not isolated.

## Future Scope

- Correct the bowling stats using the `extras_type` and `dismissal_kind` columns
- Break down the toss and scoring patterns by venue
- Generate AI-based scouting reports for players from their stats
- Build an interactive Power BI dashboard

## Repository Structure

```
beyond-the-scoreboard-ipl/
├── README.md                                        # project overview and findings
├── Beyond_The_Scoreboard_IPL_Data_Analysis.ipynb    # data cleaning and charts (Python)
├── ipl_analysis.sql                                 # table creation, checks and analysis queries (PostgreSQL)
└── images/                                          # charts used in this README
    ├── scoring_trend.png
    ├── toss_decision.png
    ├── death_over_bowlers.png
    └── consistent_batters.png
```
