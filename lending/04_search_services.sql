/*=============================================================================
  LENDING ANALYTICS - CORTEX SEARCH SERVICES
  Database: BNK | Schema: LENDING | Warehouse: BNK_WH
  
  Creates two Cortex Search services for semantic retrieval:
  1. LENDING_POLICY_SEARCH - Internal mortgage lending policy documents
  2. INTERACTION_SEARCH - Borrower interaction history and conversation summaries
=============================================================================*/

USE DATABASE BNK;
USE SCHEMA BNK.LENDING;
USE WAREHOUSE BNK_WH;

-------------------------------------------------------------------------------
-- LENDING POLICY SEARCH SERVICE
-- Enables semantic search over internal lending policy documents.
-- Used by the Lending Agent to retrieve relevant policy guidance
-- (underwriting criteria, forbearance rules, compliance requirements)
-- when relationship managers ask about lending procedures.
-------------------------------------------------------------------------------
CREATE CORTEX SEARCH SERVICE IF NOT EXISTS BNK.LENDING.LENDING_POLICY_SEARCH
  ON content
  ATTRIBUTES category, title
  WAREHOUSE = BNK_WH
  TARGET_LAG = '1 day'
  EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
  COMMENT = 'Semantic search service over internal mortgage lending policy documents. Indexes full policy text with category and title attributes for filtered retrieval. Covers underwriting standards, servicing procedures, collections guidelines, compliance requirements, pricing frameworks, and loan modification criteria. Refreshes daily from BNK.LENDING.LENDING_POLICIES.'
AS (
  SELECT
    policy_id,
    title,
    category,
    effective_date,
    content
  FROM BNK.LENDING.LENDING_POLICIES
);

-------------------------------------------------------------------------------
-- INTERACTION HISTORY SEARCH SERVICE
-- Enables semantic search over borrower conversation summaries.
-- Used by the Lending Agent to retrieve relevant past interactions
-- when relationship managers ask about customer history, prior requests,
-- or what has been discussed with a specific borrower.
-------------------------------------------------------------------------------
CREATE CORTEX SEARCH SERVICE IF NOT EXISTS BNK.LENDING.INTERACTION_SEARCH
  ON summary
  ATTRIBUTES borrower_id, channel, topic
  WAREHOUSE = BNK_WH
  TARGET_LAG = '1 day'
  EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
  COMMENT = 'Semantic search service over borrower interaction history. Indexes agent-written conversation summaries with borrower_id, channel, and topic attributes for filtered retrieval. Covers phone calls, emails, branch visits, portal activity, and chat sessions across all servicing topics. Refreshes daily from BNK.LENDING.INTERACTION_HISTORY.'
AS (
  SELECT
    interaction_id,
    borrower_id,
    channel,
    topic,
    interaction_date,
    summary,
    agent_name
  FROM BNK.LENDING.INTERACTION_HISTORY
);
