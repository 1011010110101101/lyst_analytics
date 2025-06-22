{{ config(materialized='view') }}

select
    insert_timestamp,
    track_timestamp,
    track_id,
    product_id,
    retailer_id,
    price
from {{ source('data_source', 'tracks_raw') }}