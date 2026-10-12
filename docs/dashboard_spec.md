# Power BI dashboard spec — NYC 2013 Flight Delays

Built by hand in Power BI Desktop, using the tables exported to `powerbi/data/*.csv`
(the same tables loaded into `warehouse/flights.db`). This spec is the build plan: data model,
KPIs, DAX measures, and one layout per page. Screenshots go in `docs/figures/dashboard/` once
built.

## 1. Load and model

Import all six CSVs from `powerbi/data/`: `dim_date`, `dim_airline`, `dim_airport`, `dim_plane`,
`fact_weather`, `fact_flight`.

Relationships (all single-direction, "many" side is `fact_flight` unless noted):

| From | To | Cardinality |
|---|---|---|
| fact_flight[flight_date] | dim_date[date] | many-to-one |
| fact_flight[carrier] | dim_airline[carrier] | many-to-one |
| fact_flight[origin] | dim_airport[faa] | many-to-one (rename role "Origin Airport") |
| fact_flight[dest] | dim_airport[faa] | many-to-one, **inactive** (rename role "Destination Airport"; activate with `USERELATIONSHIP` where a dest-based measure needs it) |
| fact_flight[tailnum] | dim_plane[tailnum] | many-to-one, optional (15% of flights have no match — this is real, not a load error) |
| fact_flight[weather_key] | fact_weather[weather_key] | many-to-one, optional (0.5% have no match) |

Power BI needs two roles for `dim_airport` (origin vs destination). Either import `dim_airport`
twice (`dim_airport_origin`, `dim_airport_dest`) or keep one table and mark the dest relationship
inactive, using `USERELATIONSHIP` in the handful of destination-based measures (worst routes,
delay concentration by destination). The two-import approach is simpler for a first build.

Mark `dim_date[date]` as a **Date table** (Model view -> column tools). Hide foreign key columns
that aren't meant for slicing (`weather_key`, raw lat/lon) to keep the field list clean.

## 2. Core DAX measures

```dax
Scheduled Flights := COUNTROWS(fact_flight)

Completed Flights := CALCULATE([Scheduled Flights], fact_flight[flight_status] = "Completed")

Cancelled Flights := CALCULATE([Scheduled Flights], fact_flight[is_cancelled] = 1)

Cancellation Rate := DIVIDE([Cancelled Flights], [Scheduled Flights])

Departed Flights := CALCULATE([Scheduled Flights], NOT ISBLANK(fact_flight[is_dep_delayed]))

Delayed Departures := CALCULATE([Scheduled Flights], fact_flight[is_dep_delayed] = 1)

Dep Delay Rate := DIVIDE([Delayed Departures], [Departed Flights])

Avg Dep Delay (min) :=
AVERAGEX(FILTER(fact_flight, NOT ISBLANK(fact_flight[dep_delay_min])), fact_flight[dep_delay_min])

Arrived Flights := CALCULATE([Scheduled Flights], NOT ISBLANK(fact_flight[is_arr_delayed]))

Arr Delay Rate := DIVIDE(CALCULATE([Scheduled Flights], fact_flight[is_arr_delayed] = 1), [Arrived Flights])

Avg Minutes Recovered in Air :=
AVERAGEX(FILTER(fact_flight, NOT ISBLANK(fact_flight[time_recovered_min])), fact_flight[time_recovered_min])

-- Peer-adjusted carrier score (mirrors sql/analysis/13). Precompute in Power Query from
-- results/13_carrier_adjusted_performance.csv rather than re-deriving in DAX; simpler and
-- matches the SQL of record exactly.
Observed to Expected Ratio := AVERAGE(carrier_adjusted[observed_to_expected])
```

Delay-rate measures use `DIVIDE`, never manual division, to avoid divide-by-zero on filtered
slices (e.g. a single day with zero departed flights).

## 3. Pages

### Page 1 — Executive overview
KPI cards across the top: **Scheduled Flights**, **Cancellation Rate**, **Dep Delay Rate**, **Avg
Dep Delay (min)**, **Avg Minutes Recovered in Air**. Below: a line chart of Dep Delay Rate by
month (x = `dim_date[month_name]`, sorted by `dim_date[month]`), a bar chart of Dep Delay Rate by
`dim_airport[faa]` (origin), and a slicer panel (carrier, origin airport, month) that filters the
whole page. This page answers "how are we doing, overall and over time."

### Page 2 — Carrier performance
Two side-by-side bar charts reproducing the notebook's Section 2 comparison: raw Dep Delay Rate
by carrier, and Observed-to-Expected Ratio by carrier (loaded from
`results/13_carrier_adjusted_performance.csv` as a supporting table). A table below lists both
ranks side by side so a viewer can see which carriers move most between raw and adjusted. Tooltip
on each bar explains the peer-adjustment in one sentence.

### Page 3 — When delays happen
Three visuals: a line chart of Dep Delay Rate by `sched_dep_hour`, a column chart by
`dim_date[weekday_name]` (sorted Monday-first), and a small-multiples or single line chart by
month. A card highlighting the delay-propagation finding: "previous flight 60+ min late -> 83% of
next flights delayed vs. 23% when on time" (static text box, since this needs the windowed SQL
result from `results/11_delay_propagation.csv` loaded as a small supporting table with a matching
bar chart).

### Page 4 — Weather impact
A bar chart of Delay Rate Lift by weather band (visibility, wind, precipitation, temperature),
loaded from `results/04_weather_impact.csv` as a supporting table (this metric needs the SQL
join to fact_weather and is precomputed rather than re-derived live in DAX, to keep the model
simple). Include the caveat text: "Association from one year of NYC data — not a causal estimate."

### Page 5 — Routes and destinations
A map visual (bing/ArcGIS) plotting destinations sized by `Scheduled Flights` and colored by Dep
Delay Rate, using `dim_airport[lat]/[lon]`. Below it, a table of the worst 15 routes
(`results/06_worst_routes.csv`) and a Pareto chart of delay-minute concentration by destination
(`results/07_delay_concentration.csv`, combo chart: bars = share of delay minutes, line =
cumulative share).

### Page 6 — Data quality (optional, for the "so what" of the ETL)
A single page summarizing `docs/qa_report.md`: counts of PASS/FIXED/WARN checks (a simple KPI
card row) and a short table of the FIXED/WARN items, so a reviewer can see the pipeline's rigor
without opening the markdown file.

## 4. Style

- Palette: one accent blue (`#1F5C99`) for primary series, a muted red (`#D1495B`) reserved only
  for "this is the problem" bars (e.g. the worst carrier, the worst weather band), grey (`#9AA3AB`)
  for context bars. Matches the notebook's chart palette for visual consistency between the two
  deliverables.
- One consistent header per page: title top-left, page-level slicers top-right.
- Every rate visual uses a percentage format with 1 decimal place; every KPI card includes a
  one-line subtitle stating the scope (e.g. "of flights that departed").
- Tooltips on every complex visual (peer-adjusted score, delay concentration, weather lift) explain
  the calculation in plain language — a recruiter or interviewer should be able to hover and
  understand it without reading the SQL.

## 5. What NOT to build

Keep this to one dataset and the pages above. Resist adding a generic "sales-style" KPI wall or
unrelated visuals just to fill space — a tight, explainable six-page report beats a sprawling one
for an interview context.
