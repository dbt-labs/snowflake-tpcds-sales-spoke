-- models/model_b.sql

{{ config(materialized = 'table') }}

select
    {{ function("area_of_circle") }}(my_numeric_column) as area_of_circle

from {{ ref('model_a') }}