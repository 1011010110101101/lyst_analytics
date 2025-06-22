{{ config(materialized='table') }}

with c_data as (
    select country_code
    from {{ ref('stg_countries') }}
),

p_data as (
    select
        product_id,
        date,
        allowed_countries,
        disallowed_countries
    from {{ ref('stg_products') }}
),

exploded as (
    select
        p_data.product_id,
        p_data.date,
        c_data.country_code,
        case
            when array_size(p_data.allowed_countries) > 0 then
                case
                    when c_data.country_code = ANY(p_data.allowed_countries) then 'allowed'
                    else 'unavailable'
                end
            when array_size(p_data.disallowed_countries) > 0 then
                case
                    when c_data.country_code = ANY(p_data.disallowed_countries) then 'unavailable'
                    else 'allowed'
                end
            when array_size(p_data.allowed_countries) = 0 and array_size(p_data.disallowed_countries) = 0 then 'allowed'
            else 'unavailable'
        end as availability
    from p_data
    cross join c_data
)

select *
from exploded