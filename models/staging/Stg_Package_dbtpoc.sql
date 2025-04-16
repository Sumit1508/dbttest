SELECT 
    CAST(package_code AS INT) AS package_code,
    CAST(pkg_name AS STRING) AS pkg_name,
    CAST(pkg_name_short AS STRING) AS pkg_name_short,
    CAST(pkg_desc AS STRING) AS pkg_desc,
    pkg_price,
    pkg_active,
    allow_ala_carte,
    CAST(init_comp AS STRING) AS init_comp,
    CAST(search_type_code AS STRING) AS search_type_code,
    CAST(yr_searched AS STRING) AS yr_searched,
    CAST(CASE UPPER(pkg_plus) WHEN 'Y' THEN TRUE ELSE FALSE END AS BOOLEAN) AS pkg_plus,
    CAST(CASE UPPER(no_addl_inof_needed) WHEN 'Y' THEN TRUE ELSE FALSE END AS BOOLEAN) AS no_addl_inof_needed,  
    no_fm,
    name_count,
    county_count,
    ask_conv,
    CAST(CASE UPPER(MMN_SHOW) WHEN 'Y' THEN TRUE ELSE FALSE END AS BOOLEAN) AS MMN_SHOW,
    CAST(CASE UPPER(ADD_POSITION_LOCATION_SEARCHES) WHEN 'Y' THEN TRUE ELSE FALSE END AS BOOLEAN) AS ADD_POSITION_LOCATION_SEARCHES,
    CAST(CASE UPPER(auto_W2_opt) WHEN 'Y' THEN TRUE ELSE FALSE END AS BOOLEAN) AS auto_W2_opt,
    CAST(CASE UPPER(auto_W2_utv) WHEN 'Y' THEN TRUE ELSE FALSE END AS BOOLEAN) AS auto_W2_utv,
    CAST(CASE UPPER(intl_address_question) WHEN 'Y' THEN TRUE ELSE FALSE END AS BOOLEAN) AS intl_address_question,
    CAST(CASE UPPER(sin_required) WHEN 'Y' THEN TRUE ELSE FALSE END AS BOOLEAN) AS sin_required

FROM {{ source('ACCEL_ABCNEW_RAW', 'package') }}

