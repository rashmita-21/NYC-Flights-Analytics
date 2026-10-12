# NYC 2013 Flight Delays — End-to-End Analytics Project

An end-to-end analytics project using real-world flight data to investigate delay patterns and operational performance through **Python ETL, SQL data warehousing, exploratory data analysis, and an interactive Power BI dashboard**.

## 1. Problem Statement

**Why do flight delays build up throughout the day, and where are they most concentrated?**

Flight delays can accumulate throughout the day due to aircraft rotation, weather conditions, and operational disruptions.  
Identifying the airlines, airports, and routes contributing most to delays helps uncover patterns and potential operational bottlenecks.  
This project analyzes 336,776 NYC flights from 2013 to identify delay trends and support data-driven operational decisions.

## 2. Dataset

Source: [`nycflights13`](https://github.com/tidyverse/nycflights13)

The dataset contains **336,776 flights departing from New York City's three major airports — EWR, JFK, and LGA — during 2013**. It includes flight records alongside airline, airport, aircraft, and hourly weather data.

The multi-table structure makes it suitable for studying airline performance, airport contributions, weather associations, and operational delay patterns.

## 3. Project Structure

```text
NYC Flights Project/
├── data/raw/               # Raw source data
├── docs/
│   ├── qa_report.md        # Data-quality report
│   ├── dashboard_spec.md   # Dashboard model and specifications
│   └── figures/            # Exported charts
├── etl/
│   └── pipeline.py         # ETL and validation pipeline
├── notebooks/
│   └── eda.ipynb           # Exploratory data analysis
├── powerbi/data/           # Tables exported for Power BI
├── results/                # SQL analysis outputs
├── sql/
│   ├── schema.sql          # Warehouse schema
│   └── analysis/           # 14 SQL queries
└── warehouse/
    └── flights.db          # SQLite data warehouse
```

## 4. Data Model

The project uses a **star schema in SQLite** with two fact tables and four dimensions.

| Table | Records |
|---|---:|
| `fact_flight` | 336,776 |
| `fact_weather` | 26,115 |
| `dim_date` | 365 |
| `dim_airline` | 16 |
| `dim_airport` | 1,462 |
| `dim_plane` | 3,322 |

The schema supports analysis across flights, dates, airlines, airports, aircraft, and weather. See [`sql/schema.sql`](sql/schema.sql) for the table definitions and [`docs/dashboard_spec.md`](docs/dashboard_spec.md) for the Power BI data model.

## 5. ETL and Data Quality

The Python pipeline handles extraction, data validation, cleaning, loading, reconciliation, and export. It performs checks at the raw-data, post-cleaning, and post-load stages, recording results in `docs/qa_report.md`.

### Issues identified and handled

| Issue | Resolution |
|---|---|
| Wind-speed reading of 1,048 mph | Set to NULL as an implausible sensor value |
| Four destination airports missing from the source airport table | Added airport names; unknown coordinates left NULL |
| Inconsistent aircraft manufacturer names | Standardized 35 raw spellings to 31 canonical names |
| Aircraft speed column approximately 99.3% empty | Dropped instead of imputing unreliable values |

Missing aircraft records and unmatched hourly weather observations were retained as documented data limitations rather than filled with assumed values.

**Validation results**

| Check | Result |
|---|---:|
| PASS | 44 |
| FIXED | 4 |
| WARN | 7 |
| FAIL | 0 |
| Foreign-key violations | 0 |

Post-load reconciliation confirmed that the complete star-schema join preserved all 336,776 flight records without dropping or duplicating flights. The pipeline stops before loading if a hard validation failure occurs.

## 6. SQL Analysis

The project includes **14 standalone SQL queries**, each addressing a business question. The analyses use:

- Multi-table joins and aggregations
- `GROUP BY` and `HAVING`
- Common table expressions (CTEs)
- Window functions, including `RANK`, `LAG`, and running sums
- Self-joins and peer-adjusted comparisons

Query outputs are saved in `results/`, with the corresponding SQL files available in `sql/analysis/`.

## 7. Key Findings

**1. Aircraft rotation and subsequent delays**

When the previous NYC departure associated with an aircraft was on time, the next flight was delayed by 15 or more minutes in 22.7% of cases. When the previous departure was at least 60 minutes late, the rate increased to 83.0%. The average gap between departures was approximately 6.5 hours in both groups. This pattern is consistent with delays carrying forward through aircraft rotations, although the previous NYC departure is only a proxy for the full rotation.

**2. Peer-adjusted airline performance**

ExpressJet (EV) recorded 1.43 times its expected delay rate when compared with flights operating at the same airport and scheduled hour. This indicates poorer performance relative to that comparison baseline, but does not establish the underlying cause. AirTran and Southwest performed better relative to their respective expected rates.

**3. Weather conditions and delays**

Visibility below one mile was associated with 1.6 times the normal delay rate and 3.6 times the normal cancellation rate. Precipitation was associated with nearly double the delay rate and more than triple the cancellation rate. Temperatures at or below freezing changed the delay rate by less than one percentage point.

**4. Delays increase later in the day**

Departure delay rates rose from approximately 6–8% at 6 AM to over 30% by early evening. This trend is consistent with accumulating operational disruption, though the analysis does not establish that aircraft rotation alone causes the increase.

**5. Aircraft age shows limited predictive value**

Across carriers, delay rates remained relatively similar across aircraft-age bands, ranging from approximately 18.7% to 24.4%. The pattern was also broadly flat within individual carriers, suggesting that aircraft age alone may not be a useful predictor of delay risk in this dataset.

**6. Departure-delay minutes are concentrated across major destinations**

Chicago O'Hare and Atlanta together accounted for approximately one-tenth of total departure-delay minutes across more than 100 destinations. This highlights the value of examining both delay rates and the overall volume of delay minutes.

Further charts and analysis are available in [`notebooks/eda.ipynb`](notebooks/eda.ipynb).

## 8. Recommendations

- **Investigate early-day disruptions:** Examine whether preventing or reducing early delays could limit subsequent disruption across aircraft rotations.
- **Review ExpressJet's performance:** Investigate operational factors behind its peer-adjusted delay rate rather than attributing the difference to scheduling alone.
- **Plan for adverse visibility and precipitation:** Evaluate contingency measures for conditions associated with higher delays and cancellations.
- **Monitor high-contribution destinations:** Consider destination-level delay minutes when prioritizing operational reviews and scheduling buffers.

These are recommendations for further investigation, not measured improvements from implemented operational changes.

## 9. Power BI Dashboard

Built in **Microsoft Power BI**, the interactive dashboard presents the analysis across four pages:

- **Executive Overview:** Flight volume, cancellation rate, departure delay rate, average departure delay, and monthly trends.
- **Carrier Performance:** Airline comparisons and peer-adjusted delay performance.
- **Route & Airport Insights:** Airport contributions, route patterns, and delay concentration.
- **Weather & Delay Impact:** Delay and cancellation patterns across weather conditions.

Dashboard screenshots can be added here to give visitors a quick view of the finished report. The supporting tables are available in `powerbi/data/`.

## 10. Limitations

- The analysis covers a single year (2013) and flights departing from three NYC airports; results may not generalize to other years or airports.
- Weather and aircraft-age findings are observational associations, not causal estimates.
- Aircraft rotation is approximated using the same aircraft's previous NYC departure that day; the dataset does not confirm the aircraft's complete routing.
- The `Diverted_or_Incomplete` status is inferred from incomplete arrival information and may include diversions as well as incomplete records.
- Missing aircraft and weather matches limit the records available for analyses that depend on those sources.

## 11. Reproducing the Pipeline

Install the required packages:

```bash
python -m pip install nycflights13 pandas numpy
```

Run from the project root:

```bash
python etl/pipeline.py
```

The pipeline rebuilds the SQLite warehouse, regenerates the data-quality report, and exports the tables for Power BI. **Running it again replaces the existing warehouse contents.**

## Author

**Rashmita Perumanla**