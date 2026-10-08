/*
================================================================================
 File        : 01_goto/A4_rewrite_no_goto.sql
 Task        : A4 - Rewrite A1 and A2 without GOTO
 Author      : Keza Christa Clea (Student ID 29570)
 Course      : INSY 8311 - Database Development with PL/SQL (AUCA)
 Purpose     : Same programs as A1 (number classifier) and A2 (salary review),
               rewritten with structured control flow only:
               IF/ELSIF/ELSE, CASE, CONTINUE WHEN and EXIT WHEN.
               There is not a single GOTO or label in this file.
 Dependencies: Table EMPLOYEES (run 00_setup/create_tables.sql first).
 How to run  : @01_goto/A4_rewrite_no_goto.sql
 Expected    : Output IDENTICAL to running A1 followed by A2 (same lines, same
               order, same summary). Checked by diffing the two spool files.
 Data changes: none (display only).
================================================================================
*/
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET TAB OFF

-- -----------------------------------------------------------------------------
-- Part 1: A1 Number Classifier without GOTO
--   - basic LOOP with EXIT WHEN instead of a FOR loop, to show EXIT WHEN
--   - CONTINUE WHEN replaces "GOTO next_number" for NULL values
--   - CASE replaces the is_negative / is_zero / is_positive labels
-- -----------------------------------------------------------------------------
DECLARE
    v_numbers   SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST(-15, -4, 0, 7, 12, 3.5, NULL);
    v_processed PLS_INTEGER := 0;
    v_i         PLS_INTEGER := 0;
    v_n         NUMBER;
    v_text      VARCHAR2(20);
    v_sign      VARCHAR2(20);
    v_parity    VARCHAR2(20);
BEGIN
    DBMS_OUTPUT.PUT_LINE('A1 - Number Classifier');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 40, '-'));

    LOOP
        v_i := v_i + 1;
        EXIT WHEN v_i > v_numbers.COUNT;           -- replaces the FOR loop bound

        v_processed := v_processed + 1;
        v_n    := v_numbers(v_i);
        v_text := NVL(TO_CHAR(v_n), 'NULL');

        IF v_n IS NULL THEN
            DBMS_OUTPUT.PUT_LINE(RPAD(v_text, 10) || ' -> NULL, cannot be classified');
        END IF;
        CONTINUE WHEN v_n IS NULL;                 -- replaces GOTO next_number

        v_sign := CASE
                      WHEN v_n < 0 THEN 'NEGATIVE'
                      WHEN v_n = 0 THEN 'ZERO'
                      ELSE 'POSITIVE'
                  END;

        v_parity := CASE
                        WHEN v_n <> TRUNC(v_n) THEN 'NOT AN INTEGER'
                        WHEN MOD(v_n, 2) = 0   THEN 'EVEN'   -- includes 0
                        ELSE 'ODD'
                    END;

        DBMS_OUTPUT.PUT_LINE(RPAD(v_text, 10) || ' -> ' || v_sign || ', ' || v_parity);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(RPAD('-', 40, '-'));
    DBMS_OUTPUT.PUT_LINE('Numbers processed: ' || v_processed);
END;
/

-- -----------------------------------------------------------------------------
-- Part 2: A2 Salary Review without GOTO
--   - CONTINUE WHEN replaces "GOTO skip_employee ... GOTO next_employee"
--   - IF/ELSIF/ELSE sets the raise; the print code simply follows the IF,
--     so no "GOTO print_result" is needed
-- -----------------------------------------------------------------------------
DECLARE
    c_low_limit   CONSTANT NUMBER := 100000;
    c_high_limit  CONSTANT NUMBER := 300000;
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
        IF r.salary IS NULL THEN
            v_skipped := v_skipped + 1;
            DBMS_OUTPUT.PUT_LINE(RPAD(r.emp_id, 5) || RPAD(r.first_name || ' ' || r.last_name, 24)
                || LPAD('-', 14) || LPAD('-', 7) || LPAD('-', 14) || '  skipped: no salary');
        END IF;
        CONTINUE WHEN r.salary IS NULL;            -- go straight to the next employee

        v_reviewed := v_reviewed + 1;
        v_note     := NULL;

        IF r.salary < c_low_limit THEN
            v_pct := c_pct_low;
        ELSIF r.salary <= c_high_limit THEN
            v_pct := c_pct_mid;
        ELSE
            v_pct  := c_pct_none;
            v_note := 'review only';
        END IF;

        v_new_salary  := ROUND(r.salary * (1 + v_pct / 100), 2);
        v_total_raise := v_total_raise + (v_new_salary - r.salary);
        DBMS_OUTPUT.PUT_LINE(RPAD(r.emp_id, 5) || RPAD(r.first_name || ' ' || r.last_name, 24)
            || LPAD(TO_CHAR(r.salary, c_money_fmt), 14)
            || LPAD(v_pct || '%', 7)
            || LPAD(TO_CHAR(v_new_salary, c_money_fmt), 14)
            || CASE WHEN v_note IS NOT NULL THEN '  ' || v_note END);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(RPAD('-', 88, '-'));
    DBMS_OUTPUT.PUT_LINE('Employees reviewed      : ' || v_reviewed);
    DBMS_OUTPUT.PUT_LINE('Employees skipped       : ' || v_skipped);
    DBMS_OUTPUT.PUT_LINE('Total monthly increase  : '
        || TO_CHAR(ROUND(v_total_raise, 2), c_money_fmt) || ' RWF');

    ROLLBACK;
END;
/

/*
================================================================================
 Comparison: GOTO versions (A1, A2) vs structured versions (A4)

 Readability
   - A4 reads top to bottom. In A1/A2 you have to find each label to see where
     a GOTO goes, and remember which paths "fall through" to the next label
     (e.g. is_positive falls into check_parity in A1).
   - In A4 the CASE expressions say what is decided in one place; in A1 the
     same decision is spread over four IF+GOTO pairs and five labels.

 Maintainability
   - Adding a new category in A4 means adding one WHEN line. In A1 it means a
     new label, a new GOTO, and checking that no other path falls into it.
   - GOTO code breaks easily when moved: putting a label inside an IF or a
     sub-block during an edit gives PLS-00375 (see A3).
   - A4 needs no "NULL;" placeholders after labels.

 Debugging
   - With structured code each statement is reached in only one way, so you
     can trace it by reading. With GOTO, a line can be reached from several
     jumps, so you must check every path into it.

 When GOTO is (rarely) acceptable
   - Jumping forward to a single cleanup/exit point in a long routine, as in
     C1 (fn_validate_payroll): many checks, and the first failure jumps to one
     <<invalid_payroll>> label. Even that can be written with IF/ELSIF or by
     raising and handling an exception.

 Why structured code is preferred
   - Structured control flow (IF, CASE, loops with EXIT/CONTINUE, exceptions)
     covers every case GOTO handles, keeps one entry and one exit per
     construct, and is what other developers expect to read.
================================================================================
*/
