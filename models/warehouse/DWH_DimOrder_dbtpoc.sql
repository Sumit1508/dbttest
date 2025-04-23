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
                'NeedReviewEmailSent', 'OINEmailSent', 'PkgProcessed', 'InsertAuditKey',
                'UpdateAuditKey', 'DisputedStatus', 'DisputedDate', 'DOC_FEE', 'STATUTORY_FEE',
                'ADDITIONAL_YEAR_FEE', 'COPIES', 'RefNumber2', 'RefNumber3', 'RefNumber4',
                'RefNumber5', 'SEARCHID', 'ABStartDate', 'ABEndDate', 'CompleteDate',
                'CannedNote', 'AdjTriggerReason', 'PackageCompleted10Days', 'CandidateDisputedName',
                'PackageReopenInd', 'PackageReopenTime', 'PastDueSearchCount', 'ClientRefNum6',
                'ClientRefNum7', 'ClientRefNum8', 'ClientRefNum9', 'SearchOrderCount',
                'OINSearchCount', 'IsOIN', 'IsRN', 'AdjudicationNote', 'FinalAdjudicatorName',
                'NeedsReviewAdjudicatorName', 'ABReviewerName', 'InvitationEmailSent',
                'PackageProcessed', 'DatePlacedIntoNeedReview', 'OR_OrderInitDate',
                'AdjGridId', 'AdjGridName'
            ]
        ) }}"
    ]
) }}


-- Dummy SELECT (only for initial temp view, won't be used during merge)
SELECT *
FROM {{ ref('Stg_DimOrder') }}
WHERE 1 = 0
