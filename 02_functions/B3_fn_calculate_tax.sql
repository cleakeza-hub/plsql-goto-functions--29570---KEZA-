/*
================================================================================
 File        : 02_functions/B3_fn_calculate_tax.sql
 Task        : B3 - Function: progressive (PAYE-style) monthly tax
 Author      : Keza Christa Clea (Student ID 29570)
 Course      : INSY 8311 - Database Development with PL/SQL (AUCA)
 Purpose     : fn_calculate_tax(p_monthly_salary) returns the monthly tax
               in RWF using marginal brackets:
                     0 -  60,000 ->  0%
                60,001 - 100,000 -> 10%
               100,001 - 200,000 -> 20%
                 above   200,000 -> 30%
               Each rate applies ONLY to the part of the salary that falls
               inside its bracket.
 Dependencies: None.
 How to run  : @02_functions/B3_fn_calculate_tax.sql
 Expected    : "Function created." and "No errors."

 Worked example, salary 250,000:
     first  60,000            x  0% =      0
     next   40,000 (60k-100k) x 10% =  4,000
     next  100,000 (100k-200k)x 20% = 20,000
     last   50,000 (above 200k)x 30% = 15,000
                                 total = 39,000

 Parameters  : p_monthly_salary IN NUMBER - gross monthly salary in RWF
 Returns     : NUMBER - tax, ROUND(x, 2)
 Behaviour   : NULL      -> returns NULL
               0         -> returns 0
               negative  -> raises -20003
 Error codes : -20003  Salary cannot be negative.
 Design note : DETERMINISTIC is correct here: the result depends only on the
               input (no tables, no SYSDATE), so the same salary always gives
               the same tax. Oracle may then reuse results within a query.
================================================================================
*/
SET SERVEROUTPUT ON SIZE UNLIMITED

CREATE OR REPLACE FUNCTION fn_calculate_tax (
    p_monthly_salary IN NUMBER
) RETURN NUMBER
DETERMINISTIC
IS
    -- Bracket upper limits (RWF)
    c_limit_0pct   CONSTANT NUMBER := 60000;
    c_limit_10pct  CONSTANT NUMBER := 100000;
    c_limit_20pct  CONSTANT NUMBER := 200000;
    -- Rates
    c_rate_10      CONSTANT NUMBER := 0.10;
    c_rate_20      CONSTANT NUMBER := 0.20;
    c_rate_30      CONSTANT NUMBER := 0.30;
    c_err_negative CONSTANT PLS_INTEGER := -20003;

    v_tax          NUMBER := 0;
BEGIN
    IF p_monthly_salary IS NULL THEN
        RETURN NULL;
    END IF;

    IF p_monthly_salary < 0 THEN
        RAISE_APPLICATION_ERROR(c_err_negative,
            'Salary cannot be negative: ' || p_monthly_salary);
    END IF;

    -- 10% on the part between 60,000 and 100,000
    IF p_monthly_salary > c_limit_0pct THEN
        v_tax := v_tax
               + (LEAST(p_monthly_salary, c_limit_10pct) - c_limit_0pct) * c_rate_10;
    END IF;

    -- 20% on the part between 100,000 and 200,000
    IF p_monthly_salary > c_limit_10pct THEN
        v_tax := v_tax
               + (LEAST(p_monthly_salary, c_limit_20pct) - c_limit_10pct) * c_rate_20;
    END IF;

    -- 30% on the part above 200,000
    IF p_monthly_salary > c_limit_20pct THEN
        v_tax := v_tax + (p_monthly_salary - c_limit_20pct) * c_rate_30;
    END IF;

    RETURN ROUND(v_tax, 2);
END fn_calculate_tax;
/
SHOW ERRORS FUNCTION fn_calculate_tax
