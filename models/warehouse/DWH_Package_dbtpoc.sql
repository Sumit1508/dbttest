{{ config(
    materialized='incremental',
    alias='DWH_Package_DBTPOC',
    unique_key='package_code',
    on_schema_change='sync_all_columns'
) }}

{% if is_incremental() %}

    {{ merge_into(
        target_table = 'DEV.ACCEL_BI_BR.DWH_Package_DBTPOC',
        source_table = ref('Stg_Package_dbtpoc'),
        unique_key = 'package_code',
        update_columns = [
            'pkg_name', 'pkg_name_short', 'pkg_desc', 'pkg_price',
            'pkg_active', 'allow_ala_carte', 'init_comp', 'search_type_code',
            'yr_searched', 'pkg_plus', 'no_addl_inof_needed', 'no_fm',
            'name_count', 'county_count', 'ask_conv', 'MMN_SHOW',
            'ADD_POSITION_LOCATION_SEARCHES', 'auto_W2_opt', 'auto_W2_utv',
            'intl_address_question', 'sin_required'
        ],
        insert_columns = [
            'package_code', 'pkg_name', 'pkg_name_short', 'pkg_desc', 'pkg_price',
            'pkg_active', 'allow_ala_carte', 'init_comp', 'search_type_code',
            'yr_searched', 'pkg_plus', 'no_addl_inof_needed', 'no_fm',
            'name_count', 'county_count', 'ask_conv', 'MMN_SHOW',
            'ADD_POSITION_LOCATION_SEARCHES', 'auto_W2_opt', 'auto_W2_utv',
            'intl_address_question', 'sin_required'
        ]
    ) }}

{% else %}

    SELECT *
    FROM {{ ref('Stg_Package_dbtpoc') }}

{% endif %}
