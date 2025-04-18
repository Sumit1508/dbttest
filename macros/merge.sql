{% macro merge_with_logging(target_table, source_table, merge_key, columns_to_update, logging_table='DEV.ACCEL_LOGGINGDB.MERGE_OPERATION_LOGS', run_by='dbt_user') %}

begin;

-- Extract schema from target_table
{% set target_schema = target_table.split('.')[1] %}
{% set target_db = target_table.split('.')[0] %}

-- Generate temp table names (scoped to current schema)
{% set pre_merge_target_temp = target_schema ~ '.PRE_MERGE_TARGET' %}
{% set pre_merge_source_temp = target_schema ~ '.PRE_MERGE_SOURCE' %}

-- Create temp tables to track merge impact
create or replace temp table {{ pre_merge_target_temp }} as
select {{ merge_key }} from {{ target_table }};

create or replace temp table {{ pre_merge_source_temp }} as
select {{ merge_key }} from {{ source_table }};



-- Actual merge logic
merge into {{ target_table }} as target
using {{ source_table }} as source
on target.{{ merge_key }} = source.{{ merge_key }}

when matched then update set
    {% for col in columns_to_update %}
        target.{{ col }} = source.{{ col }}{% if not loop.last %}, {% endif %}
    {% endfor %}

when not matched then insert (
    {{ merge_key }}, {% for col in columns_to_update %}
        {{ col }}{% if not loop.last %}, {% endif %}
    {% endfor %}
) values (
    source.{{ merge_key }}, {% for col in columns_to_update %}
        source.{{ col }}{% if not loop.last %}, {% endif %}
    {% endfor %}
);

-- Insert logging info
insert into {{ logging_table }} (
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
-- Calculate affected row count
with new_rows as (
    select {{ merge_key }} from {{ pre_merge_source_temp }}
    where {{ merge_key }} not in (
        select {{ merge_key }} from {{ pre_merge_target_temp }}
    )
),
updated_rows as (
    select s.{{ merge_key }}
    from {{ source_table }} s
    join {{ target_table }} t
    on s.{{ merge_key }} = t.{{ merge_key }}
    where
        {% for col in columns_to_update %}
            s.{{ col }} is distinct from t.{{ col }}{% if not loop.last %} or {% endif %}
        {% endfor %}
)



select
    '{{ target_table }}',
    '{{ source_table }}',
    '{{ merge_key }}',
    (select count(*) from new_rows),
    (select count(*) from updated_rows),
    0,
    current_timestamp(),
    '{{ run_by }}',
    'Ending Merge';

-- Cleanup temp tables
drop table if exists {{ pre_merge_target_temp }};
drop table if exists {{ pre_merge_source_temp }};
commit;

{% endmacro %}
