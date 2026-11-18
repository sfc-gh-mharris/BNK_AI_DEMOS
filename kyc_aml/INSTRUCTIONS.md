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
  API_ALLOWED_PREFIXES = ('https://github.com/sfc-gh-mharris')
  ALLOWED_AUTHENTICATION_SECRETS = (BNK.PUBLIC.GIT_PAT_SECRET)
  ENABLED = TRUE;

-- 3. Create the Git Repository object
CREATE OR REPLACE GIT REPOSITORY BNK.PUBLIC.BNK_AI_DEMOS
  API_INTEGRATION = GIT_API_INTEGRATION
  GIT_CREDENTIALS = BNK.PUBLIC.GIT_PAT_SECRET
  ORIGIN = 'https://github.com/sfc-gh-mharris/BNK_AI_DEMOS.git';
```

Then navigate to **Snowsight > Projects > Workspaces**, select `BNK_AI_DEMOS`, and open the `kyc_aml/` folder. Execute each SQL file in numbered order.

> **GitHub PAT**: Go to github.com > Settings > Developer settings > Personal access tokens > Tokens (classic). Generate a token with `repo` scope.

### Opening the Repository as a Workspace

1. In Snowsight, click **Projects** in the left navigation bar
2. Click **Workspaces**
3. Click the **+ Workspace** button (top right)
4. Select **"From Git repository"**
5. Fill in the form:
   - **Repository URL:** `https://github.com/sfc-gh-mharris/BNK_AI_DEMOS.git`
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
00_setup.sql             - Database, schema, warehouse, directory-enabled internal stage
01_ddl.sql               - Tables: CLIENTS, KYC_CASES, DOCUMENTS_METADATA, VERIFICATION_RESULTS, KYC_POLICIES, ALERT_QUEUE
02_data.sql              - Synthetic data: 100K clients, 200K cases, 500K documents, 25 compliance policies, plus 5 showcase demo cases
03_search_services.sql   - Cortex Search over KYC policies (Arctic Embed L v2.0)
03b_semantic_view.sql    - Semantic View (SV_KYC_AML) over all 5 structured KYC/AML tables
04_document_pipeline.sql - Stored procedures for AI document processing and identity verification
05_agent.sql             - KYC Agent with Cortex Analyst, policy search, and live verification tools
```

Alternatively, use the Cortex Code deploy skill: `/deploy-kyc`

## Using the Document Pipeline

### 1. Upload sample documents to the stage

Pre-generated PDFs are in `sample_documents/pdfs/clients/`. Upload them via Snow CLI or SnowSQL (or Snowsight Stage UI):

```sql
-- Adjust the file path to your local clone location
PUT file:///path/to/kyc_aml/sample_documents/pdfs/clients/*.pdf
    @BNK.KYC_AML.KYC_DOCUMENTS/clients/
    AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

ALTER STAGE BNK.KYC_AML.KYC_DOCUMENTS REFRESH;
```

To generate more documents locally:

```bash
pip install fpdf2
python sample_documents/generate_pdfs.py --output sample_documents/pdfs --count 50
```

### 2. Process a single document

```sql
-- Pass the relative path within @BNK.KYC_AML.KYC_DOCUMENTS
CALL BNK.KYC_AML.PROCESS_KYC_DOCUMENT(
    'clients/Passport_54866c22-96f2-4967-a248-1d6b72a2310f.pdf'
);
```

Returns a VARIANT with:
- `classification` and `predicted_type` - detected document type from `AI_CLASSIFY`
- `extracted_fields` and `field_scores` - structured data and per-field confidence scores from `AI_EXTRACT`
- `parsed_pages` - raw OCR/layout Markdown output from `AI_PARSE_DOCUMENT`

### 3. Process staged documents in batch

```sql
-- Process up to 5 staged Pending documents
CALL BNK.KYC_AML.BATCH_PROCESS_DOCUMENTS(5);
```

### 4. End-to-end: process and verify against client master

`02_data.sql` seeds five showcase clients linked to staged sample PDFs:
- `CL-DEMO-001` (`Oliver Clarke`, UK PEP) + `54866c22-96f2-4967-a248-1d6b72a2310f` -> `Match`
- `CL-DEMO-002` (`Jen Muller`, High risk) + `99c221cb-eb27-44bd-88d7-b69929da359b` -> `Partial` (surname transliteration)
- `CL-DEMO-003` (`Marcus Sterling`, High risk) + `f89335ea-0fd0-4e9e-8b72-fedd94795d9a` -> `Mismatch` (wrong person's passport)
- `CL-DEMO-004` (`Nexus Technology Solutions GmbH`, Corporate) + `f55f0a67-05dd-4903-9200-6e8c95d3e5d3` -> `Match` + flags mislabeled upload (`Passport` vs `FinancialStatement`)
- `CL-DEMO-005` (`James Williams`, Medium risk) + `5b502551-c7ae-4ba5-a196-aafd4fb16d03` -> `Match` (German Driver's License)

```sql
CALL BNK.KYC_AML.PROCESS_AND_VERIFY_DOCUMENT('CL-DEMO-001', '54866c22-96f2-4967-a248-1d6b72a2310f');
```

### 5. Re-verify identity against client master

```sql
CALL BNK.KYC_AML.VERIFY_IDENTITY('CL-DEMO-001', '54866c22-96f2-4967-a248-1d6b72a2310f');
```

Compares extracted fields against `CLIENTS` using Jaro-Winkler name similarity, DOB, ISO-3 nationality, document expiry, and declared vs classified document type.

## Using the KYC Agent

The agent is available in Snowflake Intelligence (CoWork) after deployment. Sample questions:

- "How many high-risk and PEP clients currently have overdue periodic reviews, broken down by priority?"
- "Review client Oliver Clarke (CL-DEMO-001): process and verify his pending passport and tell me what UK PEP due diligence steps apply."
- "Process and verify the uploaded documents for Marcus Sterling (CL-DEMO-003) and Nexus Technology Solutions GmbH (CL-DEMO-004) and flag any compliance risks."
- "Show all open Critical alerts by alert type and summarize our SLA obligations under ongoing monitoring and sanctions policies."

The agent has access to:
- **KYCAnalyst** - Cortex Analyst over `SV_KYC_AML` across all 5 structured KYC/AML tables
- **KYCPolicySearch** - RAG over 25 compliance policies across US/UK/EU/APAC/Global jurisdictions with citations
- **ProcessAndVerifyDocument** & **VerifyIdentity** - Live AI document extraction and client verification procedures

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
