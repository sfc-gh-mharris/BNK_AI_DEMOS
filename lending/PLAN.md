# Lending Analytics - Architecture Plan

## Overview

The Lending Analytics use case provides a **virtual banker assistant** that helps mortgage lending professionals make data-driven decisions about their customer portfolios. A relationship manager can ask natural language questions spanning structured portfolio data, internal lending policies, and historical customer interactions — receiving synthesized, actionable responses.

## Architecture

### Core Components

```
┌─────────────────────────────────────────────────────────┐
│                   LENDING AGENT                          │
│          (claude-4-sonnet orchestration)                 │
│                                                         │
│  "Which customers are at risk of refinancing elsewhere?"│
└──────────┬──────────────┬──────────────┬────────────────┘
           │              │              │
           ▼              ▼              ▼
┌──────────────┐ ┌───────────────┐ ┌──────────────────┐
│   Cortex     │ │ Cortex Search │ │  Cortex Search   │
│   Analyst    │ │ (Policies)    │ │ (Interactions)   │
│              │ │               │ │                  │
│ Structured   │ │ Lending rules │ │ Past customer    │
│ SQL queries  │ │ & procedures  │ │ conversations    │
└──────┬───────┘ └───────┬───────┘ └────────┬─────────┘
       │                 │                   │
       ▼                 ▼                   ▼
┌──────────────┐ ┌───────────────┐ ┌──────────────────┐
│  Semantic    │ │  LENDING_     │ │  INTERACTION_    │
│  View        │ │  POLICIES     │ │  HISTORY         │
│  (4 tables)  │ │  (300 docs)   │ │  (200K records)  │
└──────────────┘ └───────────────┘ └──────────────────┘
```

### How Cortex Analyst Handles Structured Queries

Cortex Analyst uses the **SV_LENDING_ANALYTICS** semantic view to translate natural language into SQL. The semantic view defines:

- **Entities**: BORROWERS, MORTGAGES, PAYMENTS, RISK_SCORES — each with business-friendly column descriptions
- **Measures**: Portfolio-level aggregations (total loan balance, average LTV, delinquency rates, default probabilities)
- **Dimensions**: Categorical slicing (region, state, loan type, employment status, payment status)
- **Time dimensions**: Temporal analysis on origination_date, payment_date, score_date
- **Relationships**: JOIN paths between entities (borrower → mortgages → payments, borrower → risk_scores)

Example flow:
1. Banker asks: "What is the 90-day delinquency rate for jumbo loans in California?"
2. Cortex Analyst generates SQL joining MORTGAGES (filtered on loan_type='Jumbo', state='CA') with PAYMENTS (days_past_due >= 90)
3. Returns structured result with delinquency percentage

### How Cortex Search Retrieves Context

Two search services provide unstructured context:

**LENDING_POLICY_SEARCH** — Searches ~300 internal policy documents covering:
- Underwriting criteria (credit score thresholds, DTI limits, LTV caps)
- Forbearance and modification rules
- Rate lock and pricing guidelines
- Collections escalation procedures
- Compliance requirements (TILA, RESPA, fair lending)

**INTERACTION_SEARCH** — Searches ~200K customer interaction summaries across:
- Phone calls, emails, branch visits, portal messages, chat sessions
- Topics: payment inquiries, rate questions, hardship requests, refinance inquiries
- Filterable by borrower_id, channel, and topic for targeted retrieval

### How the Agent Synthesizes Responses

The orchestration model (claude-4-sonnet) follows these patterns:

1. **Quantitative questions** → Routes to Cortex Analyst for SQL-based answers
2. **Policy questions** → Routes to Lending Policy Search for authoritative guidelines
3. **Customer history** → Routes to Interaction Search for past conversation context
4. **Complex recommendations** → Chains multiple tools:
   - Pulls risk scores and payment data via Analyst
   - Retrieves relevant policies via Policy Search
   - Checks interaction history for context
   - Synthesizes a recommendation with specific next steps

Example multi-tool flow:
- "Which customers should I proactively call about refinancing?"
  1. Analyst: Query borrowers with high refinance_probability AND current rates above market
  2. Policy Search: Retrieve current refinance eligibility criteria
  3. Interaction Search: Check if these borrowers have been contacted recently
  4. Synthesize: Prioritized call list with talking points per customer

## Data Model Relationships

```
BORROWERS (200K)
├── MORTGAGES (300K)         [borrower_id FK, 1:many]
│   └── PAYMENTS (1M)       [mortgage_id FK, 1:many]
├── RISK_SCORES (200K)      [borrower_id FK, 1:many over time]
├── REFINANCE_SIGNALS (50K) [borrower_id FK, 1:many]
└── INTERACTION_HISTORY (200K) [borrower_id FK, 1:many]

LENDING_POLICIES (300)       [standalone reference table]
```

### Key Design Decisions

- **Credit scores**: Normal distribution centered at 720, std dev ~60 (mirrors FICO population)
- **Income**: Lognormal distribution (median ~$85K, right-skewed for high earners)
- **LTV ratios**: 60-95% range, correlated with loan type (FHA allows higher LTV)
- **Interest rates**: 3.0-8.0%, inversely correlated with credit score
- **Payment behavior**: 95% on-time, 3% late, 1.5% partial, 0.5% missed
- **Default probability**: Strongly correlated with credit score (exponential decay from 650 down)

## Infrastructure

- **Database**: BNK
- **Schema**: BNK.LENDING
- **Warehouse**: BNK_WH
- **Embedding Model**: snowflake-arctic-embed-l-v2.0 (for search services)
- **Orchestration Model**: claude-4-sonnet (for agent)
