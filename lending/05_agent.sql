-- =============================================================================
-- LENDING ANALYTICS — CORTEX AGENT
-- Schema: BNK.LENDING
--
-- Creates the Lending Agent with profile for CoWork visibility.
-- Uses: Cortex Analyst, Cortex Search (Policies + Interactions), Data to Chart, Code Execution
-- =============================================================================

USE DATABASE BNK;
USE SCHEMA LENDING;
USE WAREHOUSE BNK_WH;

CREATE AGENT IF NOT EXISTS BNK.LENDING.LENDING_AGENT
  COMMENT = 'Agentic AI for virtual bankers. Orchestrates portfolio analytics, policy retrieval, and interaction history for actionable customer insights.'
  PROFILE = '{"display_name": "Lending Analytics Assistant", "avatar": "bank-icon.png", "color": "green"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  orchestration:
    budget:
      seconds: 60
      tokens: 32000

  instructions:
    response: "You are a lending analytics assistant for virtual bankers at a major mortgage lender. Provide data-driven answers with actionable recommendations. When identifying at-risk customers, explain the specific signals and suggest concrete next steps. Format numbers clearly (currency, percentages, basis points)."
    orchestration: "For quantitative questions about mortgage portfolios, borrower profiles, payment patterns, delinquency rates, or risk scores, use LendingAnalyst. For questions about lending policies, underwriting criteria, servicing procedures, or forbearance rules, use LendingPolicySearch. For questions about past borrower interactions or communication history, use InteractionSearch. When asked for recommendations or at-risk customers, combine Analyst data with Search context for a complete picture."
    sample_questions:
      - question: "Which of my customers are at risk of refinancing elsewhere?"
      - question: "What is the delinquency trend for 30-year fixed mortgages?"
      - question: "What are our forbearance options for customers with hardship?"
      - question: "Show me borrowers with high refinance probability and declining credit scores"

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "LendingAnalyst"
        description: "Queries structured mortgage portfolio, borrower, payment, and risk data."
    - tool_spec:
        type: "cortex_search"
        name: "LendingPolicySearch"
        description: "Searches mortgage lending policy documents."
    - tool_spec:
        type: "cortex_search"
        name: "InteractionSearch"
        description: "Searches borrower interaction history and conversation summaries."
    - tool_spec:
        type: "data_to_chart"
        name: "data_to_chart"
        description: "Generates visualizations from query results."
    - tool_spec:
        type: "code_execution"
        name: "code_execution"
        description: "Python for complex analysis or calculations."

  tool_resources:
    LendingAnalyst:
      semantic_view: "BNK.LENDING.SV_LENDING_ANALYTICS"
      execution_environment:
        type: "warehouse"
        warehouse: "BNK_WH"
    LendingPolicySearch:
      name: "BNK.LENDING.LENDING_POLICY_SEARCH"
      max_results: "5"
      columns_and_descriptions:
        CONTENT:
          description: "Full text of the lending policy document."
          type: "string"
          searchable: true
          filterable: false
        CATEGORY:
          description: "Policy category: Underwriting, Servicing, Collections, Compliance, Pricing, Modification."
          type: "string"
          searchable: false
          filterable: true
        TITLE:
          description: "Policy title."
          type: "string"
          searchable: false
          filterable: true
    InteractionSearch:
      name: "BNK.LENDING.INTERACTION_SEARCH"
      max_results: "10"
      columns_and_descriptions:
        SUMMARY:
          description: "Agent-written summary of borrower interaction."
          type: "string"
          searchable: true
          filterable: false
        BORROWER_ID:
          description: "UUID of the borrower."
          type: "string"
          searchable: false
          filterable: true
        CHANNEL:
          description: "Communication channel: Phone, Email, Branch, Portal, Chat."
          type: "string"
          searchable: false
          filterable: true
        TOPIC:
          description: "Interaction topic: PaymentInquiry, RateQuestion, HardshipRequest, RefinanceInquiry, EscrowQuestion, PayoffRequest."
          type: "string"
          searchable: false
          filterable: true
  $$;
