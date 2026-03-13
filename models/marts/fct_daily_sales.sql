with

current_dates as (
    select * from {{ ref('stg_tpcds_core__current_year_dates') }}
),

sales as (
    select
        sold_date_sk,
        item_sk,
        sum(sales_price) as total_sales,
        count(*) as num_transactions
    from {{ ref('int_sales__unioned') }}
    where sold_date_sk in (select date_sk from current_dates)
    {% if is_incremental() %}
        and sold_date_sk > (select max(sold_date_sk) from {{ this }})
    {% endif %}
    group by 1, 2
)

select
    {{ dbt_utils.generate_surrogate_key(['sold_date_sk', 'item_sk']) }} as sale_date_item_key,
    sold_date_sk,
    item_sk,
    total_sales,
    num_transactions
from sales
