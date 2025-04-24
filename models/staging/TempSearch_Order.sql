{{ config(
    materialized = 'table',
    alias = 'TempSEARCH_ORDER'
) }}

SELECT 
    CASE 
        WHEN j.PkgReqId IS NULL THEN s.PackageId 
        ELSE j.PkgReqId 
    END AS PackageId,  
    s.StatusCode AS StatusCode,
    s.SubStatus AS SubStatus,
    s.InvoiceDatetime AS InvoiceDatetime,
    s.NotMonthlyInvoiceDatetime,
    s.ResearcherSummaryDate,
    s.ResultNote,
    s.StatusNote,
    s.email_sent,
    s.need_review_email_sent,
    s.oin_email_sent,
    s.pkg_processed,
    s.adj_id,
    s.CompletionDate,
    s.OrderDate,
    FEES.DOC_FEE,
    FEES.STATUTORY_FEE,
    FEES.ADDITIONAL_YEAR_FEE,
    FEES.COPIES,
    s.RefNumber2,
    s.RefNumber3,
    s.RefNumber4,
    s.RefNumber5,
    s.OrderDate AS ABStartDate,
    NULL AS ABEndDate,
    HFA.history_time AS CompleteDate,
    s.SearchId,
    NULL AS CannedNote,
    APD.reason AS AdjTriggerReason,
    'N' AS PackageCompleted10Days,
    0 AS PastDueSearchCount,
    NULL AS FinalAdjudicatorName,
    NULL AS AdjudicationNote,
    NULL AS NeedsReviewAdjudicatorName,
    NULL AS InvitationEmailSent,
    NULL AS PackageProcessed,
    NULL AS DatePlacedIntoNeedReview,
    NULL AS AdjGridId,
    NULL AS AdjGridName
FROM {{ ref('Stg_Serch_Dim') }} s
JOIN {{ source('ACCEL_ABCNEW_RAW', 'journal') }} j 
    ON s.SearchId = j.EntityId
LEFT JOIN (
    SELECT 
        SUM(DOC_FEE) AS DOC_FEE,
        SUM(STATUTORY_FEE) AS STATUTORY_FEE,
        SUM(addl_year_fee) AS ADDITIONAL_YEAR_FEE,
        SUM(COPIES) AS COPIES,
        PackageId AS package_req_id
    FROM {{ ref('Stg_Serch_Dim') }}
    GROUP BY PackageId
) FEES 
    ON FEES.package_req_id = s.PackageId
LEFT JOIN (
    SELECT 
        search_id, 
        history_time, 
        ROW_NUMBER() OVER(PARTITION BY search_id ORDER BY history_id DESC) AS RN
    FROM {{ source('ACCEL_ABCNEW_RAW', 'HISTORY_DETAIL') }}
    WHERE status_Code = 'R' AND history_category = 'ADJ'
) HFA 
    ON HFA.search_id = s.SearchId AND HFA.RN = 1
LEFT JOIN (
    SELECT 
        reason, 
        search_id, 
        adj_value, 
        ROW_NUMBER() OVER (PARTITION BY search_id ORDER BY adj_process_detail_id DESC) AS rw
    FROM {{ source('ACCEL_ABCNEW_RAW', 'ADJ_PROCESS_DETAIL') }}
    WHERE adj_value IS NOT NULL
) APD 
    ON s.SearchId = APD.search_id AND APD.rw = 1
WHERE s.SearchTypeCode='9PK'