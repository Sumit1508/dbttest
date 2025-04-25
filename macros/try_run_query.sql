{% macro try_run_query(sql_statement, error_context, logging_table, run_by, target_table, source_table, merge_key) %}
    {% set result = run_query(sql_statement) %}
    {% if result is none %}
        {% set log_sql %}
            INSERT INTO {{ logging_table }} (
                target_table, source_table, merge_key,
                INSERT_COUNT, UPDATE_COUNT, DELETE_COUNT,
                merge_timestamp, run_by, additional_info
            )
            SELECT
                '{{ target_table }}', '{{ source_table }}', '{{ merge_key }}',
                NULL, NULL, NULL,
                CURRENT_TIMESTAMP(), '{{ run_by }}', '{{ error_context }}'
        {% endset %}
        {{ log("ERROR: " ~ error_context, info=True) }}
        {{ run_query("ROLLBACK;") }}
        {{ run_query(log_sql) }}
        {{ return('FAILED') }}
    {% endif %}
    {{ return('OK') }}
{% endmacro %}
