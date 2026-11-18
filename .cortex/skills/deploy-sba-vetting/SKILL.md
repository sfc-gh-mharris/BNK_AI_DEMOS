---
name: deploy-sba-vetting
description: "Deploy the U.S. Small Business Administration (SBA) Borrower & Program Integrity (NSBPS / SBAID) AI demo module to Snowflake. Creates unified SBAID profiles, beneficial ownership and federal exclusion tables, IRS Form 4506-C / Form 1919 / Operating Agreement Document AI procedures, SBA SOP Cortex Search, Semantic View SV_SBA_VETTING, and Cortex Agent SBA_VETTING_AGENT. Triggers: deploy sba, deploy sba vetting, sba kyc demo, nsbps demo, sba loan vetting agent."
---

# Deploy SBA Borrower and Program Integrity (`sba_vetting`)

Deploys the U.S. Small Business Administration (SBA) Borrower & Program Integrity (`NSBPS` / `SBAID`) module from `sba_vetting/`:
- Schema `BNK.SBA_VETTING` and directory-enabled stage `@BNK.SBA_VETTING.SBA_DOCUMENTS`
- Tables: `SBA_BUSINESSES`, `BENEFICIAL_OWNERS`, `SBA_APPLICATIONS`, `SBA_DOCUMENTS_METADATA`, `SBA_VERIFICATION_RESULTS`, `FEDERAL_EXCLUSION_ALERTS`, `SBA_SOP_POLICIES`
- Cortex Search Service: `SBA_SOP_SEARCH`
- Semantic View: `SV_SBA_VETTING`
- Document AI & Statutory Vetting Procedures: `PROCESS_SBA_DOCUMENT`, `VERIFY_SBA_ELIGIBILITY`, `PROCESS_AND_VERIFY_SBA_APPLICATION`, `BATCH_PROCESS_SBA_DOCUMENTS`
- Cortex Agent: `SBA_VETTING_AGENT`

## Prerequisites

- `ACCOUNTADMIN` or role with `CREATE DATABASE`, `CREATE WAREHOUSE`, `CREATE STAGE`, and Cortex AI privileges
- Pre-generated sample PDFs in `sba_vetting/sample_documents/pdfs/applications/` (or generate with `uv run --with fpdf2 python3 sba_vetting/sample_documents/generate_sba_pdfs.py --output sba_vetting/sample_documents/pdfs --extra-count 15`)

## Deployment Steps

1. Confirm target database (default `BNK`), warehouse (default `BNK_WH`), and schema (default `SBA_VETTING`) with `ask_user_question`.
2. Execute `sba_vetting/00_setup.sql` and `sba_vetting/01_ddl.sql`.
3. Upload the 20 sample PDFs to `@BNK.SBA_VETTING.SBA_DOCUMENTS/applications/` (`AUTO_COMPRESS=FALSE OVERWRITE=TRUE`) and run `ALTER STAGE BNK.SBA_VETTING.SBA_DOCUMENTS REFRESH;`.
4. Execute `sba_vetting/02_data.sql`, `sba_vetting/03_search_services.sql`, `sba_vetting/03b_semantic_view.sql`, `sba_vetting/04_document_pipeline.sql`, and `sba_vetting/05_agent.sql`.
5. Validate `SV_SBA_VETTING`, `SBA_SOP_SEARCH`, and `SBA_VETTING_AGENT` via `SNOWFLAKE.CORTEX.DATA_AGENT_RUN`, then ensure showcase documents `sba-doc-0001-4506c-apex` through `sba-doc-0005-opag-potomac` are set to `Pending` for live presentation runs.
