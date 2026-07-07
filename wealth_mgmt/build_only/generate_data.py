"""
=============================================================================
WEALTH MANAGEMENT — BUILD ONLY: Data Generation Documentation
=============================================================================
Purpose: Documents the logic and distribution choices behind the synthetic
         data generated in 02_data.sql. This script is NOT shared with the
         customer — it exists as internal reference for how the demo data
         was constructed.

Key Distribution Decisions:
- Client segments: 40% MassAffluent ($250K-$1M), 35% HNWI ($1M-$10M), 
  20% UHNWI ($10M+), 5% Institutional ($50M+)
- Risk tolerance: Correlates with segment (UHNWI skews aggressive)
- Portfolios per client: 1-3 (weighted toward 1-2)
- Holdings per portfolio: 5-15 positions for equity, 3-8 for fixed income
- Trading frequency: ~3-4 trades per portfolio per month
- Research: Fresh reports within last 180 days across all sectors
- Compliance: Documents with effective dates spanning last 3 years
=============================================================================
"""

# === AUM Distribution ===
# Based on industry data from Cerulli Associates and Spectrem Group:
# - MassAffluent: $250K - $1M investable assets (40% of clients)
# - HNWI: $1M - $10M (35% of clients) 
# - UHNWI: $10M - $100M+ (20% of clients)
# - Institutional: $50M+ (5% of clients, pension/endowment/foundation)
#
# Total demo AUM should approximate $150-200B across 100K clients

# === Ticker Universe ===
# 32 tickers covering all GICS sectors for realistic allocation:
TICKER_UNIVERSE = {
    'Technology': ['AAPL', 'MSFT', 'GOOGL', 'AMZN', 'NVDA', 'META', 'TSLA', 'CRM'],
    'Healthcare': ['JNJ', 'PFE', 'UNH', 'ABBV', 'MRK', 'LLY'],
    'Financials': ['JPM', 'BAC', 'WFC', 'GS', 'MS', 'BLK'],
    'Energy': ['XOM', 'CVX', 'COP'],
    'ConsumerDiscretionary': ['HD', 'NKE', 'COST', 'TGT'],
    'Industrials': ['CAT', 'HON', 'GE'],
    'Utilities': ['NEE', 'DUK', 'SO'],
    'RealEstate': ['AMT', 'PLD'],
    'CommServices': ['DIS', 'NFLX'],
}

# === Price Ranges (approximate as of 2024-2025) ===
PRICE_RANGES = {
    'AAPL': (170, 220), 'MSFT': (380, 450), 'GOOGL': (140, 180),
    'AMZN': (170, 210), 'NVDA': (500, 900), 'META': (350, 550),
    'TSLA': (170, 280), 'CRM': (250, 320), 'JNJ': (145, 165),
    'PFE': (25, 32), 'UNH': (480, 580), 'ABBV': (155, 195),
    'MRK': (110, 135), 'LLY': (700, 900), 'JPM': (170, 220),
    'BAC': (32, 42), 'WFC': (50, 65), 'GS': (380, 500),
    'MS': (85, 105), 'BLK': (750, 900), 'XOM': (100, 120),
    'CVX': (145, 165), 'COP': (105, 125), 'HD': (340, 400),
    'NKE': (80, 115), 'COST': (680, 800), 'TGT': (130, 170),
    'CAT': (290, 370), 'HON': (190, 220), 'GE': (140, 180),
    'NEE': (65, 80), 'DUK': (95, 110), 'SO': (70, 82),
    'AMT': (200, 230), 'PLD': (120, 140), 'DIS': (85, 110),
    'NFLX': (550, 700),
}

# === Portfolio Strategy Allocation Targets ===
STRATEGY_ALLOCATIONS = {
    'ActiveGrowth': {'USEquity': 0.55, 'IntlEquity': 0.20, 'FixedIncome': 0.10, 'Alternatives': 0.10, 'Cash': 0.05},
    'ValueIncome': {'USEquity': 0.30, 'IntlEquity': 0.10, 'FixedIncome': 0.40, 'Alternatives': 0.10, 'Cash': 0.10},
    'IndexCore': {'USEquity': 0.45, 'IntlEquity': 0.20, 'FixedIncome': 0.25, 'Alternatives': 0.05, 'Cash': 0.05},
    'TacticalAllocation': {'USEquity': 0.35, 'IntlEquity': 0.15, 'FixedIncome': 0.25, 'Alternatives': 0.15, 'Cash': 0.10},
    'AbsoluteReturn': {'USEquity': 0.20, 'IntlEquity': 0.10, 'FixedIncome': 0.20, 'Alternatives': 0.40, 'Cash': 0.10},
}

# === Research Report Distribution ===
# Reports per sector (30 total):
# Technology: 8, Healthcare: 6, Financials: 5, Energy: 4,
# ConsumerDiscretionary: 3, Industrials: 2, Utilities: 2
#
# Rating distribution: StrongBuy 5, Buy 10, Hold 10, Sell 4, StrongSell 1

# === Compliance Document Categories ===
# Suitability: 4 docs (RegBI core requirements, suitability procedures)
# RegBI: 4 docs (care obligation, disclosure, conflicts, documentation)
# BestExecution: 3 docs (routing, review, reporting)
# FormADV: 3 docs (Part 2A brochure, Part 2B supplement, amendments)
# ProxyVoting: 2 docs (policy, guidelines)
# ClientAgreement: 2 docs (standard terms, fee schedule)
# AntiMoneyLaundering: 2 docs (CIP policy, SAR procedures)

# === Verification Queries ===
# After running 02_data.sql, verify with:
VERIFICATION_QUERIES = """
-- Client segment distribution
SELECT segment, COUNT(*), ROUND(COUNT(*)*100.0/SUM(COUNT(*)) OVER(), 1) AS pct
FROM BNK.WEALTH_MGMT.WM_CLIENTS GROUP BY segment;

-- AUM by segment  
SELECT segment, 
    MIN(total_aum) AS min_aum, 
    AVG(total_aum) AS avg_aum, 
    MAX(total_aum) AS max_aum,
    SUM(total_aum) AS total_aum
FROM BNK.WEALTH_MGMT.WM_CLIENTS GROUP BY segment;

-- Holdings per portfolio
SELECT portfolio_id, COUNT(*) AS holdings_count
FROM BNK.WEALTH_MGMT.HOLDINGS
GROUP BY portfolio_id
ORDER BY holdings_count DESC
LIMIT 20;

-- Sector distribution in holdings
SELECT sector, COUNT(*), SUM(market_value) AS total_mv
FROM BNK.WEALTH_MGMT.HOLDINGS
GROUP BY sector
ORDER BY total_mv DESC;

-- Research reports by sector
SELECT sector, COUNT(*), 
    LISTAGG(DISTINCT rating, ', ') AS ratings
FROM BNK.WEALTH_MGMT.RESEARCH_REPORTS
GROUP BY sector;
"""

if __name__ == '__main__':
    print("This script documents data generation logic.")
    print("Actual data is generated via Snowflake SQL in 02_data.sql")
    print("\nTicker universe covers", sum(len(v) for v in TICKER_UNIVERSE.values()), "securities")
    print("across", len(TICKER_UNIVERSE), "sectors")
    print("\nVerification queries:")
    print(VERIFICATION_QUERIES)
