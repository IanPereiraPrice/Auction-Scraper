{{ config(
    materialized='incremental'
    , unique_key='auction_id'
)}}





-- Create Ranks Over all days we have data for
With 


scrape_data as (
  select * from {{ref('stg_yahoo__scraped_data')}}
  {% if is_incremental() %}
    where scrape_time >= (select max(scrape_time)::date from {{this}})
  {% endif %}
)


,usd_to_yen as(
    SELECT *
    FROM {{ ref('stg_usd_to_yen') }}
    )

,money_cte_1 AS(
    SELECT 
        date
        , open
        ,RANK() OVER(ORDER BY date) AS ranking
    FROM usd_to_yen)

-- Fill missing dates as having a value of zero
,money_cte_2 AS (
    SELECT  
        DISTINCT(auction_end::DATE) AS auction_end
        ,date
        ,open
        ,COALESCE(ranking,NULL,0) AS ranking
    FROM scrape_data   
    LEFT JOIN money_cte_1
    ON (auction_end)::DATE = date
)

-- Add date values, so that the missing days have same value as the last day before that had non-missing values
,money_cte_3 AS (
    SELECT 
        auction_end
        ,date
        ,open
        ,SUM(ranking) OVER(ORDER BY auction_end) AS rankings_2
    FROM money_cte_2)

--Join conversion rates with all dates needed for auction table
,money_cte_final AS (
    SELECT 
        auction_end AS date
        , open_sub as usd_yen_rate
    FROM money_cte_3
    LEFT JOIN (
        SELECT open AS open_sub, rankings_2
        FROM money_cte_3
        WHERE open IS NOT NULL) AS sub
    USING(rankings_2)
    )

--standardize the data types of incoming columns

--adjust columns with taxed final price so that final comparison is the same


--Put it all together
--INSERT INTO "final_sales_table"(auction_id,title,price,bids,tax,final_price_yen,currency,final_price_usd,auction_start,auction_end,auction_extension,best_offer_accepted,all_images)
SELECT 
    auction_id
    ,title  
    ,price
    ,bids
    ,tax
    ,final_price_yen
    ,currency
    ,(final_price_yen/(usd_yen_rate::NUMERIC))::MONEY AS final_price_usd
    ,condition
    ,auction_start
    ,auction_end
    ,auction_extension
    ,best_offer_accepted
    ,categories
    ,flag
    ,scrape_time
    ,all_images
FROM scrape_data
LEFT JOIN money_cte_final
ON auction_end::date = money_cte_final."date"

