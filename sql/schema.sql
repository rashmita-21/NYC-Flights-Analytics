-- =====================================================================
-- Star schema for NYC 2013 flight delay analysis (SQLite)
-- Grain of fact_flight: one scheduled flight departure from EWR/JFK/LGA
-- =====================================================================
PRAGMA foreign_keys = ON;

DROP VIEW  IF EXISTS vw_flight_enriched;
DROP TABLE IF EXISTS fact_flight;
DROP TABLE IF EXISTS fact_weather;
DROP TABLE IF EXISTS dim_plane;
DROP TABLE IF EXISTS dim_airport;
DROP TABLE IF EXISTS dim_airline;
DROP TABLE IF EXISTS dim_date;

CREATE TABLE dim_date (
    date            TEXT PRIMARY KEY,          -- ISO yyyy-mm-dd
    year            INTEGER NOT NULL,
    quarter         INTEGER NOT NULL CHECK (quarter BETWEEN 1 AND 4),
    month           INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
    month_name      TEXT    NOT NULL,
    week_of_year    INTEGER NOT NULL,
    weekday_num     INTEGER NOT NULL CHECK (weekday_num BETWEEN 1 AND 7),  -- 1 = Monday
    weekday_name    TEXT    NOT NULL,
    is_weekend      INTEGER NOT NULL CHECK (is_weekend IN (0,1)),
    is_us_holiday   INTEGER NOT NULL CHECK (is_us_holiday IN (0,1)),
    holiday_name    TEXT
);

CREATE TABLE dim_airline (
    carrier         TEXT PRIMARY KEY,          -- 2-character IATA code
    airline_name    TEXT NOT NULL
);

CREATE TABLE dim_airport (
    faa             TEXT PRIMARY KEY,
    name            TEXT NOT NULL,
    lat             REAL,
    lon             REAL,
    altitude_ft     INTEGER,
    tz_offset       REAL,
    dst             TEXT,
    tzone           TEXT,
    is_supplemented INTEGER NOT NULL DEFAULT 0 CHECK (is_supplemented IN (0,1))
);

CREATE TABLE dim_plane (
    tailnum          TEXT PRIMARY KEY,
    year_built       INTEGER CHECK (year_built BETWEEN 1900 AND 2013),
    plane_age_2013   INTEGER CHECK (plane_age_2013 >= 0),
    plane_type       TEXT,
    manufacturer_raw TEXT,
    manufacturer     TEXT NOT NULL,            -- standardised
    model            TEXT,
    engines          INTEGER,
    seats            INTEGER,
    engine_type      TEXT
);

CREATE TABLE fact_weather (
    weather_key      TEXT PRIMARY KEY,         -- <origin>-<YYYYMMDDHH> (UTC hour)
    origin           TEXT NOT NULL REFERENCES dim_airport(faa),
    time_hour_utc    TEXT NOT NULL,
    temp_f           REAL,
    dewp_f           REAL,
    humid_pct        REAL CHECK (humid_pct BETWEEN 0 AND 100),
    wind_dir_deg     REAL,
    wind_speed_mph   REAL CHECK (wind_speed_mph >= 0),
    wind_gust_mph    REAL,
    precip_in        REAL CHECK (precip_in >= 0),
    pressure_mb      REAL,
    visib_mi         REAL CHECK (visib_mi BETWEEN 0 AND 10),
    is_precip        INTEGER NOT NULL CHECK (is_precip IN (0,1)),
    is_freezing      INTEGER CHECK (is_freezing IN (0,1)),
    visib_band       TEXT NOT NULL,
    wind_band        TEXT
);

CREATE TABLE fact_flight (
    flight_id                INTEGER PRIMARY KEY,
    flight_date              TEXT    NOT NULL REFERENCES dim_date(date),
    carrier                  TEXT    NOT NULL REFERENCES dim_airline(carrier),
    flight_number            INTEGER NOT NULL,
    tailnum                  TEXT,             -- NULL only for cancelled flights
    origin                   TEXT    NOT NULL REFERENCES dim_airport(faa),
    dest                     TEXT    NOT NULL REFERENCES dim_airport(faa),
    route                    TEXT    NOT NULL,
    sched_dep_hour           INTEGER NOT NULL CHECK (sched_dep_hour BETWEEN 0 AND 23),
    sched_dep_minute_of_day  INTEGER NOT NULL CHECK (sched_dep_minute_of_day BETWEEN 0 AND 1439),
    dep_minute_of_day        INTEGER,
    dep_delay_min            INTEGER,          -- negative = early
    arr_delay_min            INTEGER,
    air_time_min             INTEGER,
    distance_mi              INTEGER NOT NULL CHECK (distance_mi > 0),
    flight_status            TEXT    NOT NULL CHECK (flight_status IN ('Completed','Cancelled','Diverted_or_Incomplete')),
    is_cancelled             INTEGER NOT NULL CHECK (is_cancelled IN (0,1)),
    is_dep_delayed           INTEGER CHECK (is_dep_delayed IN (0,1)),   -- dep_delay >= 15
    is_arr_delayed           INTEGER CHECK (is_arr_delayed IN (0,1)),   -- arr_delay >= 15
    time_recovered_min       INTEGER,          -- dep_delay - arr_delay (>0 = made up time in air)
    weather_key              TEXT REFERENCES fact_weather(weather_key)  -- NULL if no observation
);

CREATE INDEX ix_flight_date    ON fact_flight(flight_date);
CREATE INDEX ix_flight_carrier ON fact_flight(carrier);
CREATE INDEX ix_flight_origin  ON fact_flight(origin);
CREATE INDEX ix_flight_dest    ON fact_flight(dest);
CREATE INDEX ix_flight_tail    ON fact_flight(tailnum, flight_date, sched_dep_minute_of_day);
CREATE INDEX ix_flight_weather ON fact_flight(weather_key);

-- Convenience view for notebooks/BI. The analysis SQL writes its joins explicitly.
CREATE VIEW vw_flight_enriched AS
SELECT f.*, al.airline_name, ao.name AS origin_name, ad.name AS dest_name,
       p.plane_age_2013, p.manufacturer, p.seats,
       w.temp_f, w.wind_speed_mph, w.precip_in, w.visib_mi,
       w.is_precip, w.is_freezing, w.visib_band, w.wind_band,
       d.month, d.month_name, d.weekday_name, d.is_weekend, d.is_us_holiday
FROM fact_flight f
JOIN dim_airline al        ON al.carrier = f.carrier
JOIN dim_airport ao        ON ao.faa = f.origin
JOIN dim_airport ad        ON ad.faa = f.dest
JOIN dim_date d            ON d.date = f.flight_date
LEFT JOIN dim_plane p      ON p.tailnum = f.tailnum
LEFT JOIN fact_weather w   ON w.weather_key = f.weather_key;
