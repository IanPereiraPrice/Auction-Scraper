{{ config(
    materialized='incremental'
    , unique_key='auction_id'
)}}


WITH RECURSIVE 
{% if is_incremental() %}
please_work AS (
    SELECT 
        MAX(scrape_time)::DATE
        FROM {{this}})

,
{% endif %}

item_class_list AS (
    SELECT 
        *
    FROM {{  ref('stg_yahoo_auction_card_classifications')  }}
    )

,item_tag_list AS (
    SELECT 
        auction_id
        ,tag_list
        ,group_list
        ,scrape_time
    FROM {{  ref('int_mapping_tags')  }}
    {% if is_incremental() %}
    where scrape_time >= (select * from please_work)
    {% endif %}
    )

-- Recursive loop to check for matching tag combinations to label card_id
,cte AS (
    SELECT
        0 AS _n
        ,'' AS auction_id
        ,'' AS card_id
    UNION ALL
    SELECT 
        _n+1
        ,f.auction_id::TEXT
        , CASE
            WHEN (
                SELECT 
                    tag_combinations::VARCHAR[] 
                FROM item_class_list
                WHERE id = _n+1
                ) <@ (tag_list)  
                AND NOT
                (
                    (
                    SELECT 
                        CASE 
                            WHEN tag_exclusions is NULL 
                                THEN ARRAY['QUIT'] 
                            ELSE  tag_exclusions::VARCHAR[] 
                        END 
                    FROM item_class_list
                    WHERE id = _n+1
                    )&&(tag_list)
                )
                THEN (
                    SELECT card_Name||','||card_value
                    FROM item_class_list
                    WHERE id = _n+1)
                ELSE NULL
            END AS card_id
    FROM item_tag_list as f
    CROSS JOIN (SELECT _n FROM cte LIMIT 1) AS _t
    WHERE  _n < (SELECT MAX(id) FROM item_class_list)
    )

,cte_card_values AS (
    SELECT DISTINCT
        auction_id
        ,SPLIT_PART(card_id,',',1) AS card_id
        ,SPLIT_PART(card_id,',',2)::INT AS card_value
    FROM cte
    WHERE _n>0)

,cte_clear_dupes AS (
    SELECT DISTINCT
        auction_id
        ,card_id
        ,MAX(card_value) AS card_value
    FROM cte_card_values
    GROUP BY auction_id, card_id
)
-- join table in order to have auction_id accessible for incremental loads
SELECT 
    auction_id
    ,card_id
    ,scrape_time
    ,card_value
FROM cte_clear_dupes
LEFT JOIN item_tag_list
USING(auction_id)
WHERE card_id IS NOT NULL