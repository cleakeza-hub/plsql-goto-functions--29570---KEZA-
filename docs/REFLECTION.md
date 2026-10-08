# Reflection: PL/SQL GOTO Statements and Functions (Task C2)

Keza Christa Clea, Student ID 29570
INSY 8311, Database Development with PL/SQL


---

## Part 1: What I built and the errors I hit (factual notes)

### What I built
- **Setup:** tables `departments`, `employees` and `payroll`, with 5 departments, 15 employees and 17 payroll rows. The data deliberately includes edge cases: salaries exactly on bracket boundaries, a NULL salary, a NULL department, an employee hired today, an employee with a future hire date, and payroll rows that are each invalid for one reason.
- **A1 / A2:** a number classifier and a salary review, both written with GOTO and labels.
- **A3:** six illegal GOTO cases, each followed by a fix.
- **A4:** A1 and A2 rewritten without GOTO. The output is identical; I checked with `diff`.
- **B1–B4:** four functions: `fn_annual_salary`, `fn_years_of_service`, `fn_calculate_tax` and `fn_dept_name`.
- **B5:** the functions used in SELECT, WHERE, ORDER BY and GROUP BY.
- **C1:** `fn_validate_payroll`, which combines GOTO with the B functions to run eight checks.
- **Tests:** 32 unit tests for B1–B4 and 19 tests for C1, all passing.

### Errors and surprises during the work
- **Cases 3 and 4 in A3 gave a different error than expected.** A GOTO into a LOOP body, or into a nested BEGIN…END block, gave **PLS-00201: identifier must be declared**, not PLS-00375. The reason is that the label lives in an inner scope, so the GOTO cannot even see it. A GOTO into an IF, or from THEN into ELSE, gives **PLS-00375** because the label is in the same scope.
- **A label just before `END`** gives **PLS-00103** (`Encountered the symbol "END"`). Adding `NULL;` fixes it.
- **A function that raises an error breaks the whole SELECT.** In B5, `fn_years_of_service` on the future-dated employee raised ORA-20002 and the entire query failed. The fix is to filter that row out before calling the function.
- **A scalar subquery cannot be passed as a PL/SQL argument.** The first draft of the tests used `fn_dept_name((SELECT dept_id FROM ...))` inside a PL/SQL block. It was replaced with a `SELECT ... INTO` a variable first.
- **The expected total in the A2 header was wrong.** The first draft (written by the AI) said 101,500 RWF. Running the program showed 100,500, and re-adding the raises by hand confirmed 100,500. This is a good example of why running the code matters.
- **SQL\*Plus wrapped the A2 lines at 80 characters.** `SET LINESIZE 200` and `SET TAB OFF` fixed the output.

---

## Part 2: My reflection (my own words)

1. What GOTO does and how PL/SQL restricts it
_Guiding questions:_ What does GOTO do? What limits does PL/SQL put on where it can jump? Which illegal GOTO surprised me most, and why?

- GOTO jumps straight to a labelled statement such as <<next_employee>>, skipping the lines in between.
- Allowed: jumping within the same block, or out of an IF, a loop or a block into the code around it.
- Not allowed: jumping into an IF, a loop or a block; from THEN into ELSE; or from an exception handler back into the block that raised the error.
- A label must be followed by a statement, so <<label>> just before END gives PLS-00103. NULL; fixes it.
- Possible surprise: jumping into a loop or a block gave PLS-00201 ("identifier must be declared"), not PLS-00375. The label is hidden inside the inner scope, so the GOTO can't even see it. Whether that, or something else, surprised you most is your call.

### 2. GOTO versus structured control flow
_Guiding questions:_ Compare my A1/A2 (GOTO) with A4 (no GOTO). Which is easier to read? Which is easier to change or maintain? Which is easier to debug? Is GOTO ever acceptable?

_(write - A4 does exactly the same work as A1/A2 (identical output), but with no labels.
- Readability: A4 reads top to bottom. With GOTO you have to hunt for each label, and remember that some paths fall through into the next label, as is_positive does into check_parity.
- Maintenance: adding a category in A4 is one WHEN line. In A1 it means a new label and a new GOTO, then checking every path into it.
- Debugging: in A4 each line is reached in one way. With GOTO, a line can be reached from several jumps.
- When GOTO is acceptable: jumping forward to one exit point after many checks, as in C1.here)_

### 3. Stored functions and exception handling
_Guiding questions:_ What did I learn about writing functions (parameters, RETURN, %TYPE)? When should a function return NULL, and when should it raise an error (compare B1/B4 with B2/B3)? What does `RAISE_APPLICATION_ERROR` do?

- A function takes IN parameters and must RETURN one value.
- %TYPE ties a variable to a column's type, so it stays correct if the column changes.
- Returning NULL suits "nothing found" cases that are safe to show: B1 (unknown employee) and B4 (unknown department).
- Raising an error suits data that is actually wrong: B2 (future hire date, -20002) and B3 (negative salary, -20003).
- RAISE_APPLICATION_ERROR stops the function with your own error code (-20000 to -20999) and message.
- NO_DATA_FOUND happens when SELECT INTO finds no row, so you catch it and decide what to return.

### 4. Using functions inside SQL
_Guiding questions:_ What are the benefits of calling my own functions in SELECT, WHERE, ORDER BY and GROUP BY? What are the limitations? Consider the future-date exception breaking a query, why DML is not allowed inside SQL-callable functions, and what DETERMINISTIC means.

- Benefits: logic like tax or department name is written once and reused in SELECT, WHERE, ORDER BY and GROUP BY, which keeps queries short and consistent.
- Limitation: an error inside a function stops the whole query. In B5, one future hire date broke the query until that row was filtered out.
- No DML: a function called from a query can't INSERT, UPDATE, DELETE or COMMIT, because reading data shouldn't change it.
- DETERMINISTIC: the same input always gives the same output, so Oracle can reuse results. It's correct for the tax function. It's wrong for functions that read tables or use SYSDATE.

### 5. Challenges and how I solved them
_Guiding questions:_ What was hardest? How did I find and fix the problem?

- A3 cases 3 and 4 gave PLS-00201 instead of the expected PLS-00375. The fix was to understand label scope and update the comments.
- The A2 total: the expected total was first written as 101,500. Running the program showed 100,500, and recounting by hand confirmed it.
- Scalar subquery: a subquery can't be passed as a PL/SQL argument. The fix was to SELECT INTO a variable first.
- Wrapped output: SQL*Plus wrapped lines at 80 characters. SET LINESIZE 200 fixed it.
- Which of these felt hardest to you is your call.

### 6. How I used AI
_Guiding questions:_ What did I use AI for? What did I check and run myself? What would I do differently next time?

- What the AI did: Claude Code set up the structure, drafted the SQL and tests, set up Oracle in Docker, ran everything, and drafted the README.
- What you checked: say honestly which outputs and files you went through yourself.
- What you'd do differently: your call. One idea is to write some of the code yourself first and use AI to review it.

