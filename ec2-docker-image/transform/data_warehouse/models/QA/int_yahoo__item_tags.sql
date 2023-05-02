{{ config(
    materialized='incremental'
    , unique_key='auction_id'
)}}


WITH RECURSIVE 
{% if is_incremental() %}
please_work as (select max(scrape_time)::date from {{this}})

,
{% endif %}

item_tags as (
  select * from {{ref('int_creating_item_tags')}}
  {% if is_incremental() %}
    where scrape_time >= (select * from please_work)
  {% endif %}
)
,mapped_names as (
    select 
        auction_id
        ,card_id
    from {{ref('int_mapping_card_names')}}
    {% if is_incremental() %}
        where scrape_time >= (select * from please_work)
    {% endif %}
)


SELECT 
    auction_id
    ,card_id
    ,tag_list
    ,group_list
    ,scrape_time
FROM mapped_names
LEFT JOIN item_tags
USING (auction_id)

