SELECT 
    PkgReqId, 
    MAX(PackageUpdateTime) AS PackageUpdateTime
FROM (
    SELECT  
        CASE 
            WHEN j.PkgReqId IS NULL THEN s.PackageId 
            ELSE j.PkgReqId 
        END AS PkgReqId,
        j.entereddate AS PackageUpdateTime
    FROM {{ source('ACCEL_ABCNEW_RAW', 'journal') }} j
    INNER JOIN {{ ref('Stg_Serch_Dim') }} s 
        ON s.SearchId = j.EntityId
    WHERE j.EntityName = 'Search'
) T
GROUP BY PkgReqId
