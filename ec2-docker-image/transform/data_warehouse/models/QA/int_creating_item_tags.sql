{{ config(
    materialized='incremental'
    , unique_key='auction_id'
)}}


WITH RECURSIVE 
{% if is_incremental() %}
please_work as (
    select 
        max(scrape_time)::date 
        from {{this}})

,
{% endif %}


scrape_data as (
  select * from {{ref('stg_yahoo__scraped_data')}}
  {% if is_incremental() %}
    where scrape_time >= (select * from please_work)
  {% endif %}
)
,jp_trans AS (
    SELECT *
    FROM {{  ref('stg_japanese_translations')  }}
    )

,item_tag AS (
    SELECT *
    FROM {{  ref('stg_yahoo_auction_tags')  }}
)


,tag_array AS (
    SELECT 
         ARRAY_AGG(id) as ids
        , ARRAY_LENGTH(ARRAY_AGG(tag),1) AS _len
    FROM item_tag
    )

-- Adds wildcard to all search terms and concats the regex expressions for each tag into one expression

,regex_prep AS (
    SELECT 
        id
        , '('||STRING_AGG(japanese,'|')||')' AS japanese
    FROM item_tag
    INNER JOIN jp_trans
    ON item_tag.tag = jp_trans.english
    GROUP BY id
    )

-- Iterates through # of rows in translation table that are also in our tags table to create table of auction ids and associated tags(will replace with a Jinja for loop)
,cte AS (
    SELECT
        0 AS _n
        ,'' AS auction_id
        ,0 AS tag_id
    UNION ALL
    SELECT 
        _n+1
        ,f.auction_id::TEXT
        , CASE
            WHEN title ~ (
                SELECT japanese
                    FROM regex_prep
                    WHERE id = (
                        SELECT ids[_n+1] 
                        FROM tag_array)
                ) 
                THEN (
                    SELECT ids[_n+1] 
                    FROM tag_array)
                ELSE 0
            END AS tag_id
    FROM scrape_data as f
    CROSS JOIN (SELECT _n FROM cte LIMIT 1) AS _t
    WHERE  _n < (SELECT _len FROM tag_array)
    )


-- If any tag_group only has one tag associated with it, it will not end up in the results
-- Drop auction_id - Tag pairings with no match
, cte_final AS(
    SELECT
        auction_id
        ,array_agg(tag) as tag_list
        ,array_agg(group_id) as group_list
    FROM cte
    LEFT JOIN item_tag
    ON cte.tag_id = item_tag.id
    WHERE tag_id > 0
    GROUP BY auction_id
)


-- Adds in the auction end date in order to use incremental loads (Want to add in scraped time to make adding new searches not need a full refresh to update)

SELECT 
    auction_id
    ,tag_list
    ,group_list
    ,scrape_time
FROM cte_final
LEFT JOIN scrape_data
USING(auction_id)
