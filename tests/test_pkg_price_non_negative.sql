SELECT *
FROM {{ ref('DWH_Package_dbtpoc') }}
WHERE pkg_price < 0
