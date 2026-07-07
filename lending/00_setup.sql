-- =============================================================================
-- LENDING ANALYTICS — INFRASTRUCTURE SETUP
-- Schema: BNK.LENDING
--
-- Creates only the objects needed for the Lending Analytics use case.
-- Safe to re-run (all IF NOT EXISTS).
-- NEVER drops or replaces existing objects.
-- =============================================================================

CREATE DATABASE IF NOT EXISTS BNK
    COMMENT = 'Banking AI demonstration database. Contains schemas for Customer 360, KYC/AML, Lending Analytics, and Wealth Management use cases.';

CREATE SCHEMA IF NOT EXISTS BNK.LENDING
    COMMENT = 'Lending Analytics use case. Virtual bankers query mortgage portfolios via Cortex Analyst and lending policies via Cortex Search, orchestrated by an Agent.';

CREATE WAREHOUSE IF NOT EXISTS BNK_WH
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Dedicated compute for BNK demo workloads. Auto-suspends after 5 minutes.';

USE DATABASE BNK;
USE SCHEMA LENDING;
USE WAREHOUSE BNK_WH;
