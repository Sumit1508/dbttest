WITH base_journal AS (
    SELECT 
        j.EntityId, 
        CASE 
            WHEN j.PkgReqId IS NULL THEN s.PackageId 
            ELSE j.PkgReqId 
        END AS PkgReqId,
        j.ValueTo
    FROM {{ source('ACCEL_ABCNEW_RAW', 'journal') }} j
    INNER JOIN {{ ref('Stg_Serch_Dim') }} s 
        ON s.SearchId = j.EntityId
    WHERE j.EntityName = 'Search'
      AND j.ValueTo IN ('P4', 'P5')
)

SELECT 
    PkgReqId,
    CAST(ValueTo AS STRING) AS ValueTo,
    COUNT(PkgReqId) AS OINSearchCount
FROM base_journal
GROUP BY PkgReqId, ValueTo