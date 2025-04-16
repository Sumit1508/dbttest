SELECT *
FROM {{ ref('DWH_Package_DBTPOC') }}
WHERE pkg_price < 0
