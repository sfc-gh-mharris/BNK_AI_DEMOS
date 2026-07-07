-- =============================================================================
-- WEALTH MANAGEMENT — SEMANTIC VIEW
-- Schema: BNK.WEALTH_MGMT
--
-- Defines the semantic model enabling natural language queries over
-- the wealth management data warehouse via Cortex Analyst.
--
-- Uses CREATE OR ALTER (creates if not exists, alters if exists).
-- Clause order: TABLES → RELATIONSHIPS → FACTS → DIMENSIONS → METRICS
-- =============================================================================

USE DATABASE BNK;
USE SCHEMA BNK.WEALTH_MGMT;
USE WAREHOUSE BNK_WH;

CREATE OR ALTER SEMANTIC VIEW BNK.WEALTH_MGMT.SV_WEALTH_PORTFOLIO
  TABLES (
    wm_clients AS BNK.WEALTH_MGMT.WM_CLIENTS
      PRIMARY KEY (client_id)
      COMMENT = 'Wealth management clients with profile, risk parameters, and relationship metadata.',
    advisors AS BNK.WEALTH_MGMT.ADVISORS
      PRIMARY KEY (advisor_id)
      COMMENT = 'Financial advisors managing client relationships.',
    portfolios AS BNK.WEALTH_MGMT.PORTFOLIOS
      PRIMARY KEY (portfolio_id)
      COMMENT = 'Managed investment portfolios with strategy and benchmark details.',
    holdings AS BNK.WEALTH_MGMT.HOLDINGS
      PRIMARY KEY (holding_id)
      COMMENT = 'Security-level positions within portfolios for concentration and allocation analysis.',
    trades AS BNK.WEALTH_MGMT.TRADES
      PRIMARY KEY (trade_id)
      COMMENT = 'Executed trade records for performance attribution and best execution analysis.'
  )
  RELATIONSHIPS (
    clients_to_portfolios AS portfolios (client_id) REFERENCES wm_clients (client_id),
    portfolios_to_holdings AS holdings (portfolio_id) REFERENCES portfolios (portfolio_id),
    portfolios_to_trades AS trades (portfolio_id) REFERENCES portfolios (portfolio_id),
    clients_to_advisors AS wm_clients (advisor_id) REFERENCES advisors (advisor_id)
  )
  FACTS (
    wm_clients.total_aum AS total_aum COMMENT = 'Total assets under management for a client in USD.',
    advisors.clients_count AS clients_count COMMENT = 'Number of active client relationships managed by this advisor.',
    advisors.total_aum_managed AS total_aum_managed COMMENT = 'Total AUM across all clients for this advisor in USD.',
    portfolios.target_return AS target_return COMMENT = 'Annualized target return percentage from IPS.',
    portfolios.management_fee_bps AS management_fee_bps COMMENT = 'Annual management fee in basis points.',
    holdings.quantity AS holding_quantity COMMENT = 'Shares or units held.',
    holdings.market_value AS market_value COMMENT = 'Current market value of the position in USD.',
    holdings.cost_basis AS cost_basis COMMENT = 'Total cost basis of the position in USD.',
    holdings.weight_pct AS weight_pct COMMENT = 'Position weight as percentage of portfolio.',
    holdings.unrealized_gain_loss AS unrealized_gain_loss COMMENT = 'Unrealized gain/loss in USD (market_value - cost_basis).',
    trades.quantity AS trade_quantity COMMENT = 'Shares traded.',
    trades.price AS trade_price COMMENT = 'Execution price per share in USD.',
    trades.total_value AS trade_total_value COMMENT = 'Total trade value in USD (quantity x price).'
  )
  DIMENSIONS (
    wm_clients.client_id AS client_id COMMENT = 'Unique client identifier (UUID).',
    wm_clients.first_name AS client_first_name COMMENT = 'Client first name.',
    wm_clients.last_name AS client_last_name COMMENT = 'Client last name.',
    wm_clients.segment AS segment COMMENT = 'Wealth segment classification.' SAMPLE_VALUES ('MassAffluent', 'HNWI', 'UHNWI', 'Institutional') IS_ENUM,
    wm_clients.risk_tolerance AS risk_tolerance COMMENT = 'Risk tolerance from suitability questionnaire.' SAMPLE_VALUES ('Conservative', 'Moderate', 'Aggressive', 'VeryAggressive') IS_ENUM,
    wm_clients.investment_objective AS investment_objective COMMENT = 'Primary investment objective.' SAMPLE_VALUES ('Growth', 'Income', 'Balanced', 'Preservation', 'Speculation') IS_ENUM,
    wm_clients.tax_status AS tax_status COMMENT = 'Tax classification.' SAMPLE_VALUES ('Taxable', 'TaxExempt', 'Qualified') IS_ENUM,
    wm_clients.status AS client_status COMMENT = 'Relationship status: Active, Inactive, Closed, Pending.',
    wm_clients.onboarding_date AS onboarding_date COMMENT = 'Date client completed onboarding.',
    advisors.advisor_id AS advisor_id COMMENT = 'Unique advisor identifier.',
    advisors.first_name AS advisor_first_name COMMENT = 'Advisor first name.',
    advisors.last_name AS advisor_last_name COMMENT = 'Advisor last name.',
    advisors.title AS advisor_title COMMENT = 'Corporate title: VP, SVP, MD, Director.',
    advisors.team AS advisor_team COMMENT = 'Practice group: Private Wealth, Institutional Advisory, Family Office.',
    advisors.region AS advisor_region COMMENT = 'Geographic coverage region.' SAMPLE_VALUES ('Northeast', 'Southeast', 'Midwest', 'West', 'Southwest', 'Pacific') IS_ENUM,
    advisors.certification AS advisor_certification COMMENT = 'Professional certification.' SAMPLE_VALUES ('CFP', 'CFA', 'CAIA', 'ChFC') IS_ENUM,
    portfolios.portfolio_id AS portfolio_id COMMENT = 'Unique portfolio identifier.',
    portfolios.portfolio_name AS portfolio_name COMMENT = 'Descriptive portfolio name.',
    portfolios.portfolio_type AS portfolio_type COMMENT = 'Asset class focus.' SAMPLE_VALUES ('Equity', 'FixedIncome', 'Balanced', 'Alternative', 'MultiAsset') IS_ENUM,
    portfolios.strategy AS strategy COMMENT = 'Investment strategy.' SAMPLE_VALUES ('ActiveGrowth', 'ValueIncome', 'IndexCore', 'TacticalAllocation', 'AbsoluteReturn') IS_ENUM,
    portfolios.benchmark AS benchmark COMMENT = 'Performance benchmark.' SAMPLE_VALUES ('SP500', 'MSCIWORLD', 'BARCLAYSAGG', 'HFRI', 'Custom') IS_ENUM,
    portfolios.inception_date AS inception_date COMMENT = 'Portfolio inception date.',
    holdings.ticker AS ticker COMMENT = 'Exchange ticker symbol (e.g., AAPL, MSFT).',
    holdings.security_name AS security_name COMMENT = 'Full security name.',
    holdings.asset_class AS asset_class COMMENT = 'Broad asset class.' SAMPLE_VALUES ('USEquity', 'IntlEquity', 'FixedIncome', 'RealEstate', 'Commodities', 'Alternatives', 'Cash') IS_ENUM,
    holdings.sector AS sector COMMENT = 'GICS sector classification.' SAMPLE_VALUES ('Technology', 'Healthcare', 'Financials', 'Energy', 'ConsumerDiscretionary', 'Industrials', 'Utilities', 'Materials', 'RealEstate', 'CommServices') IS_ENUM,
    holdings.as_of_date AS as_of_date COMMENT = 'Position snapshot date.',
    trades.direction AS direction COMMENT = 'Trade direction: Buy or Sell.' SAMPLE_VALUES ('Buy', 'Sell') IS_ENUM,
    trades.order_type AS order_type COMMENT = 'Order type: Market, Limit, Stop.' SAMPLE_VALUES ('Market', 'Limit', 'Stop') IS_ENUM,
    trades.reason AS trade_reason COMMENT = 'Business reason for trade.' SAMPLE_VALUES ('Rebalance', 'TaxLoss', 'ClientRequest', 'ModelChange', 'Dividend') IS_ENUM,
    trades.trade_date AS trade_date COMMENT = 'Trade execution date.'
  )
  METRICS (
    wm_clients.client_count AS COUNT(client_id) COMMENT = 'Count of distinct wealth management clients.',
    wm_clients.avg_client_aum AS AVG(total_aum) COMMENT = 'Average AUM per client in USD.',
    wm_clients.total_client_aum AS SUM(total_aum) COMMENT = 'Total AUM across all clients.',
    holdings.total_market_value AS SUM(market_value) COMMENT = 'Total market value of all holdings.',
    holdings.total_unrealized_gl AS SUM(unrealized_gain_loss) COMMENT = 'Total unrealized gain/loss across holdings.',
    holdings.max_concentration AS MAX(weight_pct) COMMENT = 'Maximum single-position weight — key risk metric.',
    holdings.avg_position_weight AS AVG(weight_pct) COMMENT = 'Average position weight percentage.',
    holdings.holdings_count AS COUNT(holding_id) COMMENT = 'Number of individual positions.',
    trades.trade_count AS COUNT(trade_id) COMMENT = 'Number of executed trades.',
    trades.total_trade_volume AS SUM(trade_total_value) COMMENT = 'Total dollar value of all trades.',
    trades.avg_trade_size AS AVG(trade_total_value) COMMENT = 'Average trade size in USD.'
  )
  COMMENT = 'Semantic model for wealth management portfolio analytics. Enables financial advisors to ask natural language questions about client AUM, portfolio allocation, holdings concentration, trading activity, and market performance.';
