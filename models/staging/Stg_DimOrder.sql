SELECT 
    -- '' AS "OrderKey",  -- Uncomment if needed
    OM.OM_Type AS "OrderModeType",
    OM.OM_SubType AS "OrderModeSubType",
    OO.OO_Code AS "OrderOriginCode",
    OO.OO_SubCode AS "OrderOriginSubCode",
    OT.OT_Type AS "OrderType",
    OT.OT_SubType AS "OrderSubType",
    SO.package_req_id AS "PackageID",
    SO.PackageCode,
    SO.OrderDate AS "OrderDate",
    ORQ.OR_ClientRefNum AS "ClientRefNum",
    SO.CompletionDate AS "CompletionDate",
    ST.status AS "Status",
    SO.sub_status AS "SubStatus",
    CAST(ORQ.OR_ResultSentDate AS DATE) AS "ResultSentDate",
    L.language_code AS "LocaleCode",
    CAST(SO.invoice_datetime AS DATE) AS "InvoiceDatetime",
    CAST(SO.not_monthly_invoice_datetime AS DATE) AS "NotMonthlyInvoiceDatetime",
    CAST(SO.researcher_summary_date AS DATE) AS "ResearcherSummaryDate",
    SO.result_note AS "ResultNote",
    SO.status_note AS "StatusNote",
    CAST(SO.email_sent AS DATE) AS "EmailSent",
    ADJ.adj_desc AS "AdjudicationDescription",
    CAST(SO.need_review_email_sent AS DATE) AS "NeedReviewEmailSent",
    CAST(SO.oin_email_sent AS DATE) AS "OINEmailSent",
    SO.pkg_processed AS "PkgProcessed",
    SO.DOC_FEE,
    SO.STATUTORY_FEE,
    SO.addl_year_fee,
    SO.COPIES_FEE,
    0 AS "InsertAuditKey",
    0 AS "UpdateAuditKey",
    CASE 
        WHEN DO.package_id IS NOT NULL THEN 'Disputed'
        ELSE 'Unknown'
    END AS "DisputedStatus",
    CAST(DO.created_on AS DATE) AS "DisputedDate",
    SO.RefNumber2,
    SO.RefNumber3,
    SO.RefNumber4,
    SO.RefNumber5,
    COALESCE(SO.SEARCHID, -1) AS "SEARCHID",
    SO.ABStartDate,
    CASE 
        WHEN DimOdr.ABEndDate IS NOT NULL AND SO.ABEndDate IS NULL THEN DimOdr.ABEndDate
        ELSE SO.ABEndDate
    END AS "ABEndDate",
    CASE 
        WHEN DimOdr.CompleteDate IS NOT NULL AND SO.CompleteDate IS NULL THEN DimOdr.CompleteDate
        ELSE SO.CompleteDate
    END AS "CompleteDate",
    SO.CannedNote,
    EEG6.EAVG_Value AS "ClientRefNum6",
    EEG7.EAVG_Value AS "ClientRefNum7",
    EEG8.EAVG_Value AS "ClientRefNum8",
    EEG9.EAVG_Value AS "ClientRefNum9",
    SO.AdjTriggerReason,
    CASE 
        WHEN DimOdr.PackageCompleted10Days IS NOT NULL AND SO.PackageCompleted10Days = 'N' THEN DimOdr.PackageCompleted10Days
        ELSE COALESCE(SO.PackageCompleted10Days, 'N')
    END AS "PackageCompleted10Days",
    DO.CandidateDisputedName,
    COALESCE(JRNL.PackageReopenInd, 'N') AS "PackageReopenInd",
    JRNL.PackageReopenTime,
    COALESCE(SO.PastDueSearchCount, 0) AS "PastDueSearchCount",
    PLUD.PackageUpdateTime,
    SOC.SearchOrderCount,
    COALESCE(STAJRNL.OINSearchCount, 0) AS "OINSearchCount",
    CASE 
        WHEN oin.IsOIN IS NULL THEN 0
        ELSE 1
    END AS "IsOIN",
    CASE 
        WHEN rn.IsRN IS NULL THEN 0
        ELSE 1
    END AS "IsRN",
    SO.AdjudicationNote,
    CASE 
        WHEN DimOdr.FinalAdjudicatorName IS NOT NULL AND SO.FinalAdjudicatorName IS NULL THEN DimOdr.FinalAdjudicatorName
        ELSE SO.FinalAdjudicatorName
    END AS "FinalAdjudicatorName",
    CASE 
        WHEN DimOdr.NeedsReviewAdjudicatorName IS NOT NULL AND SO.NeedsReviewAdjudicatorName IS NULL THEN DimOdr.NeedsReviewAdjudicatorName
        ELSE SO.NeedsReviewAdjudicatorName
    END AS "NeedsReviewAdjudicatorName",
    COALESCE(
        CASE 
            WHEN DimOdr.NeedsReviewAdjudicatorName IS NOT NULL AND SO.NeedsReviewAdjudicatorName IS NULL THEN DimOdr.NeedsReviewAdjudicatorName
            ELSE SO.NeedsReviewAdjudicatorName
        END, 
        CASE 
            WHEN DimOdr.FinalAdjudicatorName IS NOT NULL AND SO.FinalAdjudicatorName IS NULL THEN DimOdr.FinalAdjudicatorName
            ELSE SO.FinalAdjudicatorName
        END
    ) AS "ABReviewerName",
    CASE 
        WHEN DimOdr.InvitationEmailSent IS NOT NULL AND SO.InvitationEmailSent IS NULL THEN DimOdr.InvitationEmailSent
        ELSE SO.InvitationEmailSent
    END AS "InvitationEmailSent",
    CASE 
        WHEN DimOdr.PackageProcessedDate IS NOT NULL AND SO.PackageProcessed IS NULL THEN DimOdr.PackageProcessedDate
        ELSE SO.PackageProcessed
    END AS "PackageProcessed",
    CASE 
        WHEN DimOdr.DatePlacedIntoNeedReview IS NOT NULL AND SO.DatePlacedIntoNeedReview IS NULL THEN DimOdr.DatePlacedIntoNeedReview
        ELSE SO.DatePlacedIntoNeedReview
    END AS "DatePlacedIntoNeedReview",
    ORQ.OrderInitiationDate,
    SO.adj_grid_id,
    SO.adj_grid_name
FROM 
    {{ ref('TempSearch_Order') }} SO
INNER JOIN 
    ACCEL_ABCNEW_RAW.SEARCH_STATUS ST ON ST.status_code = SO.search_status
LEFT JOIN 
    ACCEL_BI_BR.DWH_DimOrder DimOdr ON DimOdr.PackageID = SO.package_req_id
LEFT JOIN 
    {{ ref('TempOrder_Request') }} ORQ ON ORQ.OR_PackageId = SO.package_req_id
LEFT JOIN 
    ACCEL_ABCNEW_RAW.LOCALE L ON L.id = ORQ.OR_Locale_Id
LEFT JOIN 
    ACCEL_ABCNEW_RAW.ADJ_OPTION ADJ ON ADJ.adj_id = SO.adj_id
LEFT JOIN 
    ACCEL_ABCNEW_RAW.ORDER_MODE OM ON OM.OM_Id = ORQ.OR_OM_id 
LEFT JOIN 
    ACCEL_ABCNEW_RAW.ORDER_ORIGIN OO ON OO.OO_Id = ORQ.OR_OO_id 
LEFT JOIN 
    ACCEL_ABCNEW_RAW.ORDER_TYPE OT ON OT.OT_Id = ORQ.OR_OT_id 
LEFT JOIN 
    ACCEL_ABCNEW_RAW.STG_OR_EAV_ENTITY_GEN EEG6 ON EEG6.EAVG_OR_Id = ORQ.OR_Id 
    AND ORQ.OR_PackageId = SO.package_req_id 
    AND EEG6.EAVG_GA_Id = 56
LEFT JOIN 
    ACCEL_ABCNEW_RAW.STG_OR_EAV_ENTITY_GEN EEG7 ON EEG7.EAVG_OR_Id = ORQ.OR_Id 
    AND ORQ.OR_PackageId = SO.package_req_id 
    AND EEG7.EAVG_GA_Id = 41
LEFT JOIN 
    ACCEL_ABCNEW_RAW.STG_OR_EAV_ENTITY_GEN EEG8 ON EEG8.EAVG_OR_Id = ORQ.OR_Id 
    AND ORQ.OR_PackageId = SO.package_req_id 
    AND EEG8.EAVG_GA_Id = 42
LEFT JOIN 
    ACCEL_ABCNEW_RAW.STG_OR_EAV_ENTITY_GEN EEG9 ON EEG9.EAVG_OR_Id = ORQ.OR_Id 
    AND ORQ.OR_PackageId = SO.package_req_id 
    AND EEG9.EAVG_GA_Id = 44
LEFT JOIN 
    {{ ref('Stg_Pkg_Reopentime_Jrnl') }} JRNL ON JRNL.PkgReqId = SO.package_req_id
LEFT JOIN 
    {{ ref('Stg_Pckg_Last_Update_Dt') }} PLUD ON PLUD.PkgReqId = SO.package_req_id
LEFT JOIN 
    {{ ref('TempSearch_OrderCount') }} SOC ON SOC.package_req_id = SO.package_req_id
LEFT JOIN 
    STG_PKG_STATUS_JRNL STAJRNL ON STAJRNL.PKGREQID = SO.package_req_id 
    AND STAJRNL.VALUETO = 'P5'
LEFT JOIN (
    SELECT 1 AS IsOIN, PkgReqId
    FROM {{ ref('Stg_Pkg_Status_Jrnl') }} sj 
    WHERE sj.ValueTo = 'P5'
) oin ON oin.PkgReqId = SO.package_req_id
LEFT JOIN (
    SELECT 1 AS IsRN, PkgReqId
    FROM {{ ref('Stg_Pkg_Status_Jrnl') }} sj 
    WHERE sj.ValueTo = 'P4'
) rn ON rn.PkgReqId = SO.package_req_id
LEFT JOIN (
    SELECT package_id, created_on, first_name || ' ' || last_name AS CandidateDisputedName
    FROM (
        SELECT 
            package_id, 
            created_on, 
            ROW_NUMBER() OVER (PARTITION BY package_id ORDER BY created_on DESC) AS RNUM 
        FROM ACCEL_ABCNEW_RAW.DISPUTED_ORDER
    ) T
    WHERE RNUM = 1
) DO ON DO.package_id = ORQ.OR_PackageId
WHERE 
    SO.package_req_id IS NOT NULL;
