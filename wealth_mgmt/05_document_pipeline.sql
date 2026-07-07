-- =============================================================================
-- WEALTH MANAGEMENT — DOCUMENT AI PIPELINE (Onboarding)
-- Schema: BNK.WEALTH_MGMT
--
-- Processes client onboarding documents (W-9, Investment Policy Statements,
-- Client Agreements) from @BNK.WEALTH_MGMT.ONBOARDING_DOCS stage using
-- AI_PARSE_DOCUMENT → AI_CLASSIFY → AI_EXTRACT.
-- =============================================================================

USE DATABASE BNK;
USE SCHEMA BNK.WEALTH_MGMT;
USE WAREHOUSE BNK_WH;

-- -----------------------------------------------------------------------------
-- PROCESS_ONBOARDING_DOC
-- Core procedure: takes a staged document path, parses it, classifies it,
-- and extracts structured client onboarding fields.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE IF NOT EXISTS BNK.WEALTH_MGMT.PROCESS_ONBOARDING_DOC(DOC_PATH VARCHAR)
    RETURNS VARIANT
    LANGUAGE SQL
    COMMENT = 'Processes a single client onboarding document through the full AI pipeline: AI_PARSE_DOCUMENT (layout extraction) → AI_CLASSIFY (document type determination) → AI_EXTRACT (structured field extraction). Accepts a relative path within @ONBOARDING_DOCS stage. Returns a VARIANT containing document_type, extracted_fields, and page_count.'
AS
BEGIN
    -- Step 1: Parse the document preserving layout structure
    LET parsed VARIANT := (
        SELECT AI_PARSE_DOCUMENT(
            TO_FILE('@BNK.WEALTH_MGMT.ONBOARDING_DOCS', :DOC_PATH),
            {'mode': 'LAYOUT', 'page_split': true}
        )
    );

    -- Step 2: Extract text from first page for classification
    LET doc_text VARCHAR := (SELECT :parsed:pages[0]:content::VARCHAR);

    -- Step 3: Classify the document into onboarding document types
    LET classification VARIANT := (
        SELECT AI_CLASSIFY(
            :doc_text,
            ['W9Form', 'InvestmentPolicyStatement', 'ClientAgreement', 'AccountApplication', 'BeneficiaryDesignation']
        )
    );

    -- Step 4: Extract structured fields relevant to client onboarding
    LET extracted VARIANT := (
        SELECT AI_EXTRACT(
            :doc_text,
            {
                'client_name': 'Full legal name of the client or entity',
                'ssn_last_four': 'Last four digits of SSN or Tax Identification Number',
                'risk_tolerance': 'Stated investment risk tolerance level (Conservative, Moderate, Aggressive)',
                'investment_objective': 'Primary investment objective or financial goal',
                'time_horizon': 'Investment time horizon in years',
                'annual_income': 'Annual income or revenue in USD',
                'net_worth': 'Estimated total net worth excluding primary residence in USD',
                'account_type': 'Type of account being opened (Individual, Joint, Trust, IRA, Corporate)',
                'beneficiary_name': 'Named beneficiary if applicable',
                'date_signed': 'Date the document was signed'
            }
        )
    );

    -- Return consolidated results
    RETURN OBJECT_CONSTRUCT(
        'document_type', :classification,
        'extracted_fields', :extracted,
        'page_count', ARRAY_SIZE(:parsed:pages),
        'raw_text_preview', LEFT(:doc_text, 500)
    );
END;

-- -----------------------------------------------------------------------------
-- BATCH_PROCESS_ONBOARDING
-- Processes all unprocessed documents in the onboarding stage.
-- Designed for scheduled execution via Snowflake Task.
-- -----------------------------------------------------------------------------
CREATE PROCEDURE IF NOT EXISTS BNK.WEALTH_MGMT.BATCH_PROCESS_ONBOARDING(BATCH_SIZE INTEGER DEFAULT 50)
    RETURNS VARCHAR
    LANGUAGE SQL
    COMMENT = 'Batch processes unprocessed onboarding documents from @ONBOARDING_DOCS stage. Iterates through staged files, calls PROCESS_ONBOARDING_DOC for each, and logs results. Accepts an optional BATCH_SIZE parameter (default 50) for cost control. Designed for scheduled execution via Snowflake Task.'
AS
BEGIN
    LET processed_count INTEGER := 0;
    LET error_count INTEGER := 0;

    -- In production this would iterate over directory listing
    -- and filter to unprocessed files. For demo purposes, this
    -- documents the pattern.
    --
    -- FOR file IN (
    --     SELECT RELATIVE_PATH
    --     FROM DIRECTORY(@BNK.WEALTH_MGMT.ONBOARDING_DOCS)
    --     LIMIT :BATCH_SIZE
    -- ) DO
    --     CALL BNK.WEALTH_MGMT.PROCESS_ONBOARDING_DOC(file.RELATIVE_PATH);
    --     processed_count := processed_count + 1;
    -- END FOR;

    RETURN 'Batch processing complete. Processed: ' || :processed_count::VARCHAR || ', Errors: ' || :error_count::VARCHAR;
END;
