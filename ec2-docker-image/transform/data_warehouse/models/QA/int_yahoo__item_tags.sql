{{ config(
    materialized='incremental'
    , unique_key='auction_id'
)}}


WITH RECURSIVE 
{% if is_incremental() %}
please_work as (select max(scrape_time)::date from {{this}})

,
{% endif %}

item_tags AS (
  SELECT * 
  FROM {{ref('int_mapping_tags')}}
  {% if is_incremental() %}
    WHERE scrape_time >= (SELECT * FROM please_work)
  {% endif %}
)
,mapped_names AS (
    SELECT 
        auction_id
        ,card_id
        ,card_value
    FROM {{ref('int_mapping_card_names')}}
    {% if is_incremental() %}
        WHERE scrape_time >= (SELECT * FROM please_work)
    {% endif %}
)


SELECT
    auction_id
    ,card_id
    ,tag_list
    ,group_list
    ,scrape_time
    ,card_value
FROM mapped_names AS m
LEFT JOIN item_tags AS i
USING (auction_id)