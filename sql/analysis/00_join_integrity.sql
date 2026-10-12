-- Q00 | Join integrity: what does each join type do to the row count?
-- Business question: can we trust the numbers once we join facts to dimensions?
-- Techniques: INNER vs LEFT JOIN, anti-join (LEFT JOIN ... IS NULL), UNION ALL, scalar subquery
-- Why it matters: an INNER JOIN to dim_plane silently drops ~15% of flights. Every analysis
-- that needs plane data must state that it covers matched flights only.
SELECT 'All flights (fact_flight)' AS step, COUNT(*) AS rows_returned,
       0.0 AS pct_lost_vs_all
FROM fact_flight
UNION ALL
SELECT 'INNER JOIN dim_plane', COUNT(*),
       ROUND(100.0 * (1 - COUNT(*) * 1.0 / (SELECT COUNT(*) FROM fact_flight)), 2)
FROM fact_flight f JOIN dim_plane p ON p.tailnum = f.tailnum
UNION ALL
SELECT 'LEFT JOIN dim_plane', COUNT(*),
       ROUND(100.0 * (1 - COUNT(*) * 1.0 / (SELECT COUNT(*) FROM fact_flight)), 2)
FROM fact_flight f LEFT JOIN dim_plane p ON p.tailnum = f.tailnum
UNION ALL
SELECT 'INNER JOIN fact_weather', COUNT(*),
       ROUND(100.0 * (1 - COUNT(*) * 1.0 / (SELECT COUNT(*) FROM fact_flight)), 2)
FROM fact_flight f JOIN fact_weather w ON w.weather_key = f.weather_key
UNION ALL
SELECT 'LEFT JOIN fact_weather', COUNT(*),
       ROUND(100.0 * (1 - COUNT(*) * 1.0 / (SELECT COUNT(*) FROM fact_flight)), 2)
FROM fact_flight f LEFT JOIN fact_weather w ON w.weather_key = f.weather_key
UNION ALL
SELECT 'Anti-join: flights with a tail number but no plane record', COUNT(*),
       ROUND(100.0 * COUNT(*) * 1.0 / (SELECT COUNT(*) FROM fact_flight), 2)
FROM fact_flight f LEFT JOIN dim_plane p ON p.tailnum = f.tailnum
WHERE f.tailnum IS NOT NULL AND p.tailnum IS NULL;
