-- models/marts/product_countries.sql
{{ config(
    materialized='table'
) }}

with countries as (
    select * from {{ ref('stg_countries') }}
),

products as (
    select * from {{ ref('stg_products') }}
),

exploded as (
    select
        p.product_id,
        p.date,
        c.country_code,
        case
            when array_size(p.allowed_countries) > 0 then 'allowed'
            when array_size(p.disallowed_countries) > 0 and not array_contains(p.disallowed_countries, c.country_code) then 'allowed'
            when array_size(p.allowed_countries) = 0 and array_size(p.disallowed_countries) = 0 then 'allowed'
            else 'unavailable'
        end as availability
    from products p
    cross join countries c
)

select * from exploded