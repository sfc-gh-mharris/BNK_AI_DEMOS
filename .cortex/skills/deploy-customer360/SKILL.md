---
name: deploy-customer360
description: "Deploy the Customer 360 banking AI demo use case to Snowflake. Creates a Cortex Agent with Semantic View (Cortex Analyst) and Search Services for customer notes and policies. Use when: deploying customer 360, banking demo, customer agent. Triggers: deploy customer360, deploy customer 360, banking customer agent."
---

# Deploy Customer 360

Deploys the Customer 360 use case from the `bnk-ai-demos` repository. This creates:
- BNK database and CUSTOMER_360 schema
- Tables: CUSTOMERS, ACCOUNTS, TRANSACTIONS, CUSTOMER_NOTES, BANKING_POLICIES
- Semantic View: SV_CUSTOMER_360 (Cortex Analyst)
- Search Services: CUSTOMER_NOTES_SEARCH, POLICY_SEARCH
- Agent: CUSTOMER_360_AGENT (combines Analyst + Search tools)

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

Verify the `customer_360/` subfolder exists with files: `00_setup.sql`, `01_ddl.sql`, `02_data.sql`, `03_semantic_view.sql`, `04_search_services.sql`, `05_agent.sql`.

### Step 2: Execute Deployment Scripts in Order

Execute each SQL file sequentially using `snowflake_sql_execute`. Read each file with the `read` tool, then execute each SQL statement individually (split on semicolons, skip empty statements).

**Execution order:**
1. `00_setup.sql` — Creates BNK database, CUSTOMER_360 schema, BNK_WH warehouse
2. `01_ddl.sql` — Creates tables
3. `02_data.sql` — Inserts synthetic banking data
4. `03_semantic_view.sql` — Creates SV_CUSTOMER_360 semantic view
5. `04_search_services.sql` — Creates CUSTOMER_NOTES_SEARCH and POLICY_SEARCH
6. `05_agent.sql` — Creates CUSTOMER_360_AGENT

**Error handling:**
- If a statement fails, report the error and the file/statement that failed
- Common fix: If "already exists" errors appear, these are safe to ignore (scripts use IF NOT EXISTS / CREATE OR ALTER)
- If warehouse or database doesn't exist errors occur, ensure 00_setup.sql ran first
- If "not an allowed model" error occurs, verify the agent spec uses `orchestration: auto`

### Step 3: Validate Deployment

After all scripts complete:

1. Verify objects exist:
   ```sql
   SHOW TABLES IN SCHEMA BNK.CUSTOMER_360;
   SHOW CORTEX SEARCH SERVICES IN SCHEMA BNK.CUSTOMER_360;
   SHOW SEMANTIC VIEWS IN SCHEMA BNK.CUSTOMER_360;
   SHOW AGENTS IN SCHEMA BNK.CUSTOMER_360;
   ```

2. Quick agent test:
   ```sql
   SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
     'BNK.CUSTOMER_360.CUSTOMER_360_AGENT',
     [{'role': 'user', 'content': 'How many customers do we have?'}]
   );
   ```

Present results to user.

## Stopping Points

- None — this is a fully automated deployment. Report results at the end.

## Output

Fully deployed Customer 360 use case in BNK.CUSTOMER_360 schema with a working Cortex Agent accessible in Snowflake CoWork.

## Troubleshooting

**"Tool X is missing execution_environment"** — The agent spec must include `execution_environment: {type: warehouse, warehouse: BNK_WH}` for Cortex Analyst tools.

**"Column X doesn't have a text index"** — In the agent's `columns_and_descriptions`, only the ON column should be `searchable: true`. All ATTRIBUTES must be `searchable: false, filterable: true`.

**Agent not visible in CoWork** — Ensure the CREATE AGENT statement includes a PROFILE clause with display_name.
