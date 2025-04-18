{% macro on_error_handling() %}
    {%- set error_message = "An error occurred during model execution." -%}
    {%- set model_name = this.name -%}
    {%- set run_by = 'dbt_user' -%}
    {%- set logging_table = 'DEV.ACCEL_LOGGINGDB.MERGE_OPERATION_LOGS' -%}

    insert into {{ logging_table }} (
        model_name,
        run_by,
        error_message,
        error_timestamp
    )
    values (
        '{{ model_name }}',
        '{{ run_by }}',
        '{{ error_message }}',
        current_timestamp()
    );

    {% do log("Error handled and logged", info=True) %}
{% endmacro %}
