# KYC/AML Document Processing Pipeline — Architecture

## Overview

This use case demonstrates an AI-driven KYC (Know Your Customer) and AML (Anti-Money Laundering) compliance platform built entirely on Snowflake. The system automates document ingestion, classification, data extraction, identity verification, and policy-aware decision support — replacing manual analyst workflows with an AI-orchestrated pipeline.

## Pipeline Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                        KYC Document Processing Pipeline                    │
├──────────────────────────────────────────────────────────────────────────┤
│                                                                            │
│  ┌─────────────┐     ┌────────────────┐     ┌────────────────────┐       │
│  │  Document    │     │ AI_PARSE_      │     │  AI_CLASSIFY       │       │
│  │  Upload to   │────▶│ DOCUMENT       │────▶│  (Doc Type         │       │
│  │  Stage       │     │ (OCR + Layout) │     │   Detection)       │       │
│  └─────────────┘     └────────────────┘     └────────────────────┘       │
│                                                        │                  │
│                                                        ▼                  │
│  ┌─────────────┐     ┌────────────────┐     ┌────────────────────┐       │
│  │ VERIFICATION │     │ Cross-Reference│     │  AI_EXTRACT        │       │
│  │ _RESULTS     │◀────│ Against Client │◀────│  (Structured       │       │
│  │ (Final)      │     │ Master Data    │     │   Field Extraction)│       │
│  └─────────────┘     └────────────────┘     └────────────────────┘       │
│                                                                            │
└──────────────────────────────────────────────────────────────────────────┘
```

### Stage 1: Document Ingestion

Documents (passports, driver's licenses, financial statements, utility bills, corporate registries) are uploaded to the Snowflake internal stage `@BNK.KYC_AML.KYC_DOCUMENTS`. The stage organizes files by client:

```
@BNK.KYC_AML.KYC_DOCUMENTS/
  clients/<client_id>/
    Passport_<doc_id>.pdf
    FinancialStatement_<doc_id>.pdf
    UtilityBill_<doc_id>.pdf
```

**Sample documents** are included in `sample_documents/pdfs/` — upload them to the stage to exercise the pipeline immediately. See `sample_documents/README.md` for instructions. To generate additional documents, run `sample_documents/generate_pdfs.py`.

### Stage 2: AI_PARSE_DOCUMENT (OCR + Layout Extraction)

The `PROCESS_KYC_DOCUMENT` stored procedure calls `AI_PARSE_DOCUMENT` with `LAYOUT` mode to extract structured text while preserving document layout. This handles:
- Scanned identity documents (passports, licenses)
- Multi-page financial statements
- Corporate registry filings with tables and structured data

### Stage 3: AI_CLASSIFY (Document Type Detection)

The extracted text is passed to `AI_CLASSIFY` to confirm or correct the stated document type. This catches mislabeled uploads and routes documents to the correct extraction template. Classification categories:
- Passport
- DriversLicense
- NationalID
- FinancialStatement
- UtilityBill
- CorporateRegistry
- BeneficialOwnership

### Stage 4: AI_EXTRACT (Structured Field Extraction)

Based on the classified document type, `AI_EXTRACT` pulls structured fields:
- **Identity documents**: full_name, date_of_birth, document_number, issuing_authority, expiry_date
- **Address documents**: full_name, address, issue_date
- **Financial documents**: entity_name, reporting_period, total_assets, total_liabilities
- **Corporate documents**: company_name, registration_number, directors, beneficial_owners

### Stage 5: Identity Verification (Cross-Reference)

The `VERIFY_IDENTITY` procedure compares extracted fields against the client master record in `CLIENTS`. It produces a field-by-field match analysis with confidence scores, flagging:
- Name mismatches (accounting for transliteration, abbreviations)
- Date of birth discrepancies
- Nationality/country inconsistencies
- Expired documents

## Data Model

```
┌──────────────┐       ┌──────────────┐       ┌────────────────────┐
│   CLIENTS    │───1:N─│  KYC_CASES   │───1:N─│ DOCUMENTS_METADATA │
│              │       │              │       │                    │
│ client_id PK │       │ case_id PK   │       │ doc_id PK          │
│ entity_type  │       │ client_id FK │       │ case_id FK         │
│ risk_rating  │       │ case_type    │       │ client_id FK       │
│ status       │       │ status       │       │ doc_type           │
└──────────────┘       └──────────────┘       │ file_path          │
       │                                       │ extraction_status  │
       │                                       └────────────────────┘
       │                                               │
       │                                           1:1 │
       │                                               ▼
       │                                       ┌────────────────────┐
       │                                       │VERIFICATION_RESULTS│
       │                                       │                    │
       │                                       │ result_id PK       │
       │                                       │ doc_id FK          │
       │                                       │ extracted_fields   │
       │                                       │ confidence_score   │
       │                                       │ match_status       │
       │                                       └────────────────────┘
       │
       │         ┌──────────────┐              ┌────────────────────┐
       └────1:N──│ ALERT_QUEUE  │              │   KYC_POLICIES     │
                 │              │              │                    │
                 │ alert_id PK  │              │ policy_id PK       │
                 │ client_id FK │              │ jurisdiction       │
                 │ alert_type   │              │ category           │
                 │ severity     │              │ content (TEXT)     │
                 └──────────────┘              └────────────────────┘
```

### Key Relationships
- One **Client** has many **KYC Cases** (periodic reviews, trigger events)
- One **KYC Case** has many **Documents** submitted for verification
- Each **Document** produces one **Verification Result** after AI processing
- One **Client** may have many **Alerts** in the queue
- **KYC Policies** are standalone reference data, searched via Cortex Search

## Agent Orchestration

The `KYC_AGENT` (powered by Claude Sonnet) serves as the compliance analyst's AI assistant:

### Tools Available to the Agent

| Tool | Type | Purpose |
|------|------|---------|
| KYCPolicySearch | Cortex Search | RAG over compliance policies by jurisdiction and category |
| VerifyIdentity | Stored Procedure | Trigger identity cross-referencing for a client/document pair |
| code_execution | Python | Ad-hoc data analysis, aggregation, reporting |

### Typical Agent Workflows

1. **Policy Inquiry**: Analyst asks "What EDD requirements apply to UK PEP clients?" → Agent searches KYC_POLICY_SEARCH filtered by jurisdiction=UK, category=EDD/PEP → Returns relevant policy excerpts with citations.

2. **Document Verification**: Analyst asks "Verify client ABC-123's latest passport" → Agent calls VerifyIdentity → Returns field-by-field match analysis with confidence scores.

3. **Portfolio Analysis**: Analyst asks "How many high-risk clients have overdue periodic reviews?" → Agent uses code_execution to query KYC_CASES joined with CLIENTS → Returns count and breakdown.

4. **Risk Assessment**: Analyst asks "Show me all alerts for clients with upcoming document expirations" → Agent uses code_execution to join ALERT_QUEUE with DOCUMENTS_METADATA → Returns prioritized list.

## Infrastructure

| Component | Value |
|-----------|-------|
| Database | BNK |
| Schema | BNK.KYC_AML |
| Warehouse | BNK_WH |
| Stage | @BNK.KYC_AML.KYC_DOCUMENTS |
| Search Service | BNK.KYC_AML.KYC_POLICY_SEARCH |
| Agent | BNK.KYC_AML.KYC_AGENT |

## Compliance Jurisdictions Covered

- **US**: BSA/AML, FinCEN CDD Rule, OFAC sanctions
- **UK**: MLR 2017, FCA guidance, HM Treasury sanctions
- **EU**: AMLD6, EBA guidelines, EU sanctions lists
- **APAC**: FATF recommendations, jurisdiction-specific (JFSA, MAS, HKMA)
- **Global**: FATF 40 Recommendations, Wolfsberg Principles
