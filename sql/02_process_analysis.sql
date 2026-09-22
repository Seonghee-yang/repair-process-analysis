-- 02_process_analysis.sql
-- 수리 프로세스 및 수리 시간 분석을 위한 데이터 생성

-- repair_time_df
WITH actual_repair AS (
        SELECT caseID
            , MIN(CASE
                    WHEN eventtype = 'start'
                    AND taskID IN ('InternRepair', 'ImmediateRepair', 'ExternRepair')
                    THEN timestamp
                END) AS first_repair_start
            , MAX(CASE
                    WHEN eventtype = 'complete'
                    AND taskID IN ('InternRepair', 'ImmediateRepair')
                    THEN timestamp
                END) AS repair_complete
            , MAX(CASE
                    WHEN eventtype = 'complete'
                    AND taskID = 'RepairReady'
                    THEN timestamp
                END) AS repair_ready_complete
        FROM repair_event_log_clean
        GROUP BY caseID
    ),
    repair_count AS (
        SELECT caseID
             , COUNT(*) AS repair_count
        FROM repair_event_log_clean
        WHERE eventtype = 'start'
          AND taskID IN ('InternRepair', 'ImmediateRepair', 'ExternRepair')
        GROUP BY caseID
    ),
    repair_seq AS (
        SELECT caseID
             , GROUP_CONCAT(taskID ORDER BY timestamp SEPARATOR ' > ') AS repair_sequence
        FROM repair_event_log_clean
        WHERE eventtype = 'start'
          AND taskID IN ('InternRepair', 'ImmediateRepair', 'ExternRepair')
        GROUP BY caseID
    )
SELECT c.caseID
     , c.EstimatedRepairTime
     , c.RepairCode
     , c.RepairInternally
     , a.first_repair_start
     , CASE WHEN c.RepairInternally = False THEN a.repair_ready_complete ELSE a.repair_complete END AS last_repair_complete
     , TIMESTAMPDIFF(
            MINUTE
        , a.first_repair_start
        , CASE WHEN c.RepairInternally = False 
                THEN a.repair_ready_complete 
                ELSE a.repair_complete 
            END
            ) - c.EstimatedRepairTime AS repair_time_diff
    , rc.repair_count
    , CASE
        WHEN rc.repair_count = 1 THEN 'SingleRepair'
        WHEN rc.repair_count >= 2 THEN 'MultipleRepair'
        ELSE 'unknown'
      END AS repair_group
    , rs.repair_sequence
FROM case_flow_table c
LEFT JOIN actual_repair a ON c.caseID = a.caseID
LEFT JOIN repair_count rc ON c.caseID = rc.caseID
LEFT JOIN repair_seq rs ON c.caseID = rs.caseID
-- WHERE a.first_repair_start IS NOT NULL
-- AND a.last_repair_complete IS NOT NULL
-- AND TIMESTAMPDIFF(MINUTE, a.first_repair_start, a.last_repair_complete) >= 0
ORDER BY c.caseID