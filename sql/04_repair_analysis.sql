-- 04_repair_analysis.sql
-- 수리 방식, 수리 횟수 및 수리 특성 분석

-- 수리 방식별 건수/비율
WITH survey_complete AS (
    SELECT
        caseID,
        timestamp AS survey_complete_time
    FROM repair_event_log_clean
    WHERE taskID = 'Survey'
      AND eventtype = 'complete'
),
repair_after_survey AS (
    SELECT DISTINCT
        s.caseID,
        CASE
            WHEN e.taskID = 'InternRepair' THEN 'InternRepair'
            WHEN e.taskID = 'ImmediateRepair' THEN 'ImmediateRepair'
            WHEN e.taskID = 'ExternRepair' THEN 'ExternRepair'
        END AS repair_method
    FROM survey_complete s
    JOIN repair_event_log_clean e
        ON s.caseID = e.caseID
       AND e.timestamp >= s.survey_complete_time
    WHERE e.eventtype = 'start'
      AND e.taskID IN (
          'InternRepair',
          'ImmediateRepair',
          'ExternRepair'
      )
)
SELECT
    repair_method,
    COUNT(DISTINCT caseID) AS case_cnt,
    ROUND(
        COUNT(DISTINCT caseID) * 100.0
        / SUM(COUNT(DISTINCT caseID)) OVER (),
        2
    ) AS ratio_pct
FROM repair_after_survey
GROUP BY repair_method
ORDER BY case_cnt DESC;

-- Survey 판단 편수별 수리 방식 분포
WITH survey_complete AS (
    SELECT
        caseID,
        timestamp AS survey_complete_time,
        RepairInternally,
        EstimatedRepairTime,
        RepairCode
    FROM repair_event_log_clean
    WHERE taskID = 'Survey'
      AND eventtype = 'complete'
),
repair_after_survey AS (
    SELECT DISTINCT
        s.caseID,
        s.RepairInternally,
        s.EstimatedRepairTime,
        s.RepairCode,
        CASE
            WHEN e.taskID = 'InternRepair' THEN 'InternRepair'
            WHEN e.taskID = 'ImmediateRepair' THEN 'ImmediateRepair'
            WHEN e.taskID = 'ExternRepair' THEN 'ExternRepair'
        END AS repair_method
    FROM survey_complete s
    JOIN repair_event_log_clean e
        ON s.caseID = e.caseID
       AND e.timestamp >= s.survey_complete_time
    WHERE e.eventtype = 'start'
      AND e.taskID IN (
          'InternRepair',
          'ImmediateRepair',
          'ExternRepair'
      )
)
SELECT
    RepairInternally,
    RepairCode,
    repair_method,
    COUNT(DISTINCT caseID) AS case_cnt,
    ROUND(
        COUNT(DISTINCT caseID) * 100.0
        / SUM(COUNT(DISTINCT caseID))
          OVER (PARTITION BY RepairInternally, RepairCode),
        2
    ) AS ratio_pct,
    ROUND(AVG(EstimatedRepairTime), 2) AS avg_estimated_repair_time
FROM repair_after_survey
GROUP BY
    RepairInternally,
    RepairCode,
    repair_method
ORDER BY
    RepairInternally,
    RepairCode,
    case_cnt DESC;