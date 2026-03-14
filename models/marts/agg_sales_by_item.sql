select
    item_sk,
    sum(sales_price) as total_sales,
    count(*) as num_transactions,
    avg(sales_price) as avg_sales_price
from {{ ref('int_sales__unioned') }}
group by 1
