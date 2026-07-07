---
name: deploy-lending
description: "Deploy the Lending Analytics banking AI demo use case to Snowflake. Creates a Cortex Agent with Semantic View for mortgage/loan analytics and Search Services for lending policies and customer interactions. Use when: deploying lending, mortgage analytics, loan portfolio demo. Triggers: deploy lending, deploy mortgage, lending analytics agent, loan portfolio demo."
---

# Deploy Lending Analytics

Deploys the Lending Analytics use case from the `bnk-ai-demos` repository. This creates:
- BNK database and LENDING schema
- Tables: BORROWERS, MORTGAGES, PAYMENTS, LENDING_POLICIES, INTERACTIONS
- Semantic View: SV_LENDING_ANALYTICS (Cortex Analyst for mortgage portfolio)
- Search Services: LENDING_POLICY_SEARCH, INTERACTION_SEARCH
- Agent: LENDING_AGENT (combines Analyst + two Search tools)

## Prerequisites

- Cloned repo: `https://github.com/sfc-gh-jheisler/BNK_AI_DEMOS`
- ACCOUNTADMIN or role with CREATE DATABASE, CREATE WAREHOUSE privileges
- Snowflake account with Cortex AI features enabled

## Workflow

### Step 1: Locate Repository

Find the cloned repo on disk. Check common locations:
1. Current working directory
2. `~/Documents/GitHub/BNK_AI_DEMOS/`
3. Ask user if not found

Verify the `lending/` subfolder exists with files: `00_setup.sql`, `01_ddl.sql`, `02_data.sql`, `03_semantic_view.sql`, `04_search_services.sql`, `05_agent.sql`.

### Step 2: Execute Deployment Scripts in Order

Execute each SQL file sequentially using `snowflake_sql_execute`. Read each file with the `read` tool, then execute each SQL statement individually (split on semicolons, skip empty statements).

**Execution order:**
1. `00_setup.sql` — Creates BNK database, LENDING schema, BNK_WH warehouse
2. `01_ddl.sql` — Creates tables
3. `02_data.sql` — Inserts synthetic borrower, mortgage, and payment data
4. `03_semantic_view.sql` — Creates SV_LENDING_ANALYTICS semantic view
5. `04_search_services.sql` — Creates LENDING_POLICY_SEARCH and INTERACTION_SEARCH
6. `05_agent.sql` — Creates LENDING_AGENT

**Error handling:**
- If a statement fails, report the error and the file/statement that failed
- "already exists" errors are safe to ignore (scripts use IF NOT EXISTS / CREATE OR ALTER)
- If warehouse or database doesn't exist errors occur, ensure 00_setup.sql ran first
- If "not an allowed model" error occurs, verify the agent spec uses `orchestration: auto`
- Semantic view "invalid identifier" errors: dimension aliases must match source column names exactly

### Step 3: Validate Deployment

After all scripts complete:

1. Verify objects exist:
   ```sql
   SHOW TABLES IN SCHEMA BNK.LENDING;
   SHOW CORTEX SEARCH SERVICES IN SCHEMA BNK.LENDING;
   SHOW SEMANTIC VIEWS IN SCHEMA BNK.LENDING;
   SHOW AGENTS IN SCHEMA BNK.LENDING;
   ```

2. Quick agent test:
   ```sql
   SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
     'BNK.LENDING.LENDING_AGENT',
     [{'role': 'user', 'content': 'What is the total value of our mortgage portfolio?'}]
   );
   ```

Present results to user.

## Stopping Points

- None — fully automated deployment. Report results at the end.

## Output

Fully deployed Lending Analytics use case in BNK.LENDING schema with a working Cortex Agent accessible in Snowflake CoWork.

## Troubleshooting

**"Tool X is missing execution_environment"** — The agent spec must include `execution_environment: {type: warehouse, warehouse: BNK_WH}` for Cortex Analyst tools.

**"Column X doesn't have a text index"** — In the agent's `columns_and_descriptions`, only the ON column should be `searchable: true`. All ATTRIBUTES must be `searchable: false, filterable: true`.

**"invalid identifier" in semantic view** — Dimension aliases in DIMENSIONS clause must match the source column name exactly (e.g., `mortgages.status AS status`, not `mortgages.status AS mortgage_status`).

**Agent not visible in CoWork** — Ensure the CREATE AGENT statement includes a PROFILE clause with display_name.
