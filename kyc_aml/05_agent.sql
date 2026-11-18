-- =============================================================================
-- KYC/AML — CORTEX AGENT
-- Schema: BNK.KYC_AML
--
-- Creates the KYC Agent with profile for CoWork visibility.
-- Uses:
--   - KYCAnalyst (Cortex Analyst over SV_KYC_AML Semantic View)
--   - KYCPolicySearch (Cortex Search over KYC_POLICIES with citations)
--   - ProcessAndVerifyDocument (Stored procedure: AI_PARSE_DOCUMENT + AI_CLASSIFY + AI_EXTRACT + VERIFY_IDENTITY)
--   - VerifyIdentity (Stored procedure: identity cross-reference on extracted docs)
--   - data_to_chart (Visualizations)
-- =============================================================================

USE DATABASE BNK;
USE SCHEMA KYC_AML;
USE WAREHOUSE BNK_WH;

CREATE OR REPLACE AGENT BNK.KYC_AML.KYC_AGENT
  COMMENT = 'AI agent for KYC/AML compliance analysts. Orchestrates structured case/alert analytics, compliance policy RAG, and live AI document extraction and identity verification.'
  PROFILE = '{"display_name": "KYC/AML Compliance Assistant", "avatar": "ShieldBoltAgentIcon", "color": "red"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  orchestration:
    budget:
      seconds: 300
      tokens: 64000

  instructions:
    response: "You are a KYC/AML compliance assistant for a global financial institution. Lead with the compliance finding or risk posture, support with exact figures from structured KYC tables and extracted document fields, and cite applicable policies by policy_id and title (for example POL-PEP-002). Flag overdue SLAs, identity mismatches, mislabeled uploads, and critical alerts clearly."
    orchestration: "Tool routing rules:\n1. Use KYCAnalyst for all structured questions about clients, risk ratings, KYC cases, overdue reviews, SLA due dates, uploaded documents, verification match statistics, and AML alerts.\n2. Use KYCPolicySearch for regulatory rules, CDD/EDD procedures, PEP requirements, beneficial ownership thresholds, ongoing monitoring SLAs, and sanctions obligations. Filter by jurisdiction (US, UK, EU, APAC, Global) or category when relevant.\n3. When asked to process, extract, or verify a client's pending or uploaded document (such as Oliver Clarke / CL-DEMO-001, Jen Muller / CL-DEMO-002, Marcus Sterling / CL-DEMO-003, Nexus Technology Solutions GmbH / CL-DEMO-004, or James Williams / CL-DEMO-005), first use KYCAnalyst if needed to look up client_id and doc_id in DOCUMENTS_METADATA, then call ProcessAndVerifyDocument (if Pending or re-processing) or VerifyIdentity (if already Completed), and pair the result with KYCPolicySearch to state the required compliance action."
    sample_questions:
      - question: "How many high-risk and PEP clients currently have overdue periodic reviews, broken down by priority?"
      - question: "Review client Oliver Clarke (CL-DEMO-001): process and verify his pending passport and tell me what UK PEP due diligence steps apply."
      - question: "Investigate applicant Marcus Sterling (CL-DEMO-003): process and verify his uploaded passport, check open alerts, and state the required escalation action."
      - question: "Process the pending upload for corporate client Nexus Technology Solutions GmbH (CL-DEMO-004) and check whether it satisfies Corporate CDD requirements."

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "KYCAnalyst"
        description: "Queries structured KYC/AML data across CLIENTS (100K rows), KYC_CASES (200K rows), DOCUMENTS_METADATA (500K rows), VERIFICATION_RESULTS, and ALERT_QUEUE (50K rows). Use for counts, breakdowns, client/case/document ID lookups, overdue SLA analysis, and alert queue metrics."
    - tool_spec:
        type: "cortex_search"
        name: "KYCPolicySearch"
        description: "Searches 25 full-text KYC/AML compliance policies covering CDD, EDD, PEP, Sanctions, BeneficialOwnership, and OngoingMonitoring across US, UK, EU, APAC, and Global jurisdictions."
    - tool_spec:
        type: "generic"
        name: "ProcessAndVerifyDocument"
        description: "Executes the live AI document pipeline (AI_PARSE_DOCUMENT -> AI_CLASSIFY -> AI_EXTRACT with field confidence scores -> VERIFY_IDENTITY) for a client's staged PDF document and updates VERIFICATION_RESULTS and DOCUMENTS_METADATA."
        input_schema:
          type: "object"
          properties:
            p_client_id:
              type: "string"
              description: "Client ID from CLIENTS (for example CL-DEMO-001)."
            p_doc_id:
              type: "string"
              description: "Document ID (doc_id) or relative stage file_path from DOCUMENTS_METADATA."
          required:
            - "p_client_id"
            - "p_doc_id"
    - tool_spec:
        type: "generic"
        name: "VerifyIdentity"
        description: "Cross-references already-extracted document fields in VERIFICATION_RESULTS against CLIENTS master data (Jaro-Winkler name similarity, DOB, ISO nationality, document expiry, and declared vs AI-classified doc_type)."
        input_schema:
          type: "object"
          properties:
            p_client_id:
              type: "string"
              description: "Client ID from CLIENTS."
            p_doc_id:
              type: "string"
              description: "Document ID from DOCUMENTS_METADATA."
          required:
            - "p_client_id"
            - "p_doc_id"
    - tool_spec:
        type: "data_to_chart"
        name: "data_to_chart"
        description: "Generates charts and visualizations from structured query results."

  tool_resources:
    KYCAnalyst:
      semantic_view: "BNK.KYC_AML.SV_KYC_AML"
      execution_environment:
        type: "warehouse"
        warehouse: "BNK_WH"
        query_timeout: 60
    KYCPolicySearch:
      name: "BNK.KYC_AML.KYC_POLICY_SEARCH"
      id_column: "POLICY_ID"
      title_column: "TITLE"
      max_results: 5
      columns_and_descriptions:
        CONTENT:
          description: "Full text of KYC/AML compliance policy."
          type: "string"
          searchable: true
          filterable: false
        JURISDICTION:
          description: "Jurisdiction: US, UK, EU, APAC, Global."
          type: "string"
          searchable: false
          filterable: true
        CATEGORY:
          description: "Policy domain: CDD, EDD, PEP, Sanctions, BeneficialOwnership, OngoingMonitoring."
          type: "string"
          searchable: false
          filterable: true
        TITLE:
          description: "Policy title."
          type: "string"
          searchable: false
          filterable: true
    ProcessAndVerifyDocument:
      type: "procedure"
      identifier: "BNK.KYC_AML.PROCESS_AND_VERIFY_DOCUMENT"
      name: "PROCESS_AND_VERIFY_DOCUMENT(VARCHAR, VARCHAR)"
      execution_environment:
        type: "warehouse"
        warehouse: "BNK_WH"
        query_timeout: 180
    VerifyIdentity:
      type: "procedure"
      identifier: "BNK.KYC_AML.VERIFY_IDENTITY"
      name: "VERIFY_IDENTITY(VARCHAR, VARCHAR)"
      execution_environment:
        type: "warehouse"
        warehouse: "BNK_WH"
        query_timeout: 60
  $$;
