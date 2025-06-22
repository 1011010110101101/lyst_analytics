-- Test that when only disallowed_countries is populated,
-- product is available in all countries except the ones disallowed.

with base as (
    select *
    from {{ ref('stg_products') }}
    where array_size(allowed_countries) = 0
      and array_size(disallowed_countries) > 0
),

exploded as (
    select
        b.product_id,
        b.date,
        c.country_code,
        case
            when array_contains(b.disallowed_countries, c.country_code) then 'unavailable'
            else 'allowed'
        end as expected_availability
    from base b
    cross join {{ ref('stg_countries') }} c
),

actual as (
    select
        pc.product_id,
        pc.date,
        pc.country_code,
        pc.availability
    from {{ ref('product_countries') }} pc
    join base b
      on pc.product_id = b.product_id and pc.date = b.date
)

select *
from exploded e
left join actual a
  on e.product_id = a.product_id
 and e.date = a.date
 and e.country_code = a.country_code
where e.expected_availability != a.availability