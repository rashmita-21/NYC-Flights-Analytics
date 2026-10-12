-- Q06 | Worst routes by delay rate
-- Business question: which routes should an operations team look at first?
-- Techniques: SELF-JOIN (dim_airport joined twice as origin and destination), CTE, RANK() OVER
-- Notes: routes with <500 flights excluded for stable rates.
WITH r AS (
    SELECT f.origin, f.dest, ao.name AS origin_airport, ad.name AS dest_airport,
           COUNT(*)                                                         AS scheduled_flights,
           ROUND(100.0 * SUM(f.is_dep_delayed) / COUNT(f.is_dep_delayed), 2) AS dep_delay_rate_pct,
           ROUND(AVG(f.dep_delay_min), 1)                                   AS avg_dep_delay_min,
           ROUND(100.0 * SUM(f.is_cancelled) / COUNT(*), 2)                 AS cancel_rate_pct
    FROM fact_flight f
    JOIN dim_airport ao ON ao.faa = f.origin
    JOIN dim_airport ad ON ad.faa = f.dest
    GROUP BY f.origin, f.dest, ao.name, ad.name
    HAVING COUNT(*) >= 500
)
SELECT RANK() OVER (ORDER BY dep_delay_rate_pct DESC) AS rank_worst, *
FROM r
ORDER BY rank_worst
LIMIT 15;
