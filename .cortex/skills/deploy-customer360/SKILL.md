---
name: deploy-customer360
description: "Deploy the Customer 360 banking AI demo use case to Snowflake. Creates a Cortex Agent with Semantic View (Cortex Analyst) and Search Services for customer notes and policies. Use when: deploying customer 360, banking demo, customer agent. Triggers: deploy customer360, deploy customer 360, banking customer agent."
---

# Deploy Customer 360

Deploys the Customer 360 use case from the `bnk-ai-demos` repository. This creates:
- Database and CUSTOMER_360 schema
- Tables: CUSTOMERS, ACCOUNTS, TRANSACTIONS, CUSTOMER_NOTES, BANKING_POLICIES
- Semantic View: SV_CUSTOMER_360 (Cortex Analyst)
- Search Services: CUSTOMER_NOTES_SEARCH, POLICY_SEARCH
- Agent: CUSTOMER_360_AGENT (combines Analyst + Search tools)

## Prerequisites

- Cloned repo: `https://github.com/sfc-gh-jheisler/BNK_AI_DEMOS`
- ACCOUNTADMIN or role with CREATE DATABASE, CREATE WAREHOUSE privileges
- Snowflake account with Cortex AI features enabled

## Configuration

Before executing any SQL, collect the deployment configuration from the user using `ask_user_question`:

1. **Database** — Ask which database to deploy into. Default: `BNK`. If user specifies a different database, use it for all fully-qualified references throughout the deployment.
2. **Warehouse** — Ask which warehouse to use for compute. Default: `BNK_WH`. If user specifies an existing warehouse, skip warehouse creation (`CREATE WAREHOUSE IF NOT EXISTS`) and just use their warehouse.
3. **Schema** — Ask which schema name to use. Default: `CUSTOMER_360`.

Store these three values as the **deployment configuration**. All subsequent SQL execution MUST apply these substitutions to every statement before running it:

| Default Value | Substitution |
|---------------|-------------|
| `BNK_WH` | → user's warehouse (in `USE WAREHOUSE`, `WAREHOUSE =` clauses, agent `execution_environment`) |
| `BNK.CUSTOMER_360` | → `{user_db}.{user_schema}` in all fully-qualified references |
| `BNK` (standalone database references in `USE DATABASE`, `CREATE DATABASE`) | → user's database |
| `CUSTOMER_360` (in `USE SCHEMA`, `CREATE SCHEMA`) | → user's schema |

**Critical — downstream propagation**: These substitutions MUST be applied in ALL contexts including:
- `WAREHOUSE =` clauses in `CREATE CORTEX SEARCH SERVICE` statements
- `warehouse:` value in agent `execution_environment` YAML (inside `$$` dollar-quoted spec)
- Fully-qualified object names inside the agent spec (semantic view references, search service `name:` fields)
- All validation and verification queries in Step 3
- Stage references (`@DB.SCHEMA.STAGE_NAME`) if applicable

## Workflow

### Step 1: Locate Repository

Find the cloned repo on disk. Check common locations:
1. Current working directory
2. `~/Documents/GitHub/BNK_AI_DEMOS/`
3. Ask user if not found

Verify the `customer_360/` subfolder exists with files: `00_setup.sql`, `01_ddl.sql`, `02_data.sql`, `03_semantic_view.sql`, `04_search_services.sql`, `05_agent.sql`.

### Step 2: Execute Deployment Scripts in Order

Execute each SQL file sequentially using `snowflake_sql_execute`. Read each file with the `read` tool, then execute each SQL statement individually (split on semicolons, skip empty statements).

**Before executing each statement**, apply the deployment configuration substitutions from the Configuration section above. Every reference to the default database, warehouse, and schema must be replaced with the user's configured values.

**Execution order:**
1. `00_setup.sql` — Creates database, schema, warehouse (skip warehouse creation if user specified an existing warehouse)
2. `01_ddl.sql` — Creates tables
3. `02_data.sql` — Inserts synthetic banking data
4. `03_semantic_view.sql` — Creates SV_CUSTOMER_360 semantic view (substitute fully-qualified table references in the view definition)
5. `04_search_services.sql` — Creates CUSTOMER_NOTES_SEARCH and POLICY_SEARCH (substitute `WAREHOUSE =` clause and fully-qualified source table names)
6. `05_agent.sql` — Creates CUSTOMER_360_AGENT (substitute `execution_environment.warehouse`, semantic view FQN in tool definitions, and search service FQN in tool definitions)

**Error handling:**
- If a statement fails, report the error and the file/statement that failed
- Common fix: If "already exists" errors appear, these are safe to ignore (scripts use IF NOT EXISTS / CREATE OR ALTER)
- If warehouse or database doesn't exist errors occur, ensure 00_setup.sql ran first
- If "not an allowed model" error occurs, verify the agent spec uses `orchestration: auto`

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
       '{user_db}.{user_schema}.CUSTOMER_360_AGENT',
       $${"messages": [{"role": "user", "content": [{"type": "text", "text": "How many customers do we have?"}]}]}$$
     )
   ) AS resp;
   ```

Present results to user.

### Step 4: Demo the Agent (Interactive)

After validation succeeds, ask the user if they'd like to see the agent's multi-tool capabilities in action. Use `ask_user_question`:

```
"Your Customer 360 agent is deployed. Would you like to see it combine structured analytics with unstructured search in a single question?"
Options:
- "Yes, show me the demo" — proceed with the steps below
- "No, I'm done for now" — skip to Output
```

**If the user opts in:**

1. **Multi-tool question (Analyst + Search combined).** Run a question that forces the agent to use both its Semantic View (Cortex Analyst) and Search tools:
   ```sql
   SELECT TRY_PARSE_JSON(
     SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
       '{user_db}.{user_schema}.CUSTOMER_360_AGENT',
       $${"messages": [{"role": "user", "content": [{"type": "text", "text": "Who are our top 5 customers by total account balance, and are there any recent notes or concerns flagged for them?"}]}]}$$
     )
   ) AS resp;
   ```

2. **Show the user what to look for in the output:**
   - **Tool orchestration** → The agent should call Cortex Analyst first (to get top customers by balance from structured data), then Cortex Search on customer notes for those specific clients. Point out the multi-step reasoning.
   - **SQL generation** → Expand the analyst tool call to show the generated SQL. Highlight that it correctly joined the right tables and applied the right aggregation without any SQL being written by the user.
   - **Search grounding** → The notes search results should include citations. Point out how the agent synthesizes structured numbers with unstructured context.

3. **Policy search demo.** Run a pure search question to show RAG quality:
   ```sql
   SELECT TRY_PARSE_JSON(
     SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
       '{user_db}.{user_schema}.CUSTOMER_360_AGENT',
       $${"messages": [{"role": "user", "content": [{"type": "text", "text": "What is our policy on fee waivers for high-value clients?"}]}]}$$
     )
   ) AS resp;
   ```
   Point out that the response cites specific policies and provides actionable guidance grounded in institutional rules.

4. **Call out key observations:**
   - The agent decides which tools to call based on the question — no routing logic needed
   - Analyst generates correct SQL over the semantic model without the user knowing table/column names
   - Search results are filtered by relevant attributes (customer segment, topic) automatically
   - Multi-turn conversations maintain context (the user can follow up without restating context)
   - Response time is typically 5-15 seconds depending on query complexity

## Stopping Points

- Step 4 is interactive. If the user declines, stop after Step 3 results.

## Output

Fully deployed Customer 360 use case in `{user_db}.{user_schema}` schema with a working Cortex Agent accessible in Snowflake CoWork.

## Troubleshooting

**"Tool X is missing execution_environment"** — The agent spec must include `execution_environment: {type: warehouse, warehouse: {user_warehouse}}` for Cortex Analyst tools. Verify the substitution was applied inside the dollar-quoted agent spec.

**"Column X doesn't have a text index"** — In the agent's `columns_and_descriptions`, only the ON column should be `searchable: true`. All ATTRIBUTES must be `searchable: false, filterable: true`.

**"invalid identifier" in agent spec** — If the user changed the database or schema, ensure all fully-qualified names inside the agent YAML spec were updated. The agent references search services and semantic views by their full `DB.SCHEMA.OBJECT` path.

**Agent not visible in CoWork** — Ensure the CREATE AGENT statement includes a PROFILE clause with display_name.

**Warehouse does not exist** — If the user specified a custom warehouse, verify it exists before deployment. The skill skips `CREATE WAREHOUSE` when the user provides an existing warehouse name.
