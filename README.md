# Netflix SQL Analysis

An end-to-end SQL project analyzing Netflix's content catalog using PostgeSQL. This project demonstrates advanced SQL skills including schema design, data normalization, transformation layers, window functions, CTEs, and data quality analysis.

## 📁 Repository Structure
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

## 📊 Dataset
- Source: [Netflix Movies and TV Shows — Kaggle](https://www.kaggle.com/datasets/shivamb/netflix-shows/data)
- Size: 8,807 titles
- Fields: show_id, type, title, director, cast, country, date_added, release_year, rating, duration, listed_in, description

## 🏗️ Schema Design
The raw CSV was normalized into a proper relational schema to handle multi-value fields (genres, cast, directors, countries) that were stored as comma-separated strings in the source data.

Tables

| Table | Description |
|---|---|---|
| netflix_raw, Raw ingestion table — mirrors source CSV exactly | Row 1, Col 2 | Row 1, Col 3 |
| Row 2, Col 1 | Row 2, Col 2 | Row 2, Col 3 |
