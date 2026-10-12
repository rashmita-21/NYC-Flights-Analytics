-- Q01 | Carrier scorecard
-- Business question: which airlines run late or cancel most, and who makes up time in the air?
-- Techniques: INNER JOIN, GROUP BY, conditional aggregation, HAVING
-- Notes: COUNT(col) ignores NULLs, so COUNT(is_dep_delayed) = flights that actually departed.
--        Carriers with <500 scheduled flights are dropped because their rates are unstable.
SELECT al.airline_name,
       f.carrier,
       COUNT(*)                                                       AS scheduled_flights,
       ROUND(100.0 * SUM(f.is_cancelled) / COUNT(*), 2)               AS cancel_rate_pct,
       ROUND(100.0 * SUM(f.is_dep_delayed) / COUNT(f.is_dep_delayed), 2) AS dep_delay_rate_pct,
       ROUND(AVG(f.dep_delay_min), 1)                                 AS avg_dep_delay_min,
       ROUND(100.0 * SUM(f.is_arr_delayed) / COUNT(f.is_arr_delayed), 2) AS arr_delay_rate_pct,
       ROUND(AVG(f.time_recovered_min), 1)                            AS avg_min_recovered_in_air
FROM fact_flight f
JOIN dim_airline al ON al.carrier = f.carrier
GROUP BY f.carrier, al.airline_name
HAVING COUNT(*) >= 500
ORDER BY dep_delay_rate_pct DESC;
