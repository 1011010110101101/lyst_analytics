{{ config(materialized='table') }}

with countries as (
    select
        country_code
    from {{ ref('stg_countries') }}
),

product_data as (
    select
        product_id,
        date,
        allowed_countries,
        disallowed_countries
    from {{ ref('stg_products') }}
),

exploded as (
    select
        product_data.product_id,
        product_data.date,
        countries.country_code,
        case
            when array_size(product_data.allowed_countries) > 0 then
                case
                    when countries.country_code = ANY(product_data.allowed_countries) then 'allowed'
                    else 'unavailable'
                end
            when array_size(product_data.disallowed_countries) > 0 then
                case
                    when countries.country_code = ANY(product_data.disallowed_countries) then 'unavailable'
                    else 'allowed'
                end
            when array_size(product_data.allowed_countries) = 0 and array_size(product_data.disallowed_countries) = 0 then 'allowed'
            else 'unavailable'
        end as availability
    from product_data
    cross join countries
)

select *
from exploded