WITH 

usd_to_yen AS (

    SELECT *
    FROM {{ source('yahoo_db','yen_to_usd')}}

)

SELECT * 
FROM usd_to_yen