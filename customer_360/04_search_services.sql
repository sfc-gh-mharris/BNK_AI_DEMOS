/*=============================================================================
  Customer 360 — Cortex Search Services
  Database: BNK | Schema: CUSTOMER_360 | Warehouse: BNK_WH
  
  Creates two Cortex Search Services for semantic document retrieval:
  1. CUSTOMER_NOTES_SEARCH - Advisor notes and interaction summaries
  2. POLICY_SEARCH - Bank policy documents
  
  Run AFTER 01_ddl.sql and 02_data.sql (requires populated tables).
=============================================================================*/

USE DATABASE BNK;
USE SCHEMA CUSTOMER_360;
USE WAREHOUSE BNK_WH;

-------------------------------------------------------------------------------
-- CUSTOMER_NOTES_SEARCH
-- Indexes advisor notes for semantic retrieval by the Customer 360 Agent.
-- Filterable by customer_id (to scope to a specific customer) and agent_name.
-------------------------------------------------------------------------------
CREATE CORTEX SEARCH SERVICE IF NOT EXISTS BNK.CUSTOMER_360.CUSTOMER_NOTES_SEARCH
  ON note_text
  ATTRIBUTES customer_id, agent_name, note_date
  WAREHOUSE = BNK_WH
  TARGET_LAG = '1 day'
  EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
  COMMENT = 'Cortex Search Service indexing free-text advisor notes from the CUSTOMER_NOTES table. Supports semantic search over interaction summaries, relationship context, and follow-up items. Used by the Customer 360 Agent to answer questions about past customer interactions and advisor observations.'
AS (
  SELECT 
    note_id,
    customer_id,
    agent_name,
    note_date,
    note_text
  FROM BNK.CUSTOMER_360.CUSTOMER_NOTES
);

-------------------------------------------------------------------------------
-- POLICY_SEARCH
-- Indexes bank policy documents for semantic retrieval.
-- Filterable by category (Fees, Disputes, Privacy, Compliance, Products, Operations)
-- and title for targeted policy lookup.
-------------------------------------------------------------------------------
CREATE CORTEX SEARCH SERVICE IF NOT EXISTS BNK.CUSTOMER_360.POLICY_SEARCH
  ON content
  ATTRIBUTES category, title, effective_date
  WAREHOUSE = BNK_WH
  TARGET_LAG = '1 day'
  EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
  COMMENT = 'Cortex Search Service indexing full-text bank policy documents from the POLICIES table. Supports semantic search over fee schedules, dispute procedures, compliance requirements, and operational standards. Used by the Customer 360 Agent to answer policy and procedure questions.'
AS (
  SELECT 
    policy_id,
    title,
    category,
    effective_date,
    content
  FROM BNK.CUSTOMER_360.POLICIES
);
