WITH

tags AS (

    SELECT *
    FROM {{ source('yahoo_db','yahoo_auction_tags')}}

)

SELECT * 
FROM tags