-- Q04 | Weather impact on delays and cancellations
-- Business question: how much worse is the delay/cancellation rate in bad weather than average?
-- Techniques: INNER JOIN fact_flight to fact_weather, CTEs, CASE bucketing, UNION ALL,
--             CROSS JOIN to a one-row baseline, lift = band rate / overall rate
-- Notes: flights with no weather observation (0.46%) drop out of the INNER JOIN by design.
--        This shows association, not proof of cause (see the notebook for caveats).
WITH j AS (
    SELECT f.is_dep_delayed, f.is_cancelled, f.dep_delay_min,
           w.visib_band, w.wind_band,
           CASE w.is_precip   WHEN 1 THEN '2) precipitation' ELSE '1) dry' END       AS precip_band,
           CASE w.is_freezing WHEN 1 THEN '1) at or below 32F'
                              WHEN 0 THEN '2) above 32F' END                          AS temp_band
    FROM fact_flight f
    JOIN fact_weather w ON w.weather_key = f.weather_key
),
base AS (
    SELECT 100.0 * SUM(is_dep_delayed) / COUNT(is_dep_delayed) AS base_delay,
           100.0 * SUM(is_cancelled)   / COUNT(*)              AS base_cancel
    FROM j
),
banded AS (
    SELECT 'Visibility'    AS factor, visib_band  AS band, is_dep_delayed, is_cancelled, dep_delay_min FROM j
    UNION ALL
    SELECT 'Wind speed',   wind_band,  is_dep_delayed, is_cancelled, dep_delay_min FROM j WHERE wind_band IS NOT NULL
    UNION ALL
    SELECT 'Precipitation', precip_band, is_dep_delayed, is_cancelled, dep_delay_min FROM j
    UNION ALL
    SELECT 'Temperature',  temp_band,  is_dep_delayed, is_cancelled, dep_delay_min FROM j WHERE temp_band IS NOT NULL
)
SELECT b.factor, b.band,
       COUNT(*)                                                        AS scheduled_flights,
       ROUND(100.0 * SUM(b.is_dep_delayed) / COUNT(b.is_dep_delayed), 2) AS dep_delay_rate_pct,
       ROUND(100.0 * SUM(b.is_dep_delayed) / COUNT(b.is_dep_delayed) / base.base_delay, 2) AS delay_lift_vs_all,
       ROUND(100.0 * SUM(b.is_cancelled) / COUNT(*), 2)                AS cancel_rate_pct,
       ROUND(100.0 * SUM(b.is_cancelled) / COUNT(*) / base.base_cancel, 2) AS cancel_lift_vs_all
FROM banded b
CROSS JOIN base
GROUP BY b.factor, b.band
ORDER BY b.factor, b.band;
