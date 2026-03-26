-- =========================
-- PROCEDURE: GIVE_BONUS_TO_DEPT
-- =========================
CREATE OR REPLACE PROCEDURE give_bonus_to_dept (
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
/


-- =========================
-- PROCEDURE: ADD_EMPLOYEE
-- =========================
CREATE OR REPLACE PROCEDURE add_employee (
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
        RAISE_APPLICATION_ERROR(-20001, 'Salary out of allowed range for this job');
    END IF;

    INSERT INTO employees (
        employee_id,
        first_name,
        last_name,
        email,
        phone_number,
        hire_date,
        job_id,
        department_id,
        salary,
        status
    )
    VALUES (
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
        RAISE_APPLICATION_ERROR(-20002, 'Invalid job_id or department_id');

    WHEN DUP_VAL_ON_INDEX THEN
        RAISE_APPLICATION_ERROR(-20003, 'Email already exists');

    WHEN OTHERS THEN
        RAISE_APPLICATION_ERROR(-20004, 'Unexpected error: ' || SQLERRM);
END;
/


-- =========================
-- PROCEDURE: DEACTIVATE_EMPLOYEE
-- =========================
CREATE OR REPLACE PROCEDURE deactivate_employee (
    p_employee_id IN NUMBER
)
IS
BEGIN
    UPDATE employees
    SET status = 'INACTIVE'
    WHERE employee_id = p_employee_id;

    COMMIT;
END;
/


-- =========================
-- PROCEDURE: EMP_PAYROLL_REPORT
-- =========================
CREATE OR REPLACE PROCEDURE emp_payroll_report
IS
    CURSOR c_emp IS
        SELECT
            e.first_name || ' ' || e.last_name,
            d.department_name,
            p.net_salary
        FROM employees e
        JOIN departments d ON e.department_id = d.department_id
        JOIN payroll p ON e.employee_id = p.employee_id;

    v_name   VARCHAR2(100);
    v_dept   VARCHAR2(100);
    v_salary NUMBER;
BEGIN
    OPEN c_emp;

    LOOP
        FETCH c_emp INTO v_name, v_dept, v_salary;
        EXIT WHEN c_emp%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(
            'NAME: ' || v_name ||
            ' | Dept: ' || v_dept ||
            ' | Salary: ' || v_salary
        );
    END LOOP;

    CLOSE c_emp;
END;
/


-- =========================
-- PROCEDURE: PROCESS_MONTHLY_PAYROLL
-- =========================
CREATE OR REPLACE PROCEDURE process_monthly_payroll
IS
    CURSOR c_emp IS
        SELECT employee_id, salary
        FROM employees
        WHERE status = 'ACTIVE';

    v_emp_id employees.employee_id%TYPE;
    v_salary employees.salary%TYPE;
BEGIN
    OPEN c_emp;

    LOOP
        FETCH c_emp INTO v_emp_id, v_salary;
        EXIT WHEN c_emp%NOTFOUND;

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
            v_emp_id,
            SYSDATE,
            v_salary,
            0,
            0
        );
    END LOOP;

    CLOSE c_emp;

    COMMIT;
END;
/


-- =========================
-- FUNCTION: GET_TOTAL_SALARY
-- =========================
CREATE OR REPLACE FUNCTION get_total_salary (
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

    RETURN v_total;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END;
/


-- =========================
-- FUNCTION: GET_ANNUAL_SALARY
-- =========================
CREATE OR REPLACE FUNCTION get_annual_salary (
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

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END;
/