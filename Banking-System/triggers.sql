-- =========================
-- TRIGGER: NO NEGATIVE BALANCE
-- =========================
CREATE OR REPLACE TRIGGER trg_no_negative_balance
BEFORE INSERT OR UPDATE ON accounts
FOR EACH ROW
BEGIN
    IF :NEW.balance < 0 THEN
        RAISE_APPLICATION_ERROR(-20030, 'Balance cannot be negative');
    END IF;
END;
/


-- =========================
-- TRIGGER: VALIDATE TRANSACTION
-- =========================
CREATE OR REPLACE TRIGGER trg_validate_transaction
BEFORE INSERT ON transactions
FOR EACH ROW
BEGIN
    IF :NEW.amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20031, 'Transaction amount must be positive');
    END IF;
END;
/