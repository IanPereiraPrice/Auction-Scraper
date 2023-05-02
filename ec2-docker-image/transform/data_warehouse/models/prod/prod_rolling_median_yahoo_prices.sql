{{ config(
    materialized='incremental'
    , unique_key='auction_id'
)}}

WITH 

{% if is_incremental() %}
please_work as (select max(scrape_time)::date from {{this}})

,
{% endif %}

item_tag_list AS (
    SELECT 
        auction_id
        ,tag_list
        ,group_list
        ,card_id
    FROM {{  ref('int_yahoo__item_tags')  }}
    )

,int_table_load AS (
    SELECT *
    FROM {{  ref('int_yahoo__data')  }}
    {% if is_incremental() %}
    where scrape_time >= (select * from please_work)
    {% endif %}
)
,int_table AS (
    SELECT *
    FROM int_table_load
)
-- WHERE flag IS NULL or flag = 'false' need to change flag as scheduled to be deleted refers to the category not the item


-- make values with no listed condition as not described
, cte_filter_conditions AS (
    SELECT 
        *
        , COALESCE(tag_list[array_position(group_list,1)],'Not_described') AS regex_condition
    FROM int_table
    LEFT JOIN item_tag_list
    USING(auction_id)
    
    )

-- convert graded conditions into a similar raw condition for less segmented data
, cte_agg_similar_names AS(
    SELECT 
        auction_id
        ,card_id
        ,auction_end
        ,CASE 
            WHEN regex_condition = 'PSA_9' OR regex_condition = 'BGS_9' THEN 'Mint'
            WHEN regex_condition = 'PSA_8' THEN 'Near_Mint'
            WHEN regex_condition = 'PSA_7' OR regex_condition = 'PSA_6' OR regex_condition = 'Unopened' THEN 'Light_Play'
            WHEN regex_condition = 'PSA_5' OR regex_condition = 'PSA_4' OR regex_condition = 'Moderately_Played' THEN 'Played'
            WHEN regex_condition = 'PSA_3' OR regex_condition = 'PSA_2' THEN 'Poor'
            ELSE regex_condition
            END as condition
        ,final_price_usd
    FROM cte_filter_conditions)
    
-- In future need to adust the where clause on price to keep out bad data want to use a more error insensitive approach    
, cte_outlier_values AS(
    SELECT 
        card_id
        ,condition
        ,PERCENTILE_DISC(0.5) WITHIN GROUP( ORDER BY final_price_usd)
        ,PERCENTILE_DISC(0.05) WITHIN GROUP( ORDER BY final_price_usd)
        ,MAX(final_price_usd)
        ,stddev(final_price_usd::numeric)
        ,(PERCENTILE_DISC(0.5) WITHIN GROUP( ORDER BY final_price_usd))::NUMERIC - stddev(final_price_usd::numeric) as med_stv
        ,ROUND(COALESCE((AVG(final_price_usd::numeric) - stddev(final_price_usd::numeric)),0),2) as avg_std


        
    FROM cte_agg_similar_names
    GROUP BY card_id,condition
)

-- filter out values below our determined metric
, cte_filter_outliers AS (
    SELECT 
        auction_id
        ,card_id
        ,auction_end 
        ,condition
        ,final_price_usd
    FROM cte_agg_similar_names
    LEFT JOIN cte_outlier_values
    USING(card_id,condition)
    WHERE final_price_usd::numeric > avg_std
)
-- a 2 month rolling median might adjust to depending on items sold vs date, but dont want issues with infrequently sold items atm
, cte_get_monthly_medians AS (SELECT 
    auction_id
    ,card_id
    ,auction_end AS d
    ,date_trunc('MONTH',auction_end::TIMESTAMP) as m
    ,condition as c
    ,MEDIAN(final_price_usd::numeric) OVER(PARTITION BY card_id, condition ORDER BY (auction_end::TIMESTAMP) RANGE BETWEEN interval '1 month' PRECEDING AND '1 month' FOLLOWING) as r
    ,final_price_usd::numeric AS sold
    
FROM cte_filter_outliers
ORDER BY d)



,done AS (
    SELECT 
        auction_id
        ,card_id
        ,d AS date
        ,m AS month
        ,c AS condition
        ,round(r,2) AS median_cost
        ,sold
        ,scrape_time
    FROM cte_get_monthly_medians
    LEFT JOIN int_table_load 
    USING(auction_id)
    WHERE c != 'Collection'  AND c != 'Fake' 
    ORDER BY card_id, condition, date
    )

SELECT *
FROM done
