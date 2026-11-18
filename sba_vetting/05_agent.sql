/*=============================================================================
  SBA Borrower and Program Integrity (NSBPS / SBAID) - Cortex Agent
  Database: BNK | Schema: SBA_VETTING | Warehouse: BNK_WH

  Creates BNK.SBA_VETTING.SBA_VETTING_AGENT with CoWork profile.
  Tools:
    - SBAAnalyst (Cortex Analyst over SV_SBA_VETTING)
    - SBASOPSearch (Cortex Search over SBA_SOP_POLICIES with citations)
    - ProcessAndVerifySBAApplication (Live AI_PARSE_DOCUMENT + AI_CLASSIFY + AI_EXTRACT + VERIFY_SBA_ELIGIBILITY)
    - VerifySBAEligibility (Statutory eligibility check on extracted documents)
    - data_to_chart (Visualizations)
=============================================================================*/

USE DATABASE BNK;
USE SCHEMA SBA_VETTING;
USE WAREHOUSE BNK_WH;

CREATE OR REPLACE AGENT BNK.SBA_VETTING.SBA_VETTING_AGENT
  COMMENT = 'AI agent for U.S. Small Business Administration (SBA) loan specialists, GCBD 8(a) reviewers, and OIG investigators using the National Small Business Profile Service (NSBPS / SBAID).'
  PROFILE = '{"display_name": "SBA Borrower & Program Integrity Assistant", "avatar": "ShieldBoltAgentIcon", "color": "blue"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  orchestration:
    budget:
      seconds: 300
      tokens: 64000

  instructions:
    response: "You are an SBA Borrower Vetting and Program Integrity assistant operating over the National Small Business Profile Service (NSBPS / SBAID). Lead with the statutory eligibility determination or fraud posture, back every claim with exact figures from structured SBAID tables and AI-extracted PDF fields, and cite applicable SBA authorities by policy_id, title, and statutory citation (such as SOP-CIT-001 / Policy Notice 5000-876441, SOP-TAX-001 / IRS Form 4506-C, SOP-AGE-001 / News Release 25-42, or SOP-8A-001 / 13 CFR 124.106). Highlight indirect foreign ownership, <18 or >115 age guardrails, Death Master File hits, IRS 4506-C gross receipts inflation, prior COVID EIDL/PPP hold codes, watchlisted Form 159 loan packagers, and mislabeled uploads clearly."
    orchestration: "Tool routing rules:\n1. Use SBAAnalyst for structured queries across SBA_BUSINESSES (SBAID), BENEFICIAL_OWNERS, SBA_APPLICATIONS, SBA_DOCUMENTS_METADATA, SBA_VERIFICATION_RESULTS, and FEDERAL_EXCLUSION_ALERTS (including SLA backlogs, hold codes, loan packager volume, and document lookups).\n2. Use SBASOPSearch for SBA SOP 50 10 8.1 rules, Policy Notice 5000-876441 100% citizen ownership rules, News Release 25-42 age guardrails, IRS Form 4506-C transcript thresholds, CAIVRS/SAM.gov/Do Not Pay screening, NAICS size standards, and 13 CFR 124/125 8(a) control rules.\n3. When asked to vet, process, or verify an applicant business or showcase SBAID (SBAID-DEMO-001 Apex Precision Machining LLC, SBAID-DEMO-002 Harborview Logistics Group LLC, SBAID-DEMO-003 Sunbelt Staffing Solutions Inc, SBAID-DEMO-004 Metro Property Restoration LLC, or SBAID-DEMO-005 Potomac Cyber Defense LLC), first use SBAAnalyst to check the SBAID profile, beneficial owners, open alerts, and pending doc_id, then call ProcessAndVerifySBAApplication (if Pending or re-processing) or VerifySBAEligibility (if already Completed), and pair the result with SBASOPSearch to state the required E-Tran, GCBD, or OIG action."
    sample_questions:
      - question: "Across our active 7(a), Made in America 7(a), 504, Disaster, and 8(a) queues, how many applications are overdue or carry Critical federal exclusion alerts by program?"
      - question: "Vet Harborview Logistics Group LLC (SBAID-DEMO-002): process its uploaded Operating Agreement and determine whether its ownership structure is eligible under the March 2026 SBA citizenship rules."
      - question: "Investigate Sunbelt Staffing Solutions Inc (SBAID-DEMO-003): process its IRS Form 4506-C transcript, check prior pandemic hold codes and loan packager alerts, and state the required OIG action."
      - question: "Audit 8(a) participant Potomac Cyber Defense LLC (SBAID-DEMO-005): process its pending upload and evaluate compliance with 13 CFR 124 control and subcontracting rules."

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "SBAAnalyst"
        description: "Queries unified NSBPS / SBAID structured tables covering 50K small businesses, 75K direct and indirect beneficial owners, 100K cross-program SBA applications, 200K uploaded documents, verification results, and 25K CAIVRS/SAM.gov/Do Not Pay/OIG exclusion alerts."
    - tool_spec:
        type: "cortex_search"
        name: "SBASOPSearch"
        description: "Searches authoritative SBA SOP 50 10 8.1 rules, Policy Notice 5000-876441 citizenship rules, age guardrails, IRS Form 4506-C reconciliation standards, CAIVRS/SAM.gov/Do Not Pay exclusions, 13 CFR 121 size caps, and 13 CFR 124/125 8(a) contracting rules."
    - tool_spec:
        type: "generic"
        name: "ProcessAndVerifySBAApplication"
        description: "Runs the live Cortex Document AI pipeline (AI_PARSE_DOCUMENT -> AI_CLASSIFY -> AI_EXTRACT with field confidence scores -> VERIFY_SBA_ELIGIBILITY) on a staged SBA PDF (Form 1919, IRS 4506-C/1120-S transcript, Operating Agreement, or Owner ID) and persists statutory eligibility results."
        input_schema:
          type: "object"
          properties:
            p_sba_id:
              type: "string"
              description: "Persistent SBAID (for example SBAID-DEMO-002) or application ID (app_id)."
            p_doc_id:
              type: "string"
              description: "Document ID (doc_id) or relative stage file_path from SBA_DOCUMENTS_METADATA."
          required:
            - "p_sba_id"
            - "p_doc_id"
    - tool_spec:
        type: "generic"
        name: "VerifySBAEligibility"
        description: "Evaluates already-extracted document fields in SBA_VERIFICATION_RESULTS against SBA_BUSINESSES, BENEFICIAL_OWNERS, SBA_APPLICATIONS, and FEDERAL_EXCLUSION_ALERTS."
        input_schema:
          type: "object"
          properties:
            p_sba_id:
              type: "string"
              description: "Persistent SBAID from SBA_BUSINESSES."
            p_doc_id:
              type: "string"
              description: "Document ID from SBA_DOCUMENTS_METADATA."
          required:
            - "p_sba_id"
            - "p_doc_id"
    - tool_spec:
        type: "data_to_chart"
        name: "data_to_chart"
        description: "Generates charts and visualizations from structured SBA portfolio query results."

  tool_resources:
    SBAAnalyst:
      semantic_view: "BNK.SBA_VETTING.SV_SBA_VETTING"
      execution_environment:
        type: "warehouse"
        warehouse: "BNK_WH"
        query_timeout: 60
    SBASOPSearch:
      name: "BNK.SBA_VETTING.SBA_SOP_SEARCH"
      id_column: "POLICY_ID"
      title_column: "TITLE"
      max_results: 5
      columns_and_descriptions:
        CONTENT:
          description: "Full text of SBA SOP, Policy Notice, 13 CFR rule, or OIG directive."
          type: "string"
          searchable: true
          filterable: false
        PROGRAM_SCOPE:
          description: "Applicable SBA scope: 7a_504, AllPrograms, Disaster, 8a_Contracting."
          type: "string"
          searchable: false
          filterable: true
        CATEGORY:
          description: "Domain: CitizenshipOwnership, TaxVerification, AgeIdentityGuardrail, FederalExclusions, SizeAndNAICS, ContractingControl, PackagerOversight."
          type: "string"
          searchable: false
          filterable: true
        TITLE:
          description: "Policy title."
          type: "string"
          searchable: false
          filterable: true
        AUTHORITY_CITATION:
          description: "Statutory or SOP citation."
          type: "string"
          searchable: false
          filterable: true
    ProcessAndVerifySBAApplication:
      type: "procedure"
      identifier: "BNK.SBA_VETTING.PROCESS_AND_VERIFY_SBA_APPLICATION"
      name: "PROCESS_AND_VERIFY_SBA_APPLICATION(VARCHAR, VARCHAR)"
      execution_environment:
        type: "warehouse"
        warehouse: "BNK_WH"
        query_timeout: 180
    VerifySBAEligibility:
      type: "procedure"
      identifier: "BNK.SBA_VETTING.VERIFY_SBA_ELIGIBILITY"
      name: "VERIFY_SBA_ELIGIBILITY(VARCHAR, VARCHAR)"
      execution_environment:
        type: "warehouse"
        warehouse: "BNK_WH"
        query_timeout: 60
  $$;
