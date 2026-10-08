/*
================================================================================
 File        : 02_functions/B2_fn_years_of_service.sql
 Task        : B2 - Function: years of service
 Author      : Keza Christa Clea (Student ID 29570)
 Course      : INSY 8311 - Database Development with PL/SQL (AUCA)
 Purpose     : fn_years_of_service(p_hire_date) returns the number of
               COMPLETED full years between the hire date and today.
 Dependencies: None (works on a DATE value only).
 How to run  : @02_functions/B2_fn_years_of_service.sql
 Expected    : "Function created." and "No errors."

 Parameters  : p_hire_date IN DATE - the date the employee was hired
 Returns     : NUMBER - whole years: TRUNC(MONTHS_BETWEEN(today, hire) / 12)
 Behaviour   : p_hire_date NULL          -> returns NULL
               hire date = today         -> returns 0
               hire date in the future   -> raises -20002
 Error codes : -20002  Hire date is in the future.
 Design note : A future hire date is a data-entry error, so the function
               raises instead of returning a misleading negative number.
               Consequence: a SELECT that calls this function on a row with a
               future hire date FAILS with ORA-20002 (shown in
               03_tests/B5_functions_in_select.sql). Queries must filter that
               row out first.
               Not DETERMINISTIC: the result depends on SYSDATE, so it changes
               over time for the same input.
================================================================================
*/
SET SERVEROUTPUT ON SIZE UNLIMITED

CREATE OR REPLACE FUNCTION fn_years_of_service (
    p_hire_date IN DATE
) RETURN NUMBER
IS
    c_err_future_hire CONSTANT PLS_INTEGER := -20002;
    v_today           DATE := TRUNC(SYSDATE);   -- TRUNC removes the time part
BEGIN
    IF p_hire_date IS NULL THEN
        RETURN NULL;
    END IF;

    IF TRUNC(p_hire_date) > v_today THEN
        RAISE_APPLICATION_ERROR(
            c_err_future_hire,
            'Hire date ' || TO_CHAR(p_hire_date, 'YYYY-MM-DD')
            || ' is in the future; years of service cannot be calculated.');
    END IF;

    RETURN TRUNC(MONTHS_BETWEEN(v_today, TRUNC(p_hire_date)) / 12);
END fn_years_of_service;
/
SHOW ERRORS FUNCTION fn_years_of_service
