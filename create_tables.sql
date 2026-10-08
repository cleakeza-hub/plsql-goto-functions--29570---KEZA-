/*
================================================================================
 File        : 00_setup/create_tables.sql
 Task        : SETUP - Tables and sample data
 Author      : Keza Christa Clea (Student ID 29570)
 Course      : INSY 8311 - Database Development with PL/SQL (AUCA)
 Purpose     : Creates DEPARTMENTS, EMPLOYEES and PAYROLL and loads sample
               data with deliberate edge cases (bracket boundaries, NULL
               salary, NULL department, hired today, future hire date, and
               payroll rows that are invalid for one specific reason each).
 Dependencies: None. This is the first script to run.
 How to run  : SQL*Plus / SQLcl : @00_setup/create_tables.sql
               SQL Developer    : open the file and press F5 (Run Script)
 Expected    : Three tables created, then a row count summary:
                 DEPARTMENTS 5, EMPLOYEES 15, PAYROLL 17
 Re-runnable : Yes. Existing tables are dropped first; the "table does not
               exist" error (ORA-00942) is ignored on the first run.
================================================================================
*/
SET SERVEROUTPUT ON SIZE UNLIMITED

-- -----------------------------------------------------------------------------
-- 1. Drop old tables. Child tables first (payroll, employees) so the foreign
--    key from employees to departments never blocks a drop.
--    ORA-00942 = table does not exist, ORA-02289 = sequence does not exist.
--    Both just mean "nothing to drop", so they are ignored. Any other error
--    is re-raised so a real problem is not hidden.
-- -----------------------------------------------------------------------------
DECLARE
    TYPE t_names IS TABLE OF VARCHAR2(30);
    v_tables t_names := t_names('PAYROLL', 'EMPLOYEES', 'DEPARTMENTS');
BEGIN
    FOR i IN 1 .. v_tables.COUNT LOOP
        BEGIN
            EXECUTE IMMEDIATE 'DROP TABLE ' || v_tables(i) || ' PURGE';
            DBMS_OUTPUT.PUT_LINE('Dropped table ' || v_tables(i));
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE NOT IN (-942, -2289) THEN
                    RAISE;
                END IF;
        END;
    END LOOP;
END;
/

-- -----------------------------------------------------------------------------
-- 2. Tables
-- -----------------------------------------------------------------------------
CREATE TABLE departments (
    dept_id    NUMBER        CONSTRAINT pk_departments PRIMARY KEY,
    dept_name  VARCHAR2(50)  CONSTRAINT nn_dept_name NOT NULL
                             CONSTRAINT uq_dept_name UNIQUE,
    location   VARCHAR2(50)
);

CREATE TABLE employees (
    emp_id      NUMBER        CONSTRAINT pk_employees PRIMARY KEY,
    first_name  VARCHAR2(50)  NOT NULL,
    last_name   VARCHAR2(50)  NOT NULL,
    email       VARCHAR2(100) CONSTRAINT uq_emp_email UNIQUE,
    job_title   VARCHAR2(60),
    salary      NUMBER(12,2),          -- monthly salary in RWF; NULLABLE ON PURPOSE
    hire_date   DATE,
    dept_id     NUMBER                 -- NULLABLE ON PURPOSE (employee without a department)
                CONSTRAINT fk_emp_dept REFERENCES departments (dept_id)
);

-- PAYROLL.EMP_ID deliberately has NO foreign key. Without it we can store a
-- payroll row for an employee that does not exist (an "orphan" row), which is
-- exactly what fn_validate_payroll (task C1) must be able to detect.
CREATE TABLE payroll (
    payroll_id  NUMBER        CONSTRAINT pk_payroll PRIMARY KEY,
    emp_id      NUMBER,                -- no FK on purpose (see comment above)
    pay_period  VARCHAR2(7),           -- expected format YYYY-MM, e.g. 2026-09
    gross_pay   NUMBER(12,2),
    tax_amount  NUMBER(12,2),
    net_pay     NUMBER(12,2)
);

-- -----------------------------------------------------------------------------
-- 3. Departments
-- -----------------------------------------------------------------------------
INSERT INTO departments VALUES (10, 'Finance',                'Kigali');
INSERT INTO departments VALUES (20, 'Human Resources',        'Kigali');
INSERT INTO departments VALUES (30, 'Information Technology', 'Kigali');
INSERT INTO departments VALUES (40, 'Operations',             'Musanze');
INSERT INTO departments VALUES (50, 'Marketing',              'Huye');

-- -----------------------------------------------------------------------------
-- 4. Employees (salary = monthly, RWF)
--    Tax column in the comments = expected fn_calculate_tax(salary).
-- -----------------------------------------------------------------------------
-- High salary, long-serving (10+ years). Tax 99,000. A2: > 300,000 -> review only.
INSERT INTO employees VALUES (101, 'Jean',      'Mugisha',      'jean.mugisha@company.rw',      'Finance Manager',        450000, DATE '2012-03-15', 10);
-- Exactly on the 200,000 tax boundary. Tax 24,000. 10+ years.
INSERT INTO employees VALUES (102, 'Aline',     'Uwase',        'aline.uwase@company.rw',       'Accountant',             200000, DATE '2015-07-01', 10);
-- Exactly on the 100,000 tax AND salary-review boundary. Tax 4,000. A2: 5%.
INSERT INTO employees VALUES (103, 'Eric',      'Niyonzima',    'eric.niyonzima@company.rw',    'HR Officer',             100000, DATE '2019-01-10', 20);
-- Exactly on the 60,000 tax boundary (still 0% tax). A2: 10%.
INSERT INTO employees VALUES (104, 'Claudine',  'Mukamana',     'claudine.mukamana@company.rw', 'Recruiter',               60000, DATE '2021-06-01', 20);
-- High salary. Tax 69,000. A2: > 300,000 -> review only.
INSERT INTO employees VALUES (105, 'Patrick',   'Habimana',     'patrick.habimana@company.rw',  'Software Engineer',      350000, DATE '2016-09-20', 30);
-- Worked example salary. Tax 39,000.
INSERT INTO employees VALUES (106, 'Diane',     'Ingabire',     'diane.ingabire@company.rw',    'Systems Analyst',        250000, DATE '2020-02-03', 30);
-- Low-middle salary, short service. Tax 2,500.
INSERT INTO employees VALUES (107, 'Olivier',   'Nshimiyimana', 'olivier.nshimiyimana@company.rw', 'IT Support Technician', 85000, DATE '2023-11-13', 30);
-- Middle salary, 10+ years. Tax 14,000.
INSERT INTO employees VALUES (108, 'Grace',     'Uwimana',      'grace.uwimana@company.rw',     'Operations Officer',     150000, DATE '2014-04-07', 40);
-- Low salary (below 60,000, no tax), longest serving.
INSERT INTO employees VALUES (109, 'Samuel',    'Hakizimana',   'samuel.hakizimana@company.rw', 'Driver',                  45000, DATE '2010-08-30', 40);
-- Middle salary. Tax 8,000.
INSERT INTO employees VALUES (110, 'Josiane',   'Umutoni',      'josiane.umutoni@company.rw',   'Marketing Officer',      120000, DATE '2018-05-14', 50);
-- NULL SALARY edge case (salary not yet set). A2 must skip this employee.
INSERT INTO employees VALUES (111, 'Emmanuel',  'Twagirayezu',  'emmanuel.twagirayezu@company.rw', 'Intern',                NULL, DATE '2026-07-01', 50);
-- NULL DEPT_ID edge case. fn_dept_name returns 'No Department'. Tax 20,000.
INSERT INTO employees VALUES (112, 'Divine',    'Iradukunda',   'divine.iradukunda@company.rw', 'Consultant',             180000, DATE '2022-01-17', NULL);
-- HIRED TODAY edge case: 0 completed years of service. Tax 3,500.
INSERT INTO employees VALUES (113, 'Kevin',     'Manzi',        'kevin.manzi@company.rw',       'Junior Developer',        95000, TRUNC(SYSDATE), 30);
-- FUTURE HIRE DATE edge case (data-entry error): fn_years_of_service raises -20002.
INSERT INTO employees VALUES (114, 'Sandrine',  'Mutoni',       'sandrine.mutoni@company.rw',   'Sales Associate',         70000, TRUNC(SYSDATE) + 30, 50);
-- Exactly on the 300,000 salary-review boundary (still 5%). Tax 54,000. 15+ years.
INSERT INTO employees VALUES (115, 'Theogene',  'Bizimana',     'theogene.bizimana@company.rw', 'Senior Auditor',         300000, DATE '2008-02-11', 10);

-- -----------------------------------------------------------------------------
-- 5. Payroll for period 2026-09
--    Tax rules (progressive): 0-60,000 0%; 60,000-100,000 10%;
--    100,000-200,000 20%; above 200,000 30%. Net = gross - tax.
--    Each invalid row breaks exactly ONE rule, and the comment names the
--    check in fn_validate_payroll that catches it first.
-- -----------------------------------------------------------------------------
-- VALID: 450,000 -> tax 0 + 4,000 + 20,000 + 75,000 = 99,000; net 351,000
INSERT INTO payroll VALUES (1,  101, '2026-09', 450000,  99000, 351000);
-- VALID: boundary 200,000 -> tax 24,000; net 176,000
INSERT INTO payroll VALUES (2,  102, '2026-09', 200000,  24000, 176000);
-- VALID: boundary 100,000 -> tax 4,000; net 96,000
INSERT INTO payroll VALUES (3,  103, '2026-09', 100000,   4000,  96000);
-- VALID: boundary 60,000 -> tax 0; net 60,000
INSERT INTO payroll VALUES (4,  104, '2026-09',  60000,      0,  60000);
-- VALID: 150,000 -> tax 14,000; net 136,000
INSERT INTO payroll VALUES (5,  108, '2026-09', 150000,  14000, 136000);
-- INVALID (check 2): employee 999 does not exist (orphan row, possible because there is no FK)
INSERT INTO payroll VALUES (6,  999, '2026-09', 100000,   4000,  96000);
-- INVALID (check 3): employee 112 has no department
INSERT INTO payroll VALUES (7,  112, '2026-09', 180000,  20000, 160000);
-- INVALID (check 4): employee 114 has a hire date in the future
INSERT INTO payroll VALUES (8,  114, '2026-09',  70000,   1000,  69000);
-- INVALID (check 5): gross pay is NULL
INSERT INTO payroll VALUES (9,  105, '2026-09',   NULL,   NULL,   NULL);
-- INVALID (check 5): gross pay is zero
INSERT INTO payroll VALUES (10, 106, '2026-09',      0,      0,      0);
-- INVALID (check 5): gross pay is negative
INSERT INTO payroll VALUES (11, 107, '2026-09', -85000,      0, -85000);
-- INVALID (check 6): wrong period format (slash instead of dash)
INSERT INTO payroll VALUES (12, 109, '2026/09',  45000,      0,  45000);
-- INVALID (check 6): impossible month 13
INSERT INTO payroll VALUES (13, 110, '2026-13', 120000,   8000, 112000);
-- INVALID (check 7): wrong tax, a flat 10% (25,000) instead of the progressive 39,000
INSERT INTO payroll VALUES (14, 106, '2026-08', 250000,  25000, 225000);
-- INVALID (check 8): tax is right (54,000) but net should be 246,000, not 250,000
INSERT INTO payroll VALUES (15, 115, '2026-09', 300000,  54000, 250000);
-- INVALID (check 7): impossible negative tax (net is larger than gross)
INSERT INTO payroll VALUES (16, 113, '2026-09',  95000,  -3500,  98500);
-- VALID: employee hired today is allowed (hire date is not in the future); tax 3,500
INSERT INTO payroll VALUES (17, 113, '2026-10',  95000,   3500,  91500);

COMMIT;

-- -----------------------------------------------------------------------------
-- 6. Summary
-- -----------------------------------------------------------------------------
PROMPT
PROMPT Row counts per table:
SELECT 'DEPARTMENTS' AS table_name, COUNT(*) AS row_count FROM departments
UNION ALL
SELECT 'EMPLOYEES',                 COUNT(*)              FROM employees
UNION ALL
SELECT 'PAYROLL',                   COUNT(*)              FROM payroll;
