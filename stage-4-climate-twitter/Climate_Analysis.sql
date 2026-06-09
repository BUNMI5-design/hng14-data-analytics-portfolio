-- ============================================================
-- CLIMATE CHANGE TWITTER DATASET — FULL ANALYSIS
-- Analyst: Balogun Bunmi
-- Date: May 2026
-- Tool: PostgreSQL
-- Dataset: The Climate Change Twitter Dataset (Mendeley)
-- ============================================================
-- This single file covers:
--   Part 1: Table Creation & Data Loading
--   Part 2: Data Cleaning & Preparation
--   Part 3: Data Transformation & Views
--   Part 4: Descriptive Analytics
--   Part 5: Diagnostic Analytics
-- ============================================================


-- ============================================================
-- PART 1: TABLE CREATION & DATA LOADING
-- ============================================================

-- ── Drop tables if re-running from scratch ────────────────────
DROP TABLE IF EXISTS tweets CASCADE;
DROP TABLE IF EXISTS disasters CASCADE;

-- ── Create raw tweets table ───────────────────────────────────
CREATE TABLE tweets (
    created_at          TEXT,           -- loaded as TEXT first, cast to TIMESTAMP later
    tweet_id            BIGINT,
    lng                 DOUBLE PRECISION,
    lat                 DOUBLE PRECISION,
    topic               TEXT,
    sentiment           DOUBLE PRECISION,
    stance              TEXT,
    gender              TEXT,
    temperature_avg     DOUBLE PRECISION,
    aggressiveness      TEXT
);

-- ── Create raw disasters table ────────────────────────────────
CREATE TABLE disasters (
    disaster_type           TEXT,
    disaster_subtype        TEXT,
    disaster_group          TEXT,
    disaster_subgroup       TEXT,
    event_name              TEXT,
    origin                  TEXT,
    country                 TEXT,
    location                TEXT,
    latitude                DOUBLE PRECISION,
    longitude               DOUBLE PRECISION,
    start_date              TEXT,
    end_date                TEXT,
    total_deaths            DOUBLE PRECISION,
    no_affected             DOUBLE PRECISION,
    reconstruction_costs    DOUBLE PRECISION,
    total_damages           DOUBLE PRECISION,
    cpi                     DOUBLE PRECISION
);

-- ── Load tweets data ──────────────────────────────────────────
-- IMPORTANT: Update this path to match your actual file location
-- Replace the path below with your exact file path
COPY tweets (created_at, tweet_id, lng, lat, topic, sentiment,
             stance, gender, temperature_avg, aggressiveness)
FROM 'C:\Users\Sylvia\OneDrive\Documents\The Climate Change Twitter Dataset.csv'
DELIMITER ','
CSV HEADER
ENCODING 'UTF8';

-- ── Load disasters data ───────────────────────────────────────
COPY disasters (disaster_type, disaster_subtype, disaster_group,
                disaster_subgroup, event_name, origin, country,
                location, latitude, longitude, start_date, end_date,
                total_deaths, no_affected, reconstruction_costs,
                total_damages, cpi)
FROM 'C:\Users\Sylvia\Downloads\disasters.csv'
DELIMITER ','
CSV HEADER
ENCODING 'UTF8';

-- ── Verify row counts ─────────────────────────────────────────
SELECT 'tweets'    AS table_name, COUNT(*) AS row_count FROM tweets
UNION ALL
SELECT 'disasters' AS table_name, COUNT(*) AS row_count FROM disasters;


-- ============================================================
-- PART 2: DATA CLEANING & PREPARATION
-- ============================================================

-- ── 2A: INSPECT RAW DATA ─────────────────────────────────────

-- Preview tweets
SELECT * FROM tweets LIMIT 10;

-- Preview disasters
SELECT * FROM disasters LIMIT 10;

-- Check distinct values for categorical columns
SELECT DISTINCT topic        FROM tweets ORDER BY topic;
SELECT DISTINCT stance       FROM tweets ORDER BY stance;
SELECT DISTINCT gender       FROM tweets ORDER BY gender;
SELECT DISTINCT aggressiveness FROM tweets ORDER BY aggressiveness;

-- ── 2B: CHECK MISSING VALUES ─────────────────────────────────

SELECT
    COUNT(*)                                                    AS total_rows,
    SUM(CASE WHEN created_at IS NULL THEN 1 ELSE 0 END)        AS null_created_at,
    SUM(CASE WHEN tweet_id  IS NULL THEN 1 ELSE 0 END)         AS null_tweet_id,
    SUM(CASE WHEN lng       IS NULL THEN 1 ELSE 0 END)         AS null_lng,
    SUM(CASE WHEN lat       IS NULL THEN 1 ELSE 0 END)         AS null_lat,
    SUM(CASE WHEN topic     IS NULL THEN 1 ELSE 0 END)         AS null_topic,
    SUM(CASE WHEN sentiment IS NULL THEN 1 ELSE 0 END)         AS null_sentiment,
    SUM(CASE WHEN stance    IS NULL THEN 1 ELSE 0 END)         AS null_stance,
    SUM(CASE WHEN gender    IS NULL THEN 1 ELSE 0 END)         AS null_gender,
    SUM(CASE WHEN temperature_avg IS NULL THEN 1 ELSE 0 END)   AS null_temperature,
    SUM(CASE WHEN aggressiveness  IS NULL THEN 1 ELSE 0 END)   AS null_aggressiveness
FROM tweets;

-- ── 2C: CHECK DUPLICATES ─────────────────────────────────────

-- Check for duplicate tweet IDs
SELECT tweet_id, COUNT(*) AS occurrences
FROM tweets
GROUP BY tweet_id
HAVING COUNT(*) > 1
ORDER BY occurrences DESC
LIMIT 20;

-- Total duplicate count
SELECT COUNT(*) AS duplicate_tweet_ids
FROM (
    SELECT tweet_id
    FROM tweets
    GROUP BY tweet_id
    HAVING COUNT(*) > 1
) dupes;

-- ── 2D: CHECK SENTIMENT RANGE ────────────────────────────────

-- Sentiment must be between -1 and 1
SELECT
    COUNT(*) AS out_of_range_sentiment
FROM tweets
WHERE sentiment < -1 OR sentiment > 1;

-- Distribution check
SELECT
    MIN(sentiment)  AS min_sentiment,
    MAX(sentiment)  AS max_sentiment,
    AVG(sentiment)  AS avg_sentiment,
    STDDEV(sentiment) AS stddev_sentiment
FROM tweets;

-- ── 2E: CHECK COORDINATE RANGES ──────────────────────────────

-- Valid longitude: -180 to 180, Valid latitude: -90 to 90
SELECT COUNT(*) AS invalid_coordinates
FROM tweets
WHERE lng < -180 OR lng > 180
   OR lat < -90  OR lat > 90;

-- ── 2F: CHECK AGGRESSIVENESS VALUES ──────────────────────────

SELECT aggressiveness, COUNT(*) AS count
FROM tweets
GROUP BY aggressiveness
ORDER BY count DESC;

-- ── 2G: CREATE CLEANED TWEETS TABLE ──────────────────────────
-- Decisions made:
-- 1. Cast created_at from TEXT to TIMESTAMP
-- 2. Remove duplicate tweet_ids (keep first occurrence)
-- 3. Retain NULL coordinates (geolocation is optional on Twitter)
--    — flagged with has_geolocation column for filtering in Power BI
-- 4. Standardise topic names (fix typo: 'Importance of Human Intervantion')
-- 5. Standardise gender: keep male/female/undefined as-is
-- 6. Flag out-of-range sentiment but retain (only 0 found — all valid)
-- 7. Extract year, month, quarter, hour for time intelligence
-- 8. Add continent derived from coordinates for regional analysis

DROP TABLE IF EXISTS tweets_clean CASCADE;

CREATE TABLE tweets_clean AS
WITH deduped AS (
    -- Remove duplicate tweet_ids, keep earliest record
    SELECT DISTINCT ON (tweet_id) *
    FROM tweets
    WHERE tweet_id IS NOT NULL
    ORDER BY tweet_id,
             TO_TIMESTAMP(created_at, 'YYYY-MM-DD HH24:MI:SS') ASC
)
SELECT
    -- ── Timestamp fields ──────────────────────────────────────
    TO_TIMESTAMP(
        REGEXP_REPLACE(created_at, '\+\d{2}:\d{2}$', ''),
        'YYYY-MM-DD HH24:MI:SS'
    )::TIMESTAMP WITHOUT TIME ZONE                          AS tweet_timestamp,

    EXTRACT(YEAR    FROM TO_TIMESTAMP(
        REGEXP_REPLACE(created_at, '\+\d{2}:\d{2}$', ''),
        'YYYY-MM-DD HH24:MI:SS'))::INT                     AS tweet_year,

    EXTRACT(MONTH   FROM TO_TIMESTAMP(
        REGEXP_REPLACE(created_at, '\+\d{2}:\d{2}$', ''),
        'YYYY-MM-DD HH24:MI:SS'))::INT                     AS tweet_month,

    EXTRACT(QUARTER FROM TO_TIMESTAMP(
        REGEXP_REPLACE(created_at, '\+\d{2}:\d{2}$', ''),
        'YYYY-MM-DD HH24:MI:SS'))::INT                     AS tweet_quarter,

    EXTRACT(HOUR    FROM TO_TIMESTAMP(
        REGEXP_REPLACE(created_at, '\+\d{2}:\d{2}$', ''),
        'YYYY-MM-DD HH24:MI:SS'))::INT                     AS tweet_hour,

    TO_CHAR(TO_TIMESTAMP(
        REGEXP_REPLACE(created_at, '\+\d{2}:\d{2}$', ''),
        'YYYY-MM-DD HH24:MI:SS'), 'YYYY-MM')               AS year_month,

    -- ── Identity fields ───────────────────────────────────────
    tweet_id,

    -- ── Geolocation fields ────────────────────────────────────
    CASE WHEN lng BETWEEN -180 AND 180 THEN lng ELSE NULL END AS lng,
    CASE WHEN lat BETWEEN  -90 AND  90 THEN lat ELSE NULL END AS lat,
    CASE WHEN lng IS NOT NULL
          AND lat IS NOT NULL
          AND lng BETWEEN -180 AND 180
          AND lat BETWEEN  -90 AND  90
         THEN TRUE ELSE FALSE END                           AS has_geolocation,

    -- ── Derived continent from coordinates ────────────────────
    CASE
        WHEN lat BETWEEN  15 AND  72 AND lng BETWEEN -170 AND -50 THEN 'North America'
        WHEN lat BETWEEN -56 AND  15 AND lng BETWEEN  -82 AND -34 THEN 'South America'
        WHEN lat BETWEEN  35 AND  72 AND lng BETWEEN  -25 AND  45 THEN 'Europe'
        WHEN lat BETWEEN -35 AND  37 AND lng BETWEEN  -18 AND  52 THEN 'Africa'
        WHEN lat BETWEEN -10 AND  77 AND lng BETWEEN   25 AND 180 THEN 'Asia'
        WHEN lat BETWEEN -50 AND -10 AND lng BETWEEN  110 AND 180 THEN 'Oceania'
        ELSE 'Unknown'
    END                                                     AS continent,

    -- ── Topic (standardised) ──────────────────────────────────
    CASE
        WHEN topic ILIKE '%intervantion%'
          OR topic ILIKE '%intervention%' THEN 'Importance of Human Intervention'
        WHEN topic ILIKE '%gas%'          THEN 'Seriousness of Gas Emissions'
        WHEN topic ILIKE '%weather%'      THEN 'Weather Extremes'
        WHEN topic ILIKE '%pollution%'    THEN 'Significance of Pollution Awareness'
        WHEN topic ILIKE '%resource%'     THEN 'Impact of Resource Overconsumption'
        WHEN topic ILIKE '%trump%'        THEN 'Donald Trump vs Science'
        WHEN topic ILIKE '%ideological%'  THEN 'Ideological Positions on Global Warming'
        WHEN topic ILIKE '%global stance%'
          OR topic ILIKE '%global%'       THEN 'Global Stance'
        WHEN topic ILIKE '%politic%'      THEN 'Politics'
        ELSE COALESCE(topic, 'Undefined')
    END                                                     AS topic,

    -- ── Sentiment ─────────────────────────────────────────────
    sentiment,
    CASE
        WHEN sentiment >  0.05 THEN 'Positive'
        WHEN sentiment < -0.05 THEN 'Negative'
        ELSE 'Neutral'
    END                                                     AS sentiment_label,

    -- ── Stance ───────────────────────────────────────────────
    INITCAP(TRIM(stance))                                   AS stance,

    -- ── Gender ───────────────────────────────────────────────
    INITCAP(TRIM(gender))                                   AS gender,

    -- ── Temperature ──────────────────────────────────────────
    temperature_avg,
    CASE
        WHEN temperature_avg > 0 THEN 'Above Average'
        WHEN temperature_avg < 0 THEN 'Below Average'
        ELSE 'At Average'
    END                                                     AS temp_category,

    -- ── Aggressiveness ────────────────────────────────────────
    CASE
        WHEN LOWER(TRIM(aggressiveness)) = 'aggressive'     THEN 'Aggressive'
        WHEN LOWER(TRIM(aggressiveness)) = 'not aggressive' THEN 'Not Aggressive'
        ELSE 'Unknown'
    END                                                     AS aggressiveness

FROM deduped
WHERE created_at IS NOT NULL
  AND tweet_id   IS NOT NULL;

-- Add primary key
ALTER TABLE tweets_clean ADD PRIMARY KEY (tweet_id);

-- Verify cleaned table
SELECT COUNT(*) AS cleaned_row_count FROM tweets_clean;

SELECT
    SUM(CASE WHEN has_geolocation THEN 1 ELSE 0 END) AS geolocated_tweets,
    SUM(CASE WHEN NOT has_geolocation THEN 1 ELSE 0 END) AS non_geolocated_tweets
FROM tweets_clean;

-- ── 2H: CLEAN DISASTERS TABLE ────────────────────────────────

DROP TABLE IF EXISTS disasters_clean CASCADE;

CREATE TABLE disasters_clean AS
SELECT
    INITCAP(TRIM(disaster_type))     AS disaster_type,
    INITCAP(TRIM(disaster_subtype))  AS disaster_subtype,
    INITCAP(TRIM(disaster_group))    AS disaster_group,
    INITCAP(TRIM(disaster_subgroup)) AS disaster_subgroup,
    TRIM(event_name)                 AS event_name,
    TRIM(country)                    AS country,
    TRIM(location)                   AS location,
    latitude,
    longitude,
    start_date::DATE                 AS start_date,
    end_date::DATE                   AS end_date,
    EXTRACT(YEAR FROM start_date::DATE)::INT AS disaster_year,
    COALESCE(total_deaths, 0)        AS total_deaths,
    COALESCE(no_affected, 0)         AS total_affected,
    COALESCE(total_damages, 0)       AS total_damages_usd
FROM disasters
WHERE disaster_type IS NOT NULL
  AND country IS NOT NULL;

-- Verify
SELECT COUNT(*) AS disaster_row_count FROM disasters_clean;


-- ============================================================
-- PART 3: DATA TRANSFORMATION & VIEWS
-- ============================================================
-- All views below feed directly into Power BI

-- ── VIEW 1: Master cleaned tweets view ───────────────────────
CREATE OR REPLACE VIEW vw_tweets_master AS
SELECT
    tweet_id,
    tweet_timestamp,
    tweet_year,
    tweet_month,
    tweet_quarter,
    tweet_hour,
    year_month,
    lng,
    lat,
    has_geolocation,
    continent,
    topic,
    sentiment,
    sentiment_label,
    stance,
    gender,
    temperature_avg,
    temp_category,
    aggressiveness
FROM tweets_clean;

-- ── VIEW 2: Yearly sentiment & stance summary ─────────────────
CREATE OR REPLACE VIEW vw_yearly_trends AS
SELECT
    tweet_year,
    COUNT(*)                                        AS total_tweets,
    ROUND(AVG(sentiment)::NUMERIC, 4)               AS avg_sentiment,
    ROUND(STDDEV(sentiment)::NUMERIC, 4)            AS sentiment_stddev,
    SUM(CASE WHEN stance = 'Believer' THEN 1 ELSE 0 END) AS believer_count,
    SUM(CASE WHEN stance = 'Denier'   THEN 1 ELSE 0 END) AS denier_count,
    SUM(CASE WHEN stance = 'Neutral'  THEN 1 ELSE 0 END) AS neutral_count,
    ROUND(
        SUM(CASE WHEN stance = 'Believer' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2)                              AS believer_pct,
    ROUND(
        SUM(CASE WHEN stance = 'Denier'   THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2)                              AS denier_pct,
    SUM(CASE WHEN aggressiveness = 'Aggressive' THEN 1 ELSE 0 END) AS aggressive_count,
    ROUND(
        SUM(CASE WHEN aggressiveness = 'Aggressive' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2)                              AS aggressive_pct
FROM tweets_clean
GROUP BY tweet_year
ORDER BY tweet_year;

-- ── VIEW 3: Monthly trends ────────────────────────────────────
CREATE OR REPLACE VIEW vw_monthly_trends AS
SELECT
    tweet_year,
    tweet_month,
    year_month,
    COUNT(*)                              AS total_tweets,
    ROUND(AVG(sentiment)::NUMERIC, 4)     AS avg_sentiment,
    SUM(CASE WHEN stance = 'Believer' THEN 1 ELSE 0 END) AS believers,
    SUM(CASE WHEN stance = 'Denier'   THEN 1 ELSE 0 END) AS deniers,
    SUM(CASE WHEN aggressiveness = 'Aggressive' THEN 1 ELSE 0 END) AS aggressive_tweets
FROM tweets_clean
GROUP BY tweet_year, tweet_month, year_month
ORDER BY tweet_year, tweet_month;

-- ── VIEW 4: Topic analysis ────────────────────────────────────
CREATE OR REPLACE VIEW vw_topic_analysis AS
SELECT
    topic,
    COUNT(*)                                        AS total_tweets,
    ROUND(AVG(sentiment)::NUMERIC, 4)               AS avg_sentiment,
    ROUND(STDDEV(sentiment)::NUMERIC, 4)            AS sentiment_stddev,
    SUM(CASE WHEN stance = 'Believer' THEN 1 ELSE 0 END) AS believers,
    SUM(CASE WHEN stance = 'Denier'   THEN 1 ELSE 0 END) AS deniers,
    SUM(CASE WHEN stance = 'Neutral'  THEN 1 ELSE 0 END) AS neutrals,
    SUM(CASE WHEN aggressiveness = 'Aggressive' THEN 1 ELSE 0 END) AS aggressive_tweets,
    ROUND(
        SUM(CASE WHEN aggressiveness = 'Aggressive' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2)                              AS aggressive_pct,
    ROUND(AVG(temperature_avg)::NUMERIC, 4)         AS avg_temp_deviation
FROM tweets_clean
GROUP BY topic
ORDER BY total_tweets DESC;

-- ── VIEW 5: Stance over time ──────────────────────────────────
CREATE OR REPLACE VIEW vw_stance_over_time AS
SELECT
    tweet_year,
    stance,
    COUNT(*)                              AS tweet_count,
    ROUND(AVG(sentiment)::NUMERIC, 4)     AS avg_sentiment,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY tweet_year),
        2)                                AS pct_of_year
FROM tweets_clean
GROUP BY tweet_year, stance
ORDER BY tweet_year, stance;

-- ── VIEW 6: Sentiment distribution ───────────────────────────
CREATE OR REPLACE VIEW vw_sentiment_distribution AS
SELECT
    sentiment_label,
    tweet_year,
    COUNT(*)                              AS tweet_count,
    ROUND(AVG(sentiment)::NUMERIC, 4)     AS avg_sentiment,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY tweet_year),
        2)                                AS pct_of_year
FROM tweets_clean
GROUP BY sentiment_label, tweet_year
ORDER BY tweet_year, sentiment_label;

-- ── VIEW 7: Gender analysis ───────────────────────────────────
CREATE OR REPLACE VIEW vw_gender_analysis AS
SELECT
    gender,
    COUNT(*)                                        AS total_tweets,
    ROUND(AVG(sentiment)::NUMERIC, 4)               AS avg_sentiment,
    SUM(CASE WHEN stance = 'Believer' THEN 1 ELSE 0 END) AS believers,
    SUM(CASE WHEN stance = 'Denier'   THEN 1 ELSE 0 END) AS deniers,
    SUM(CASE WHEN aggressiveness = 'Aggressive' THEN 1 ELSE 0 END) AS aggressive_tweets,
    ROUND(
        SUM(CASE WHEN aggressiveness = 'Aggressive' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2)                              AS aggressive_pct
FROM tweets_clean
GROUP BY gender
ORDER BY total_tweets DESC;

-- ── VIEW 8: Regional (continent) analysis ────────────────────
CREATE OR REPLACE VIEW vw_regional_analysis AS
SELECT
    continent,
    COUNT(*)                                        AS total_tweets,
    ROUND(AVG(sentiment)::NUMERIC, 4)               AS avg_sentiment,
    SUM(CASE WHEN stance = 'Believer' THEN 1 ELSE 0 END) AS believers,
    SUM(CASE WHEN stance = 'Denier'   THEN 1 ELSE 0 END) AS deniers,
    SUM(CASE WHEN aggressiveness = 'Aggressive' THEN 1 ELSE 0 END) AS aggressive_tweets,
    ROUND(
        SUM(CASE WHEN aggressiveness = 'Aggressive' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2)                              AS aggressive_pct,
    ROUND(AVG(temperature_avg)::NUMERIC, 4)         AS avg_temp_deviation
FROM tweets_clean
WHERE has_geolocation = TRUE
GROUP BY continent
ORDER BY total_tweets DESC;

-- ── VIEW 9: Aggressiveness by topic and stance ────────────────
CREATE OR REPLACE VIEW vw_aggressiveness_analysis AS
SELECT
    topic,
    stance,
    aggressiveness,
    COUNT(*)                              AS tweet_count,
    ROUND(AVG(sentiment)::NUMERIC, 4)     AS avg_sentiment
FROM tweets_clean
GROUP BY topic, stance, aggressiveness
ORDER BY tweet_count DESC;

-- ── VIEW 10: Temperature deviation analysis ───────────────────
CREATE OR REPLACE VIEW vw_temperature_analysis AS
SELECT
    tweet_year,
    temp_category,
    COUNT(*)                                        AS total_tweets,
    ROUND(AVG(sentiment)::NUMERIC, 4)               AS avg_sentiment,
    ROUND(AVG(temperature_avg)::NUMERIC, 4)         AS avg_temp_deviation,
    SUM(CASE WHEN stance = 'Believer' THEN 1 ELSE 0 END) AS believers,
    SUM(CASE WHEN stance = 'Denier'   THEN 1 ELSE 0 END) AS deniers,
    SUM(CASE WHEN aggressiveness = 'Aggressive' THEN 1 ELSE 0 END) AS aggressive_tweets
FROM tweets_clean
WHERE temperature_avg IS NOT NULL
GROUP BY tweet_year, temp_category
ORDER BY tweet_year, temp_category;

-- ── VIEW 11: Disasters by year ────────────────────────────────
CREATE OR REPLACE VIEW vw_disasters_by_year AS
SELECT
    disaster_year,
    COUNT(*)                              AS total_disasters,
    SUM(total_deaths)                     AS total_deaths,
    SUM(total_affected)                   AS total_affected,
    SUM(total_damages_usd)                AS total_damages_usd,
    COUNT(DISTINCT disaster_type)         AS disaster_types_count
FROM disasters_clean
GROUP BY disaster_year
ORDER BY disaster_year;

-- ── VIEW 12: Tweets vs disasters joined by year ───────────────
CREATE OR REPLACE VIEW vw_tweets_vs_disasters AS
SELECT
    t.tweet_year,
    t.total_tweets,
    ROUND(t.avg_sentiment::NUMERIC, 4)    AS avg_sentiment,
    t.aggressive_pct,
    t.believer_pct,
    t.denier_pct,
    COALESCE(d.total_disasters, 0)        AS total_disasters,
    COALESCE(d.total_deaths, 0)           AS total_deaths,
    COALESCE(d.total_affected, 0)         AS total_affected
FROM vw_yearly_trends t
LEFT JOIN vw_disasters_by_year d ON t.tweet_year = d.disaster_year
ORDER BY t.tweet_year;

-- ── VIEW 13: Topic sentiment heatmap ─────────────────────────
CREATE OR REPLACE VIEW vw_topic_year_heatmap AS
SELECT
    tweet_year,
    topic,
    COUNT(*)                              AS total_tweets,
    ROUND(AVG(sentiment)::NUMERIC, 4)     AS avg_sentiment,
    ROUND(
        SUM(CASE WHEN aggressiveness = 'Aggressive' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2)                    AS aggressive_pct
FROM tweets_clean
GROUP BY tweet_year, topic
ORDER BY tweet_year, topic;

-- ── VIEW 14: Geolocated tweets for map visual ─────────────────
CREATE OR REPLACE VIEW vw_geo_tweets AS
SELECT
    tweet_id,
    tweet_year,
    lng,
    lat,
    continent,
    sentiment,
    sentiment_label,
    stance,
    aggressiveness,
    topic
FROM tweets_clean
WHERE has_geolocation = TRUE;

-- ── VIEW 15: Quarter trends ───────────────────────────────────
CREATE OR REPLACE VIEW vw_quarterly_trends AS
SELECT
    tweet_year,
    tweet_quarter,
    CONCAT(tweet_year, ' Q', tweet_quarter) AS year_quarter,
    COUNT(*)                                AS total_tweets,
    ROUND(AVG(sentiment)::NUMERIC, 4)       AS avg_sentiment,
    SUM(CASE WHEN stance = 'Believer' THEN 1 ELSE 0 END) AS believers,
    SUM(CASE WHEN stance = 'Denier'   THEN 1 ELSE 0 END) AS deniers,
    SUM(CASE WHEN aggressiveness = 'Aggressive' THEN 1 ELSE 0 END) AS aggressive_tweets
FROM tweets_clean
GROUP BY tweet_year, tweet_quarter
ORDER BY tweet_year, tweet_quarter;


-- ============================================================
-- PART 4: DESCRIPTIVE ANALYTICS
-- ============================================================

-- ── 4A: OVERALL SUMMARY STATISTICS ───────────────────────────

SELECT
    COUNT(*)                                        AS total_tweets,
    COUNT(DISTINCT tweet_year)                      AS years_covered,
    MIN(tweet_year)                                 AS earliest_year,
    MAX(tweet_year)                                 AS latest_year,
    ROUND(AVG(sentiment)::NUMERIC, 4)               AS overall_avg_sentiment,
    MIN(sentiment)                                  AS min_sentiment,
    MAX(sentiment)                                  AS max_sentiment,
    SUM(CASE WHEN has_geolocation THEN 1 ELSE 0 END) AS geolocated_count,
    ROUND(
        SUM(CASE WHEN has_geolocation THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2)                              AS geolocated_pct
FROM tweets_clean;

-- ── 4B: TWEET VOLUME BY YEAR ─────────────────────────────────

SELECT
    tweet_year,
    total_tweets,
    ROUND(
        (total_tweets - LAG(total_tweets) OVER (ORDER BY tweet_year)) * 100.0
        / NULLIF(LAG(total_tweets) OVER (ORDER BY tweet_year), 0),
        2)                                          AS yoy_growth_pct
FROM vw_yearly_trends
ORDER BY tweet_year;

-- ── 4C: STANCE DISTRIBUTION OVERALL ──────────────────────────

SELECT
    stance,
    COUNT(*)                                        AS tweet_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM tweets_clean
GROUP BY stance
ORDER BY tweet_count DESC;

-- ── 4D: TOPIC DISTRIBUTION ───────────────────────────────────

SELECT
    topic,
    total_tweets,
    ROUND(total_tweets * 100.0 / SUM(total_tweets) OVER (), 2) AS pct_of_total,
    avg_sentiment,
    aggressive_pct
FROM vw_topic_analysis
ORDER BY total_tweets DESC;

-- ── 4E: GENDER DISTRIBUTION ──────────────────────────────────

SELECT
    gender,
    total_tweets,
    ROUND(total_tweets * 100.0 / SUM(total_tweets) OVER (), 2) AS pct_of_total,
    avg_sentiment,
    aggressive_pct
FROM vw_gender_analysis
ORDER BY total_tweets DESC;

-- ── 4F: AGGRESSIVENESS OVERALL ───────────────────────────────

SELECT
    aggressiveness,
    COUNT(*)                                        AS tweet_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage,
    ROUND(AVG(sentiment)::NUMERIC, 4)               AS avg_sentiment
FROM tweets_clean
GROUP BY aggressiveness
ORDER BY tweet_count DESC;

-- ── 4G: SENTIMENT LABEL DISTRIBUTION ─────────────────────────

SELECT
    sentiment_label,
    COUNT(*)                                        AS tweet_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS percentage
FROM tweets_clean
GROUP BY sentiment_label
ORDER BY tweet_count DESC;

-- ── 4H: TOP 5 MOST TWEETED YEARS ─────────────────────────────

SELECT tweet_year, total_tweets, avg_sentiment
FROM vw_yearly_trends
ORDER BY total_tweets DESC
LIMIT 5;

-- ── 4I: DISASTERS SUMMARY ────────────────────────────────────

SELECT
    COUNT(*)              AS total_disaster_events,
    SUM(total_deaths)     AS total_deaths_recorded,
    SUM(total_affected)   AS total_people_affected,
    COUNT(DISTINCT disaster_type) AS disaster_types,
    COUNT(DISTINCT country)       AS countries_affected
FROM disasters_clean;


-- ============================================================
-- PART 5: DIAGNOSTIC ANALYTICS
-- ============================================================

-- ── 5A: SENTIMENT TREND OVER TIME ────────────────────────────
-- Has public sentiment been getting more positive or negative?

SELECT
    tweet_year,
    avg_sentiment,
    ROUND(
        avg_sentiment - LAG(avg_sentiment) OVER (ORDER BY tweet_year),
        4)                                          AS sentiment_change,
    total_tweets
FROM vw_yearly_trends
ORDER BY tweet_year;

-- ── 5B: STANCE SHIFT ANALYSIS ────────────────────────────────
-- Are believers growing or shrinking relative to deniers over time?

SELECT
    tweet_year,
    believer_pct,
    denier_pct,
    ROUND(believer_pct - denier_pct, 2)             AS believer_denier_gap,
    ROUND(
        believer_pct - LAG(believer_pct) OVER (ORDER BY tweet_year),
        2)                                          AS believer_pct_change
FROM vw_yearly_trends
ORDER BY tweet_year;

-- ── 5C: MOST DIVISIVE TOPICS ─────────────────────────────────
-- High sentiment stddev = most polarising topic

SELECT
    topic,
    total_tweets,
    avg_sentiment,
    sentiment_stddev,
    aggressive_pct,
    ROUND(
        ABS(
            SUM(CASE WHEN stance='Believer' THEN 1 ELSE 0 END) -
            SUM(CASE WHEN stance='Denier'   THEN 1 ELSE 0 END)
        ) * 100.0 / NULLIF(total_tweets, 0),
        2)                                          AS stance_gap_pct
FROM vw_topic_analysis
JOIN (
    SELECT topic,
           SUM(CASE WHEN stance='Believer' THEN 1 ELSE 0 END) AS believers,
           SUM(CASE WHEN stance='Denier'   THEN 1 ELSE 0 END) AS deniers
    FROM tweets_clean GROUP BY topic
) t USING (topic)
ORDER BY sentiment_stddev DESC;

-- ── 5D: AGGRESSIVENESS BY TOPIC ──────────────────────────────
-- Which topics generate the most aggressive discourse?

SELECT
    topic,
    total_tweets,
    aggressive_tweets,
    aggressive_pct,
    avg_sentiment
FROM vw_topic_analysis
ORDER BY aggressive_pct DESC;

-- ── 5E: AGGRESSIVENESS BY STANCE ─────────────────────────────
-- Are deniers more aggressive than believers?

SELECT
    stance,
    COUNT(*)                                        AS total_tweets,
    SUM(CASE WHEN aggressiveness='Aggressive' THEN 1 ELSE 0 END) AS aggressive,
    ROUND(
        SUM(CASE WHEN aggressiveness='Aggressive' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2)                              AS aggressive_pct,
    ROUND(AVG(sentiment)::NUMERIC, 4)               AS avg_sentiment
FROM tweets_clean
GROUP BY stance
ORDER BY aggressive_pct DESC;

-- ── 5F: GENDER vs SENTIMENT & AGGRESSIVENESS ─────────────────
-- Do male and female users express climate opinions differently?

SELECT
    gender,
    stance,
    COUNT(*)                                        AS tweet_count,
    ROUND(AVG(sentiment)::NUMERIC, 4)               AS avg_sentiment,
    ROUND(
        SUM(CASE WHEN aggressiveness='Aggressive' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2)                              AS aggressive_pct
FROM tweets_clean
WHERE gender IN ('Male','Female')
GROUP BY gender, stance
ORDER BY gender, tweet_count DESC;

-- ── 5G: TEMPERATURE DEVIATION vs SENTIMENT ────────────────────
-- Do warmer-than-average periods trigger more negative sentiment?

SELECT
    tweet_year,
    temp_category,
    avg_temp_deviation,
    avg_sentiment,
    total_tweets,
    aggressive_tweets
FROM vw_temperature_analysis
ORDER BY tweet_year, temp_category;

-- ── 5H: REGIONAL AGGRESSIVENESS ──────────────────────────────
-- Which continents drive the most aggressive climate discourse?

SELECT
    continent,
    total_tweets,
    avg_sentiment,
    aggressive_tweets,
    aggressive_pct,
    believers,
    deniers
FROM vw_regional_analysis
ORDER BY aggressive_pct DESC;

-- ── 5I: DISASTER CORRELATION WITH TWEET VOLUME ───────────────
-- Do major disaster years see spikes in tweet volume?

SELECT
    tweet_year,
    total_tweets,
    avg_sentiment,
    aggressive_pct,
    total_disasters,
    total_deaths,
    total_affected
FROM vw_tweets_vs_disasters
ORDER BY tweet_year;

-- ── 5J: PEAK TWEET HOURS ─────────────────────────────────────
-- What time of day drives the most climate discourse?

SELECT
    tweet_hour,
    COUNT(*)                              AS total_tweets,
    ROUND(AVG(sentiment)::NUMERIC, 4)     AS avg_sentiment,
    ROUND(
        SUM(CASE WHEN aggressiveness='Aggressive' THEN 1 ELSE 0 END) * 100.0
        / COUNT(*), 2)                    AS aggressive_pct
FROM tweets_clean
GROUP BY tweet_hour
ORDER BY total_tweets DESC
LIMIT 10;

-- ── 5K: TOPIC SHIFTS BY DECADE ───────────────────────────────
-- Which topics dominated early vs late in the dataset?

SELECT
    CASE
        WHEN tweet_year BETWEEN 2006 AND 2012 THEN '2006-2012 (Early)'
        WHEN tweet_year BETWEEN 2013 AND 2017 THEN '2013-2017 (Mid)'
        WHEN tweet_year BETWEEN 2018 AND 2022 THEN '2018-2022 (Recent)'
    END                                             AS period,
    topic,
    COUNT(*)                                        AS tweet_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (
        PARTITION BY CASE
            WHEN tweet_year BETWEEN 2006 AND 2012 THEN '2006-2012'
            WHEN tweet_year BETWEEN 2013 AND 2017 THEN '2013-2017'
            WHEN tweet_year BETWEEN 2018 AND 2022 THEN '2018-2022'
        END), 2)                                    AS pct_of_period
FROM tweets_clean
GROUP BY period, topic
ORDER BY period, tweet_count DESC;


-- ============================================================
-- SUMMARY OF ALL VIEWS CREATED (for Power BI connection)
-- ============================================================
-- vw_tweets_master          — Full cleaned dataset (use for slicers)
-- vw_yearly_trends          — KPIs by year
-- vw_monthly_trends         — Monthly tweet volume and sentiment
-- vw_quarterly_trends       — Quarterly breakdown
-- vw_topic_analysis         — Topic-level metrics
-- vw_stance_over_time       — Stance shifts year by year
-- vw_sentiment_distribution — Positive/Negative/Neutral by year
-- vw_gender_analysis        — Gender breakdown
-- vw_regional_analysis      — Continent-level metrics
-- vw_aggressiveness_analysis — Aggression by topic and stance
-- vw_temperature_analysis   — Temperature deviation correlations
-- vw_disasters_by_year      — Disaster counts and deaths by year
-- vw_tweets_vs_disasters    — Tweets + disasters joined by year
-- vw_topic_year_heatmap     — Topic x Year for heatmap visual
-- vw_geo_tweets             — Geolocated tweets for map visual
-- ============================================================
-- END OF FILE
-- ============================================================
