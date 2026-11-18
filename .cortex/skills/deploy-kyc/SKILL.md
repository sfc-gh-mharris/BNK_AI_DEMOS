---
name: deploy-kyc
description: "Deploy the KYC/AML banking AI demo use case to Snowflake. Creates an AI-powered document processing pipeline with AI_PARSE_DOCUMENT, Cortex Search for policies, and a Cortex Agent for KYC case management. Use when: deploying KYC, AML, know your customer, document processing demo, identity verification. Triggers: deploy kyc, deploy aml, deploy KYC AML, banking kyc agent, document processing demo."
---

# Deploy KYC/AML

Deploys the KYC/AML use case from the `bnk-ai-demos` repository. This creates:
- Database and KYC_AML schema
- Tables: CLIENTS, KYC_CASES, DOCUMENTS_METADATA, VERIFICATION_RESULTS, KYC_POLICIES, ALERT_QUEUE
- Semantic View: SV_KYC_AML (across all 5 structured KYC/AML tables)
- Document Pipeline: AI_PARSE_DOCUMENT + AI_CLASSIFY + AI_EXTRACT + VERIFY_IDENTITY
- Search Service: KYC_POLICY_SEARCH
- Agent: KYC_AGENT (combines Cortex Analyst, Cortex Search, and live document verification tools)
- Stage: @DB.SCHEMA.KYC_DOCUMENTS for PDF uploads

## Prerequisites

- Cloned repo: `https://github.com/sfc-gh-mharris/BNK_AI_DEMOS`
- ACCOUNTADMIN or role with CREATE DATABASE, CREATE WAREHOUSE, CREATE STAGE privileges
- Snowflake account with Cortex AI features enabled (AI_PARSE_DOCUMENT requires Arctic or compatible model access)

## Configuration

Before executing any SQL, collect the deployment configuration from the user using `ask_user_question`:

1. **Database** — Ask which database to deploy into. Default: `BNK`. If user specifies a different database, use it for all fully-qualified references throughout the deployment.
2. **Warehouse** — Ask which warehouse to use for compute. Default: `BNK_WH`. If user specifies an existing warehouse, skip warehouse creation (`CREATE WAREHOUSE IF NOT EXISTS`) and just use their warehouse.
3. **Schema** — Ask which schema name to use. Default: `KYC_AML`.

Store these three values as the **deployment configuration**. All subsequent SQL execution MUST apply these substitutions to every statement before running it:

| Default Value | Substitution |
|---------------|-------------|
| `BNK_WH` | → user's warehouse (in `USE WAREHOUSE`, `WAREHOUSE =` clauses, agent `execution_environment`) |
| `BNK.KYC_AML` | → `{user_db}.{user_schema}` in all fully-qualified references |
| `BNK` (standalone database references in `USE DATABASE`, `CREATE DATABASE`) | → user's database |
| `KYC_AML` (in `USE SCHEMA`, `CREATE SCHEMA`) | → user's schema |

**Critical — downstream propagation**: These substitutions MUST be applied in ALL contexts including:
- `WAREHOUSE =` clauses in `CREATE CORTEX SEARCH SERVICE` statements
- `warehouse:` value in agent `execution_environment` YAML (inside `$$` dollar-quoted spec)
- Fully-qualified object names inside the agent spec (search service `name:` fields)
- Stage references (`@BNK.KYC_AML.KYC_DOCUMENTS` → `@{user_db}.{user_schema}.KYC_DOCUMENTS`)
- Stored procedure bodies that reference fully-qualified table/stage names
- All validation and verification queries in Step 3

## Workflow

### Step 1: Locate Repository

Find the cloned repo on disk. Check common locations:
1. Current working directory
2. `~/Documents/GitHub/BNK_AI_DEMOS/`
3. Ask user if not found

Verify the `kyc_aml/` subfolder exists with files: `00_setup.sql`, `01_ddl.sql`, `02_data.sql`, `03_search_services.sql`, `03b_semantic_view.sql`, `04_document_pipeline.sql`, `05_agent.sql`.

### Step 2: Execute Deployment Scripts in Order

Execute each SQL file sequentially using `snowflake_sql_execute`. Read each file with the `read` tool, then execute each SQL statement individually (split on semicolons, skip empty statements).

**Before executing each statement**, apply the deployment configuration substitutions from the Configuration section above. Every reference to the default database, warehouse, and schema must be replaced with the user's configured values.

**Execution order:**
1. `00_setup.sql` - Creates database, schema, warehouse, and directory-enabled stage (skip warehouse creation if user specified an existing warehouse)
2. `01_ddl.sql` - Creates tables
3. `02_data.sql` - Inserts synthetic KYC case data, client records, risk alerts, and 5 showcase demo cases
4. `03_search_services.sql` - Creates KYC_POLICY_SEARCH service (substitute `WAREHOUSE =` clause and fully-qualified source table name)
5. `03b_semantic_view.sql` - Creates SV_KYC_AML semantic view over the 5 structured KYC/AML tables
6. `04_document_pipeline.sql` - Creates stored procedures for document processing and identity verification (substitute fully-qualified stage and table references inside procedure bodies)
7. `05_agent.sql` - Creates KYC_AGENT (substitute `execution_environment.warehouse`, semantic view FQN, search service FQN, and procedure FQNs in tool definitions)

**Error handling:**
- If a statement fails, report the error and the file/statement that failed
- "already exists" errors are safe to ignore (scripts use IF NOT EXISTS / CREATE OR ALTER / CREATE OR REPLACE)
- If warehouse or database doesn't exist errors occur, ensure 00_setup.sql ran first
- If "not an allowed model" error occurs, verify the agent spec uses `orchestration: auto`
- FK constraint errors: ensure 01_ddl.sql creates tables in dependency order

### Step 3: Validate Deployment

After all scripts complete, use the **user's configured database and schema** in all verification queries:

1. Verify objects exist:
   ```sql
   SHOW TABLES IN SCHEMA {user_db}.{user_schema};
   SHOW SEMANTIC VIEWS IN SCHEMA {user_db}.{user_schema};
   SHOW CORTEX SEARCH SERVICES IN SCHEMA {user_db}.{user_schema};
   SHOW PROCEDURES IN SCHEMA {user_db}.{user_schema};
   SHOW AGENTS IN SCHEMA {user_db}.{user_schema};
   ```

2. Quick agent test:
   ```sql
   SELECT TRY_PARSE_JSON(
     SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
       '{user_db}.{user_schema}.KYC_AGENT',
       $${"messages": [{"role": "user", "content": [{"type": "text", "text": "How many high-risk and PEP clients currently have overdue periodic reviews?"}]}]}$$
     )
   ) AS resp;
   ```

Present results to user.

### Step 4: Try the Document Pipeline (Interactive)

After validation succeeds, ask the user if they'd like to upload sample documents and run one through the pipeline. Use `ask_user_question`:

```
"Your KYC/AML pipeline is deployed. Would you like to upload a sample document and run it through the AI processing pipeline?"
Options:
- "Yes, upload samples and run one" - proceed with the steps below
- "No, I'm done for now" - skip to Output
```

**If the user opts in:**

1. **Generate or locate sample PDFs.** The repo includes pre-generated samples at `kyc_aml/sample_documents/pdfs/clients/`. If they don't exist, run the generator:
   ```bash
   pip install fpdf2
   python kyc_aml/sample_documents/generate_pdfs.py --output kyc_aml/sample_documents/pdfs --count 10
   ```

2. **Upload to stage and refresh directory.** Upload the sample PDFs to `@{user_db}.{user_schema}.KYC_DOCUMENTS/clients/` (via Snow CLI / Python connector) and run:
   ```sql
   ALTER STAGE {user_db}.{user_schema}.KYC_DOCUMENTS REFRESH;
   ```

3. **Run the end-to-end pipeline on showcase cases.** Call:
   ```sql
   -- Clean Match (Oliver Clarke, UK PEP passport)
   CALL {user_db}.{user_schema}.PROCESS_AND_VERIFY_DOCUMENT('CL-DEMO-001', '54866c22-96f2-4967-a248-1d6b72a2310f');

   -- Partial Match (Jen Muller vs Jennifer Mueller)
   CALL {user_db}.{user_schema}.PROCESS_AND_VERIFY_DOCUMENT('CL-DEMO-002', '99c221cb-eb27-44bd-88d7-b69929da359b');

   -- Critical Mismatch (Marcus Sterling vs Jennifer Smith passport)
   CALL {user_db}.{user_schema}.PROCESS_AND_VERIFY_DOCUMENT('CL-DEMO-003', 'f89335ea-0fd0-4e9e-8b72-fedd94795d9a');
   ```

4. **Show the user what to look for in the output.** After the procedure returns, explain:
   - `classification` → The AI's prediction of document type (Passport / DriversLicense / FinancialStatement) plus confidence. Highlight whether it correctly identified the document.
   - `extracted_fields` → Structured fields pulled from the document. For a passport: `full_name`, `date_of_birth`, `document_number`, `nationality`, `expiry_date`. Point out the accuracy of the extraction.
   - `parsed_pages` → The raw OCR text. Useful for debugging if extraction looks wrong.

5. **Optional: Run identity verification.** If the uploaded document was a passport or driver's license, offer to run verification:
   ```sql
   CALL {user_db}.{user_schema}.VERIFY_IDENTITY('<client_id>', '<doc_id>');
   ```
   Explain that this fuzzy-matches extracted name/DOB against the CLIENTS master table using Jaro-Winkler similarity. Since the sample docs are synthetic, the match will show "mismatch" (the generated names won't match the seed data) — but this demonstrates the verification flow. In a real deployment, documents uploaded for actual clients would produce match/partial-match results.

6. **Call out key observations for the user:**
   - AI_PARSE_DOCUMENT handles scanned PDFs, rotated text, and multi-column layouts
   - AI_CLASSIFY catches mislabeled uploads (e.g., a financial statement uploaded as "passport")
   - AI_EXTRACT field accuracy depends on document quality — clean text PDFs extract near-perfectly; scanned/low-res images may have partial extractions
   - The full pipeline runs in ~3-5 seconds per document on a MEDIUM warehouse
   - Batch mode (`BATCH_PROCESS_DOCUMENTS`) parallelizes across the warehouse for production scale

## Stopping Points

- Step 4 is interactive. If the user declines, stop after Step 3 results.

## Output

Fully deployed KYC/AML use case in `{user_db}.{user_schema}` schema with a working Cortex Agent, document processing pipeline, and policy search accessible in Snowflake CoWork.

## Troubleshooting

**"Tool X is missing execution_environment"** — The agent spec must include `execution_environment: {type: warehouse, warehouse: {user_warehouse}}` for Cortex Analyst tools. Verify the substitution was applied inside the dollar-quoted agent spec.

**"Column X doesn't have a text index"** — In the agent's `columns_and_descriptions`, only the ON column should be `searchable: true`. All ATTRIBUTES must be `searchable: false, filterable: true`.

**"invalid identifier" in agent spec** — If the user changed the database or schema, ensure all fully-qualified names inside the agent YAML spec were updated. The agent references search services by their full `DB.SCHEMA.OBJECT` path.

**Agent not visible in CoWork** — Ensure the CREATE AGENT statement includes a PROFILE clause with display_name.

**Document pipeline errors** — AI_PARSE_DOCUMENT requires files in the stage. The demo data creates metadata records but actual PDF processing requires uploading files to `@{user_db}.{user_schema}.KYC_DOCUMENTS`.

**Warehouse does not exist** — If the user specified a custom warehouse, verify it exists before deployment. The skill skips `CREATE WAREHOUSE` when the user provides an existing warehouse name.
