-- SQL Lesson 10: Queries with aggregates (Pt. 1)
-- 10.1: Find the longest time that an employee has been at the studio
SELECT MAX(years_employed) FROM employees;
-- 10.2: For each role, find the average number of years employed by employees in that role
SELECT AVG(years_employed),* FROM employees 
GROUP BY role;
-- 10.3: Find the total number of employee years worked in each building
SELECT SUM(years_employed),* FROM employees 
GROUP BY building;

-- 11.1: Find the number of Artists in the studio (without a HAVING clause)
SELECT COUNT(*),* FROM employees WHERE role="Artist";
-- 11.2: Find the number of Employees of each role in the studio
SELECT COUNT(role),* FROM employees GROUP BY role;
-- 11.3: Find the total number of years employed by all Engineers
SELECT SUM(years_employed),* FROM employees WHERE role="Engineer";



-- Oracle FreeSQL
-- 4 . Try It!
-- Complete the following query to return the:
--  Number of different shapes
--  The standard deviation (stddev) of the unique weights
select count(distinct shape) number_of_shapes,
       stddev(distinct weight) distinct_weight_stddev
from   bricks;

-- 6 . Try It!
-- Complete the following query to return the total weight for each shape stored in the bricks table:
select shape, SUM(weight) shape_weight
from   bricks
GROUP BY shape;

-- 8 . Try It!
-- Complete the following query to find the shapes which have a total weight less than four:
select shape, sum ( weight )
from   bricks
group  by shape
HAVING SUM(weight)<4;