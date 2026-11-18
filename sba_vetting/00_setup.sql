/*=============================================================================
  SBA Borrower and Program Integrity (NSBPS / SBAID) - Setup
  Database: BNK | Schema: SBA_VETTING | Warehouse: BNK_WH
=============================================================================*/

USE ROLE ACCOUNTADMIN;

CREATE DATABASE IF NOT EXISTS BNK
    COMMENT = 'Banking and Federal Lending AI Demos database.';

CREATE SCHEMA IF NOT EXISTS BNK.SBA_VETTING
    COMMENT = 'U.S. Small Business Administration (SBA) National Small Business Profile Service (NSBPS) borrower vetting, ownership verification, tax transcript reconciliation, and OIG fraud defense.';

CREATE WAREHOUSE IF NOT EXISTS BNK_WH
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = FALSE
    COMMENT = 'Shared compute warehouse for BNK AI Demo workloads.';

USE DATABASE BNK;
USE SCHEMA SBA_VETTING;
USE WAREHOUSE BNK_WH;

CREATE STAGE IF NOT EXISTS BNK.SBA_VETTING.SBA_DOCUMENTS
    ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE')
    DIRECTORY = (ENABLE = TRUE)
    COMMENT = 'Internal stage for SBA loan and certification documents (Form 1919, IRS 4506-C/1120-S transcripts, multi-tier LLC Operating Agreements, and principal IDs) processed by AI_PARSE_DOCUMENT.';
