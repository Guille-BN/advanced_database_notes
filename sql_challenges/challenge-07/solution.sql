-- Today's Challenge
-- Lesson 04: Setup
-- Create a simple accounts table for the transfer demo

DROP TABLE accounts PURGE;

CREATE TABLE accounts (
    account_id   NUMBER PRIMARY KEY,
    owner_name   VARCHAR2(50) NOT NULL,
    balance      NUMBER(10,2) NOT NULL CHECK (balance >= 0)
);

INSERT INTO accounts VALUES (1, 'Alice',  1000.00);
INSERT INTO accounts VALUES (2, 'Bob',     500.00);
INSERT INTO accounts VALUES (3, 'Charlie', 250.00);
COMMIT;

-- Verify starting state
SELECT account_id, owner_name, balance FROM accounts ORDER BY account_id;
-- Expected: Alice=1000, Bob=500, Charlie=250

-- Lesson 04: Class Exercises
-- Students: work through these in order. Don't skip the verify steps.

-- ============================================================
-- EXERCISE 1: Manual transaction (warm-up)
-- ============================================================
-- Transfer $50 from Charlie (3) to Alice (1) using BEGIN / COMMIT manually.
-- Before: verify balances. After COMMIT: verify again.

-- ============================================================
-- EXERCISE 1: Manual transaction (warm-up)
-- ============================================================
-- Transfer $50 from Charlie (3) to Alice (1) using BEGIN / COMMIT manually.
-- Before: verify balances. After COMMIT: verify again.

SELECT account_id,owner_name,balance 
FROM accounts 
ORDER BY account_id;

BEGIN
    UPDATE accounts
    SET balance=balance-50
    WHERE account_id=3;

    UPDATE accounts
    SET balance=balance+50
    WHERE account_id=1;
END;
/

SELECT account_id,owner_name,balance 
FROM accounts 
ORDER BY account_id;

COMMIT;

-- ============================================================
-- EXERCISE 2: Catch yourself with ROLLBACK
-- ============================================================
-- Start a transfer of $10,000 from Bob (2) to Charlie (3).
-- Before committing, check the balances. Does Bob have enough?
-- Use ROLLBACK to undo. Verify balances restored.

SELECT account_id, owner_name, balance 
FROM accounts 
ORDER BY account_id;

BEGIN
    UPDATE accounts
    SET balance=balance-10000
    WHERE account_id=2;

    UPDATE accounts
    SET balance=balance+10000
    WHERE account_id=3;
END;
/

SELECT account_id,owner_name,balance 
FROM accounts 
ORDER BY account_id;

ROLLBACK;

SELECT account_id, owner_name, balance 
FROM accounts 
ORDER BY account_id;
 

-- ============================================================
-- EXERCISE 3: SAVEPOINT checkpoint
-- ============================================================
-- You need to:
-- 1. Add $25 to Alice's balance
-- 2. Set a savepoint
-- 3. Deduct $25 from Charlie's balance (wrong account — you meant Bob)
-- 4. Rollback to savepoint
-- 5. Deduct $25 from Bob's balance instead
-- 6. Commit

SELECT account_id, owner_name, balance 
FROM accounts 
ORDER BY account_id;

BEGIN
    -- 1.
    UPDATE accounts
    SET balance=balance+25
    WHERE account_id=1;

    -- 2. 
    SAVEPOINT after_alice_update;

    -- 3.
    UPDATE accounts
    SET balance=balance-25
    WHERE account_id=3;

    -- 4. 
    ROLLBACK TO after_alice_update;

    -- 5. 
    UPDATE accounts
    SET balance=balance-25
    WHERE account_id=2;
END;
/

-- 6.
COMMIT;

SELECT account_id, owner_name, balance 
FROM accounts 
ORDER BY account_id;

-- ============================================================
-- EXERCISE 4: Write your own stored procedure
-- ============================================================
-- Create a procedure called deposit_funds(p_account_id, p_amount)
-- It should:
-- 1. Validate that p_amount > 0 (raise error if not)
-- 2. Add p_amount to the account balance
-- 3. COMMIT on success
-- 4. ROLLBACK + re-raise on any error
CREATE OR REPLACE PROCEDURE depositar (
    p_account_id IN NUMBER,
    p_amount     IN NUMBER
) IS
BEGIN
    -- 1.
    IF p_amount<=0 THEN
        RAISE_APPLICATION_ERROR(-20001,'No hay fondos.');
    END IF;

    -- 2. 
    UPDATE accounts
    SET balance=balance+p_amount
    WHERE account_id=p_account_id;

    -- 3.
    COMMIT;

EXCEPTION
    WHEN OTHERS THEN
        -- 4.
        ROLLBACK;
        RAISE;
END;
/
-- Test it with: EXEC deposit_funds(3, 75);

EXEC deposit_funds(3, 75);

 

-- ============================================================
-- EXERCISE 5: Discussion
-- ============================================================
-- Answer these in words (no SQL needed):

-- Q1: You're building a patient appointment booking system.
-- A booking requires:
--   a) Reserve the time slot
--   b) Create the appointment record
--   c) Send a confirmation notification
-- Which of these should be inside the transaction? Which should be outside? Why?
/*
Reserving the time slot and creating the appointment record should be done together, 
so either both succeed or fail together. Sending the notification should be done outside 
the transaction, given that its not a database change and can fail for other reasons unrelated 
to the data, but this should not cause the transaction to fail.
*/

-- Q2: Your stored procedure calls COMMIT at the end.
-- A developer calls your procedure from inside their own larger transaction.
-- What problem does this create?
/*
It would force a commit even if the caller is not ready yet, which breaks the larger 
transaction calling the procedure, and if something fails later, they can't call ROLLBACK.
*/

-- Q3: You have a function called calculate_copay() and a procedure called post_payment().
-- A colleague wants to use calculate_copay() inside a SELECT statement.
-- Can they? Can they do the same with post_payment()? Why or why not?
/*
calculate_copay() can be used inside a SELECT statement, because it is designed to return a value, 
not change data. post_payment() cannot be used in a SELECT, because procedures do not return a value 
in the same way and they usually make changes to the database.
*/