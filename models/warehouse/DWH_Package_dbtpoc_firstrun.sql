{{ config(
    materialized='table',
    alias='DWH_Package_DBTPOC'
) }}

SELECT *
    FROM ACCEL_BI_STG.stg_package_dbtpoc