-- Q05 | Aircraft age vs delays, controlling for carrier
-- Business question: do older aircraft cause more delays, or do old planes just belong to certain airlines?
-- Techniques: INNER JOIN to dim_plane, CASE bucketing, conditional aggregation (pivot by carrier)
-- Notes: covers the ~85% of flights whose tail number exists in dim_plane (see Q00).
--        Reading across a row (one age band, several carriers) is the confounder check.
WITH aged AS (
    SELECT f.carrier, f.is_dep_delayed,
           CASE WHEN p.plane_age_2013 < 5  THEN '1) under 5 yrs'
                WHEN p.plane_age_2013 < 10 THEN '2) 5-9 yrs'
                WHEN p.plane_age_2013 < 15 THEN '3) 10-14 yrs'
                WHEN p.plane_age_2013 < 20 THEN '4) 15-19 yrs'
                ELSE '5) 20+ yrs' END AS age_band
    FROM fact_flight f
    JOIN dim_plane p ON p.tailnum = f.tailnum
    WHERE f.is_dep_delayed IS NOT NULL
      AND p.plane_age_2013 IS NOT NULL
)
SELECT age_band,
       COUNT(*)                                                     AS flights,
       ROUND(100.0 * SUM(is_dep_delayed) / COUNT(*), 2)             AS all_carriers_rate_pct,
       ROUND(100.0 * SUM(CASE WHEN carrier = 'UA' THEN is_dep_delayed END)
             / COUNT(CASE WHEN carrier = 'UA' THEN 1 END), 2)       AS UA_rate_pct,
       ROUND(100.0 * SUM(CASE WHEN carrier = 'B6' THEN is_dep_delayed END)
             / COUNT(CASE WHEN carrier = 'B6' THEN 1 END), 2)       AS B6_rate_pct,
       ROUND(100.0 * SUM(CASE WHEN carrier = 'EV' THEN is_dep_delayed END)
             / COUNT(CASE WHEN carrier = 'EV' THEN 1 END), 2)       AS EV_rate_pct,
       ROUND(100.0 * SUM(CASE WHEN carrier = 'DL' THEN is_dep_delayed END)
             / COUNT(CASE WHEN carrier = 'DL' THEN 1 END), 2)       AS DL_rate_pct,
       ROUND(100.0 * SUM(CASE WHEN carrier = 'AA' THEN is_dep_delayed END)
             / COUNT(CASE WHEN carrier = 'AA' THEN 1 END), 2)       AS AA_rate_pct
FROM aged
GROUP BY age_band
ORDER BY age_band;
