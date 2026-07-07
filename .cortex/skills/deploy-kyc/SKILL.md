---
name: deploy-kyc
description: "Deploy the KYC/AML banking AI demo use case to Snowflake. Creates an AI-powered document processing pipeline with AI_PARSE_DOCUMENT, Cortex Search for policies, and a Cortex Agent for KYC case management. Use when: deploying KYC, AML, know your customer, document processing demo, identity verification. Triggers: deploy kyc, deploy aml, deploy KYC AML, banking kyc agent, document processing demo."
---

# Deploy KYC/AML

Deploys the KYC/AML use case from the `bnk-ai-demos` repository. This creates:
- Database and KYC_AML schema
- Tables: KYC_CASES, CUSTOMERS_KYC, DOCUMENTS_METADATA, DOCUMENT_EXTRACTIONS, KYC_POLICIES, RISK_ALERTS, SAR_FILINGS
- Document Pipeline: AI_PARSE_DOCUMENT + AI_CLASSIFY + AI_EXTRACT for identity documents
- Search Service: KYC_POLICY_SEARCH
- Agent: KYC_AGENT (combines Search + document classification tools)
- Stage: @DB.SCHEMA.KYC_DOCUMENTS for PDF uploads

## Prerequisites

- Cloned repo: `https://github.com/sfc-gh-jheisler/BNK_AI_DEMOS`
- ACCOUNTADMIN or role with CREATE DATABASE, CREATE WAREHOUSE, CREATE STAGE privileges
- Snowflake account with Cortex AI features enabled (AI_PARSE_DOCUMENT requires Arctic or compatible model access)

## Configuration

Before executing any SQL, collect the deployment configuration from the user using `ask_user_question`:

1. **Database** — Ask which database to deploy into. Default: `BNK`. If user specifies a different database, use it for all fully-qualified references throughout the deployment.
2. **Warehouse** — Ask which warehouse to use for compute. Default: `BNK_WH`. If user specifies an existing warehouse, skip warehouse creation (`CREATE WAREHOUSE IF NOT EXISTS`) and just use their warehouse.
3. **Schema** — Ask which schema name to use. Default: `KYC_AML`.

Store these three values as the **deployment configuration**. All subsequent SQL execution MUST apply these substitutions to every statement before running it:

| Default Value | Substitution |
|---------------|-------------|
| `BNK_WH` | → user's warehouse (in `USE WAREHOUSE`, `WAREHOUSE =` clauses, agent `execution_environment`) |
| `BNK.KYC_AML` | → `{user_db}.{user_schema}` in all fully-qualified references |
| `BNK` (standalone database references in `USE DATABASE`, `CREATE DATABASE`) | → user's database |
| `KYC_AML` (in `USE SCHEMA`, `CREATE SCHEMA`) | → user's schema |

**Critical — downstream propagation**: These substitutions MUST be applied in ALL contexts including:
- `WAREHOUSE =` clauses in `CREATE CORTEX SEARCH SERVICE` statements
- `warehouse:` value in agent `execution_environment` YAML (inside `$$` dollar-quoted spec)
- Fully-qualified object names inside the agent spec (search service `name:` fields)
- Stage references (`@BNK.KYC_AML.KYC_DOCUMENTS` → `@{user_db}.{user_schema}.KYC_DOCUMENTS`)
- Stored procedure bodies that reference fully-qualified table/stage names
- All validation and verification queries in Step 3

## Workflow

### Step 1: Locate Repository

Find the cloned repo on disk. Check common locations:
1. Current working directory
2. `~/Documents/GitHub/BNK_AI_DEMOS/`
3. Ask user if not found

Verify the `kyc_aml/` subfolder exists with files: `00_setup.sql`, `01_ddl.sql`, `02_data.sql`, `03_search_services.sql`, `04_document_pipeline.sql`, `05_agent.sql`.

### Step 2: Execute Deployment Scripts in Order

Execute each SQL file sequentially using `snowflake_sql_execute`. Read each file with the `read` tool, then execute each SQL statement individually (split on semicolons, skip empty statements).

**Before executing each statement**, apply the deployment configuration substitutions from the Configuration section above. Every reference to the default database, warehouse, and schema must be replaced with the user's configured values.

**Execution order:**
1. `00_setup.sql` — Creates database, schema, warehouse (skip warehouse creation if user specified an existing warehouse)
2. `01_ddl.sql` — Creates tables and internal stage (substitute stage FQN)
3. `02_data.sql` — Inserts synthetic KYC case data, customer records, risk alerts
4. `03_search_services.sql` — Creates KYC_POLICY_SEARCH service (substitute `WAREHOUSE =` clause and fully-qualified source table name)
5. `04_document_pipeline.sql` — Creates stored procedures for document processing (substitute fully-qualified stage and table references inside procedure bodies)
6. `05_agent.sql` — Creates KYC_AGENT (substitute `execution_environment.warehouse` and search service FQN in tool definitions)

**Error handling:**
- If a statement fails, report the error and the file/statement that failed
- "already exists" errors are safe to ignore (scripts use IF NOT EXISTS / CREATE OR ALTER)
- If warehouse or database doesn't exist errors occur, ensure 00_setup.sql ran first
- If "not an allowed model" error occurs, verify the agent spec uses `orchestration: auto`
- FK constraint errors: ensure 01_ddl.sql creates tables in dependency order

### Step 3: Validate Deployment

After all scripts complete, use the **user's configured database and schema** in all verification queries:

1. Verify objects exist:
   ```sql
   SHOW TABLES IN SCHEMA {user_db}.{user_schema};
   SHOW CORTEX SEARCH SERVICES IN SCHEMA {user_db}.{user_schema};
   SHOW PROCEDURES IN SCHEMA {user_db}.{user_schema};
   SHOW AGENTS IN SCHEMA {user_db}.{user_schema};
   ```

2. Quick agent test:
   ```sql
   SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
     '{user_db}.{user_schema}.KYC_AGENT',
     [{'role': 'user', 'content': 'What are our current high-risk KYC cases?'}]
   );
   ```

Present results to user.

## Stopping Points

- None — fully automated deployment. Report results at the end.

## Output

Fully deployed KYC/AML use case in `{user_db}.{user_schema}` schema with a working Cortex Agent, document processing pipeline, and policy search accessible in Snowflake CoWork.

## Troubleshooting

**"Tool X is missing execution_environment"** — The agent spec must include `execution_environment: {type: warehouse, warehouse: {user_warehouse}}` for Cortex Analyst tools. Verify the substitution was applied inside the dollar-quoted agent spec.

**"Column X doesn't have a text index"** — In the agent's `columns_and_descriptions`, only the ON column should be `searchable: true`. All ATTRIBUTES must be `searchable: false, filterable: true`.

**"invalid identifier" in agent spec** — If the user changed the database or schema, ensure all fully-qualified names inside the agent YAML spec were updated. The agent references search services by their full `DB.SCHEMA.OBJECT` path.

**Agent not visible in CoWork** — Ensure the CREATE AGENT statement includes a PROFILE clause with display_name.

**Document pipeline errors** — AI_PARSE_DOCUMENT requires files in the stage. The demo data creates metadata records but actual PDF processing requires uploading files to `@{user_db}.{user_schema}.KYC_DOCUMENTS`.

**Warehouse does not exist** — If the user specified a custom warehouse, verify it exists before deployment. The skill skips `CREATE WAREHOUSE` when the user provides an existing warehouse name.
