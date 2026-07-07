---
name: deploy-wealth-mgmt
description: "Deploy the Wealth Management banking AI demo use case to Snowflake. The most comprehensive demo: Cortex Analyst for portfolio analytics, Cortex Search for research/compliance/notes, AI_PARSE_DOCUMENT for onboarding docs, and a multi-tool Cortex Agent. Use when: deploying wealth management, portfolio analytics, wealth advisor demo. Triggers: deploy wealth, deploy wealth management, wealth mgmt, portfolio agent, wealth advisor demo."
---

# Deploy Wealth Management

Deploys the Wealth Management use case from the `bnk-ai-demos` repository. This is the most comprehensive demo, combining all Cortex AI capabilities. It creates:
- BNK database and WEALTH_MGMT schema
- Tables: CLIENTS, PORTFOLIOS, HOLDINGS, TRADES, RESEARCH_REPORTS, COMPLIANCE_RULES, CLIENT_NOTES, ONBOARDING_DOCUMENTS, DOCUMENT_EXTRACTIONS
- Semantic View: SV_WEALTH_PORTFOLIO (Cortex Analyst for portfolio analytics)
- Search Services: RESEARCH_SEARCH, COMPLIANCE_SEARCH, CLIENT_NOTES_SEARCH
- Document Pipeline: AI_PARSE_DOCUMENT + AI_EXTRACT for onboarding documents
- Agent: WEALTH_MGMT_AGENT (combines Analyst + 3 Search tools)
- Stage: @BNK.WEALTH_MGMT.ONBOARDING_DOCS for document uploads

## Prerequisites

- Cloned repo: `https://github.com/sfc-gh-jheisler/BNK_AI_DEMOS`
- ACCOUNTADMIN or role with CREATE DATABASE, CREATE WAREHOUSE, CREATE STAGE privileges
- Snowflake account with Cortex AI features enabled

## Workflow

### Step 1: Locate Repository

Find the cloned repo on disk. Check common locations:
1. Current working directory
2. `~/Documents/GitHub/BNK_AI_DEMOS/`
3. Ask user if not found

Verify the `wealth_mgmt/` subfolder exists with files: `00_setup.sql`, `01_ddl.sql`, `02_data.sql`, `03_semantic_view.sql`, `04_search_services.sql`, `05_document_pipeline.sql`, `06_agent.sql`.

### Step 2: Execute Deployment Scripts in Order

Execute each SQL file sequentially using `snowflake_sql_execute`. Read each file with the `read` tool, then execute each SQL statement individually (split on semicolons, skip empty statements).

**Execution order:**
1. `00_setup.sql` — Creates BNK database, WEALTH_MGMT schema, BNK_WH warehouse
2. `01_ddl.sql` — Creates tables and internal stage
3. `02_data.sql` — Inserts synthetic client, portfolio, holdings, trades, research, and compliance data
4. `03_semantic_view.sql` — Creates SV_WEALTH_PORTFOLIO semantic view
5. `04_search_services.sql` — Creates RESEARCH_SEARCH, COMPLIANCE_SEARCH, CLIENT_NOTES_SEARCH
6. `05_document_pipeline.sql` — Creates stored procedures for onboarding document processing
7. `06_agent.sql` — Creates WEALTH_MGMT_AGENT

**Error handling:**
- If a statement fails, report the error and the file/statement that failed
- "already exists" errors are safe to ignore (scripts use IF NOT EXISTS / CREATE OR ALTER)
- If warehouse or database doesn't exist errors occur, ensure 00_setup.sql ran first
- If "not an allowed model" error occurs, verify the agent spec uses `orchestration: auto`
- Semantic view "invalid identifier" errors: dimension aliases must match source column names; metric expressions must reference fact aliases
- 02_data.sql is the largest file — it may take several minutes to execute all INSERT statements

### Step 3: Validate Deployment

After all scripts complete:

1. Verify objects exist:
   ```sql
   SHOW TABLES IN SCHEMA BNK.WEALTH_MGMT;
   SHOW CORTEX SEARCH SERVICES IN SCHEMA BNK.WEALTH_MGMT;
   SHOW SEMANTIC VIEWS IN SCHEMA BNK.WEALTH_MGMT;
   SHOW PROCEDURES IN SCHEMA BNK.WEALTH_MGMT;
   SHOW AGENTS IN SCHEMA BNK.WEALTH_MGMT;
   ```

2. Quick agent test:
   ```sql
   SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
     'BNK.WEALTH_MGMT.WEALTH_MGMT_AGENT',
     [{'role': 'user', 'content': 'What is the total AUM across all client portfolios?'}]
   );
   ```

Present results to user.

## Stopping Points

- None — fully automated deployment. Report results at the end.

## Output

Fully deployed Wealth Management use case in BNK.WEALTH_MGMT schema with a working multi-tool Cortex Agent accessible in Snowflake CoWork.

## Troubleshooting

**"Tool X is missing execution_environment"** — The agent spec must include `execution_environment: {type: warehouse, warehouse: BNK_WH}` for Cortex Analyst tools.

**"Column X doesn't have a text index"** — In the agent's `columns_and_descriptions`, only the ON column should be `searchable: true`. All ATTRIBUTES must be `searchable: false, filterable: true`.

**"invalid identifier" in semantic view** — Dimension aliases must match source column names. Metric expressions must reference fact alias names (e.g., if fact is `holdings.total_value AS total_value`, metric uses `SUM(total_value)`).

**Agent not visible in CoWork** — Ensure the CREATE AGENT statement includes a PROFILE clause with display_name.

**Document pipeline errors** — AI_PARSE_DOCUMENT requires files in the stage. The demo creates metadata but actual PDF processing requires uploading files to @BNK.WEALTH_MGMT.ONBOARDING_DOCS.

**Large data file timeout** — 02_data.sql contains substantial INSERT statements. If timeouts occur, execute the file in smaller batches.
