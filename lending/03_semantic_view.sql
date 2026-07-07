-- =============================================================================
-- LENDING ANALYTICS — SEMANTIC VIEW
-- Schema: BNK.LENDING
--
-- Defines the semantic model for Cortex Analyst, enabling natural language
-- queries over the lending portfolio data model.
--
-- Uses CREATE OR ALTER (creates if not exists, alters if exists).
-- Clause order: TABLES → RELATIONSHIPS → FACTS → DIMENSIONS → METRICS
-- =============================================================================

USE DATABASE BNK;
USE SCHEMA BNK.LENDING;
USE WAREHOUSE BNK_WH;

CREATE OR ALTER SEMANTIC VIEW BNK.LENDING.SV_LENDING_ANALYTICS
  TABLES (
    borrowers AS BNK.LENDING.BORROWERS
      PRIMARY KEY (borrower_id)
      COMMENT = 'Mortgage borrowers with demographic, financial, and employment attributes.',
    mortgages AS BNK.LENDING.MORTGAGES
      PRIMARY KEY (mortgage_id)
      COMMENT = 'Mortgage loan details including terms, rates, and current status.',
    payments AS BNK.LENDING.PAYMENTS
      PRIMARY KEY (payment_id)
      COMMENT = 'Monthly mortgage payment records with delinquency tracking.',
    risk_scores AS BNK.LENDING.RISK_SCORES
      PRIMARY KEY (score_id)
      COMMENT = 'Model-generated risk scores including PD, LGD, and refinance probability.'
  )
  RELATIONSHIPS (
    borrowers_to_mortgages AS mortgages (borrower_id) REFERENCES borrowers (borrower_id),
    mortgages_to_payments AS payments (mortgage_id) REFERENCES mortgages (mortgage_id),
    borrowers_to_risk AS risk_scores (borrower_id) REFERENCES borrowers (borrower_id)
  )
  FACTS (
    borrowers.annual_income AS annual_income COMMENT = 'Gross annual income in USD.',
    borrowers.credit_score AS credit_score COMMENT = 'FICO credit score (300-850).',
    mortgages.loan_amount AS loan_amount COMMENT = 'Original mortgage principal in USD.',
    mortgages.property_value AS property_value COMMENT = 'Appraised property value at origination in USD.',
    mortgages.interest_rate AS interest_rate COMMENT = 'Annual mortgage interest rate as decimal.',
    mortgages.ltv_ratio AS ltv_ratio COMMENT = 'Loan-to-value ratio at origination (loan_amount / property_value).',
    mortgages.dti_ratio AS dti_ratio COMMENT = 'Debt-to-income ratio at origination.',
    payments.amount_due AS amount_due COMMENT = 'Monthly payment amount due in USD.',
    payments.amount_paid AS amount_paid COMMENT = 'Actual amount paid in USD for this period.',
    payments.days_past_due AS days_past_due COMMENT = 'Number of days past the due date. 0 = on time.',
    risk_scores.probability_of_default AS probability_of_default COMMENT = 'Predicted probability of default (0-1) from the credit risk model.',
    risk_scores.loss_given_default AS loss_given_default COMMENT = 'Expected loss percentage (0-1) if default occurs.',
    risk_scores.refinance_probability AS refinance_probability COMMENT = 'Predicted probability (0-1) that borrower will refinance elsewhere.'
  )
  DIMENSIONS (
    borrowers.borrower_id AS borrower_id COMMENT = 'Unique borrower identifier (UUID).',
    borrowers.first_name AS first_name COMMENT = 'Borrower first name.',
    borrowers.last_name AS last_name COMMENT = 'Borrower last name.',
    borrowers.region AS region COMMENT = 'Geographic region.' SAMPLE_VALUES ('Northeast', 'Southeast', 'Midwest', 'West', 'Southwest') IS_ENUM,
    borrowers.state AS state COMMENT = 'US state of residence.',
    borrowers.employment_status AS employment_status COMMENT = 'Employment status.' SAMPLE_VALUES ('Employed', 'SelfEmployed', 'Retired', 'Unemployed') IS_ENUM,
    mortgages.loan_type AS loan_type COMMENT = 'Mortgage product type.' SAMPLE_VALUES ('Fixed', 'ARM', 'FHA', 'VA', 'Jumbo') IS_ENUM,
    mortgages.term_years AS term_years COMMENT = 'Loan term in years.' SAMPLE_VALUES ('15', '20', '30') IS_ENUM,
    mortgages.status AS mortgage_status COMMENT = 'Current mortgage status.' SAMPLE_VALUES ('Current', 'Delinquent30', 'Delinquent60', 'Delinquent90', 'Default', 'PaidOff', 'Refinanced') IS_ENUM,
    mortgages.origination_date AS origination_date COMMENT = 'Date the mortgage was originated.',
    payments.payment_date AS payment_date COMMENT = 'Date of the payment record.',
    payments.payment_status AS payment_status COMMENT = 'Payment outcome.' SAMPLE_VALUES ('OnTime', 'Late', 'Missed', 'Partial') IS_ENUM,
    risk_scores.score_date AS score_date COMMENT = 'Date the risk score was generated.'
  )
  METRICS (
    borrowers.borrower_count AS COUNT(borrower_id) COMMENT = 'Count of distinct borrowers.',
    borrowers.avg_credit_score AS AVG(credit_score) COMMENT = 'Average FICO credit score.',
    borrowers.avg_income AS AVG(annual_income) COMMENT = 'Average annual income in USD.',
    mortgages.total_portfolio_value AS SUM(loan_amount) COMMENT = 'Total outstanding loan balance across portfolio.',
    mortgages.avg_ltv AS AVG(ltv_ratio) COMMENT = 'Average loan-to-value ratio.',
    mortgages.avg_interest_rate AS AVG(interest_rate) COMMENT = 'Average mortgage interest rate.',
    mortgages.mortgage_count AS COUNT(mortgage_id) COMMENT = 'Number of mortgages in portfolio.',
    payments.avg_days_past_due AS AVG(days_past_due) COMMENT = 'Average days past due across payments.',
    payments.payment_count AS COUNT(payment_id) COMMENT = 'Total payment records.',
    risk_scores.avg_pd AS AVG(probability_of_default) COMMENT = 'Average probability of default.',
    risk_scores.avg_refinance_prob AS AVG(refinance_probability) COMMENT = 'Average refinance probability.'
  )
  COMMENT = 'Semantic view for mortgage lending portfolio analytics. Enables natural language queries about portfolio health, delinquency patterns, borrower segmentation, and refinance propensity via Cortex Analyst.';
