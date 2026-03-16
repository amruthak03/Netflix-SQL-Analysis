-- populate netflix_shows 
INSERT INTO netflix_shows (
	show_id, type, title, date_added, release_year, rating, duration, description
)
SELECT 
	show_id, type, title,
	-- Clean and cast date_added
	TO_DATE(NULLIF(TRIM(date_added), ''), 'Month DD, YYYY'),
	release_year, rating, duration, description
FROM netflix_raw
WHERE show_id IS NOT NULL;

-- populate genres table 
INSERT INTO netflix_genres (genre_name)
SELECT DISTINCT TRIM(g) -- removes any leading/trailing spaces from each genre value
FROM netflix_raw,
	unnest(string_to_array(listed_in, ',')) AS g -- splits the comma separated genre string into an array, unnset - explodes that array into individual rows. So it means one row in netflix_raw with 3 genres will become 3 rows. 
WHERE TRIM(g) != '' -- Filters out any empty string
ON CONFLICT (genre_name) DO NOTHING; -- Since `genre_name` has a `UNIQUE` constraint, if you run this query twice, it won't throw an error or create duplicates — it just silently skips any genre that already exists in the table.

-- populate bridge table
INSERT INTO netflix_show_genres (show_id, genre_id)
SELECT DISTINCT r.show_id, ng.genre_id
FROM netflix_raw r,
	unnest(string_to_array(r.listed_in, ',')) AS g
JOIN netflix_genres ng ON ng.genre_name = TRIM(g)
WHERE r.show_id IS NOT NULL
ON CONFLICT DO NOTHING;

-- Insert distinct directors
INSERT INTO netflix_directors (director_name)
SELECT DISTINCT TRIM(d)
FROM netflix_raw,
	unnest(string_to_array(director, ',')) AS d
WHERE TRIM(d) != ''
ON CONFLICT (director_name) DO NOTHING;

-- Insert into bridge table
INSERT INTO netflix_show_directors (show_id, director_id)
SELECT DISTINCT r.show_id, nd.director_id
FROM netflix_raw r,
	unnest(string_to_array(director, ',')) AS d
JOIN netflix_directors nd ON nd.director_name = TRIM(d)
WHERE r.show_id IS NOT NULL
	AND TRIM(d) != ''
ON CONFLICT DO NOTHING;

-- Insert distinct cast members
INSERT INTO netflix_cast (cast_name)
SELECT DISTINCT TRIM(c)
FROM netflix_raw,
	unnest(string_to_array(casts, ',')) AS c
WHERE TRIM(c) != ''
ON CONFLICT (cast_name) DO NOTHING;

-- Insert into bridge table
INSERT INTO netflix_show_cast (show_id, cast_id)
SELECT DISTINCT r.show_id, nc.cast_id
FROM netflix_raw r,
	unnest(string_to_array(r.casts, ',')) AS c
JOIN netflix_cast nc ON nc.cast_name = TRIM(c)
WHERE r.show_id IS NOT NULL AND TRIM(c) != ''
ON CONFLICT DO NOTHING;

-- Insert into countries table
INSERT INTO netflix_countries (country_name)
SELECT DISTINCT TRIM(co)
FROM netflix_raw,
	unnest(string_to_array(country, ',')) AS co
WHERE TRIM(co) != ''
ON CONFLICT (country_name) DO NOTHING;

-- Insert into bridge table
INSERT INTO netflix_show_countries (show_id, country_id)
SELECT DISTINCT r.show_id, nco.country_id
FROM netflix_raw r,
	unnest(string_to_array(r.country, ',')) AS co
JOIN netflix_countries nco ON nco.country_name = TRIM(co)
WHERE r.show_id IS NOT NULL AND TRIM(co) != ''
ON CONFLICT DO NOTHING;

-- verify everything loaded correctly
SELECT 'netflix_shows' AS table_name, COUNT(*) FROM netflix_shows
UNION ALL
SELECT 'netflix_genres',COUNT(*) FROM netflix_genres
UNION ALL
SELECT 'netflix_show_genres', COUNT(*) FROM netflix_show_genres
UNION ALL
SELECT 'netflix_directors', COUNT(*) FROM netflix_directors
UNION ALL
SELECT 'netflix_show_directors', COUNT(*) FROM netflix_show_directors
UNION ALL
SELECT 'netflix_cast', COUNT(*) FROM netflix_cast
UNION ALL
SELECT 'netflix_show_cast', COUNT(*) FROM netflix_show_cast
UNION ALL
SELECT 'netflix_countries', COUNT(*) FROM netflix_countries
UNION ALL
SELECT 'netflix_show_countries', COUNT(*) FROM netflix_show_countries;