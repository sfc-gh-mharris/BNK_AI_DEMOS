-- =============================================================================
-- WEALTH MANAGEMENT — INFRASTRUCTURE SETUP
-- Schema: BNK.WEALTH_MGMT
--
-- Creates only the objects needed for the Wealth Management use case.
-- Safe to re-run (all IF NOT EXISTS).
-- NEVER drops or replaces existing objects.
-- =============================================================================

CREATE DATABASE IF NOT EXISTS BNK
    COMMENT = 'Banking AI demonstration database. Contains schemas for Customer 360, KYC/AML, Lending Analytics, and Wealth Management use cases.';

CREATE SCHEMA IF NOT EXISTS BNK.WEALTH_MGMT
    COMMENT = 'Wealth Management use case. Enterprise AI platform combining Cortex Analyst, Cortex Search, and AI_PARSE_DOCUMENT for advisor self-service.';

CREATE WAREHOUSE IF NOT EXISTS BNK_WH
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Dedicated compute for BNK demo workloads. Auto-suspends after 5 minutes.';

CREATE STAGE IF NOT EXISTS BNK.WEALTH_MGMT.ONBOARDING_DOCS
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
    COMMENT = 'Internal stage for synthetic account-opening documents (PDFs) for onboarding.';

USE DATABASE BNK;
USE SCHEMA WEALTH_MGMT;
USE WAREHOUSE BNK_WH;
