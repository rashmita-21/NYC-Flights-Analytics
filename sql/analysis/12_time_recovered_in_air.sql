-- Q12 | How much lateness do pilots recover en route?
-- Business question: when a flight leaves 15+ minutes late, how much of that is made up by landing,
--                    and does the answer depend on flight length?
-- Techniques: CASE bucketing on distance, filtered aggregation
-- Notes: time_recovered_min = dep_delay - arr_delay; positive means the delay shrank in the air.
SELECT CASE WHEN distance_mi < 500  THEN '1) under 500 mi'
            WHEN distance_mi < 1000 THEN '2) 500-999 mi'
            WHEN distance_mi < 2000 THEN '3) 1,000-1,999 mi'
            ELSE                         '4) 2,000+ mi' END AS distance_band,
       COUNT(*)                                   AS late_departures,
       ROUND(AVG(dep_delay_min), 1)               AS avg_dep_delay_min,
       ROUND(AVG(arr_delay_min), 1)               AS avg_arr_delay_min,
       ROUND(AVG(time_recovered_min), 1)          AS avg_min_recovered,
       ROUND(100.0 * SUM(CASE WHEN arr_delay_min < 15 THEN 1 ELSE 0 END) / COUNT(*), 1)
                                                  AS pct_arrive_on_time_despite_late_departure
FROM fact_flight
WHERE flight_status = 'Completed' AND dep_delay_min >= 15
GROUP BY distance_band
ORDER BY distance_band;
