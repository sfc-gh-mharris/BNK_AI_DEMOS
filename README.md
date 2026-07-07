# Banking AI Demo

End-to-end banking AI demonstrations built on Snowflake Cortex. Each use case showcases different Cortex AI capabilities — Cortex Agents, Cortex Analyst (Semantic Views), Cortex Search, and AI_PARSE_DOCUMENT — applied to realistic banking scenarios.

## Use Cases

| Use Case | Schema | Capabilities | Description |
|----------|--------|--------------|-------------|
| **Customer 360** | `BNK.CUSTOMER_360` | Cortex Analyst + Search | Unified customer view with transaction analytics and note search |
| **KYC/AML** | `BNK.KYC_AML` | Document Pipeline + Search | Identity document processing with policy compliance search |
| **Lending Analytics** | `BNK.LENDING` | Cortex Analyst + Search | Mortgage portfolio analytics with policy and interaction search |
| **Wealth Management** | `BNK.WEALTH_MGMT` | Cortex Analyst + Search + Documents | Portfolio analytics, research search, compliance, and onboarding doc processing |

## Prerequisites

- **Snowflake account** with Cortex AI features enabled
- **ACCOUNTADMIN** role (or equivalent: CREATE DATABASE, CREATE WAREHOUSE, CREATE STAGE)
- **[Cortex Code Desktop](https://docs.snowflake.com/en/user-guide/cortex-code/cortex-code)** installed

## Deployment with Cortex Code

This repo includes built-in Cortex Code skills that automate the entire deployment. No manual SQL execution required.

### Step 1: Clone the repository

```bash
git clone https://github.com/sfc-gh-jheisler/BNK_AI_DEMOS.git
```

### Step 2: Open in Cortex Code

Open Cortex Code Desktop and open the cloned `BNK_AI_DEMOS` folder as your workspace.

### Step 3: Connect to Snowflake

Use the Snowflake connection picker (bottom status bar) to connect to your target account.

### Step 4: Deploy with skills

Type `/` in the Cortex Code chat to see available skills. Select the use case you want to deploy:

| Skill Command | Deploys |
|---------------|---------|
| `/deploy-customer360` | Customer 360 — Cortex Analyst + 2 Search Services + Agent |
| `/deploy-kyc` | KYC/AML — Document Pipeline + Search + Agent |
| `/deploy-lending` | Lending Analytics — Cortex Analyst + 2 Search Services + Agent |
| `/deploy-wealth-mgmt` | Wealth Management — Cortex Analyst + 3 Search Services + Document Pipeline + Agent |

Each skill reads the SQL scripts from the corresponding subfolder and executes them in order. The deployment is fully idempotent — you can re-run safely.

### Step 5: Use the agents

After deployment, access your agents in:

- **Snowflake CoWork** — The AI chat interface in Snowsight (agents appear automatically)
- **Direct SQL** — Query agents programmatically:

```sql
SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
  'BNK.CUSTOMER_360.CUSTOMER_360_AGENT',
  [{'role': 'user', 'content': 'How many customers do we have?'}]
);
```

## What Gets Deployed

All use cases deploy into the **BNK** database with a shared **BNK_WH** warehouse (MEDIUM, auto-suspend 300s).

### Objects Created

| Schema | Agent | Semantic View | Search Services | Document Pipeline |
|--------|-------|---------------|-----------------|-------------------|
| CUSTOMER_360 | CUSTOMER_360_AGENT | SV_CUSTOMER_360 | CUSTOMER_NOTES_SEARCH, POLICY_SEARCH | — |
| KYC_AML | KYC_AGENT | — | KYC_POLICY_SEARCH | AI_PARSE_DOCUMENT procedures |
| LENDING | LENDING_AGENT | SV_LENDING_ANALYTICS | LENDING_POLICY_SEARCH, INTERACTION_SEARCH | — |
| WEALTH_MGMT | WEALTH_MGMT_AGENT | SV_WEALTH_PORTFOLIO | RESEARCH_SEARCH, COMPLIANCE_SEARCH, CLIENT_NOTES_SEARCH | AI_PARSE_DOCUMENT procedures |

## Manual Deployment (without Cortex Code)

If you prefer to deploy manually, execute the SQL files in each subfolder in numbered order:

```bash
# Example: Deploy Customer 360
# Execute in Snowsight or SnowSQL, in this order:
customer_360/00_setup.sql
customer_360/01_ddl.sql
customer_360/02_data.sql
customer_360/03_semantic_view.sql
customer_360/04_search_services.sql
customer_360/05_agent.sql
```

## Teardown

Each use case includes a `99_teardown.sql` script to remove all objects:

```sql
-- Run in Snowsight or via Cortex Code
-- Example: Remove Customer 360
@customer_360/99_teardown.sql
```

## Repository Structure

```
├── .cortex/skills/          # Cortex Code deployment skills (auto-detected)
│   ├── deploy-customer360/
│   ├── deploy-kyc/
│   ├── deploy-lending/
│   └── deploy-wealth-mgmt/
├── customer_360/            # Customer 360 use case
│   ├── 00_setup.sql         # Database, schema, warehouse
│   ├── 01_ddl.sql           # Table definitions
│   ├── 02_data.sql          # Synthetic data
│   ├── 03_semantic_view.sql # Cortex Analyst semantic view
│   ├── 04_search_services.sql # Cortex Search services
│   ├── 05_agent.sql         # Cortex Agent
│   ├── 99_teardown.sql      # Cleanup
│   └── build_only/          # Internal tooling (not for customer deployment)
├── kyc_aml/                 # KYC/AML use case (same structure + document pipeline)
├── lending/                 # Lending Analytics use case
├── wealth_mgmt/             # Wealth Management use case (most comprehensive)
└── data_refresh/            # Streamlit app for refreshing demo dates
```

## Notes

- All scripts use `CREATE IF NOT EXISTS` or `CREATE OR ALTER` — safe to re-run
- The `build_only/` folders contain Python scripts used to generate the synthetic data; they are not needed for deployment
- Agents use `orchestration: auto` for model selection
- Search Services require a few minutes after creation to index data before they return results
