with 

source as (

    select * from {{ source('tpcds_core', 'catalog_page') }}

),

renamed as (

    select
        cp_catalog_page_sk as catalog_page_sk, -- a no op comment
        cp_catalog_page_id as catalog_page_id,
        cp_start_date_sk as start_date_sk,
        cp_end_date_sk as end_date_sk,
        cp_department as department,
        cp_catalog_number as catalog_number,
        cp_catalog_page_number as catalog_page_number,
        cp_description as description,
        cp_type as type

    from source

)

select * from renamed
