{{ config(
    materialized='incremental',
    unique_key='track_id'
) }}

with raw_tracks as (

    {% if is_incremental() %}

    -- Only pull records newer than what's already in the table
    select s.*
    from {{ ref('stg_tracks_raw') }} s
    where s.insert_timestamp > (
        select max(insert_timestamp) from {{ this }}
    )

    {% else %}

    -- For full-refresh, pull all data
    select * from {{ ref('stg_tracks_raw') }}

    {% endif %}

),

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