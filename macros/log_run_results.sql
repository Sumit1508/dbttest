{% macro log_run_results(results) %}
  {% for r in results %}
    {% if r.status == 'error' %}
      {% set log_sql %}
        INSERT INTO DEV.ACCEL_LOGGINGDB.DBT_MODEL_ERRORS (
          model_name,
          status,
          message,
          run_by,
          run_time
        )
        VALUES (
          '{{ r.node.name }}',
          '{{ r.status }}',
          '{{ r.message | replace("'", "") }}',
          '{{ target.user }}',
          CURRENT_TIMESTAMP()
        )
      {% endset %}
      {% do run_query(log_sql) %}
    {% endif %}
  {% endfor %}
{% endmacro %}
