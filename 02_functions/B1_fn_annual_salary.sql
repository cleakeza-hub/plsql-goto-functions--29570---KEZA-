/*
================================================================================
 File        : 02_functions/B1_fn_annual_salary.sql
 Task        : B1 - Function: annual salary
 Author      : Keza Christa Clea (Student ID 29570)
 Course      : INSY 8311 - Database Development with PL/SQL (AUCA)
 Purpose     : fn_annual_salary(p_emp_id) returns the employee's monthly
               salary x 12, rounded to 2 decimals (RWF).
 Dependencies: Table EMPLOYEES (run 00_setup/create_tables.sql first).
 How to run  : @02_functions/B1_fn_annual_salary.sql
 Expected    : "Function created." and "No errors."

 Parameters  : p_emp_id  IN employees.emp_id%TYPE - the employee to look up
 Returns     : NUMBER    - annual salary in RWF, ROUND(salary * 12, 2)
 Behaviour   : p_emp_id is NULL       -> returns NULL
               employee not found     -> returns NULL (NO_DATA_FOUND is caught)
               employee salary NULL   -> returns NULL (NULL * 12 = NULL)
 Error codes : none raised.
 Design note : Returning NULL (instead of raising an error) for "not found"
               keeps the function safe inside a SELECT: one bad ID gives an
               empty cell for that row instead of failing the whole query.
               Not DETERMINISTIC: the result depends on table data, which can
               change, so the same input does not always give the same output.
================================================================================
*/
SET SERVEROUTPUT ON SIZE UNLIMITED

CREATE OR REPLACE FUNCTION fn_annual_salary (
    p_emp_id IN employees.emp_id%TYPE
) RETURN NUMBER
IS
    c_months_per_year CONSTANT PLS_INTEGER := 12;
    v_salary          employees.salary%TYPE;
BEGIN
    IF p_emp_id IS NULL THEN
        RETURN NULL;
    END IF;

    SELECT salary
      INTO v_salary
      FROM employees
     WHERE emp_id = p_emp_id;

    RETURN ROUND(v_salary * c_months_per_year, 2);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;   -- unknown employee: no annual salary
END fn_annual_salary;
/
SHOW ERRORS FUNCTION fn_annual_salary
