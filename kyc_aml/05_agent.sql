-- =============================================================================
-- KYC/AML — CORTEX AGENT
-- Schema: BNK.KYC_AML
--
-- Creates the KYC Agent with profile for CoWork visibility.
-- Uses: Cortex Search (Policies), Code Execution
-- Note: VerifyIdentity stored procedure exists but is called directly, not
--       as an agent tool (generic tool resource parsing is restrictive).
-- =============================================================================

USE DATABASE BNK;
USE SCHEMA KYC_AML;
USE WAREHOUSE BNK_WH;

CREATE AGENT IF NOT EXISTS BNK.KYC_AML.KYC_AGENT
  COMMENT = 'AI agent for KYC/AML compliance analysts. Orchestrates policy lookup and data analysis for CDD, EDD, PEP, and sanctions workflows.'
  PROFILE = '{"display_name": "KYC/AML Compliance Assistant", "avatar": "bank-icon.png", "color": "red"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  orchestration:
    budget:
      seconds: 60
      tokens: 32000

  instructions:
    response: "You are a KYC/AML compliance assistant for a global financial institution. Provide precise, regulation-aware answers grounded in institutional policies. Always cite the specific policy by ID and title. Flag compliance risks proactively."
    orchestration: "For questions about KYC/AML policies, regulatory requirements, CDD/EDD rules, PEP obligations, sanctions requirements, or beneficial ownership, use KYCPolicySearch. Filter by jurisdiction and category when relevant. For data analysis, case management queries, alert statistics, or trends, use code_execution to query KYC tables."
    sample_questions:
      - question: "What are the enhanced due diligence requirements for PEP clients?"
      - question: "What documents are required for corporate client onboarding?"
      - question: "What is our policy on beneficial ownership for trusts?"
      - question: "What are the sanctions screening frequency requirements?"

  tools:
    - tool_spec:
        type: "cortex_search"
        name: "KYCPolicySearch"
        description: "Searches KYC/AML compliance policies covering CDD, EDD, PEP, Sanctions, Beneficial Ownership, and Ongoing Monitoring across US, UK, EU, APAC, and Global jurisdictions."
    - tool_spec:
        type: "code_execution"
        name: "code_execution"
        description: "Executes Python for data analysis against KYC tables: CLIENTS (100K rows), KYC_CASES (200K), DOCUMENTS_METADATA (500K), VERIFICATION_RESULTS (350K), ALERT_QUEUE (50K)."

  tool_resources:
    KYCPolicySearch:
      name: "BNK.KYC_AML.KYC_POLICY_SEARCH"
      max_results: "5"
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
  $$;
