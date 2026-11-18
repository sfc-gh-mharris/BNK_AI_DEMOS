---
name: deploy-lending
description: "Deploy the Lending Analytics banking AI demo use case to Snowflake. Creates a Cortex Agent with Semantic View for mortgage/loan analytics and Search Services for lending policies and customer interactions. Use when: deploying lending, mortgage analytics, loan portfolio demo. Triggers: deploy lending, deploy mortgage, lending analytics agent, loan portfolio demo."
---

# Deploy Lending Analytics

Deploys the Lending Analytics use case from the `bnk-ai-demos` repository. This creates:
- Database and LENDING schema
- Tables: BORROWERS, MORTGAGES, PAYMENTS, LENDING_POLICIES, INTERACTIONS
- Semantic View: SV_LENDING_ANALYTICS (Cortex Analyst for mortgage portfolio)
- Search Services: LENDING_POLICY_SEARCH, INTERACTION_SEARCH
- Agent: LENDING_AGENT (combines Analyst + two Search tools)

## Prerequisites

- Cloned repo: `https://github.com/sfc-gh-mharris/BNK_AI_DEMOS`
- ACCOUNTADMIN or role with CREATE DATABASE, CREATE WAREHOUSE privileges
- Snowflake account with Cortex AI features enabled

## Configuration

Before executing any SQL, collect the deployment configuration from the user using `ask_user_question`:

1. **Database** — Ask which database to deploy into. Default: `BNK`. If user specifies a different database, use it for all fully-qualified references throughout the deployment.
2. **Warehouse** — Ask which warehouse to use for compute. Default: `BNK_WH`. If user specifies an existing warehouse, skip warehouse creation (`CREATE WAREHOUSE IF NOT EXISTS`) and just use their warehouse.
3. **Schema** — Ask which schema name to use. Default: `LENDING`.

Store these three values as the **deployment configuration**. All subsequent SQL execution MUST apply these substitutions to every statement before running it:

| Default Value | Substitution |
|---------------|-------------|
| `BNK_WH` | → user's warehouse (in `USE WAREHOUSE`, `WAREHOUSE =` clauses, agent `execution_environment`) |
| `BNK.LENDING` | → `{user_db}.{user_schema}` in all fully-qualified references |
| `BNK` (standalone database references in `USE DATABASE`, `CREATE DATABASE`) | → user's database |
| `LENDING` (in `USE SCHEMA`, `CREATE SCHEMA`) | → user's schema |

**Critical — downstream propagation**: These substitutions MUST be applied in ALL contexts including:
- `WAREHOUSE =` clauses in `CREATE CORTEX SEARCH SERVICE` statements
- `warehouse:` value in agent `execution_environment` YAML (inside `$$` dollar-quoted spec)
- Fully-qualified object names inside the agent spec (semantic view references, search service `name:` fields)
- All validation and verification queries in Step 3

## Workflow

### Step 1: Locate Repository

Find the cloned repo on disk. Check common locations:
1. Current working directory
2. `~/Documents/GitHub/BNK_AI_DEMOS/`
3. Ask user if not found

Verify the `lending/` subfolder exists with files: `00_setup.sql`, `01_ddl.sql`, `02_data.sql`, `03_semantic_view.sql`, `04_search_services.sql`, `05_agent.sql`.

### Step 2: Execute Deployment Scripts in Order

Execute each SQL file sequentially using `snowflake_sql_execute`. Read each file with the `read` tool, then execute each SQL statement individually (split on semicolons, skip empty statements).

**Before executing each statement**, apply the deployment configuration substitutions from the Configuration section above. Every reference to the default database, warehouse, and schema must be replaced with the user's configured values.

**Execution order:**
1. `00_setup.sql` — Creates database, schema, warehouse (skip warehouse creation if user specified an existing warehouse)
2. `01_ddl.sql` — Creates tables
3. `02_data.sql` — Inserts synthetic borrower, mortgage, and payment data
4. `03_semantic_view.sql` — Creates SV_LENDING_ANALYTICS semantic view (substitute fully-qualified table references in the view definition)
5. `04_search_services.sql` — Creates LENDING_POLICY_SEARCH and INTERACTION_SEARCH (substitute `WAREHOUSE =` clause and fully-qualified source table names)
6. `05_agent.sql` — Creates LENDING_AGENT (substitute `execution_environment.warehouse`, semantic view FQN in tool definitions, and search service FQN in tool definitions)

**Error handling:**
- If a statement fails, report the error and the file/statement that failed
- "already exists" errors are safe to ignore (scripts use IF NOT EXISTS / CREATE OR ALTER)
- If warehouse or database doesn't exist errors occur, ensure 00_setup.sql ran first
- If "not an allowed model" error occurs, verify the agent spec uses `orchestration: auto`
- Semantic view "invalid identifier" errors: dimension aliases must match source column names exactly

### Step 3: Validate Deployment

After all scripts complete, use the **user's configured database and schema** in all verification queries:

1. Verify objects exist:
   ```sql
   SHOW TABLES IN SCHEMA {user_db}.{user_schema};
   SHOW CORTEX SEARCH SERVICES IN SCHEMA {user_db}.{user_schema};
   SHOW SEMANTIC VIEWS IN SCHEMA {user_db}.{user_schema};
   SHOW AGENTS IN SCHEMA {user_db}.{user_schema};
   ```

2. Quick agent test:
   ```sql
   SELECT TRY_PARSE_JSON(
     SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
       '{user_db}.{user_schema}.LENDING_AGENT',
       $${"messages": [{"role": "user", "content": [{"type": "text", "text": "What is the total value of our mortgage portfolio?"}]}]}$$
     )
   ) AS resp;
   ```

Present results to user.

### Step 4: Demo the Agent (Interactive)

After validation succeeds, ask the user if they'd like to see the lending agent demonstrate natural language portfolio analytics and policy search. Use `ask_user_question`:

```
"Your Lending Analytics agent is deployed. Would you like to see it answer complex portfolio questions in natural language?"
Options:
- "Yes, show me the demo" — proceed with the steps below
- "No, I'm done for now" — skip to Output
```

**If the user opts in:**

1. **Complex analytics question (Cortex Analyst).** Run a question that exercises the Semantic View with joins, filters, and aggregation:
   ```sql
   SELECT TRY_PARSE_JSON(
     SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
       '{user_db}.{user_schema}.LENDING_AGENT',
       $${"messages": [{"role": "user", "content": [{"type": "text", "text": "What are the top 5 mortgage products by delinquency rate, and what is the average loan-to-value ratio for each?"}]}]}$$
     )
   ) AS resp;
   ```

2. **Show the user what to look for:**
   - **Generated SQL** → The agent produced a correct query with GROUP BY, ratio calculations, and proper joins across the lending tables — all from a plain English question. Point out the SQL it generated.
   - **Semantic model grounding** → The agent knows which columns mean "delinquent" vs "current" because the semantic view defines business meaning. Highlight that no one had to explain the schema.
   - **Numeric precision** → The aggregation results should be accurate. Compare against a manual spot-check if desired.

3. **Policy + interaction search.** Run a question that triggers both Search tools:
   ```sql
   SELECT TRY_PARSE_JSON(
     SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
       '{user_db}.{user_schema}.LENDING_AGENT',
       $${"messages": [{"role": "user", "content": [{"type": "text", "text": "What is our policy on loan modifications for borrowers in hardship, and have any recent customer interactions mentioned forbearance requests?"}]}]}$$
     )
   ) AS resp;
   ```
   Point out how the agent searches two separate corpora (lending policies and customer interactions) and synthesizes them into a coherent answer with citations.

4. **Call out key observations:**
   - The Semantic View translates business questions into SQL without exposing table complexity to the user
   - The agent combines quantitative answers (Analyst) with qualitative context (Search) in one response
   - Policy search returns specific regulation/guideline citations, not generic summaries
   - Interaction search surfaces relevant customer conversations that would take hours to find manually
   - Typical response time: 5-15 seconds for analytics, 3-8 seconds for pure search

## Stopping Points

- Step 4 is interactive. If the user declines, stop after Step 3 results.

## Output

Fully deployed Lending Analytics use case in `{user_db}.{user_schema}` schema with a working Cortex Agent accessible in Snowflake CoWork.

## Troubleshooting

**"Tool X is missing execution_environment"** — The agent spec must include `execution_environment: {type: warehouse, warehouse: {user_warehouse}}` for Cortex Analyst tools. Verify the substitution was applied inside the dollar-quoted agent spec.

**"Column X doesn't have a text index"** — In the agent's `columns_and_descriptions`, only the ON column should be `searchable: true`. All ATTRIBUTES must be `searchable: false, filterable: true`.

**"invalid identifier" in semantic view** — Dimension aliases in DIMENSIONS clause must match the source column name exactly (e.g., `mortgages.status AS status`, not `mortgages.status AS mortgage_status`).

**"invalid identifier" in agent spec** — If the user changed the database or schema, ensure all fully-qualified names inside the agent YAML spec were updated. The agent references search services and semantic views by their full `DB.SCHEMA.OBJECT` path.

**Agent not visible in CoWork** — Ensure the CREATE AGENT statement includes a PROFILE clause with display_name.

**Warehouse does not exist** — If the user specified a custom warehouse, verify it exists before deployment. The skill skips `CREATE WAREHOUSE` when the user provides an existing warehouse name.
