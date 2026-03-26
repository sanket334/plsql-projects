-- =========================
-- PACKAGE: BANKING_PKG
-- =========================
CREATE OR REPLACE PACKAGE banking_pkg
IS
    -- Procedures
    PROCEDURE deposit_money (
        p_account_id IN NUMBER,
        p_amount     IN NUMBER
    );

    PROCEDURE withdraw_money (
        p_account_id IN NUMBER,
        p_amount     IN NUMBER
    );

    PROCEDURE transfer_money (
        p_from_account IN NUMBER,
        p_to_account   IN NUMBER,
        p_amount       IN NUMBER
    );

    PROCEDURE account_summary_report;

    -- Functions
    FUNCTION get_account_balance (
        p_account_id IN NUMBER
    ) RETURN NUMBER;

    FUNCTION get_total_transactions (
        p_account_id IN NUMBER
    ) RETURN NUMBER;

END banking_pkg;
/


-- =========================
-- PACKAGE BODY: BANKING_PKG
-- =========================
CREATE OR REPLACE PACKAGE BODY banking_pkg
IS

-- ======================
-- DEPOSIT
-- ======================
PROCEDURE deposit_money (
    p_account_id IN NUMBER,
    p_amount     IN NUMBER
)
IS
BEGIN
    UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_id = p_account_id;

    INSERT INTO transactions
    VALUES (seq_transactions.NEXTVAL, p_account_id, 'DEPOSIT', p_amount, SYSDATE);

    COMMIT;
END;


-- ======================
-- WITHDRAW
-- ======================
PROCEDURE withdraw_money (
    p_account_id IN NUMBER,
    p_amount     IN NUMBER
)
IS
    v_balance NUMBER;
BEGIN
    SELECT balance INTO v_balance
    FROM accounts
    WHERE account_id = p_account_id;

    IF v_balance < p_amount THEN
        RAISE_APPLICATION_ERROR(-20010, 'Insufficient balance');
    END IF;

    UPDATE accounts
    SET balance = balance - p_amount
    WHERE account_id = p_account_id;

    INSERT INTO transactions
    VALUES (seq_transactions.NEXTVAL, p_account_id, 'WITHDRAW', p_amount, SYSDATE);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;


-- ======================
-- TRANSFER
-- ======================
PROCEDURE transfer_money (
    p_from_account IN NUMBER,
    p_to_account   IN NUMBER,
    p_amount       IN NUMBER
)
IS
    v_balance NUMBER;
BEGIN
    SELECT balance INTO v_balance
    FROM accounts
    WHERE account_id = p_from_account;

    IF v_balance < p_amount THEN
        RAISE_APPLICATION_ERROR(-20020, 'Insufficient balance');
    END IF;

    UPDATE accounts
    SET balance = balance - p_amount
    WHERE account_id = p_from_account;

    UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_id = p_to_account;

    INSERT INTO transactions
    VALUES (seq_transactions.NEXTVAL, p_from_account, 'WITHDRAW', p_amount, SYSDATE);

    INSERT INTO transactions
    VALUES (seq_transactions.NEXTVAL, p_to_account, 'DEPOSIT', p_amount, SYSDATE);

    INSERT INTO transfers
    VALUES (seq_transfers.NEXTVAL, p_from_account, p_to_account, p_amount, SYSDATE);

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;


-- ======================
-- REPORT
-- ======================
PROCEDURE account_summary_report
IS
BEGIN
    FOR rec IN (
        SELECT a.account_id, c.name, a.account_type, a.balance
        FROM accounts a
        JOIN customers c ON a.customer_id = c.customer_id
    )
    LOOP
        DBMS_OUTPUT.PUT_LINE(
            rec.account_id || ' | ' ||
            rec.name || ' | ' ||
            rec.account_type || ' | ' ||
            rec.balance
        );
    END LOOP;
END;


-- ======================
-- FUNCTION: BALANCE
-- ======================
FUNCTION get_account_balance (
    p_account_id IN NUMBER
)
RETURN NUMBER
IS
    v_balance NUMBER;
BEGIN
    SELECT balance INTO v_balance
    FROM accounts
    WHERE account_id = p_account_id;

    RETURN v_balance;
END;


-- ======================
-- FUNCTION: TOTAL TRANSACTIONS
-- ======================
FUNCTION get_total_transactions (
    p_account_id IN NUMBER
)
RETURN NUMBER
IS
    v_total NUMBER;
BEGIN
    SELECT SUM(amount)
    INTO v_total
    FROM transactions
    WHERE account_id = p_account_id;

    RETURN NVL(v_total, 0);
END;

END banking_pkg;
/