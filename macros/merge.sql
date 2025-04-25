{% macro merge_with_logging(target_table, source_table, merge_key, columns_to_update, logging_table='DEV.ACCEL_LOGGINGDB.MERGE_OPERATION_LOGS', run_by='dbt_user') %}
  {% set target_schema = target_table.split('.')[1] %}
  {% set pre_merge_target_temp = target_schema ~ '.PRE_MERGE_TARGET' %}
  {% set pre_merge_source_temp = target_schema ~ '.PRE_MERGE_SOURCE' %}
  {% set merge_failed = false %}
  {% set error_message = '' %}

  {{ log("Starting MERGE process for " ~ target_table, info=True) }}

  {% set begin_tx = run_query("BEGIN;") %}
  {% if begin_tx is none %}
    {{ log("Failed to begin transaction", info=True) }}
    {% set merge_failed = true %}
    {% set error_message = 'BEGIN failed' %}
  {% endif %}

  {% if not merge_failed %}
    {% set prep1 = run_query("CREATE OR REPLACE TEMP TABLE " ~ pre_merge_target_temp ~ " AS SELECT " ~ merge_key ~ " FROM " ~ target_table) %}
    {% if prep1 is none %}
      {% set merge_failed = true %}
      {% set error_message = 'Creating pre_merge_target_temp failed' %}
    {% endif %}
  {% endif %}

  {% if not merge_failed %}
    {% set prep2 = run_query("CREATE OR REPLACE TEMP TABLE " ~ pre_merge_source_temp ~ " AS SELECT " ~ merge_key ~ " FROM " ~ source_table) %}
    {% if prep2 is none %}
      {% set merge_failed = true %}
      {% set error_message = 'Creating pre_merge_source_temp failed' %}
    {% endif %}
  {% endif %}

  {% if not merge_failed %}
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
    {% set merge_result = run_query(merge_sql) %}
    {% if merge_result is none %}
      {% set merge_failed = true %}
      {% set error_message = 'MERGE failed' %}
    {% endif %}
  {% endif %}

  {% if not merge_failed %}
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
    {% set log_result = run_query(log_sql) %}
    {% if log_result is none %}
      {% set merge_failed = true %}
      {% set error_message = 'Logging merge result failed' %}
    {% endif %}
  {% endif %}

  {% if merge_failed %}
    {{ log("ERROR: " ~ error_message, info=True) }}
    {% do run_query("ROLLBACK;") %}
    {% set error_log %}
    INSERT INTO {{ logging_table }} (
      target_table, source_table, merge_key,
      INSERT_COUNT, UPDATE_COUNT, DELETE_COUNT,
      merge_timestamp, run_by, additional_info
    )
    SELECT
      '{{ target_table }}', '{{ source_table }}', '{{ merge_key }}',
      NULL, NULL, NULL,
      CURRENT_TIMESTAMP(),
      '{{ run_by }}',
      '{{ error_message }}'
    {% endset %}
    {% do run_query(error_log) %}
  {% else %}
    {% do run_query("DROP TABLE IF EXISTS " ~ pre_merge_target_temp) %}
    {% do run_query("DROP TABLE IF EXISTS " ~ pre_merge_source_temp) %}
    {% do run_query("COMMIT;") %}
    {{ log("MERGE process completed and committed for " ~ target_table, info=True) }}
  {% endif %}

{% endmacro %}
