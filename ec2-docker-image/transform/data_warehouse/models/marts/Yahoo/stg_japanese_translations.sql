WITH

translate AS (

    SELECT *
    FROM {{ source('yahoo_db','japanese_translations')}}

)

SELECT * 
FROM translate