-- ============================================================
-- Lesson 08: Exercise — Assignment History
-- ============================================================

/*A support ticketing system. Tickets get reassigned between agents.
You need to track who was assigned when the ticket was created
vs when it was resolved.*/


-- ============================================================
-- CLEAN UP (optional if re-running)
-- ============================================================

BEGIN EXECUTE IMMEDIATE 'DROP TABLE ticket_assignments'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE tickets'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dim_agent'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE fact_ticket_daily'; EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TRIGGER trg_ticket_assignment_log'; EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- ============================================================
-- Step 1 — Source Tables (OLTP)
-- ============================================================

CREATE TABLE tickets (
    ticket_id     NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title         VARCHAR2(200) NOT NULL,
    status        VARCHAR2(30) NOT NULL,
    priority      VARCHAR2(20) NOT NULL,
    created_at    TIMESTAMP DEFAULT SYSTIMESTAMP,
    resolved_at   TIMESTAMP,
    assigned_to   VARCHAR2(100)
);

CREATE TABLE ticket_assignments (
    assignment_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    ticket_id     NUMBER NOT NULL REFERENCES tickets(ticket_id),
    assigned_to   VARCHAR2(100) NOT NULL,
    assigned_by   VARCHAR2(100),
    valid_from    TIMESTAMP NOT NULL,
    valid_to      TIMESTAMP
);

CREATE INDEX idx_ticket_assignment_lookup
ON ticket_assignments (ticket_id, valid_from, valid_to);


-- ============================================================
-- Step 2 — Sample Data
-- ============================================================

INSERT INTO tickets (
    title,
    status,
    priority,
    created_at,
    resolved_at,
    assigned_to
) VALUES (
    'Login page broken',
    'resolved',
    'high',
    TO_TIMESTAMP('2026-06-01 08:00:00', 'YYYY-MM-DD HH24:MI:SS'),
    TO_TIMESTAMP('2026-06-02 10:00:00', 'YYYY-MM-DD HH24:MI:SS'),
    'Alice'
);

INSERT INTO tickets (
    title,
    status,
    priority,
    created_at,
    resolved_at,
    assigned_to
) VALUES (
    'Database timeout',
    'in_progress',
    'critical',
    TO_TIMESTAMP('2026-06-01 09:30:00', 'YYYY-MM-DD HH24:MI:SS'),
    NULL,
    'Bob'
);

INSERT INTO tickets (
    title,
    status,
    priority,
    created_at,
    resolved_at,
    assigned_to
) VALUES (
    'Email notifications failing',
    'resolved',
    'medium',
    TO_TIMESTAMP('2026-06-02 11:00:00', 'YYYY-MM-DD HH24:MI:SS'),
    TO_TIMESTAMP('2026-06-03 14:00:00', 'YYYY-MM-DD HH24:MI:SS'),
    'Charlie'
);

INSERT INTO tickets (
    title,
    status,
    priority,
    created_at,
    resolved_at,
    assigned_to
) VALUES (
    'UI alignment issue',
    'open',
    'low',
    TO_TIMESTAMP('2026-06-03 15:00:00', 'YYYY-MM-DD HH24:MI:SS'),
    NULL,
    'Diana'
);

INSERT INTO tickets (
    title,
    status,
    priority,
    created_at,
    resolved_at,
    assigned_to
) VALUES (
    'API authentication bug',
    'resolved',
    'critical',
    TO_TIMESTAMP('2026-06-04 08:45:00', 'YYYY-MM-DD HH24:MI:SS'),
    TO_TIMESTAMP('2026-06-05 16:30:00', 'YYYY-MM-DD HH24:MI:SS'),
    'Alice'
);


-- ============================================================
-- Step 3 — Trigger
-- ============================================================

CREATE OR REPLACE TRIGGER trg_ticket_assignment_log
AFTER INSERT OR UPDATE OF assigned_to ON tickets
FOR EACH ROW
BEGIN

    IF INSERTING THEN

        INSERT INTO ticket_assignments (
            ticket_id,
            assigned_to,
            assigned_by,
            valid_from
        )
        VALUES (
            :NEW.ticket_id,
            :NEW.assigned_to,
            'system',
            :NEW.created_at
        );

    ELSIF UPDATING THEN

        -- Close previous assignment
        UPDATE ticket_assignments
           SET valid_to = SYSTIMESTAMP
         WHERE ticket_id = :OLD.ticket_id
           AND valid_to IS NULL;

        -- Insert new assignment
        INSERT INTO ticket_assignments (
            ticket_id,
            assigned_to,
            assigned_by,
            valid_from,
            valid_to
        )
        VALUES (
            :NEW.ticket_id,
            :NEW.assigned_to,
            'manager',
            SYSTIMESTAMP,
            NULL
        );

    END IF;

END;
/

-- ============================================================
-- TEST THE TRIGGER
-- ============================================================

-- Reassign ticket 1 from Alice to Bob
UPDATE tickets
SET assigned_to = 'Bob'
WHERE ticket_id = 1;

-- Verify assignment history
SELECT *
FROM ticket_assignments
ORDER BY ticket_id, valid_from;


-- ============================================================
-- Step 4 — Data Warehouse Tables (Star Schema)
-- ============================================================

CREATE TABLE dim_agent (
    agent_key   NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    agent_name  VARCHAR2(100) NOT NULL,
    team        VARCHAR2(100) NOT NULL
);

CREATE TABLE fact_ticket_daily (
    date_key          DATE,
    agent_key         NUMBER REFERENCES dim_agent(agent_key),
    status            VARCHAR2(30),
    priority          VARCHAR2(20),
    tickets_created   NUMBER,
    tickets_resolved  NUMBER
);


-- ============================================================
-- Step 5 — Populate dim_agent
-- ============================================================

INSERT INTO dim_agent (agent_name, team)
VALUES ('Alice', 'Support');

INSERT INTO dim_agent (agent_name, team)
VALUES ('Bob', 'Infrastructure');

INSERT INTO dim_agent (agent_name, team)
VALUES ('Charlie', 'Backend');

INSERT INTO dim_agent (agent_name, team)
VALUES ('Diana', 'Frontend');


-- ============================================================
-- Step 6 — ETL Logic (Done in Colab with pandas)
-- ============================================================

/*
In Colab:

1. Extract tickets and ticket_assignments from FreeSQL

2. Find assignment at ticket creation:
   valid_from <= created_at
   AND (valid_to IS NULL OR valid_to > created_at)

3. Find assignment at resolution:
   valid_from <= resolved_at
   AND (valid_to IS NULL OR valid_to > resolved_at)

4. Group by:
   date
   agent
   status
   priority

5. Count:
   tickets_created
   tickets_resolved

6. Insert results into fact_ticket_daily
*/


-- ============================================================
-- Step 7 — Verify
-- ============================================================

SELECT
    f.date_key,
    d.agent_name,
    d.team,
    f.status,
    f.priority,
    f.tickets_created,
    f.tickets_resolved
FROM fact_ticket_daily f
JOIN dim_agent d
    ON f.agent_key = d.agent_key
ORDER BY f.date_key, d.agent_name;