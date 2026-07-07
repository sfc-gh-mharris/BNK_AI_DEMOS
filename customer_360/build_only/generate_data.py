"""
Customer 360 — Data Generation Logic Documentation
===================================================

This script documents the design decisions and statistical distributions used
to generate synthetic banking data for the Customer 360 demo. It is NOT shared
with the customer — it exists solely as internal tooling documentation.

The actual data generation is performed by 02_data.sql using Snowflake's
GENERATOR function and UNIFORM/NORMAL distributions. This Python script
captures the *reasoning* behind those choices.

Author: Internal Demo Engineering
Database: BNK.CUSTOMER_360
"""

# =============================================================================
# DISTRIBUTION DESIGN CHOICES
# =============================================================================

# --- Customer Segments ---
# Rationale: Typical US retail bank portfolio composition
# Source: Federal Reserve Survey of Consumer Finances (2022)
SEGMENT_DISTRIBUTION = {
    "Consumer": 0.80,       # 80% - retail individuals (checking, savings, cards)
    "SmallBusiness": 0.15,  # 15% - small businesses (annual revenue < $5M)
    "Commercial": 0.05,     # 5% - commercial clients (annual revenue >= $5M)
}

# --- Geographic Regions ---
# Rationale: Approximates US population distribution across banking regions
# Source: US Census Bureau 2020 population estimates by region
REGION_DISTRIBUTION = {
    "Northeast": 0.22,   # NY, NJ, PA, CT, MA, etc.
    "Southeast": 0.24,   # FL, GA, NC, VA, TN, etc.
    "Midwest": 0.20,     # IL, OH, MI, IN, WI, etc.
    "West": 0.22,        # CA, WA, OR, CO, AZ, etc.
    "Southwest": 0.12,   # TX, NM, OK, AR, LA
}

# --- Account Product Mix ---
# Rationale: Based on FDIC Summary of Deposits and card issuer benchmarks
# Reflects typical product penetration rates at a diversified retail bank
PRODUCT_TYPE_DISTRIBUTION = {
    "Checking": 0.35,     # Most common - primary banking relationship
    "Savings": 0.25,      # Strong savings product adoption
    "CreditCard": 0.20,   # Card penetration ~60% of households
    "MoneyMarket": 0.10,  # Higher-balance customers
    "CD": 0.05,           # Declining but still meaningful
    "Investment": 0.05,   # Advisory/brokerage accounts
}

# --- Transaction Amount Distribution ---
# Rationale: Log-normal distribution matches real transaction data
# Most transactions are small (grocery, coffee, gas)
# Long tail of large transactions (rent, mortgage, wire transfers)
TRANSACTION_AMOUNT_PARAMETERS = {
    "small_txn_pct": 0.60,       # 60% of transactions: mean=$45, std=$80
    "medium_txn_pct": 0.25,      # 25% of transactions: mean=$150, std=$200
    "large_deposit_pct": 0.10,   # 10% of transactions: mean=$2000, std=$3000 (deposits)
    "large_purchase_pct": 0.05,  # 5% of transactions: mean=$500, std=$400
}

# Using Normal distribution in Snowflake: NORMAL(mean, stddev, RANDOM())
# For amounts, we take ABS() since NORMAL can go negative
# Negative sign applied to debits/purchases, positive for deposits

# --- Transaction Categories ---
# Rationale: Weighted by typical household spending patterns
# Source: Bureau of Labor Statistics Consumer Expenditure Survey 2023
CATEGORY_WEIGHTS = {
    "Groceries": 0.20,      # Largest single category
    "Dining": 0.12,         # Restaurants, fast food, delivery
    "Travel": 0.05,         # Airlines, hotels, rental cars
    "Entertainment": 0.05,  # Streaming, events, hobbies
    "Utilities": 0.15,      # Electric, gas, water, telecom
    "Transfer": 0.10,       # Zelle, Venmo, internal transfers
    "Deposit": 0.15,        # Direct deposits, check deposits
    "Withdrawal": 0.08,     # ATM, cash back
    "Payment": 0.10,        # Bill pay, loan payments
}

# --- Transaction Channels ---
# Rationale: Reflects digital transformation in banking (2024 benchmarks)
# Source: ABA Banking Journal Digital Adoption Survey 2024
CHANNEL_DISTRIBUTION = {
    "Online": 0.30,   # Web banking bill pay, transfers
    "Mobile": 0.30,   # Mobile app transactions
    "Branch": 0.10,   # In-person teller transactions (declining)
    "ATM": 0.20,      # Cash withdrawals, deposits
    "Wire": 0.10,     # Wire transfers (higher dollar)
}

# --- Interaction Sentiment ---
# Rationale: Industry benchmark from JD Power Banking Satisfaction Study
SENTIMENT_DISTRIBUTION = {
    "Positive": 0.30,   # Customer expressed satisfaction
    "Neutral": 0.50,    # Standard interaction, no strong emotion
    "Negative": 0.20,   # Complaint, frustration, dissatisfaction
}

# --- Interaction Topics ---
# Rationale: Based on CFPB Complaint Database category frequencies + bank CRM data
TOPIC_DISTRIBUTION = {
    "AccountInquiry": 0.30,    # Balance, statement, general questions
    "FeeDispute": 0.20,        # Overdraft, monthly fee, ATM fee disputes
    "ProductInquiry": 0.20,    # Interest in new products, rate inquiries
    "Complaint": 0.10,         # Formal complaints
    "ServiceRequest": 0.20,    # Address change, card replacement, etc.
}

# --- Offer Types ---
# Rationale: Marketing campaign mix for a mature customer base
OFFER_TYPE_DISTRIBUTION = {
    "CrossSell": 0.40,   # Majority of offers are cross-sell (new product)
    "Upsell": 0.30,      # Upgrade existing product
    "Retention": 0.20,   # Prevent attrition of at-risk customers
    "WinBack": 0.10,     # Re-engage churned/inactive customers
}

# --- Offer Funnel Conversion ---
# Rationale: Typical digital marketing funnel metrics in financial services
OFFER_STATUS_DISTRIBUTION = {
    "Sent": 0.30,       # Delivered but no engagement
    "Viewed": 0.20,     # Opened/displayed
    "Clicked": 0.20,    # CTA engaged
    "Converted": 0.10,  # Product opened (10% conversion rate)
    "Expired": 0.20,    # Past expiry with no action
}

# --- Customer Lifetime Value ---
# Rationale: Log-normal distribution centered around median retail bank customer value
# Top commercial clients can have LTV > $100K; majority of consumers $5K-$30K
LIFETIME_VALUE_PARAMETERS = {
    "mean": 15000,    # $15,000 average LTV
    "stddev": 25000,  # High variance — long tail of high-value clients
    "min": 0,         # Floor at zero (use ABS of NORMAL)
}

# --- Customer Tenure ---
# Rationale: Uniform distribution 1-360 months (up to 30 years)
# Real distributions would be slightly right-skewed but uniform works for demo
TENURE_PARAMETERS = {
    "min_months": 1,
    "max_months": 360,
}

# --- Account Balances ---
# Rationale: Varies significantly by product type
# Checking: most have $2K-$10K, some payroll accumulation
# Savings: slightly higher, $5K-$25K typical
# CreditCard: outstanding balance $200-$25K (uniform — varies widely)
# MoneyMarket: minimum $25K for most products
# CD: $5K minimum, many at $50K-$100K
# Investment: highly variable, $10K-$100K+
BALANCE_PARAMETERS = {
    "Checking": {"mean": 5000, "stddev": 8000},
    "Savings": {"mean": 12000, "stddev": 15000},
    "CreditCard": {"min": 200, "max": 25000},  # Uniform
    "MoneyMarket": {"mean": 30000, "stddev": 20000},
    "CD": {"min": 5000, "max": 100000},  # Uniform
    "Investment": {"mean": 50000, "stddev": 40000},
}


# =============================================================================
# DATA VOLUME TARGETS
# =============================================================================

TABLE_ROW_COUNTS = {
    "CUSTOMERS": 500_000,
    "ACCOUNTS": 1_000_000,      # ~2 accounts per customer average
    "TRANSACTIONS": 1_000_000,  # ~1 txn per account (for demo; real would be 10-50x)
    "INTERACTIONS": 200_000,    # ~0.4 interactions per customer (annual)
    "CUSTOMER_NOTES": 200_000,  # ~0.4 notes per customer
    "OFFERS": 100_000,          # ~0.2 offers per customer (recent campaigns)
    "PRODUCTS": 50,             # Reference data - manually curated
    "POLICIES": 30,             # Reference data - manually curated
}


# =============================================================================
# DATA GENERATION NOTES
# =============================================================================

"""
Key implementation choices in 02_data.sql:

1. GENERATOR + CROSS JOIN pattern:
   - Large tables use FROM TABLE(GENERATOR(ROWCOUNT => N))
   - FK references use a CTE sampling from parent table then CROSS JOIN
   - LIMIT clause ensures exact target row count

2. Array-based random selection:
   - ARRAY_CONSTRUCT('val1','val2',...)[UNIFORM(0, N-1, RANDOM())]::VARCHAR
   - More readable than nested CASE statements
   - Weights achieved by repeating values in the array

3. Text generation for notes/interactions:
   - Concatenation of template segments with random array picks
   - Creates varied but grammatically correct text
   - 20 unique note templates provide sufficient variety at 200K rows
   - Each template is a realistic multi-sentence advisor note

4. Realistic names:
   - Top 100 US first names (Census) and top 100 US last names
   - Provides 10,000 unique combinations
   - At 500K customers some names repeat (realistic — many John Smiths)

5. Email generation:
   - first.last + random digits + @domain
   - 8 common email providers
   - Results in unique emails at scale

6. Date ranges:
   - Customer created_date: up to 30 years ago (tenure_months alignment)
   - Account opened_date: up to 10 years ago
   - Transaction txn_date: last 2 years (rolling window)
   - Interaction dates: last 2 years
   - Offer sent_date: last 1 year (recent campaigns only)

7. Balance distributions:
   - Normal distribution with ABS() prevents negative balances
   - Different parameters per product type create realistic spread
   - Credit card uses uniform (outstanding balances vary widely)

8. Interest rates:
   - Scaled integers divided by 10000 for 4-decimal precision
   - Checking: 0-0.005% (near-zero for most)
   - Savings: 0.01-0.045% (current rate environment)
   - CreditCard: 14.99-26.99% (standard APR range)
   - MoneyMarket: 2.75-4.50%
   - CD: 3.75-5.00%
   - Investment: NULL (returns are market-based, not fixed rate)
"""


# =============================================================================
# VERIFICATION QUERIES (run after 02_data.sql to validate)
# =============================================================================

VERIFICATION_QUERIES = """
-- Verify row counts
SELECT 'CUSTOMERS' AS tbl, COUNT(*) AS cnt FROM BNK.CUSTOMER_360.CUSTOMERS
UNION ALL SELECT 'ACCOUNTS', COUNT(*) FROM BNK.CUSTOMER_360.ACCOUNTS
UNION ALL SELECT 'TRANSACTIONS', COUNT(*) FROM BNK.CUSTOMER_360.TRANSACTIONS
UNION ALL SELECT 'INTERACTIONS', COUNT(*) FROM BNK.CUSTOMER_360.INTERACTIONS
UNION ALL SELECT 'CUSTOMER_NOTES', COUNT(*) FROM BNK.CUSTOMER_360.CUSTOMER_NOTES
UNION ALL SELECT 'OFFERS', COUNT(*) FROM BNK.CUSTOMER_360.OFFERS
UNION ALL SELECT 'PRODUCTS', COUNT(*) FROM BNK.CUSTOMER_360.PRODUCTS
UNION ALL SELECT 'POLICIES', COUNT(*) FROM BNK.CUSTOMER_360.POLICIES;

-- Verify segment distribution (target: 80/15/5)
SELECT segment, COUNT(*) AS cnt, 
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM BNK.CUSTOMER_360.CUSTOMERS
GROUP BY segment
ORDER BY cnt DESC;

-- Verify region distribution
SELECT region, COUNT(*) AS cnt,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM BNK.CUSTOMER_360.CUSTOMERS
GROUP BY region
ORDER BY cnt DESC;

-- Verify product type distribution
SELECT product_type, COUNT(*) AS cnt,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM BNK.CUSTOMER_360.ACCOUNTS
GROUP BY product_type
ORDER BY cnt DESC;

-- Verify transaction category distribution
SELECT category, COUNT(*) AS cnt,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct
FROM BNK.CUSTOMER_360.TRANSACTIONS
GROUP BY category
ORDER BY cnt DESC;

-- Verify balance ranges by product type
SELECT product_type,
       MIN(balance) AS min_bal,
       AVG(balance) AS avg_bal,
       MEDIAN(balance) AS med_bal,
       MAX(balance) AS max_bal
FROM BNK.CUSTOMER_360.ACCOUNTS
GROUP BY product_type;
"""
