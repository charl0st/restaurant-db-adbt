
-- SQL Loader Control File
-- Table: RESTAURANT_DW.FACT_SALES
-- Data File: fact_sales.csv
-- Student ID: 10218 // Group: 11B

-- HOW TO RUN (inside Docker container):
--
--   docker cp fact_sales.csv <container>:/tmp/fact_sales.csv
--   docker cp fact_sales.ctl <container>:/tmp/fact_sales.ctl
--   docker exec -it <container> bash
--
--   sqlldr userid=RESTAURANT_DW/<password>@localhost:1521/XEPDB1 \
--          control=/tmp/fact_sales.ctl \
--          log=/tmp/fact_sales.log \
--          bad=/tmp/fact_sales.bad


LOAD DATA
INFILE '/tmp/fact_sales.csv'
APPEND
INTO TABLE RESTAURANT_DW.FACT_SALES
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
TRAILING NULLCOLS
(
    SALEID          INTEGER EXTERNAL,
    DATEID          INTEGER EXTERNAL,
    RESTAURANTID    INTEGER EXTERNAL,
    ITEMID          INTEGER EXTERNAL,
    CUSTOMERID      INTEGER EXTERNAL,
    QUANTITYSOLD    INTEGER EXTERNAL,
    TOTALREVENUE    DECIMAL EXTERNAL
)
