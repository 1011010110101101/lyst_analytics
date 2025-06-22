-- Test that no rows exist where BOTH allowed and disallowed countries are set

select *
from {{ ref('stg_products') }}
where array_size(allowed_countries) > 0
  and array_size(disallowed_countries) > 0