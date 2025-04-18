{{ config(
    materialized='incremental',
    alias='DWH_Package_DBTPOC',
    unique_key='package_code',
    on_schema_change='sync_all_columns',
    post_hook=[ 
        """
        -- Perform the MERGE operation
        BEGIN;

        -- Create temporary variables for the inserted and updated row counts
        DECLARE inserted_rows INT DEFAULT 0;
        DECLARE updated_rows INT DEFAULT 0;

        -- Perform the MERGE operation
        MERGE INTO DEV.ACCEL_BI_BR.DWH_Package_DBTPOC AS target
        USING DEV.ACCEL_BI_STG.Stg_Package_dbtpoc AS source
        ON target.package_code = source.package_code

        WHEN MATCHED THEN 
            UPDATE SET 
                target.pkg_name = source.pkg_name,
                target.pkg_name_short = source.pkg_name_short,
                target.pkg_desc = source.pkg_desc,
                target.pkg_price = source.pkg_price,
                target.pkg_active = source.pkg_active,
                target.allow_ala_carte = source.allow_ala_carte,
                target.init_comp = source.init_comp,
                target.search_type_code = source.search_type_code,
                target.yr_searched = source.yr_searched,
                target.pkg_plus = source.pkg_plus,
                target.no_addl_inof_needed = source.no_addl_inof_needed,
                target.no_fm = source.no_fm,
                target.name_count = source.name_count,
                target.county_count = source.county_count,
                target.ask_conv = source.ask_conv,
                target.MMN_SHOW = source.MMN_SHOW,
                target.ADD_POSITION_LOCATION_SEARCHES = source.ADD_POSITION_LOCATION_SEARCHES,
                target.auto_W2_opt = source.auto_W2_opt,
                target.auto_W2_utv = source.auto_W2_utv,
                target.intl_address_question = source.intl_address_question,
                target.sin_required = source.sin_required;

        -- Store the count of updated rows
        LET updated_rows = (SELECT COUNT(*) FROM DEV.ACCEL_BI_BR.DWH_Package_DBTPOC 
                            WHERE package_code IN (SELECT package_code FROM DEV.ACCEL_BI_STG.Stg_Package_dbtpoc));

        WHEN NOT MATCHED THEN
            INSERT (package_code, pkg_name, pkg_name_short, pkg_desc, pkg_price, pkg_active, 
                    allow_ala_carte, init_comp, search_type_code, yr_searched, pkg_plus, 
                    no_addl_inof_needed, no_fm, name_count, county_count, ask_conv, MMN_SHOW, 
                    ADD_POSITION_LOCATION_SEARCHES, auto_W2_opt, auto_W2_utv, intl_address_question, 
                    sin_required)
            VALUES (source.package_code, source.pkg_name, source.pkg_name_short, source.pkg_desc, 
                    source.pkg_price, source.pkg_active, source.allow_ala_carte, source.init_comp, 
                    source.search_type_code, source.yr_searched, source.pkg_plus, source.no_addl_inof_needed, 
                    source.no_fm, source.name_count, source.county_count, source.ask_conv, source.MMN_SHOW, 
                    source.ADD_POSITION_LOCATION_SEARCHES, source.auto_W2_opt, source.auto_W2_utv, 
                    source.intl_address_question, source.sin_required);

        -- Store the count of inserted rows
        LET inserted_rows = (SELECT COUNT(*) FROM DEV.ACCEL_BI_STG.Stg_Package_dbtpoc
                              WHERE package_code NOT IN (SELECT package_code FROM DEV.ACCEL_BI_BR.DWH_Package_DBTPOC));

        -- Commit the transaction
        COMMIT;

        -- Log the affected rows
        INSERT INTO DEV.ACCEL_LOGGINGDB.MERGE_OPERATION_LOGS (
            target_table,
            source_table,
            merge_key,
            operation_type,
            affected_row_count,
            merge_timestamp,
            run_by,
            additional_info
        )
        VALUES
        ('DEV.ACCEL_BI_BR.DWH_Package_DBTPOC',  -- Target table
         'DEV.ACCEL_BI_STG.Stg_Package_dbtpoc',  -- Source table
         'package_code',                         -- Merge key
         'Insert/Update',                        -- Operation type
         inserted_rows + updated_rows,          -- Total affected row count
         CURRENT_TIMESTAMP,                     -- Merge timestamp
         'dbt_user',                            -- Run by (this could be dynamic if needed)
         NULL);                                 -- Additional info (optional)
        """
    ]
) }}

SELECT
    package_code,
    pkg_name,
    pkg_name_short,
    pkg_desc,
    pkg_price,
    pkg_active,
    allow_ala_carte,
    init_comp,
    search_type_code,
    yr_searched,
    pkg_plus,
    no_addl_inof_needed,
    no_fm,
    name_count,
    county_count,
    ask_conv,
    MMN_SHOW,
    ADD_POSITION_LOCATION_SEARCHES,
    auto_W2_opt,
    auto_W2_utv,
    intl_address_question,
    sin_required
FROM {{ ref('Stg_Package_dbtpoc') }}
