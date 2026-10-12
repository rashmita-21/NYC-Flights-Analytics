-- Q03 | Delay build-up through the day
-- Business question: do delays accumulate as the day goes on?
-- Techniques: GROUP BY on a numeric dimension, HAVING for minimum volume
-- Notes: hours with <100 flights are dropped (a handful of flights make a meaningless rate).
SELECT sched_dep_hour,
       COUNT(*)                                                          AS scheduled_flights,
       ROUND(100.0 * SUM(is_dep_delayed) / COUNT(is_dep_delayed), 2)     AS dep_delay_rate_pct,
       ROUND(AVG(dep_delay_min), 1)                                      AS avg_dep_delay_min,
       ROUND(100.0 * SUM(is_cancelled) / COUNT(*), 2)                    AS cancel_rate_pct
FROM fact_flight
GROUP BY sched_dep_hour
HAVING COUNT(*) >= 100
ORDER BY sched_dep_hour;
