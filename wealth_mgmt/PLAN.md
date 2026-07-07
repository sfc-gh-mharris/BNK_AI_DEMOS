# Wealth Management AI Platform — Architecture Plan

## Overview

The Wealth Management AI Platform provides financial advisors with a unified AI assistant that spans portfolio analytics, investment research retrieval, compliance lookup, document processing, and complex quantitative calculations. It is the most comprehensive agent in the banking AI demo suite, combining all four Cortex AI tool types into a single orchestrated workflow.

## Architecture Components

### 1. Cortex Analyst — Portfolio Analytics (Text-to-SQL)

**Purpose:** Converts natural-language questions about client portfolios, AUM, holdings, trades, and performance into precise SQL against the wealth management data model.

**Semantic View:** `BNK.WEALTH_MGMT.SV_WEALTH_PORTFOLIO`

**Capabilities:**
- Client segmentation analysis (MassAffluent / HNWI / UHNWI / Institutional)
- Portfolio concentration risk assessment (max weight per holding, sector exposure)
- Trade activity summaries (volume, direction, reason)
- AUM aggregation by advisor, region, segment
- Unrealized gain/loss reporting
- Benchmark comparison and management fee analysis

**Data Flow:**
```
Advisor Question → Cortex Analyst → SQL Generation → Snowflake Execution → Formatted Response
```

### 2. Cortex Search — Research & Compliance Retrieval

Three independent search services provide semantic retrieval over unstructured content:

#### a. Research Search (`BNK.WEALTH_MGMT.RESEARCH_SEARCH`)
- **Source:** Internal equity research reports authored by firm analysts
- **Use Cases:** Sector outlooks, company theses, price targets, analyst ratings
- **Filterable:** sector, analyst_name, rating

#### b. Compliance Search (`BNK.WEALTH_MGMT.COMPLIANCE_SEARCH`)
- **Source:** Regulatory and compliance policy documents
- **Use Cases:** RegBI suitability requirements, best execution policies, AML procedures, proxy voting guidelines
- **Filterable:** category, title

#### c. Client Notes Search (`BNK.WEALTH_MGMT.CLIENT_NOTES_SEARCH`)
- **Source:** Advisor notes from client meetings, calls, reviews
- **Use Cases:** Relationship context, past discussions, client preferences, meeting history
- **Filterable:** client_id, advisor_id, note_type

**Data Flow:**
```
Advisor Question → Cortex Search → Vector Similarity → Top-K Documents → Grounded Response
```

### 3. AI_PARSE_DOCUMENT — Onboarding Pipeline

**Purpose:** Processes physical client onboarding documents (W-9 forms, Investment Policy Statements, Client Agreements) through OCR and AI extraction.

**Pipeline Steps:**
1. Document uploaded to `@BNK.WEALTH_MGMT.ONBOARDING_DOCS` stage
2. `AI_PARSE_DOCUMENT` extracts text with layout preservation
3. `AI_CLASSIFY` identifies document type (W9, IPS, ClientAgreement, etc.)
4. `AI_EXTRACT` pulls structured fields (client name, risk tolerance, investment objective, time horizon, net worth)
5. Extracted data returned as structured VARIANT for downstream processing

**Data Flow:**
```
PDF Upload → Stage → AI_PARSE_DOCUMENT → AI_CLASSIFY → AI_EXTRACT → Structured Output
```

### 4. Wealth Management Agent — Unified Orchestration

**Object:** `BNK.WEALTH_MGMT.WEALTH_MGMT_AGENT`

The agent is the most complex in the suite because it combines all tool types:

| Tool | Type | Purpose |
|------|------|---------|
| PortfolioAnalyst | cortex_analyst_text_to_sql | Quantitative portfolio queries |
| ResearchSearch | cortex_search | Investment research retrieval |
| ComplianceSearch | cortex_search | Regulatory/compliance lookup |
| ClientNotesSearch | cortex_search | Advisor note history |
| data_to_chart | data_to_chart | Visualization generation |
| code_execution | code_execution | Complex analytics (Sharpe, attribution) |

**Orchestration Logic:**
- Portfolio data questions → PortfolioAnalyst
- Research/sector questions → ResearchSearch
- Compliance/suitability questions → ComplianceSearch
- Client history questions → ClientNotesSearch
- Trade suitability checks → PortfolioAnalyst + ComplianceSearch (combined)
- Complex calculations → code_execution (Python)

**Model:** `claude-4-sonnet` with 90-second / 48K-token budget

## Data Model & Relationships

```
ADVISORS (500)
  │
  ├──< WM_CLIENTS (100K)
  │       │
  │       ├──< PORTFOLIOS (150K)
  │       │       │
  │       │       ├──< HOLDINGS (1M)
  │       │       │       │
  │       │       │       └──── MARKET_DATA (500K) [joined on ticker]
  │       │       │
  │       │       └──< TRADES (500K)
  │       │
  │       └──< CLIENT_NOTES (100K)
  │
  RESEARCH_REPORTS (5K) [standalone, searched]
  COMPLIANCE_DOCS (1K)  [standalone, searched]
```

**Key Relationships:**
- `ADVISORS.advisor_id` → `WM_CLIENTS.advisor_id` (1:many)
- `WM_CLIENTS.client_id` → `PORTFOLIOS.client_id` (1:many)
- `PORTFOLIOS.portfolio_id` → `HOLDINGS.portfolio_id` (1:many)
- `PORTFOLIOS.portfolio_id` → `TRADES.portfolio_id` (1:many)
- `WM_CLIENTS.client_id` → `CLIENT_NOTES.client_id` (1:many)
- `HOLDINGS.ticker` → `MARKET_DATA.ticker` (many:many via ticker+date)

## Segment Distribution

| Segment | % | AUM Range | Typical Portfolios |
|---------|---|-----------|-------------------|
| MassAffluent | 40% | $250K–$1M | 1–2 |
| HNWI | 35% | $1M–$10M | 2–3 |
| UHNWI | 20% | $10M+ | 3–5 |
| Institutional | 5% | $50M+ | 5–10 |

## Infrastructure

- **Database:** BNK
- **Schema:** BNK.WEALTH_MGMT
- **Warehouse:** BNK_WH
- **Stage:** @BNK.WEALTH_MGMT.ONBOARDING_DOCS (for document processing)
- **Embedding Model:** snowflake-arctic-embed-l-v2.0 (for all search services)
- **Orchestration Model:** claude-4-sonnet (for agent)
