{{ config(
    materialized='view'
) }}

with source as (
    select * from {{ source('data_source', 'tracks_raw') }}
),
deduplicated as (
    select *
    from (
        select *,
               row_number() over (partition by track_id order by insert_timestamp desc) as row_num
        from source
    )
    where row_num = 1
)

select
    track_id,
    track_timestamp,
    product_id,
    retailer_id,
    price,
    insert_timestamp
from deduplicated