-- =============================================================================
-- KYC / AML — INFRASTRUCTURE SETUP
-- Schema: BNK.KYC_AML
--
-- Creates only the objects needed for the KYC/AML use case.
-- Safe to re-run (all IF NOT EXISTS).
-- NEVER drops or replaces existing objects.
-- =============================================================================

CREATE DATABASE IF NOT EXISTS BNK
    COMMENT = 'Banking AI demonstration database. Contains schemas for Customer 360, KYC/AML, Lending Analytics, and Wealth Management use cases.';

CREATE SCHEMA IF NOT EXISTS BNK.KYC_AML
    COMMENT = 'KYC/AML use case. Automated document processing using AI_PARSE_DOCUMENT to extract and classify onboarding documents at scale.';

CREATE WAREHOUSE IF NOT EXISTS BNK_WH
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Dedicated compute for BNK demo workloads. Auto-suspends after 5 minutes.';

CREATE STAGE IF NOT EXISTS BNK.KYC_AML.KYC_DOCUMENTS
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Internal stage for synthetic KYC onboarding documents (PDFs) processed by AI_PARSE_DOCUMENT.';

USE DATABASE BNK;
USE SCHEMA KYC_AML;
USE WAREHOUSE BNK_WH;
