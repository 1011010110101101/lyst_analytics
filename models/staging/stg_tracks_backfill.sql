{{ config(
    materialized='view'
) }}

select
    track_id,
    track_timestamp,
    product_id,
    retailer_id,
    price,
    insert_timestamp
from {{ source('data_source', 'tracks_backfill') }}