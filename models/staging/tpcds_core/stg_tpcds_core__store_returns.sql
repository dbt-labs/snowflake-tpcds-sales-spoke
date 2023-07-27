with 

source as (

    select * from {{ source('tpcds_core', 'store_returns') }}

),

renamed as (

    select
        'store_return' as return_type,
        sr_returned_date_sk as return_date_sk,
        sr_return_time_sk as return_time_sk,
        sr_item_sk as item_sk,
        {{
            dbt_utils.generate_surrogate_key(
                [
                    'return_type',
                    'return_time_sk'
                ]
            )
        }} as store_return_sk,
        sr_customer_sk as customer_sk,
        sr_cdemo_sk as cdemo_sk,
        sr_hdemo_sk as hdemo_sk,
        sr_addr_sk as addr_sk,
        sr_store_sk as store_sk,
        sr_reason_sk as reason_sk,
        sr_ticket_number as ticket_number,
        sr_return_quantity as return_quantity,
        sr_return_amt as return_amt,
        sr_return_tax as return_tax,
        sr_return_amt_inc_tax as return_amt_inc_tax,
        sr_fee as fee,
        sr_return_ship_cost as return_ship_cost,
        sr_refunded_cash as refunded_cash,
        sr_reversed_charge as reversed_charge,
        sr_store_credit as store_credit,
        sr_net_loss as net_loss

    from source

)

select * from renamed
