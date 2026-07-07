# KYC/AML Document Processing Pipeline

AI-powered Know Your Customer and Anti-Money Laundering compliance platform on Snowflake. Automates document ingestion, classification, data extraction, and identity verification.

## Prerequisites

- Snowflake account with `ACCOUNTADMIN` or role with `CREATE DATABASE`, `CREATE WAREHOUSE` privileges
- Warehouse size MEDIUM or larger (for AI functions)

## Opening in Snowflake Workspaces

To run these scripts directly in Snowsight without cloning locally:

```sql
USE ROLE ACCOUNTADMIN;

-- 1. Store your GitHub credentials
CREATE OR REPLACE SECRET BNK.PUBLIC.GIT_PAT_SECRET
  TYPE = password
  USERNAME = '<YOUR_GITHUB_USERNAME>'
  PASSWORD = '<YOUR_GITHUB_PAT>';

-- 2. Create API integration for GitHub access
CREATE OR REPLACE API INTEGRATION GIT_API_INTEGRATION
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-jheisler')
  ALLOWED_AUTHENTICATION_SECRETS = (BNK.PUBLIC.GIT_PAT_SECRET)
  ENABLED = TRUE;

-- 3. Create the Git Repository object
CREATE OR REPLACE GIT REPOSITORY BNK.PUBLIC.BNK_AI_DEMOS
  API_INTEGRATION = GIT_API_INTEGRATION
  GIT_CREDENTIALS = BNK.PUBLIC.GIT_PAT_SECRET
  ORIGIN = 'https://github.com/sfc-gh-jheisler/BNK_AI_DEMOS.git';
```

Then navigate to **Snowsight > Projects > Workspaces**, select `BNK_AI_DEMOS`, and open the `kyc_aml/` folder. Execute each SQL file in numbered order.

> **GitHub PAT**: Go to github.com > Settings > Developer settings > Personal access tokens > Tokens (classic). Generate a token with `repo` scope.

### Opening the Repository as a Workspace

1. In Snowsight, click **Projects** in the left navigation bar
2. Click **Workspaces**
3. Click the **+ Workspace** button (top right)
4. Select **"From Git repository"**
5. Fill in the form:
   - **Repository URL:** `https://github.com/sfc-gh-jheisler/BNK_AI_DEMOS.git`
   - **API Integration:** Select `GIT_API_INTEGRATION` from the dropdown
   - **Authentication method:** Select **"Personal access token"**
   - **Secret:** Browse to `BNK.PUBLIC` and select `GIT_PAT_SECRET`
6. Click **"Create"**

Snowflake will clone the repo and open it as a workspace. All files from the repository will appear in the file explorer on the left.

### Working with Your Workspace

Once open, you can:

- **Switch branches** — Use the branch selector at the top of the file explorer
- **Pull changes** — Click the pull icon to sync latest changes from GitHub
- **Run files** — Open any `.sql` file and execute it directly
- **Navigate** — Open the `kyc_aml/` folder and run scripts `00_setup.sql` through `05_agent.sql` in order

## Deployment

Run the SQL scripts in order. Each is idempotent (safe to re-run).

```
00_setup.sql          — Database, schema, warehouse, internal stage
01_ddl.sql            — Tables: CLIENTS, KYC_CASES, DOCUMENTS_METADATA, VERIFICATION_RESULTS, KYC_POLICIES, ALERT_QUEUE
02_data.sql           — Synthetic data: 100K clients, 200K cases, 500K documents, 25 compliance policies
03_search_services.sql — Cortex Search over KYC policies (Arctic Embed L v2.0)
04_document_pipeline.sql — Stored procedures for AI document processing
05_agent.sql          — KYC Agent with policy search + code execution
```

Alternatively, use the Cortex Code deploy skill: `/deploy-kyc`

## Using the Document Pipeline

### 1. Upload sample documents to the stage

Pre-generated PDFs are in `sample_documents/pdfs/`. Upload them:

```sql
-- Adjust the file path to your local clone location
PUT file:///path/to/kyc_aml/sample_documents/pdfs/clients/*.pdf
    @BNK.KYC_AML.KYC_DOCUMENTS/clients/
    AUTO_COMPRESS=FALSE;
```

To generate more documents locally:

```bash
pip install fpdf2
python sample_documents/generate_pdfs.py --output sample_documents/pdfs --count 50
```

### 2. Process a single document

```sql
-- Pass the relative path within the stage
CALL BNK.KYC_AML.PROCESS_KYC_DOCUMENT(
    'clients/<client_id>/Passport_<doc_id>.pdf'
);
```

Returns a VARIANT with:
- `classification` — detected document type and confidence
- `extracted_fields` — structured data (name, DOB, document number, etc.)
- `parsed_pages` — raw OCR output with layout

### 3. Process documents in batch

```sql
-- Process up to 10 pending documents
CALL BNK.KYC_AML.BATCH_PROCESS_DOCUMENTS(10);
```

### 4. Verify identity against client master

```sql
CALL BNK.KYC_AML.VERIFY_IDENTITY('<client_id>', '<doc_id>');
```

Compares extracted fields against the CLIENTS table using fuzzy matching (Jaro-Winkler similarity). Produces match/partial/mismatch determination with per-field confidence scores.

### 5. End-to-end: process and verify in one call

```sql
CALL BNK.KYC_AML.PROCESS_AND_VERIFY_DOCUMENT('<client_id>', 'clients/<client_id>/Passport_<doc_id>.pdf');
```

## Using the KYC Agent

The agent is available in Snowflake Intelligence (CoWork) after deployment. Sample questions:

- "What are the enhanced due diligence requirements for PEP clients?"
- "What documents are required for corporate client onboarding?"
- "How many high-risk clients have overdue periodic reviews?"
- "Show me all critical alerts from the past 30 days by jurisdiction"

The agent has access to:
- **KYCPolicySearch** — RAG over 25 compliance policies covering CDD, EDD, PEP, Sanctions, Beneficial Ownership, and Ongoing Monitoring across US/UK/EU/APAC/Global jurisdictions
- **code_execution** — Python for ad-hoc queries across all KYC tables

## Pipeline Architecture

```
Document Upload    →  AI_PARSE_DOCUMENT   →  AI_CLASSIFY         →  AI_EXTRACT           →  VERIFY_IDENTITY
(PUT to stage)        (OCR + layout)          (doc type detection)    (structured fields)     (fuzzy match vs client master)
```

## Data Model

| Table | Rows | Purpose |
|-------|------|---------|
| CLIENTS | 100K | Master client records (individuals + corporates) |
| KYC_CASES | 200K | Periodic review and trigger event cases |
| DOCUMENTS_METADATA | 500K | Document tracking (file paths, extraction status) |
| VERIFICATION_RESULTS | 500K | AI extraction output + identity match scores |
| KYC_POLICIES | 25 | Compliance policy library (searched via Cortex Search) |
| ALERT_QUEUE | 50K | Risk alerts requiring analyst review |

## Teardown

```sql
-- Removes all objects created by this demo
@99_teardown.sql
```

## File Structure

```
kyc_aml/
├── 00_setup.sql                  — Infrastructure
├── 01_ddl.sql                    — Table definitions
├── 02_data.sql                   — Synthetic data
├── 03_search_services.sql        — Cortex Search
├── 04_document_pipeline.sql      — AI processing procedures
├── 05_agent.sql                  — Cortex Agent
├── 99_teardown.sql               — Cleanup
├── PLAN.md                       — Architecture deep-dive
├── INSTRUCTIONS.md               — This file
└── sample_documents/
    ├── README.md                 — Upload instructions
    ├── generate_pdfs.py          — PDF generator script
    └── pdfs/clients/...          — Pre-generated sample PDFs
```
