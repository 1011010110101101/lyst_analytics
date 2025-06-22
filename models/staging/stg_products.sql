{{ config(materialized='view') }}

select
    product_id,
    date,
    allowed_countries,
    disallowed_countries
from {{ source('data_source', 'products') }}