{{ config(
    materialized='incremental',
    unique_key='track_id'
) }}

{% if is_incremental() %}
-- CTE to get the minimum insert timestamp from the existing table
with existing_min as (
    select min(insert_timestamp) as min_insert_ts
    from {{ this }}
),
all_staging as (
    select * from {{ ref('stg_tracks_backfill') }}
    union all
    select * from {{ ref('stg_tracks_raw') }}
),
all_tracks as (
    select *
    from all_staging
    where insert_timestamp > (select min_insert_ts from existing_min)
)
{% else %}
with all_tracks as (
    select * from {{ ref('stg_tracks_backfill') }}
    union all
    select * from {{ ref('stg_tracks_raw') }}
)
{% endif %},

ranked_tracks as (
    select
        insert_timestamp,
        track_timestamp,
        track_id,
        product_id,
        retailer_id,
        price,
        row_number() over (
            partition by track_id
            order by insert_timestamp desc
        ) as row_num
    from all_tracks
)

select
    insert_timestamp,
    track_timestamp,
    track_id,
    product_id,
    retailer_id,
    price
from ranked_tracks
where row_num = 1
  and track_id is not null