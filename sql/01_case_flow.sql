-- 01_case_flow.sql
-- Event Log를 Case 단위 분석 테이블로 변환

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