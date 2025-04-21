{{ config(
    materialized='incremental',
    unique_key='PackageID',
    alias='DWH_DimOrder',
    on_schema_change='sync_all_columns',
    post_hook=[
        "{{ merge_with_logging(
            'DEV.ACCEL_BI_BR.DWH_DimOrder_dbtpoc',
            'DEV.ACCEL_BI_STG.Stg_DimOrder',
            'PackageID',
            [
                'OrderModeType', 'OrderModeSubType', 'OrderOriginCode', 'OrderOriginSubCode',
                'OrderType', 'OrdeSubType', 'PackageCode', 'OrderDate', 'ClientRefNum',
                'CompletionDate', 'Status', 'SubStatus', 'ResultSentDate', 'LocaleCode',
                'InvoiceDatetime', 'NotMonthlyInvoiceDatetime', 'ResearcherSummaryDate',
                'ResultNote', 'StatusNote', 'EmailSent', 'AdjudicationDescription',
                'NeedReviewEmailSent', 'OINEmailSent', 'PkgProcessed', 'InsertAuditKey',
                'UpdateAuditKey', 'DisputedStatus', 'DisputedDate', 'DOC_FEE', 'STATUTORY_FEE',
                'addl_year_fee', 'COPIES_FEE', 'RefNumber2', 'RefNumber3', 'RefNumber4',
                'RefNumber5', 'SEARCHID', 'ABStartDate', 'ABEndDate', 'CompleteDate',
                'CannedNote', 'AdjTriggerReason', 'PackageCompleted10Days', 'CandidateDisputedName',
                'PackageReopenInd', 'PackageReopenTime', 'PastDueSearchCount', 'ClientRefNum6',
                'ClientRefNum7', 'ClientRefNum8', 'ClientRefNum9', 'SearchOrderCount',
                'OINSearchCount', 'IsOIN', 'IsRN', 'AdjudicationNote', 'FinalAdjudicatorName',
                'NeedsReviewAdjudicatorName', 'ABReviewerName', 'InvitationEmailSent',
                'PackageProcessedDate', 'DatePlacedIntoNeedReview', 'OrderInitiationDate',
                'adj_grid_id', 'adj_grid_name','PackageKey'
            ]
        ) }}"
    ]
) }}


-- Dummy SELECT (only for initial temp view, won't be used during merge)
SELECT *
FROM {{ ref('Stg_DimOrder') }}
WHERE 1 = 0
