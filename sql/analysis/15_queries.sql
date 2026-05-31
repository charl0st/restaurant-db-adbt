

-- A. ROLLUP QUERIES


-- A1: Revenue by Year > Quarter > Month (time hierarchy)
-- Produces subtotals at each level of the time hierarchy.
-- Grand total row appears at the bottom (all columns NULL).
SELECT
    d.YEAR,
    d.QUARTER,
    d.MONTH,
    COUNT(*)                        AS TotalTransactions,
    SUM(f.QUANTITYSOLD)             AS TotalQty,
    ROUND(SUM(f.TOTALREVENUE), 2)   AS TotalRevenue
FROM FACT_SALES f
JOIN DIM_DATE   d ON f.DATEID = d.DATEID
GROUP BY ROLLUP (d.YEAR, d.QUARTER, d.MONTH)
ORDER BY d.YEAR   NULLS LAST,
         d.QUARTER NULLS LAST,
         d.MONTH   NULLS LAST;


-- A2: Revenue by Region > City > Restaurant (geographic hierarchy)
-- Rolls up from individual restaurant revenue to city totals,
-- then regional totals, and finally a network-wide grand total.
SELECT
    r.REGIONNAME,
    r.CITYNAME,
    r.RESTNAME,
    SUM(f.QUANTITYSOLD)           AS TotalSold,
    ROUND(SUM(f.TOTALREVENUE), 2) AS TotalRevenue
FROM FACT_SALES       f
JOIN DIM_RESTAURANT   r ON f.RESTAURANTID = r.RESTAURANTID
GROUP BY ROLLUP (r.REGIONNAME, r.CITYNAME, r.RESTNAME)
ORDER BY r.REGIONNAME NULLS LAST,
         r.CITYNAME   NULLS LAST,
         r.RESTNAME   NULLS LAST;


-- A3: Revenue by Category > Menu Item (product hierarchy)
-- Shows revenue per dish with category-level subtotals.
-- Identifies which categories and items drive the most revenue.
SELECT
    m.CATEGORYNAME,
    m.ITEMNAME,
    SUM(f.QUANTITYSOLD)           AS UnitsSold,
    ROUND(SUM(f.TOTALREVENUE), 2) AS Revenue
FROM FACT_SALES     f
JOIN DIM_MENUITEM   m ON f.ITEMID = m.ITEMID
GROUP BY ROLLUP (m.CATEGORYNAME, m.ITEMNAME)
ORDER BY m.CATEGORYNAME NULLS LAST,
         Revenue DESC   NULLS LAST;

--------------------------------------------------------------------------------------------------------------------------------------

-- B. CUBE QUERIES


-- B1: Revenue CUBE - Year x Region
-- Generates every combination: year+region, year-only,
-- region-only, and grand total. Full cross-dimensional matrix.
SELECT
    d.YEAR,
    r.REGIONNAME,
    ROUND(SUM(f.TOTALREVENUE), 2) AS Revenue,
    GROUPING(d.YEAR)              AS GRP_YEAR,
    GROUPING(r.REGIONNAME)        AS GRP_REGION
FROM FACT_SALES       f
JOIN DIM_DATE         d ON f.DATEID       = d.DATEID
JOIN DIM_RESTAURANT   r ON f.RESTAURANTID = r.RESTAURANTID
GROUP BY CUBE (d.YEAR, r.REGIONNAME)
ORDER BY d.YEAR      NULLS LAST,
         r.REGIONNAME NULLS LAST;


-- B2: Quantity CUBE - Category x Loyalty Tier
-- Analyzes which food categories are preferred by each
-- loyalty tier (Gold, Silver, Bronze), including all marginal totals.
SELECT
    m.CATEGORYNAME,
    c.LOYALTYTIER,
    SUM(f.QUANTITYSOLD)           AS TotalQty,
    ROUND(SUM(f.TOTALREVENUE), 2) AS Revenue
FROM FACT_SALES     f
JOIN DIM_MENUITEM   m ON f.ITEMID      = m.ITEMID
JOIN DIM_CUSTOMER   c ON f.CUSTOMERID  = c.CUSTOMERID
GROUP BY CUBE (m.CATEGORYNAME, c.LOYALTYTIER)
ORDER BY m.CATEGORYNAME NULLS LAST,
         c.LOYALTYTIER  NULLS LAST;


-- B3: Revenue CUBE - City x Day of Week
-- Cross-analyzes which days perform best per city.
-- Reveals weekend peaks and weekday patterns by location.
SELECT
    r.CITYNAME,
    d.DAYOFWEEK,
    ROUND(SUM(f.TOTALREVENUE), 2) AS Revenue,
    SUM(f.QUANTITYSOLD)           AS TotalQty
FROM FACT_SALES       f
JOIN DIM_RESTAURANT   r ON f.RESTAURANTID = r.RESTAURANTID
JOIN DIM_DATE         d ON f.DATEID       = d.DATEID
GROUP BY CUBE (r.CITYNAME, d.DAYOFWEEK)
ORDER BY r.CITYNAME  NULLS LAST,
         d.DAYOFWEEK NULLS LAST;


--------------------------------------------------------------------------------------------------------------------------------------
-- C. PARTITION QUERIES


-- C1: Each item's revenue vs. its category total
-- Uses SUM OVER PARTITION BY to add a category-total column
-- alongside each row, without collapsing the result set.
SELECT
    m.CATEGORYNAME,
    m.ITEMNAME,
    ROUND(SUM(f.TOTALREVENUE), 2)                    AS ItemRev,
    ROUND(SUM(SUM(f.TOTALREVENUE))
          OVER (PARTITION BY m.CATEGORYNAME), 2)     AS CatTotal,
    ROUND(SUM(f.TOTALREVENUE) /
          SUM(SUM(f.TOTALREVENUE))
          OVER (PARTITION BY m.CATEGORYNAME)
          * 100, 2)                                  AS PctOfCategory
FROM FACT_SALES   f
JOIN DIM_MENUITEM m ON f.ITEMID = m.ITEMID
GROUP BY m.CATEGORYNAME, m.ITEMNAME
ORDER BY m.CATEGORYNAME, ItemRev DESC;


-- C2: Each restaurant's avg quantity vs. its region average
-- Benchmarks individual restaurant performance within its region.
SELECT
    r.REGIONNAME,
    r.RESTNAME,
    ROUND(AVG(f.QUANTITYSOLD), 2)                    AS RestAvg,
    ROUND(AVG(AVG(f.QUANTITYSOLD))
          OVER (PARTITION BY r.REGIONNAME), 2)       AS RegionAvg,
    ROUND(AVG(f.QUANTITYSOLD) -
          AVG(AVG(f.QUANTITYSOLD))
          OVER (PARTITION BY r.REGIONNAME), 2)       AS DiffFromRegionAvg
FROM FACT_SALES      f
JOIN DIM_RESTAURANT  r ON f.RESTAURANTID = r.RESTAURANTID
GROUP BY r.REGIONNAME, r.RESTNAME
ORDER BY r.REGIONNAME, RestAvg DESC;


-- C3: Customer spending vs. their loyalty tier average
-- Compares each customer's total spend to peers in the same tier.
-- Helps identify under- and over-performers within each tier.
SELECT
    c.LOYALTYTIER,
    c.FULLNAME,
    ROUND(SUM(f.TOTALREVENUE), 2)                    AS TotalSpend,
    ROUND(AVG(SUM(f.TOTALREVENUE))
          OVER (PARTITION BY c.LOYALTYTIER), 2)      AS TierAvg,
    ROUND(SUM(f.TOTALREVENUE) -
          AVG(SUM(f.TOTALREVENUE))
          OVER (PARTITION BY c.LOYALTYTIER), 2)      AS DiffFromTierAvg
FROM FACT_SALES    f
JOIN DIM_CUSTOMER  c ON f.CUSTOMERID = c.CUSTOMERID
GROUP BY c.LOYALTYTIER, c.FULLNAME
ORDER BY c.LOYALTYTIER, TotalSpend DESC;


--------------------------------------------------------------------------------------------------------------------------------------
-- D. WINDOW FUNCTIONS

-- D1: Cumulative (running total) daily revenue
-- Tracks total revenue growth day by day across the full dataset.
-- SUM OVER ORDER BY creates a monotonically increasing running total.
SELECT
    d.FULLDATE,
    ROUND(SUM(f.TOTALREVENUE), 2)    AS DailyRevenue,
    ROUND(SUM(SUM(f.TOTALREVENUE))
          OVER (ORDER BY d.FULLDATE
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 2)
                                     AS RunningTotal
FROM FACT_SALES f
JOIN DIM_DATE   d ON f.DATEID = d.DATEID
GROUP BY d.FULLDATE
ORDER BY d.FULLDATE;


-- D2: Month-over-month revenue comparison using LAG
-- LAG retrieves the previous month's value without a self-join.
-- NULL in LastMonth = the first month in the dataset.
SELECT
    d.YEAR,
    d.MONTH,
    ROUND(SUM(f.TOTALREVENUE), 2)    AS CurrentMonth,
    ROUND(LAG(SUM(f.TOTALREVENUE))
          OVER (ORDER BY d.YEAR, d.MONTH), 2)
                                     AS LastMonth,
    ROUND(SUM(f.TOTALREVENUE) -
          LAG(SUM(f.TOTALREVENUE))
          OVER (ORDER BY d.YEAR, d.MONTH), 2)
                                     AS MoMChange
FROM FACT_SALES f
JOIN DIM_DATE   d ON f.DATEID = d.DATEID
GROUP BY d.YEAR, d.MONTH
ORDER BY d.YEAR, d.MONTH;


-- D3: 7-day moving average revenue
-- Smooths daily fluctuations by averaging the current day and
-- the 6 preceding days. Reveals the underlying business trend.
SELECT
    d.FULLDATE,
    ROUND(SUM(f.TOTALREVENUE), 2)    AS DailyRevenue,
    ROUND(AVG(SUM(f.TOTALREVENUE))
          OVER (ORDER BY d.FULLDATE
                ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2)
                                     AS MovingAvg7Day
FROM FACT_SALES f
JOIN DIM_DATE   d ON f.DATEID = d.DATEID
GROUP BY d.FULLDATE
ORDER BY d.FULLDATE;

--------------------------------------------------------------------------------------------------------------------------------------
-- E. RANK FUNCTIONS


-- E1: Menu item sales ranking using RANK
-- RANK() assigns the same rank to ties and skips the next rank.
-- Example: items with equal quantity get rank 1, 1, 3 (not 1, 1, 2).
SELECT
    m.ITEMNAME,
    SUM(f.QUANTITYSOLD)                                       AS TotalSold,
    RANK() OVER (ORDER BY SUM(f.QUANTITYSOLD) DESC)           AS SalesRank
FROM FACT_SALES   f
JOIN DIM_MENUITEM m ON f.ITEMID = m.ITEMID
GROUP BY m.ITEMNAME
ORDER BY SalesRank;


-- E2: Top spending customers using DENSE_RANK
-- DENSE_RANK does NOT skip ranks on ties: 1, 1, 2, 2, 3 ...
-- Produces a clean leaderboard without gaps in rank numbers.
SELECT
    c.FULLNAME,
    c.LOYALTYTIER,
    ROUND(SUM(f.TOTALREVENUE), 2)                              AS TotalSpent,
    DENSE_RANK() OVER (ORDER BY SUM(f.TOTALREVENUE) DESC)      AS SpendRank
FROM FACT_SALES   f
JOIN DIM_CUSTOMER c ON f.CUSTOMERID = c.CUSTOMERID
GROUP BY c.FULLNAME, c.LOYALTYTIER
ORDER BY SpendRank;


-- E3: Restaurant performance quartiles using NTILE(4)
-- Divides all restaurants into 4 equal buckets by total revenue.
-- Quartile 1 = top 25% best performers; Quartile 4 = bottom 25%.
SELECT
    r.RESTNAME,
    r.CITYNAME,
    ROUND(SUM(f.TOTALREVENUE), 2)                              AS Revenue,
    NTILE(4) OVER (ORDER BY SUM(f.TOTALREVENUE) DESC)          AS Quartile
FROM FACT_SALES      f
JOIN DIM_RESTAURANT  r ON f.RESTAURANTID = r.RESTAURANTID
GROUP BY r.RESTNAME, r.CITYNAME
ORDER BY Quartile, Revenue DESC;



