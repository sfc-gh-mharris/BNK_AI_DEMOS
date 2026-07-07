-- =============================================================================
-- WEALTH MANAGEMENT — CORTEX SEARCH SERVICES
-- Schema: BNK.WEALTH_MGMT
--
-- Creates three Cortex Search Services for semantic retrieval:
--   1. RESEARCH_SEARCH — Equity research reports for investment thesis lookup
--   2. COMPLIANCE_SEARCH — Regulatory/compliance documents for policy lookup
--   3. CLIENT_NOTES_SEARCH — Advisor notes for relationship context
--
-- All services use snowflake-arctic-embed-l-v2.0 for multilingual support
-- and refresh daily to stay current with new documents.
-- =============================================================================

USE DATABASE BNK;
USE SCHEMA BNK.WEALTH_MGMT;
USE WAREHOUSE BNK_WH;

-- -----------------------------------------------------------------------------
-- RESEARCH_SEARCH
-- Enables advisors to ask: "What does our research say about AI in healthcare?"
-- -----------------------------------------------------------------------------
CREATE CORTEX SEARCH SERVICE IF NOT EXISTS BNK.WEALTH_MGMT.RESEARCH_SEARCH
    ON content
    ATTRIBUTES sector, analyst_name, rating
    WAREHOUSE = BNK_WH
    TARGET_LAG = '1 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    COMMENT = 'Semantic search over internal equity research reports. Supports queries about investment theses, sector outlooks, company analysis, price targets, and analyst ratings. Filterable by sector, analyst, and rating.'
AS (
    SELECT
        report_id,
        title,
        analyst_name,
        publish_date,
        sector,
        ticker_coverage,
        rating,
        target_price,
        content
    FROM BNK.WEALTH_MGMT.RESEARCH_REPORTS
);

-- -----------------------------------------------------------------------------
-- COMPLIANCE_SEARCH
-- Enables advisors to ask: "What are the RegBI suitability requirements?"
-- -----------------------------------------------------------------------------
CREATE CORTEX SEARCH SERVICE IF NOT EXISTS BNK.WEALTH_MGMT.COMPLIANCE_SEARCH
    ON content
    ATTRIBUTES category, title
    WAREHOUSE = BNK_WH
    TARGET_LAG = '1 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    COMMENT = 'Semantic search over compliance and regulatory policy documents. Supports questions about suitability obligations, RegBI requirements, best execution, proxy voting, and AML procedures. Filterable by category and title.'
AS (
    SELECT
        doc_id,
        title,
        category,
        effective_date,
        content
    FROM BNK.WEALTH_MGMT.COMPLIANCE_DOCS
);

-- -----------------------------------------------------------------------------
-- CLIENT_NOTES_SEARCH
-- Enables advisors to ask: "What did we discuss with John Smith last quarter?"
-- -----------------------------------------------------------------------------
CREATE CORTEX SEARCH SERVICE IF NOT EXISTS BNK.WEALTH_MGMT.CLIENT_NOTES_SEARCH
    ON note_text
    ATTRIBUTES client_id, advisor_id, note_type
    WAREHOUSE = BNK_WH
    TARGET_LAG = '1 day'
    EMBEDDING_MODEL = 'snowflake-arctic-embed-l-v2.0'
    COMMENT = 'Semantic search over advisor client interaction notes. Supports retrieval of meeting summaries, call logs, review notes, and rebalancing discussions. Filterable by client_id, advisor_id, and note_type for targeted history retrieval.'
AS (
    SELECT
        note_id,
        client_id,
        advisor_id,
        note_date,
        note_type,
        note_text
    FROM BNK.WEALTH_MGMT.CLIENT_NOTES
);
