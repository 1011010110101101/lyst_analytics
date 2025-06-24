# Analytics Engineer Test (dbt + Snowflake)

## Overview

This project demonstrates the completion of a data modeling exercise using **dbt** on top of **Snowflake**, designed to evaluate proficiency in building performant, reliable, and BI-ready datasets. The work includes the creation of deduplicated track data and product-country availability modeling.

---

## Tasks Summary

### Task 1.1 – Create `TRACKS` Table

**Objective**: Combine and deduplicate user track events from `tracks_raw` and `tracks_backfill`.

- Data sources: `DATA_SOURCE.tracks_raw`, `DATA_SOURCE.tracks_backfill`
- Output: `fct_tracks`
- Logic:
  - Unified and deduplicated `track_id` values using `ROW_NUMBER()` over `insert_timestamp DESC`
  - Ensured `track_id` uniqueness and removed null values
  - Stored as an **incremental model**

### Task 1.2 – Incrementally Update `TRACKS`

**Objective**: Load only new batches of data based on the `insert_timestamp`.

- On initial run: Full load from both sources
- On incremental runs: Only loads records where `insert_timestamp` > `min(insert_timestamp)` of existing data
- Maintains latest `track_id` entry per insert logic

---

### Task 2.1 – Create `PRODUCT_COUNTRIES` Table

**Objective**: Normalize product availability data by date and country from allowed/disallowed arrays.

- Data sources: `DATA_SOURCE.products`, `DATA_SOURCE.countries`
- Output: `fct_product_countries`
- Logic:
  - Flattened allowed and disallowed arrays using `LATERAL FLATTEN`
  - Cross-joined all products to countries by date
  - Applied logic:
    - If `allowed_countries` present → only allowed countries
    - If `disallowed_countries` present → available in all **except** these
    - If both are empty/null → available everywhere
  - Enriched output with readable country names

---

## Project Structure

```
models/
├── staging/
│   ├── stg_tracks_raw.sql
│   ├── stg_tracks_backfill.sql
│   ├── stg_products.sql
│   ├── stg_countries.sql
├── marts/
│   ├── fct_tracks.sql
│   ├── fct_product_countries.sql
│   ├── fct_tracks.yml
│   ├── product_availability_schema.yml

dbt_project.yml
packages.yml
```

---

## Testing & Validation

- **Unique and Not Null** tests on primary keys:
  - `track_id` in `fct_tracks`
  - `product_id`, `date`, `country_code` in `fct_product_countries`
- **dbt-utils** used for composite uniqueness

---

## Assumptions

- `insert_timestamp` correctly reflects freshness of the batch
- Flattening logic assumes country arrays do not contain malformed values
- Products without any allowed/disallowed logic are globally available

---

## Future Enhancements

- Add region mappings to `fct_product_countries` for aggregated analysis
- Add snapshotting or slowly-changing-dimension support for track updates
- Extend availability logic with time-zone normalization if needed

---

## Usage

Run the project with:

```bash
dbt run
```

### For incremental updates:

```
dbt build --select fct_tracks
 ```

### Test the models:

```
dbt test
```

---

## Credits

Built for the Analytics Engineer Test using:
- dbt (v1.3+)
- Snowflake
- dbt-utils

