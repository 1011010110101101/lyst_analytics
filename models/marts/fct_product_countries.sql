{{ config(
    materialized='table'
) }}

with exploded_allowed as (
    select
        product_id,
        date,
        value::string as country_code
    from {{ ref('stg_products') }},
    lateral flatten(input => allowed_countries)
),

exploded_disallowed as (
    select
        product_id,
        date,
        value::string as country_code
    from {{ ref('stg_products') }},
    lateral flatten(input => disallowed_countries)
),

product_dates as (
    select distinct product_id, date
    from {{ ref('stg_products') }}
),

all_countries as (
    select distinct country_code
    from {{ ref('stg_countries') }}
),

product_country_cross as (
    select
        pd.product_id,
        pd.date,
        c.country_code
    from product_dates pd
    cross join all_countries c
),

final as (
    select
        pcc.product_id,
        pcc.date,
        pcc.country_code,
        case
            when ea.country_code is not null then true
            when ed.country_code is not null then false
            when ea.country_code is null and ed.country_code is null and sp.allowed_countries is null and sp.disallowed_countries is null then true
            else true
        end as is_available
    from product_country_cross pcc
    left join exploded_allowed ea
        on pcc.product_id = ea.product_id and pcc.date = ea.date and pcc.country_code = ea.country_code
    left join exploded_disallowed ed
        on pcc.product_id = ed.product_id and pcc.date = ed.date and pcc.country_code = ed.country_code
    left join {{ ref('stg_products') }} sp
        on pcc.product_id = sp.product_id and pcc.date = sp.date
)

select * from final