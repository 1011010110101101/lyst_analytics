-- models/marts/product_countries.sql
{{ config(materialized='table') }}

with countries as (
    select * from {{ ref('stg_countries') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

exploded as (
    select
        products.product_id,
        products.date,
        countries.country_code,
        case
            when array_size(products.allowed_countries) > 0 then
                case
                    when countries.country_code = ANY(products.allowed_countries) then 'allowed'
                    else 'unavailable'
                end
            when array_size(products.disallowed_countries) > 0 then
                case
                    when countries.country_code = ANY(products.disallowed_countries) then 'unavailable'
                    else 'allowed'
                end
            when array_size(products.allowed_countries) = 0 and array_size(products.disallowed_countries) = 0 then 'allowed'
            else 'unavailable'
        end as availability
    from products
    cross join countries
)

select * from exploded