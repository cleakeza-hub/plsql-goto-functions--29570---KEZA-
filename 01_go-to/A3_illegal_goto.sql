/*
================================================================================
 File        : 01_goto/A3_illegal_goto.sql
 Task        : A3 - Illegal GOTO and Fix
 Author      : Keza Christa Clea (Student ID 29570)
 Course      : INSY 8311 - Database Development with PL/SQL (AUCA)
 Purpose     : Demonstrates six ILLEGAL uses of GOTO / labels. Each illegal
               block is immediately followed by a FIXED block that compiles
               and runs.

 >>> NOTE FOR THE GRADER: THE COMPILE ERRORS IN THIS FILE ARE INTENTIONAL. <<<
     Every block marked "ILLEGAL" is meant to fail with the error code
     given in its comment (ORA-06550 + PLS-00375, PLS-00201 or PLS-00103). The script
     deliberately does NOT use WHENEVER SQLERROR EXIT, so SQL*Plus prints
     the error and continues with the next block.

 Dependencies: None (no tables).
 How to run  : @01_goto/A3_illegal_goto.sql
 Expected    : (verified on Oracle AI Database 26ai Free, release 23.26)
               Cases 1, 2, 5 ILLEGAL -> PLS-00375: illegal GOTO statement;
                                        this GOTO cannot branch to label '...'
               Cases 3, 4 ILLEGAL    -> PLS-00201: identifier '...' must be
                                        declared (see note below)
               Case 6 ILLEGAL        -> PLS-00103: Encountered the symbol "END"
               Every FIXED block  -> prints "Case n FIXED: ..." lines.
 Data changes: none.

 The rule behind cases 1-5:
   A GOTO can only jump to a label that is in the same sequence of
   statements as the GOTO, or in a sequence that ENCLOSES it. It can never
   jump INTO an IF, CASE, LOOP or sub-block, from one IF branch to
   another, or from an exception handler back into the block it handles.

 Why cases 3 and 4 give PLS-00201 instead of PLS-00375:
   A LOOP body and a nested BEGIN...END each open a new SCOPE for labels.
   A label inside them is invisible from outside, so the compiler cannot
   even find the label the GOTO names and reports "identifier must be
   declared". A label inside an IF is in the same scope as the GOTO, so
   the compiler finds it and then rejects the jump with PLS-00375. Both
   errors mean the same thing here: this GOTO target is not allowed.
================================================================================
*/
SET SERVEROUTPUT ON SIZE UNLIMITED
SET LINESIZE 200
SET TAB OFF

PROMPT
PROMPT ==== Case 1 ILLEGAL: GOTO into an IF statement from outside it (expect PLS-00375) ====
DECLARE
    v_x NUMBER := 5;
BEGIN
    -- The GOTO is outside the IF; the label is inside the IF's THEN branch.
    -- Jumping into an IF would skip its condition test, so PL/SQL forbids it.
    GOTO inside_if;
    IF v_x > 0 THEN
        <<inside_if>>
        DBMS_OUTPUT.PUT_LINE('Case 1 ILLEGAL: reached the label inside the IF');
    END IF;
END;
/

PROMPT ==== Case 1 FIXED: label moved out of the IF to the same level as the GOTO ====
DECLARE
    v_x NUMBER := 5;
BEGIN
    -- Fix: the label is now in the same sequence as the GOTO (the block body),
    -- so the jump never enters the IF.
    GOTO after_if;
    IF v_x > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Case 1 FIXED: this line is skipped by the GOTO');
    END IF;
    <<after_if>>
    DBMS_OUTPUT.PUT_LINE('Case 1 FIXED: GOTO jumped over the IF to a label at block level');
END;
/

PROMPT
PROMPT ==== Case 2 ILLEGAL: GOTO from the THEN branch into the ELSE branch (expect PLS-00375) ====
DECLARE
    v_x NUMBER := 5;
BEGIN
    -- THEN and ELSE are separate sequences of statements. Neither encloses the
    -- other, so a jump from one into the other is illegal.
    IF v_x > 0 THEN
        GOTO else_part;
    ELSE
        <<else_part>>
        DBMS_OUTPUT.PUT_LINE('Case 2 ILLEGAL: reached the ELSE label');
    END IF;
END;
/

PROMPT ==== Case 2 FIXED: shared code moved after the IF ====
DECLARE
    v_x NUMBER := 5;
BEGIN
    -- Fix: the code both branches need is placed after END IF, at block level.
    -- Jumping OUT of an IF branch to the enclosing sequence is legal.
    IF v_x > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Case 2 FIXED: in the THEN branch, jumping out of the IF');
        GOTO shared_part;
    ELSE
        DBMS_OUTPUT.PUT_LINE('Case 2 FIXED: in the ELSE branch');
    END IF;
    <<shared_part>>
    DBMS_OUTPUT.PUT_LINE('Case 2 FIXED: reached shared code after END IF');
END;
/

PROMPT
PROMPT ==== Case 3 ILLEGAL: GOTO into a LOOP body from outside the loop (expect PLS-00201) ====
DECLARE
    v_i NUMBER := 0;
BEGIN
    -- The loop body is its own sequence. Jumping into the middle of it would
    -- bypass the loop start (and, in a FOR loop, the counter setup).
    -- The label is in the loop's scope, so from out here it is not visible:
    -- Oracle reports PLS-00201 identifier 'INSIDE_LOOP' must be declared.
    GOTO inside_loop;
    LOOP
        v_i := v_i + 1;
        <<inside_loop>>
        DBMS_OUTPUT.PUT_LINE('Case 3 ILLEGAL: inside the loop, i = ' || v_i);
        EXIT WHEN v_i >= 3;
    END LOOP;
END;
/

PROMPT ==== Case 3 FIXED: jump to a label placed BEFORE the loop ====
DECLARE
    v_i NUMBER := 0;
BEGIN
    -- Fix: the label is at block level, just before LOOP, so the loop is
    -- entered normally from the top.
    GOTO start_loop;
    DBMS_OUTPUT.PUT_LINE('Case 3 FIXED: this line is skipped');
    <<start_loop>>
    LOOP
        v_i := v_i + 1;
        DBMS_OUTPUT.PUT_LINE('Case 3 FIXED: inside the loop, i = ' || v_i);
        EXIT WHEN v_i >= 3;
    END LOOP;
END;
/

PROMPT
PROMPT ==== Case 4 ILLEGAL: GOTO from the outer block into a nested sub-block (expect PLS-00201) ====
BEGIN
    -- The label belongs to the inner BEGIN...END. A GOTO can leave a block
    -- but cannot enter one, because that would skip the inner block's start
    -- (its declarations would never be set up).
    -- The label is in the sub-block's scope, so the outer GOTO cannot see it:
    -- Oracle reports PLS-00201 identifier 'INNER_LABEL' must be declared.
    GOTO inner_label;
    BEGIN
        <<inner_label>>
        DBMS_OUTPUT.PUT_LINE('Case 4 ILLEGAL: inside the nested block');
    END;
END;
/

PROMPT ==== Case 4 FIXED: label placed in front of the sub-block, at the outer level ====
BEGIN
    -- Fix: jump to a label in the OUTER sequence; the sub-block then starts
    -- normally from its BEGIN.
    GOTO before_inner;
    DBMS_OUTPUT.PUT_LINE('Case 4 FIXED: this line is skipped');
    <<before_inner>>
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Case 4 FIXED: entered the nested block from its BEGIN');
        -- Jumping OUT of the inner block to the outer one is legal:
        GOTO outer_end;
    END;
    <<outer_end>>
    DBMS_OUTPUT.PUT_LINE('Case 4 FIXED: GOTO from the inner block to the outer block worked');
END;
/

PROMPT
PROMPT ==== Case 5 ILLEGAL: GOTO from an EXCEPTION handler back into its block (expect PLS-00375) ====
DECLARE
    v_attempts NUMBER := 0;
BEGIN
    <<retry>>
    v_attempts := v_attempts + 1;
    IF v_attempts < 3 THEN
        RAISE ZERO_DIVIDE;
    END IF;
    DBMS_OUTPUT.PUT_LINE('Case 5 ILLEGAL: attempts = ' || v_attempts);
EXCEPTION
    WHEN ZERO_DIVIDE THEN
        -- Once an exception is raised, the block that raised it is finished.
        -- The handler cannot jump back into that block's statements.
        GOTO retry;
END;
/

PROMPT ==== Case 5 FIXED: retry with a loop around a sub-block ====
DECLARE
    v_attempts NUMBER := 0;
    v_done     BOOLEAN := FALSE;
BEGIN
    -- Fix: put the risky code in a sub-block INSIDE a loop. The handler just
    -- records the failure; the loop starts the sub-block again from the top.
    WHILE NOT v_done LOOP
        BEGIN
            v_attempts := v_attempts + 1;
            IF v_attempts < 3 THEN
                RAISE ZERO_DIVIDE;
            END IF;
            v_done := TRUE;
            DBMS_OUTPUT.PUT_LINE('Case 5 FIXED: succeeded on attempt ' || v_attempts);
        EXCEPTION
            WHEN ZERO_DIVIDE THEN
                DBMS_OUTPUT.PUT_LINE('Case 5 FIXED: attempt ' || v_attempts || ' failed, retrying');
        END;
    END LOOP;
END;
/

PROMPT
PROMPT ==== Case 6 ILLEGAL: label at the end of a block with no statement after it (expect PLS-00103) ====
DECLARE
    v_x NUMBER := 5;
BEGIN
    IF v_x > 0 THEN
        GOTO the_end;
    END IF;
    DBMS_OUTPUT.PUT_LINE('Case 6 ILLEGAL: not reached');
    -- A label marks a STATEMENT. END is not a statement, so the parser finds
    -- END where it expected a statement and reports PLS-00103.
    <<the_end>>
END;
/

PROMPT ==== Case 6 FIXED: NULL; after the label ====
DECLARE
    v_x NUMBER := 5;
BEGIN
    IF v_x > 0 THEN
        DBMS_OUTPUT.PUT_LINE('Case 6 FIXED: jumping to the label at the end of the block');
        GOTO the_end;
    END IF;
    DBMS_OUTPUT.PUT_LINE('Case 6 FIXED: not reached');
    <<the_end>>
    -- Fix: NULL; is an executable statement that does nothing, so the label
    -- now has a statement to point to and the block compiles.
    NULL;
END;
/
