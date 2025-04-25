{{ config(
    materialized='incremental',
    unique_key='PackageID',
    alias='DWH_DimOrder',
    on_schema_change='sync_all_columns',
    post_hook=[
        "{{ merge_with_logging(
            'DEV.ACCEL_BI_BR.DWH_DimOrder',
            'DEV.ACCEL_BI_STG.Stg_DimOrder',
            'PackageID',
            [
                'OrderModeType', 'OrderModeSubType', 'OrderOriginCode', 'OrderOriginSubCode',
                'OrderType', 'OrderSubType', 'OrderDate', 'ClientRefNum',
                'CompletionDate', 'Status', 'SubStatus', 'ResultSentDate',
                'InvoiceDatetime', 'NotMonthlyInvoiceDatetime', 'ResearcherSummaryDate',
                'ResultNote', 'StatusNote', 'EmailSent', 'AdjudicationDescription',
                'NeedReviewEmailSent', 'OINEmailSent', 'PkgProcessed', 'DOC_FEE', 'STATUTORY_FEE',
                'ADDITIONAL_YEAR_FEE', 'COPIES', 'InsertAuditKey', 'UpdateAuditKey',
                'DisputedStatus', 'DisputedDate', 'RefNumber2', 'RefNumber3', 'RefNumber4',
                'RefNumber5', 'SEARCHID', 'ABStartDate', 'ABEndDate', 'CompleteDate',
                'CannedNote', 'ClientRefNum6', 'ClientRefNum7', 'ClientRefNum8', 'ClientRefNum9',
                'AdjTriggerReason', 'PackageCompleted10Days', 'CandidateDisputedName',
                'PackageReopenInd', 'PackageReopenTime', 'PastDueSearchCount', 'PackageUpdateTime',
                'SearchOrderCount', 'OINSearchCount', 'IsOIN', 'IsRN', 'AdjudicationNote',
                'FinalAdjudicatorName', 'NeedsReviewAdjudicatorName', 'ABReviewerName',
                'InvitationEmailSent', 'PackageProcessed', 'DatePlacedIntoNeedReview',
                'OR_OrderInitDate', 'AdjGridId', 'AdjGridName'
            ]
        ) }}"
        ,
        "INSERT INTO ACCEL_LOGGINGDB.load_audit_log (model_name, last_run_timestamp) "
        "SELECT 'Stg_Serch_Dim', COALESCE(MAX(last_update_date), '1900-01-01') FROM ACCEL_BI_STG.Stg_Serch_Dim"
    ]
) }}

-- Dummy SELECT (only for initial temp view, won't be used during merge)
SELECT *
FROM {{ ref('Stg_DimOrder') }}
WHERE 1 = 0
