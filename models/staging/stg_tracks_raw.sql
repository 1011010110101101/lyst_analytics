{{ config(materialized='view') }}

SELECT
    insert_timestamp,
    track_timestamp,
    track_id,
    product_id,
    retailer_id,
    price
FROM {{ source('tracks', 'tracks_raw') }}