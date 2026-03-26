-- =========================
-- DEPARTMENTS
-- =========================
CREATE TABLE departments (
   department_id NUMBER PRIMARY KEY,
   department_name VARCHAR2(100) NOT NULL,
   location VARCHAR2(100)
);


-- =========================
-- JOBS
-- =========================
CREATE TABLE jobs (
   job_id NUMBER PRIMARY KEY,
   job_title VARCHAR2(100) NOT NULL,
   min_salary NUMBER,
   max_salary NUMBER,
   CONSTRAINT chk_salary_range CHECK (min_salary <= max_salary)
);


-- =========================
-- EMPLOYEES
-- =========================
CREATE TABLE employees (
   employee_id NUMBER PRIMARY KEY,
   first_name VARCHAR2(50),
   last_name VARCHAR2(50) NOT NULL,
   email VARCHAR2(100) UNIQUE,
   phone_number VARCHAR2(20),
   hire_date DATE DEFAULT SYSDATE,
   job_id NUMBER,
   department_id NUMBER,
   salary NUMBER,
   status VARCHAR2(10) DEFAULT 'ACTIVE',
   CONSTRAINT chk_status CHECK (status IN ('ACTIVE', 'INACTIVE')),
   CONSTRAINT fk_emp_job FOREIGN KEY (job_id) REFERENCES jobs(job_id),
   CONSTRAINT fk_emp_dept FOREIGN KEY (department_id) REFERENCES departments(department_id)
);


-- =========================
-- ATTENDANCE
-- =========================
CREATE TABLE attendance (
   attendance_id NUMBER PRIMARY KEY,
   employee_id NUMBER,
   attendance_date DATE,
   status VARCHAR2(10),
   CONSTRAINT chk_att_status CHECK (status IN ('PRESENT', 'ABSENT', 'LEAVE')),
   CONSTRAINT fk_att_emp FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);


-- =========================
-- LEAVES
-- =========================
CREATE TABLE leaves (
   leave_id NUMBER PRIMARY KEY,
   employee_id NUMBER,
   leave_type VARCHAR2(50),
   start_date DATE,
   end_date DATE,
   status VARCHAR2(20),
   CONSTRAINT chk_leave_status CHECK (status IN ('PENDING', 'APPROVED', 'REJECTED')),
   CONSTRAINT fk_leave_emp FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);


-- =========================
-- PAYROLL
-- =========================
CREATE TABLE payroll (
   payroll_id NUMBER PRIMARY KEY,
   employee_id NUMBER NOT NULL,
   pay_date DATE DEFAULT SYSDATE,
   basic_salary NUMBER NOT NULL,
   bonus NUMBER DEFAULT 0,
   deductions NUMBER DEFAULT 0,
   net_salary NUMBER,
   CONSTRAINT fk_pay_emp FOREIGN KEY (employee_id) REFERENCES employees(employee_id)
);