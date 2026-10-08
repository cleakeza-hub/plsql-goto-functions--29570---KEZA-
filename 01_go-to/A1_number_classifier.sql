/*
================================================================================
 File        : 01_goto/A1_number_classifier.sql
 Task        : A1 - Number Classifier (with GOTO)
 Author      : Keza Christa Clea (Student ID 29570)
 Course      : INSY 8311 - Database Development with PL/SQL (AUCA)
 Purpose     : Loops over a list of test numbers and uses GOTO + labels to
               classify each one as NULL / NEGATIVE / ZERO / POSITIVE and,
               for numbers that are not NULL, as EVEN / ODD / NOT AN INTEGER.
 Dependencies: None (no tables). SYS.ODCINUMBERLIST is a built-in Oracle
               collection type (a VARRAY of NUMBER).
 How to run  : @01_goto/A1_number_classifier.sql
 Expected    :
     A1 - Number Classifier
     ----------------------------------------
     -15        -> NEGATIVE, ODD
     -4         -> NEGATIVE, EVEN
     0          -> ZERO, EVEN
     7          -> POSITIVE, ODD
     12         -> POSITIVE, EVEN
     3.5        -> POSITIVE, NOT AN INTEGER
     NULL       -> NULL, cannot be classified
     ----------------------------------------
     Numbers processed: 7
 Data changes: none (display only), so it can be rerun with identical output.

 GOTO rules used in this file:
   - A GOTO may jump to a label in the SAME sequence of statements, or OUT to
     an ENCLOSING block/loop body.
   - A GOTO may NOT jump INTO an IF, a LOOP, or a sub-block.
   - A label must be followed by at least one executable statement
     (NULL; counts), otherwise you get PLS-00103.
   That is why all per-number labels live in ONE inner block inside the loop:
   every GOTO and every label it targets are in the same BEGIN...END
   sequence, so every jump is a legal "sideways" jump in that sequence.
================================================================================
*/
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET TAB OFF

DECLARE
    v_numbers   SYS.ODCINUMBERLIST := SYS.ODCINUMBERLIST(-15, -4, 0, 7, 12, 3.5, NULL);
    v_processed PLS_INTEGER := 0;
BEGIN
    DBMS_OUTPUT.PUT_LINE('A1 - Number Classifier');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 40, '-'));

    FOR i IN 1 .. v_numbers.COUNT LOOP
        v_processed := v_processed + 1;

        -- Inner block: holds all the classification labels for ONE number.
        DECLARE
            v_n      NUMBER := v_numbers(i);
            v_text   VARCHAR2(20) := NVL(TO_CHAR(v_n), 'NULL');
            v_sign   VARCHAR2(20);
            v_parity VARCHAR2(20);
        BEGIN
            -- Routing. Each GOTO is inside an IF and jumps OUT of that IF to a
            -- label in this inner block's sequence: legal.
            IF v_n IS NULL THEN
                GOTO is_null;
            END IF;
            IF v_n < 0 THEN
                GOTO is_negative;
            END IF;
            IF v_n = 0 THEN
                GOTO is_zero;
            END IF;
            GOTO is_positive;   -- only positive numbers reach this line

            <<is_null>>
            -- NULL has no sign and no parity: print it, then leave the inner
            -- block. GOTO next_number jumps OUT of this inner block to a label
            -- in the enclosing loop body: legal (leaving a block is allowed).
            DBMS_OUTPUT.PUT_LINE(RPAD(v_text, 10) || ' -> NULL, cannot be classified');
            GOTO next_number;

            <<is_negative>>
            v_sign := 'NEGATIVE';
            GOTO check_parity;  -- forward jump in the same sequence: legal

            <<is_zero>>
            v_sign   := 'ZERO';
            v_parity := 'EVEN'; -- 0 is divisible by 2, so zero is even
            GOTO classified;    -- skip the parity check: legal forward jump

            <<is_positive>>
            v_sign := 'POSITIVE';
            -- falls through to check_parity (no GOTO needed)

            <<check_parity>>
            -- The IF below is a normal statement; no GOTO jumps into it.
            IF v_n <> TRUNC(v_n) THEN
                v_parity := 'NOT AN INTEGER';
            ELSIF MOD(v_n, 2) = 0 THEN
                v_parity := 'EVEN';
            ELSE
                v_parity := 'ODD';
            END IF;

            <<classified>>
            -- Common output point for every non-NULL number.
            DBMS_OUTPUT.PUT_LINE(RPAD(v_text, 10) || ' -> ' || v_sign || ', ' || v_parity);
        END;

        <<next_number>>
        -- Rule: a label needs an executable statement after it. END LOOP is
        -- not a statement, so NULL; is required here.
        NULL;
    END LOOP;

    DBMS_OUTPUT.PUT_LINE(RPAD('-', 40, '-'));
    DBMS_OUTPUT.PUT_LINE('Numbers processed: ' || v_processed);
END;
/
