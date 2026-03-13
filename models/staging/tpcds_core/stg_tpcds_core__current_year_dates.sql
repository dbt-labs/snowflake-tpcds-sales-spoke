select *
from {{ ref('stg_tpcds_core__date_dim') }}
where current_year = 'Y'
