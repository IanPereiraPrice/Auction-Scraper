{{ config(
    materialized='incremental'
    , unique_key='auction_id'
)}}

WITH 

-- incremental statement
{% if is_incremental() %}
please_work as (select max(scrape_time)::date from {{this}})
,
{% endif %}

-- int_yahoo__item_tags
item_tag_list AS (
    SELECT 
        auction_id
        ,tag_list
        ,group_list
        ,card_id
        ,card_value
    FROM {{  ref('int_yahoo__item_tags')  }}
    )

-- int_yahoo__data
,int_table_load AS (
    SELECT *
    FROM {{  ref('int_yahoo__data')  }}
    {% if is_incremental() %}
    where scrape_time >= (select * from please_work)
    {% endif %}
)

-- What is this doing here?
,int_table_good_ids AS (
    SELECT
        auction_id
    FROM item_tag_list 
    GROUP BY auction_id
    HAVING count(*) = 1
)

,int_table_clean AS (
    SELECT *
    FROM int_table_good_ids
    LEFT JOIN int_table_load
    USING (auction_id)
)

,item_tag_clean AS (
    SELECT *
    FROM int_table_good_ids
    LEFT JOIN item_tag_list
    USING (auction_id)
)

-- WHERE flag IS NULL or flag = 'false' need to change flag as scheduled to be deleted refers to the category not the item


-- for items with no condition listed in tag list [condition is '1' in group_list], add a 'Not Described' tag to it
-- Joins list of tags associated with items, and the cleaned auction data together 
, cte_coalesce_conditions AS (
    SELECT 
        *
        , COALESCE(tag_list[array_position(group_list,1)],'Not_described') AS regex_condition
    FROM int_table_clean
    LEFT JOIN item_tag_clean
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
        ,card_value::INT
    FROM cte_coalesce_conditions
)
, cte_filter_conditions AS(
    SELECT *
    FROM cte_agg_similar_names
    WHERE 
        condition != 'Collection'
        AND condition != 'Fake'
)

-- rolling median to help identify outlier values
,cte_outliers_medians AS (
    SELECT DISTINCT 
    card_id
    ,condition
    ,DATE_TRUNC('month',auction_end)::date AS month
    ,MEDIAN(final_price_usd::numeric) OVER(PARTITION BY card_id, condition ORDER BY (DATE_TRUNC('month',auction_end)) RANGE BETWEEN interval '3 month' PRECEDING AND '3 month' FOLLOWING) as monthly_median_verified  
    FROM cte_filter_conditions
    WHERE card_value = 100
)

-- create rank over card,id and condition to prep for filling in missing dates
,cte_outliers_1 AS(
    SELECT 
        month
        , card_id
        , condition
        , monthly_median_verified
        ,RANK() OVER(PARTITION BY card_id,condition ORDER BY month) AS ranking
    FROM cte_outliers_medians)

-- Fill missing dates as having a rank value of zero
,cte_outliers_2 AS (
    SELECT DISTINCT
        
        
        DATE_TRUNC('month',a.auction_end)::date AS month
        , a.card_id
        , a.condition
        , monthly_median_verified
        ,COALESCE(ranking,NULL,0) AS ranking
    FROM cte_filter_conditions AS a
    LEFT JOIN cte_outliers_1 AS b
    ON
        a.card_id = b.card_id
        AND a.condition = b.condition
        AND (DATE_TRUNC('month',a.auction_end)::DATE) = month
    WHERE a.card_id IS NOT NULL
        
)

-- SUM over ranks to have missing dates joined onto the next closest rate
,cte_outliers_3 AS (
    SELECT 
        *
        ,SUM(ranking) OVER(PARTITION BY card_id, condition ORDER BY month) + 1 AS rankings_2
    FROM cte_outliers_2)


-- Join table onto itself and filter out duplicates, and the table matches where ranks are same, but neither has median
,cte_outliers_final AS (
    SELECT DISTINCT
        b.card_id
        ,b.month
        ,b.condition
        ,a.monthly_median_verified
    FROM cte_outliers_3 AS a
    LEFT JOIN cte_outliers_3 AS b
    ON a.rankings_2 = b.rankings_2
    AND a.card_id = b.card_id
    AND a.condition = b.condition
    WHERE a.monthly_median_verified IS NOT NULL
)


-- Currently quite satisfied with this filter. Most filtered out results either well below listed condition or the wrong card. Only exception is som cards in not described that are in bad condition are filtered out.
-- If add modern cards, aprroach may have to cahnge however to be based off of std dev
,cte_filter_outliers AS (
    SELECT 
        a.auction_id
        ,a.card_id
        ,a.auction_end 
        ,a.condition
        ,a.final_price_usd
        ,monthly_median_verified
    FROM cte_filter_conditions as a
    LEFT JOIN cte_outliers_final as b
    ON 
        a.card_id = b.card_id
        AND a.condition = b.condition
        AND (DATE_TRUNC('month',a.auction_end)::date) = b.month
    WHERE 
        a.card_id IS NOT NULL
        AND b.card_id IS NOT NULL
        AND final_price_usd::decimal < (monthly_median_verified*.20/(.01 * card_value::decimal))
)

-- a 2 month rolling median might adjust to depending on items sold vs date, but dont want issues with infrequently sold items atm
, cte_get_monthly_medians AS (
    SELECT 
        auction_id
        ,card_id
        ,auction_end AS d
        ,date_trunc('MONTH',auction_end::TIMESTAMP) as m
        ,condition as c
        ,MEDIAN(final_price_usd::numeric) OVER(PARTITION BY card_id, condition ORDER BY (auction_end::TIMESTAMP) RANGE BETWEEN interval '1 month' PRECEDING AND '1 month' FOLLOWING) as r
        ,final_price_usd::numeric AS sold
        
    FROM cte_filter_outliers
    ORDER BY d
)



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
    LEFT JOIN int_table_clean 
    USING(auction_id)
    ORDER BY card_id, condition, date
    )




SELECT *
FROM done
