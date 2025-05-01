with 

source as (

    select * from {{ source('jaffle_shop', 'customers') }}

),

renamed as (

    select
        id as id

    from source

)

select * from renamed
