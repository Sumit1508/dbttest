{% macro merge_into(target_table, source_table, unique_key, update_columns, insert_columns) %}

    MERGE INTO {{ target_table }} AS target
    USING {{ source_table }} AS source
    ON target.{{ unique_key }} = source.{{ unique_key }}

    WHEN MATCHED THEN UPDATE SET
        {% for col in update_columns %}
            target.{{ col }} = source.{{ col }}{% if not loop.last %}, {% endif %}
        {% endfor %}

    WHEN NOT MATCHED THEN INSERT (
        {% for col in insert_columns %}
            {{ col }}{% if not loop.last %}, {% endif %}
        {% endfor %}
    )
    VALUES (
        {% for col in insert_columns %}
            source.{{ col }}{% if not loop.last %}, {% endif %}
        {% endfor %}
    );

{% endmacro %}
