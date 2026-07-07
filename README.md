# Banking AI Demo

End-to-end banking AI demonstrations built on Snowflake Cortex. Each use case showcases different Cortex AI capabilities — Cortex Agents, Cortex Analyst (Semantic Views), Cortex Search, and AI_PARSE_DOCUMENT — applied to realistic banking scenarios.

## Use Cases

| Use Case | Schema | Capabilities | Description |
|----------|--------|--------------|-------------|
| **Customer 360** | `BNK.CUSTOMER_360` | Cortex Analyst + Search | Unified customer view with transaction analytics and note search |
| **KYC/AML** | `BNK.KYC_AML` | Document Pipeline + Search | Identity document processing with policy compliance search. Includes sample PDFs and generator. |
| **Lending Analytics** | `BNK.LENDING` | Cortex Analyst + Search | Mortgage portfolio analytics with policy and interaction search |
| **Wealth Management** | `BNK.WEALTH_MGMT` | Cortex Analyst + Search + Documents | Portfolio analytics, research search, compliance, and onboarding doc processing |

## Prerequisites

- **Snowflake account** with Cortex AI features enabled
- **ACCOUNTADMIN** role (or equivalent: CREATE DATABASE, CREATE WAREHOUSE, CREATE STAGE)

## Deployment Options

### Option A: Cortex Code Desktop (recommended)

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

After deployment, each skill offers an interactive demo walkthrough that showcases the key AI capabilities of that use case (multi-tool agent orchestration, document parsing, natural language analytics, etc.).

### Step 5: Use the agents

After deployment, access your agents in:

- **Snowflake CoWork** — The AI chat interface in Snowsight (agents appear automatically)
- **Direct SQL** — Query agents programmatically:

```sql
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'BNK.CUSTOMER_360.CUSTOMER_360_AGENT',
    $${"messages": [{"role": "user", "content": [{"type": "text", "text": "How many customers do we have?"}]}]}$$
  )
) AS resp;
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

### Option B: Snowflake Workspaces (via Git integration)

If you prefer to work directly in Snowsight without installing Cortex Code Desktop, you can connect this repository to Snowflake Workspaces.

#### 1. Create a GitHub Personal Access Token

1. Go to **github.com > Settings > Developer settings > Personal access tokens > Tokens (classic)**
2. Click **"Generate new token (classic)"**
3. Name it (e.g. `snowflake-workspace`), set expiration (90 days or no expiration for demos)
4. Select scope: **`repo`** (full control of private repositories)
5. Click **"Generate token"** and copy the token immediately

#### 2. Create a Snowflake SECRET

```sql
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE SECRET BNK.PUBLIC.GIT_PAT_SECRET
  TYPE = password
  USERNAME = '<YOUR_GITHUB_USERNAME>'
  PASSWORD = '<YOUR_GITHUB_PAT>';
```

#### 3. Create an API Integration

```sql
CREATE OR REPLACE API INTEGRATION GIT_API_INTEGRATION
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-jheisler')
  ALLOWED_AUTHENTICATION_SECRETS = (BNK.PUBLIC.GIT_PAT_SECRET)
  ENABLED = TRUE;
```

#### 4. Create a Git Repository object

```sql
CREATE OR REPLACE GIT REPOSITORY BNK.PUBLIC.BNK_AI_DEMOS
  API_INTEGRATION = GIT_API_INTEGRATION
  GIT_CREDENTIALS = BNK.PUBLIC.GIT_PAT_SECRET
  ORIGIN = 'https://github.com/sfc-gh-jheisler/BNK_AI_DEMOS.git';
```

#### 5. Run the SQL

Navigate to **Snowsight > Projects > Workspaces**, select the repository, and execute the SQL files in numbered order for each use case (e.g. `kyc_aml/00_setup.sql` through `05_agent.sql`). Each file runs independently — just open and execute.

#### 6. (Optional) Add the deploy skills to Cortex Code in Snowsight

The `.cortex/skills/` folder in this repo contains deployment skills that automate the full setup. To use them in the Snowsight Cortex Code UI:

1. Open your Workspace in Snowsight
2. Click the **Cortex Code icon** (bottom-right corner) to open the assistant panel
3. In the Cortex Code panel, click the **`/`** menu and select **"+ Upload Skill Folder(s)"**
4. Navigate to the `.cortex/skills/` directory in the workspace file explorer and upload the skill folder you want (e.g. `deploy-kyc`)
5. The skill is now available — type `/` in the message box and select it (e.g. `/deploy-kyc`)

Alternatively, you can upload individual skill files:
- Click **"Upload Skill File(s)"** and select the `SKILL.md` file from any skill folder

Once uploaded, the skills appear under the `/` menu and provide the same automated deployment + interactive demo walkthrough as in Cortex Code Desktop.

### Option C: Manual Deployment (without Cortex Code)

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
│   ├── INSTRUCTIONS.md      # Full usage guide
│   └── sample_documents/    # Pre-generated PDFs + generator script for pipeline demo
├── lending/                 # Lending Analytics use case
├── wealth_mgmt/             # Wealth Management use case (most comprehensive)
└── data_refresh/            # Streamlit app for refreshing demo dates
```

## Notes

- All scripts use `CREATE IF NOT EXISTS` or `CREATE OR ALTER` — safe to re-run
- The `build_only/` folders contain Python scripts used to generate the synthetic data; they are not needed for deployment
- The KYC/AML use case includes `sample_documents/` with pre-generated PDFs ready to upload to the stage — see `kyc_aml/INSTRUCTIONS.md` for the full pipeline walkthrough
- Agents use `orchestration: auto` for model selection
- Search Services require a few minutes after creation to index data before they return results
