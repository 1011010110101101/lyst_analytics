with product_dates as (
    select
        product_id,
        date
    from {{ ref('stg_products') }}
),

availability_check as (
    select
        product_id,
        date,
        count(*) as availability_count
    from {{ ref('product_countries') }}
    group by 1, 2
)

select *
from product_dates pd
left join availability_check ac
  on pd.product_id = ac.product_id and pd.date = ac.date
where ac.availability_count is null