---
name: deploy-wealth-mgmt
description: "Deploy the Wealth Management banking AI demo use case to Snowflake. The most comprehensive demo: Cortex Analyst for portfolio analytics, Cortex Search for research/compliance/notes, AI_PARSE_DOCUMENT for onboarding docs, and a multi-tool Cortex Agent. Use when: deploying wealth management, portfolio analytics, wealth advisor demo. Triggers: deploy wealth, deploy wealth management, wealth mgmt, portfolio agent, wealth advisor demo."
---

# Deploy Wealth Management

Deploys the Wealth Management use case from the `bnk-ai-demos` repository. This is the most comprehensive demo, combining all Cortex AI capabilities. It creates:
- Database and WEALTH_MGMT schema
- Tables: CLIENTS, PORTFOLIOS, HOLDINGS, TRADES, RESEARCH_REPORTS, COMPLIANCE_RULES, CLIENT_NOTES, ONBOARDING_DOCUMENTS, DOCUMENT_EXTRACTIONS
- Semantic View: SV_WEALTH_PORTFOLIO (Cortex Analyst for portfolio analytics)
- Search Services: RESEARCH_SEARCH, COMPLIANCE_SEARCH, CLIENT_NOTES_SEARCH
- Document Pipeline: AI_PARSE_DOCUMENT + AI_EXTRACT for onboarding documents
- Agent: WEALTH_MGMT_AGENT (combines Analyst + 3 Search tools)
- Stage: @DB.SCHEMA.ONBOARDING_DOCS for document uploads

## Prerequisites

- Cloned repo: `https://github.com/sfc-gh-mharris/BNK_AI_DEMOS`
- ACCOUNTADMIN or role with CREATE DATABASE, CREATE WAREHOUSE, CREATE STAGE privileges
- Snowflake account with Cortex AI features enabled

## Configuration

Before executing any SQL, collect the deployment configuration from the user using `ask_user_question`:

1. **Database** — Ask which database to deploy into. Default: `BNK`. If user specifies a different database, use it for all fully-qualified references throughout the deployment.
2. **Warehouse** — Ask which warehouse to use for compute. Default: `BNK_WH`. If user specifies an existing warehouse, skip warehouse creation (`CREATE WAREHOUSE IF NOT EXISTS`) and just use their warehouse.
3. **Schema** — Ask which schema name to use. Default: `WEALTH_MGMT`.

Store these three values as the **deployment configuration**. All subsequent SQL execution MUST apply these substitutions to every statement before running it:

| Default Value | Substitution |
|---------------|-------------|
| `BNK_WH` | → user's warehouse (in `USE WAREHOUSE`, `WAREHOUSE =` clauses, agent `execution_environment`) |
| `BNK.WEALTH_MGMT` | → `{user_db}.{user_schema}` in all fully-qualified references |
| `BNK` (standalone database references in `USE DATABASE`, `CREATE DATABASE`) | → user's database |
| `WEALTH_MGMT` (in `USE SCHEMA`, `CREATE SCHEMA`) | → user's schema |

**Critical — downstream propagation**: These substitutions MUST be applied in ALL contexts including:
- `WAREHOUSE =` clauses in `CREATE CORTEX SEARCH SERVICE` statements
- `warehouse:` value in agent `execution_environment` YAML (inside `$$` dollar-quoted spec)
- Fully-qualified object names inside the agent spec (semantic view references, search service `name:` fields)
- Stage references (`@BNK.WEALTH_MGMT.ONBOARDING_DOCS` → `@{user_db}.{user_schema}.ONBOARDING_DOCS`)
- Stored procedure bodies that reference fully-qualified table/stage names
- All validation and verification queries in Step 3

## Workflow

### Step 1: Locate Repository

Find the cloned repo on disk. Check common locations:
1. Current working directory
2. `~/Documents/GitHub/BNK_AI_DEMOS/`
3. Ask user if not found

Verify the `wealth_mgmt/` subfolder exists with files: `00_setup.sql`, `01_ddl.sql`, `02_data.sql`, `03_semantic_view.sql`, `04_search_services.sql`, `05_document_pipeline.sql`, `06_agent.sql`.

### Step 2: Execute Deployment Scripts in Order

Execute each SQL file sequentially using `snowflake_sql_execute`. Read each file with the `read` tool, then execute each SQL statement individually (split on semicolons, skip empty statements).

**Before executing each statement**, apply the deployment configuration substitutions from the Configuration section above. Every reference to the default database, warehouse, and schema must be replaced with the user's configured values.

**Execution order:**
1. `00_setup.sql` — Creates database, schema, warehouse (skip warehouse creation if user specified an existing warehouse)
2. `01_ddl.sql` — Creates tables and internal stage (substitute stage FQN)
3. `02_data.sql` — Inserts synthetic client, portfolio, holdings, trades, research, and compliance data
4. `03_semantic_view.sql` — Creates SV_WEALTH_PORTFOLIO semantic view (substitute fully-qualified table references in the view definition)
5. `04_search_services.sql` — Creates RESEARCH_SEARCH, COMPLIANCE_SEARCH, CLIENT_NOTES_SEARCH (substitute `WAREHOUSE =` clause and fully-qualified source table names)
6. `05_document_pipeline.sql` — Creates stored procedures for onboarding document processing (substitute fully-qualified stage and table references inside procedure bodies)
7. `06_agent.sql` — Creates WEALTH_MGMT_AGENT (substitute `execution_environment.warehouse`, semantic view FQN in tool definitions, and all three search service FQNs in tool definitions)

**Error handling:**
- If a statement fails, report the error and the file/statement that failed
- "already exists" errors are safe to ignore (scripts use IF NOT EXISTS / CREATE OR ALTER)
- If warehouse or database doesn't exist errors occur, ensure 00_setup.sql ran first
- If "not an allowed model" error occurs, verify the agent spec uses `orchestration: auto`
- Semantic view "invalid identifier" errors: dimension aliases must match source column names; metric expressions must reference fact aliases
- 02_data.sql is the largest file — it may take several minutes to execute all INSERT statements

### Step 3: Validate Deployment

After all scripts complete, use the **user's configured database and schema** in all verification queries:

1. Verify objects exist:
   ```sql
   SHOW TABLES IN SCHEMA {user_db}.{user_schema};
   SHOW CORTEX SEARCH SERVICES IN SCHEMA {user_db}.{user_schema};
   SHOW SEMANTIC VIEWS IN SCHEMA {user_db}.{user_schema};
   SHOW PROCEDURES IN SCHEMA {user_db}.{user_schema};
   SHOW AGENTS IN SCHEMA {user_db}.{user_schema};
   ```

2. Quick agent test:
   ```sql
   SELECT TRY_PARSE_JSON(
     SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
       '{user_db}.{user_schema}.WEALTH_MGMT_AGENT',
       $${"messages": [{"role": "user", "content": [{"type": "text", "text": "What is the total AUM across all client portfolios?"}]}]}$$
     )
   ) AS resp;
   ```

Present results to user.

### Step 4: Demo the Agent (Interactive)

After validation succeeds, ask the user if they'd like to see the wealth management agent's full capabilities — this is the most feature-rich of the four demos with 4 tools. Use `ask_user_question`:

```
"Your Wealth Management agent is deployed with portfolio analytics, research, compliance, and client notes. Would you like to see a multi-tool demo?"
Options:
- "Yes, show me the demo" — proceed with the steps below
- "No, I'm done for now" — skip to Output
```

**If the user opts in:**

1. **Portfolio analytics (Cortex Analyst).** Run a question that demonstrates the Semantic View over portfolio/holdings data:
   ```sql
   SELECT TRY_PARSE_JSON(
     SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
       '{user_db}.{user_schema}.WEALTH_MGMT_AGENT',
       $${"messages": [{"role": "user", "content": [{"type": "text", "text": "What are our largest equity exposures by sector, and which client portfolios have the highest concentration risk?"}]}]}$$
     )
   ) AS resp;
   ```

2. **Show the user what to look for:**
   - **SQL generation** → The agent translated "concentration risk" into the right calculation (% of portfolio in a single sector/holding). Point out the generated SQL.
   - **Multi-table joins** → The query should join portfolios, holdings, and securities tables correctly. Highlight the complexity being hidden from the user.
   - **Business context** → The semantic model knows what "AUM", "exposure", and "concentration" mean in a wealth management context.

3. **Multi-tool orchestration (Analyst + Research + Compliance).** Run a question that requires multiple tools:
   ```sql
   SELECT TRY_PARSE_JSON(
     SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
       '{user_db}.{user_schema}.WEALTH_MGMT_AGENT',
       $${"messages": [{"role": "user", "content": [{"type": "text", "text": "Are any of our client portfolios overweight in technology stocks, and what does our latest research say about the tech sector outlook? Also check if there are any compliance guidelines on sector concentration limits."}]}]}$$
     )
   ) AS resp;
   ```
   Point out:
   - The agent calls **three different tools** to answer one question (Analyst for portfolio data, Research Search for sector outlook, Compliance Search for concentration rules)
   - Each source is cited separately — the user can distinguish data facts from research opinions from compliance requirements
   - The synthesis connects all three: here's the exposure, here's the outlook, here's whether it violates policy

4. **Client notes search.** Show the relationship-management angle:
   ```sql
   SELECT TRY_PARSE_JSON(
     SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
       '{user_db}.{user_schema}.WEALTH_MGMT_AGENT',
       $${"messages": [{"role": "user", "content": [{"type": "text", "text": "What have advisors noted about clients who expressed interest in ESG investing?"}]}]}$$
     )
   ) AS resp;
   ```
   Highlight that this surfaces advisor meeting notes, preferences, and action items that would otherwise require reading through hundreds of records.

5. **Call out key observations:**
   - This agent orchestrates 4 tools without explicit routing — the model decides what to call based on the question
   - Research search returns timely market commentary grounded in the institution's own research library
   - Compliance search provides specific rules with regulatory references, not generic advice
   - The combination of quantitative (Analyst) + qualitative (3x Search) creates an assistant that understands both numbers and context
   - This is the demo that best shows what a "wealth advisor co-pilot" looks like in production
   - Typical response time: 10-20 seconds for multi-tool questions (each tool call adds latency)

## Stopping Points

- Step 4 is interactive. If the user declines, stop after Step 3 results.

## Output

Fully deployed Wealth Management use case in `{user_db}.{user_schema}` schema with a working multi-tool Cortex Agent accessible in Snowflake CoWork.

## Troubleshooting

**"Tool X is missing execution_environment"** — The agent spec must include `execution_environment: {type: warehouse, warehouse: {user_warehouse}}` for Cortex Analyst tools. Verify the substitution was applied inside the dollar-quoted agent spec.

**"Column X doesn't have a text index"** — In the agent's `columns_and_descriptions`, only the ON column should be `searchable: true`. All ATTRIBUTES must be `searchable: false, filterable: true`.

**"invalid identifier" in semantic view** — Dimension aliases must match source column names. Metric expressions must reference fact alias names (e.g., if fact is `holdings.total_value AS total_value`, metric uses `SUM(total_value)`).

**"invalid identifier" in agent spec** — If the user changed the database or schema, ensure all fully-qualified names inside the agent YAML spec were updated. The agent references search services and semantic views by their full `DB.SCHEMA.OBJECT` path.

**Agent not visible in CoWork** — Ensure the CREATE AGENT statement includes a PROFILE clause with display_name.

**Document pipeline errors** — AI_PARSE_DOCUMENT requires files in the stage. The demo creates metadata but actual PDF processing requires uploading files to `@{user_db}.{user_schema}.ONBOARDING_DOCS`.

**Large data file timeout** — 02_data.sql contains substantial INSERT statements. If timeouts occur, execute the file in smaller batches.

**Warehouse does not exist** — If the user specified a custom warehouse, verify it exists before deployment. The skill skips `CREATE WAREHOUSE` when the user provides an existing warehouse name.
