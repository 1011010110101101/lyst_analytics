{{ config(
    materialized = 'incremental',
    unique_key = 'track_id'
) }}

with all_tracks as (

    select * from {{ ref('stg_tracks_backfill') }}
    union all
    select * from {{ ref('stg_tracks_raw') }}

    {% if is_incremental() %}
    where insert_timestamp > (select min(insert_timestamp) from {{ this }})
    {% endif %}

),

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