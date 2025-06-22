-- models/marts/product_countries.sql
{{ config(materialized='table') }}

with country_cte as (
    select country_code
    from {{ ref('stg_countries') }}
),

product_cte as (
    select
        product_id,
        date,
        allowed_countries,
        disallowed_countries
    from {{ ref('stg_products') }}
),

exploded as (
    select
        product_cte.product_id,
        product_cte.date,
        country_cte.country_code,
        case
            when array_size(product_cte.allowed_countries) > 0 then
                case
                    when country_cte.country_code = ANY(product_cte.allowed_countries) then 'allowed'
                    else 'unavailable'
                end
            when array_size(product_cte.disallowed_countries) > 0 then
                case
                    when country_cte.country_code = ANY(product_cte.disallowed_countries) then 'unavailable'
                    else 'allowed'
                end
            when array_size(product_cte.allowed_countries) = 0 and array_size(product_cte.disallowed_countries) = 0 then 'allowed'
            else 'unavailable'
        end as availability
    from product_cte
    cross join country_cte
)

select *
from exploded