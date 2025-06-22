-- models/marts/product_countries.sql
{{ config(
    materialized='table'
) }}

with country_cte as (
    select
        country_code
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
        p.product_id,
        p.date,
        c.country_code,
        case
            -- Explicit allowlist
            when array_size(p.allowed_countries) > 0 then
                case
                    when c.country_code = ANY(p.allowed_countries) then 'allowed'
                    else 'unavailable'
                end

            -- Only disallow list populated
            when array_size(p.disallowed_countries) > 0 then
                case
                    when c.country_code = ANY(p.disallowed_countries) then 'unavailable'
                    else 'allowed'
                end

            -- Neither list populated
            when array_size(p.allowed_countries) = 0 and array_size(p.disallowed_countries) = 0 then 'allowed'

            else 'unavailable'
        end as availability
    from product_cte as p
    cross join country_cte as c
)

select *
from exploded