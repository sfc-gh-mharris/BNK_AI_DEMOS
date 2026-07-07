-- =============================================================================
-- CUSTOMER 360 — SEMANTIC VIEW
-- Schema: BNK.CUSTOMER_360
--
-- Creates a Semantic View joining CUSTOMERS, ACCOUNTS, and TRANSACTIONS
-- for natural-language analytics via Cortex Analyst.
--
-- Uses CREATE OR ALTER (creates if not exists, alters if exists).
-- Clause order: TABLES → RELATIONSHIPS → FACTS → DIMENSIONS → METRICS
-- =============================================================================

USE DATABASE BNK;
USE SCHEMA CUSTOMER_360;
USE WAREHOUSE BNK_WH;

CREATE OR ALTER SEMANTIC VIEW BNK.CUSTOMER_360.SV_CUSTOMER_360
  TABLES (
    customers AS BNK.CUSTOMER_360.CUSTOMERS PRIMARY KEY (customer_id) COMMENT = 'Customer master entity with demographics and segmentation.',
    accounts AS BNK.CUSTOMER_360.ACCOUNTS PRIMARY KEY (account_id) COMMENT = 'Account holdings entity with balances and product types.',
    transactions AS BNK.CUSTOMER_360.TRANSACTIONS PRIMARY KEY (txn_id) COMMENT = 'Transaction entity with amounts, categories, and channels.'
  )
  RELATIONSHIPS (
    customers_to_accounts AS accounts (customer_id) REFERENCES customers (customer_id),
    accounts_to_transactions AS transactions (account_id) REFERENCES accounts (account_id)
  )
  FACTS (
    accounts.balance AS balance COMMENT = 'Account balance in USD. For credit cards = outstanding balance, for deposits = available funds.',
    transactions.amount AS amount COMMENT = 'Transaction amount in USD. Positive = credit/deposit, Negative = debit/purchase.',
    customers.lifetime_value AS lifetime_value COMMENT = 'Estimated total net revenue over the customer relationship in USD.',
    customers.tenure_months AS tenure_months COMMENT = 'Number of months since customer first opened any account.'
  )
  DIMENSIONS (
    customers.segment AS segment COMMENT = 'Business segment: Consumer (retail), SmallBusiness (revenue < $5M), Commercial (revenue >= $5M).' SAMPLE_VALUES ('Consumer', 'SmallBusiness', 'Commercial') IS_ENUM,
    customers.region AS region COMMENT = 'Geographic region based on primary mailing address.' SAMPLE_VALUES ('Northeast', 'Southeast', 'Midwest', 'West', 'Southwest') IS_ENUM,
    customers.customer_status AS status COMMENT = 'Relationship status: Active, Inactive, Closed.' SAMPLE_VALUES ('Active', 'Inactive', 'Closed') IS_ENUM,
    customers.first_name AS first_name COMMENT = 'Customer first name for display and lookup.',
    customers.last_name AS last_name COMMENT = 'Customer last name for display and lookup.',
    customers.created_date AS created_date COMMENT = 'Date customer relationship began. Use for cohort analysis.',
    accounts.product_type AS product_type COMMENT = 'Banking product type.' SAMPLE_VALUES ('Checking', 'Savings', 'CreditCard', 'MoneyMarket', 'CD', 'Investment') IS_ENUM,
    accounts.opened_date AS opened_date COMMENT = 'Date account was opened. Use for vintage analysis.',
    transactions.category AS category COMMENT = 'Transaction spending category.' SAMPLE_VALUES ('Groceries', 'Dining', 'Travel', 'Entertainment', 'Utilities', 'Transfer', 'Deposit', 'Withdrawal', 'Payment') IS_ENUM,
    transactions.channel AS channel COMMENT = 'Channel through which transaction was initiated.' SAMPLE_VALUES ('Branch', 'ATM', 'Online', 'Mobile', 'Wire') IS_ENUM,
    transactions.merchant_name AS merchant_name COMMENT = 'Merchant or counterparty name.',
    transactions.txn_date AS txn_date COMMENT = 'Transaction settlement date. Primary time dimension for transaction analysis.'
  )
  METRICS (
    customers.customer_count AS COUNT(customer_id) COMMENT = 'Count of distinct customers in scope.',
    customers.avg_lifetime_value AS AVG(lifetime_value) COMMENT = 'Average lifetime value per customer in USD.',
    accounts.total_balance AS SUM(balance) COMMENT = 'Total balance across all accounts in scope (USD).',
    accounts.avg_balance AS AVG(balance) COMMENT = 'Average account balance in USD.',
    accounts.account_count AS COUNT(account_id) COMMENT = 'Number of accounts.',
    transactions.transaction_count AS COUNT(txn_id) COMMENT = 'Total number of transactions.',
    transactions.total_amount AS SUM(amount) COMMENT = 'Net transaction amount (credits minus debits).',
    transactions.avg_transaction_amount AS AVG(ABS(amount)) COMMENT = 'Average absolute transaction size in USD.'
  )
  COMMENT = 'Semantic View for Customer 360 analytics. Enables natural-language queries about customer segments, account balances, transaction patterns, and product penetration via Cortex Analyst.';
