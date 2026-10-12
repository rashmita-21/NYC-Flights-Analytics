-- Q10 | The ten days with the most cancellations, and what the weather was doing
-- Business question: are mass cancellations explained by weather?
-- Techniques: two CTEs at daily grain joined together (avoids fan-out by aggregating BEFORE joining),
--             LEFT JOIN, USING
-- Notes: weather columns describe conditions at the scheduled departure hour of that day's flights
--        (flights joined to their hourly observation), so no timezone conversion is needed.
WITH daily_flights AS (
    SELECT flight_date,
           COUNT(*)                       AS scheduled_flights,
           SUM(is_cancelled)              AS cancelled_flights,
           ROUND(100.0 * SUM(is_cancelled) / COUNT(*), 1)                    AS cancel_rate_pct,
           ROUND(100.0 * SUM(is_dep_delayed) / COUNT(is_dep_delayed), 1)     AS dep_delay_rate_pct
    FROM fact_flight
    GROUP BY flight_date
),
daily_weather AS (
    SELECT f.flight_date,
           ROUND(AVG(w.precip_in), 3)  AS avg_precip_in_per_hour,
           ROUND(MIN(w.visib_mi), 1)   AS min_visibility_mi,
           ROUND(MAX(w.wind_speed_mph), 1) AS max_wind_mph,
           ROUND(AVG(w.temp_f), 1)     AS avg_temp_f
    FROM fact_flight f
    JOIN fact_weather w ON w.weather_key = f.weather_key
    GROUP BY f.flight_date
)
SELECT df.flight_date, dd.weekday_name, df.scheduled_flights, df.cancelled_flights, df.cancel_rate_pct,
       df.dep_delay_rate_pct, dw.avg_precip_in_per_hour, dw.min_visibility_mi, dw.max_wind_mph, dw.avg_temp_f
FROM daily_flights df
JOIN dim_date dd ON dd.date = df.flight_date
LEFT JOIN daily_weather dw USING (flight_date)
ORDER BY df.cancelled_flights DESC
LIMIT 10;
