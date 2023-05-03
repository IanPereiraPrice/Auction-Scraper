
BEGIN;

-- Name: tag_groups_tag_group_id_seq; Type: SEQUENCE; Schema: public;

CREATE SEQUENCE IF NOT EXISTS public.tag_groups_tag_group_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

-- Name: tag_groups; Type: TABLE; Schema: public;
--

CREATE TABLE IF NOT EXISTS public.tag_groups (
    group_id integer DEFAULT nextval('public."tag_groups_tag_group_id_seq"'::regclass) NOT NULL,
    group_name character varying NOT NULL,
    UNIQUE (group_id),
    UNIQUE (group_name)

);

CREATE TEMP TABLE temp_table
(LIKE public.tag_groups INCLUDING DEFAULTS)
ON COMMIT DROP;

\COPY temp_table FROM '/opt/airflow/db_setup/csv_files/tag_groups.csv' DELIMITER ','  CSV HEADER;

INSERT INTO public.tag_groups
SELECT * 
FROM temp_table
ON CONFLICT DO NOTHING;

SELECT setval('public."tag_groups_tag_group_id_seq"', (SELECT MAX(group_id) FROM public.tag_groups));

COMMIT;

----------------------------------------

BEGIN;
-- Name: Card_Sales_Staging_id_seq; Type: SEQUENCE; Schema: public
--

CREATE SEQUENCE IF NOT EXISTS public.Card_Sales_Staging_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


-- Name: card_sales_staging; Type: TABLE; Schema: public
--

CREATE TABLE IF NOT EXISTS public.card_sales_staging (
    id integer DEFAULT nextval('public."Card_Sales_Staging_id_seq"'::regclass),
    auction_id character varying NOT NULL,
    title character varying NOT NULL,
    price character varying,
    bids integer,
    tax character varying,
    auction_start character varying,
    auction_end character varying,
    auction_extension character varying,
    best_offer_accepted character varying,
    all_images character varying NOT NULL,
    categories character varying,
    condition character varying,
    flag character varying,
    scrape_time timestamp without time zone,
    UNIQUE (auction_id),
    UNIQUE (id),
    PRIMARY KEY (id)
);

CREATE TEMP TABLE temp_table
(LIKE public.card_sales_staging INCLUDING DEFAULTS)
ON COMMIT DROP;

\COPY temp_table FROM '/opt/airflow/db_setup/csv_files/card_data.csv' DELIMITER ','  CSV HEADER;


INSERT INTO public.card_sales_staging
SELECT * 
FROM temp_table
ON CONFLICT DO NOTHING;

SELECT SETVAL('public."Card_Sales_Staging_id_seq"', (SELECT MAX(id) FROM public.card_sales_staging));


COMMIT;

------------------------------------------------------------------

BEGIN;

-- Name: japanese_translations; Type: TABLE; Schema: public
--

CREATE TABLE IF NOT EXISTS public.japanese_translations (
    japanese text NOT NULL,
    english character varying NOT NULL,
    UNIQUE (japanese)
);

CREATE TEMP TABLE temp_table
(LIKE public.japanese_translations INCLUDING DEFAULTS)
ON COMMIT DROP;

\COPY temp_table FROM '/opt/airflow/db_setup/csv_files/japanese_translations.csv' DELIMITER ','  CSV HEADER;


INSERT INTO public.japanese_translations
SELECT * 
FROM temp_table
ON CONFLICT DO NOTHING;

COMMIT;


BEGIN;
-- Name: yen_to_usd; Type: TABLE; Schema: public
--

CREATE TABLE IF NOT EXISTS public.yen_to_usd (
    date date,
    open numeric,
    high numeric,
    low numeric,
    close numeric,
    UNIQUE (date)
);

CREATE TEMP TABLE temp_table
(LIKE public.yen_to_usd INCLUDING DEFAULTS)
ON COMMIT DROP;

\COPY temp_table FROM '/opt/airflow/db_setup/csv_files/yen_usd.csv' DELIMITER ','  CSV HEADER;


INSERT INTO public.yen_to_usd
SELECT * 
FROM temp_table
ON CONFLICT DO NOTHING;

COMMIT;

--------

BEGIN;



CREATE SEQUENCE IF NOT EXISTS public.card_classification_table_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
-- Name: card_classification_table; Type: TABLE; Schema: public
--

CREATE TABLE IF NOT EXISTS public.card_classification_table (
    card_name text NOT NULL,
    tag_combinations text NOT NULL,
    tag_exclusions text,
    id integer DEFAULT nextval('public."card_classification_table_id_seq"'::regclass) NOT NULL,
    PRIMARY KEY (id),
    UNIQUE (id)
);

CREATE TEMP TABLE temp_table
(LIKE public.card_classification_table INCLUDING DEFAULTS)
ON COMMIT DROP;

\COPY temp_table FROM '/opt/airflow/db_setup/csv_files/card_classifications.csv' DELIMITER ','  CSV HEADER;


INSERT INTO public.card_classification_table
SELECT * 
FROM temp_table
ON CONFLICT DO NOTHING;

SELECT SETVAL('public."card_classification_table_id_seq"', (SELECT MAX(id) FROM public.card_classification_table));

COMMIT;


BEGIN;

-- Name: yahoo_auction_tags_id_seq; Type: SEQUENCE; Schema: public
--

CREATE SEQUENCE IF NOT EXISTS public.yahoo_auction_tags_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

--
-- Name: yahoo_auction_tags; Type: TABLE; Schema: public
--

CREATE TABLE IF NOT EXISTS public.yahoo_auction_tags (
    id integer DEFAULT nextval('public."yahoo_auction_tags_id_seq"'::regclass) NOT NULL,
    tag character varying NOT NULL,
    group_id integer,
    PRIMARY KEY (id),
    FOREIGN KEY (group_id) REFERENCES tag_groups(group_id),
    UNIQUE (tag)
);

CREATE TEMP TABLE temp_table
(LIKE public.yahoo_auction_tags INCLUDING DEFAULTS)
ON COMMIT DROP;

\COPY temp_table FROM '/opt/airflow/db_setup/csv_files/ids_tags.csv' DELIMITER ','  CSV HEADER;

INSERT INTO public.yahoo_auction_tags
SELECT * 
FROM temp_table
ON CONFLICT DO NOTHING;

SELECT SETVAL('public."yahoo_auction_tags_id_seq"', (SELECT MAX(id) FROM public.yahoo_auction_tags));

COMMIT;

CREATE OR REPLACE FUNCTION public._final_median(numeric[])
 RETURNS numeric
 LANGUAGE sql
 IMMUTABLE
AS $function$
   SELECT AVG(val)
   FROM (
     SELECT val
     FROM unnest($1) val
     ORDER BY 1
     LIMIT  2 - MOD(array_upper($1, 1), 2)
     OFFSET CEIL(array_upper($1, 1) / 2.0) - 1
   ) sub;
$function$;

CREATE AGGREGATE median(numeric) (
  SFUNC=array_append,
  STYPE=numeric[],
  FINALFUNC=_final_median,
  INITCOND='{}'
);