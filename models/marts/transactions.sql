with 

customers as (

    select * from {{ ref('snowflake_tpcds_core', 'customers') }}

),

stores as (

    select * from {{ ref('snowflake_tpcds_core', 'stores') }}

),

unioned as (
    {{
        dbt_utils.union_relations(
            [
                ref('int_returns__unioned'),
                ref('int_sales__unioned'),
            ]
        )
    }}

),

final as (

    select
        coaleasce(sale_id, return_id) as transaction_id,
        transaction_type,
        item_sk,
        coalesce(
            customer_sk, -- store
            returning_customer_sk -- catalog + web
        ) as customer_sk,
        call_center_sk
        store_sk,
        coalesce(sales_price, -1 * return_amt) as transaction_amount
        customers.first_name
        customers.last_name,
        customers.is_preferred_customer
        customers.gender
        stores.store_name,
        stores.city,
        stores.state


    from unioned
    left join customers
        on unioned.customer_sk = customers.customer_sk
    left join stores
        on unioned.store_sk = stores.store_sk

)

select * from final