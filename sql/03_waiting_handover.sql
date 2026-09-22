-- 03_waiting_handover.sql
-- 단계 간 대기시간 및 담당자 Handover 분석

-- 담당자 분석(handover 부분)
SELECT caseID
     , taskID AS prev_task
     , originator AS prev_actor
     , timestamp AS start_time
     , LEAD(taskID) OVER (PARTITION BY caseID ORDER BY timestamp) AS next_task
     , LEAD(originator) OVER (PARTITION BY caseID ORDER BY timestamp) AS next_actor
     , LEAD(timestamp) OVER (PARTITION BY caseID ORDER BY timestamp) AS next_time
     , TIMESTAMPDIFF(MINUTE, timestamp, LEAD(timestamp) OVER (PARTITION BY caseID ORDER BY timestamp)) / 60 AS transition_time_min
     , (TIMESTAMPDIFF(SECOND, timestamp, LEAD(timestamp) OVER (PARTITION BY caseID ORDER BY timestamp)) / 60) / 60 AS transition_time_hr,
     , (TIMESTAMPDIFF(SECOND, timestamp, LEAD(timestamp) OVER (PARTITION BY caseID ORDER BY timestamp)) / 60) / 1440 AS transition_time_day
FROM repair_event_log_clean
ORDER BY caseID, timestamp

-- 담당자 불일치 검증
WITH start_events AS (
    SELECT
        caseID,
        taskID,
        originator AS start_originator,
        timestamp AS start_time,
        ROW_NUMBER() OVER (
            PARTITION BY caseID, taskID
            ORDER BY timestamp
        ) AS seq
    FROM repair_event_log_clean
    WHERE eventtype = 'start'
      AND originator <> 'System'
),
complete_events AS (
    SELECT
        caseID,
        taskID,
        originator AS complete_originator,
        timestamp AS complete_time,
        ROW_NUMBER() OVER (
            PARTITION BY caseID, taskID
            ORDER BY timestamp
        ) AS seq
    FROM repair_event_log_clean
    WHERE eventtype = 'complete'
      AND originator <> 'System'
)
SELECT
    s.caseID,
    s.taskID,
    s.seq,
    s.start_originator,
    s.start_time,
    c.complete_originator,
    c.complete_time
FROM start_events s
INNER JOIN complete_events c
    ON s.caseID = c.caseID
   AND s.taskID = c.taskID
   AND s.seq = c.seq
WHERE s.start_originator <> c.complete_originator
ORDER BY s.caseID, s.taskID, s.start_time;
