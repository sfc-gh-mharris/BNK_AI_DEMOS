# Sample KYC Documents

This directory contains pre-generated sample documents and a generator script for the KYC/AML document processing pipeline.

## Quick Start — Use the Pre-Generated Samples

Upload the included PDFs directly to your Snowflake stage:

```sql
-- From SnowSQL or Snowsight (adjust the local path to where you cloned this repo)
PUT file:///path/to/kyc_aml/sample_documents/pdfs/clients/*.pdf
    @BNK.KYC_AML.KYC_DOCUMENTS/clients/
    AUTO_COMPRESS=FALSE;
```

Then run the processing pipeline on uploaded documents:

```sql
CALL BNK.KYC_AML.PROCESS_KYC_DOCUMENT(
    '<client_id>',
    '@BNK.KYC_AML.KYC_DOCUMENTS/clients/<client_id>/Passport_<doc_id>.pdf'
);
```

Or process all documents in batch:

```sql
CALL BNK.KYC_AML.BATCH_PROCESS_DOCUMENTS(10);
```

## Generate More Documents

If you want a larger set or want to customize the synthetic data:

```bash
pip install fpdf2
python generate_pdfs.py --output ./pdfs --count 50
```

This generates a random mix of:
- **Passports** (~50%) — with MRZ zone, personal details, issuing authority
- **Driver's Licenses** (~30%) — ID-card format with address
- **Financial Statements** (~20%) — corporate balance sheets with IFRS formatting

## What the Pipeline Does With These

Each document goes through:

1. `AI_PARSE_DOCUMENT` — OCR and layout extraction
2. `AI_CLASSIFY` — confirms document type (Passport / DriversLicense / FinancialStatement)
3. `AI_EXTRACT` — pulls structured fields (name, DOB, document number, etc.)
4. `VERIFY_IDENTITY` — fuzzy-matches extracted fields against the CLIENTS master table

Results land in `VERIFICATION_RESULTS` with a confidence score and match status.
