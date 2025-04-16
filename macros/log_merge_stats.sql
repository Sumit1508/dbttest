{% macro log_merge_stats(model_name) %}
    {% if execute %}
        {% set merge_stats = adapter.get_incremental_insert_rows() %}
        {% set full_model_name = model_name or this.name %}

        insert into your_logging_schema.merge_log_table (
            model_name,
            rows_inserted,
            rows_updated,
            run_timestamp
        ) values (
            '{{ full_model_name }}',
            {{ merge_stats.get('inserted', 0) }},
            {{ merge_stats.get('updated', 0) }},
            current_timestamp()
        );
    {% endif %}
{% endmacro %}
