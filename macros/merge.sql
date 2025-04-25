{% macro merge_with_logging(target_table, source_table, merge_key, columns_to_update, logging_table='DEV.ACCEL_LOGGINGDB.MERGE_OPERATION_LOGS', run_by='dbt_user') %}
  {% set target_schema = target_table.split('.')[1] %}
  {% set pre_merge_target_temp = target_schema ~ '.PRE_MERGE_TARGET' %}
  {% set pre_merge_source_temp = target_schema ~ '.PRE_MERGE_SOURCE' %}

  {{ log(" Starting MERGE for: " ~ target_table, info=True) }}

  {% if try_run_query("BEGIN;", "BEGIN transaction failed", logging_table, run_by, target_table, source_table, merge_key) == 'FAILED' %}{{ return('') }}{% endif %}

  {% if try_run_query("CREATE OR REPLACE TEMP TABLE " ~ pre_merge_target_temp ~ " AS SELECT " ~ merge_key ~ " FROM " ~ target_table, "Creating PRE_MERGE_TARGET failed", logging_table, run_by, target_table, source_table, merge_key) == 'FAILED' %}{{ return('') }}{% endif %}

  {% if try_run_query("CREATE OR REPLACE TEMP TABLE " ~ pre_merge_source_temp ~ " AS SELECT " ~ merge_key ~ " FROM " ~ source_table, "Creating PRE_MERGE_SOURCE failed", logging_table, run_by, target_table, source_table, merge_key) == 'FAILED' %}{{ return('') }}{% endif %}

  {% set merge_sql %}
    MERGE INTO {{ target_table }} AS target
    USING {{ source_table }} AS source
    ON target.{{ merge_key }} = source.{{ merge_key }}
    WHEN MATCHED THEN UPDATE SET
      {% for col in columns_to_update %}
        target.{{ col }} = source.{{ col }}{% if not loop.last %}, {% endif %}
      {% endfor %}
    WHEN NOT MATCHED THEN INSERT (
      {{ merge_key }}, {% for col in columns_to_update %}
        {{ col }}{% if not loop.last %}, {% endif %}
      {% endfor %}
    ) VALUES (
      source.{{ merge_key }}, {% for col in columns_to_update %}
        source.{{ col }}{% if not loop.last %}, {% endif %}
      {% endfor %}
    )
  {% endset %}

  {% if try_run_query(merge_sql, "MERGE statement failed", logging_table, run_by, target_table, source_table, merge_key) == 'FAILED' %}{{ return('') }}{% endif %}

  {% set log_sql %}
    INSERT INTO {{ logging_table }} (
      target_table, source_table, merge_key,
      INSERT_COUNT, UPDATE_COUNT, DELETE_COUNT,
      merge_timestamp, run_by, additional_info
    )
    WITH new_rows AS (
      SELECT {{ merge_key }} FROM {{ pre_merge_source_temp }}
      WHERE {{ merge_key }} NOT IN (SELECT {{ merge_key }} FROM {{ pre_merge_target_temp }})
    ),
    updated_rows AS (
      SELECT s.{{ merge_key }}
      FROM {{ source_table }} s
      JOIN {{ target_table }} t ON s.{{ merge_key }} = t.{{ merge_key }}
      WHERE {% for col in columns_to_update %}
        s.{{ col }} IS DISTINCT FROM t.{{ col }}{% if not loop.last %} OR {% endif %}
      {% endfor %}
    )
    SELECT
      '{{ target_table }}',
      '{{ source_table }}',
      '{{ merge_key }}',
      (SELECT COUNT(*) FROM new_rows),
      (SELECT COUNT(*) FROM updated_rows),
      0,
      CURRENT_TIMESTAMP(),
      '{{ run_by }}',
      'Merge completed successfully'
  {% endset %}

  {% if try_run_query(log_sql, "Logging merge impact failed", logging_table, run_by, target_table, source_table, merge_key) == 'FAILED' %}{{ return('') }}{% endif %}

  {% do run_query("DROP TABLE IF EXISTS " ~ pre_merge_target_temp) %}
  {% do run_query("DROP TABLE IF EXISTS " ~ pre_merge_source_temp) %}
  {% do run_query("COMMIT;") %}
  {{ log(" MERGE completed and committed for: " ~ target_table, info=True) }}

{% endmacro %}
