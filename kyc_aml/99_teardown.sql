-- =============================================================================
-- KYC / AML — TEARDOWN SCRIPT
-- Schema: BNK.KYC_AML
--
-- Removes all AI services, data, procedures, and objects.
-- PRESERVES: The BNK database and KYC_AML schema (empty shell remains).
-- NEVER: Drops the database.
-- =============================================================================

USE DATABASE BNK;
USE SCHEMA KYC_AML;
USE WAREHOUSE BNK_WH;

-- Step 1: Drop Agent
DROP AGENT IF EXISTS BNK.KYC_AML.KYC_AGENT;

-- Step 2: Drop Cortex Search Services and Semantic View
DROP CORTEX SEARCH SERVICE IF EXISTS BNK.KYC_AML.KYC_POLICY_SEARCH;
DROP SEMANTIC VIEW IF EXISTS BNK.KYC_AML.SV_KYC_AML;

-- Step 3: Drop Stored Procedures (Document AI pipeline)
DROP PROCEDURE IF EXISTS BNK.KYC_AML.PROCESS_KYC_DOCUMENT(VARCHAR);
DROP PROCEDURE IF EXISTS BNK.KYC_AML.BATCH_PROCESS_DOCUMENTS(INTEGER);
DROP PROCEDURE IF EXISTS BNK.KYC_AML.VERIFY_IDENTITY(VARCHAR, VARCHAR);
DROP PROCEDURE IF EXISTS BNK.KYC_AML.PROCESS_AND_VERIFY_DOCUMENT(VARCHAR, VARCHAR);

-- Step 4: Drop Tables (reverse dependency order)
DROP TABLE IF EXISTS BNK.KYC_AML.ALERT_QUEUE;
DROP TABLE IF EXISTS BNK.KYC_AML.VERIFICATION_RESULTS;
DROP TABLE IF EXISTS BNK.KYC_AML.DOCUMENTS_METADATA;
DROP TABLE IF EXISTS BNK.KYC_AML.KYC_CASES;
DROP TABLE IF EXISTS BNK.KYC_AML.CLIENTS;
DROP TABLE IF EXISTS BNK.KYC_AML.KYC_POLICIES;

-- Step 5: Remove staged documents (but keep the stage)
REMOVE @BNK.KYC_AML.KYC_DOCUMENTS;

-- Schema and stage remain intact for re-deployment
