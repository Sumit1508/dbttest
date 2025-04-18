{{ config(
    materialized='incremental',
    unique_key='package_code',
    alias='DWH_Package_DBTPOC',
    on_schema_change='sync_all_columns',
    post_hook=[
        merge_with_logging(
            'DEV.ACCEL_BI_BR.DWH_Package_DBTPOC',
            'DEV.ACCEL_BI_STG.Stg_Package_dbtpoc',
            'package_code',
            [
                'pkg_name', 'pkg_name_short', 'pkg_desc', 'pkg_price', 'pkg_active',
                'allow_ala_carte', 'init_comp', 'search_type_code', 'yr_searched', 'pkg_plus',
                'no_addl_inof_needed', 'no_fm', 'name_count', 'county_count', 'ask_conv',
                'MMN_SHOW', 'ADD_POSITION_LOCATION_SEARCHES', 'auto_W2_opt', 'auto_W2_utv',
                'intl_address_question', 'sin_required'
            ]
        )
    ],
    on_error="on_error_handling"
) }}

-- Dummy SELECT (only for initial temp view, won't be used during merge)
SELECT *
FROM {{ ref('Stg_Package_dbtpoc') }}
WHERE 1 = 0
