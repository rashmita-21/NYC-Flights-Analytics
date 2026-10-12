-- Q02 | Carrier ranking inside each NYC airport
-- Business question: is a carrier's poor record the same at EWR, JFK and LGA?
-- Techniques: CTEs, RANK() OVER (PARTITION BY ...), comparison to a group benchmark
WITH per_carrier AS (
    SELECT f.origin, f.carrier, al.airline_name,
           COUNT(*)                  AS scheduled_flights,
           COUNT(f.is_dep_delayed)   AS departed,
           SUM(f.is_dep_delayed)     AS delayed
    FROM fact_flight f
    JOIN dim_airline al ON al.carrier = f.carrier
    GROUP BY f.origin, f.carrier, al.airline_name
    HAVING COUNT(*) >= 500
),
per_origin AS (
    SELECT origin, 100.0 * SUM(is_dep_delayed) / COUNT(is_dep_delayed) AS origin_rate
    FROM fact_flight
    GROUP BY origin
)
SELECT c.origin, c.airline_name, c.scheduled_flights,
       ROUND(100.0 * c.delayed / c.departed, 2)                       AS dep_delay_rate_pct,
       ROUND(o.origin_rate, 2)                                        AS airport_rate_pct,
       ROUND(100.0 * c.delayed / c.departed - o.origin_rate, 2)       AS vs_airport_pts,
       RANK() OVER (PARTITION BY c.origin ORDER BY 1.0 * c.delayed / c.departed DESC) AS rank_worst_at_airport
FROM per_carrier c
JOIN per_origin o ON o.origin = c.origin
ORDER BY c.origin, rank_worst_at_airport;
