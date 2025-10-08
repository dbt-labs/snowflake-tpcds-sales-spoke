-- models/model_a.sql

select
  {{ function("whoami") }}() as my_name,
  'string' as my_string_column,
  2 as my_numeric_column,
  true as my_boolean_column