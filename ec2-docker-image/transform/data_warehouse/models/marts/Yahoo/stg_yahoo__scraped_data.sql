WITH

scraped_data AS (

    SELECT *
    FROM {{ source('yahoo_db','card_sales_staging')}}

)

,cleaning_dtype_cte AS (
    SELECT 
        auction_id
        ,translate(upper(title),
        '０１２３４５６７８９ＡＢＣＤＥＦＧＨＩＪＫＬＭＮＯＰＱＲＳＴＵＶＷＸＹＺ',
        '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
        ) AS title
        ,bids
        ,to_timestamp((LEFT(auction_start,10)||' '||RIGHT(auction_start,5)),'YYYY.MM.DD HH24:MI') AS auction_start
        ,to_timestamp((LEFT(auction_end,10)||' '||RIGHT(auction_end,5)),'YYYY.MM.DD HH24:MI') AS auction_end
        ,regexp_replace(price, '\D+', '', 'g')::int AS price
        ,'¥' AS currency
        ,regexp_replace(tax, '\D+', '', 'g')::int AS tax
        ,CASE
            WHEN auction_extension = 'なし' THEN 'No'
            ELSE 'Yes'
            END AS auction_extension
        ,CASE
            WHEN best_offer_accepted = 'なし' THEN 'No'
            ELSE 'Yes'
            END AS best_offer_accepted
        ,REPLACE(all_images,' ',',')AS all_images
        ,condition
        ,categories
        ,flag
        ,scrape_time
    FROM scraped_data)


,stg_yahoo AS(
    SELECT 
        auction_id
        ,title
        ,auction_start
        ,auction_end
        ,bids
        ,price
        , CASE 
            WHEN tax = 0
            THEN tax
            ELSE tax-price
        END AS tax
        , CASE 
            WHEN tax = 0
            THEN Price
            ELSE tax 
        END AS final_price_yen
        ,currency
        ,condition
        ,auction_extension
        ,best_offer_accepted
        ,categories
        ,flag
        ,scrape_time
        ,all_images
    FROM cleaning_dtype_cte
    )

SELECT * 
FROM stg_yahoo
