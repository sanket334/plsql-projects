-- =========================
-- CUSTOMERS
-- =========================
CREATE TABLE customers (
    customer_id NUMBER PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    email VARCHAR2(100) UNIQUE,
    phone VARCHAR2(20)
);


-- =========================
-- ACCOUNTS
-- =========================
CREATE TABLE accounts (
    account_id NUMBER PRIMARY KEY,
    customer_id NUMBER NOT NULL,
    account_type VARCHAR2(20),
    balance NUMBER DEFAULT 0,
    status VARCHAR2(10) DEFAULT 'ACTIVE',
    CONSTRAINT chk_acc_type CHECK (account_type IN ('SAVINGS', 'CURRENT')),
    CONSTRAINT chk_acc_status CHECK (status IN ('ACTIVE', 'CLOSED')),
    CONSTRAINT fk_acc_customer FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
);


-- =========================
-- TRANSACTIONS
-- =========================
CREATE TABLE transactions (
    transaction_id NUMBER PRIMARY KEY,
    account_id NUMBER NOT NULL,
    transaction_type VARCHAR2(20),
    amount NUMBER NOT NULL,
    transaction_date DATE DEFAULT SYSDATE,
    CONSTRAINT chk_trans_type CHECK (transaction_type IN ('DEPOSIT', 'WITHDRAW')),
    CONSTRAINT fk_trans_account FOREIGN KEY (account_id)
        REFERENCES accounts(account_id)
);


-- =========================
-- TRANSFERS
-- =========================
CREATE TABLE transfers (
    transfer_id NUMBER PRIMARY KEY,
    from_account NUMBER,
    to_account NUMBER,
    amount NUMBER,
    transfer_date DATE DEFAULT SYSDATE,
    CONSTRAINT fk_from_acc FOREIGN KEY (from_account)
        REFERENCES accounts(account_id),
    CONSTRAINT fk_to_acc FOREIGN KEY (to_account)
        REFERENCES accounts(account_id)
);