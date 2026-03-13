select
    sale_id,
    transaction_type,
    item_sk,
    customer_sk,
    sales_price,
    sold_date_sk
from {{ ref('int_sales__unioned') }}
