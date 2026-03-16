select * from netflix_raw;
-- Performing data cleaning and transformation
-- For best practice, will create views and transformed tables rather than modifying the normalized tables

-- Transformation 1: Clean Shows - Split `duration` into numeric value + unit (minutes vs seasons)
CREATE view vw_shows_cleaned AS
SELECT
	show_id,
	type,
	title,
	date_added,
	release_year,
	rating,
	duration,
	-- Extract numeric part of duration
	CAST(SPLIT_PART(duration, ' ', 1) AS INT) AS duration_value,
	-- Extract unit (min or Seasons)
	TRIM(SPLIT_PART(duration, ' ', 2)) AS duration_unit,
	-- Separate clean columns for movie minutes vs show seasons
	CASE
		WHEN type = 'Movie' THEN CAST(SPLIT_PART(duration, ' ', 1) AS INT)
		ELSE NULL
	END AS movie_minutes,
	CASE
		WHEN type = 'TV Show' THEN CAST(SPLIT_PART(duration, ' ', 1) AS INT)
		ELSE NULL
	END AS tv_seasons,
	description,
	 -- Extract year and month from date_added for trend analysis
	 EXTRACT(YEAR FROM date_added)::INT AS year_added,
	 EXTRACT(MONTH FROM date_added)::INT AS month_added,
	 TO_CHAR(date_added, 'Month') AS month_name,
	 -- How old was the content when added to Netflix?
	 EXTRACT(YEAR FROM date_added)::INT - release_year AS years_before_netflix
FROM netflix_shows
WHERE date_added IS NOT NULL;

select * from vw_shows_cleaned;

-- Transformation 2: Categorize content by how old it is
CREATE VIEW vw_content_age AS
SELECT
	show_id,
	title,
	type,
	release_year,
	CASE 
		WHEN release_year >= 2020 THEN 'Recent (2020+)'
		WHEN release_year >= 2015 THEN 'Modern (2015-2019)'
		WHEN release_year >= 2010 THEN 'Early 2010s'
		WHEN release_year >= 2000 THEN '2000s'
		ELSE 'Classic (Pre-2000)'
	END AS content_era,
	CASE
		WHEN movie_minutes < 60 THEN 'Short (<1hr)'
		WHEN movie_minutes < 90 THEN 'Standard (1-1.5hr)'
		WHEN movie_minutes < 120 THEN 'Long (1.5-2hr)'
		WHEN movie_minutes >= 120 THEN 'Extend (2hr+)'
		ELSE NULL
	END AS movie_length_bucket
FROM vw_shows_cleaned;

select * from vw_content_age;

-- Transformation 3: Flatten into one wide table - main analysis table
CREATE VIEW vw_netflix_flat AS
SELECT 
	s.show_id,
	s.type,
    s.title,
    s.date_added,
    s.year_added,
    s.month_added,
    s.month_name,
    s.release_year,
    s.rating,
    s.duration,
    s.duration_value,
    s.duration_unit,
    s.movie_minutes,
    s.tv_seasons,
    s.years_before_netflix,
    s.description,
	-- Aggregate multi-value fields back as clean strings
	STRING_AGG(DISTINCT g.genre_name, ', ') AS genres,
	STRING_AGG(DISTINCT d.director_name, ', ') AS directors,
	STRING_AGG(DISTINCT co.country_name, ', ') AS countries,
	COUNT(DISTINCT g.genre_id) AS genre_count,
	COUNT(DISTINCT d.director_id) AS director_count,
	COUNT(DISTINCT co.country_id) AS country_count
FROM vw_shows_cleaned s
LEFT JOIN netflix_show_genres sg ON s.show_id = sg.show_id
LEFT JOIN netflix_genres g ON sg.genre_id = g.genre_id
LEFT JOIN netflix_show_directors sd ON s.show_id = sd.show_id
LEFT JOIN netflix_directors d ON sd.director_id = d.director_id
LEFT JOIN netflix_show_countries sco ON s.show_id = sco.show_id
LEFT JOIN netflix_countries co ON sco.country_id = co.country_id
GROUP BY
	s.show_id, s.type, s.title, s.date_added,
	s.year_added, s.month_added, s.month_name,
	s.release_year, s.rating, s.duration,
	s.duration_value, s.duration_unit,
	s.movie_minutes, s.tv_seasons,
	s.years_before_netflix, s.description;

select * from vw_netflix_flat;

-- Transformation 4: Map raw ratings to audience categories
CREATE VIEW vw_rating_classified AS
SELECT
	show_id,
	title,
	type,
	rating,
	CASE 
		WHEN rating IN ('G', 'TV-Y', 'TV-G') THEN 'Kids'
		WHEN rating IN ('PG', 'TV-Y7', 'TV-Y7-FV') THEN 'Older Kids'
		WHEN rating IN ('PG-13', 'TV-PG', 'TV-14') THEN 'Teens'
		WHEN rating IN ('R', 'TV-MA') THEN 'Adults'
		WHEN rating IN ('NC-17', 'NR', 'UR') THEN 'Restricted/Unrated'
		ELSE 'Unknown'
	END AS audience_category
FROM netflix_shows;

select * from vw_rating_classified;

-- Transformation 5: Data Quality Flags
CREATE VIEW vw_data_quality AS
SELECT
	show_id,
	title,
	CASE WHEN director IS NULL OR TRIM(director) = ''
		THEN TRUE ELSE FALSE END AS missing_director,
	CASE WHEN casts IS NULL OR TRIM(casts) = ''     
         THEN TRUE ELSE FALSE END AS missing_cast,
	CASE WHEN country IS NULL OR TRIM(country) = '' 
         THEN TRUE ELSE FALSE END AS missing_country,
	CASE WHEN date_added IS NULL
		THEN TRUE ELSE FALSE END AS missing_date_added,
	CASE WHEN rating IS NULL 
		THEN TRUE ELSE FALSE END AS missing_rating,
	CASE WHEN duration IS NULL
		THEN TRUE ELSE FALSE END AS missing_duration
FROM netflix_raw;

-- Summary of data quality issues
SELECT
    COUNT(*) AS total_records,
    SUM(CASE WHEN missing_director THEN 1 END) AS missing_directors,
    SUM(CASE WHEN missing_cast THEN 1 END) AS missing_cast,
    SUM(CASE WHEN missing_country THEN 1 END) AS missing_countries,
    SUM(CASE WHEN missing_date_added THEN 1 END) AS missing_date_added,
    SUM(CASE WHEN missing_rating THEN 1 END) AS missing_ratings
FROM vw_data_quality;

--- Missing Directors = 29.9% (Expected, not a data problem TV Shows typically don't have a single director the way movies do)
SELECT
	type, COUNT(*) AS total, 
	SUM(CASE WHEN missing_director THEN 1 END) AS missing_directors,
	ROUND(SUM(CASE WHEN missing_director THEN 1 END)*100/COUNT(*), 1) AS missing_pct
FROM vw_data_quality dq
JOIN netflix_shows s USING (show_id)
GROUP BY type;

--- Who are the shows with missing countries
SELECT * FROM netflix_shows;
SELECT s.title, s.type, s.rating, s.release_year
FROM netflix_shows s
JOIN vw_data_quality dq USING (show_id)
WHERE dq.missing_country = TRUE
LIMIT 20;

--- Adding this view to handle NULLs cleanly going forward
CREATE VIEW vw_shows_nulls_handled AS
SELECT
    show_id,
    type,
    title,
    COALESCE(rating, 'Not Rated') AS rating,
    date_added,
    release_year,
    duration
FROM netflix_shows;

select * from vw_shows_nulls_handled;

-- Investigate the Bad Rows. Ratings have some dirty data - some rows have duration values accidentally loaded into the rating column in the raw CSV
SELECT
	show_id,
	title,
	type,
	rating,
	duration
FROM netflix_shows
WHERE rating ~ '^\d+\s*min$'; -- regex: matches patterns like "66 min"

-- move the bad rating value into duration, set rating to NULL
UPDATE netflix_shows
SET
	duration = rating, -- move "66 min" to duration where it belongs
	rating = NULL -- clear the bad rating value
WHERE rating ~ '^\d+\s*min$';
-- Verify the fix
SELECT show_id, title, rating, duration
FROM netflix_shows
WHERE rating ~ '^\d+\s*min$'; --returns 0 value means fixed