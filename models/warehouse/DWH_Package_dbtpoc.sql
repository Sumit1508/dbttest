{{ config(
    materialized='incremental',
    alias='DWH_Package_DBTPOC',
    unique_key='package_code',
    on_schema_change='sync_all_columns'
    
) }}


SELECT * 
FROM {{ ref('Stg_Package_dbtpoc') }}
