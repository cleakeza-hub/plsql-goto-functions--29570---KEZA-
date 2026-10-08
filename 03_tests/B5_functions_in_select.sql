/*
================================================================================
 File        : 03_tests/B5_functions_in_select.sql
 Task        : B5 - Using user-defined functions in SQL
 Author      : Keza Christa Clea (Student ID 29570)
 Course      : INSY 8311 - Database Development with PL/SQL (AUCA)
 Purpose     : Shows the B1-B4 functions used inside SQL statements:
               1. in the SELECT list
               2. in a WHERE clause
               3. in ORDER BY
               4. with GROUP BY and aggregate functions
               5. what happens when a function raises an error inside a SELECT
 Dependencies: 00_setup/create_tables.sql and all of 02_functions/B1-B4.
 How to run  : @03_tests/B5_functions_in_select.sql
 Expected    : Four result sets, then query 5 fails with
               ORA-20002: Hire date ... is in the future (this is intended).
 Data changes: none (SELECT only).
================================================================================
*/
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 100
SET TAB OFF

COLUMN employee        FORMAT A24
COLUMN department      FORMAT A24
COLUMN salary          FORMAT 999,999,990.00
COLUMN annual_salary   FORMAT 99,999,990.00
COLUMN years           FORMAT 990
COLUMN hire_date       FORMAT A10
COLUMN monthly_tax     FORMAT 999,990.00
COLUMN net_salary      FORMAT 999,999,990.00
COLUMN employees       FORMAT 990
COLUMN total_salary    FORMAT 9,999,999,990.00
COLUMN avg_salary      FORMAT 999,999,990.00
COLUMN total_tax       FORMAT 999,999,990.00

PROMPT
PROMPT ==== 1. Functions in the SELECT list ====
-- Employee 114 has a future hire date, so fn_years_of_service would raise
-- ORA-20002 for that row and the WHOLE query would fail. The WHERE clause
-- removes that row before the SELECT list is evaluated.
SELECT e.emp_id,
       e.first_name || ' ' || e.last_name               AS employee,
       fn_dept_name(e.dept_id)                          AS department,
       e.salary                                         AS salary,
       fn_annual_salary(e.emp_id)                       AS annual_salary,
       fn_years_of_service(e.hire_date)                 AS years,
       fn_calculate_tax(e.salary)                       AS monthly_tax,
       e.salary - fn_calculate_tax(e.salary)            AS net_salary
  FROM employees e
 WHERE e.hire_date <= TRUNC(SYSDATE)                    -- exclude future hire date
 ORDER BY e.emp_id;

PROMPT
PROMPT ==== 2. Function in a WHERE clause: employees with 5 or more years of service ====
-- The plain column test (hire_date <= today) is listed first to keep the
-- future-dated row away from fn_years_of_service.
SELECT e.emp_id,
       e.first_name || ' ' || e.last_name               AS employee,
       TO_CHAR(e.hire_date, 'YYYY-MM-DD')               AS hire_date,
       fn_years_of_service(e.hire_date)                 AS years
  FROM employees e
 WHERE e.hire_date <= TRUNC(SYSDATE)
   AND fn_years_of_service(e.hire_date) >= 5
 ORDER BY years DESC, e.emp_id;

PROMPT
PROMPT ==== 3. Function in ORDER BY: annual salary, highest first ====
-- NULLS LAST puts the employee with no salary at the bottom.
SELECT e.emp_id,
       e.first_name || ' ' || e.last_name               AS employee,
       fn_annual_salary(e.emp_id)                       AS annual_salary
  FROM employees e
 ORDER BY fn_annual_salary(e.emp_id) DESC NULLS LAST, e.emp_id;

PROMPT
PROMPT ==== 4. Function in GROUP BY: totals per department ====
-- COUNT(*) counts all employees; SUM/AVG ignore the NULL salary.
SELECT fn_dept_name(e.dept_id)                          AS department,
       COUNT(*)                                         AS employees,
       SUM(e.salary)                                    AS total_salary,
       ROUND(AVG(e.salary), 2)                          AS avg_salary,
       SUM(fn_calculate_tax(e.salary))                  AS total_tax
  FROM employees e
 GROUP BY fn_dept_name(e.dept_id)
 ORDER BY department;

PROMPT
PROMPT ==== 5. Limitation: a function that raises an error breaks the whole query ====
PROMPT (Expected: ORA-20002 because employee 114 has a future hire date.)
SELECT e.emp_id,
       e.first_name || ' ' || e.last_name               AS employee,
       TO_CHAR(e.hire_date, 'YYYY-MM-DD')               AS hire_date,
       fn_years_of_service(e.hire_date)                 AS years
  FROM employees e
 WHERE e.emp_id = 114;

CLEAR COLUMNS
