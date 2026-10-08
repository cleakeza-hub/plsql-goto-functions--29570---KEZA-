/*
================================================================================
 File        : 03_tests/test_validate_payroll.sql
 Task        : Tests for C1 fn_validate_payroll
 Author      : Keza Christa Clea (Student ID 29570)
 Course      : INSY 8311 - Database Development with PL/SQL (AUCA)
 Purpose     : 1. Runs fn_validate_payroll on EVERY payroll row in a SELECT.
               2. Asserts that each row returns its expected result (VALID or
                  the specific INVALID reason), plus a payroll_id that does
                  not exist and a NULL payroll_id.
               3. Prints valid/invalid counts and tests passed/failed.
 Dependencies: 00_setup/create_tables.sql, 02_functions/B1-B4 and C1.
 How to run  : @03_tests/test_validate_payroll.sql
 Expected    : Result set of 17 rows (6 VALID, 11 INVALID), then 19 PASS
               lines and "Failed: 0".
 Data changes: none.
================================================================================
*/
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET PAGESIZE 100
SET TAB OFF

COLUMN pay_period FORMAT A10
COLUMN gross_pay  FORMAT 999,999,990.00
COLUMN tax_amount FORMAT 999,999,990.00
COLUMN net_pay    FORMAT 999,999,990.00
COLUMN result     FORMAT A55

PROMPT
PROMPT ==== fn_validate_payroll on every payroll row ====
SELECT p.payroll_id,
       p.emp_id,
       p.pay_period,
       p.gross_pay,
       p.tax_amount,
       p.net_pay,
       fn_validate_payroll(p.payroll_id) AS result
  FROM payroll p
 ORDER BY p.payroll_id;

PROMPT ==== Assertions ====
DECLARE
    TYPE t_case IS RECORD (
        payroll_id payroll.payroll_id%TYPE,
        expected   VARCHAR2(100)
    );
    TYPE t_cases IS TABLE OF t_case;

    c_valid      CONSTANT VARCHAR2(10) := 'VALID';
    v_cases      t_cases := t_cases();
    v_actual     VARCHAR2(250);
    v_total      PLS_INTEGER := 0;
    v_passed     PLS_INTEGER := 0;
    v_valid      PLS_INTEGER := 0;
    v_invalid    PLS_INTEGER := 0;

    PROCEDURE add_case (p_id IN NUMBER, p_expected IN VARCHAR2) IS
    BEGIN
        v_cases.EXTEND;
        v_cases(v_cases.LAST).payroll_id := p_id;
        v_cases(v_cases.LAST).expected   := p_expected;
    END add_case;
BEGIN
    -- Expected result for each row in 00_setup/create_tables.sql
    add_case(1,    c_valid);
    add_case(2,    c_valid);
    add_case(3,    c_valid);
    add_case(4,    c_valid);
    add_case(5,    c_valid);
    add_case(6,    'INVALID: employee not found');
    add_case(7,    'INVALID: employee has no department');
    add_case(8,    'INVALID: employee hire date is in the future');
    add_case(9,    'INVALID: gross pay is missing or not positive');
    add_case(10,   'INVALID: gross pay is missing or not positive');
    add_case(11,   'INVALID: gross pay is missing or not positive');
    add_case(12,   'INVALID: pay period is not in YYYY-MM format');
    add_case(13,   'INVALID: pay period is not in YYYY-MM format');
    add_case(14,   'INVALID: tax amount does not match calculated tax');
    add_case(15,   'INVALID: net pay does not equal gross pay minus tax');
    add_case(16,   'INVALID: tax amount does not match calculated tax');
    add_case(17,   c_valid);
    add_case(9999, 'INVALID: payroll record not found');   -- payroll_id that does not exist
    add_case(NULL, 'INVALID: payroll record not found');   -- NULL payroll_id

    FOR i IN 1 .. v_cases.COUNT LOOP
        v_actual := fn_validate_payroll(v_cases(i).payroll_id);
        v_total  := v_total + 1;

        IF v_actual = v_cases(i).expected THEN
            v_passed := v_passed + 1;
            DBMS_OUTPUT.PUT_LINE('PASS  payroll_id ' || RPAD(NVL(TO_CHAR(v_cases(i).payroll_id), 'NULL'), 5)
                || ' -> ' || v_actual);
        ELSE
            DBMS_OUTPUT.PUT_LINE('FAIL  payroll_id ' || RPAD(NVL(TO_CHAR(v_cases(i).payroll_id), 'NULL'), 5)
                || ' expected "' || v_cases(i).expected || '" but got "' || v_actual || '"');
        END IF;
    END LOOP;

    -- Valid / invalid counts over the real payroll table
    FOR r IN (SELECT fn_validate_payroll(payroll_id) AS result FROM payroll) LOOP
        IF r.result = c_valid THEN
            v_valid := v_valid + 1;
        ELSE
            v_invalid := v_invalid + 1;
        END IF;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(RPAD('=', 80, '='));
    DBMS_OUTPUT.PUT_LINE('Payroll rows VALID   : ' || v_valid);
    DBMS_OUTPUT.PUT_LINE('Payroll rows INVALID : ' || v_invalid);
    DBMS_OUTPUT.PUT_LINE('Tests run            : ' || v_total);
    DBMS_OUTPUT.PUT_LINE('Passed               : ' || v_passed);
    DBMS_OUTPUT.PUT_LINE('Failed               : ' || (v_total - v_passed));
END;
/

CLEAR COLUMNS
