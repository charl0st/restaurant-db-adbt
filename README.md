# 🍽️ Restaurant Database & Data Warehouse Project

**Course:** Advanced Database Techniques (ADBT)  
**Group:** 2ID EN11B | **Student ID:** 10218  
**Platform:** Oracle Database XE (XEPDB1)

---

## 📋 Project Overview

This project implements a full **OLTP → Data Warehouse** pipeline for a restaurant chain network. It covers:

- Operational relational database design (3NF)
- Star-schema data warehouse
- Bulk data loading with SQL Loader
- 15 analytical queries using advanced SQL features

---

## 🗂️ Repository Structure

```
├── sql/
│   ├── operational/          # OLTP database DDL (RESTARUANT_DB schema)
│   ├── datawarehouse/        # Star schema DDL (RESTAURANT_DW schema)
│   ├── etl/                  # SQL Loader control file & utility scripts
│   └── analysis/             # 15 analytical queries
├── data/                     # Seed data (CSV files)
│   ├── fact_sales.csv        # 10,000 fact rows (loaded via SQL Loader)
│   ├── customers.csv
│   ├── employees.csv
│   ├── menuitem.csv
│   └── restaurants.csv
└── docs/                     # Project report (Word document)
```

---

## 🗄️ Database Schemas

### Operational DB — `RESTARUANT_DB` (15 tables)

| # | Table | Description |
|---|-------|-------------|
| 1 | REGIONS | Geographic regions |
| 2 | CITIES | Cities within regions |
| 3 | RESTAURANTS | Restaurant locations |
| 4 | EMPLOYEES | Staff per restaurant |
| 5 | CUSTOMERS | Customer profiles & loyalty points |
| 6 | CATEGORIES | Menu item categories |
| 7 | MENUITEMS | Menu items with prices |
| 8 | INGREDIENTS | Raw ingredients |
| 9 | RECIPES | Item–ingredient mapping |
| 10 | INVENTORY | Stock levels per restaurant |
| 11 | ORDERS | Customer orders |
| 12 | ORDERDETAILS | Line items per order |
| 13 | SUPPLIERS | Ingredient suppliers |
| 14 | PURCHASEORDERS | Supplier purchase orders |
| 15 | PURCHASEORDERDETAILS | Line items per PO |

### Data Warehouse — `RESTAURANT_DW` (Star Schema)

```
               DIM_DATE
                  │
DIM_RESTAURANT ──FACT_SALES── DIM_MENUITEM
                  │
              DIM_CUSTOMER
```

| Table | Type | Key Columns |
|-------|------|-------------|
| FACT_SALES | Fact | SALEID, DATEID, ITEMID, CUSTOMERID, RESTAURANTID, QUANTITYSOLD, TOTALREVENUE |
| DIM_DATE | Dimension | DATEID, FULLDATE, YEAR, QUARTER, MONTH, DAYOFWEEK |
| DIM_RESTAURANT | Dimension | RESTAURANTID, RESTNAME, CITYNAME, REGIONNAME |
| DIM_MENUITEM | Dimension | ITEMID, ITEMNAME, CATEGORYNAME, CURRENTPRICE |
| DIM_CUSTOMER | Dimension | CUSTOMERID, FULLNAME, LOYALTYTIER |

---

## 🚀 Setup Instructions

### Prerequisites

- Oracle Database XE with pluggable database `XEPDB1`
- SQL\*Loader (`sqlldr`) available in PATH
- DBeaver or SQL\*Plus for running DDL

### 1 — Create Schemas

Run both DDL files as SYS or a DBA user:

```sql
-- Operational database
@sql/operational/restaurant_database_ddl.sql

-- Data warehouse
@sql/datawarehouse/restaurant_datawarehouse_ddl.sql
```

> **Note:** The DDL files include `CREATE USER` statements. Add `IDENTIFIED BY <password>` and grant the necessary privileges before running.

### 2 — Load Dimension Data

Import the CSV files into the appropriate dimension tables using your preferred tool (DBeaver import wizard, SQL\*Plus, or external tables).

### 3 — Load Fact Table via SQL Loader

```bash
# Copy files into the container (if using Docker)
docker cp data/fact_sales.csv <container>:/tmp/fact_sales.csv
docker cp sql/etl/fact_sales.ctl <container>:/tmp/fact_sales.ctl
docker exec -it <container> bash

# Run SQL Loader
sqlldr userid=RESTAURANT_DW/<password>@localhost:1521/XEPDB1 \
       control=/tmp/fact_sales.ctl \
       log=/tmp/fact_sales.log \
       bad=/tmp/fact_sales.bad
```

### 4 — Re-load (Reset Fact Table)

```bash
# Truncate and reload if needed
sqlplus RESTAURANT_DW/<password>@localhost:1521/XEPDB1 @sql/etl/fix.sql
```

---

## 📊 Analytical Queries

All 15 queries are in [`sql/analysis/15_queries.sql`](sql/analysis/15_queries.sql), organized into 5 groups:

| Group | Technique | Queries |
|-------|-----------|---------|
| **A** | ROLLUP | Time hierarchy · Geographic hierarchy · Product hierarchy |
| **B** | CUBE | Year × Region · Category × Loyalty Tier · City × Day of Week |
| **C** | PARTITION BY | Item % of category · Restaurant vs. region avg · Customer vs. tier avg |
| **D** | Window Functions | Running total · Month-over-month LAG · 7-day moving average |
| **E** | Rank Functions | RANK (menu items) · DENSE_RANK (customers) · NTILE quartiles (restaurants) |

---

## 📁 Data Files

| File | Rows | Description |
|------|------|-------------|
| `fact_sales.csv` | 10,000 | Sales transactions (loaded via SQL Loader) |
| `customers.csv` | ~200 | Customer master data |
| `employees.csv` | ~50 | Employee records |
| `menuitem.csv` | ~30 | Menu items & categories |
| `restaurants.csv` | ~20 | Restaurant locations |
