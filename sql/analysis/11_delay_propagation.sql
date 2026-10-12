-- Q11 | Does a late aircraft make its next departure late? (rotation effect, proxy)
-- Business question: how much of today's delay is inherited from the aircraft's earlier flight?
-- Techniques: LAG() OVER (PARTITION BY tailnum, date ORDER BY scheduled time), named WINDOW clause,
--             CTE, CASE bucketing on the lagged value
-- Notes: the dataset only has departures from NYC, so "previous flight" means the same aircraft's
--        previous NYC departure that day (it flew out and back in between). Shared conditions
--        such as weather or the carrier also raise both flights' delays, so this is an upper bound
--        on inheritance. The notebook stratifies to check.
WITH seq AS (
    SELECT f.flight_id, f.dep_delay_min, f.is_dep_delayed,
           f.sched_dep_minute_of_day - LAG(f.sched_dep_minute_of_day) OVER w AS gap_min,
           LAG(f.dep_delay_min) OVER w                                        AS prev_dep_delay_min
    FROM fact_flight f
    WHERE f.tailnum IS NOT NULL AND f.is_cancelled = 0
    WINDOW w AS (PARTITION BY f.tailnum, f.flight_date
                 ORDER BY f.sched_dep_minute_of_day, f.flight_id)
)
SELECT CASE WHEN prev_dep_delay_min <= 0  THEN '1) previous flight on time or early'
            WHEN prev_dep_delay_min < 15  THEN '2) previous flight 1-14 min late'
            WHEN prev_dep_delay_min < 60  THEN '3) previous flight 15-59 min late'
            ELSE                               '4) previous flight 60+ min late' END AS previous_flight,
       COUNT(*)                                                       AS flights,
       ROUND(AVG(gap_min) / 60.0, 1)                                  AS avg_hours_between_departures,
       ROUND(100.0 * SUM(is_dep_delayed) / COUNT(is_dep_delayed), 2)  AS this_flight_delay_rate_pct,
       ROUND(AVG(dep_delay_min), 1)                                   AS this_flight_avg_delay_min
FROM seq
WHERE prev_dep_delay_min IS NOT NULL
GROUP BY previous_flight
ORDER BY previous_flight;
