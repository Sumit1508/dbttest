-- 1. Insert Data into TempSEARCH_ORDER

SELECT 
    CASE 
        WHEN j.PkgReqId IS NULL THEN s.PackageId 
        ELSE j.PkgReqId 
    END AS PackageId,  
    s.StatusCode AS StatusCode,  -- Updated from 'search_status'
    s.SubStatus AS SubStatus,  -- Updated from 'sub_status'
    s.InvoiceDatetime AS InvoiceDatetime,  -- Updated from 'invoice_datetime'
    s.NotMonthlyInvoiceDatetime,  -- Updated from 'not_monthly_invoice_datetime'
    s.ResearcherSummaryDate,  -- Updated from 'researcher_summary_date'
    s.ResultNote,  -- Updated from 'result_note'
    s.StatusNote,  -- Updated from 'status_note'
    s.email_sent,  -- Updated from 'email_sent'
    s.need_review_email_sent,  -- Updated from 'need_review_email_sent'
    s.oin_email_sent ,  -- Updated from 'oin_email_sent'
    s.pkg_processed,  -- Updated from 'pkg_processed'
    s.adj_id ,  -- Updated from 'adj_id'
    s.CompletionDate,  -- Updated from 'return_datetime'
    s.OrderDate,  -- Updated from 'order_datetime'
    FEES.DOC_FEE ,  -- Updated from 'DOC_FEE'
    FEES.STATUTORY_FEE ,  -- Updated from 'STATUTORY_FEE'
    FEES.ADDITIONAL_YEAR_FEE,  -- Updated from 'addl_year_fee'
    FEES.COPIES ,  -- Updated from 'COPIES'
    s.RefNumber2 ,  -- Updated from 'ref_number2'
    s.RefNumber3 ,  -- Updated from 'ref_number3'
    s.RefNumber4 ,  -- Updated from 'ref_number4'
    s.RefNumber5 ,  -- Updated from 'ref_number5'
    s.OrderDate AS ABStartDate,  -- Updated from 'ab_start_date'
    NULL AS ABEndDate,  -- Updated from 'ab_end_date'
    HFA.history_time AS CompleteDate,  -- Updated from 'history_time'
    s.SearchId,  -- Updated from 'search_id'
    NULL as CannedNote ,  -- Updated from 'canned_note'
    APD.reason as AdjTriggerReason ,  -- Updated from 'adj_trigger_reason'
    'N' AS PackageCompleted10Days,  -- Updated from 'package_completed_10_days'
    0 AS PastDueSearchCount,  -- Updated from 'past_due_search_count'
    NULL AS FinalAdjudicatorName,  -- Updated from 'final_adjudicator_name'
    NULL AS AdjudicationNote,  -- Updated from 'adjudication_note'
    NULL AS NeedsReviewAdjudicatorName,  -- Updated from 'needs_review_adjudicator_name'
    NULL AS InvitationEmailSent,  -- Updated from 'invitation_email_sent'
    NULL AS PackageProcessed,  -- Updated from 'package_processed'
    NULL AS DatePlacedIntoNeedReview,  -- Updated from 'date_placed_into_need_review'
    NULL AS AdjGridId,  -- Updated from 'adj_grid_id'
    NULL AS AdjGridName  -- Updated from 'adj_grid_name'
FROM {{ ref('Stg_Serch_Dim') }} s  -- Use ref() to reference the Stg_Serch_Dim model
JOIN {{ source('ACCEL_ABCNEW_RAW', 'journal') }} j ON s.SearchId = j.EntityId
LEFT JOIN (
    SELECT 
        SUM(DOC_FEE) AS DOC_FEE,
        SUM(STATUTORY_FEE) AS STATUTORY_FEE,
        SUM(addl_year_fee) AS ADDITIONAL_YEAR_FEE,
        SUM(COPIES) AS COPIES,
        PackageId AS package_req_id
    FROM {{ ref('Stg_Serch_Dim') }}  -- Use ref() for Stg_Serch_Dim here as well
    GROUP BY PackageId
) FEES ON FEES.package_req_id = s.PackageId
LEFT JOIN (
    SELECT search_id, history_time, ROW_NUMBER() OVER(PARTITION BY search_id ORDER BY history_id DESC) AS RN
    FROM {{ source('ACCEL_ABCNEW_RAW', 'HISTORY_DETAIL') }} h
    WHERE h.status_Code = 'R' AND h.history_category = 'ADJ'
) HFA ON HFA.search_id = s.SearchId AND HFA.RN = 1
LEFT JOIN (
    SELECT reason, search_id, adj_value, ROW_NUMBER() OVER (PARTITION BY search_id ORDER BY adj_process_detail_id DESC) AS rw
    FROM {{ source('ACCEL_ABCNEW_RAW', 'ADJ_PROCESS_DETAIL') }}
    WHERE adj_value IS NOT NULL
) APD ON s.SearchId = APD.search_id AND APD.rw = 1
