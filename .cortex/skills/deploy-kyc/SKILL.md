---
name: deploy-kyc
description: "Deploy the KYC/AML banking AI demo use case to Snowflake. Creates an AI-powered document processing pipeline with AI_PARSE_DOCUMENT, Cortex Search for policies, and a Cortex Agent for KYC case management. Use when: deploying KYC, AML, know your customer, document processing demo, identity verification. Triggers: deploy kyc, deploy aml, deploy KYC AML, banking kyc agent, document processing demo."
---

# Deploy KYC/AML

Deploys the KYC/AML use case from the `bnk-ai-demos` repository. This creates:
- BNK database and KYC_AML schema
- Tables: KYC_CASES, CUSTOMERS_KYC, DOCUMENTS_METADATA, DOCUMENT_EXTRACTIONS, KYC_POLICIES, RISK_ALERTS, SAR_FILINGS
- Document Pipeline: AI_PARSE_DOCUMENT + AI_CLASSIFY + AI_EXTRACT for identity documents
- Search Service: KYC_POLICY_SEARCH
- Agent: KYC_AGENT (combines Search + document classification tools)
- Stage: @BNK.KYC_AML.KYC_DOCUMENTS for PDF uploads

## Prerequisites

- Cloned repo: `https://github.com/sfc-gh-jheisler/BNK_AI_DEMOS`
- ACCOUNTADMIN or role with CREATE DATABASE, CREATE WAREHOUSE, CREATE STAGE privileges
- Snowflake account with Cortex AI features enabled (AI_PARSE_DOCUMENT requires Arctic or compatible model access)

## Workflow

### Step 1: Locate Repository

Find the cloned repo on disk. Check common locations:
1. Current working directory
2. `~/Documents/GitHub/BNK_AI_DEMOS/`
3. Ask user if not found

Verify the `kyc_aml/` subfolder exists with files: `00_setup.sql`, `01_ddl.sql`, `02_data.sql`, `03_search_services.sql`, `04_document_pipeline.sql`, `05_agent.sql`.

### Step 2: Execute Deployment Scripts in Order

Execute each SQL file sequentially using `snowflake_sql_execute`. Read each file with the `read` tool, then execute each SQL statement individually (split on semicolons, skip empty statements).

**Execution order:**
1. `00_setup.sql` — Creates BNK database, KYC_AML schema, BNK_WH warehouse
2. `01_ddl.sql` — Creates tables and internal stage
3. `02_data.sql` — Inserts synthetic KYC case data, customer records, risk alerts
4. `03_search_services.sql` — Creates KYC_POLICY_SEARCH service
5. `04_document_pipeline.sql` — Creates stored procedures for document processing (AI_PARSE_DOCUMENT, AI_CLASSIFY, AI_EXTRACT)
6. `05_agent.sql` — Creates KYC_AGENT

**Error handling:**
- If a statement fails, report the error and the file/statement that failed
- "already exists" errors are safe to ignore (scripts use IF NOT EXISTS / CREATE OR ALTER)
- If warehouse or database doesn't exist errors occur, ensure 00_setup.sql ran first
- If "not an allowed model" error occurs, verify the agent spec uses `orchestration: auto`
- FK constraint errors: ensure 01_ddl.sql creates tables in dependency order

### Step 3: Validate Deployment

After all scripts complete:

1. Verify objects exist:
   ```sql
   SHOW TABLES IN SCHEMA BNK.KYC_AML;
   SHOW CORTEX SEARCH SERVICES IN SCHEMA BNK.KYC_AML;
   SHOW PROCEDURES IN SCHEMA BNK.KYC_AML;
   SHOW AGENTS IN SCHEMA BNK.KYC_AML;
   ```

2. Quick agent test:
   ```sql
   SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
     'BNK.KYC_AML.KYC_AGENT',
     [{'role': 'user', 'content': 'What are our current high-risk KYC cases?'}]
   );
   ```

Present results to user.

## Stopping Points

- None — fully automated deployment. Report results at the end.

## Output

Fully deployed KYC/AML use case in BNK.KYC_AML schema with a working Cortex Agent, document processing pipeline, and policy search accessible in Snowflake CoWork.

## Troubleshooting

**"Tool X is missing execution_environment"** — The agent spec must include `execution_environment: {type: warehouse, warehouse: BNK_WH}` for Cortex Analyst tools.

**"Column X doesn't have a text index"** — In the agent's `columns_and_descriptions`, only the ON column should be `searchable: true`. All ATTRIBUTES must be `searchable: false, filterable: true`.

**Agent not visible in CoWork** — Ensure the CREATE AGENT statement includes a PROFILE clause with display_name.

**Document pipeline errors** — AI_PARSE_DOCUMENT requires files in the stage. The demo data creates metadata records but actual PDF processing requires uploading files to @BNK.KYC_AML.KYC_DOCUMENTS.
