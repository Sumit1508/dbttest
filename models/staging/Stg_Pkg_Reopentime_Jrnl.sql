SELECT 
    CASE 
        WHEN j.PkgReqId IS NULL THEN s.PackageId 
        ELSE j.PkgReqId 
    END AS PkgReqId,

    j.entereddate AS PackageReopenTime,

    CAST('Y' AS STRING) AS PackageReopenInd

FROM {{ source('ACCEL_ABCNEW_RAW', 'journal') }} j
INNER JOIN {{ ref('Stg_Serch_Dim') }} s
    ON s.SearchId = j.EntityId

WHERE 
    j.logaction = 'pkg-reopen'
    AND j.EntityName = 'Search'
    AND j.id = (
        SELECT MAX(j2.id)
        FROM {{ source('ACCEL_ABCNEW_RAW', 'journal') }} j2
        WHERE j2.EntityId = j.EntityId 
          AND j2.logaction = 'pkg-reopen'
    )
