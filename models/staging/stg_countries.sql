{{ config(materialized='view') }}

select
    country_code,
    country_name,
    country_name_looker,
    country_code_iso3,
    country_code_num
from {{ source('data_source', 'countries') }}