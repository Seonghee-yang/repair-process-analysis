-- event_task table
CREATE TABLE event_task AS
    SELECT caseID
        , taskID
        , MIN(CASE WHEN eventtype = 'start' THEN timestamp END) AS start_time
        , MAX(CASE WHEN eventtype = 'complete' THEN timestamp END) AS complete_time
        , TIMSTAMPDIFF(MINUTE
        , MIN(CASE WHEN eventtype = 'start' THEN timestamp END)
        , MAX(CASE WHEN eventtype = 'complete' THEN timestamp END)
        ) AS task_duration_minutes
    FROM repair_event_log_clean
    GROUP BY caseID, taskID

-- case_flow_table
CREATE TABLE case_flow_table AS
    SELECT
        CAST(CAST(caseID AS SIGNED INTEGER) AS CHAR) AS caseID,
        MAX(CASE WHEN taskID = 'FirstContact' AND eventtype = 'complete'
                THEN timestamp END) AS FirstContact_end,
        MIN(CASE WHEN taskID = "FirstContact" THEN contact END) AS FirstContact_type,
        MIN(CASE WHEN taskID = 'FirstContact'
                THEN originator END) AS FirstContact_originator,


        MAX(CASE WHEN taskID = 'InformClientWrongPlace' AND eventtype = 'complete'
                THEN timestamp END) AS InformClientWrongPlace_end,
        MIN(CASE WHEN taskID = 'InformClientWrongPlace'
                THEN originator END) AS InformClientWrongPlace_originator,

        MIN(CASE WHEN taskID = 'MakeTicket' AND eventtype = 'start'
                THEN timestamp END) AS MakeTicket_start,
        MAX(CASE WHEN taskID = 'MakeTicket' AND eventtype = 'complete'
                THEN timestamp END) AS MakeTicket_end,
        MAX(CASE WHEN taskID = 'MakeTicket'
                THEN RepairType END) AS RepairType,
        MAX(CASE WHEN taskID = 'MakeTicket'
                THEN objectKey END) AS objectKey,
        MAX(CASE WHEN taskID = 'MakeTicket'
                THEN originator END) AS originator,

        MIN(CASE WHEN taskID = 'ArrangeSurvey' AND eventtype = 'start'
                THEN timestamp END) AS ArrangeSurvey_start,
        MAX(CASE WHEN taskID = 'ArrangeSurvey' AND eventtype = 'complete'
                THEN timestamp END) AS ArrangeSurvey_end,
        MIN(CASE WHEN taskID = 'ArrangeSurvey' AND eventtype = 'start'
                THEN originator END) AS ArrangeSurvey_start_originator,
        MAX(CASE WHEN taskID = 'ArrangeSurvey' AND eventtype = 'complete'
                THEN originator END) AS ArrangeSurvey_end_originator,

        MAX(CASE WHEN taskID = 'InformClientSurvey' AND eventtype = 'complete'
                THEN timestamp END) AS InformClientSurvey_end,
        MAX(CASE WHEN taskID = 'InformClientSurvey'
                THEN originator END) AS InformClientSurvey_originator,

        MIN(CASE WHEN taskID = 'Survey' AND eventtype = 'start'
                THEN timestamp END) AS Survey_start,
        MAX(CASE WHEN taskID = 'Survey' AND eventtype = 'complete'
                THEN timestamp END) AS Survey_end,
        MAX(CASE WHEN taskID = 'Survey'
                THEN originator END) AS Survey_originator,
        MAX(CASE WHEN taskID = 'Survey' AND eventtype = 'complete'
                THEN RepairInternally END) AS RepairInternally,
        MAX(CASE WHEN taskID = 'Survey' AND eventtype = 'complete'
                THEN EstimatedRepairTime END) AS EstimatedRepairTime,
        MAX(CASE WHEN taskID = 'Survey' AND eventtype = 'complete'
                THEN RepairCode END) AS RepairCode,

        MIN(CASE WHEN taskID = 'InternRepair' AND eventtype = 'start'
                THEN timestamp END) AS InternRepair_start,
        MIN(CASE WHEN taskID = 'InternRepair' AND eventtype = 'start'
                THEN originator END) AS InternRepair_start_originator,
        MAX(CASE WHEN taskID = 'InternRepair' AND eventtype = 'complete'
                THEN timestamp END) AS InternRepair_end,

        MAX(CASE WHEN taskID = 'InternRepair' AND eventtype = 'complete'
                THEN originator END) AS InternRepair_end_originator,

        MIN(CASE WHEN taskID = 'ImmediateRepair' AND eventtype = 'start'
                THEN timestamp END) AS ImmediateRepair_start,
            MIN(CASE WHEN taskID = 'ImmediateRepair' AND eventtype = 'start'
                THEN originator END) AS ImmediateRepair_start_originator,
        MAX(CASE WHEN taskID = 'ImmediateRepair' AND eventtype = 'complete'
                THEN timestamp END) AS ImmediateRepair_end,
        MAX(CASE WHEN taskID = 'ImmediateRepair' AND eventtype = 'complete'
                THEN originator END) AS ImmediateRepair_end_originator,

        MIN(CASE WHEN taskID = 'ExternRepair' AND eventtype = 'start'
                THEN timestamp END) AS ExternRepair_start,
        MIN(CASE WHEN taskID = 'ExternRepair'
                THEN originator END) AS ExternRepair_originator,

        MIN(CASE WHEN taskID = 'RepairReady' AND eventtype = 'complete'
                THEN timestamp END) AS RepairReady_complete,
        MIN(CASE WHEN taskID = 'RepairReady'
                THEN originator END) AS RepairReady_originator,

        MIN(CASE WHEN taskID = 'SendTicketToFinAdmin' AND eventtype = 'complete'
                THEN timestamp END) AS SendTicketToFinAdmin_complete,

        MIN(CASE WHEN taskID = 'ReadyInformClient' AND eventtype = 'complete'
                THEN timestamp END) AS ReadyForInformClient_complete,

        MIN(CASE WHEN taskID = 'TicketReady' AND eventtype = 'complete'
                THEN timestamp END) AS TicketReady_complete

    FROM repair_event_log_clean
    GROUP BY caseID

-- case_flow_df
SELECT *
    , CASE WHEN InternRepair_start IS NOT NULL THEN 'InternRepair'
        WHEN ImmediateRepair_start IS NOT NULL THEN 'ImmediateRepair'
        WHEN ExternRepair_start IS NOT NULL THEN 'ExternRepair'
        ELSE 'NoRepair'
        END AS repair_path
    , TIMESTAMPDIFF(MINUTE, Survey_start, Survey_end) AS survey_duration
    , TIMESTAMPDIFF(MINUTE, InternRepair_start, InternRepair_end) AS internrepair_duration
    , TIMESTAMPDIFF(MINUTE, ImmediateRepair_start, ImmediateRepair_end) AS immediaterepair_duration
    , TIMESTAMPDIFF(MINUTE, ExternRepair_start, RepairReady_end) AS externrepair_duration
    , TIMESTAMPDIFF(MINUTE, FirstContact_end, TicketReady_end) AS case_lead_time_min
FROM case_flow_table

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

-- 담당자 분석(handover 부분) : long case
WITH start_base AS (
    SELECT caseID
         , taskID
         , timestamp AS start_time
         , originator AS s_org
         , ROW_NUMBER() OVER (PARTITION BY caseID, taskID ORDER BY timestamp) AS seq
    FROM repair_event_log_clean
    WHERE eventtype = 'start'
)
, complete_base AS (
    SELECT caseID
         , taskID
         , timestamp AS complete_time
         , originator AS c_org
         , ROW_NUMBER() OVER (PARTITION BY caseID, taskID ORDER BY timestamp) AS seq
    FROM repair_event_log_clean
    WHERE eventtype = 'complete'
)
, task_duration AS (
    SELECT s.caseID
         , s.taskID
         , IF(s.s_org = c.c_org, 'Same', 'Changed') AS hand_over
         , TIMESTAMPDIFF(MINUTE, s.start_time, c.complete_time) AS task_duration_min
    FROM start_base s
        INNER JOIN complete_base c ON s.caseID = c.caseID 
                                   AND s.taskID = c.taskID 
                                   AND s.seq = c.seq
)
SELECT *
FROM task_duration

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


-- 특정 가설 검증 쿼리
-- inform client survey 종료 후 survey 시작 전 사이인 3.2일 대기구간 데이터와 해당 케이스 arrange survey 담당자 변경 여부 결합

-- 1. 각 케이스별/태스크별 시작과 종료 담당자 매칭(hand-over 판별용)
WITH task_originators AS (
    SELECT s.caseID
         , s.taskID
         , s.originator AS start_org
         , c.originator AS complete_org
         , IF(s.originator = c.originator, 0, 1) AS handover_flag
    FROM (SELECT * FROM repair_event_log_clean WHERE eventtype = 'start') s
    JOIN (SELECT * FROM repair_event_log_clean WHERE eventtype = 'complete') c
        ON s.caseID = c.caseID
        AND s.taskID = c.taskID
)
-- 2. LEAD 함수를 이용해 'Inform Client Survey' 다음의 'Survey' 시작 시간 가져오기
, event_flow AS (
    SELECT caseID
         , taskID
         , timestamp AS current_end_time
         , LEAD(taskID) OVER (PARTITION BY caseID ORDER BY timestamp) AS next_task
         , LEAD(timestamp) OVER (PARTITION BY caseID ORDER BY timestamp) AS next_start_time
    FROM repair_event_log_clean
)
-- 3. 'Inform -> Survey' 구간의 대기시간(분) 계산
, waiting_analysis AS (
    SELECT *
         , TIMESTAMPDIFF(MINUTE, current_end_time, next_start_time) AS wait_min
    FROM event_flow
    WHERE taskID = 'InformClientSurvey'
    AND next_task = 'Survey'
)

-- 4. 최종 병합: 대기구간 데이터와 해당 케이스의 arrange survey 담당자 변경 여부 결합
SELECT *
FROM waiting_analysis w
LEFT JOIN task_originators t
    ON w.caseID = t.caseID
WHERE t.taskID = 'ArrangeSurvey'



-- base query (수리 유형 관련 쿼리)
WITH wrong_cases AS (
    SELECT DISTINCT caseID
    FROM repair_event_log_clean
    WHERE taskID = 'InformClientWrongPlace'
),
repair_start AS (
    SELECT
        caseID,
        MIN(timestamp) AS first_repair_start
    FROM repair_event_log_clean
    WHERE eventtype = 'start'
      AND taskID IN ('InternRepair', 'ImmediateRepair', 'ExternRepair')
      AND caseID NOT IN (SELECT caseID FROM wrong_cases)
    GROUP BY caseID
),
repair_complete AS (
    SELECT
        caseID,
        MAX(timestamp) AS last_repair_complete
    FROM repair_event_log_clean
    WHERE eventtype = 'complete'
      AND taskID IN ('InternRepair', 'ImmediateRepair', 'ExternRepair')
      AND caseID NOT IN (SELECT caseID FROM wrong_cases)
    GROUP BY caseID
),
repair_ready AS (
    SELECT
        caseID,
        MIN(timestamp) AS repair_ready_complete
    FROM repair_event_log_clean
    WHERE eventtype = 'complete'
      AND taskID = 'RepairReady'
      AND caseID NOT IN (SELECT caseID FROM wrong_cases)
    GROUP BY caseID
),
repair_count AS (
    SELECT
        caseID,
        COUNT(*) AS repair_count
    FROM repair_event_log_clean
    WHERE eventtype = 'start'
      AND taskID IN ('InternRepair', 'ImmediateRepair', 'ExternRepair')
    GROUP BY caseID
),
repair_seq AS (
    SELECT
        caseID,
        GROUP_CONCAT(taskID ORDER BY timestamp SEPARATOR ' > ') AS repair_sequence
    FROM repair_event_log_clean
    WHERE eventtype = 'start'
      AND taskID IN ('InternRepair', 'ImmediateRepair', 'ExternRepair')
    GROUP BY caseID
)
SELECT
    c.caseID,
    c.EstimatedRepairTime,
    c.RepairType,
    c.RepairCode,
    c.RepairInternally,
    rs.first_repair_start,
    rc.last_repair_complete,
    rr.repair_ready_complete,
    rq.repair_count,
    rseq.repair_sequence,

    CASE
        WHEN rseq.repair_sequence LIKE '%ExternRepair%'
            THEN rr.repair_ready_complete
        ELSE rc.last_repair_complete
    END AS final_repair_end_time,

    TIMESTAMPDIFF(
        MINUTE,
        rs.first_repair_start,
        CASE
            WHEN rseq.repair_sequence LIKE '%ExternRepair%'
                THEN rr.repair_ready_complete
            ELSE rc.last_repair_complete
        END
    ) AS actual_repair_time_minutes,

    TIMESTAMPDIFF(
        MINUTE,
        rs.first_repair_start,
        CASE
            WHEN rseq.repair_sequence LIKE '%ExternRepair%'
                THEN rr.repair_ready_complete
            ELSE rc.last_repair_complete
        END
    ) - c.EstimatedRepairTime AS repair_time_diff,

    CASE
        WHEN rq.repair_count = 1 THEN 'single'
        WHEN rq.repair_count >= 2 THEN 'multi'
        ELSE 'unknown'
    END AS repair_group

FROM case_flow_table c
LEFT JOIN repair_start rs
    ON c.caseID = rs.caseID
LEFT JOIN repair_complete rc
    ON c.caseID = rc.caseID
LEFT JOIN repair_ready rr
    ON c.caseID = rr.caseID
LEFT JOIN repair_count rq
    ON c.caseID = rq.caseID
LEFT JOIN repair_seq rseq
    ON c.caseID = rseq.caseID
WHERE c.caseID NOT IN (SELECT caseID FROM wrong_cases)


--- 여기서부터는 파이썬에서 사용안한 코드. 그냥 확인용
-- 단계별 평균 시간(bottleneck)
SELECT AVG(TIMESTAMPDIFF(MINUTE, FirstContact_end, MakeTicket_start)) AS firstcontact_to_ticket
    , AVG(TIMESTAMPDIFF(MINUTE, MakeTicket_end, Survey_start)) AS ticket_to_survey
    , AVG(TIMESTAMPDIFF(MINUTE, Survey_end, InternRepair_start)) AS survey_to_intern_repair
    , AVG(TIMESTAMPDIFF(MINUTE, Survey_end, ImmediateRepair_start)) AS survey_to_immediate_repair
    , AVG(TIMESTAMPDIFF(MINUTE, Survey_end, ExternRepair_start)) AS survey_to_extern_repair
    , AVG(TIMESTAMPDIFF(MINUTE, InternRepair_end, RepairReady_end)) AS intern_to_ready
    , AVG(TIMESTAMPDIFF(MINUTE, ImmediateRepair_end, RepairReady_end)) AS imme_to_ready
    , AVG(TIMESTAMPDIFF(MINUTE, ExternRepair_start, RepairReady_end)) AS extern_to_ready
    , AVG(TIMESTAMPDIFF(MINUTE, RepairReady_end, SendTicketToFinAdmin_end)) AS ready_to_send
    , AVG(TIMESTAMPDIFF(MINUTE, SendTicketToFinAdmin_end, ReadyForInformClient_end)) AS send_to_client
    , AVG(TIMESTAMPDIFF(MINUTE, ReadyForInformClient_end, TicketReady_end)) AS client_to_ticket
FROM (
SELECT *
    , CASE WHEN InternRepair_start IS NOT NULL THEN 'InternRepair'
        WHEN ImmediateRepair_start IS NOT NULL THEN 'ImmediateRepair'
        WHEN ExternRepair_start IS NOT NULL THEN 'ExternRepair'
        ELSE 'NoRepair'
        END AS repair_path
    , CASE WHEN Survey_start IS NOT NULL THEN 1 ELSE 0 END AS has_survey
    , CASE WHEN TicketReady_end IS NOT NULL THEN 1 ELSE 0 END AS is_completed
    , TIMESTAMPDIFF(MINUTE, Survey_start, Survey_end) AS survey_duration
    , TIMESTAMPDIFF(MINUTE, InternRepair_start, InternRepair_end) AS internrepair_duration
    , TIMESTAMPDIFF(MINUTE, ImmediateRepair_start, ImmediateRepair_end) AS immediaterepair_duration
    , TIMESTAMPDIFF(MINUTE, ExternRepair_start, RepairReady_end) AS externrepair_duration
    , TIMESTAMPDIFF(MINUTE, FirstContact_end, TicketReady_end) AS total_leadtime_duration
    , CASE WHEN FirstContact_end IS NOT NULL 
            AND MakeTicket_end IS NOT NULL 
            AND FirstContact_end <= MakeTicket_end THEN 1 ELSE 0 
            END AS valid_firstcontact_to_maketicket
    , CASE WHEN Survey_start IS NOT NULL
            AND (InternRepair_start IS NOT NULL
                OR ImmediateRepair_start IS NOT NULL
                OR ExternRepair_start IS NOT NULL)
            THEN 1 ELSE 0 END AS has_repair_after_survey
FROM case_flow_table
) t

-- case flow 파생변수들
SELECT *
    , CASE WHEN InternRepair_start IS NOT NULL THEN 'InternRepair'
        WHEN ImmediateRepair_start IS NOT NULL THEN 'ImmediateRepair'
        WHEN ExternRepair_start IS NOT NULL THEN 'ExternRepair'
        ELSE 'NoRepair'
        END AS repair_path
    , CASE WHEN Survey_start IS NOT NULL THEN 1 ELSE 0 END AS has_survey
    , CASE WHEN TicketReady_end IS NOT NULL THEN 1 ELSE 0 END AS is_completed
    , TIMESTAMPDIFF(MINUTE, Survey_start, Survey_end) AS survey_duration
    , TIMESTAMPDIFF(MINUTE, InternRepair_start, InternRepair_end) AS internrepair_duration
    , TIMESTAMPDIFF(MINUTE, ImmediateRepair_start, ImmediateRepair_end) AS immediaterepair_duration
    , TIMESTAMPDIFF(MINUTE, ExternRepair_start, RepairReady_end) AS externrepair_duration
    , TIMESTAMPDIFF(MINUTE, FirstContact_end, TicketReady_end) AS total_leadtime
    , CASE WHEN FirstContact_end IS NOT NULL 
            AND MakeTicket_end IS NOT NULL 
            AND FirstContact_end <= MakeTicket_end THEN 1 ELSE 0 
            END AS valid_firstcontact_to_maketicket
    , CASE WHEN Survey_start IS NOT NULL
            AND (InternRepair_start IS NOT NULL
                OR ImmediateRepair_start IS NOT NULL
                OR ExternRepair_start IS NOT NULL)
            THEN 1 ELSE 0 END AS has_repair_after_survey
FROM case_flow_table

-- case flow 전체 리드타임 통계
SELECT repair_path
    , COUNT(*) AS case_cnt
    , AVG(internrepair_duration) AS avg_intern_time
    , AVG(immediaterepair_duration) AS avg_immediate_time
    , AVG(externrepair_duration) AS avg_extern_time
    , AVG(total_leadtime_duration) AS avg_total_time
    , MIN(total_leadtime_duration) AS min_leadtime
    , MAX(total_leadtime_duration) AS max_leadtime
FROM (
    SELECT *
        , CASE WHEN InternRepair_start IS NOT NULL THEN 'InternRepair'
            WHEN ImmediateRepair_start IS NOT NULL THEN 'ImmediateRepair'
            WHEN ExternRepair_start IS NOT NULL THEN 'ExternRepair'
            ELSE 'NoRepair'
            END AS repair_path
        , CASE WHEN Survey_start IS NOT NULL THEN 1 ELSE 0 END AS has_survey
        , CASE WHEN TicketReady_end IS NOT NULL THEN 1 ELSE 0 END AS is_completed
        , TIMESTAMPDIFF(MINUTE, Survey_start, Survey_end) AS survey_duration
        , TIMESTAMPDIFF(MINUTE, InternRepair_start, InternRepair_end) AS internrepair_duration
        , TIMESTAMPDIFF(MINUTE, ImmediateRepair_start, ImmediateRepair_end) AS immediaterepair_duration
        , TIMESTAMPDIFF(MINUTE, ExternRepair_start, RepairReady_end) AS externrepair_duration
        , TIMESTAMPDIFF(MINUTE, FirstContact_end, TicketReady_end) AS total_leadtime_duration
        , CASE WHEN FirstContact_end IS NOT NULL 
                AND MakeTicket_end IS NOT NULL 
                AND FirstContact_end <= MakeTicket_end THEN 1 ELSE 0 
                END AS valid_firstcontact_to_maketicket
        , CASE WHEN Survey_start IS NOT NULL
                AND (InternRepair_start IS NOT NULL
                    OR ImmediateRepair_start IS NOT NULL
                    OR ExternRepair_start IS NOT NULL)
                THEN 1 ELSE 0 END AS has_repair_after_survey
    FROM case_flow_table
    ) t
GROUP BY repair_path
ORDER BY avg_total_time DESC

-- survey 쿼리 버전
WITH survey_df AS (
    	SELECT *
        FROM repair_event_log_clean
        WHERE taskID = "Survey"
        AND eventtype = "complete"
        ),
    repair_start_df AS (
        SELECT *
        FROM repair_event_log_clean
        WHERE taskID IN ("InternRepair", "ImmediateRepair", "ExternRepair")
        AND eventtype = "start"
    ),
    ranked_repair AS (
        SELECT caseID
    		, taskID
            , timestamp
            , ROW_NUMBER() OVER(PARTITION BY caseID ORDER BY timestamp) AS rn_first
            , ROW_NUMBER() OVER(PARTITION BY caseID ORDER BY timestamp DESC) AS rn_last
    	FROM repair_start_df
    ),
    repair_summary AS (
        SELECT caseID
    		, MAX(CASE WHEN rn_first = 1 THEN taskID END) AS first_repair_type
            , MAX(CASE WHEN rn_last = 1 THEN taskID END) AS last_repair_type
    	FROM ranked_repair
        GROUP BY caseID
    ), 
    survey_first_df AS (
        SELECT s.*
    		, r.first_repair_type
            , r.last_repair_type
            , CASE WHEN EstimatedRepairTime <= 120 THEN '<=120'
    			   WHEN EstimatedRepairTime <= 240 THEN '<=240'
                   ELSE '360+'
                   ENd AS time_bucket
    	FROM survey_df s
    		LEFT JOIN repair_summary r ON r.caseID = s.caseID
	)
SELECT *
FROM survey_first_df
ORDER BY caseID

-- waiting time analysis
-- complete -> next_start 구간
WITH event_seq AS (
    SELECT
        caseID,
        taskID,
        originator,
        eventtype,
        timestamp,
        LEAD(taskID) OVER (
            PARTITION BY caseID
            ORDER BY timestamp
        ) AS next_task,
        LEAD(originator) OVER (
            PARTITION BY caseID
            ORDER BY timestamp
        ) AS next_originator,
        LEAD(eventtype) OVER (
            PARTITION BY caseID
            ORDER BY timestamp
        ) AS next_event,
        LEAD(timestamp) OVER (
            PARTITION BY caseID
            ORDER BY timestamp
        ) AS next_time
    FROM repair_event_log_clean
)
SELECT
    caseID,
    taskID AS current_task,
    originator AS current_originator,
    eventtype AS current_event,
    timestamp AS current_time,
    next_task,
    next_originator,
    next_event,
    next_time,
    TIMESTAMPDIFF(MINUTE, timestamp, next_time) AS waiting_minutes,
    ROUND(
        TIMESTAMPDIFF(SECOND, timestamp, next_time) / 3600,
        2
    ) AS waiting_hours,
    ROUND(
        TIMESTAMPDIFF(SECOND, timestamp, next_time) / 86400,
        2
    ) AS waiting_days
FROM event_seq
WHERE eventtype = 'complete'
  AND next_event = 'start'
  AND next_time IS NOT NULL
ORDER BY caseID, current_time;

-- 평균 대기 시간
WITH event_seq AS (
    SELECT
        caseID,
        taskID,
        eventtype,
        timestamp,
        LEAD(taskID) OVER (
            PARTITION BY caseID
            ORDER BY timestamp
        ) AS next_task,
        LEAD(eventtype) OVER (
            PARTITION BY caseID
            ORDER BY timestamp
        ) AS next_event,
        LEAD(timestamp) OVER (
            PARTITION BY caseID
            ORDER BY timestamp
        ) AS next_time
    FROM repair_event_log_clean
)
SELECT
    taskID AS current_task,
    next_task,
    COUNT(*) AS transition_cnt,
    AVG(
        TIMESTAMPDIFF(MINUTE, timestamp, next_time)
    ) AS avg_waiting_minutes,
    ROUND(
        AVG(TIMESTAMPDIFF(SECOND, timestamp, next_time)) / 3600,
        2
    ) AS avg_waiting_hours,
    ROUND(
        AVG(TIMESTAMPDIFF(SECOND, timestamp, next_time)) / 86400,
        2
    ) AS avg_waiting_days
FROM event_seq
WHERE eventtype = 'complete'
  AND next_event = 'start'
  AND next_time IS NOT NULL
GROUP BY taskID, next_task
ORDER BY avg_waiting_days DESC;


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

-- 
