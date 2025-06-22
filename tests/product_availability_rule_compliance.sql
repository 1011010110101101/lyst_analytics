-- Validate that when both allowed and disallowed arrays are empty, the product appears for ALL countries
with base as (
    select *
    from {{ ref('stg_products') }}
    where array_size(allowed_countries) = 0 and array_size(disallowed_countries) = 0
),

crossed as (
    select
        b.product_id,
        b.date,
        count(*) as expected_country_count
    from base b
    cross join {{ ref('stg_countries') }} c
    group by 1, 2
),

actual as (
    select
        pc.product_id,
        pc.date,
        count(*) as actual_country_count
    from {{ ref('product_countries') }} pc
    join base b
    on pc.product_id = b.product_id and pc.date = b.date
    group by 1, 2
)

select *
from crossed x
left join actual a
on x.product_id = a.product_id and x.date = a.date
where x.expected_country_count != a.actual_country_count
