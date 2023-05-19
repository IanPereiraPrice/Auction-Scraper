-- Always name column names in lowercase: dbt will not send the query as capitalized and will be unable to select the column


WITH 

card_classification_table AS (

    SELECT 
        id
        ,card_name
        ,tag_combinations
        ,tag_exclusions
        ,card_value
    FROM {{ source('yahoo_db','card_classification_table')}}

)

SELECT * 
FROM card_classification_table