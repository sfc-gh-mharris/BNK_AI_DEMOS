/*=============================================================================
  Customer 360 — Data Population
  Database: BNK | Schema: CUSTOMER_360 | Warehouse: BNK_WH
  
  Populates all tables with synthetic but realistic banking data.
  Uses Snowflake GENERATOR for large tables, INSERT VALUES for reference data.
  
  IMPORTANT: INSERT only. No TRUNCATE, no DELETE, no DROP.
  Run AFTER 01_ddl.sql.
=============================================================================*/

USE DATABASE BNK;
USE SCHEMA CUSTOMER_360;
USE WAREHOUSE BNK_WH;

-------------------------------------------------------------------------------
-- PRODUCTS (50 rows) — Reference data, manually curated
-------------------------------------------------------------------------------
INSERT INTO BNK.CUSTOMER_360.PRODUCTS (product_id, name, category, annual_fee, interest_rate_range, description)
SELECT * FROM VALUES
('P001', 'Essential Checking', 'Checking', 0.00, NULL, 'No-fee everyday checking account with free online bill pay, mobile deposit, and unlimited debit card transactions. No minimum balance required. Ideal for customers seeking a simple, cost-effective checking solution.'),
('P002', 'Premier Checking', 'Checking', 25.00, '0.01% - 0.05% APY', 'Full-featured checking account with interest earnings, free cashier checks, and priority customer service. Annual fee waived with $15,000+ combined balance. Includes free safe deposit box (small).'),
('P003', 'Business Checking', 'Checking', 15.00, NULL, 'Business checking designed for small businesses with up to 500 free transactions per month. Includes merchant services integration, payroll direct deposit, and business debit cards for authorized signers.'),
('P004', 'Commercial Operating Account', 'Checking', 50.00, '0.02% - 0.10% APY', 'High-volume commercial operating account with earnings credit rate (ECR) to offset service charges. Supports ACH origination, positive pay fraud protection, and zero-balance account (ZBA) structures.'),
('P005', 'Student Checking', 'Checking', 0.00, NULL, 'Fee-free checking for students aged 16-24. No minimum balance, free ATM network access, and built-in budgeting tools in the mobile app. Automatically converts to Essential Checking at age 25.'),
('P006', 'Standard Savings', 'Savings', 0.00, '0.50% - 1.00% APY', 'Traditional savings account with competitive interest rate. Six withdrawal limit per statement cycle per Regulation D. $300 minimum balance to avoid $5 monthly service fee.'),
('P007', 'High-Yield Savings', 'Savings', 0.00, '3.75% - 4.25% APY', 'Premium savings account offering top-tier APY for balances over $10,000. Online and mobile access. Rate tiers: $0-$9,999 at 3.75%, $10,000+ at 4.25%. No monthly fees.'),
('P008', 'Business Savings', 'Savings', 0.00, '1.00% - 2.50% APY', 'Business savings account with tiered interest rates based on balance. Integrates with Business Checking for automated sweep. $1,000 minimum to open. Interest compounded daily, paid monthly.'),
('P009', 'Kids Savings', 'Savings', 0.00, '2.00% APY', 'Savings account for children under 18 with parental joint ownership. Flat 2.00% APY regardless of balance. Includes financial literacy tools and goal-setting features in the mobile app.'),
('P010', 'Holiday Club Savings', 'Savings', 0.00, '1.50% APY', 'Goal-based savings account that automatically distributes accumulated balance in November for holiday spending. Fixed 1.50% APY. Automatic weekly or bi-weekly transfers from linked checking.'),
('P011', 'Platinum Rewards Visa', 'CreditCard', 95.00, '16.99% - 24.99% APR', 'Premium rewards credit card earning 3X points on travel and dining, 2X on groceries, 1X on everything else. Includes travel insurance, purchase protection, and TSA PreCheck credit. $5,000 minimum credit line.'),
('P012', 'Cash Back Mastercard', 'CreditCard', 0.00, '19.99% - 26.99% APR', 'No annual fee cash back card with 2% back on all purchases. Cash back redeemed as statement credit or deposit to savings. $1,000 minimum credit line. Ideal for everyday spending.'),
('P013', 'Business Rewards Card', 'CreditCard', 150.00, '15.99% - 22.99% APR', 'Business credit card with 3X points on advertising, shipping, and internet services. Employee cards at no extra cost. Detailed expense reporting and QuickBooks integration. Up to $100,000 credit line.'),
('P014', 'Secured Credit Card', 'CreditCard', 35.00, '22.99% APR', 'Credit-building card secured by a cash deposit equal to the credit line ($200-$5,000). Reports to all three bureaus. Automatic review for graduation to unsecured card after 12 months of on-time payments.'),
('P015', 'Student Credit Card', 'CreditCard', 0.00, '21.99% APR', 'First credit card for college students with no annual fee and 1% cash back. $500-$2,000 credit line. Includes free FICO score monitoring and responsible spending alerts. No co-signer required with verified enrollment.'),
('P016', 'Money Market Select', 'MoneyMarket', 0.00, '3.50% - 4.00% APY', 'High-yield money market account combining savings rates with checking flexibility. Includes check-writing privileges (6/month) and debit card. $25,000 minimum for top tier rate. FDIC insured up to $250,000.'),
('P017', 'Business Money Market', 'MoneyMarket', 0.00, '2.75% - 3.50% APY', 'Business money market for operating reserves and short-term cash management. Tiered rates start at $50,000. Sweep capability from Business Checking. Unlimited deposits, six withdrawals per cycle.'),
('P018', 'Premium Money Market', 'MoneyMarket', 0.00, '4.00% - 4.50% APY', 'Top-tier money market for high-net-worth clients with $100,000+ balances. Dedicated relationship manager, same-day wire transfers, and priority rate matching. Rate guaranteed for 90 days from opening.'),
('P019', '6-Month CD', 'CD', 0.00, '4.50% APY', 'Short-term certificate of deposit with competitive fixed rate. $1,000 minimum deposit. Early withdrawal penalty: 90 days of interest. Auto-renews at maturity to same term at prevailing rate.'),
('P020', '12-Month CD', 'CD', 0.00, '4.75% APY', 'One-year certificate of deposit with guaranteed fixed rate. $1,000 minimum. Early withdrawal penalty: 180 days of interest. Rate locked at funding regardless of market changes.'),
('P021', '24-Month CD', 'CD', 0.00, '4.25% APY', 'Two-year certificate of deposit for longer-term savings goals. $1,000 minimum. One penalty-free withdrawal allowed after 12 months. Includes bump-up option: raise rate once if rates increase during term.'),
('P022', '60-Month CD', 'CD', 0.00, '4.00% APY', 'Five-year certificate of deposit offering rate certainty for long-term savings. $5,000 minimum. Early withdrawal penalty: 365 days of interest. Best for funds not needed for 5+ years.'),
('P023', 'CD Ladder Builder', 'CD', 0.00, '4.25% - 4.75% APY', 'Structured CD product that automatically divides deposit across 3, 6, 12, and 24-month terms to balance rate and liquidity. $10,000 minimum total investment. Each rung auto-renews independently.'),
('P024', 'Managed Investment Portfolio', 'Investment', 0.00, '0.50% advisory fee', 'Professionally managed diversified investment portfolio. Asset allocation based on risk profile assessment. Quarterly rebalancing. Access to institutional-class mutual funds and ETFs. $25,000 minimum.'),
('P025', 'Self-Directed Brokerage', 'Investment', 0.00, '$0 online trades', 'Self-directed brokerage account with commission-free online stock and ETF trades. Access to research, screeners, and analyst reports. Options trading available with approval. No account minimum.'),
('P026', 'Retirement IRA', 'Investment', 0.00, 'Varies by allocation', 'Traditional and Roth IRA options with broad investment selection including mutual funds, ETFs, stocks, and bonds. Annual contribution limits per IRS guidelines. No account fees. Rollover assistance available.'),
('P027', 'Education Savings 529', 'Investment', 0.00, 'Varies by allocation', 'Tax-advantaged 529 college savings plan with age-based and static portfolio options. State tax deduction where applicable. Can be used for K-12 tuition, college, and student loan repayment.'),
('P028', 'Robo-Advisor Account', 'Investment', 0.00, '0.25% advisory fee', 'Automated investment management using algorithmic portfolio construction. Tax-loss harvesting included. $500 minimum to start. Risk-adjusted returns targeting market benchmarks net of fees.'),
('P029', 'Private Wealth Management', 'Investment', 0.00, '0.75% - 1.25% advisory fee', 'Comprehensive wealth management for high-net-worth individuals and families. Dedicated team including portfolio manager, financial planner, and tax advisor. $500,000 minimum. Estate and trust services included.'),
('P030', 'Essential Line of Credit', 'Checking', 0.00, 'Prime + 2.00%', 'Unsecured personal line of credit linked to checking for overdraft protection and planned expenses. Credit lines from $1,000 to $25,000. Interest only on amounts drawn. No annual fee.'),
('P031', 'Home Equity Line', 'Checking', 50.00, 'Prime + 0.00% - 1.50%', 'Secured line of credit backed by home equity. Draw period of 10 years followed by 20-year repayment. Combined loan-to-value up to 85%. Interest may be tax-deductible (consult tax advisor).'),
('P032', 'Premier Savings Plus', 'Savings', 0.00, '4.00% - 4.50% APY', 'Premium savings tier for relationship clients with $50,000+ across all accounts. Highest published savings rate, unlimited transactions, and dedicated service line. Relationship pricing on loans.'),
('P033', 'Digital-Only Savings', 'Savings', 0.00, '4.30% APY', 'Online-only savings account with industry-leading flat rate regardless of balance. No branch access but full mobile and web functionality. Transfer to linked checking in 1 business day.'),
('P034', 'Visa Signature Infinite', 'CreditCard', 495.00, '14.99% - 21.99% APR', 'Ultra-premium credit card with 5X points on travel booked through our portal, airport lounge access (Priority Pass), $300 annual travel credit, and personal concierge service. $10,000 minimum credit line.'),
('P035', 'Balance Transfer Card', 'CreditCard', 0.00, '0% intro APR 18mo', 'Promotional balance transfer card with 0% APR for 18 months on transferred balances. 3% transfer fee. No annual fee. Ideal for consolidating high-interest credit card debt.'),
('P036', 'Commercial Line of Credit', 'Checking', 0.00, 'SOFR + 2.00% - 3.50%', 'Revolving credit facility for businesses with $5M+ annual revenue. Lines from $250,000 to $10,000,000. Secured or unsecured based on financial strength. Annual review and renewal.'),
('P037', 'Business Term Loan', 'Checking', 0.00, '6.50% - 9.00% fixed', 'Fixed-rate term loan for business expansion, equipment purchase, or commercial real estate. Terms from 3 to 10 years. SBA preferred lender for loans up to $5,000,000.'),
('P038', 'Jumbo Money Market', 'MoneyMarket', 0.00, '4.25% - 4.75% APY', 'Institutional-grade money market for deposits over $500,000. Negotiable rate based on relationship size. Full liquidity with same-day access. Ideal for corporate treasury and municipal deposits.'),
('P039', 'Bump-Up CD', 'CD', 0.00, '4.00% - 4.50% APY', 'Certificate of deposit with one-time rate increase option during the term. If market rates rise, request a bump to current rate. Available in 12 and 24-month terms. $5,000 minimum.'),
('P040', 'No-Penalty CD', 'CD', 0.00, '3.75% APY', 'Flexible certificate of deposit allowing full withdrawal without penalty after the first 7 days. 11-month term. $1,000 minimum. Ideal for customers who want CD rates with savings-like flexibility.'),
('P041', 'Trust Services', 'Investment', 0.00, '0.50% - 1.00% trustee fee', 'Professional trust administration for revocable living trusts, irrevocable trusts, and testamentary trusts. Fiduciary oversight, annual accountings, and tax filing. Paired with investment management.'),
('P042', 'Custodial Account (UTMA)', 'Investment', 0.00, 'Varies by allocation', 'Uniform Transfers to Minors Act account for gifting assets to children. Managed by adult custodian until child reaches age of majority (18 or 21 per state). Flexible investment options.'),
('P043', 'Health Savings Account', 'Savings', 0.00, '1.00% - 3.00% APY', 'Tax-advantaged HSA for individuals with high-deductible health plans. Triple tax benefit: deductible contributions, tax-free growth, tax-free qualified withdrawals. Investment option for balances over $2,000.'),
('P044', 'Foreign Currency Account', 'Savings', 25.00, 'Varies by currency', 'Multi-currency deposit account supporting EUR, GBP, JPY, CHF, CAD, and AUD. Competitive exchange rates, wire transfers in native currency, and hedging capabilities for businesses.'),
('P045', 'Payroll Solutions', 'Checking', 0.00, 'N/A', 'Full-service payroll management for businesses with 1-500 employees. Direct deposit, tax filing, W-2 generation, and benefits administration. Integrates with Business Checking for funding.'),
('P046', 'Merchant Services', 'Checking', 0.00, '2.50% + $0.10 per txn', 'Payment processing for businesses accepting credit/debit cards. Point-of-sale terminals, e-commerce gateway, and mobile card readers. Next-day funding to Business Checking. PCI-compliant.'),
('P047', 'Commercial Real Estate Loan', 'Checking', 0.00, '6.00% - 8.50%', 'Financing for commercial property acquisition, construction, or refinance. Loan amounts $500,000 to $25,000,000. Terms up to 25 years with 5 or 10-year rate resets. LTV up to 75%.'),
('P048', 'Treasury Management', 'Checking', 0.00, 'Custom pricing', 'Enterprise cash management platform with real-time visibility, automated sweeps, controlled disbursement, lockbox processing, and integrated payables/receivables. For businesses with $10M+ in annual revenue.'),
('P049', 'Private Banking Package', 'Checking', 0.00, 'Relationship pricing', 'All-inclusive banking package for high-net-worth clients ($1M+ in assets). Includes Premier Checking, High-Yield Savings, Platinum Rewards Visa, and dedicated Private Banker. All fees waived.'),
('P050', 'Digital Wallet Integration', 'Checking', 0.00, NULL, 'Seamless integration with Apple Pay, Google Pay, and Samsung Pay for all debit and credit cards. Includes virtual card numbers for secure online shopping and real-time transaction notifications.')
;

-------------------------------------------------------------------------------
-- POLICIES (30 rows) — Full-text policy documents
-------------------------------------------------------------------------------
INSERT INTO BNK.CUSTOMER_360.POLICIES (policy_id, title, category, effective_date, content)
SELECT * FROM VALUES
('POL001', 'Overdraft Fee Policy', 'Fees', '2024-01-01'::DATE, 'POLICY: Overdraft Fee Policy. EFFECTIVE DATE: January 1, 2024. SCOPE: Applies to all consumer and small business checking accounts. OVERDRAFT FEE: A $35.00 overdraft fee is assessed per transaction when the account balance falls below zero and the transaction is paid. Maximum of 3 overdraft fees per business day ($105 daily cap). OVERDRAFT PROTECTION: Customers enrolled in overdraft protection will have funds automatically transferred from a linked savings account or line of credit. A $12.00 transfer fee applies per transfer (waived for Premier Checking customers). DE MINIMIS THRESHOLD: No overdraft fee is charged if the account is overdrawn by $5.00 or less at end of day, or if the transaction causing the overdraft is $5.00 or less. FEE WAIVER GUIDELINES: Branch managers and call center supervisors may waive up to 2 overdraft fees per customer per rolling 12-month period as a courtesy. Additional waivers require regional manager approval. Waivers should be documented in customer notes. OPT-OUT: Customers may opt out of overdraft coverage for one-time debit card transactions and ATM withdrawals. Recurring transactions (ACH, checks) are not eligible for opt-out per Regulation E.'),
('POL002', 'Dispute Resolution Process', 'Disputes', '2024-03-15'::DATE, 'POLICY: Consumer Transaction Dispute Resolution. EFFECTIVE DATE: March 15, 2024. SCOPE: Covers all disputed debit card, credit card, and ACH transactions for consumer accounts. FILING A DISPUTE: Customers may file a dispute through any channel (branch, phone, online, mobile app, or written correspondence). Disputes must be filed within 60 days of the statement date on which the transaction appeared. PROVISIONAL CREDIT: For debit card disputes over $50, provisional credit must be issued within 10 business days of the dispute filing. For credit card disputes, the charge is placed in dispute status and not subject to interest or minimum payment. INVESTIGATION TIMELINE: The bank has 45 calendar days to complete the investigation for domestic transactions, and 90 calendar days for international transactions or new accounts (open less than 30 days). RESPONSE TO CUSTOMER: Written determination must be sent within 3 business days of completing the investigation. If the dispute is denied, the letter must explain the reason and inform the customer of their right to request documentation. ESCALATION: If a customer disagrees with the determination, they may request a re-investigation by writing to the Customer Resolution Department within 10 days of receiving the determination letter.'),
('POL003', 'Customer Privacy and Data Sharing', 'Privacy', '2024-01-01'::DATE, 'POLICY: Customer Privacy and Data Sharing. EFFECTIVE DATE: January 1, 2024. SCOPE: Governs collection, use, storage, and sharing of customer personal information across all channels and business lines. DATA COLLECTION: We collect personal information necessary to provide banking services including: name, address, SSN/TIN, date of birth, employment information, income, and transaction history. PERMITTED USES: Customer data may be used for: (1) Account servicing and transaction processing, (2) Fraud prevention and security, (3) Regulatory compliance (BSA/AML, CRA, HMDA), (4) Marketing of bank products (with opt-out), (5) Credit decisions. DATA SHARING - AFFILIATES: We may share customer data with affiliated companies within our corporate family for marketing purposes. Customers may opt out of affiliate marketing. DATA SHARING - THIRD PARTIES: We do not sell customer personal information to third parties. We may share information with: (1) Service providers under contract, (2) Joint marketing partners, (3) As required by law or legal process. DATA RETENTION: Customer records are retained for 7 years after account closure per federal regulation. Transaction records retained for 5 years. CUSTOMER RIGHTS: Customers have the right to: access their personal information, correct inaccuracies, opt out of marketing, and request explanation of automated decisions.'),
('POL004', 'Wire Transfer Compliance', 'Compliance', '2024-06-01'::DATE, 'POLICY: Wire Transfer Compliance and Controls. EFFECTIVE DATE: June 1, 2024. SCOPE: All domestic and international wire transfers originated by or received by bank customers. CTR REQUIREMENT: Cash deposits or withdrawals related to wire transfers exceeding $10,000 require Currency Transaction Report (CTR) filing with FinCEN within 15 days. Structuring detection algorithms monitor for patterns designed to avoid CTR thresholds. OFAC SCREENING: All wire transfers are screened against OFAC Specially Designated Nationals (SDN) list and consolidated sanctions lists in real-time before processing. Matches result in automatic hold pending BSA/AML team review. DOLLAR THRESHOLDS: Under $3,000 standard processing; $3,000-$10,000 full record retention; Over $10,000 CTR if cash-funded; Over $50,000 additional management approval; Over $100,000 same-day callback verification to originator. INTERNATIONAL WIRES: Must include complete originator and beneficiary information per Travel Rule. SWIFT messaging standards apply.'),
('POL005', 'Fee Schedule - Consumer Accounts', 'Fees', '2024-01-01'::DATE, 'POLICY: Consumer Account Fee Schedule. EFFECTIVE DATE: January 1, 2024. MONTHLY SERVICE FEES: Essential Checking $0; Premier Checking $25/month (waived with $15,000+ combined balance); Standard Savings $5/month (waived with $300+ balance); High-Yield Savings $0; Money Market Select $15/month (waived with $10,000+ balance). ATM FEES: In-network free; Out-of-network domestic $3.00; International ATMs $5.00 + 3% foreign transaction fee; Premier Checking 4 free out-of-network per month. WIRE TRANSFER FEES: Domestic incoming $15; Domestic outgoing $30 online, $45 branch; International incoming $15; International outgoing $50 online, $65 branch. OTHER FEES: Cashier check $10; Stop payment $35; Account research $25/hour; Paper statement $3/month; Returned deposit item $15; Account closure within 90 days $25.'),
('POL006', 'Anti-Money Laundering Program', 'Compliance', '2024-01-01'::DATE, 'POLICY: Anti-Money Laundering (AML) and Bank Secrecy Act (BSA) Program. EFFECTIVE DATE: January 1, 2024. SCOPE: All employees, contractors, and business lines. CUSTOMER IDENTIFICATION PROGRAM (CIP): All new customers must be verified using government-issued photo identification and one additional form of identification. CUSTOMER DUE DILIGENCE (CDD): Risk-based due diligence performed at account opening and periodically thereafter. Risk factors include: type of business, geographic location, transaction patterns, and PEP status. High-risk customers require Enhanced Due Diligence (EDD). BENEFICIAL OWNERSHIP: For legal entity customers, beneficial owners (25%+ equity or one controlling person) must be identified and verified per FinCEN rules. SUSPICIOUS ACTIVITY REPORTING: Employees must report suspicious activity to the BSA team. The BSA team evaluates and files Suspicious Activity Reports (SARs) with FinCEN within 30 days when warranted. Tipping off is prohibited. TRAINING: All employees complete annual BSA/AML training. RECORD RETENTION: All CIP documentation retained for 5 years after account closure.'),
('POL007', 'Credit Card Rewards Program', 'Products', '2024-01-01'::DATE, 'POLICY: Credit Card Rewards Program Terms and Conditions. EFFECTIVE DATE: January 1, 2024. SCOPE: All credit cards enrolled in rewards programs. POINT EARNING: Points earned on net purchases (purchases minus returns/credits). Bonus categories determined by merchant category code (MCC). Cash advances, balance transfers, fees, and interest do not earn points. Points credited within 1-2 billing cycles. POINT EXPIRATION: Points expire 36 months from month earned if account has no qualifying purchase activity in 12 consecutive months. Active accounts retain points indefinitely. REDEMPTION OPTIONS: Travel 1 point = $0.015 value; Statement credit 1 point = $0.01; Gift cards 1 point = $0.01; Cash deposit 1 point = $0.01. MINIMUM REDEMPTION: 2,500 points for statement credit, 5,000 points for travel booking. PROGRAM CHANGES: Bank reserves right to modify earning rates and redemption values with 30 days advance notice.'),
('POL008', 'Branch Operations Standards', 'Operations', '2024-02-01'::DATE, 'POLICY: Branch Operations Standards. EFFECTIVE DATE: February 1, 2024. SCOPE: All retail branch locations. HOURS: Standard Monday-Friday 9:00 AM-5:00 PM, Saturday 9:00 AM-1:00 PM. Extended hours branches Monday-Friday 8:00 AM-7:00 PM. CASH HANDLING: Teller drawers limited to $50,000; Vault access requires dual control; Bait money tracked daily; Counterfeit detection on all $50 and $100 bills. CUSTOMER SERVICE STANDARDS: Greet within 30 seconds; Wait time target under 5 minutes; Platform same-day availability for routine requests; Complex requests scheduled within 2 business days; Complaints escalated to branch manager within 1 business day. SECURITY: Opening/closing requires minimum 2 employees; Panic buttons tested monthly; Camera systems record minimum 30 days.'),
('POL009', 'Digital Banking Security', 'Compliance', '2024-04-01'::DATE, 'POLICY: Digital Banking Security Standards. EFFECTIVE DATE: April 1, 2024. SCOPE: Online banking, mobile banking, and all digital channels. AUTHENTICATION: Multi-factor authentication (MFA) required for first-time device login and high-risk transactions. MFA methods: SMS one-time code, authenticator app, biometric, hardware security key. Session timeout: 15 minutes inactivity. Maximum login attempts: 5 before lockout. TRANSACTION LIMITS (per 24 hours): Internal transfers $250,000; External transfers (ACH) $25,000; Zelle/P2P $2,500; Bill pay $50,000; Mobile deposit $10,000 per check, $25,000 daily. FRAUD MONITORING: Real-time ML transaction scoring; Device fingerprinting; Geographic anomaly detection; Velocity checks; Known fraud pattern matching. CUSTOMER NOTIFICATION: Immediate push/email for login from new device, password change, contact info change, and external transfer setup.'),
('POL010', 'Account Closure Procedures', 'Operations', '2024-01-01'::DATE, 'POLICY: Account Closure Procedures. EFFECTIVE DATE: January 1, 2024. SCOPE: All deposit and credit accounts. CUSTOMER-INITIATED CLOSURE: Checking/Savings available via branch, phone, or written request. Credit cards by phone or written request (must be paid in full). CDs subject to early withdrawal penalty. BANK-INITIATED CLOSURE: Zero-balance inactive 12+ months with 30-day notice; Suspicious activity immediate closure by BSA Officer; Repeated overdrafts (5+ in 60 days) with 30-day notice. RESIDUAL BALANCE: Positive balance mailed as cashier check within 10 business days. Negative balance sent to collections after 60 days. ESCHEATMENT: Dormant accounts with no customer contact for 3-5 years escheated to state unclaimed property fund per applicable state law. RECORD RETENTION: Account records retained 7 years after closure per BSA requirements.'),
('POL011', 'Complaint Management Process', 'Operations', '2024-03-01'::DATE, 'POLICY: Customer Complaint Management. EFFECTIVE DATE: March 1, 2024. SCOPE: All customer complaints received through any channel. DEFINITION: A complaint is any expression of dissatisfaction regarding a product, service, policy, or employee that requires investigation or resolution beyond routine service. RESPONSE TIMELINES: Verbal acknowledgment same day; Written acknowledgment within 3 business days; Investigation and resolution within 15 business days (30 days for complex cases); Regulatory complaints (CFPB/OCC) within regulator timeframe. ESCALATION PATH: (1) Front-line employee, (2) Team supervisor within 1 day, (3) Department manager within 3 days, (4) Customer Resolution Department within 5 days, (5) Executive Office final escalation. ROOT CAUSE ANALYSIS: All complaints tracked in CRM. Monthly reporting on volume, categories, resolution time, and trends. Systemic issues escalated to product/policy owners.'),
('POL012', 'Consumer Lending Standards', 'Products', '2024-01-01'::DATE, 'POLICY: Consumer Lending Underwriting Standards. EFFECTIVE DATE: January 1, 2024. SCOPE: All consumer credit products including credit cards, personal loans, lines of credit, auto loans, and HELOCs. CREDIT SCORE REQUIREMENTS: Prime 720+ FICO (best rates); Near-prime 660-719 (standard rates); Subprime 580-659 (higher rates, may require collateral); Below 580 generally declined unless secured. DEBT-TO-INCOME: Maximum DTI unsecured 43%; Maximum DTI secured 50%. COLLATERAL: Auto loans LTV up to 100% new, 90% used 1-3 years; HELOC CLTV up to 85%; CD-secured up to 95% of CD balance. INCOME VERIFICATION: Loans under $50,000 stated income acceptable with 720+ score; Loans $50,000+ require tax returns or pay stubs. FAIR LENDING: All decisions comply with ECOA and Fair Housing Act.'),
('POL013', 'Check Hold Policy', 'Operations', '2024-01-01'::DATE, 'POLICY: Funds Availability and Check Hold Policy (Regulation CC). EFFECTIVE DATE: January 1, 2024. STANDARD AVAILABILITY: Cash and electronic same day; Direct deposit day of receipt; U.S. Treasury checks next business day; Local checks 2 business days (first $225 next day); Non-local checks 5 business days (first $225 next day). EXCEPTION HOLDS: New accounts (under 30 days) up to 9 business days; Repeated overdrafts up to 7 days; Large deposits over $5,525 excess held up to 7 days. NOTIFICATION: Written or electronic notice at time of deposit specifying hold amount and availability date. MOBILE DEPOSIT: Follows non-local check schedule. Cutoff 8:00 PM ET for same-day processing. Customer must retain physical check 14 days then securely destroy.'),
('POL014', 'Business Account Requirements', 'Products', '2024-01-15'::DATE, 'POLICY: Business Account Opening Requirements. EFFECTIVE DATE: January 15, 2024. DOCUMENTATION: Sole Proprietorship requires government ID and DBA certificate; Partnership requires partnership agreement and all partner IDs; LLC requires Articles of Organization, Operating Agreement, and member IDs; Corporation requires Articles of Incorporation, Bylaws, Corporate Resolution, and authorized signer IDs; Non-Profit requires 501(c) determination letter, Bylaws, and Board Resolution. BENEFICIAL OWNERSHIP: Must identify all individuals owning 25%+ and at least one control person per FinCEN CDD Rule. HIGH-RISK BUSINESSES: Money services businesses, marijuana-related businesses, cryptocurrency exchanges, and shell companies require enhanced review and BSA Officer approval.'),
('POL015', 'Interest Rate Adjustment Policy', 'Products', '2024-07-01'::DATE, 'POLICY: Interest Rate Adjustment Policy. EFFECTIVE DATE: July 1, 2024. DEPOSIT RATES: Set by Treasury based on Fed Funds Rate and competitive analysis. May change without advance notice. CD rates fixed for stated term. LENDING RATES: Variable-rate loans tied to Prime Rate (WSJ). Adjustments on first day of billing cycle following Prime change. HELOC lifetime cap: initial rate + 8%. Credit card rate changes require 45-day advance notice per CARD Act except index-based changes. PROMOTIONAL RATES: Guaranteed for stated period, then revert to standard rate. RELATIONSHIP PRICING: $100,000+ combined balance eligible for +0.25% deposit enhancement and -0.25% lending discount.'),
('POL016', 'Elder Financial Exploitation Prevention', 'Compliance', '2024-02-01'::DATE, 'POLICY: Elder Financial Exploitation Prevention. EFFECTIVE DATE: February 1, 2024. SCOPE: All customer-facing employees. Applies to customers aged 65+ and vulnerable adults. RED FLAGS: Sudden changes in banking patterns; Caregiver directing transactions; Customer appears confused or under duress; Sudden changes to beneficiaries or POA; Customer cannot explain large transactions; Third party insisting on presence. RESPONSE PROTOCOL: (1) Engage customer privately, (2) Ask open-ended questions, (3) If exploitation suspected delay transaction up to 15 business days, (4) File internal suspicious activity referral, (5) Report to Adult Protective Services as required by state mandatory reporting laws. TRAINING: Annual elder exploitation awareness training for all customer-facing employees. SAFE HARBOR: Employees acting in good faith protected from liability per federal and state provisions.'),
('POL017', 'Mobile Deposit Policy', 'Operations', '2024-01-01'::DATE, 'POLICY: Mobile Remote Deposit Capture. EFFECTIVE DATE: January 1, 2024. ELIGIBILITY: Account open 30+ days (waived for Premier); No deposit fraud history; Account in good standing. DEPOSIT LIMITS: Consumer Standard $5,000 per check, $10,000 per day, $25,000 per month; Consumer Premier $10,000/$25,000/$50,000; Business $25,000/$50,000/$100,000. ACCEPTABLE ITEMS: Personal checks, business checks, cashier checks, money orders, government checks. NOT ACCEPTED: International checks, third-party checks, previously deposited items. IMAGE QUALITY: Clear, well-lit, all four corners visible. Endorsement must include signature and For Mobile Deposit Only. FUNDS AVAILABILITY: Standard 2 business day hold per Reg CC. First $225 available next business day.'),
('POL018', 'Dormant Account Policy', 'Operations', '2024-01-01'::DATE, 'POLICY: Dormant and Abandoned Account Policy. EFFECTIVE DATE: January 1, 2024. DEFINITIONS: Inactive = no customer-initiated transaction for 6 months; Dormant = no activity for 12 months; Abandoned = no customer contact for state-specified dormancy period (3-5 years). PROCEDURES: At 6 months inactive send reactivation letter; At 12 months restrict electronic access, apply $5/month dormant fee; At 18 months final notice via certified mail; At state dormancy period escheat to state unclaimed property fund. REACTIVATION: Customer may reactivate at any time prior to escheatment by verifying identity and performing a transaction. All dormant fees reversed upon reactivation. ESCHEATMENT REPORTING: Annual report filed with each applicable state by November 1.'),
('POL019', 'Safe Deposit Box Procedures', 'Operations', '2024-01-01'::DATE, 'POLICY: Safe Deposit Box Operations. EFFECTIVE DATE: January 1, 2024. RENTAL: Small (3x5) $50/year; Medium (5x10) $100/year; Large (10x10) $200/year; Jumbo $350/year. Premier Checking customers small box free. ACCESS: During branch hours only. Two-key system. Customer must present valid ID and sign access log. FORCED OPENING: Non-payment 90+ days with 30-day notice; Court order immediate; Death of sole renter requires letters testamentary; Lost key $150 drill fee. LIABILITY: Bank not liable for loss except in cases of negligence. Contents not FDIC insured. PROHIBITED ITEMS: Hazardous materials, perishable items, firearms, illegal substances.'),
('POL020', 'Electronic Fund Transfer Rights', 'Compliance', '2024-01-01'::DATE, 'POLICY: Electronic Fund Transfer Error Resolution (Regulation E). EFFECTIVE DATE: January 1, 2024. SCOPE: All EFTs including debit card, ATM, ACH, recurring payments, and P2P. CUSTOMER LIABILITY: Reported within 2 business days max $50; After 2 days but within 60 days of statement max $500; Not reported within 60 days of statement unlimited liability for subsequent unauthorized transfers. ERROR RESOLUTION: Customer must notify within 60 days of statement; Bank investigates within 10 business days (20 for new accounts); Provisional credit if investigation extends beyond 10 days; Conclude within 45 days (90 for POS, foreign, or new account); Written results within 3 business days of determination. IF ERROR NOT CONFIRMED: Reverse provisional credit with 5 business days written notice.'),
('POL021', 'Lost/Stolen Card Procedures', 'Operations', '2024-05-01'::DATE, 'POLICY: Credit Card Lost/Stolen Response. EFFECTIVE DATE: May 1, 2024. REPORTING: 24/7 via phone, mobile app, online banking, or branch. IMMEDIATE ACTIONS: (1) Card blocked within 30 seconds, (2) Fraud alert placed, (3) Last 48 hours reviewed with customer, (4) Provisional credit for unauthorized charges, (5) Replacement card ordered (express 1-2 days, standard 5-7 days). ZERO LIABILITY: Customers not liable for unauthorized transactions when reported promptly. DIGITAL WALLET: Blocking physical card disables digital wallet token. New token provisioned with replacement. RECURRING PAYMENTS: Customer advised to update credentials. Bank provides list of identified recurring merchants. FRAUD INVESTIGATION: Unauthorized transactions forwarded to fraud team. Law enforcement referral when fraud exceeds $5,000.'),
('POL022', 'Communication Preferences', 'Privacy', '2024-03-01'::DATE, 'POLICY: Customer Communication and Marketing Preferences. EFFECTIVE DATE: March 1, 2024. REQUIRED COMMUNICATIONS (cannot opt out): Regulatory notices, fraud/security alerts, account statements, tax documents, legal notices. MARKETING PREFERENCES (opt-in/out): Product offers, partner offers, market research, educational content. OPT-OUT COMPLIANCE: Email processed within 10 business days (CAN-SPAM); Phone do-not-call within 30 days; SMS STOP keyword immediate; Physical mail within 30 days. FREQUENCY CAPS: Email marketing max 2/week; SMS marketing max 4/month; Push notifications max 3/week; Phone marketing max 1/month; Physical mail max 2/month.'),
('POL023', 'Power of Attorney Acceptance', 'Compliance', '2024-01-01'::DATE, 'POLICY: Power of Attorney Acceptance and Administration. EFFECTIVE DATE: January 1, 2024. ACCEPTABLE FORMS: Durable Financial POA, Springing POA (requires triggering event certification), Limited/Special POA, Military POA. VERIFICATION: Original or certified copy; Notarized or witnessed per state; Government ID of agent; Branch manager review; If older than 6 months, certification of continued validity; Legal review for out-of-state or international documents. PROHIBITED ACTIONS BY AGENT: Changing beneficiaries (unless specifically granted); Opening new credit products (unless specifically granted); Closing accounts and transferring all funds to agent personal account (triggers investigation). MONITORING: POA accounts flagged for enhanced transaction monitoring.'),
('POL024', 'Fraud Prevention Program', 'Compliance', '2024-04-01'::DATE, 'POLICY: Fraud Prevention and Detection Program. EFFECTIVE DATE: April 1, 2024. DETECTION LAYERS: (1) Real-time ML transaction scoring, (2) Rule-based alerts, (3) Behavioral analytics, (4) Device intelligence, (5) Network analysis. TRANSACTION ALERTS TRIGGERING REVIEW: Card-present 500+ miles from last transaction within 2 hours; Card-not-present 3X average amount; Multiple declines followed by success; First-time merchant category over $500; International with no travel notification; Wire to new beneficiary over $10,000. CUSTOMER NOTIFICATION: Text/push alert for high-risk scores. Customer confirms or denies. If denied: immediate block, case created. No response 30 minutes: outbound call. FALSE POSITIVE TARGET: Below 5%. Weekly rule review for high false-positive generators.'),
('POL025', 'Accessibility Standards', 'Operations', '2024-01-01'::DATE, 'POLICY: Accessibility Standards for Banking Services. EFFECTIVE DATE: January 1, 2024. PHYSICAL (ADA): All branches ADA compliant; ATMs with audio and Braille; Service animals permitted; Accessible parking. DIGITAL (WCAG 2.1 AA): Screen reader compatible; Keyboard navigable; Color contrast 4.5:1; Captions on video; Alt text on images. COMMUNICATIONS: Large print statements available; Braille statements 5-7 day delivery; Audio statements via phone; Translation in 200+ languages; Spanish on ATMs and IVR. SERVICE ACCOMMODATIONS: Extended appointments; Video relay service for deaf/hard-of-hearing; Home visits for homebound (maintenance only). TESTING: Quarterly digital audits; Annual physical inspections; Customer feedback remediated within 30 days.'),
('POL026', 'Beneficial Ownership Updates', 'Compliance', '2024-05-01'::DATE, 'POLICY: Beneficial Ownership and CDD Refresh. EFFECTIVE DATE: May 1, 2024. SCOPE: All legal entity customers. INITIAL COLLECTION: Identify all individuals owning 25%+ and at least one control person. TRIGGER-BASED REFRESH: Customer reports ownership change; Significant transaction pattern change; Adverse media hit; Business type change; State filing shows new officers; Periodic review cycle. PERIODIC REVIEW: High-risk annual; Medium-risk every 2 years; Low-risk every 3 years. NON-COMPLIANCE: If not provided within 60 days, account restricted. After 120 days, escalation to BSA Officer for potential closure.'),
('POL027', 'Loan Modification and Hardship', 'Products', '2024-01-01'::DATE, 'POLICY: Loan Modification and Financial Hardship Program. EFFECTIVE DATE: January 1, 2024. ELIGIBILITY: Documented hardship (job loss, medical emergency, natural disaster, divorce, death); Account current or less than 90 days past due; Minimum 12 months payment history. OPTIONS: (1) Payment Deferral 1-3 payments, (2) Rate Reduction temporary or permanent, (3) Term Extension, (4) Principal Forbearance, (5) Settlement (requires VP approval, minimum 30% recovery). CREDIT REPORTING: Deferrals during declared disasters no adverse reporting; Modifications reported current if paying per modified terms; Settlements reported as settled for less than full amount. APPLICATION: Decision within 15 business days.'),
('POL028', 'Data Retention and Destruction', 'Privacy', '2024-01-01'::DATE, 'POLICY: Data Retention and Secure Destruction. EFFECTIVE DATE: January 1, 2024. RETENTION SCHEDULES: Account records 7 years after closure; Transaction records 5 years; Wire transfer records 5 years (BSA); CTR/SAR filings 5 years; Customer identification 5 years after closure; Loan files 7 years after payoff; Complaints 7 years from resolution; Email 7 years; Recorded calls 3 years (7 if dispute-related); Video surveillance 90 days (1 year if incident); Board minutes permanent. DESTRUCTION: Paper cross-cut shredding DIN P-4+; Electronic media NIST 800-88; Hard drives degaussing then physical destruction; Backup tapes overwrite with certificate. LEGAL HOLD: All relevant records preserved when litigation anticipated. Destruction suspended until hold lifted.'),
('POL029', 'Vendor Risk Management', 'Compliance', '2024-03-01'::DATE, 'POLICY: Third-Party Vendor Risk Management. EFFECTIVE DATE: March 1, 2024. RISK TIERS: Critical (direct PII access, core functions) Tier 1; Significant (sensitive data, important services) Tier 2; Moderate (limited data, standard services) Tier 3. DUE DILIGENCE: Financial stability review; SOC 2 Type II; Business continuity plans; Regulatory compliance history; Insurance coverage. ONGOING MONITORING: Critical vendors annual on-site, quarterly performance; Significant annual assessment, semi-annual performance; Moderate biennial assessment, annual performance. CONTRACTUAL: Right to audit; Data protection obligations; 24-hour incident notification; Termination assistance and data return/destruction. EXIT STRATEGY: All critical vendors must have documented exit strategy.'),
('POL030', 'Account Incentive Terms', 'Products', '2024-06-01'::DATE, 'POLICY: Account Incentive and Bonus Offer Standard Terms. EFFECTIVE DATE: June 1, 2024. STANDARD OFFERS: New Checking $300 bonus with qualifying direct deposit ($500+/month for 3 months); New Savings $200 with $15,000+ maintained 90 days; Referral $50 per qualified referral (both parties). ELIGIBILITY: New customers or existing without specific product in prior 12 months; One bonus per product per customer per 12 months; Account must remain open 6 months (bonus clawed back if closed early). FULFILLMENT: Credited within 30 days of criteria met; Taxable income, 1099-INT issued for bonuses over $10. FRAUD PREVENTION: Multiple open/close to farm bonuses subject to closure and reversal; Internal transfers do not qualify as direct deposit or new money.')
;

-------------------------------------------------------------------------------
-- CUSTOMERS (500,000 rows) — Generated via Snowflake GENERATOR
-------------------------------------------------------------------------------
INSERT INTO BNK.CUSTOMER_360.CUSTOMERS
SELECT
    UUID_STRING() AS customer_id,
    ARRAY_CONSTRUCT('James','Mary','Robert','Patricia','John','Jennifer','Michael','Linda','David','Elizabeth','William','Barbara','Richard','Susan','Joseph','Jessica','Thomas','Sarah','Christopher','Karen','Charles','Lisa','Daniel','Nancy','Matthew','Betty','Anthony','Margaret','Mark','Sandra','Donald','Ashley','Steven','Dorothy','Andrew','Kimberly','Paul','Emily','Joshua','Donna','Kenneth','Michelle','Kevin','Carol','Brian','Amanda','George','Melissa','Timothy','Deborah','Ronald','Stephanie','Edward','Rebecca','Jason','Sharon','Jeffrey','Laura','Ryan','Cynthia','Jacob','Kathleen','Gary','Amy','Nicholas','Angela','Eric','Shirley','Jonathan','Anna','Stephen','Brenda','Larry','Pamela','Justin','Emma','Scott','Nicole','Brandon','Helen','Benjamin','Samantha','Samuel','Katherine','Raymond','Christine','Gregory','Debra','Frank','Rachel','Alexander','Carolyn','Patrick','Janet','Jack','Catherine','Dennis','Maria','Jerry','Heather','Tyler','Diane')[UNIFORM(0,99,RANDOM())]::VARCHAR AS first_name,
    ARRAY_CONSTRUCT('Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Rodriguez','Martinez','Hernandez','Lopez','Gonzalez','Wilson','Anderson','Thomas','Taylor','Moore','Jackson','Martin','Lee','Perez','Thompson','White','Harris','Sanchez','Clark','Ramirez','Lewis','Robinson','Walker','Young','Allen','King','Wright','Scott','Torres','Nguyen','Hill','Flores','Green','Adams','Nelson','Baker','Hall','Rivera','Campbell','Mitchell','Carter','Roberts','Phillips','Evans','Turner','Diaz','Parker','Cruz','Edwards','Collins','Reyes','Stewart','Morris','Morales','Murphy','Cook','Rogers','Gutierrez','Ortiz','Morgan','Cooper','Peterson','Bailey','Reed','Kelly','Howard','Ramos','Kim','Cox','Ward','Richardson','Watson','Brooks','Chavez','Wood','James','Bennett','Gray','Mendoza','Ruiz','Hughes','Price','Alvarez','Castillo','Sanders','Patel','Myers','Long','Ross','Foster','Jimenez','Powell','Jenkins','Perry')[UNIFORM(0,99,RANDOM())]::VARCHAR AS last_name,
    LOWER(
        ARRAY_CONSTRUCT('james','mary','robert','patricia','john','jennifer','michael','linda','david','elizabeth','william','barbara','richard','susan','joseph','jessica','thomas','sarah','christopher','karen')[UNIFORM(0,19,RANDOM())]::VARCHAR 
        || '.' 
        || ARRAY_CONSTRUCT('smith','johnson','williams','brown','jones','garcia','miller','davis','rodriguez','martinez')[UNIFORM(0,9,RANDOM())]::VARCHAR 
        || UNIFORM(100,9999,RANDOM())::VARCHAR 
        || '@' 
        || ARRAY_CONSTRUCT('gmail.com','yahoo.com','outlook.com','aol.com','icloud.com','hotmail.com','protonmail.com','mail.com')[UNIFORM(0,7,RANDOM())]::VARCHAR
    ) AS email,
    CASE 
        WHEN UNIFORM(1,100,RANDOM()) <= 80 THEN 'Consumer'
        WHEN UNIFORM(1,100,RANDOM()) <= 75 THEN 'SmallBusiness'
        ELSE 'Commercial'
    END AS segment,
    ARRAY_CONSTRUCT('Northeast','Southeast','Midwest','West','Southwest')[
        CASE 
            WHEN UNIFORM(1,100,RANDOM()) <= 22 THEN 0
            WHEN UNIFORM(1,100,RANDOM()) <= 55 THEN 1
            WHEN UNIFORM(1,100,RANDOM()) <= 75 THEN 2
            WHEN UNIFORM(1,100,RANDOM()) <= 90 THEN 3
            ELSE 4
        END
    ]::VARCHAR AS region,
    UNIFORM(1, 360, RANDOM()) AS tenure_months,
    ROUND(ABS(NORMAL(15000, 25000, RANDOM())), 2) AS lifetime_value,
    DATEADD('month', -1 * UNIFORM(1, 360, RANDOM()), CURRENT_DATE()) AS created_date,
    CASE 
        WHEN UNIFORM(1,100,RANDOM()) <= 85 THEN 'Active'
        WHEN UNIFORM(1,100,RANDOM()) <= 70 THEN 'Inactive'
        ELSE 'Closed'
    END AS status
FROM TABLE(GENERATOR(ROWCOUNT => 500000));

-------------------------------------------------------------------------------
-- ACCOUNTS (1,000,000 rows) — 2 accounts per customer on average
-- Uses a lateral join to generate 1-4 accounts per customer
-------------------------------------------------------------------------------
INSERT INTO BNK.CUSTOMER_360.ACCOUNTS
WITH cust AS (
    SELECT customer_id
    FROM BNK.CUSTOMER_360.CUSTOMERS
)
SELECT
    UUID_STRING() AS account_id,
    cust.customer_id,
    prod_arr[UNIFORM(0, ARRAY_SIZE(prod_arr)-1, RANDOM())]::VARCHAR AS product_type,
    ROUND(
        CASE UNIFORM(0,5,RANDOM())
            WHEN 0 THEN ABS(NORMAL(5000, 8000, RANDOM()))
            WHEN 1 THEN ABS(NORMAL(12000, 15000, RANDOM()))
            WHEN 2 THEN UNIFORM(200, 25000, RANDOM())::FLOAT
            WHEN 3 THEN ABS(NORMAL(30000, 20000, RANDOM()))
            WHEN 4 THEN UNIFORM(5000, 100000, RANDOM())::FLOAT
            ELSE ABS(NORMAL(50000, 40000, RANDOM()))
        END, 2
    ) AS balance,
    DATEADD('day', -1 * UNIFORM(30, 3650, RANDOM()), CURRENT_DATE()) AS opened_date,
    CASE 
        WHEN UNIFORM(1,100,RANDOM()) <= 90 THEN 'Active'
        WHEN UNIFORM(1,100,RANDOM()) <= 60 THEN 'Dormant'
        ELSE 'Closed'
    END AS status,
    CASE UNIFORM(0,5,RANDOM())
        WHEN 0 THEN ROUND(UNIFORM(0, 50, RANDOM()) / 10000.0, 4)
        WHEN 1 THEN ROUND(UNIFORM(100, 450, RANDOM()) / 10000.0, 4)
        WHEN 2 THEN ROUND(UNIFORM(1499, 2699, RANDOM()) / 10000.0, 4)
        WHEN 3 THEN ROUND(UNIFORM(275, 450, RANDOM()) / 10000.0, 4)
        WHEN 4 THEN ROUND(UNIFORM(375, 500, RANDOM()) / 10000.0, 4)
        ELSE NULL
    END AS interest_rate
FROM cust
CROSS JOIN (
    SELECT ARRAY_CONSTRUCT('Checking','Savings','CreditCard','MoneyMarket','CD','Investment') AS prod_arr
) p
CROSS JOIN TABLE(GENERATOR(ROWCOUNT => 2))
LIMIT 1000000;

-------------------------------------------------------------------------------
-- TRANSACTIONS (1,000,000 rows) — Linked to accounts
-------------------------------------------------------------------------------
INSERT INTO BNK.CUSTOMER_360.TRANSACTIONS
WITH acct AS (
    SELECT account_id 
    FROM BNK.CUSTOMER_360.ACCOUNTS 
    WHERE status = 'Active'
)
SELECT
    UUID_STRING() AS txn_id,
    acct.account_id,
    DATEADD('day', -1 * UNIFORM(0, 730, RANDOM()), CURRENT_DATE()) AS txn_date,
    ROUND(
        CASE 
            WHEN UNIFORM(1,100,RANDOM()) <= 60 THEN -1 * ABS(NORMAL(45, 80, RANDOM()))
            WHEN UNIFORM(1,100,RANDOM()) <= 80 THEN -1 * ABS(NORMAL(150, 200, RANDOM()))
            WHEN UNIFORM(1,100,RANDOM()) <= 95 THEN ABS(NORMAL(2000, 3000, RANDOM()))
            ELSE -1 * ABS(NORMAL(500, 400, RANDOM()))
        END, 2
    ) AS amount,
    ARRAY_CONSTRUCT('Groceries','Groceries','Dining','Dining','Travel','Entertainment','Utilities','Utilities','Transfer','Deposit','Withdrawal','Payment','Payment','Groceries','Dining','Utilities')[UNIFORM(0,15,RANDOM())]::VARCHAR AS category,
    ARRAY_CONSTRUCT(
        'Whole Foods Market','Trader Joes','Walmart Supercenter','Target','Costco Wholesale',
        'Starbucks','Chipotle Mexican Grill','McDonalds','Olive Garden','Panera Bread',
        'Delta Air Lines','United Airlines','Marriott Hotels','Hilton Hotels','Uber',
        'Netflix','Amazon Prime','Spotify','AMC Theatres','Peloton',
        'ConEdison','AT&T Wireless','Verizon','Comcast Xfinity','State Farm Insurance',
        'Venmo Transfer','Zelle Payment','ACH Direct Deposit','Wire Transfer','ATM Withdrawal',
        'Chase Mortgage','Capital One Payment','Student Loan Corp','Auto Finance LLC','IRS Tax Payment',
        'Home Depot','Lowes','CVS Pharmacy','Walgreens','Shell Gas Station',
        'Exxon Mobil','BP Gas','Kroger','Safeway','Publix',
        'Best Buy','Apple Store','Nordstrom','Macys','TJ Maxx'
    )[UNIFORM(0,49,RANDOM())]::VARCHAR AS merchant_name,
    ARRAY_CONSTRUCT('Online','Online','Online','Mobile','Mobile','Mobile','Branch','ATM','ATM','Wire')[UNIFORM(0,9,RANDOM())]::VARCHAR AS channel
FROM acct
CROSS JOIN TABLE(GENERATOR(ROWCOUNT => 2))
LIMIT 1000000;

-------------------------------------------------------------------------------
-- INTERACTIONS (200,000 rows) — Linked to customers
-------------------------------------------------------------------------------
INSERT INTO BNK.CUSTOMER_360.INTERACTIONS
WITH cust AS (
    SELECT customer_id 
    FROM BNK.CUSTOMER_360.CUSTOMERS 
    WHERE status = 'Active'
)
SELECT
    UUID_STRING() AS interaction_id,
    cust.customer_id,
    ARRAY_CONSTRUCT('Branch','Branch','CallCenter','CallCenter','CallCenter','Email','Email','Chat','Chat','Mobile')[UNIFORM(0,9,RANDOM())]::VARCHAR AS channel,
    DATEADD('day', -1 * UNIFORM(0, 730, RANDOM()), CURRENT_DATE()) AS interaction_date,
    ARRAY_CONSTRUCT('AccountInquiry','AccountInquiry','AccountInquiry','FeeDispute','FeeDispute','ProductInquiry','ProductInquiry','Complaint','ServiceRequest','ServiceRequest')[UNIFORM(0,9,RANDOM())]::VARCHAR AS topic,
    ARRAY_CONSTRUCT('Positive','Positive','Positive','Neutral','Neutral','Neutral','Neutral','Neutral','Negative','Negative')[UNIFORM(0,9,RANDOM())]::VARCHAR AS sentiment,
    ARRAY_CONSTRUCT('Resolved','Resolved','Resolved','Resolved','Resolved','Resolved','Pending','Pending','Escalated','Transferred')[UNIFORM(0,9,RANDOM())]::VARCHAR AS resolution_status,
    ARRAY_CONSTRUCT('Sarah Chen','Michael Torres','Jennifer Walsh','David Kim','Rachel Patterson','Marcus Johnson','Emily Rodriguez','Christopher Lee','Amanda Foster','Robert Williams','Lisa Nguyen','James Anderson','Maria Santos','Thomas Brown','Stephanie Martinez','Kevin O''Brien','Nicole Parker','Jason Rivera','Ashley Thompson','Daniel Garcia')[UNIFORM(0,19,RANDOM())]::VARCHAR AS agent_name,
    'Customer contacted via ' 
    || ARRAY_CONSTRUCT('phone','branch visit','email','chat','mobile app')[UNIFORM(0,4,RANDOM())]::VARCHAR 
    || ' regarding ' 
    || ARRAY_CONSTRUCT(
        'an overdraft fee on their checking account',
        'a pending direct deposit that has not posted',
        'interest rate options for their savings account',
        'a suspicious transaction on their debit card',
        'upgrading to Premier Checking',
        'a wire transfer they need to send internationally',
        'closing a CD before maturity',
        'adding a beneficiary to their account',
        'a monthly service fee they were not expecting',
        'their credit card rewards points balance',
        'setting up automatic bill pay',
        'a declined transaction at a merchant',
        'requesting a credit limit increase',
        'disputing a charge from an online purchase',
        'opening a new savings account for their child'
    )[UNIFORM(0,14,RANDOM())]::VARCHAR
    || '. '
    || ARRAY_CONSTRUCT(
        'Issue was resolved during the call. Customer expressed satisfaction with the outcome.',
        'Provided detailed explanation of the policy. Customer acknowledged understanding.',
        'Escalated to supervisor for approval. Follow-up call scheduled for next business day.',
        'Submitted request for processing. Customer will receive confirmation within 3-5 business days.',
        'Waived fee as a one-time courtesy per bank policy. Documented in account notes.',
        'Referred customer to specialist team for further assistance. Transfer completed.',
        'Opened investigation case. Provisional credit applied. Customer notified of timeline.',
        'Walked customer through the process step by step. No further action required.',
        'Customer decided to think about it and will call back. No changes made today.',
        'Completed the requested changes. Confirmation sent to customer email on file.'
    )[UNIFORM(0,9,RANDOM())]::VARCHAR AS notes
FROM cust
CROSS JOIN TABLE(GENERATOR(ROWCOUNT => 1))
LIMIT 200000;

-------------------------------------------------------------------------------
-- CUSTOMER_NOTES (200,000 rows) — Advisor notes for Cortex Search
-------------------------------------------------------------------------------
INSERT INTO BNK.CUSTOMER_360.CUSTOMER_NOTES
WITH cust AS (
    SELECT customer_id 
    FROM BNK.CUSTOMER_360.CUSTOMERS 
    WHERE status = 'Active'
)
SELECT
    UUID_STRING() AS note_id,
    cust.customer_id,
    ARRAY_CONSTRUCT('Sarah Chen','Michael Torres','Jennifer Walsh','David Kim','Rachel Patterson','Marcus Johnson','Emily Rodriguez','Christopher Lee','Amanda Foster','Robert Williams','Lisa Nguyen','James Anderson','Maria Santos','Thomas Brown','Stephanie Martinez','Kevin O''Brien','Nicole Parker','Jason Rivera','Ashley Thompson','Daniel Garcia')[UNIFORM(0,19,RANDOM())]::VARCHAR AS agent_name,
    DATEADD('day', -1 * UNIFORM(0, 730, RANDOM()), CURRENT_DATE()) AS note_date,
    ARRAY_CONSTRUCT(
        'Annual review meeting with customer. Portfolio performing well above benchmark. Customer expressed interest in increasing allocation to fixed income as they approach retirement. Discussed CD ladder strategy and money market options. Customer will review proposed allocation and confirm by end of week. Risk tolerance remains moderate-conservative.',
        'Customer called regarding overdraft fee charged on checking account. Reviewed transaction history and confirmed the fee was correctly assessed per account terms. Waived fee as one-time courtesy given 8-year relationship and clean history. Recommended enrolling in overdraft protection linked to savings. Customer agreed to enrollment.',
        'Relationship review scheduled by retention model. Customer has shown declining engagement over past 3 months. Called to check in and discuss their banking needs. Customer mentioned considering a competitor for higher savings rate. Offered High-Yield Savings upgrade at 4.25% APY. Customer interested and scheduled branch visit.',
        'Customer visited branch to discuss small business loan options. Operating a catering business for 3 years with growing revenue. Discussed Business Term Loan and SBA options. Collected preliminary financials. Customer will provide 2 years tax returns and current P&L for formal application.',
        'Processed wire transfer request for $45,000 to international beneficiary (UK). Completed enhanced due diligence per wire transfer policy. Customer provided documentation of property purchase. Verified beneficiary details via callback. Transfer processed same day.',
        'Customer filed dispute for $287.43 charge from online retailer. Customer states product never received and merchant is unresponsive. Opened investigation case, applied provisional credit. Initiated chargeback with card network. Customer satisfied with response time.',
        'Wealth planning session with customer and spouse. Discussed estate planning, education savings for two children (ages 5 and 8), and retirement timeline (target age 62). Recommended 529 accounts and updated beneficiary designations on investment accounts. Follow-up meeting in 2 weeks with estate attorney.',
        'Customer upset about monthly service fee being charged despite maintaining balance. Investigated and found balance dipped below threshold for 2 days due to timing of auto-pay. Explained the policy but waived fee given circumstances. Set up low balance alert to prevent recurrence. Customer de-escalated.',
        'Quarterly business review with commercial client. Company expanding to second location. Discussed increased line of credit from $500K to $750K and commercial real estate financing for new space. Financial performance supports the request. Submitted credit memo for approval.',
        'Customer inquired about adding adult child as authorized user on credit card account. Explained the process, impact on both credit reports, and liability implications. Customer decided to proceed. Completed authorization form and ordered additional card. Will arrive in 5-7 business days.',
        'Assisted customer with setting up online banking and mobile app after branch visit. Customer is 72 years old and prefers in-person service but wants to check balances remotely. Walked through login process, balance checking, and bill pay setup. Did not enable external transfers per customer preference.',
        'Customer referred by existing client for new Premier Checking account. High-net-worth individual relocating from competitor bank. Opened Premier Checking, High-Yield Savings, and initiated investment account transfer ($350K). Assigned to Private Banking team for ongoing relationship management.',
        'Follow-up on merchant dispute filed 3 weeks ago. Investigation complete, ruling in customer favor. Provisional credit made permanent. Customer appreciative of timely resolution. Used opportunity to discuss credit card upgrade to Platinum Rewards given spending patterns.',
        'Customer called concerned about potential fraud. Noticed two small charges ($1.02 and $0.75) from unfamiliar merchants. Identified as common card testing pattern. Blocked card immediately, issued replacement. No further unauthorized charges detected. Filed fraud report.',
        'Retirement planning discussion. Customer turning 59.5 and wants to understand distribution options from IRA. Reviewed tax implications of traditional vs Roth conversions. Discussed Required Minimum Distribution timeline starting at 73. Recommended meeting with tax advisor before making decisions.',
        'Customer request to close savings account and transfer funds to competitor offering higher rate. Conducted retention conversation. Offered relationship pricing bump of +0.50% APY on High-Yield Savings. Customer accepted counter-offer. Processed rate adjustment and documented approval.',
        'Business customer needs to add new authorized signer for operating account. New CFO joining company next month. Collected documentation requirements: updated corporate resolution, new signer government ID, and beneficial ownership update form. Scheduled branch appointment for document execution.',
        'Customer walked in without appointment regarding identity theft concern. Someone attempted to open credit card in their name at another institution. Placed fraud alert on all accounts. Reviewed recent activity - no unauthorized transactions found. Recommended filing FTC identity theft report and credit freeze.',
        'Annual mortgage review. Customer has 4.875% fixed rate from 2019. Discussed refinance options but current rates higher. Customer would benefit from biweekly payment schedule (saves 4 years of payments). Set up biweekly ACH. Also discussed dropping PMI as home value has increased significantly.',
        'Customer called to understand the CD early withdrawal penalty before making a decision. Has 24-month CD maturing in 8 months but needs funds for home renovation. Explained penalty is 180 days of interest. Calculated actual dollar impact ($1,240 on $50K CD). Customer decided to wait and use HELOC instead.'
    )[UNIFORM(0,19,RANDOM())]::VARCHAR AS note_text
FROM cust
CROSS JOIN TABLE(GENERATOR(ROWCOUNT => 1))
LIMIT 200000;

-------------------------------------------------------------------------------
-- OFFERS (100,000 rows) — Linked to customers and products
-------------------------------------------------------------------------------
INSERT INTO BNK.CUSTOMER_360.OFFERS
WITH cust AS (
    SELECT customer_id 
    FROM BNK.CUSTOMER_360.CUSTOMERS 
    WHERE status = 'Active'
),
prod AS (
    SELECT product_id 
    FROM BNK.CUSTOMER_360.PRODUCTS
)
SELECT
    UUID_STRING() AS offer_id,
    cust.customer_id,
    ARRAY_CONSTRUCT('P001','P002','P006','P007','P011','P012','P016','P019','P020','P024','P025','P028')[UNIFORM(0,11,RANDOM())]::VARCHAR AS product_id,
    ARRAY_CONSTRUCT('CrossSell','CrossSell','CrossSell','CrossSell','Upsell','Upsell','Upsell','Retention','Retention','WinBack')[UNIFORM(0,9,RANDOM())]::VARCHAR AS offer_type,
    ARRAY_CONSTRUCT('Sent','Sent','Sent','Viewed','Viewed','Clicked','Clicked','Converted','Expired','Expired')[UNIFORM(0,9,RANDOM())]::VARCHAR AS status,
    DATEADD('day', -1 * UNIFORM(0, 365, RANDOM()), CURRENT_DATE()) AS sent_date,
    DATEADD('day', UNIFORM(30, 90, RANDOM()), DATEADD('day', -1 * UNIFORM(0, 365, RANDOM()), CURRENT_DATE())) AS expires_date
FROM cust
CROSS JOIN TABLE(GENERATOR(ROWCOUNT => 1))
LIMIT 100000;
