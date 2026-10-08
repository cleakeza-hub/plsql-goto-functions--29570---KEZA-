/*
================================================================================
 File        : 01_goto/A2_salary_review.sql
 Task        : A2 - Salary Review (with GOTO)
 Author      : Keza Christa Clea (Student ID 29570)
 Course      : INSY 8311 - Database Development with PL/SQL (AUCA)
 Purpose     : Reviews every employee's monthly salary and PROPOSES a raise:
                 salary <  100,000            -> 10%
                 100,000 <= salary <= 300,000 ->  5%
                 salary >  300,000            ->  0% (review only)
                 salary NULL                  -> skipped
               GOTO routes each employee to <<skip_employee>> or
               <<print_result>>, and every path ends at <<next_employee>>.
 Dependencies: Table EMPLOYEES (run 00_setup/create_tables.sql first).
 How to run  : @01_goto/A2_salary_review.sql
 Expected    : One line per employee (101-115, ordered by emp_id), with
               employee 111 skipped, then the summary:
                 Employees reviewed      : 14
                 Employees skipped       : 1
                 Total monthly increase  : 100,500.00 RWF
 Data changes: NONE. Proposed salaries are only displayed, never UPDATEd,
               so the script can be rerun with identical output.
================================================================================
*/
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET TAB OFF

DECLARE
    c_low_limit   CONSTANT NUMBER := 100000;   -- below this: 10%
    c_high_limit  CONSTANT NUMBER := 300000;   -- up to this: 5%; above: review only
    c_pct_low     CONSTANT NUMBER := 10;
    c_pct_mid     CONSTANT NUMBER := 5;
    c_pct_none    CONSTANT NUMBER := 0;
    c_money_fmt   CONSTANT VARCHAR2(20) := 'FM999,999,990.00';

    CURSOR c_employees IS
        SELECT emp_id, first_name, last_name, salary
          FROM employees
         ORDER BY emp_id;

    v_pct          NUMBER;
    v_new_salary   employees.salary%TYPE;
    v_note         VARCHAR2(20);
    v_reviewed     PLS_INTEGER := 0;
    v_skipped      PLS_INTEGER := 0;
    v_total_raise  NUMBER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('A2 - Salary Review (proposed, not saved)');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 88, '-'));
    DBMS_OUTPUT.PUT_LINE(RPAD('ID', 5) || RPAD('Employee', 24)
        || LPAD('Current', 14) || LPAD('Raise', 7) || LPAD('Proposed', 14) || '  Note');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 88, '-'));

    FOR r IN c_employees LOOP
        -- GOTO out of an IF to a label in the loop body: legal.
        IF r.salary IS NULL THEN
            GOTO skip_employee;
        END IF;

        v_reviewed := v_reviewed + 1;
        v_note     := NULL;

        -- Each branch sets the raise and jumps OUT of the IF to <<print_result>>,
        -- which is in the same sequence (the loop body): legal.
        IF r.salary < c_low_limit THEN
            v_pct := c_pct_low;
            GOTO print_result;
        ELSIF r.salary <= c_high_limit THEN
            v_pct := c_pct_mid;
            GOTO print_result;
        ELSE
            v_pct  := c_pct_none;
            v_note := 'review only';
            GOTO print_result;
        END IF;

        <<skip_employee>>
        -- Only reached by the GOTO above (the IF/ELSIF/ELSE always jumps away).
        v_skipped := v_skipped + 1;
        DBMS_OUTPUT.PUT_LINE(RPAD(r.emp_id, 5) || RPAD(r.first_name || ' ' || r.last_name, 24)
            || LPAD('-', 14) || LPAD('-', 7) || LPAD('-', 14) || '  skipped: no salary');
        GOTO next_employee;     -- legal forward jump; skips print_result

        <<print_result>>
        v_new_salary  := ROUND(r.salary * (1 + v_pct / 100), 2);
        v_total_raise := v_total_raise + (v_new_salary - r.salary);
        DBMS_OUTPUT.PUT_LINE(RPAD(r.emp_id, 5) || RPAD(r.first_name || ' ' || r.last_name, 24)
            || LPAD(TO_CHAR(r.salary, c_money_fmt), 14)
            || LPAD(v_pct || '%', 7)
            || LPAD(TO_CHAR(v_new_salary, c_money_fmt), 14)
            || CASE WHEN v_note IS NOT NULL THEN '  ' || v_note END);

        <<next_employee>>
        -- A label must be followed by an executable statement; END LOOP is not
        -- one, so NULL; is required.
        NULL;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(RPAD('-', 88, '-'));
    DBMS_OUTPUT.PUT_LINE('Employees reviewed      : ' || v_reviewed);
    DBMS_OUTPUT.PUT_LINE('Employees skipped       : ' || v_skipped);
    DBMS_OUTPUT.PUT_LINE('Total monthly increase  : '
        || TO_CHAR(ROUND(v_total_raise, 2), c_money_fmt) || ' RWF');

    ROLLBACK;   -- nothing was changed; kept as a safety net so reruns are identical
END;
/
