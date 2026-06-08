-- ============================================================
-- Lesson 07: KPI Dashboards — Solutions
-- ============================================================


-- ============================================================
-- EXERCISE 1: Define "Team Velocity"
-- ============================================================

-- 1. What is the business question?
-- How fast does each team complete their tasks?

-- 2. What is the exact definition?
-- Velocity means completed tasks per day for each team.
-- Only completed tasks are counted.

-- 3. What are the edge cases?
-- Teams with no completed tasks.
-- Tasks without assigned users.
-- Cancelled tasks should not count.

-- 4. What is the unit?
-- Tasks completed per day.

-- 5. What would make this metric misleading?
-- Some teams may complete many small tasks while others work on harder tasks.

WITH team_velocity AS (
    SELECT
        t.name AS team_name,
        COUNT(CASE WHEN ts.status = 'completed' THEN 1 END) AS completed_tasks,
        TRUNC(MAX(ts.completed_at)) - TRUNC(MIN(ts.created_at)) + 1 AS total_days
    FROM teams t
    LEFT JOIN users u
        ON u.team_id = t.id
    LEFT JOIN tasks ts
        ON ts.assigned_to = u.id
    WHERE ts.completed_at IS NOT NULL
    GROUP BY t.name
)

SELECT
    team_name,
    completed_tasks,
    total_days,
    ROUND(completed_tasks / NULLIF(total_days, 0), 2) AS velocity,
    CASE
        WHEN completed_tasks / NULLIF(total_days, 0)
            < AVG(completed_tasks / NULLIF(total_days, 0)) OVER ()
        THEN 'BELOW_AVERAGE'
        ELSE 'ABOVE_AVERAGE'
    END AS velocity_flag
FROM team_velocity
ORDER BY velocity DESC;


-- ============================================================
-- EXERCISE 2: Define "On-Time Delivery Rate"
-- ============================================================

-- 1. What is the business question?
-- How often are tasks completed before the deadline?

-- 2. What is the exact definition?
-- A task is considered on time if completed_at is before or on due_date.

-- 3. What are the edge cases?
-- Tasks without due dates.
-- Tasks not completed yet.
-- Cancelled tasks.

-- 4. What is the unit?
-- Percentage.

-- 5. What would make this metric misleading?
-- Some tasks may have unrealistic due dates.

SELECT
    priority,
    COUNT() AS completed_tasks,

    COUNT(
        CASE
            WHEN TRUNC(CAST(completed_at AS DATE)) <= due_date
            THEN 1
        END
    ) AS on_time_tasks,

    ROUND(
        100 * COUNT(
            CASE
                WHEN TRUNC(CAST(completed_at AS DATE)) <= due_date
                THEN 1
            END
        ) / NULLIF(COUNT(), 0),
        2
    ) AS on_time_rate,

    ROUND(
        AVG(
            CASE
                WHEN TRUNC(CAST(completed_at AS DATE)) > due_date
                THEN (CAST(completed_at AS DATE) - due_date) * 24
            END
        ),
        2
    ) AS avg_late_hours

FROM tasks
WHERE status = 'completed'
  AND completed_at IS NOT NULL
  AND due_date IS NOT NULL
GROUP BY priority
ORDER BY priority;


-- ============================================================
-- EXERCISE 3: Improve "Tasks per Team"
-- ============================================================

SELECT
    t.name AS team_name,

    COUNT(ts.id) AS total_tasks,

    COUNT(
        CASE
            WHEN ts.status IN ('open', 'in_progress', 'blocked')
            THEN 1
        END
    ) AS active_tasks,

    ROUND(
        100 * COUNT(
            CASE
                WHEN ts.status = 'completed'
                THEN 1
            END
        )
        /
        NULLIF(
            COUNT(
                CASE
                    WHEN ts.status <> 'cancelled'
                    THEN 1
                END
            ),
            0
        ),
        2
    ) AS completion_rate,

    CASE
        WHEN COUNT(
            CASE
                WHEN ts.status IN ('open', 'in_progress', 'blocked')
                THEN 1
            END
        ) > 10
        THEN 'Overloaded'

        WHEN COUNT(
            CASE
                WHEN ts.status IN ('open', 'in_progress', 'blocked')
                THEN 1
            END
        ) BETWEEN 5 AND 10
        THEN 'Healthy'

        ELSE 'Underutilized'
    END AS health_score

FROM teams t
LEFT JOIN users u
    ON u.team_id = t.id
LEFT JOIN tasks ts
    ON ts.assigned_to = u.id
GROUP BY t.name
ORDER BY active_tasks DESC;


-- ============================================================
-- EXERCISE 4: Improve "Average Resolution Time"
-- ============================================================

WITH completed_tasks AS (
    SELECT
        priority,

        (
            EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
            EXTRACT(HOUR FROM (completed_at - created_at)) +
            EXTRACT(MINUTE FROM (completed_at - created_at)) / 60
        ) AS resolution_hours

    FROM tasks
    WHERE status = 'completed'
      AND completed_at IS NOT NULL
)

SELECT
    priority,

    COUNT() AS completed_count,

    ROUND(AVG(resolution_hours), 2) AS avg_resolution_hours,

    ROUND(
        PERCENTILE_CONT(0.5)
        WITHIN GROUP (ORDER BY resolution_hours),
        2
    ) AS median_resolution_hours,

    ROUND(MIN(resolution_hours), 2) AS fastest_resolution_hours,

    ROUND(MAX(resolution_hours), 2) AS slowest_resolution_hours,

    CASE
        WHEN priority = 'critical'
             AND AVG(resolution_hours) <= 24
        THEN 'SLA MET'

        WHEN priority = 'high'
             AND AVG(resolution_hours) <= 72
        THEN 'SLA MET'

        WHEN priority = 'medium'
             AND AVG(resolution_hours) <= 168
        THEN 'SLA MET'

        WHEN priority = 'low'
             AND AVG(resolution_hours) <= 336
        THEN 'SLA MET'

        ELSE 'SLA MISSED'
    END AS target_met

FROM completed_tasks
GROUP BY priority
ORDER BY priority;


-- ============================================================
-- EXERCISE 5: Improve "Overdue Tasks"
-- ============================================================

WITH overdue_tasks AS (
    SELECT
        ts.title,
        u.full_name AS assignee,
        t.name AS team,
        ts.priority,
        ts.due_date,

        TRUNC(SYSDATE) - ts.due_date AS days_overdue,

        CASE
            WHEN ts.priority = 'critical'
                 AND TRUNC(SYSDATE) - ts.due_date > 0
            THEN 'CRITICAL'

            WHEN ts.priority = 'high'
                 AND TRUNC(SYSDATE) - ts.due_date > 2
            THEN 'HIGH'

            WHEN ts.priority = 'medium'
                 AND TRUNC(SYSDATE) - ts.due_date > 5
            THEN 'MEDIUM'

            ELSE 'LOW'
        END AS severity

    FROM tasks ts
    LEFT JOIN users u
        ON u.id = ts.assigned_to
    LEFT JOIN teams t
        ON t.id = u.team_id

    WHERE ts.due_date < TRUNC(SYSDATE)
      AND ts.status NOT IN ('completed', 'cancelled')
      AND ts.due_date IS NOT NULL
)

SELECT *
FROM overdue_tasks
ORDER BY
    CASE severity
        WHEN 'CRITICAL' THEN 1
        WHEN 'HIGH' THEN 2
        WHEN 'MEDIUM' THEN 3
        ELSE 4
    END,
    days_overdue DESC;


-- ============================================================
-- EXERCISE 6: Fix the "Productivity Score"
-- ============================================================

-- PROBLEM:
-- The original query only counts tasks assigned to users.
-- It does not check if tasks were completed or how important they were.

WITH completed_tasks AS (
    SELECT
        u.full_name,

        CASE ts.priority
            WHEN 'critical' THEN 4
            WHEN 'high' THEN 3
            WHEN 'medium' THEN 2
            ELSE 1
        END AS priority_weight

    FROM users u
    LEFT JOIN tasks ts
        ON ts.assigned_to = u.id

    WHERE ts.status = 'completed'
)

SELECT
    full_name,
    COUNT() AS completed_tasks,
    SUM(priority_weight) AS productivity_score
FROM completed_tasks
GROUP BY full_name
ORDER BY productivity_score DESC;


-- ============================================================
-- EXERCISE 7: Fix the "Team Efficiency"
-- ============================================================

-- PROBLEM:
-- Average task ID does not mean anything about efficiency.

SELECT
    t.name AS team_name,

    COUNT(ts.id) AS total_tasks,

    COUNT(
        CASE
            WHEN ts.status = 'completed'
            THEN 1
        END
    ) AS completed_tasks,

    ROUND(
        100 * COUNT(
            CASE
                WHEN ts.status = 'completed'
                THEN 1
            END
        ) / NULLIF(COUNT(ts.id), 0),
        2
    ) AS completion_rate

FROM teams t
LEFT JOIN users u
    ON u.team_id = t.id
LEFT JOIN tasks ts
    ON ts.assigned_to = u.id
GROUP BY t.name
ORDER BY completion_rate DESC;


-- ============================================================
-- EXERCISE 8: Fix the "Urgency Index"
-- ============================================================

-- PROBLEM:
-- You cannot multiply text values or add dates to strings.
-- The original formula does not represent urgency correctly.

SELECT
    title,
    priority,
    due_date,

    TRUNC(due_date) - TRUNC(SYSDATE) AS days_until_due,

    (
        CASE priority
            WHEN 'critical' THEN 4
            WHEN 'high' THEN 3
            WHEN 'medium' THEN 2
            ELSE 1
        END
    ) - (TRUNC(due_date) - TRUNC(SYSDATE)) AS urgency_score

FROM tasks
WHERE due_date IS NOT NULL
  AND status NOT IN ('completed', 'cancelled')
ORDER BY urgency_score DESC;


-- ============================================================
-- PART D: Summary Dashboard Query
-- ============================================================

WITH base AS (
    SELECT
        ts.,
        TRUNC(SYSDATE) - due_date AS days_overdue
    FROM tasks ts
),

team_load AS (
    SELECT
        t.name,
        COUNT(
            CASE
                WHEN ts.status IN ('open', 'in_progress', 'blocked')
                THEN 1
            END
        ) AS active_tasks
    FROM teams t
    LEFT JOIN users u
        ON u.team_id = t.id
    LEFT JOIN tasks ts
        ON ts.assigned_to = u.id
    GROUP BY t.name
)

SELECT
    COUNT() AS total_tasks,

    COUNT(
        CASE
            WHEN status = 'completed'
            THEN 1
        END
    ) AS completed_tasks,

    COUNT(
        CASE
            WHEN status IN ('open', 'in_progress', 'blocked')
            THEN 1
        END
    ) AS active_tasks,

    COUNT(
        CASE
            WHEN due_date < TRUNC(SYSDATE)
             AND status NOT IN ('completed', 'cancelled')
            THEN 1
        END
    ) AS overdue_tasks,

    ROUND(
        100 * COUNT(
            CASE
                WHEN status = 'completed'
                THEN 1
            END
        ) / NULLIF(COUNT(), 0),
        2
    ) AS completion_rate_pct,

    ROUND(
        AVG(
            CASE
                WHEN completed_at IS NOT NULL
                THEN (
                    EXTRACT(DAY FROM (completed_at - created_at)) * 24 +
                    EXTRACT(HOUR FROM (completed_at - created_at))
                )
            END
        ),
        2
    ) AS avg_resolution_hours,

    ROUND(
        AVG(
            CASE
                WHEN due_date < TRUNC(SYSDATE)
                THEN days_overdue
            END
        ),
        2
    ) AS avg_days_overdue,

    (
        SELECT priority
        FROM (
            SELECT priority, COUNT() AS total
            FROM tasks
            WHERE status IN ('open', 'in_progress', 'blocked')
            GROUP BY priority
            ORDER BY total DESC
        )
        WHERE ROWNUM = 1
    ) AS most_common_priority,

    (
        SELECT name
        FROM (
            SELECT name, active_tasks
            FROM team_load
            ORDER BY active_tasks DESC
        )
        WHERE ROWNUM = 1
    ) AS busiest_team

FROM base;