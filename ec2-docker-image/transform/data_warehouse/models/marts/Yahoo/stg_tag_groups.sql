WITH

group_tags AS (

    SELECT *
    FROM {{ source('yahoo_db','tag_groups')}}

)

SELECT * 
FROM group_tags