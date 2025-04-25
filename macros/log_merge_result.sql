{% macro log_merge_result(model_name, status, message) %}
    {% set sql %}
        insert into DEV.ACCEL_LOGGINGDB.MERGE_OPERATION_LOGS (
            target_table,
            source_table,
            merge_key,
            INSERT_COUNT,
            UPDATE_COUNT,
            DELETE_COUNT,
            merge_timestamp,
            run_by,
            additional_info
        )
        values (
            '{{ model_name }}',
            null,
            null,
            0,
            0,
            0,
            current_timestamp(),
            '{{ target.name }}',
            '{{ status }}: {{ message | replace("'", "''") }}'
        )
    {% endset %}
    {% do run_query(sql) %}
{% endmacro %}
