/*
================================================================================
 File        : 03_tests/test_functions.sql
 Task        : Unit tests for B1-B4
 Author      : Keza Christa Clea (Student ID 29570)
 Course      : INSY 8311 - Database Development with PL/SQL (AUCA)
 Purpose     : Calls fn_annual_salary, fn_years_of_service, fn_calculate_tax
               and fn_dept_name with normal, boundary, zero, NULL, not-found
               and error inputs, and prints PASS/FAIL for each test.
 Dependencies: 00_setup/create_tables.sql and 02_functions/B1-B4.
 How to run  : @03_tests/test_functions.sql
 Expected    : Every line starts with PASS, and the summary ends with
               "Failed: 0".
 Data changes: none.
 Note        : Years-of-service tests use dates relative to today
               (ADD_MONTHS(TRUNC(SYSDATE), -60) etc.), so they stay correct
               no matter which day the script is run.
================================================================================
*/
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET TAB OFF

DECLARE
    v_total  PLS_INTEGER := 0;
    v_passed PLS_INTEGER := 0;
    v_num    NUMBER;
    v_dept   employees.dept_id%TYPE;

    -- Assert for NUMBER results. Two NULLs count as equal.
    PROCEDURE assert_num (p_name IN VARCHAR2, p_expected IN NUMBER, p_actual IN NUMBER) IS
        v_ok BOOLEAN;
    BEGIN
        v_ok := (p_expected = p_actual) OR (p_expected IS NULL AND p_actual IS NULL);
        v_total := v_total + 1;
        IF v_ok THEN
            v_passed := v_passed + 1;
            DBMS_OUTPUT.PUT_LINE('PASS  ' || RPAD(p_name, 52)
                || ' expected=' || NVL(TO_CHAR(p_expected), 'NULL')
                || ' actual='   || NVL(TO_CHAR(p_actual), 'NULL'));
        ELSE
            DBMS_OUTPUT.PUT_LINE('FAIL  ' || RPAD(p_name, 52)
                || ' expected=' || NVL(TO_CHAR(p_expected), 'NULL')
                || ' actual='   || NVL(TO_CHAR(p_actual), 'NULL'));
        END IF;
    END assert_num;

    -- Assert for VARCHAR2 results. Two NULLs count as equal.
    PROCEDURE assert_str (p_name IN VARCHAR2, p_expected IN VARCHAR2, p_actual IN VARCHAR2) IS
        v_ok BOOLEAN;
    BEGIN
        v_ok := (p_expected = p_actual) OR (p_expected IS NULL AND p_actual IS NULL);
        v_total := v_total + 1;
        IF v_ok THEN
            v_passed := v_passed + 1;
            DBMS_OUTPUT.PUT_LINE('PASS  ' || RPAD(p_name, 52)
                || ' expected=' || NVL(p_expected, 'NULL') || ' actual=' || NVL(p_actual, 'NULL'));
        ELSE
            DBMS_OUTPUT.PUT_LINE('FAIL  ' || RPAD(p_name, 52)
                || ' expected=' || NVL(p_expected, 'NULL') || ' actual=' || NVL(p_actual, 'NULL'));
        END IF;
    END assert_str;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Unit tests for B1-B4');
    DBMS_OUTPUT.PUT_LINE(RPAD('=', 100, '='));

    -- ---------------- B1 fn_annual_salary ----------------
    DBMS_OUTPUT.PUT_LINE('-- B1 fn_annual_salary');
    assert_num('B1 normal: emp 101 (450,000 x 12)',          5400000, fn_annual_salary(101));
    assert_num('B1 boundary salary: emp 104 (60,000 x 12)',   720000, fn_annual_salary(104));
    assert_num('B1 NULL salary: emp 111',                       NULL, fn_annual_salary(111));
    assert_num('B1 not found: emp 999',                         NULL, fn_annual_salary(999));
    assert_num('B1 NULL input',                                 NULL, fn_annual_salary(NULL));

    -- ---------------- B2 fn_years_of_service ----------------
    DBMS_OUTPUT.PUT_LINE('-- B2 fn_years_of_service');
    assert_num('B2 hired today -> 0',                              0, fn_years_of_service(TRUNC(SYSDATE)));
    assert_num('B2 exactly 5 years ago -> 5',                      5, fn_years_of_service(ADD_MONTHS(TRUNC(SYSDATE), -60)));
    assert_num('B2 one day short of 5 years -> 4',                 4, fn_years_of_service(ADD_MONTHS(TRUNC(SYSDATE), -60) + 1));
    assert_num('B2 exactly 10 years ago -> 10',                   10, fn_years_of_service(ADD_MONTHS(TRUNC(SYSDATE), -120)));
    assert_num('B2 time of day is ignored (today 23:59) -> 0',     0, fn_years_of_service(TRUNC(SYSDATE) + 0.999));
    assert_num('B2 NULL input -> NULL',                         NULL, fn_years_of_service(NULL));
    BEGIN
        v_num := fn_years_of_service(TRUNC(SYSDATE) + 1);
        assert_num('B2 future date raises -20002 (no error raised!)', -20002, 0);
    EXCEPTION
        WHEN OTHERS THEN
            assert_num('B2 future date raises -20002',            -20002, SQLCODE);
    END;

    -- ---------------- B3 fn_calculate_tax ----------------
    DBMS_OUTPUT.PUT_LINE('-- B3 fn_calculate_tax');
    assert_num('B3 zero salary -> 0',                              0, fn_calculate_tax(0));
    assert_num('B3 below first bracket: 45,000 -> 0',              0, fn_calculate_tax(45000));
    assert_num('B3 boundary 60,000 -> 0',                          0, fn_calculate_tax(60000));
    assert_num('B3 boundary 60,001 -> 0.10',                     0.1, fn_calculate_tax(60001));
    assert_num('B3 middle of 10% bracket: 85,000 -> 2,500',     2500, fn_calculate_tax(85000));
    assert_num('B3 boundary 100,000 -> 4,000',                  4000, fn_calculate_tax(100000));
    assert_num('B3 boundary 100,001 -> 4,000.20',             4000.2, fn_calculate_tax(100001));
    assert_num('B3 middle of 20% bracket: 150,000 -> 14,000',  14000, fn_calculate_tax(150000));
    assert_num('B3 boundary 200,000 -> 24,000',                24000, fn_calculate_tax(200000));
    assert_num('B3 boundary 200,001 -> 24,000.30',           24000.3, fn_calculate_tax(200001));
    assert_num('B3 worked example 250,000 -> 39,000',          39000, fn_calculate_tax(250000));
    assert_num('B3 high salary 450,000 -> 99,000',             99000, fn_calculate_tax(450000));
    assert_num('B3 rounding: 60,000.55 -> 0.06',                0.06, fn_calculate_tax(60000.55));
    assert_num('B3 NULL input -> NULL',                         NULL, fn_calculate_tax(NULL));
    BEGIN
        v_num := fn_calculate_tax(-1);
        assert_num('B3 negative raises -20003 (no error raised!)', -20003, 0);
    EXCEPTION
        WHEN OTHERS THEN
            assert_num('B3 negative salary raises -20003',       -20003, SQLCODE);
    END;

    -- ---------------- B4 fn_dept_name ----------------
    DBMS_OUTPUT.PUT_LINE('-- B4 fn_dept_name');
    assert_str('B4 normal: dept 10',                       'Finance', fn_dept_name(10));
    assert_str('B4 normal: dept 30',        'Information Technology', fn_dept_name(30));
    assert_str('B4 NULL input',                      'No Department', fn_dept_name(NULL));
    assert_str('B4 not found: dept 999',        'Unknown Department', fn_dept_name(999));
    SELECT dept_id INTO v_dept FROM employees WHERE emp_id = 112;
    assert_str('B4 employee with NULL dept (emp 112)',  'No Department', fn_dept_name(v_dept));

    DBMS_OUTPUT.PUT_LINE(RPAD('=', 100, '='));
    DBMS_OUTPUT.PUT_LINE('Total tests: ' || v_total);
    DBMS_OUTPUT.PUT_LINE('Passed     : ' || v_passed);
    DBMS_OUTPUT.PUT_LINE('Failed     : ' || (v_total - v_passed));
END;
/
