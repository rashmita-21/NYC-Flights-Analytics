-- Q09 | Weekday, weekend and holiday effects
-- Business question: are some days structurally worse than others?
-- Techniques: JOIN dim_date, UNION ALL to stack two different groupings into one result
SELECT 'Weekday' AS dimension, d.weekday_name AS value, d.weekday_num AS sort_key,
       COUNT(*) AS scheduled_flights,
       ROUND(100.0 * SUM(f.is_dep_delayed) / COUNT(f.is_dep_delayed), 2) AS dep_delay_rate_pct,
       ROUND(100.0 * SUM(f.is_cancelled) / COUNT(*), 2)                  AS cancel_rate_pct
FROM fact_flight f JOIN dim_date d ON d.date = f.flight_date
GROUP BY d.weekday_num, d.weekday_name
UNION ALL
SELECT 'Holiday', CASE d.is_us_holiday WHEN 1 THEN 'US federal holiday' ELSE 'Regular day' END,
       100 + d.is_us_holiday,
       COUNT(*),
       ROUND(100.0 * SUM(f.is_dep_delayed) / COUNT(f.is_dep_delayed), 2),
       ROUND(100.0 * SUM(f.is_cancelled) / COUNT(*), 2)
FROM fact_flight f JOIN dim_date d ON d.date = f.flight_date
GROUP BY d.is_us_holiday
ORDER BY 1 DESC, 3;
