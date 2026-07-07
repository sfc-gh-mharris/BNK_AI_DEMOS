/*=============================================================================
  WEALTH MANAGEMENT AI PLATFORM — DDL
  Schema: BNK.WEALTH_MGMT
  
  Creates the core data model for the wealth management advisory platform.
  All objects use IF NOT EXISTS to ensure idempotent execution.
=============================================================================*/

USE DATABASE BNK;
USE SCHEMA BNK.WEALTH_MGMT;
USE WAREHOUSE BNK_WH;

-- =============================================================================
-- ADVISORS
-- Source: HR system of record + FINRA BrokerCheck registrations
-- Grain: One row per registered financial advisor
-- =============================================================================
CREATE TABLE IF NOT EXISTS BNK.WEALTH_MGMT.ADVISORS (
    advisor_id      VARCHAR(36)     NOT NULL    COMMENT 'Unique advisor identifier (UUID v4). Primary key sourced from the HR master employee system.',
    first_name      VARCHAR(100)    NOT NULL    COMMENT 'Advisor legal first name as registered with FINRA.',
    last_name       VARCHAR(100)    NOT NULL    COMMENT 'Advisor legal last name as registered with FINRA.',
    title           VARCHAR(20)     NOT NULL    COMMENT 'Corporate title indicating seniority level. Values: VP (Vice President), SVP (Senior Vice President), MD (Managing Director), Director.',
    team            VARCHAR(100)    NOT NULL    COMMENT 'Wealth management team or practice group assignment. Examples: Private Wealth, Institutional Advisory, Family Office.',
    region          VARCHAR(50)     NOT NULL    COMMENT 'Geographic coverage region for client assignment. Values: Northeast, Southeast, Midwest, West, Southwest, Pacific.',
    clients_count   INTEGER         NOT NULL    COMMENT 'Current number of active client relationships managed by this advisor. Updated daily from the CRM system.',
    total_aum_managed DECIMAL(18,2) NOT NULL    COMMENT 'Total assets under management across all client accounts for this advisor, in USD. Updated daily from custody system.',
    certification   VARCHAR(20)     NOT NULL    COMMENT 'Primary professional certification. Values: CFP (Certified Financial Planner), CFA (Chartered Financial Analyst), CAIA (Chartered Alternative Investment Analyst), ChFC (Chartered Financial Consultant).',

    CONSTRAINT pk_advisors PRIMARY KEY (advisor_id)
)
COMMENT = 'Master table of registered financial advisors in the wealth management division. Each row represents one advisor with their credentials, team assignment, and book-of-business summary metrics. Source: HR system + FINRA BrokerCheck.';

-- =============================================================================
-- WM_CLIENTS
-- Source: Client onboarding system + CRM (Salesforce)
-- Grain: One row per wealth management client relationship
-- =============================================================================
CREATE TABLE IF NOT EXISTS BNK.WEALTH_MGMT.WM_CLIENTS (
    client_id           VARCHAR(36)     NOT NULL    COMMENT 'Unique client identifier (UUID v4). Primary key generated at account opening by the onboarding system.',
    first_name          VARCHAR(100)    NOT NULL    COMMENT 'Client legal first name as recorded on account application and verified against government-issued ID.',
    last_name           VARCHAR(100)    NOT NULL    COMMENT 'Client legal last name as recorded on account application and verified against government-issued ID.',
    advisor_id          VARCHAR(36)     NOT NULL    COMMENT 'Foreign key to ADVISORS table. The primary advisor assigned to this client relationship.',
    segment             VARCHAR(20)     NOT NULL    COMMENT 'Client wealth segment classification based on total investable assets. Values: MassAffluent ($250K-$1M), HNWI ($1M-$10M), UHNWI ($10M+), Institutional ($50M+).',
    total_aum           DECIMAL(18,2)   NOT NULL    COMMENT 'Total assets under management across all accounts for this client, in USD. Calculated daily as sum of all portfolio market values.',
    risk_tolerance      VARCHAR(20)     NOT NULL    COMMENT 'Client risk tolerance as determined by suitability questionnaire and Investment Policy Statement. Values: Conservative, Moderate, Aggressive, VeryAggressive.',
    investment_objective VARCHAR(20)    NOT NULL    COMMENT 'Primary investment objective documented in the Investment Policy Statement. Values: Growth, Income, Balanced, Preservation, Speculation.',
    tax_status          VARCHAR(20)     NOT NULL    COMMENT 'Tax classification affecting investment strategy and asset location decisions. Values: Taxable, TaxExempt (nonprofit/endowment), Qualified (IRA/401k).',
    onboarding_date     DATE            NOT NULL    COMMENT 'Date the client completed all onboarding documentation and account was activated. Source: onboarding workflow system.',
    relationship_start_date DATE        NOT NULL    COMMENT 'Date the advisory relationship formally commenced, which may predate account opening if transferred from another firm.',
    status              VARCHAR(20)     NOT NULL    COMMENT 'Current client relationship status. Values: Active, Inactive, Closed, Pending. Inactive = no transactions in 12+ months.',

    CONSTRAINT pk_wm_clients PRIMARY KEY (client_id),
    CONSTRAINT fk_wm_clients_advisor FOREIGN KEY (advisor_id) REFERENCES BNK.WEALTH_MGMT.ADVISORS(advisor_id)
)
COMMENT = 'Master client table for the wealth management division. Each row represents one advisory client with their profile, risk parameters, and relationship metadata. Supports RegBI suitability requirements by documenting investment objectives and risk tolerance. Source: onboarding system + CRM.';

-- =============================================================================
-- PORTFOLIOS
-- Source: Portfolio management system (PMS)
-- Grain: One row per managed portfolio (a client may have multiple)
-- =============================================================================
CREATE TABLE IF NOT EXISTS BNK.WEALTH_MGMT.PORTFOLIOS (
    portfolio_id    VARCHAR(36)     NOT NULL    COMMENT 'Unique portfolio identifier (UUID v4). Primary key assigned by the portfolio management system at inception.',
    client_id       VARCHAR(36)     NOT NULL    COMMENT 'Foreign key to WM_CLIENTS table. The client who owns this portfolio.',
    portfolio_name  VARCHAR(200)    NOT NULL    COMMENT 'Descriptive name for the portfolio, typically indicating account type and strategy. Example: "Smith Family Trust - Growth Equity".',
    portfolio_type  VARCHAR(20)     NOT NULL    COMMENT 'Asset class focus of the portfolio. Values: Equity, FixedIncome, Balanced, Alternative, MultiAsset.',
    strategy        VARCHAR(30)     NOT NULL    COMMENT 'Investment strategy governing security selection and allocation. Values: ActiveGrowth, ValueIncome, IndexCore, TacticalAllocation, AbsoluteReturn.',
    inception_date  DATE            NOT NULL    COMMENT 'Date the portfolio was created and initial funding was received. Used as start date for performance calculations.',
    benchmark       VARCHAR(20)     NOT NULL    COMMENT 'Performance benchmark index used for relative return measurement. Values: SP500, MSCIWORLD, BARCLAYSAGG, HFRI, Custom.',
    target_return   DECIMAL(5,2)    NOT NULL    COMMENT 'Annualized target return percentage specified in the Investment Policy Statement. Example: 8.50 represents 8.50% per annum.',
    management_fee_bps INTEGER      NOT NULL    COMMENT 'Annual management fee in basis points (1 bps = 0.01%). Typical range: 25-150 bps depending on strategy and AUM.',

    CONSTRAINT pk_portfolios PRIMARY KEY (portfolio_id),
    CONSTRAINT fk_portfolios_client FOREIGN KEY (client_id) REFERENCES BNK.WEALTH_MGMT.WM_CLIENTS(client_id)
)
COMMENT = 'Portfolio registry containing all managed investment portfolios. Each client may have multiple portfolios with different strategies, benchmarks, and fee structures. Grain: one row per portfolio. Source: portfolio management system (PMS).';

-- =============================================================================
-- HOLDINGS
-- Source: Custody system daily position file
-- Grain: One row per security position per portfolio per as-of date
-- =============================================================================
CREATE TABLE IF NOT EXISTS BNK.WEALTH_MGMT.HOLDINGS (
    holding_id          VARCHAR(36)     NOT NULL    COMMENT 'Unique holding record identifier (UUID v4). Synthetic key combining portfolio, ticker, and as-of date.',
    portfolio_id        VARCHAR(36)     NOT NULL    COMMENT 'Foreign key to PORTFOLIOS table. The portfolio containing this holding.',
    ticker              VARCHAR(20)     NOT NULL    COMMENT 'Exchange ticker symbol for the security. Sourced from custody system using Bloomberg symbology.',
    security_name       VARCHAR(200)    NOT NULL    COMMENT 'Full legal security name as registered with the exchange or fund administrator.',
    asset_class         VARCHAR(20)     NOT NULL    COMMENT 'Broad asset class classification for allocation analysis. Values: USEquity, IntlEquity, FixedIncome, RealEstate, Commodities, Alternatives, Cash.',
    sector              VARCHAR(30)     NOT NULL    COMMENT 'GICS sector classification for equity holdings. Values: Technology, Healthcare, Financials, Energy, ConsumerDiscretionary, Industrials, Utilities, Materials, RealEstate, CommServices.',
    quantity            DECIMAL(18,4)   NOT NULL    COMMENT 'Number of shares or units held. Supports fractional shares to four decimal places.',
    market_value        DECIMAL(18,2)   NOT NULL    COMMENT 'Current market value of the position in USD, calculated as quantity × closing price on the as-of date.',
    cost_basis          DECIMAL(18,2)   NOT NULL    COMMENT 'Total cost basis of the position in USD for tax lot accounting. Used for unrealized gain/loss and tax-loss harvesting.',
    weight_pct          DECIMAL(7,4)    NOT NULL    COMMENT 'Position weight as a percentage of total portfolio market value. Example: 5.2500 represents 5.25% of the portfolio.',
    unrealized_gain_loss DECIMAL(18,2)  NOT NULL    COMMENT 'Unrealized gain or loss in USD (market_value minus cost_basis). Negative values indicate unrealized losses available for tax-loss harvesting.',
    as_of_date          DATE            NOT NULL    COMMENT 'Position date for this holdings snapshot. Holdings are captured end-of-day from the custody system.',

    CONSTRAINT pk_holdings PRIMARY KEY (holding_id),
    CONSTRAINT fk_holdings_portfolio FOREIGN KEY (portfolio_id) REFERENCES BNK.WEALTH_MGMT.PORTFOLIOS(portfolio_id)
)
COMMENT = 'Daily position-level holdings for all managed portfolios. Each row represents one security position within one portfolio as of a specific date. Used for concentration analysis, asset allocation reporting, and tax-loss harvesting identification. Source: daily custody position file.';

-- =============================================================================
-- MARKET_DATA
-- Source: Market data vendor (Bloomberg/Refinitiv) end-of-day feed
-- Grain: One row per ticker per trading day
-- =============================================================================
CREATE TABLE IF NOT EXISTS BNK.WEALTH_MGMT.MARKET_DATA (
    ticker          VARCHAR(20)     NOT NULL    COMMENT 'Exchange ticker symbol. Matches HOLDINGS.ticker for join operations.',
    trade_date      DATE            NOT NULL    COMMENT 'Trading date for this market data record. Excludes weekends and market holidays.',
    open_price      DECIMAL(12,4)   NOT NULL    COMMENT 'Opening trade price in USD at market open (9:30 AM ET for US equities).',
    close_price     DECIMAL(12,4)   NOT NULL    COMMENT 'Closing trade price in USD at market close (4:00 PM ET for US equities). Used for NAV calculations.',
    high_price      DECIMAL(12,4)   NOT NULL    COMMENT 'Intraday high price in USD. Highest trade price recorded during the trading session.',
    low_price       DECIMAL(12,4)   NOT NULL    COMMENT 'Intraday low price in USD. Lowest trade price recorded during the trading session.',
    volume          BIGINT          NOT NULL    COMMENT 'Total shares traded during the session. Used for liquidity analysis and best execution monitoring.',
    market_cap      DECIMAL(18,2)   NULL        COMMENT 'Market capitalization in USD (shares outstanding × close price). Updated daily. NULL for non-equity securities.',
    pe_ratio        DECIMAL(8,2)    NULL        COMMENT 'Price-to-earnings ratio (trailing twelve months). NULL for companies with negative earnings or non-equity securities.',
    dividend_yield  DECIMAL(6,4)    NULL        COMMENT 'Indicated annual dividend yield as a decimal (e.g., 0.0325 = 3.25%). NULL for non-dividend-paying securities.',
    sector          VARCHAR(30)     NOT NULL    COMMENT 'GICS sector classification. Values: Technology, Healthcare, Financials, Energy, ConsumerDiscretionary, Industrials, Utilities, Materials, RealEstate, CommServices.',

    CONSTRAINT pk_market_data PRIMARY KEY (ticker, trade_date)
)
COMMENT = 'End-of-day market data for all securities in the investment universe. Provides OHLCV pricing, fundamental ratios, and sector classification. Grain: one row per ticker per trading day. Source: Bloomberg/Refinitiv end-of-day feed.';

-- =============================================================================
-- TRADES
-- Source: Order management system (OMS) execution records
-- Grain: One row per executed trade
-- =============================================================================
CREATE TABLE IF NOT EXISTS BNK.WEALTH_MGMT.TRADES (
    trade_id        VARCHAR(36)     NOT NULL    COMMENT 'Unique trade identifier (UUID v4). Assigned by the order management system upon execution confirmation.',
    portfolio_id    VARCHAR(36)     NOT NULL    COMMENT 'Foreign key to PORTFOLIOS table. The portfolio in which this trade was executed.',
    ticker          VARCHAR(20)     NOT NULL    COMMENT 'Exchange ticker symbol of the traded security.',
    direction       VARCHAR(10)     NOT NULL    COMMENT 'Trade direction. Values: Buy (purchase/add to position), Sell (liquidate/reduce position).',
    quantity        DECIMAL(18,4)   NOT NULL    COMMENT 'Number of shares or units traded. Supports fractional shares for ETFs and mutual funds.',
    price           DECIMAL(12,4)   NOT NULL    COMMENT 'Execution price per share in USD. Actual fill price from the executing broker.',
    total_value     DECIMAL(18,2)   NOT NULL    COMMENT 'Total trade value in USD (quantity × price). Excludes commissions and fees.',
    trade_date      DATE            NOT NULL    COMMENT 'Trade execution date (T). The date the order was filled on the exchange.',
    settlement_date DATE            NOT NULL    COMMENT 'Settlement date (typically T+1 for US equities). Date when securities and cash are exchanged.',
    order_type      VARCHAR(10)     NOT NULL    COMMENT 'Order type used for execution. Values: Market (immediate fill at current price), Limit (fill at specified price or better), Stop (triggered at stop price).',
    reason          VARCHAR(20)     NOT NULL    COMMENT 'Business reason for the trade. Values: Rebalance, TaxLoss (tax-loss harvesting), ClientRequest, ModelChange (strategy change), Dividend (reinvestment).',

    CONSTRAINT pk_trades PRIMARY KEY (trade_id),
    CONSTRAINT fk_trades_portfolio FOREIGN KEY (portfolio_id) REFERENCES BNK.WEALTH_MGMT.PORTFOLIOS(portfolio_id)
)
COMMENT = 'Executed trade records from the order management system. Each row represents one completed trade with execution details and business rationale. Used for best execution analysis, trade cost monitoring, and regulatory reporting. Source: OMS execution confirmations.';

-- =============================================================================
-- RESEARCH_REPORTS
-- Source: Internal equity research department
-- Grain: One row per published research report
-- =============================================================================
CREATE TABLE IF NOT EXISTS BNK.WEALTH_MGMT.RESEARCH_REPORTS (
    report_id       VARCHAR(36)     NOT NULL    COMMENT 'Unique report identifier (UUID v4). Assigned by the research publication system.',
    title           VARCHAR(500)    NOT NULL    COMMENT 'Report title summarizing the thesis or coverage update. Example: "Apple Inc. (AAPL) — AI Integration Accelerates Services Revenue Growth".',
    analyst_name    VARCHAR(100)    NOT NULL    COMMENT 'Name of the research analyst who authored and published the report.',
    publish_date    DATE            NOT NULL    COMMENT 'Date the report was published and distributed to advisors. Determines research freshness.',
    sector          VARCHAR(30)     NOT NULL    COMMENT 'Primary sector covered by the report. Values: Technology, Healthcare, Financials, Energy, ConsumerDiscretionary, Industrials, Utilities, Materials, RealEstate, CommServices.',
    ticker_coverage VARCHAR(200)    NOT NULL    COMMENT 'Comma-separated list of ticker symbols covered in this report. Primary ticker listed first.',
    rating          VARCHAR(20)     NOT NULL    COMMENT 'Analyst consensus rating for the primary covered security. Values: StrongBuy, Buy, Hold, Sell, StrongSell.',
    target_price    DECIMAL(12,2)   NULL        COMMENT 'Analyst 12-month price target in USD for the primary covered security. NULL if report is sector-level without specific targets.',
    content         TEXT            NOT NULL    COMMENT 'Full text content of the research report (500-2000 words). Includes investment thesis, company analysis, financial model summary, valuation methodology, and key risks. Indexed by Cortex Search for semantic retrieval.',

    CONSTRAINT pk_research_reports PRIMARY KEY (report_id)
)
COMMENT = 'Internal equity research reports authored by firm analysts. Contains full-text research including theses, valuation analysis, and ratings. Indexed by RESEARCH_SEARCH Cortex Search Service for semantic retrieval by advisors. Source: research publication system.';

-- =============================================================================
-- COMPLIANCE_DOCS
-- Source: Legal & Compliance document management system
-- Grain: One row per compliance/regulatory document
-- =============================================================================
CREATE TABLE IF NOT EXISTS BNK.WEALTH_MGMT.COMPLIANCE_DOCS (
    doc_id          VARCHAR(36)     NOT NULL    COMMENT 'Unique document identifier (UUID v4). Assigned by the compliance document management system.',
    title           VARCHAR(500)    NOT NULL    COMMENT 'Official document title as filed with regulators or approved by the Chief Compliance Officer.',
    category        VARCHAR(30)     NOT NULL    COMMENT 'Compliance document category for classification and retrieval. Values: Suitability, RegBI, FormADV, ClientAgreement, ProxyVoting, BestExecution, AntiMoneyLaundering.',
    effective_date  DATE            NOT NULL    COMMENT 'Date the document became effective and enforceable. Supersedes any prior version with the same title.',
    content         TEXT            NOT NULL    COMMENT 'Full text content of the compliance or regulatory document. Includes policy language, procedures, and regulatory citations. Indexed by Cortex Search for semantic retrieval by advisors and compliance officers.',

    CONSTRAINT pk_compliance_docs PRIMARY KEY (doc_id)
)
COMMENT = 'Compliance and regulatory policy documents governing wealth management advisory activities. Contains full-text policies covering suitability, RegBI, best execution, proxy voting, and AML. Indexed by COMPLIANCE_SEARCH Cortex Search Service. Source: legal/compliance document management system.';

-- =============================================================================
-- CLIENT_NOTES
-- Source: CRM system (Salesforce) advisor activity logs
-- Grain: One row per client interaction note
-- =============================================================================
CREATE TABLE IF NOT EXISTS BNK.WEALTH_MGMT.CLIENT_NOTES (
    note_id         VARCHAR(36)     NOT NULL    COMMENT 'Unique note identifier (UUID v4). Assigned by the CRM system when the advisor creates the record.',
    client_id       VARCHAR(36)     NOT NULL    COMMENT 'Foreign key to WM_CLIENTS table. The client this interaction note pertains to.',
    advisor_id      VARCHAR(36)     NOT NULL    COMMENT 'Foreign key to ADVISORS table. The advisor who documented this interaction.',
    note_date       DATE            NOT NULL    COMMENT 'Date of the client interaction documented in this note.',
    note_type       VARCHAR(20)     NOT NULL    COMMENT 'Type of client interaction. Values: Meeting (in-person or virtual), Call (phone), Email (written correspondence), Review (annual/quarterly review), Rebalance (portfolio adjustment discussion).',
    note_text       TEXT            NOT NULL    COMMENT 'Free-text advisor notes documenting the client interaction, decisions made, and follow-up items. Indexed by Cortex Search for relationship context retrieval.',

    CONSTRAINT pk_client_notes PRIMARY KEY (note_id),
    CONSTRAINT fk_client_notes_client FOREIGN KEY (client_id) REFERENCES BNK.WEALTH_MGMT.WM_CLIENTS(client_id),
    CONSTRAINT fk_client_notes_advisor FOREIGN KEY (advisor_id) REFERENCES BNK.WEALTH_MGMT.ADVISORS(advisor_id)
)
COMMENT = 'Advisor notes documenting client interactions including meetings, calls, reviews, and rebalancing discussions. Provides relationship context and decision history for advisory continuity. Indexed by CLIENT_NOTES_SEARCH Cortex Search Service. Source: CRM (Salesforce) advisor activity logs.';
