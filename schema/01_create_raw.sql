-- create table
CREATE TABLE netflix_raw (
	show_id VARCHAR(10),
	type VARCHAR(10),
	title VARCHAR(200),
	director VARCHAR(500),
	casts TEXT,
	country VARCHAR(200),
	date_added VARCHAR(50),
	release_year INT,
	rating VARCHAR(20),
	duration VARCHAR(20),
	listed_in VARCHAR(200),
	description TEXT
);