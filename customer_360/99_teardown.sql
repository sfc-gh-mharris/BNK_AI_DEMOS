-- =============================================================================
-- CUSTOMER 360 — TEARDOWN SCRIPT
-- Schema: BNK.CUSTOMER_360
--
-- Removes all AI services, data, and objects from the Customer 360 schema.
-- PRESERVES: The BNK database and CUSTOMER_360 schema (empty shell remains).
-- NEVER: Drops the database.
--
-- Run this to reset the environment for a clean re-deployment.
-- =============================================================================

USE DATABASE BNK;
USE SCHEMA CUSTOMER_360;
USE WAREHOUSE BNK_WH;

-- Step 1: Drop AI Services (Agent depends on Search + Semantic View)
DROP AGENT IF EXISTS BNK.CUSTOMER_360.CUSTOMER_360_AGENT;

-- Step 2: Drop Cortex Search Services
DROP CORTEX SEARCH SERVICE IF EXISTS BNK.CUSTOMER_360.CUSTOMER_NOTES_SEARCH;
DROP CORTEX SEARCH SERVICE IF EXISTS BNK.CUSTOMER_360.POLICY_SEARCH;

-- Step 3: Drop Semantic View
DROP SEMANTIC VIEW IF EXISTS BNK.CUSTOMER_360.SV_CUSTOMER_360;

-- Step 4: Drop Tables (reverse dependency order)
DROP TABLE IF EXISTS BNK.CUSTOMER_360.OFFERS;
DROP TABLE IF EXISTS BNK.CUSTOMER_360.CUSTOMER_NOTES;
DROP TABLE IF EXISTS BNK.CUSTOMER_360.INTERACTIONS;
DROP TABLE IF EXISTS BNK.CUSTOMER_360.TRANSACTIONS;
DROP TABLE IF EXISTS BNK.CUSTOMER_360.ACCOUNTS;
DROP TABLE IF EXISTS BNK.CUSTOMER_360.CUSTOMERS;
DROP TABLE IF EXISTS BNK.CUSTOMER_360.POLICIES;
DROP TABLE IF EXISTS BNK.CUSTOMER_360.PRODUCTS;

-- Schema remains intact for re-deployment
-- SELECT 'Customer 360 teardown complete. Schema BNK.CUSTOMER_360 preserved.' AS status;
