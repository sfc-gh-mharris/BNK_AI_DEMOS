/*=============================================================================
  LENDING ANALYTICS - DDL
  Database: BNK | Schema: LENDING | Warehouse: BNK_WH
  
  Creates the core lending analytics data model for the virtual banker
  assistant. All tables use IF NOT EXISTS to support idempotent deployment.
=============================================================================*/

USE DATABASE BNK;
USE SCHEMA BNK.LENDING;
USE WAREHOUSE BNK_WH;

-------------------------------------------------------------------------------
-- BORROWERS
-- Source: Core banking system (CBS) customer master + credit bureau feeds
-- Grain: One row per borrower (customer who has or has applied for a mortgage)
-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS BNK.LENDING.BORROWERS (
    borrower_id       VARCHAR(36)   NOT NULL
        COMMENT 'Universally unique identifier for the borrower, sourced from the core banking system customer master (UUID v4 format).',
    first_name        VARCHAR(100)  NOT NULL
        COMMENT 'Borrower legal first name as recorded on the mortgage application (Form 1003).',
    last_name         VARCHAR(100)  NOT NULL
        COMMENT 'Borrower legal last name as recorded on the mortgage application (Form 1003).',
    age               INTEGER       NOT NULL
        COMMENT 'Borrower age in years at time of most recent record refresh, derived from date of birth on file.',
    annual_income     NUMBER(12,2)  NOT NULL
        COMMENT 'Gross annual income in USD as verified during most recent underwriting or annual review. Includes salary, bonuses, and documented self-employment income.',
    credit_score      INTEGER       NOT NULL
        COMMENT 'Most recent FICO score (300-850 range) pulled from credit bureau feed. Updated monthly via soft inquiry batch process.',
    employment_status VARCHAR(20)   NOT NULL
        COMMENT 'Current employment classification. Valid values: Employed, SelfEmployed, Retired, Unemployed. Sourced from annual borrower attestation and employer verification.',
    employer_name     VARCHAR(200)
        COMMENT 'Current or most recent employer name. NULL for Retired or Unemployed borrowers without recent employment history.',
    years_employed    NUMBER(4,1)
        COMMENT 'Tenure in years at current employer. For SelfEmployed, represents years of continuous self-employment. NULL if Unemployed.',
    region            VARCHAR(50)   NOT NULL
        COMMENT 'Geographic region classification for portfolio segmentation. Values: Northeast, Southeast, Midwest, Southwest, West, Pacific.',
    state             VARCHAR(2)    NOT NULL
        COMMENT 'Two-letter US state code (USPS standard) of borrower primary residence.',
    created_date      DATE          NOT NULL
        COMMENT 'Date the borrower record was first created in the lending system, typically the mortgage application submission date.',

    CONSTRAINT pk_borrowers PRIMARY KEY (borrower_id)
)
COMMENT = 'Master borrower table containing demographic, financial, and employment information for all mortgage borrowers. Sourced from core banking system customer master with monthly credit bureau enrichment. One row per unique borrower.';

-------------------------------------------------------------------------------
-- MORTGAGES
-- Source: Loan origination system (LOS) + servicing platform
-- Grain: One row per mortgage loan
-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS BNK.LENDING.MORTGAGES (
    mortgage_id       VARCHAR(36)   NOT NULL
        COMMENT 'Universally unique identifier for the mortgage loan, assigned at origination by the loan origination system (UUID v4 format).',
    borrower_id       VARCHAR(36)   NOT NULL
        COMMENT 'Foreign key to BORROWERS table. Links mortgage to the primary borrower on the note.',
    property_address  VARCHAR(500)  NOT NULL
        COMMENT 'Full street address of the collateral property including unit number if applicable. Format: street, city, state ZIP.',
    property_value    NUMBER(12,2)  NOT NULL
        COMMENT 'Most recent appraised value of the collateral property in USD. Updated at origination, refinance, or periodic BPO/AVM refresh.',
    loan_amount       NUMBER(12,2)  NOT NULL
        COMMENT 'Original principal balance of the mortgage loan in USD at time of closing.',
    interest_rate     NUMBER(5,3)   NOT NULL
        COMMENT 'Current annual interest rate as a percentage (e.g., 6.250). For ARM loans, reflects the current adjusted rate.',
    term_years        INTEGER       NOT NULL
        COMMENT 'Original loan term in years. Standard values: 15, 20, 30. Determines amortization schedule and maturity date.',
    loan_type         VARCHAR(20)   NOT NULL
        COMMENT 'Mortgage product classification. Valid values: Fixed (conventional fixed-rate), ARM (adjustable-rate), FHA (Federal Housing Administration insured), VA (Veterans Affairs guaranteed), Jumbo (exceeds conforming loan limits).',
    origination_date  DATE          NOT NULL
        COMMENT 'Date the mortgage loan was funded and closed. Establishes the start of the amortization schedule.',
    maturity_date     DATE          NOT NULL
        COMMENT 'Contractual final payment date based on origination date plus loan term.',
    ltv_ratio         NUMBER(5,2)   NOT NULL
        COMMENT 'Loan-to-value ratio at origination expressed as percentage (e.g., 80.00). Calculated as loan_amount / property_value * 100.',
    dti_ratio         NUMBER(5,2)   NOT NULL
        COMMENT 'Debt-to-income ratio at origination expressed as percentage. Total monthly debt obligations (including this mortgage) divided by gross monthly income.',
    status            VARCHAR(20)   NOT NULL
        COMMENT 'Current loan servicing status. Valid values: Current (performing), Delinquent30 (30-59 days past due), Delinquent60 (60-89 DPD), Delinquent90 (90+ DPD), Default (in foreclosure/loss mitigation), PaidOff (fully satisfied), Refinanced (paid off via refinance).',

    CONSTRAINT pk_mortgages PRIMARY KEY (mortgage_id),
    CONSTRAINT fk_mortgages_borrower FOREIGN KEY (borrower_id) REFERENCES BNK.LENDING.BORROWERS(borrower_id)
)
COMMENT = 'Mortgage loan master table containing loan terms, collateral details, and current servicing status. Sourced from loan origination system at funding with ongoing updates from the servicing platform. One row per mortgage loan.';

-------------------------------------------------------------------------------
-- PAYMENTS
-- Source: Servicing platform payment processing system
-- Grain: One row per scheduled or actual payment event
-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS BNK.LENDING.PAYMENTS (
    payment_id        VARCHAR(36)   NOT NULL
        COMMENT 'Universally unique identifier for the payment record, assigned by the servicing payment processing engine (UUID v4 format).',
    mortgage_id       VARCHAR(36)   NOT NULL
        COMMENT 'Foreign key to MORTGAGES table. Links payment to the associated mortgage loan.',
    payment_date      DATE          NOT NULL
        COMMENT 'Scheduled due date for the payment. Actual receipt date may differ; see payment_status for timeliness.',
    amount_due        NUMBER(10,2)  NOT NULL
        COMMENT 'Total monthly payment amount due in USD, including principal, interest, and escrow components.',
    amount_paid       NUMBER(10,2)  NOT NULL
        COMMENT 'Actual amount received from borrower in USD for this payment period. May be zero (missed), less than due (partial), or equal to/greater than due.',
    principal_portion NUMBER(10,2)  NOT NULL
        COMMENT 'Portion of the payment applied to principal balance reduction in USD, per the amortization schedule.',
    interest_portion  NUMBER(10,2)  NOT NULL
        COMMENT 'Portion of the payment applied to accrued interest in USD, calculated based on current rate and outstanding balance.',
    escrow_portion    NUMBER(10,2)  NOT NULL
        COMMENT 'Portion of the payment deposited into escrow account for property taxes and insurance in USD.',
    days_past_due     INTEGER       NOT NULL
        COMMENT 'Number of calendar days between the scheduled due date and actual payment receipt. Zero indicates on-time payment.',
    payment_status    VARCHAR(20)   NOT NULL
        COMMENT 'Payment classification for servicing reporting. Valid values: OnTime (received by due date), Late (received after due date but in full), Missed (no payment received for the period), Partial (received less than amount due).',

    CONSTRAINT pk_payments PRIMARY KEY (payment_id),
    CONSTRAINT fk_payments_mortgage FOREIGN KEY (mortgage_id) REFERENCES BNK.LENDING.MORTGAGES(mortgage_id)
)
COMMENT = 'Payment transaction history for all mortgage loans. Records each scheduled monthly payment with actual amounts received and allocation breakdown. Sourced from servicing platform payment processing system. One row per payment period per mortgage.';

-------------------------------------------------------------------------------
-- RISK_SCORES
-- Source: Internal credit risk model (Model ID: LND-PD-v3) scoring engine
-- Grain: One row per borrower per scoring run (monthly)
-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS BNK.LENDING.RISK_SCORES (
    score_id                VARCHAR(36)   NOT NULL
        COMMENT 'Universally unique identifier for this risk score record (UUID v4 format).',
    borrower_id             VARCHAR(36)   NOT NULL
        COMMENT 'Foreign key to BORROWERS table. Identifies the borrower being scored.',
    score_date              DATE          NOT NULL
        COMMENT 'Date the risk model was executed for this borrower. Scoring runs monthly on the 1st business day.',
    probability_of_default  FLOAT         NOT NULL
        COMMENT 'Predicted 12-month probability of default (0.0 to 1.0). Output of internal PD model LND-PD-v3 using credit score, DTI, LTV, payment history, and macroeconomic inputs.',
    loss_given_default      FLOAT         NOT NULL
        COMMENT 'Estimated loss severity given default (0.0 to 1.0). Based on LTV, property type, geographic market conditions, and historical recovery rates.',
    expected_loss           NUMBER(12,2)  NOT NULL
        COMMENT 'Dollar expected loss calculated as: probability_of_default * loss_given_default * exposure_at_default. Used for CECL reserve calculations.',
    refinance_probability   FLOAT         NOT NULL
        COMMENT 'Predicted probability (0.0 to 1.0) that the borrower will refinance within the next 6 months. Based on rate differential, credit improvement, and behavioral signals.',
    model_version           VARCHAR(20)   NOT NULL
        COMMENT 'Version identifier of the risk model that produced this score (e.g., v3.2.1). Used for model governance and backtesting.',

    CONSTRAINT pk_risk_scores PRIMARY KEY (score_id),
    CONSTRAINT fk_risk_scores_borrower FOREIGN KEY (borrower_id) REFERENCES BNK.LENDING.BORROWERS(borrower_id)
)
COMMENT = 'Monthly risk model output for each borrower, including probability of default, loss given default, expected loss, and refinance propensity. Generated by internal model LND-PD-v3 on the first business day of each month. Used for portfolio risk monitoring and proactive customer outreach.';

-------------------------------------------------------------------------------
-- REFINANCE_SIGNALS
-- Source: Behavioral analytics platform + market data feeds
-- Grain: One row per detected refinance signal event
-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS BNK.LENDING.REFINANCE_SIGNALS (
    signal_id    VARCHAR(36)   NOT NULL
        COMMENT 'Universally unique identifier for the refinance signal event (UUID v4 format).',
    borrower_id  VARCHAR(36)   NOT NULL
        COMMENT 'Foreign key to BORROWERS table. Identifies the borrower exhibiting the refinance signal.',
    signal_type  VARCHAR(30)   NOT NULL
        COMMENT 'Classification of the detected signal. Valid values: RateShop (credit inquiries from other lenders), CompetitorOffer (detected marketing from competitors), PaymentStress (payment behavior degradation suggesting rate sensitivity), LifeEvent (job change, marriage, etc.), CreditScoreChange (significant FICO movement), PropertyValueIncrease (AVM shows equity gain enabling better terms).',
    detected_date DATE         NOT NULL
        COMMENT 'Date the behavioral analytics platform detected and recorded this signal.',
    confidence   FLOAT         NOT NULL
        COMMENT 'Model confidence in signal validity (0.0 to 1.0). Higher values indicate stronger behavioral evidence.',
    details      TEXT
        COMMENT 'Free-text description of the signal with supporting evidence. Example: "3 mortgage rate inquiries detected on credit bureau in past 14 days from competing lenders."',
    actioned     BOOLEAN       NOT NULL DEFAULT FALSE
        COMMENT 'Flag indicating whether a retention action has been taken in response to this signal (TRUE = contacted/offered, FALSE = pending action).',

    CONSTRAINT pk_refinance_signals PRIMARY KEY (signal_id),
    CONSTRAINT fk_refi_signals_borrower FOREIGN KEY (borrower_id) REFERENCES BNK.LENDING.BORROWERS(borrower_id)
)
COMMENT = 'Detected behavioral signals indicating a borrower may be considering refinancing with a competitor. Generated by the behavioral analytics platform using credit bureau trigger data, market intelligence, and internal payment pattern analysis. Used to drive proactive retention outreach.';

-------------------------------------------------------------------------------
-- LENDING_POLICIES
-- Source: Policy management system (Compliance & Operations teams)
-- Grain: One row per policy document version
-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS BNK.LENDING.LENDING_POLICIES (
    policy_id      VARCHAR(36)   NOT NULL
        COMMENT 'Unique identifier for the policy document (UUID v4 format).',
    title          VARCHAR(300)  NOT NULL
        COMMENT 'Official policy title as maintained in the policy management system.',
    category       VARCHAR(30)   NOT NULL
        COMMENT 'Policy classification for retrieval and governance. Valid values: Underwriting, Servicing, Collections, Compliance, Pricing, Modification.',
    effective_date DATE          NOT NULL
        COMMENT 'Date this version of the policy became effective. Supersedes any prior version with the same title.',
    content        TEXT          NOT NULL
        COMMENT 'Full text content of the policy document including scope, requirements, procedures, and exceptions. Indexed by Cortex Search for semantic retrieval.',

    CONSTRAINT pk_lending_policies PRIMARY KEY (policy_id)
)
COMMENT = 'Internal mortgage lending policy documents covering underwriting standards, servicing procedures, collections guidelines, compliance requirements, pricing frameworks, and loan modification criteria. Maintained by Compliance and Operations teams. Indexed by Cortex Search for agent-assisted policy retrieval.';

-------------------------------------------------------------------------------
-- INTERACTION_HISTORY
-- Source: CRM system + telephony platform + digital channel middleware
-- Grain: One row per customer interaction event
-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS BNK.LENDING.INTERACTION_HISTORY (
    interaction_id   VARCHAR(36)   NOT NULL
        COMMENT 'Universally unique identifier for the interaction record (UUID v4 format).',
    borrower_id      VARCHAR(36)   NOT NULL
        COMMENT 'Foreign key to BORROWERS table. Identifies the borrower involved in this interaction.',
    channel          VARCHAR(20)   NOT NULL
        COMMENT 'Communication channel through which the interaction occurred. Valid values: Phone, Email, Branch, Portal (online self-service), Chat (live chat with agent).',
    interaction_date DATE          NOT NULL
        COMMENT 'Date the interaction took place. For multi-day email threads, reflects the date of the most recent message.',
    topic            VARCHAR(30)   NOT NULL
        COMMENT 'Primary topic classification of the interaction. Valid values: PaymentInquiry, RateQuestion, HardshipRequest, RefinanceInquiry, EscrowQuestion, PayoffRequest.',
    summary          TEXT          NOT NULL
        COMMENT 'Agent-written summary of the interaction including key discussion points, borrower requests, and any commitments made. Indexed by Cortex Search for semantic retrieval.',
    agent_name       VARCHAR(100)  NOT NULL
        COMMENT 'Name of the servicing agent or relationship manager who handled the interaction.',
    outcome          VARCHAR(50)
        COMMENT 'Disposition or result of the interaction. Examples: Resolved, EscalatedToSupervisor, FollowUpScheduled, TransferredToCollections, RefinanceApplicationStarted.',

    CONSTRAINT pk_interaction_history PRIMARY KEY (interaction_id),
    CONSTRAINT fk_interactions_borrower FOREIGN KEY (borrower_id) REFERENCES BNK.LENDING.BORROWERS(borrower_id)
)
COMMENT = 'Complete interaction history across all servicing channels for every borrower. Captures phone calls, emails, branch visits, portal activity, and chat sessions with agent summaries. Sourced from CRM, telephony platform, and digital channel middleware. Indexed by Cortex Search for agent-assisted customer history retrieval.';
