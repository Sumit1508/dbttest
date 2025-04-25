{% macro log_merge_error(logging_table, run_by, target_table, source_table, merge_key, error_message) %}
  {% set error_log %}
    INSERT INTO {{ logging_table }} (
      target_table, source_table, merge_key,
      INSERT_COUNT, UPDATE_COUNT, DELETE_COUNT,
      merge_timestamp, run_by, additional_info
    ) VALUES (
      '{{ target_table }}',
      '{{ source_table }}',
      '{{ merge_key }}',
      0, 0, 0,
      CURRENT_TIMESTAMP(),
      '{{ run_by }}',
      '{{ error_message | replace("'", "") }}'
    )
  {% endset %}
  {{ log("❌ Error logged: " ~ error_message, info=True) }}
  {% do run_query(error_log) %}
{% endmacro %}
