-- =========================
-- PROCEDURE: ACCOUNT SUMMARY REPORT
-- =========================
CREATE OR REPLACE PROCEDURE account_summary_report
IS
    CURSOR c_accounts IS
        SELECT 
            a.account_id,
            c.name,
            a.account_type,
            a.balance
        FROM accounts a
        JOIN customers c ON a.customer_id = c.customer_id;

    v_acc_id   accounts.account_id%TYPE;
    v_name     customers.name%TYPE;
    v_type     accounts.account_type%TYPE;
    v_balance  accounts.balance%TYPE;
BEGIN
    OPEN c_accounts;

    LOOP
        FETCH c_accounts INTO v_acc_id, v_name, v_type, v_balance;
        EXIT WHEN c_accounts%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE(
            'Account: ' || v_acc_id ||
            ' | Name: ' || v_name ||
            ' | Type: ' || v_type ||
            ' | Balance: ' || v_balance
        );
    END LOOP;

    CLOSE c_accounts;
END;
/


-- =========================
-- PROCEDURE: DEPOSIT MONEY
-- =========================
CREATE OR REPLACE PROCEDURE deposit_money (
    p_account_id IN NUMBER,
    p_amount     IN NUMBER
)
IS
BEGIN
    UPDATE accounts
    SET balance = balance + p_amount
    WHERE account_id = p_account_id;

    INSERT INTO transactions (
        transaction_id,
        account_id,
        transaction_type,
        amount,
        transaction_date
    )
    VALUES (
        seq_transactions.NEXTVAL,
        p_account_id,
        'DEPOSIT',
        p_amount,
        SYSDATE
    );

    COMMIT;
END;
/


-- =========================
-- PROCEDURE: WITHDRAW MONEY
-- =========================
CREATE OR REPLACE PROCEDURE withdraw_money (
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

    INSERT INTO transactions (
        transaction_id,
        account_id,
        transaction_type,
        amount,
        transaction_date
    )
    VALUES (
        seq_transactions.NEXTVAL,
        p_account_id,
        'WITHDRAW',
        p_amount,
        SYSDATE
    );

    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END;
/


-- =========================
-- PROCEDURE: TRANSFER MONEY
-- =========================
CREATE OR REPLACE PROCEDURE transfer_money (
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
        RAISE_APPLICATION_ERROR(-20020, 'Insufficient balance for transfer');
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
/


-- =========================
-- FUNCTION: GET ACCOUNT BALANCE
-- =========================
CREATE OR REPLACE FUNCTION get_account_balance (
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

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;
END;
/


-- =========================
-- FUNCTION: GET TOTAL TRANSACTIONS
-- =========================
CREATE OR REPLACE FUNCTION get_total_transactions (
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
/