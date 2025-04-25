{% macro merge_with_logging(
    target_table,
    source_table,
    merge_key,
    columns_to_update,
    logging_table='DEV.ACCEL_LOGGINGDB.MERGE_OPERATION_LOGS',
    run_by='dbt_user'
) %}

  {% set target_schema = target_table.split('.')[1] %}
  {% set target_db = target_table.split('.')[0] %}

  {% set pre_merge_target_temp = target_schema ~ '.PRE_MERGE_TARGET' %}
  {% set pre_merge_source_temp = target_schema ~ '.PRE_MERGE_SOURCE' %}

  {% set begin_txn = run_query("BEGIN;") %}
  {% if begin_txn is none %}
    {% do log_merge_error(logging_table, run_by, target_table, source_table, merge_key, "BEGIN transaction failed") %}
    {{ return('') }}
  {% endif %}

  {% if run_query("CREATE OR REPLACE TEMP TABLE " ~ pre_merge_target_temp ~ " AS SELECT " ~ merge_key ~ " FROM " ~ target_table) is none %}
    {% do log_merge_error(logging_table, run_by, target_table, source_table, merge_key, "Creating PRE_MERGE_TARGET failed") %}
    {{ return('') }}
  {% endif %}

  {% if run_query("CREATE OR REPLACE TEMP TABLE " ~ pre_merge_source_temp ~ " AS SELECT " ~ merge_key ~ " FROM " ~ source_table) is none %}
    {% do log_merge_error(logging_table, run_by, target_table, source_table, merge_key, "Creating PRE_MERGE_SOURCE failed") %}
    {{ return('') }}
  {% endif %}

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

  {% if run_query(merge_sql) is none %}
    {% do log_merge_error(logging_table, run_by, target_table, source_table, merge_key, "MERGE statement failed") %}
    {{ return('') }}
  {% endif %}

  {% set log_sql %}
    INSERT INTO {{ logging_table }} (
      target_table, source_table, merge_key,
      INSERT_COUNT, UPDATE_COUNT, DELETE_COUNT,
      merge_timestamp, run_by, additional_info
    )
    WITH new_rows AS (
      SELECT {{ merge_key }} FROM {{ pre_merge_source_temp }}
      WHERE {{ merge_key }} NOT IN (
        SELECT {{ merge_key }} FROM {{ pre_merge_target_temp }}
      )
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

  {% if run_query(log_sql) is none %}
    {% do log_merge_error(logging_table, run_by, target_table, source_table, merge_key, "Logging merge impact failed") %}
    {{ return('') }}
  {% endif %}

  {% do run_query("DROP TABLE IF EXISTS " ~ pre_merge_target_temp) %}
  {% do run_query("DROP TABLE IF EXISTS " ~ pre_merge_source_temp) %}
  {% do run_query("COMMIT;") %}

{% endmacro %}
