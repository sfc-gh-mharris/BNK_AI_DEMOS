# SBA Borrower and Program Integrity Module (`BNK.SBA_VETTING`)

This module adapts the Cortex Document AI, Semantic View, Cortex Search, and Cortex Agent architecture to the U.S. Small Business Administration (SBA) **National Small Business Profile Service (`NSBPS` / `SBAID`)** pre-award borrower vetting and improper-payment defense workflow.

## Statutory Controls Demonstrated

1. **100% Direct and Indirect U.S. Citizen Ownership (`SOP 50 10 8.1` and `Policy Notice 5000-876441`)**: Traces multi-tier LLC and holding partnership structures to verify zero foreign or non-resident ownership (effective March 1, 2026).
2. **Age and Deceased/Synthetic Identity Guardrails (`SBA News Release 25-42` and Treasury `Do Not Pay`)**: Enforces mandatory principal DOB checks that auto-block applicants under age 18 or over age 115 and cross-check SSA Death Master File records.
3. **Pre-Closing IRS Form 4506-C Tax Transcript Reconciliation (`SOP 50 10 8.1`)**: Compares Line 1a Gross Receipts and W-2 Payroll on official IRS `1120-S` transcripts against stated application revenue.
4. **Cross-Program Hold Codes and Loan Packager Rings (`SBA OIG Report 26-01`)**: Screens `SBAID` profiles against `CAIVRS`, `SAM.gov` debarments, unresolved COVID EIDL/PPP hold codes (`HOLD-EIDL-09`), and watchlisted Form 159 loan packagers (`PKG-4412`).
5. **`8(a)` Unconditional Control and Pass-Through Front Audits (`13 CFR 124.106` and `13 CFR 125.6`)**: Catches portal document mislabeling and identifies Operating Agreement clauses that strip day-to-day control or subcontract >50% of set-aside billings to a non-disadvantaged investor's affiliate.

## Prerequisites

- A Snowflake account in a region where Cortex Agents, `AI_PARSE_DOCUMENT`, `AI_EXTRACT`, `AI_CLASSIFY`, and Cortex Search are available (or with cross-region inference enabled).
- `ACCOUNTADMIN`, or a role that can create a database, warehouse, stage, semantic view, Cortex Search service, and agent. `00_setup.sql` and `99_teardown.sql` run `USE ROLE ACCOUNTADMIN`; edit that line if you deploy with a different role.
- The scripts create `BNK` (database) and `BNK_WH` (MEDIUM warehouse) if they do not exist. If your account already has objects with those names, they are reused as-is.
- Run `PUT` from the repository root so the relative `file://` path resolves (SnowSQL or `snow sql`). In Cortex Code Desktop, use the `/deploy-sba-vetting` skill, which handles the upload.
- To regenerate the sample PDFs: `uv run --with fpdf2 python3 sba_vetting/sample_documents/generate_sba_pdfs.py --output sba_vetting/sample_documents/pdfs --extra-count 15`.

Notes:
- Synthetic table volumes (50K businesses, 75K owners, 100K applications, 200K documents, 25K alerts) are generated in `02_data.sql`. The five showcase records are fixed; the bulk rows are randomized on each deploy.
- Document AI latency varies from about 15 seconds to over 3 minutes per document. The agent's `ProcessAndVerifySBAApplication` tool times out at 180 seconds; if a live run times out, ask the agent to retry.

## Deployment Order

```sql
-- 1. Schema, warehouse, and directory-enabled stage
-- Execute sba_vetting/00_setup.sql
-- Execute sba_vetting/01_ddl.sql

-- 2. Upload the 20 pre-generated PDFs to the stage
PUT 'file://sba_vetting/sample_documents/pdfs/applications/*.pdf' @BNK.SBA_VETTING.SBA_DOCUMENTS/applications/ AUTO_COMPRESS=FALSE OVERWRITE=TRUE;
ALTER STAGE BNK.SBA_VETTING.SBA_DOCUMENTS REFRESH;

-- 3. Populate data, search, semantic view, procedures, and agent
-- Execute sba_vetting/02_data.sql
-- Execute sba_vetting/03_search_services.sql
-- Execute sba_vetting/03b_semantic_view.sql
-- Execute sba_vetting/04_document_pipeline.sql
-- Execute sba_vetting/05_agent.sql
```

## Five Live Showcase Scenarios

Open **Snowflake Intelligence (CoWork)** and select **SBA Borrower & Program Integrity Assistant** (`BNK.SBA_VETTING.SBA_VETTING_AGENT`):

| SBAID | Business | Program | Staged PDF (`doc_id`) | Expected Statutory Outcome |
| --- | --- | --- | --- | --- |
| `SBAID-DEMO-001` | Apex Precision Machining LLC (OH) | `MadeInAmerica_7a` ($1.85M) | `sba-doc-0001-4506c-apex` (`IRSTaxTranscript_4506C`) | **`Eligible`**: $4.82M IRS receipts match stated $4.82M (0% variance), 100% U.S. citizen direct owners, 42 employees under 500 NAICS `332710` cap |
| `SBAID-DEMO-002` | Harborview Logistics Group LLC (TX) | `504_CDC` ($3.20M) | `sba-doc-0002-opag-harbor` (`OperatingAgreement`) | **`Ineligible_Ownership`**: Tier-2 holding company `Harborview Holdings LP` reveals 10% indirect foreign non-resident ownership despite 100% citizen attestation (`SOP-CIT-001`) |
| `SBAID-DEMO-003` | Sunbelt Staffing Solutions Inc (FL) | `7a_Standard` ($950K) | `sba-doc-0003-4506c-sunbelt` (`IRSTaxTranscript_4506C`) | **`HoldAndReferOIG`**: IRS transcript shows $410K gross receipts vs $3.40M claimed (+729.3% inflation), plus active `HOLD-EIDL-09` and OIG-watchlisted packager `PKG-4412` |
| `SBAID-DEMO-004` | Metro Property Restoration LLC (GA) | `Disaster_EIDL` ($500K) | `sba-doc-0004-1919-metro` (`Form1919`) | **`AutoBlocked_AgeOrDeath`**: Sole guarantor DOB `1908-04-12` (age 118) trips `<18` / `>115` guardrail alongside a `DoNotPay_DeathMaster` hit |
| `SBAID-DEMO-005` | Potomac Cyber Defense LLC (VA) | `8a_Certification` | `sba-doc-0005-opag-potomac` (declared `IRSTaxTranscript_4506C`) | **`ControlDeficiency_8a`**: `AI_CLASSIFY` catches mislabeled `OperatingAgreement` exposing 85% subcontract pass-through and non-disadvantaged bank signatory control |

## Reset Showcase Documents to `Pending`

Run this block before a live presentation to reset all five showcase PDFs to `Pending`:

```sql
DELETE FROM BNK.SBA_VETTING.SBA_VERIFICATION_RESULTS
WHERE doc_id IN (
    'sba-doc-0001-4506c-apex',
    'sba-doc-0002-opag-harbor',
    'sba-doc-0003-4506c-sunbelt',
    'sba-doc-0004-1919-metro',
    'sba-doc-0005-opag-potomac'
);

UPDATE BNK.SBA_VETTING.SBA_DOCUMENTS_METADATA
SET extraction_status = 'Pending', extraction_confidence = NULL
WHERE doc_id IN (
    'sba-doc-0001-4506c-apex',
    'sba-doc-0002-opag-harbor',
    'sba-doc-0003-4506c-sunbelt',
    'sba-doc-0004-1919-metro',
    'sba-doc-0005-opag-potomac'
);
```
