# Netflix SQL Analysis

An end-to-end SQL project analyzing Netflix's content catalog using PostgeSQL. This project demonstrates advanced SQL skills including schema design, data normalization, transformation layers, window functions, CTEs, and data quality analysis.

## 📁 Repository Structure
```
netflix-sql-analysis/
│
├── README.md
├── data/
│   └── netflix_titles.csv          # Raw dataset (source: Kaggle)
├── schema/
│   ├── 01_create_raw.sql           # Raw ingestion table
│   ├── 02_create_normalized.sql    # Normalized relational schema
│   └── schema_diagram.png          # ERD diagram
├── ingestion/
│   ├── 03_load_raw.sql             # load CSV
│   └── 04_transform.sql            # Populate normalized tables
└── analysis/
    └── 05_analysis.sql             
```

## 📊 Dataset
- Source: [Netflix Movies and TV Shows — Kaggle](https://www.kaggle.com/datasets/shivamb/netflix-shows/data)
- Size: 8,807 titles
- Fields: show_id, type, title, director, cast, country, date_added, release_year, rating, duration, listed_in, description

## 🏗️ Schema Design
The raw CSV was normalized into a proper relational schema to handle multi-value fields (genres, cast, directors, countries) that were stored as comma-separated strings in the source data.

Tables

| Table | Description |
|-----------|-----------|
| netflix_raw | Raw ingestion table; mirrors source CSV |
| netflix_shows | Core show metadata (cleaned, typed) |
| netflix_genres | Genre lookup table |
| netflix_show_genres | Bridge table: show ↔ genre (many-to-many) |
| netflix_directors | Director lookup table |
| netflix_show_directors | Bridge table: show ↔ director (many-to-many) |
| netflix_cast | Cast member lookup table |
| netflix_show_cast | Bridge table: show ↔ cast (many-to-many) |
| netflix_countries | Country lookup table |
| netflix_show_countries | Bridge table: show ↔ country (many-to-many) |

## 🔄 Transformation Layer
Rather than modifying normalized tables directly, transformations are implemented as views on top of the normalized schema. This keeps the raw and normalized layers intact.

| View | Purpose |
|-----------|-----------|
| vw_shows_cleaned | Parses duration into numeric value + unit; extracts year/month from date_added |
| vw_content_age | Buckets content by era (Classic, Modern, Recent) and movie length |
| vw_rating_classified | Maps raw ratings (TV-MA, PG-13, etc.) to audience categories |
| vw_netflix_flat | Wide denormalized view joining all tables — primary analysis laye |
| vw_data_quality | Flags missing/dirty fields per record for quality tracking |
| vw_master_report | Final reporting view combining all transformations |
