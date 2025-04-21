SELECT 
    COUNT(1) AS SearchOrderCount,
    PackageId AS package_req_id
FROM {{ ref('Stg_Serch_Dim') }} s
WHERE s.Status != 'Cancelled'
GROUP BY PackageId

