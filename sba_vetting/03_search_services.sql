/*=============================================================================
  SBA Borrower and Program Integrity (NSBPS / SBAID) - Cortex Search Service
  Database: BNK | Schema: SBA_VETTING | Warehouse: BNK_WH
=============================================================================*/

USE DATABASE BNK;
USE SCHEMA SBA_VETTING;
USE WAREHOUSE BNK_WH;

CREATE CORTEX SEARCH SERVICE IF NOT EXISTS BNK.SBA_VETTING.SBA_SOP_SEARCH
  ON content
  ATTRIBUTES program_scope, category, title, authority_citation
  WAREHOUSE = BNK_WH
  TARGET_LAG = '1 day'
  EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
  COMMENT = 'Cortex Search service over SBA SOP 50 10 8.1, Policy Notice 5000-876441, News Release 25-42 age guardrails, IRS Form 4506-C verification, CAIVRS/SAM.gov/Do Not Pay rules, 13 CFR 121/124/125 contracting controls, and OIG fraud referral standards.'
AS (
  SELECT
    policy_id,
    title,
    program_scope,
    category,
    effective_date,
    authority_citation,
    content
  FROM BNK.SBA_VETTING.SBA_SOP_POLICIES
);
