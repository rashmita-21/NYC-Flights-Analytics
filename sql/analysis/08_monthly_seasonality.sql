-- Q08 | Seasonality by month
-- Business question: which months are worst, and how fast does performance change month to month?
-- Techniques: JOIN dim_date, CTE, LAG() for month-over-month change
WITH m AS (
    SELECT d.month, d.month_name,
           COUNT(*)                                                          AS scheduled_flights,
           ROUND(100.0 * SUM(f.is_dep_delayed) / COUNT(f.is_dep_delayed), 2) AS dep_delay_rate_pct,
           ROUND(100.0 * SUM(f.is_cancelled) / COUNT(*), 2)                  AS cancel_rate_pct
    FROM fact_flight f
    JOIN dim_date d ON d.date = f.flight_date
    GROUP BY d.month, d.month_name
)
SELECT month_name, scheduled_flights, dep_delay_rate_pct,
       ROUND(dep_delay_rate_pct - LAG(dep_delay_rate_pct) OVER (ORDER BY month), 2) AS mom_change_pts,
       cancel_rate_pct
FROM m
ORDER BY month;
