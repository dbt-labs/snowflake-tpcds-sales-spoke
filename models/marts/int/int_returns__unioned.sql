with 

unioned as (
    {{
        dbt_utils.union_relations(
            [
                ref('stg_tpcds_core__catalog_returns'),
                ref('stg_tpcds_core__store_returns'),
                ref('stg_tpcds_core__web_returns')
            ]
        )
    }}
),

final as (

    select 
        return_id,
        transaction_type,
        item_sk,
        coalesce(
            customer_sk, -- store
            returning_customer_sk -- catalog + web
        ) as customer_sk,
        call_center_sk
        store_sk,
        return_amt,
        return_date_sk

    from unioned

)

select * from final