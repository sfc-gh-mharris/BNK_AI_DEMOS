/*=============================================================================
  KYC/AML — Cortex Search Service
  Database: BNK | Schema: KYC_AML | Warehouse: BNK_WH
  
  Creates a Cortex Search Service over KYC_POLICIES for RAG-based
  policy retrieval by the KYC Agent.
=============================================================================*/

USE DATABASE BNK;
USE SCHEMA KYC_AML;
USE WAREHOUSE BNK_WH;

-------------------------------------------------------------------------------
-- KYC_POLICY_SEARCH
-- Enables semantic search over compliance policy full-text content.
-- Filterable by jurisdiction and category for precise policy retrieval.
-- Used by the KYC_AGENT's KYCPolicySearch tool.
-------------------------------------------------------------------------------
CREATE CORTEX SEARCH SERVICE IF NOT EXISTS BNK.KYC_AML.KYC_POLICY_SEARCH
  ON content
  ATTRIBUTES jurisdiction, category, title
  WAREHOUSE = BNK_WH
  TARGET_LAG = '1 day'
  EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
  COMMENT = 'Cortex Search index over KYC/AML compliance policies. Provides semantic retrieval of policy text filterable by jurisdiction (US/UK/EU/APAC/Global) and category (CDD/EDD/PEP/Sanctions/BeneficialOwnership/OngoingMonitoring). Primary retrieval layer for the KYC_AGENT RAG workflow.'
AS (
  SELECT
    policy_id,
    title,
    jurisdiction,
    category,
    effective_date,
    content
  FROM BNK.KYC_AML.KYC_POLICIES
);
