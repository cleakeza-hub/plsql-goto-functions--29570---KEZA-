/*
================================================================================
 File        : 02_functions/C1_fn_validate_payroll.sql
 Task        : C1 - Combined task: payroll validator (GOTO + functions)
 Author      : Keza Christa Clea (Student ID 29570)
 Course      : INSY 8311 - Database Development with PL/SQL (AUCA)
 Purpose     : fn_validate_payroll(p_payroll_id) checks one payroll row and
               returns 'VALID' or 'INVALID: <reason>'. It runs the checks in
               order; the FIRST failing check sets the reason and jumps
               (GOTO) to <<invalid_payroll>>. If every check passes it jumps
               to <<valid_payroll>>. Both paths end at one RETURN.
 Dependencies: Tables PAYROLL, EMPLOYEES, DEPARTMENTS and the functions
               fn_dept_name (B4), fn_years_of_service (B2),
               fn_calculate_tax (B3). Run 00_setup and B1-B4 first.
 How to run  : @02_functions/C1_fn_validate_payroll.sql
 Expected    : "Function created." and "No errors."

 Checks, in order, with the exact reason returned:
   1. payroll row exists      -> 'INVALID: payroll record not found'
   2. employee exists         -> 'INVALID: employee not found'
   3. employee has department -> 'INVALID: employee has no department'
   4. hire date not in future -> 'INVALID: employee hire date is in the future'
   5. gross_pay not NULL, > 0 -> 'INVALID: gross pay is missing or not positive'
   6. pay_period is YYYY-MM   -> 'INVALID: pay period is not in YYYY-MM format'
   7. tax = fn_calculate_tax  -> 'INVALID: tax amount does not match calculated tax'
   8. net = gross - tax       -> 'INVALID: net pay does not equal gross pay minus tax'
   Checks 7 and 8 allow a tolerance of 0.01 RWF.

 Parameters  : p_payroll_id IN payroll.payroll_id%TYPE
 Returns     : VARCHAR2 - 'VALID' or 'INVALID: <reason>'
 Behaviour   : NULL or unknown payroll_id -> 'INVALID: payroll record not found'
 Error codes : none raised; every problem becomes an 'INVALID: ...' result.
 SQL-safe    : No INSERT/UPDATE/DELETE and no COMMIT, so it can be called
               from a SELECT statement.

 Why every GOTO here is legal:
   PL/SQL lets a GOTO jump to a label that is in the SAME sequence of
   statements, or OUT to an ENCLOSING block. All three labels
   (invalid_payroll, valid_payroll, return_result) sit directly in the
   function's main BEGIN...END sequence, so:
   - a GOTO inside an IF jumps OUT of the IF into the enclosing sequence: legal;
   - a GOTO inside a nested block's EXCEPTION handler jumps OUT to the
     enclosing block: legal (only jumping back INTO the block that raised
     the exception is illegal).
   No GOTO jumps INTO an IF, a LOOP, or a sub-block.
================================================================================
*/
SET SERVEROUTPUT ON SIZE UNLIMITED

CREATE OR REPLACE FUNCTION fn_validate_payroll (
    p_payroll_id IN payroll.payroll_id%TYPE
) RETURN VARCHAR2
IS
    c_tolerance      CONSTANT NUMBER       := 0.01;
    c_period_pattern CONSTANT VARCHAR2(30) := '^[0-9]{4}-(0[1-9]|1[0-2])$';  -- YYYY-MM, month 01-12

    v_pay            payroll%ROWTYPE;
    v_hire_date      employees.hire_date%TYPE;
    v_dept_id        employees.dept_id%TYPE;
    v_dept_name      departments.dept_name%TYPE;
    v_years          NUMBER;
    v_expected_tax   NUMBER;
    v_reason         VARCHAR2(200);
    v_result         VARCHAR2(250);
BEGIN
    -- Check 1: the payroll row exists ------------------------------------------
    BEGIN
        SELECT *
          INTO v_pay
          FROM payroll
         WHERE payroll_id = p_payroll_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_reason := 'payroll record not found';
            -- Legal: jumps from a nested block's exception handler OUT to a
            -- label in the enclosing (function) block.
            GOTO invalid_payroll;
    END;

    -- Check 2: the employee exists ---------------------------------------------
    BEGIN
        SELECT hire_date, dept_id
          INTO v_hire_date, v_dept_id
          FROM employees
         WHERE emp_id = v_pay.emp_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            v_reason := 'employee not found';
            GOTO invalid_payroll;   -- Legal: exception handler -> enclosing block.
    END;

    -- Check 3: the employee has a department (uses B4 fn_dept_name) -------------
    v_dept_name := fn_dept_name(v_dept_id);
    IF v_dept_name IN ('No Department', 'Unknown Department') THEN
        v_reason := 'employee has no department';
        GOTO invalid_payroll;       -- Legal: out of an IF to the enclosing sequence.
    END IF;

    -- Check 4: hire date not in the future (uses B2 fn_years_of_service) --------
    -- fn_years_of_service raises -20002 for a future date; we catch it here
    -- and turn it into an INVALID result instead of letting it escape.
    BEGIN
        v_years := fn_years_of_service(v_hire_date);
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20002 THEN
                v_reason := 'employee hire date is in the future';
                GOTO invalid_payroll;   -- Legal: exception handler -> enclosing block.
            END IF;
            RAISE;   -- any other error is unexpected; handled at the bottom
    END;

    -- Check 5: gross pay present and positive ----------------------------------
    IF v_pay.gross_pay IS NULL OR v_pay.gross_pay <= 0 THEN
        v_reason := 'gross pay is missing or not positive';
        GOTO invalid_payroll;       -- Legal: out of an IF.
    END IF;

    -- Check 6: pay period format YYYY-MM ----------------------------------------
    IF v_pay.pay_period IS NULL
       OR NOT REGEXP_LIKE(v_pay.pay_period, c_period_pattern) THEN
        v_reason := 'pay period is not in YYYY-MM format';
        GOTO invalid_payroll;       -- Legal: out of an IF.
    END IF;

    -- Check 7: tax matches the progressive calculation (uses B3) ---------------
    v_expected_tax := fn_calculate_tax(v_pay.gross_pay);
    IF v_pay.tax_amount IS NULL
       OR ABS(v_pay.tax_amount - v_expected_tax) > c_tolerance THEN
        v_reason := 'tax amount does not match calculated tax';
        GOTO invalid_payroll;       -- Legal: out of an IF.
    END IF;

    -- Check 8: net = gross - tax -----------------------------------------------
    IF v_pay.net_pay IS NULL
       OR ABS(v_pay.net_pay - (v_pay.gross_pay - v_pay.tax_amount)) > c_tolerance THEN
        v_reason := 'net pay does not equal gross pay minus tax';
        GOTO invalid_payroll;       -- Legal: out of an IF.
    END IF;

    -- All eight checks passed.
    GOTO valid_payroll;             -- Legal: forward jump in the same sequence.

    -- Label rule: a label must be followed by an executable statement.
    -- Here each label is followed by an assignment, so no NULL; is needed.
    <<invalid_payroll>>
    v_result := 'INVALID: ' || v_reason;
    GOTO return_result;             -- Legal: skip over the VALID branch.

    <<valid_payroll>>
    v_result := 'VALID';

    <<return_result>>               -- single exit point for both paths
    RETURN v_result;
EXCEPTION
    WHEN OTHERS THEN
        -- Never let an unexpected error break a SELECT that calls this function.
        RETURN 'INVALID: unexpected error ' || SQLCODE;
END fn_validate_payroll;
/
SHOW ERRORS FUNCTION fn_validate_payroll
