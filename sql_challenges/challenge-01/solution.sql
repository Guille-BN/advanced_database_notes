-- SQL Lesson 1: SELECT queries 101
-- 1.1 Find the title of each film 
SELECT title FROM movies;
-- 1.2 Find the director of each film
SELECT director FROM movies;
-- 1.3 Find the title and director of each film
SELECT title,director FROM movies;
-- 1.4 Find the title and year of each film
SELECT title,year FROM movies;
-- 1.5 Find all the information about each film
SELECT * FROM movies;

-- SQL Lesson 2: Queries with constraints (Pt. 1)
-- 2.1 Find the movie with a row id of 6
SELECT * FROM movies WHERE Id=6;
-- 2.2 Find the movies released in the years between 2000 and 2010
SELECT * FROM movies WHERE year>=2000 AND year<=2010;
-- 2.3 Find the movies not released in the years between 2000 and 2010
SELECT * FROM movies WHERE year>2010 OR year<2000;
-- 2.4 Find the first 5 Pixar movies and their release year
SELECT title,year FROM movies WHERE Id<=5;

-- SQL Lesson 3: Queries with constraints (Pt. 2)
-- 3.1 Find all the Toy Story movies
SELECT * FROM movies WHERE Title LIKE "Toy Story%";
-- 3.2 Find all the movies directed by John Lasseter
SELECT * FROM movies WHERE Director = "John Lasseter";
-- 3.3 Find all the movies (and director) not directed by John Lasseter
SELECT * FROM movies WHERE Director != "John Lasseter";
-- 3.4 Find all the WALL-* movies
SELECT * FROM movies WHERE Title LIKE "WALL-%";

-- SQL Lesson 4: Filtering and sorting Query results
-- 4.1 List all directors of Pixar movies (alphabetically), without duplicates
SELECT DISTINCT Director FROM movies ORDER BY Director;
-- 4.2 List the last four Pixar movies released (ordered from most recent to least)
SELECT * FROM movies ORDER BY Year DESC LIMIT 4;
-- 4.3 List the first five Pixar movies sorted alphabetically
SELECT * FROM movies ORDER BY Title LIMIT 5;
-- 4.4 List the next five Pixar movies sorted alphabetically
SELECT * FROM movies ORDER BY Title LIMIT 5 OFFSET 5;

-- SQL Review: Simple SELECT Queries
-- 5.1 List all the Canadian cities and their populations
SELECT * FROM north_american_cities WHERE Country="Canada";
-- 5.2 Order all the cities in the United States by their latitude from north to south
SELECT * FROM north_american_cities WHERE Country="United States" ORDER BY Latitude DESC;
-- 5.3 List all the cities west of Chicago, ordered from west to east
SELECT * FROM north_american_cities WHERE Longitude<"-87.629798" ORDER BY Longitude;
-- 5.4 List the two largest cities in Mexico (by population)
SELECT * FROM north_american_cities WHERE Country="Mexico" ORDER BY Population DESC LIMIT 2;
-- 5.5 List the third and fourth largest cities (by population) in the United States and their population
SELECT * FROM north_american_cities WHERE Country="United States" ORDER BY Population DESC LIMIT 2 OFFSET 2;