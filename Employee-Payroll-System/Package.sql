-- =========================
-- PACKAGE: PAYROLL_PKG
-- =========================
CREATE OR REPLACE PACKAGE payroll_pkg
IS
    -- Procedures
    PROCEDURE add_employee (
        p_first_name    IN VARCHAR2,
        p_last_name     IN VARCHAR2,
        p_email         IN VARCHAR2,
        p_phone         IN VARCHAR2,
        p_job_id        IN NUMBER,
        p_department_id IN NUMBER,
        p_salary        IN NUMBER
    );

    PROCEDURE process_monthly_payroll;

    PROCEDURE give_bonus_to_dept (
        p_department_id IN NUMBER,
        p_bonus         IN NUMBER
    );

    PROCEDURE deactivate_employee (
        p_employee_id IN NUMBER
    );

    -- Functions
    FUNCTION get_total_salary (
        p_employee_id IN NUMBER
    ) RETURN NUMBER;

    FUNCTION get_annual_salary (
        p_employee_id IN NUMBER
    ) RETURN NUMBER;

END payroll_pkg;
/


-- =========================
-- PACKAGE BODY: PAYROLL_PKG
-- =========================
CREATE OR REPLACE PACKAGE BODY payroll_pkg
IS

-- =========================
-- ADD EMPLOYEE
-- =========================
PROCEDURE add_employee (
    p_first_name    IN VARCHAR2,
    p_last_name     IN VARCHAR2,
    p_email         IN VARCHAR2,
    p_phone         IN VARCHAR2,
    p_job_id        IN NUMBER,
    p_department_id IN NUMBER,
    p_salary        IN NUMBER
)
IS
    v_min_salary jobs.min_salary%TYPE;
    v_max_salary jobs.max_salary%TYPE;
    v_dummy      NUMBER;
BEGIN
    SELECT min_salary, max_salary
    INTO v_min_salary, v_max_salary
    FROM jobs
    WHERE job_id = p_job_id;

    SELECT 1 INTO v_dummy
    FROM departments
    WHERE department_id = p_department_id;

    IF p_salary < v_min_salary OR p_salary > v_max_salary THEN
        RAISE_APPLICATION_ERROR(-20001, 'Salary out of allowed range');
    END IF;

    INSERT INTO employees VALUES (
        seq_employees.NEXTVAL,
        p_first_name,
        p_last_name,
        p_email,
        p_phone,
        SYSDATE,
        p_job_id,
        p_department_id,
        p_salary,
        'ACTIVE'
    );

    COMMIT;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20002, 'Invalid job or department');

    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20003, 'Email already exists');
END;


-- =========================
-- PROCESS PAYROLL
-- =========================
PROCEDURE process_monthly_payroll
IS
BEGIN
    FOR rec IN (
        SELECT employee_id, salary
        FROM employees
        WHERE status = 'ACTIVE'
    )
    LOOP
        INSERT INTO payroll (
            payroll_id,
            employee_id,
            pay_date,
            basic_salary,
            bonus,
            deductions
        )
        VALUES (
            seq_payroll.NEXTVAL,
            rec.employee_id,
            SYSDATE,
            rec.salary,
            0,
            0
        );
    END LOOP;

    COMMIT;
END;


-- =========================
-- GIVE BONUS
-- =========================
PROCEDURE give_bonus_to_dept (
    p_department_id IN NUMBER,
    p_bonus         IN NUMBER
)
IS
BEGIN
    UPDATE payroll
    SET bonus = NVL(bonus, 0) + p_bonus
    WHERE employee_id IN (
        SELECT employee_id
        FROM employees
        WHERE department_id = p_department_id
    );

    COMMIT;
END;


-- =========================
-- DEACTIVATE EMPLOYEE
-- =========================
PROCEDURE deactivate_employee (
    p_employee_id IN NUMBER
)
IS
BEGIN
    UPDATE employees
    SET status = 'INACTIVE'
    WHERE employee_id = p_employee_id;

    COMMIT;
END;


-- =========================
-- FUNCTION TOTAL SALARY
-- =========================
FUNCTION get_total_salary (
    p_employee_id IN NUMBER
)
RETURN NUMBER
IS
    v_total NUMBER;
BEGIN
    SELECT SUM(net_salary)
    INTO v_total
    FROM payroll
    WHERE employee_id = p_employee_id;

    RETURN NVL(v_total, 0);
END;


-- =========================
-- FUNCTION ANNUAL SALARY
-- =========================
FUNCTION get_annual_salary (
    p_employee_id IN NUMBER
)
RETURN NUMBER
IS
    v_salary NUMBER;
BEGIN
    SELECT salary
    INTO v_salary
    FROM employees
    WHERE employee_id = p_employee_id;

    RETURN v_salary * 12;
END;

END payroll_pkg;
/