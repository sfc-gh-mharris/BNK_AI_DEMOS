# KYC/AML Document Processing Pipeline

AI-powered Know Your Customer and Anti-Money Laundering compliance platform on Snowflake. Automates document ingestion, classification, data extraction, and identity verification.

## Prerequisites

- Snowflake account with `ACCOUNTADMIN` or role with `CREATE DATABASE`, `CREATE WAREHOUSE` privileges
- Warehouse size MEDIUM or larger (for AI functions)

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
PUT file:///path/to/kyc_aml/sample_documents/pdfs/clients/*/*.pdf
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
