with 

unioned as (
    {{
        dbt_utils.union_relations(
            [
                ref('stg_tpcds_core__catalog_sales'),
                ref('stg_tpcds_core__store_sales'),
                ref('stg_tpcds_core__web_sales')
            ]
        )
    }}
),

final as (

    select 
        sale_id,
        transaction_type,
        item_sk,
        coalesce(
            customer_sk, -- store
            bill_customer_sk -- catalog + web
        ) as customer_sk,
        call_center_sk,
        store_sk,
        sales_price

    from unioned

)

select * from final