-- Business Questions and SQL Analysis
-- Q1. How many movies vs TV Shows are on Netflix?
SELECT * FROM netflix_shows;
SELECT
	type,
	COUNT(*) AS total_count,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM netflix_shows
GROUP BY type;

-- Q2. What are the top 10 countries producing netflix content?
SELECT * FROM netflix_countries;
SELECT * FROM netflix_show_countries;

SELECT
	c.country_name,
	COUNT(DISTINCT sc.show_id) AS total_content
FROM netflix_countries c
JOIN netflix_show_countries sc USING (country_id)
GROUP BY c.country_name
ORDER BY total_content DESC
LIMIT 10;

-- Q3. What ratings are most common?
SELECT * FROM netflix_shows;
SELECT * FROM vw_rating_classified;
SELECT
	r.audience_category,
	s.rating,
	COUNT(*) AS total,
	ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(), 1) AS percentage
FROM netflix_shows s
JOIN vw_rating_classified r USING (show_id)
WHERE s.rating IS NOT NULL
GROUP BY r.audience_category, s.rating
ORDER BY total DESC;

-- Q4. How much content was added each year?
SELECT * FROM vw_shows_cleaned;
SELECT
	year_added,
	COUNT(*) AS total_added,
	SUM(CASE WHEN type = 'Movie' THEN 1 END) AS movies_added,
	SUM(CASE WHEN type = 'TV Show' THEN 1 END) AS shows_added
FROM vw_shows_cleaned
GROUP BY year_added
ORDER BY year_added;

-- Q5. Which genres have grown the most in the last 5 years?, i.e., Top 10 Genres by Content volume
SELECT * FROM netflix_genres;
SELECT * FROM netflix_shows;
SELECT
	g.genre_name,
	COUNT(DISTINCT sg.show_id) AS total_titles,
	SUM(CASE WHEN s.type = 'Movie' THEN 1 END) AS movies,
	SUM(CASE WHEN s.type = 'TV Show' THEN 1 END) AS tv_shows
FROM netflix_genres g
JOIN netflix_show_genres sg USING (genre_id)
JOIN netflix_shows s USING (show_id)
GROUP BY g.genre_name
ORDER BY total_titles DESC
LIMIT 10;

-- Q6. What is the average movie duration by genre?
SELECT
	g.genre_name,
	ROUND(AVG(sc.movie_minutes), 1) AS avg_minutes,
	MIN(sc.movie_minutes) AS min_minutes,
	MAX(sc.movie_minutes) AS max_minutes,
	COUNT(*) AS total_movies
FROM netflix_genres g
JOIN netflix_show_genres sg USING (genre_id)
JOIN vw_shows_cleaned sc USING (show_id)
WHERE sc.type = 'Movie' AND sc.movie_minutes IS NOT NULL
GROUP BY g.genre_name
ORDER BY avg_minutes DESC;

-- Q7. Which directors have the most titles, split by Movies vs TV Shows?
SELECT * FROM netflix_directors;
SELECT
	d.director_name,
	COUNT(DISTINCT sd.show_id) AS total_titles,
	SUM(CASE WHEN s.type = 'Movie' THEN 1 END) AS movies,
	SUM(CASE WHEN s.type = 'TV Show' THEN 1 END) AS tv_shows
FROM netflix_directors d
JOIN netflix_show_directors sd USING (director_id)
JOIN netflix_shows s USING (show_id)
GROUP BY d.director_name
HAVING COUNT(DISTINCT sd.show_id) > 3
ORDER BY total_titles DESC
LIMIT 10;

-- Q8. What % of content is international (non-US)?
WITH show_origin AS (
SELECT 
	s.show_id,
	s.type,
	CASE
		WHEN MAX(CASE WHEN c.country_name = 'United States' THEN 1 ELSE 0 END) = 1 
		THEN 'US Content' ELSE 'International' END AS origin
FROM netflix_shows s
JOIN netflix_show_countries sc USING (show_id)
JOIN netflix_countries c USING (country_id)
GROUP BY s.show_id, s.type 
)
SELECT
 origin,
 type,
 COUNT(*) AS total,
 ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER(PARTITION BY type), 1) AS pct_within_type
FROM show_origin
GROUP BY origin, type
ORDER BY type, total DESC;

-- Q9. Rank countries by content volume, partitioned by type (Movie vs TV Show)
SELECT
	c.country_name,
	s.type,
	COUNT(DISTINCT sc.show_id) AS total_content,
	RANK() OVER(
		PARTITION BY s.type
		ORDER BY COUNT(DISTINCT sc.show_id) DESC
	) AS rank_within_type,
	DENSE_RANK() OVER(
		ORDER BY COUNT(DISTINCT sc.show_id) DESC
	) AS overall_rank
FROM netflix_countries c
JOIN netflix_show_countries sc USING (country_id)
JOIN netflix_shows s USING (show_id)
GROUP BY c.country_name, s.type
ORDER BY s.type, rank_within_type;

-- Q10. Month-over-month growth rate of content additions using LAG()
WITH monthly_counts AS (
	SELECT
		year_added,
		month_added,
		COUNT(*) AS titles_added
	FROM vw_shows_cleaned
	WHERE year_added IS NOT NULL
	GROUP BY year_added, month_added
)
SELECT
	year_added,
	month_added,
	titles_added,
	LAG(titles_added) OVER (ORDER BY year_added, month_added) AS prev_month_count,
	titles_added - LAG(titles_added) OVER (ORDER BY year_added, month_added) AS mom_change,
	ROUND(
		(titles_added - LAG(titles_added) OVER (
			ORDER BY year_added, month_added)) * 100.0 / NULLIF(LAG(titles_added) OVER(
												ORDER BY year_added, month_added), 0)
	, 1) AS mom_growth_pct
FROM monthly_counts
ORDER BY year_added, month_added;

-- Q11. Rolling 12-month count of titles added using window frames
WITH monthly_counts AS (
	SELECT
		year_added,
		month_added,
		TO_DATE(year_added || '-' ||
				LPAD(month_added::TEXT, 2, '0')
				|| '-01', 'YYYY-MM-DD') AS month_date,
		COUNT(*) AS titles_added
	FROM vw_shows_cleaned
	WHERE year_added IS NOT NULL
	GROUP BY year_added, month_added
)
SELECT
	month_date,
	titles_added,
	SUM(titles_added) OVER (ORDER BY month_date
					ROWS BETWEEN 11 PRECEDING AND CURRENT ROW) AS rolling_12_month_total,
	ROUND(AVG(titles_added) OVER (ORDER BY month_date
					ROWS BETWEEN 11 PRECEDING AND CURRENT ROW), 1) AS rolling_12_month_avg
FROM monthly_counts
ORDER BY month_date;

-- Q12. Identify directors who shifted from Movies to TV Shows over time
WITH director_types AS (
	SELECT 
		d.director_name,
		s.type,
		COUNT(*) AS title_count,
		MIN(sc.year_added) AS first_year,
		MAX(sc.year_added) AS last_year
	FROM netflix_directors d
	JOIN netflix_show_directors sd USING (director_id)
	JOIN netflix_shows s USING (show_id)
	JOIN vw_shows_cleaned sc USING (show_id)
	GROUP BY d.director_name, s.type
)
SELECT
	director_name,
	MAX(CASE WHEN type = 'Movie' THEN title_count END) AS movie_count,
	MAX(CASE WHEN type = 'TV Show' THEN title_count END) AS tv_show_count,
	MAX(CASE WHEN type = 'Movie' THEN first_year END) AS first_movie_year,
	MAX(CASE WHEN type = 'TV Show' THEN first_year END) AS first_tvshow_year
FROM director_types
GROUP BY director_name
HAVING COUNT(DISTINCT type) = 2
ORDER BY movie_count DESC;

-- Q13. Find duplicate titles (data quality check)
SELECT 
	title,
	type, 
	COUNT(*) AS duplicate_count,
	STRING_AGG(show_id, ', ') AS show_ids,
	STRING_AGG(CAST(release_year AS TEXT), ', ') AS release_years
FROM netflix_shows
GROUP BY title, type
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

-- Q14. Build a content diversity score per country (genres per country)
WITH country_genre_counts AS (
	SELECT
		c.country_name,
		COUNT(DISTINCT s.show_id) AS total_titles,
		COUNT(DISTINCT g.genre_id) AS unique_genres,
		COUNT(DISTINCT CASE WHEN s.type = 'Movie' THEN s.show_id END) AS movies,
		COUNT(DISTINCT CASE WHEN s.type = 'TV Show' THEN s.show_id END) AS tv_shows
	FROM netflix_countries c
	JOIN netflix_show_countries sc USING (country_id)
	JOIN netflix_shows s USING (show_id)
	JOIN netflix_show_genres sg USING (show_id)
	JOIN netflix_genres g USING (genre_id)
	GROUP BY c.country_name 
	HAVING COUNT(DISTINCT s.show_id) >= 10
)
SELECT
	country_name,
	total_titles,
	unique_genres,
	movies,
	tv_shows,
	ROUND(unique_genres * 1.0 / total_titles, 3) AS diversity_score,
	RANK() OVER (ORDER BY unique_genres * 1.0 / total_titles DESC) AS diversity_rank
FROM country_genre_counts
ORDER BY diversity_rank
LIMIT 20;

-- Q15. Create a summary "reporting view" joining all normalized tables
CREATE VIEW vw_master_report AS
SELECT 
    s.show_id,
    s.type,
    s.title,
    s.release_year,
    s.date_added,
    sc.year_added,
    sc.month_name,
    sc.movie_minutes,
    sc.tv_seasons,
    sc.years_before_netflix,
    sc2.content_era,
    r.audience_category,
    f.genres,
    f.directors,
    f.countries,
    f.genre_count,
    f.country_count
FROM netflix_shows s
JOIN vw_shows_cleaned    sc  USING (show_id)
JOIN vw_content_age      sc2 USING (show_id)  -- picks up content_era
JOIN vw_rating_classified r  USING (show_id)
JOIN vw_netflix_flat      f  USING (show_id);

SELECT * FROM vw_master_report;