SELECT *
FROM {{ ref('DWH_Package_dbtpoc') }}
WHERE package_code is  null
