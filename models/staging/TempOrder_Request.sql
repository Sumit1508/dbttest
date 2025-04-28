{{ config(
    materialized='incremental',
    pre_hook=[
        "TRUNCATE TABLE {{ this }}"
    ]
) }}

SELECT 
    ORQ.OR_id,
    ORQ.OR_OO_id,
    ORQ.OR_OT_Id,
    ORQ.OR_OM_Id,
    ORQ.OR_Locale_Id,
    ORQ.OR_PackageId,
    ORQ.OR_OrderDate,
    ORQ.OR_ClientRefNum,
    ORQ.OR_CompletionDate,
    ORQ.OR_Status,
    ORQ.OR_ResultSentDate,
    ORQ.OR_OrderInitDate
FROM {{ source('ACCEL_ABCNEW_RAW', 'ORDER_REQUEST') }} ORQ
INNER JOIN {{ ref('Stg_Serch_Dim') }} S 
    ON ORQ.OR_PackageId = S.PackageId
WHERE S.SearchTypeCode = '9PK'
