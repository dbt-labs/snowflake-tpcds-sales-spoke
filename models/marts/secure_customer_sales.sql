select
    customer_sk,
    transaction_type,
    sales_price,
    sold_date_sk
from {{ ref('int_sales__unioned') }}
