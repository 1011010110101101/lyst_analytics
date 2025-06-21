{{ config(
    materialized='incremental',
    unique_key='track_id'
) }}

{% if is_incremental() %}
with max_ts as (
    select max(insert_timestamp) as max_ts from {{ this }}
),
raw_tracks as (
    select *
    from {{ ref('stg_tracks_raw') }}
    where insert_timestamp > (select max_ts from max_ts)
),
{% else %}
raw_tracks as (
    select * from {{ ref('stg_tracks_raw') }}
),
{% endif %}

backfill_tracks as (
    select * from {{ ref('stg_tracks_backfill') }}
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