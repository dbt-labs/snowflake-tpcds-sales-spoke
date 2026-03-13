{%- materialization transient_table, adapter='snowflake' -%}

  {%- set target_relation = this.incorporate(type='table') -%}
  {%- set existing_relation = load_cached_relation(this) -%}

  {% if existing_relation is not none %}
    {{ adapter.drop_relation(existing_relation) }}
  {% endif %}

  {% call statement('main') -%}
    create or replace transient table {{ target_relation }} as (
      {{ sql }}
    )
  {%- endcall %}

  {{ return({'relations': [target_relation]}) }}

{%- endmaterialization -%}
