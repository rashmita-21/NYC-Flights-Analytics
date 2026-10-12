-- Q13 | Carrier performance adjusted for WHEN and WHERE they fly
-- Business question: is a carrier late because it is badly run, or because it schedules into
--                    the worst airport-hours? (Q01 cannot tell these apart.)
-- Method: indirect standardisation. For every (airport, scheduled hour) cell, the "expected" delay
--         rate for a carrier is the delay rate of ALL OTHER carriers in that same cell (leave-one-out,
--         so a carrier never benchmarks against itself). Observed / Expected > 1 means worse than peers
--         flying at the same airport and hour.
-- Techniques: three chained CTEs, self-referencing joins on a composite key, leave-one-out arithmetic,
--             RANK() OVER on an aggregate, comparing raw vs adjusted ranking
WITH cell AS (
    SELECT origin, sched_dep_hour,
           SUM(is_dep_delayed)   AS cell_delayed,
           COUNT(is_dep_delayed) AS cell_n
    FROM fact_flight
    WHERE is_dep_delayed IS NOT NULL
    GROUP BY origin, sched_dep_hour
),
carrier_cell AS (
    SELECT origin, sched_dep_hour, carrier,
           SUM(is_dep_delayed)   AS car_delayed,
           COUNT(is_dep_delayed) AS car_n
    FROM fact_flight
    WHERE is_dep_delayed IS NOT NULL
    GROUP BY origin, sched_dep_hour, carrier
),
scored AS (
    SELECT cc.carrier, cc.car_n, cc.car_delayed,
           1.0 * cc.car_n * (c.cell_delayed - cc.car_delayed) / (c.cell_n - cc.car_n) AS expected_delayed
    FROM carrier_cell cc
    JOIN cell c ON c.origin = cc.origin AND c.sched_dep_hour = cc.sched_dep_hour
    WHERE c.cell_n > cc.car_n            -- skip cells where the carrier is the only operator
)
SELECT al.airline_name,
       SUM(s.car_n)                                                AS flights_compared,
       ROUND(100.0 * SUM(s.car_delayed) / SUM(s.car_n), 2)         AS actual_rate_pct,
       ROUND(100.0 * SUM(s.expected_delayed) / SUM(s.car_n), 2)    AS peer_expected_rate_pct,
       ROUND(SUM(s.car_delayed) / SUM(s.expected_delayed), 2)      AS observed_to_expected,
       RANK() OVER (ORDER BY 1.0 * SUM(s.car_delayed) / SUM(s.car_n) DESC)          AS raw_rank_worst,
       RANK() OVER (ORDER BY SUM(s.car_delayed) / SUM(s.expected_delayed) DESC)     AS adjusted_rank_worst
FROM scored s
JOIN dim_airline al ON al.carrier = s.carrier
GROUP BY s.carrier, al.airline_name
HAVING SUM(s.car_n) >= 500
ORDER BY adjusted_rank_worst;
