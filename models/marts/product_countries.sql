{{ config(materialized='table') }}

with countries_cte as (
    select country_code
    from {{ ref('stg_countries') }}
),

products_cte as (
    select
        product_id,
        date,
        allowed_countries,
        disallowed_countries
    from {{ ref('stg_products') }}
),

exploded as (
    select
        prod.product_id,
        prod.date,
        ctry.country_code,
        case
            when array_size(prod.allowed_countries) > 0 then
                case
                    when ctry.country_code = ANY(prod.allowed_countries) then 'allowed'
                    else 'unavailable'
                end
            when array_size(prod.disallowed_countries) > 0 then
                case
                    when ctry.country_code = ANY(prod.disallowed_countries) then 'unavailable'
                    else 'allowed'
                end
            when array_size(prod.allowed_countries) = 0 and array_size(prod.disallowed_countries) = 0 then 'allowed'
            else 'unavailable'
        end as availability
    from products_cte prod
    cross join countries_cte ctry
)

select *
from exploded