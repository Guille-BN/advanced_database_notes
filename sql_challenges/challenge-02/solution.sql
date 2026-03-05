-- SQL Bolt
-- SQL Lesson 6: Multi-table queries with JOINs
-- 6.1: Find the domestic and international sales for each movie
SELECT * FROM movies
JOIN boxoffice on movies.id=boxoffice.movie_id;
-- 6.2: Show the sales numbers for each movie that did better internationally rather than domestically
SELECT * FROM movies as m
JOIN boxoffice as b on m.id=b.movie_id
WHERE b.domestic_sales<b.international_sales;
-- 6.3: List all the movies by their ratings in descending order
SELECT * FROM movies as m
JOIN boxoffice as b on m.id=b.movie_id
ORDER BY rating DESC;

-- SQL Lesson 7: OUTER JOINs
-- 7.1: Find the list of all buildings that have employees
SELECT DISTINCT building FROM employees AS e;
-- 7.2: Find the list of all buildings and their capacity
SELECT * FROM buildings;
-- 7.3: List all buildings and the distinct employee roles in each building (including empty buildings)
SELECT DISTINCT building_name,role FROM buildings AS b
LEFT JOIN employees as e ON b.building_name=e.building;



-- Data Lemur
-- Page With No Likes: Facebook SQL Interview Question
SELECT p.page_id FROM pages AS p
LEFT JOIN page_likes AS pl ON p.page_id=pl.page_id
WHERE liked_date IS NULL
ORDER BY p.page_id ASC;