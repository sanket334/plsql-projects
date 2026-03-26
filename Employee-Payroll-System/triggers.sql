-- =========================
-- TRIGGER: CALCULATE NET SALARY
-- =========================
CREATE OR REPLACE TRIGGER trg_calculate_net_salary
BEFORE INSERT OR UPDATE ON payroll
FOR EACH ROW
BEGIN
    :NEW.net_salary := :NEW.basic_salary
                       + NVL(:NEW.bonus, 0)
                       - NVL(:NEW.deductions, 0);
END;
/


-- =========================
-- TRIGGER: VALIDATE PAYROLL
-- =========================
CREATE OR REPLACE TRIGGER trg_validate_payroll
BEFORE INSERT OR UPDATE ON payroll
FOR EACH ROW
BEGIN
    IF :NEW.basic_salary < 0 THEN
        RAISE_APPLICATION_ERROR(-20010, 'Basic salary cannot be negative');
    END IF;

    IF :NEW.bonus < 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'Bonus cannot be negative');
    END IF;

    IF :NEW.deductions < 0 THEN
        RAISE_APPLICATION_ERROR(-20012, 'Deductions cannot be negative');
    END IF;
END;
/