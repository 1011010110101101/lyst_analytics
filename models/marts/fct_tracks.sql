{{ config(
    materialized='incremental',
    unique_key='track_id'
) }}

with raw_tracks as (
    select * from {{ ref('stg_tracks_raw') }}
    {% if is_incremental() %}
      where insert_timestamp > (select max(insert_timestamp) from {{ this }})
    {% endif %}
),
backfill_tracks as (
    select * from {{ ref('stg_tracks_backfill') }}
    -- If backfill ever changes, then filtering could be added here as well
),
combined as (
    select * from raw_tracks
    union all
    select * from backfill_tracks
),
deduplicated as (
    select *
    from (
        select *,
               row_number() over (partition by track_id order by insert_timestamp desc) as row_num
        from combined
    )
    where row_num = 1
)

select
    track_id,
    track_timestamp,
    product_id,
    retailer_id,
    price
from deduplicated