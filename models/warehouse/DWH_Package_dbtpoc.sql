{{ config(
    materialized='incremental',
    alias='DWH_Package_DBTPOC',
    unique_key='PackageCode',
    on_schema_change='sync_all_columns'
) }}

SELECT *
    FROM ACCEL_BI_STG.stg_package_dbtpoc


{% if is_incremental() %}
  WHERE updated_at >= (SELECT MAX(updated_at) FROM {{ this }})
{% endif %}