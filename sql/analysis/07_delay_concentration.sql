-- Q07 | Where do the delay minutes pile up? (Pareto by destination)
-- Business question: is delay pain spread evenly, or concentrated in a few places?
-- Techniques: CTE, window SUM() OVER () for share, running total for cumulative share, ROW_NUMBER
-- Notes: delay minutes = departure minutes late, counting only positive delays (early departures ignored).
WITH d AS (
    SELECT f.dest, ad.name AS dest_airport,
           COUNT(*) AS scheduled_flights,
           SUM(CASE WHEN f.dep_delay_min > 0 THEN f.dep_delay_min ELSE 0 END) AS delay_minutes
    FROM fact_flight f
    JOIN dim_airport ad ON ad.faa = f.dest
    GROUP BY f.dest, ad.name
),
ranked AS (
    SELECT dest, dest_airport, scheduled_flights, delay_minutes,
           ROW_NUMBER() OVER (ORDER BY delay_minutes DESC)                       AS rn,
           100.0 * delay_minutes / SUM(delay_minutes) OVER ()                    AS share_of_delay_pct,
           100.0 * scheduled_flights / SUM(scheduled_flights) OVER ()            AS share_of_flights_pct,
           100.0 * SUM(delay_minutes) OVER (ORDER BY delay_minutes DESC
                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
                 / SUM(delay_minutes) OVER ()                                    AS cumulative_share_pct
    FROM d
)
SELECT rn AS rank, dest, dest_airport, scheduled_flights, delay_minutes,
       ROUND(share_of_flights_pct, 2)  AS share_of_flights_pct,
       ROUND(share_of_delay_pct, 2)    AS share_of_delay_pct,
       ROUND(cumulative_share_pct, 2)  AS cumulative_share_pct
FROM ranked
WHERE rn <= 15
ORDER BY rn;
