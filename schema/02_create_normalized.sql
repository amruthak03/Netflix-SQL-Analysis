-- Core shows table
CREATE TABLE netflix_shows (
	show_id VARCHAR(10) PRIMARY KEY,
	type VARCHAR(10),
	title VARCHAR(200),
	date_added DATE,
	release_year INT,
	rating VARCHAR(20),
	duration VARCHAR(20),
	description TEXT
);

-- Genre lookup
CREATE TABLE netflix_genres (
	genre_id SERIAL PRIMARY KEY,
	genre_name VARCHAR(100) UNIQUE
);

-- Bridge: show <-> genre
-- Why bridge table? To solve many-to-many relationship. For instance, a single show can have multiple genres, and a single genre can belong to multiple shows. To avoid cramming it all in one table and have redundancy, bridge tables comes to use here.
CREATE TABLE netflix_show_genres (
	show_id VARCHAR(10) REFERENCES netflix_shows(show_id),
	genre_id INT REFERENCES netflix_genres(genre_id),
	PRIMARY KEY (show_id, genre_id)
);

-- Director lookup
CREATE TABLE netflix_directors (
	director_id SERIAL PRIMARY KEY,
	director_name VARCHAR(200) UNIQUE
);

-- Bridge: show <-> director
CREATE TABLE netflix_show_directors (
	show_id VARCHAR(10) REFERENCES netflix_shows(show_id),
	director_id INT REFERENCES netflix_directors(director_id),
	PRIMARY KEY (show_id, director_id)
);

-- Cast member lookup
CREATE TABLE netflix_cast (
	cast_id SERIAL PRIMARY KEY,
	cast_name VARCHAR(200) UNIQUE
);

-- Bridge: show <-> cast
CREATE TABLE netflix_show_cast (
	show_id VARCHAR(10) REFERENCES netflix_shows(show_id),
	cast_id INT REFERENCES netflix_cast(cast_id),
	PRIMARY KEY (show_id, cast_id)
);

-- Country lookup
CREATE TABLE netflix_countries (
	country_id SERIAL PRIMARY KEY,
	country_name VARCHAR(100) UNIQUE
);

-- Bridge: show <-> country
CREATE TABLE netflix_show_countries (
	show_id VARCHAR(10) REFERENCES netflix_shows(show_id),
	country_id INT REFERENCES netflix_countries(country_id),
	PRIMARY KEY (show_id, country_id)
);