# Customer 360 — Use Case Architecture

## Overview

The Customer 360 use case demonstrates a unified agentic AI assistant for retail banking relationship managers. It combines structured analytics (Cortex Analyst via Semantic View), unstructured document retrieval (Cortex Search), and agentic orchestration (Cortex Agent) into a single conversational interface.

## Infrastructure

| Object | Value |
|--------|-------|
| Database | `BNK` |
| Schema | `BNK.CUSTOMER_360` |
| Warehouse | `BNK_WH` |
| Agent | `BNK.CUSTOMER_360.CUSTOMER_360_AGENT` |

## Data Model

```
┌─────────────┐       ┌─────────────┐       ┌──────────────────┐
│  CUSTOMERS  │──1:M──│  ACCOUNTS   │──1:M──│  TRANSACTIONS    │
│  (~500K)    │       │  (~1M)      │       │  (~1M)           │
└─────┬───────┘       └─────────────┘       └──────────────────┘
      │
      ├──1:M──┌──────────────────┐
      │       │  INTERACTIONS    │  (call center, branch, digital)
      │       │  (~200K)         │
      │       └──────────────────┘
      │
      ├──1:M──┌──────────────────┐
      │       │  CUSTOMER_NOTES  │  (advisor notes, chunked for search)
      │       │  (~200K)         │
      │       └──────────────────┘
      │
      └──1:M──┌──────────────────┐
              │  OFFERS          │  (cross-sell, upsell, retention)
              │  (~100K)         │
              └──────────────────┘

┌─────────────┐       ┌─────────────┐
│  PRODUCTS   │       │  POLICIES   │
│  (~50)      │       │  (~500)     │
└─────────────┘       └─────────────┘
```

### Key Relationships

- **CUSTOMERS → ACCOUNTS**: One customer holds multiple accounts (checking, savings, credit card, etc.)
- **ACCOUNTS → TRANSACTIONS**: Each account generates many transactions over time
- **CUSTOMERS → INTERACTIONS**: Track of every call center, branch, email, chat, and mobile interaction
- **CUSTOMERS → CUSTOMER_NOTES**: Free-text notes written by relationship managers and advisors
- **CUSTOMERS → OFFERS**: Personalized offers sent through marketing automation
- **OFFERS → PRODUCTS**: Each offer references a specific banking product

### Standalone Reference Tables

- **PRODUCTS**: Master list of banking products with fee structures and rates
- **POLICIES**: Full-text policy documents governing fees, disputes, privacy, compliance, and operations

## AI Services

### 1. Cortex Analyst (Semantic View)

**Object**: `BNK.CUSTOMER_360.SV_CUSTOMER_360`

The Semantic View joins CUSTOMERS, ACCOUNTS, and TRANSACTIONS to enable natural-language queries over structured data. It exposes:

- **Dimensions**: customer segment, region, product type, transaction channel, transaction category, account status
- **Measures**: total balance, average transaction amount, transaction count, lifetime value, tenure
- **Time dimensions**: transaction date, account opened date, customer created date

Example questions:
- "What is the average balance by customer segment?"
- "Which region has the highest transaction volume this quarter?"
- "Show me the top 10 customers by lifetime value in the Northeast"

### 2. Cortex Search — Customer Notes

**Object**: `BNK.CUSTOMER_360.CUSTOMER_NOTES_SEARCH`

Indexes the `note_text` column from CUSTOMER_NOTES for semantic retrieval. Filterable by `customer_id` and `agent_name`.

Example questions:
- "What did we last discuss with customer X?"
- "Find all notes mentioning overdraft disputes"
- "What has advisor Sarah Chen been working on?"

### 3. Cortex Search — Policies

**Object**: `BNK.CUSTOMER_360.POLICY_SEARCH`

Indexes the `content` column from POLICIES for semantic retrieval. Filterable by `category` and `title`.

Example questions:
- "What is our policy on overdraft fee waivers?"
- "What are the compliance requirements for wire transfers over $10,000?"
- "How do we handle disputed transactions?"

### 4. Data-to-Chart

Built-in visualization tool that generates charts from structured query results returned by Cortex Analyst.

## Agent Orchestration

**Object**: `BNK.CUSTOMER_360.CUSTOMER_360_AGENT`

The agent uses `claude-4-sonnet` as the orchestration model. Its routing logic:

1. **Quantitative questions** (balances, counts, averages, trends, segments) → Cortex Analyst via Semantic View
2. **Interaction history** (what was discussed, advisor notes, sentiment) → Customer Notes Search
3. **Policy/compliance questions** (fees, dispute resolution, procedures) → Policy Search
4. **Hybrid questions** → Multiple tools called and synthesized

### Budget Controls

- **Time**: 60 seconds max per turn
- **Tokens**: 32,000 token budget per turn

## Deployment Order

1. `01_ddl.sql` — Create all tables
2. `02_data.sql` — Populate with synthetic data
3. `03_semantic_view.sql` — Create the Semantic View
4. `04_search_services.sql` — Create Cortex Search Services (requires populated tables)
5. `05_agent.sql` — Create the Agent (requires Semantic View + Search Services)

## Data Distribution Design Choices

| Dimension | Distribution | Rationale |
|-----------|-------------|-----------|
| Customer segment | 80% Consumer, 15% Small Business, 5% Commercial | Matches typical US retail bank portfolio |
| Region | Northeast 22%, Southeast 24%, Midwest 20%, West 22%, Southwest 12% | Approximates US population distribution |
| Transaction amounts | Log-normal distribution via `ABS(NORMAL(50, 200, RANDOM()))` | Realistic: many small transactions, few large ones |
| Account products | Checking 35%, Savings 25%, CreditCard 20%, MoneyMarket 10%, CD 5%, Investment 5% | Typical product penetration |
| Interaction sentiment | Positive 30%, Neutral 50%, Negative 20% | Industry benchmark for service interactions |
