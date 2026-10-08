/*
================================================================================
 File        : 02_functions/B4_fn_dept_name.sql
 Task        : B4 - Function: department name
 Author      : Keza Christa Clea (Student ID 29570)
 Course      : INSY 8311 - Database Development with PL/SQL (AUCA)
 Purpose     : fn_dept_name(p_dept_id) returns the department name for an ID.
 Dependencies: Table DEPARTMENTS (run 00_setup/create_tables.sql first).
 How to run  : @02_functions/B4_fn_dept_name.sql
 Expected    : "Function created." and "No errors."

 Parameters  : p_dept_id IN departments.dept_id%TYPE
 Returns     : VARCHAR2 - the department name
 Behaviour   : p_dept_id NULL    -> 'No Department'
               ID not found      -> 'Unknown Department'
               No exception escapes for these cases.
 Error codes : none raised.
 Design note : Not DETERMINISTIC because it reads a table whose data can change.
================================================================================
*/
SET SERVEROUTPUT ON SIZE UNLIMITED

CREATE OR REPLACE FUNCTION fn_dept_name (
    p_dept_id IN departments.dept_id%TYPE
) RETURN VARCHAR2
IS
    c_no_department      CONSTANT VARCHAR2(30) := 'No Department';
    c_unknown_department CONSTANT VARCHAR2(30) := 'Unknown Department';
    v_dept_name          departments.dept_name%TYPE;
BEGIN
    IF p_dept_id IS NULL THEN
        RETURN c_no_department;
    END IF;

    SELECT dept_name
      INTO v_dept_name
      FROM departments
     WHERE dept_id = p_dept_id;

    RETURN v_dept_name;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN c_unknown_department;
END fn_dept_name;
/
SHOW ERRORS FUNCTION fn_dept_name
