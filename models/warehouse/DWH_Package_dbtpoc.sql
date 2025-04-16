{{ config(
    materialized='incremental',
    alias='DWH_Package_DBTPOC',
    unique_key='PackageCode',
    on_schema_change='sync_all_columns'
) }}

WITH staged AS (

    SELECT
        *,
        MD5(TO_JSON(OBJECT_CONSTRUCT(
            'package_code', package_code,
            'pkg_name', pkg_name,
            'pkg_name_short', pkg_name_short,
            'pkg_desc', pkg_desc,
            'pkg_price', pkg_price,
            'pkg_active', pkg_active,
            'allow_ala_carte', allow_ala_carte,
            'init_comp', init_comp,
            'search_type_code', search_type_code,
            'yr_searched', yr_searched,
            'pkg_plus', pkg_plus,
            'no_addl_inof_needed', no_addl_inof_needed,
            'no_fm', no_fm,
            'name_count', name_count,
            'county_count', county_count,
            'ask_conv', ask_conv,
            'MMN_SHOW', MMN_SHOW,
            'ADD_POSITION_LOCATION_SEARCHES', ADD_POSITION_LOCATION_SEARCHES,
            'auto_W2_opt', auto_W2_opt,
            'auto_W2_utv', auto_W2_utv,
            'intl_address_question', intl_address_question,
            'sin_required', sin_required
        ))) AS row_hash
    FROM ACCEL_BI_STG.stg_package_dbtpoc

)

SELECT *
FROM staged

{% if is_incremental() %}
WHERE row_hash NOT IN (
    SELECT MD5(TO_JSON(OBJECT_CONSTRUCT(
        'package_code', package_code,
        'pkg_name', pkg_name,
        'pkg_name_short', pkg_name_short,
        'pkg_desc', pkg_desc,
        'pkg_price', pkg_price,
        'pkg_active', pkg_active,
        'allow_ala_carte', allow_ala_carte,
        'init_comp', init_comp,
        'search_type_code', search_type_code,
        'yr_searched', yr_searched,
        'pkg_plus', pkg_plus,
        'no_addl_inof_needed', no_addl_inof_needed,
        'no_fm', no_fm,
        'name_count', name_count,
        'county_count', county_count,
        'ask_conv', ask_conv,
        'MMN_SHOW', MMN_SHOW,
        'ADD_POSITION_LOCATION_SEARCHES', ADD_POSITION_LOCATION_SEARCHES,
        'auto_W2_opt', auto_W2_opt,
        'auto_W2_utv', auto_W2_utv,
        'intl_address_question', intl_address_question,
        'sin_required', sin_required
    ))) 
    FROM {{ this }}
)
{% endif %}
