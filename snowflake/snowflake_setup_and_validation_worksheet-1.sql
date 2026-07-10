-- ============================================================
-- PROJECT: Insurance Claims Leakage & KPI Trust Control Tower
-- STEP 1: Create Snowflake environment
-- ============================================================

-- Create a small compute warehouse.
-- Warehouse = compute engine that runs SQL queries.
CREATE WAREHOUSE IF NOT EXISTS INSURANCE_WH
  WAREHOUSE_SIZE = 'XSMALL'
  AUTO_SUSPEND = 60
  AUTO_RESUME = TRUE
  INITIALLY_SUSPENDED = TRUE;


-- Create database for raw source data.
-- Raw data means original data loaded from CSV files.
CREATE DATABASE IF NOT EXISTS INSURANCE_RAW;


-- Create database for cleaned analytics models.
-- dbt will later create staging, intermediate, and mart models here.
CREATE DATABASE IF NOT EXISTS INSURANCE_ANALYTICS;


-- Create RAW schema inside INSURANCE_RAW database.
-- Raw tables such as RAW_CUSTOMERS, RAW_POLICIES, RAW_CLAIMS will live here.
CREATE SCHEMA IF NOT EXISTS INSURANCE_RAW.RAW;


-- Create DBT_DEV schema inside INSURANCE_ANALYTICS database.
-- dbt will use this area to build cleaned and reporting-ready models.
CREATE SCHEMA IF NOT EXISTS INSURANCE_ANALYTICS.DBT_DEV;


-- Set working context.
-- This tells Snowflake which warehouse, database, and schema to use.
USE WAREHOUSE INSURANCE_WH;
USE DATABASE INSURANCE_RAW;
USE SCHEMA RAW;


-- Final check.
SELECT
  CURRENT_ROLE() AS current_role,
  CURRENT_WAREHOUSE() AS current_warehouse,
  CURRENT_DATABASE() AS current_database,
  CURRENT_SCHEMA() AS current_schema;


 -- ============================================================
-- PROJECT: Insurance Claims Leakage & KPI Trust Control Tower
-- STEP 2: Create raw tables, CSV file format, and Snowflake stage
-- ============================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE INSURANCE_WH;
USE DATABASE INSURANCE_RAW;
USE SCHEMA RAW;


-- ============================================================
-- 1. CREATE CSV FILE FORMAT
-- ============================================================

CREATE OR REPLACE FILE FORMAT INSURANCE_CSV_FORMAT
  TYPE = CSV
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  TRIM_SPACE = TRUE
  NULL_IF = ('NULL', 'null', '')
  ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;


-- ============================================================
-- 2. CREATE INTERNAL STAGE
-- ============================================================

CREATE OR REPLACE STAGE INSURANCE_RAW_STAGE
  FILE_FORMAT = INSURANCE_CSV_FORMAT;


-- ============================================================
-- 3. CREATE RAW CUSTOMERS TABLE
-- ============================================================

CREATE OR REPLACE TABLE RAW_CUSTOMERS (
  CUSTOMER_ID VARCHAR,
  CUSTOMER_NAME VARCHAR,
  GENDER VARCHAR,
  AGE NUMBER,
  STATE VARCHAR,
  REGION VARCHAR,
  CUSTOMER_SEGMENT VARCHAR,
  CREATED_DATE DATE
);


-- ============================================================
-- 4. CREATE RAW AGENTS TABLE
-- ============================================================

CREATE OR REPLACE TABLE RAW_AGENTS (
  AGENT_ID VARCHAR,
  AGENT_NAME VARCHAR,
  STATE VARCHAR,
  REGION VARCHAR,
  HIRE_DATE DATE,
  AGENT_TIER VARCHAR
);


-- ============================================================
-- 5. CREATE RAW POLICIES TABLE
-- ============================================================

CREATE OR REPLACE TABLE RAW_POLICIES (
  POLICY_ID VARCHAR,
  CUSTOMER_ID VARCHAR,
  AGENT_ID VARCHAR,
  POLICY_TYPE VARCHAR,
  POLICY_START_DATE DATE,
  POLICY_END_DATE DATE,
  POLICY_STATUS VARCHAR,
  REGION VARCHAR,
  ANNUAL_PREMIUM NUMBER(12,2)
);


-- ============================================================
-- 6. CREATE RAW PREMIUMS TABLE
-- ============================================================

CREATE OR REPLACE TABLE RAW_PREMIUMS (
  PREMIUM_ID VARCHAR,
  POLICY_ID VARCHAR,
  PAYMENT_DATE DATE,
  PREMIUM_AMOUNT NUMBER(12,2),
  PAYMENT_STATUS VARCHAR,
  PAYMENT_METHOD VARCHAR
);


-- ============================================================
-- 7. CREATE RAW CLAIMS TABLE
-- ============================================================

CREATE OR REPLACE TABLE RAW_CLAIMS (
  CLAIM_ID VARCHAR,
  POLICY_ID VARCHAR,
  CLAIM_DATE DATE,
  CLAIM_TYPE VARCHAR,
  CLAIM_STATUS VARCHAR,
  CLAIM_AMOUNT NUMBER(12,2),
  PAID_AMOUNT NUMBER(12,2),
  CLAIM_SEVERITY_LEVEL VARCHAR
);


-- ============================================================
-- 8. CREATE RAW CLAIM ADJUSTMENTS TABLE
-- ============================================================
--if I run this script later after loading data, it will recreate the tables and delete the loaded data.
--once data is loaded, do not rerun this fullINSURANCE_RAW.RAW.INSURANCE_RAW_STAGEINSURANCE_RAW.RAW.INSURANCE_RAW_STAGEINSURANCE_RAW.RAW.INSURANCE_RAW_STAGE script unless I want to reset the project.
CREATE OR REPLACE TABLE RAW_CLAIM_ADJUSTMENTS (
  ADJUSTMENT_ID VARCHAR,
  CLAIM_ID VARCHAR,
  ADJUSTMENT_DATE DATE,
  ADJUSTMENT_REASON VARCHAR,
  ORIGINAL_AMOUNT NUMBER(12,2),
  ADJUSTED_AMOUNT NUMBER(12,2),
  ADJUSTMENT_STATUS VARCHAR
);


-- ============================================================
-- 9. VERIFY OBJECTS WERE CREATED
-- ============================================================

SHOW TABLES IN SCHEMA INSURANCE_RAW.RAW;

SHOW STAGES IN SCHEMA INSURANCE_RAW.RAW;

SHOW FILE FORMATS IN SCHEMA INSURANCE_RAW.RAW;

--create csv format
CREATE OR REPLACE FILE FORMAT INSURANCE_CSV_FORMAT
  TYPE = CSV
  FIELD_DELIMITER = ','
  SKIP_HEADER = 1
  FIELD_OPTIONALLY_ENCLOSED_BY = '"'
  TRIM_SPACE = TRUE
  NULL_IF = ('NULL', 'null', '')
  ERROR_ON_COLUMN_COUNT_MISMATCH = FALSE;

--create stage
  CREATE OR REPLACE STAGE INSURANCE_RAW_STAGE
  FILE_FORMAT = INSURANCE_CSV_FORMAT;

--checking tables summary
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE INSURANCE_WH;
USE DATABASE INSURANCE_RAW;
USE SCHEMA RAW;

SELECT 'RAW_CUSTOMERS' AS table_name, COUNT(*) AS row_count FROM RAW_CUSTOMERS
UNION ALL
SELECT 'RAW_AGENTS', COUNT(*) FROM RAW_AGENTS
UNION ALL
SELECT 'RAW_POLICIES', COUNT(*) FROM RAW_POLICIES
UNION ALL
SELECT 'RAW_PREMIUMS', COUNT(*) FROM RAW_PREMIUMS
UNION ALL
SELECT 'RAW_CLAIMS', COUNT(*) FROM RAW_CLAIMS
UNION ALL
SELECT 'RAW_CLAIM_ADJUSTMENTS', COUNT(*) FROM RAW_CLAIM_ADJUSTMENTS;

--Check sample data
SELECT * FROM RAW_CUSTOMERS LIMIT 5;
SELECT * FROM RAW_AGENTS LIMIT 5;
SELECT * FROM RAW_POLICIES LIMIT 5;
SELECT * FROM RAW_PREMIUMS LIMIT 5;
SELECT * FROM RAW_CLAIMS LIMIT 5;
SELECT * FROM RAW_CLAIM_ADJUSTMENTS LIMIT 5;

--Check relationship quality. This is important because later dbt will test relationships.
-- Claims with missing policy IDs
SELECT COUNT(*) AS claims_missing_policy
FROM RAW_CLAIMS c
LEFT JOIN RAW_POLICIES p
    ON c.POLICY_ID = p.POLICY_ID
WHERE p.POLICY_ID IS NULL; --expected output is '0' meaning every claim belongs to a valid policy.
-- Premium payments with missing policy IDs
SELECT COUNT(*) AS premiums_missing_policy
FROM RAW_PREMIUMS pr
LEFT JOIN RAW_POLICIES p
    ON pr.POLICY_ID = p.POLICY_ID
WHERE p.POLICY_ID IS NULL;
-- Policies with missing customers
SELECT COUNT(*) AS policies_missing_customer
FROM RAW_POLICIES p
LEFT JOIN RAW_CUSTOMERS c
    ON p.CUSTOMER_ID = c.CUSTOMER_ID
WHERE c.CUSTOMER_ID IS NULL;
-- Policies with missing agents
SELECT COUNT(*) AS policies_missing_agent
FROM RAW_POLICIES p
LEFT JOIN RAW_AGENTS a
    ON p.AGENT_ID = a.AGENT_ID
WHERE a.AGENT_ID IS NULL; --These above checks prove my raw data is connected properly.

--Check insurance KPIs from raw data
--This is simple business check, not the final mart yet. Later dbt will make this cleaner and more reliable
SELECT
    p.POLICY_TYPE,
    COUNT(DISTINCT p.POLICY_ID) AS policy_count,
    SUM(pr.PREMIUM_AMOUNT) AS total_premium,
    SUM(c.PAID_AMOUNT) AS total_paid_claims,
    SUM(c.PAID_AMOUNT) / NULLIF(SUM(pr.PREMIUM_AMOUNT), 0) AS rough_loss_ratio
FROM RAW_POLICIES p
LEFT JOIN RAW_PREMIUMS pr
    ON p.POLICY_ID = pr.POLICY_ID
LEFT JOIN RAW_CLAIMS c
    ON p.POLICY_ID = c.POLICY_ID
GROUP BY p.POLICY_TYPE
ORDER BY rough_loss_ratio DESC;


--verify staging views in Snowflake
--The staging row counts should match the raw table row counts.
--That proves:
--CSV files loaded correctly
--raw tables are readable
--dbt staging views are working
--no records were lost between raw and staging
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE INSURANCE_WH;

SELECT 'STG_CUSTOMERS' AS model_name, COUNT(*) AS row_count
FROM INSURANCE_ANALYTICS.DBT_DEV_STAGING.STG_CUSTOMERS

UNION ALL

SELECT 'STG_AGENTS', COUNT(*)
FROM INSURANCE_ANALYTICS.DBT_DEV_STAGING.STG_AGENTS

UNION ALL

SELECT 'STG_POLICIES', COUNT(*)
FROM INSURANCE_ANALYTICS.DBT_DEV_STAGING.STG_POLICIES

UNION ALL

SELECT 'STG_PREMIUMS', COUNT(*)
FROM INSURANCE_ANALYTICS.DBT_DEV_STAGING.STG_PREMIUMS

UNION ALL

SELECT 'STG_CLAIMS', COUNT(*)
FROM INSURANCE_ANALYTICS.DBT_DEV_STAGING.STG_CLAIMS

UNION ALL

SELECT 'STG_CLAIM_ADJUSTMENTS', COUNT(*)
FROM INSURANCE_ANALYTICS.DBT_DEV_STAGING.STG_CLAIM_ADJUSTMENTS;


--Verify intermediate models in Snowflake
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE INSURANCE_WH;

SELECT 'INT_POLICY_PREMIUM_SUMMARY' AS model_name, COUNT(*) AS row_count
FROM INSURANCE_ANALYTICS.DBT_DEV_INTERMEDIATE.INT_POLICY_PREMIUM_SUMMARY

UNION ALL

SELECT 'INT_POLICY_CLAIM_SUMMARY', COUNT(*)
FROM INSURANCE_ANALYTICS.DBT_DEV_INTERMEDIATE.INT_POLICY_CLAIM_SUMMARY

UNION ALL

SELECT 'INT_CLAIM_LEAKAGE_FLAGS', COUNT(*)
FROM INSURANCE_ANALYTICS.DBT_DEV_INTERMEDIATE.INT_CLAIM_LEAKAGE_FLAGS;

--Check the leakage flags
SELECT
    SUM(duplicate_claim_flag) AS duplicate_claims,
    SUM(claim_after_policy_end_flag) AS claims_after_policy_end,
    SUM(claim_without_premium_flag) AS claims_without_premium,
    SUM(high_severity_claim_flag) AS high_severity_claims
FROM INSURANCE_ANALYTICS.DBT_DEV_INTERMEDIATE.INT_CLAIM_LEAKAGE_FLAGS;


--Preview risky claims
    SELECT
    claim_id,
    policy_id,
    policy_type,
    region,
    claim_date,
    claim_type,
    paid_amount,
    duplicate_claim_flag,
    claim_after_policy_end_flag,
    claim_without_premium_flag,
    high_severity_claim_flag
FROM INSURANCE_ANALYTICS.DBT_DEV_INTERMEDIATE.INT_CLAIM_LEAKAGE_FLAGS
WHERE duplicate_claim_flag = 1
   OR claim_after_policy_end_flag = 1
   OR claim_without_premium_flag = 1
   OR high_severity_claim_flag = 1
ORDER BY paid_amount DESC
LIMIT 25;
--Till now I built business logic to summarize premium payments, summarize claim activity, and identify claims leakage risks.


--
USE ROLE ACCOUNTADMIN;
USE WAREHOUSE INSURANCE_WH;

SHOW SCHEMAS LIKE '%MARTS%' IN DATABASE INSURANCE_ANALYTICS;


--
SELECT
    table_schema,
    table_name,
    table_type
FROM INSURANCE_ANALYTICS.INFORMATION_SCHEMA.TABLES
WHERE table_name ILIKE 'MART_%'
ORDER BY table_schema, table_name;

--Validate mart row counts
SELECT
    'MART_INSURANCE_PERFORMANCE' AS mart_name,
    COUNT(*) AS row_count
FROM INSURANCE_ANALYTICS.DBT_DEV_MARTS.MART_INSURANCE_PERFORMANCE

UNION ALL

SELECT
    'MART_CLAIMS_LEAKAGE',
    COUNT(*)
FROM INSURANCE_ANALYTICS.DBT_DEV_MARTS.MART_CLAIMS_LEAKAGE;
--Expected logic: MART_INSURANCE_PERFORMANCE row count = number of policies
--MART_CLAIMS_LEAKAGE row count = number of claims


--Validate executive KPIs
SELECT
    policy_type,
    COUNT(*) AS policy_count,
    SUM(total_paid_premium) AS total_paid_premium,
    SUM(total_paid_claim_amount) AS total_paid_claims,
    SUM(total_paid_claim_amount) / NULLIF(SUM(total_paid_premium), 0) AS loss_ratio,
    AVG(claim_severity) AS avg_claim_severity
FROM INSURANCE_ANALYTICS.DBT_DEV_MARTS.MART_INSURANCE_PERFORMANCE
GROUP BY policy_type
ORDER BY loss_ratio DESC;


--Validate claims leakage logic
SELECT
    SUM(duplicate_claim_flag) AS duplicate_claims,
    SUM(claim_after_policy_end_flag) AS claims_after_policy_end,
    SUM(claim_without_premium_flag) AS claims_without_premium,
    SUM(high_severity_claim_flag) AS high_severity_claims,
    COUNT(CASE WHEN leakage_risk_score > 0 THEN 1 END) AS total_risk_claims
FROM INSURANCE_ANALYTICS.DBT_DEV_MARTS.MART_CLAIMS_LEAKAGE;


--
SELECT
    claim_id,
    policy_id,
    policy_type,
    region,
    claim_date,
    claim_type,
    paid_amount,
    duplicate_claim_flag,
    claim_after_policy_end_flag,
    claim_without_premium_flag,
    high_severity_claim_flag,
    adjustment_count,
    total_adjustment_delta,
    leakage_risk_score
FROM INSURANCE_ANALYTICS.DBT_DEV_MARTS.MART_CLAIMS_LEAKAGE
WHERE leakage_risk_score > 0
ORDER BY leakage_risk_score DESC, paid_amount DESC
LIMIT 25;