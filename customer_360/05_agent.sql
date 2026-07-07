-- =============================================================================
-- CUSTOMER 360 — CORTEX AGENT
-- Schema: BNK.CUSTOMER_360
--
-- Creates the Customer 360 Agent with profile for CoWork visibility.
-- Uses: Cortex Analyst, Cortex Search (Notes + Policies), Data to Chart
-- =============================================================================

USE DATABASE BNK;
USE SCHEMA CUSTOMER_360;
USE WAREHOUSE BNK_WH;

CREATE AGENT IF NOT EXISTS BNK.CUSTOMER_360.CUSTOMER_360_AGENT
  COMMENT = 'Customer 360 AI assistant for retail banking staff. Orchestrates structured analytics, interaction history retrieval, and policy lookup.'
  PROFILE = '{"display_name": "Customer 360 Assistant", "avatar": "bank-icon.png", "color": "purple"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  orchestration:
    budget:
      seconds: 60
      tokens: 32000

  instructions:
    response: "You are a Customer 360 AI assistant for a large retail bank. Provide concise, data-driven answers with clear formatting. Cite the data source in your response."
    orchestration: "For quantitative questions about customers, accounts, balances, transactions, or offer performance, use CustomerAnalyst. For questions about past customer interactions or advisor notes, use CustomerNotesSearch. For questions about bank policies, fee structures, or compliance guidelines, use PolicySearch."
    sample_questions:
      - question: "Which customer segments have the highest average lifetime value?"
      - question: "What did we last discuss with customer John Smith?"
      - question: "What is our policy on overdraft fee waivers?"
      - question: "Show me the top 10 customers by transaction volume this quarter"

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "CustomerAnalyst"
        description: "Queries structured customer, account, and transaction data using natural language."
    - tool_spec:
        type: "cortex_search"
        name: "CustomerNotesSearch"
        description: "Searches unstructured customer interaction notes and advisor summaries."
    - tool_spec:
        type: "cortex_search"
        name: "PolicySearch"
        description: "Searches bank policy documents covering fees, disputes, privacy, compliance, products, and operations."
    - tool_spec:
        type: "data_to_chart"
        name: "data_to_chart"
        description: "Generates visualizations from query results."

  tool_resources:
    CustomerAnalyst:
      semantic_view: "BNK.CUSTOMER_360.SV_CUSTOMER_360"
      execution_environment:
        type: "warehouse"
        warehouse: "BNK_WH"
    CustomerNotesSearch:
      name: "BNK.CUSTOMER_360.CUSTOMER_NOTES_SEARCH"
      max_results: "10"
      columns_and_descriptions:
        NOTE_TEXT:
          description: "Full text of the customer interaction note."
          type: "string"
          searchable: true
          filterable: false
        CUSTOMER_ID:
          description: "UUID of the customer this note belongs to."
          type: "string"
          searchable: false
          filterable: true
        AGENT_NAME:
          description: "Name of the bank employee who wrote this note."
          type: "string"
          searchable: false
          filterable: true
    PolicySearch:
      name: "BNK.CUSTOMER_360.POLICY_SEARCH"
      max_results: "5"
      columns_and_descriptions:
        CONTENT:
          description: "Full text of the bank policy document."
          type: "string"
          searchable: true
          filterable: false
        CATEGORY:
          description: "Policy category: Fees, Disputes, Privacy, Compliance, Products, Operations."
          type: "string"
          searchable: false
          filterable: true
        TITLE:
          description: "Title of the policy document."
          type: "string"
          searchable: false
          filterable: true
  $$;
