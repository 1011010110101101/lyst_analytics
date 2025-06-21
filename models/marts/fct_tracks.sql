{{ config(
    materialized='incremental',
    unique_key='track_id'
) }}

with max_insert_ts as (
    select max(insert_timestamp) as max_ts from {{ this }}
),

raw_tracks as (
    select s.*
    from {{ ref('stg_tracks_raw') }} s
    {% if is_incremental() %}
    join max_insert_ts m on s.insert_timestamp > m.max_ts
    {% endif %}
),

backfill_tracks as (
    select * from {{ ref('stg_tracks_backfill') }}
    -- Optional: add filtering here if backfill changes over time
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