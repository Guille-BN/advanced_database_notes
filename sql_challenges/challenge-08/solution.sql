-- ============================================================
-- Lesson 03 — Indexes: Class Exercises
-- Work through these before looking at the hints
-- ============================================================

-- ============================================================
-- Exercise 1 — Find the slow query
--
-- Run this query. Look at the execution plan.
-- Is Oracle using an index? Should it?
-- ============================================================

EXPLAIN PLAN FOR
SELECT * FROM patient_visits WHERE site_id = 3;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Questions:
-- a) What scan type do you see? Why?
/*
A full table scan, because it’s cheaper to scan the whole table than to use an index, 
in cases when a filter condition is not selective enough.
*/
-- b) site_id has values 1–5. Is this high or low cardinality?
/*
Low, because only 5 possible values spread across 50000 rows.
*/
-- c) Would adding an index on site_id help? Why or why not?
/*
No, because indexes are most useful when they filter down to a small subset of rows, but here
site_id=3 would use the index to find row pointers and then jump to the table for each row, which
is inefficient.
*/

-- ============================================================
-- Exercise 2 — Create an index and see if it helps
--
-- Create an index on visit_date.
-- Then run the range query below and check the plan.
-- ============================================================

-- Step 1: Create it
CREATE INDEX idx_patient_visits_visit_date
ON patient_visits (visit_date);


-- Step 2: Gather stats
BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

-- Step 3: Run the range query and check the plan
EXPLAIN PLAN FOR
SELECT * FROM patient_visits
WHERE visit_date BETWEEN SYSDATE - 30 AND SYSDATE;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Questions:
-- a) Does Oracle use the index for this range?
/*
No, it is scanning the entire table instead of using the index created on visit_date, 
because the optimizer decided that reading the whole table is cheaper than using the 
index for that specific condition.
*/
-- b) Change the range to the last 7 days. Does the plan change?
/*
It still shows a full table scan with the same cost. The only thing that changes is the estimated 
number of rows (from around 2000 to around 500), but Oracle still considers that reading the entire 
table is cheaper than using the index.
*/
-- c) Change to the last 700 days. What happens?
/*
When changing the range to the last 700 days, the plan still does not change at all and Oracle continues 
using a full table scan. Because now the query is returning almost the entire table, around 48,000 rows 
out of 50,000. At that point, using the index would be completely inefficient, since Oracle would have to 
go through the index and then access almost every row in the table anyway. It is simply faster to read 
the whole table sequentially once.
*/
-- d) Why does the range size affect whether Oracle uses the index?
/*
The reason the range size affects whether Oracle uses the index is because it directly impacts selectivity. 
The larger the range, the more rows match the condition, and the less useful the index becomes. 
*/



-- ============================================================
-- Exercise 3 — Composite index
--
-- You often query by both patient_id AND visit_date together:
--   WHERE patient_id = 1234 AND visit_date > SYSDATE - 90
--
-- Two options:
--   Option A: Two separate indexes (one per column)
--   Option B: One composite index (patient_id, visit_date)
--
-- Create the composite index and test the query.
-- ============================================================

CREATE INDEX idx_pv_patient_date ON patient_visits(patient_id, visit_date);

BEGIN
    DBMS_STATS.GATHER_TABLE_STATS(USER, 'PATIENT_VISITS', cascade => TRUE);
END;
/

EXPLAIN PLAN FOR
SELECT * FROM patient_visits
WHERE patient_id = 1234
  AND visit_date > SYSDATE - 90;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- Questions:
-- a) Does the plan use the composite index?
/*
Yes it does, the optimizer first uses the index to efficiently locate rows where patient_id = 1234, 
and then within that subset, it applies the range condition on visit_date. Since this combination is 
highly selective, Oracle only needs to access a very small number of rows, which is why the cost is 
lower than looking through the whole 50,000 rows.
*/
-- b) Now try querying ONLY on visit_date (no patient_id).
EXPLAIN PLAN FOR
SELECT * FROM patient_visits
WHERE visit_date > SYSDATE - 90;

SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);
--    Does the composite index get used? Why not?
/*
No, because the index is defined as (patient_id, visit_date), and Oracle can only efficiently 
use the index if the query includes the leading column, which in this case is patient_id.
*/

-- c) What's the rule about column order in composite indexes?
/*
The rule is that in a composite index, the order of the columns matters because Oracle 
uses the index from left to right, starting with the leading column. So this means that 
the index can only be fully used if the query includes the first column of the index.
*/

-- Bonus test — leading column only:
EXPLAIN PLAN FOR
SELECT * FROM patient_visits WHERE patient_id = 1234;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

"PLAN_TABLE_OUTPUT"
"Plan hash value: 2583713960"
" "
"-----------------------------------------------------------------------------------------------------------"
"| Id  | Operation                           | Name                | Rows  | Bytes | Cost (%CPU)| Time     |"
"-----------------------------------------------------------------------------------------------------------"
"|   0 | SELECT STATEMENT                    |                     |     5 |   245 |     8   (0)| 00:00:01 |"
"|   1 |  TABLE ACCESS BY INDEX ROWID BATCHED| PATIENT_VISITS      |     5 |   245 |     8   (0)| 00:00:01 |"
"|*  2 |   INDEX RANGE SCAN                  | IDX_PV_PATIENT_DATE |     5 |       |     2   (0)| 00:00:01 |"
"-----------------------------------------------------------------------------------------------------------"
" "
"Predicate Information (identified by operation id):"
"---------------------------------------------------"
" "
"   2 - access(""PATIENT_ID""=1234)"

-- Trailing column only (index cannot be used from the middle):
EXPLAIN PLAN FOR
SELECT * FROM patient_visits WHERE visit_date > SYSDATE - 90;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

"PLAN_TABLE_OUTPUT"
"Plan hash value: 3966720212"
" "
"------------------------------------------------------------------------------------"
"| Id  | Operation         | Name           | Rows  | Bytes | Cost (%CPU)| Time     |"
"------------------------------------------------------------------------------------"
"|   0 | SELECT STATEMENT  |                |  6162 |   294K|   103   (1)| 00:00:01 |"
"|*  1 |  TABLE ACCESS FULL| PATIENT_VISITS |  6162 |   294K|   103   (1)| 00:00:01 |"
"------------------------------------------------------------------------------------"
" "
"Predicate Information (identified by operation id):"
"---------------------------------------------------"
" "
"   1 - filter(""VISIT_DATE"">SYSDATE@!-90)"



-- ============================================================
-- Exercise 4 — Function that breaks an index
--
-- There IS an index on patient_id (from lesson 03).
-- Predict what happens when you wrap the column in a function.
-- ============================================================

-- This query CAN use the index:
EXPLAIN PLAN FOR
SELECT * FROM patient_visits WHERE patient_id = 5432;
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

-- This one cannot — why?
EXPLAIN PLAN FOR
SELECT * FROM patient_visits WHERE TO_CHAR(patient_id) = '5432';
SELECT * FROM TABLE(DBMS_XPLAN.DISPLAY);

/*
The second query cannot use the index because TO_CHAR(patient_id) is being used, 
and that changes how the optimizer can use it, because Oracle would first have to apply 
the function TO_CHAR() to every row’s patient_id before comparing it, which means that 
the indexed values no longer match the expression being evaluated, so the index becomes 
unusable for that condition.
*/

-- Questions:
-- a) What scan type did the second query use?
/*
The second query uses a full table scan. Instead of using the index, Oracle reads the 
entire PATIENT_VISITS table and evaluates the condition row by row, which is 
why the cost is much higher compared to the first query.
*/
-- b) Why does wrapping a column in a function break index use?
/*
Because the index is built on the original values of patient_id, not on the result 
of TO_CHAR(patient_id), when applying this function Oracle would need an index on 
that exact expression, not the base column, but it does not have that, so it 
cannot use the index efficiently and falls back to a full scan
*/
-- c) How would you rewrite the second query to allow index use?
/*
A query in which the column is not wrapped in a function, like transforming the column 
into a number or just comparing directly, so that Oracle can match the predicate directly 
against the indexed values and use the index.
*/



-- ============================================================
-- Exercise 5 — Discussion: real-world scenarios
--
-- For each scenario below, decide:
--   a) Would you add an index?
--   b) On which column(s)?
--   c) Any concerns?
-- ============================================================

-- Scenario A:
-- A reporting table gets loaded once per night (batch ETL).
-- During the day, analysts run SELECT queries by date range.
-- The table has 50 million rows.
-- → Index on date? Yes/No, why?
/*
a) Yes, because the main access pattern during the day is filtering by date ranges
and in Oracle that kind of query is exactly where indexes are to be used, 
because they allow the optimizer to quickly locate only the relevant data.

b) On 'date'

c) Indexes make data loading slower, because every time new rows are inserted, 
the index also has to be updated. Since the table is loaded in batches, this 
can increase the load time. 
*/

-- Scenario B:
-- An OLTP orders table gets 10,000 inserts per minute.
-- Support staff look up orders by customer_id or order_status.
-- order_status has 4 values: pending, processing, shipped, cancelled.
-- → What indexes would you add?
/*
a) Yes.

b) On customer_id, because it will likely have many different values, 
so queries filtering by it will return a small subset of data.

c) Since the table receives around 10,000 inserts per minute, every index consumes computational resources 
and slows down writes. So, adding too many indexes can hurt performance significantly in this kind of system.
Which is why we should only use one on customer_id.
*/

-- Scenario C:
-- A patient table has an email column (unique per patient).
-- There are 5 million patients.
-- The app frequently does: WHERE email = 'user@example.com'
-- → What kind of index would be best here?
/*
a) A 'unique' index 

b) On the email column

c) Inserts and updates become slightly slower, because every time a new patient is added or an email is changed, 
the index also has to be updated.
*/