-- =============================================================================
-- CUSTOMER 360 — INFRASTRUCTURE SETUP
-- Schema: BNK.CUSTOMER_360
--
-- Creates only the objects needed for the Customer 360 use case.
-- Safe to re-run (all IF NOT EXISTS).
-- NEVER drops or replaces existing objects.
-- =============================================================================

CREATE DATABASE IF NOT EXISTS BNK
    COMMENT = 'Banking AI demonstration database. Contains schemas for Customer 360, KYC/AML, Lending Analytics, and Wealth Management use cases.';

CREATE SCHEMA IF NOT EXISTS BNK.CUSTOMER_360
    COMMENT = 'Customer 360 use case. Demonstrates natural language queries against structured customer data (Cortex Analyst) and unstructured interaction notes (Cortex Search) via an orchestrating Agent.';

CREATE WAREHOUSE IF NOT EXISTS BNK_WH
    WAREHOUSE_SIZE = 'MEDIUM'
    AUTO_SUSPEND = 300
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'Dedicated compute for BNK demo workloads. Auto-suspends after 5 minutes.';

USE DATABASE BNK;
USE SCHEMA CUSTOMER_360;
USE WAREHOUSE BNK_WH;
