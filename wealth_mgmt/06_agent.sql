-- =============================================================================
-- WEALTH MANAGEMENT — CORTEX AGENT
-- Schema: BNK.WEALTH_MGMT
--
-- The most complex agent. Creates with profile for CoWork visibility.
-- Uses: Cortex Analyst, Cortex Search (Research + Compliance + Notes),
--       Code Execution, Data to Chart
-- =============================================================================

USE DATABASE BNK;
USE SCHEMA WEALTH_MGMT;
USE WAREHOUSE BNK_WH;

CREATE AGENT IF NOT EXISTS BNK.WEALTH_MGMT.WEALTH_MGMT_AGENT
  COMMENT = 'Enterprise AI platform agent for wealth management advisors. Most comprehensive agent — orchestrates portfolio analytics, research retrieval, compliance lookup, client history, code execution, and data visualization.'
  PROFILE = '{"display_name": "Wealth Management Advisor", "avatar": "bank-icon.png", "color": "blue"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  orchestration:
    budget:
      seconds: 90
      tokens: 48000

  instructions:
    response: "You are an AI platform assistant for financial advisors at a wealth management firm. Provide investment-grade analysis with precise numbers. Consider client suitability and compliance. Cite specific research reports or compliance documents when relevant."
    orchestration: "For portfolio analytics, AUM, holdings, trades, or concentration risk, use PortfolioAnalyst. For investment research or sector outlooks, use ResearchSearch. For compliance or regulatory questions, use ComplianceSearch. For past client conversations, use ClientNotesSearch. When evaluating trade suitability, ALWAYS check both portfolio data AND compliance requirements. Use code_execution for complex calculations."
    sample_questions:
      - question: "What is my client's portfolio concentration risk in technology?"
      - question: "What does our latest research say about healthcare?"
      - question: "Is a concentrated AAPL position suitable for a conservative client?"
      - question: "Show me UHNWI clients with portfolios underperforming their benchmark"

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "PortfolioAnalyst"
        description: "Queries structured wealth management data including client profiles, portfolios, holdings, and trades."
    - tool_spec:
        type: "cortex_search"
        name: "ResearchSearch"
        description: "Searches internal equity research reports."
    - tool_spec:
        type: "cortex_search"
        name: "ComplianceSearch"
        description: "Searches compliance and regulatory documents."
    - tool_spec:
        type: "cortex_search"
        name: "ClientNotesSearch"
        description: "Searches advisor notes about client interactions."
    - tool_spec:
        type: "data_to_chart"
        name: "data_to_chart"
        description: "Generates visualizations from data."
    - tool_spec:
        type: "code_execution"
        name: "code_execution"
        description: "Python for complex portfolio analytics."

  tool_resources:
    PortfolioAnalyst:
      semantic_view: "BNK.WEALTH_MGMT.SV_WEALTH_PORTFOLIO"
      execution_environment:
        type: "warehouse"
        warehouse: "BNK_WH"
    ResearchSearch:
      name: "BNK.WEALTH_MGMT.RESEARCH_SEARCH"
      max_results: "5"
      columns_and_descriptions:
        CONTENT:
          description: "Full equity research report text."
          type: "string"
          searchable: true
          filterable: false
        SECTOR:
          description: "Sector: Technology, Healthcare, Financials, Energy, ConsumerDiscretionary, Industrials, Utilities."
          type: "string"
          searchable: false
          filterable: true
        ANALYST_NAME:
          description: "Research analyst who authored the report."
          type: "string"
          searchable: false
          filterable: true
        RATING:
          description: "Rating: StrongBuy, Buy, Hold, Sell, StrongSell."
          type: "string"
          searchable: false
          filterable: true
    ComplianceSearch:
      name: "BNK.WEALTH_MGMT.COMPLIANCE_SEARCH"
      max_results: "5"
      columns_and_descriptions:
        CONTENT:
          description: "Full compliance document text."
          type: "string"
          searchable: true
          filterable: false
        CATEGORY:
          description: "Category: Suitability, RegBI, FormADV, ClientAgreement, ProxyVoting, BestExecution, AntiMoneyLaundering."
          type: "string"
          searchable: false
          filterable: true
        TITLE:
          description: "Title of the compliance document."
          type: "string"
          searchable: false
          filterable: true
    ClientNotesSearch:
      name: "BNK.WEALTH_MGMT.CLIENT_NOTES_SEARCH"
      max_results: "10"
      columns_and_descriptions:
        NOTE_TEXT:
          description: "Advisor note about client interaction."
          type: "string"
          searchable: true
          filterable: false
        CLIENT_ID:
          description: "Client UUID for filtering."
          type: "string"
          searchable: false
          filterable: true
        ADVISOR_ID:
          description: "Advisor UUID for filtering."
          type: "string"
          searchable: false
          filterable: true
        NOTE_TYPE:
          description: "Interaction type: Meeting, Call, Email, Review, Rebalance."
          type: "string"
          searchable: false
          filterable: true
  $$;
