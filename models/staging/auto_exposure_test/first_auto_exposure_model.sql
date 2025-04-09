{{ config(materialized='table') }}

-- updating the range will increase the number of rows in the table, 
-- making it possible to check whether the rebuilt table is flowing through to the downstream exposure
{% for i in range(10) %}

    select {{ i }} as number,
    getdate() as model_built_at,
    {{ env_var('DBT_CLOUD_RUN_ID', -1) }} as dbt_cloud_run_id,

    {{ dbt_utils.generate_surrogate_key(['number', 'model_built_at', 'dbt_cloud_run_id']) }} as unique_key

    {% if not loop.last %}
        union all 
    {% endif %}
    
{% endfor %}