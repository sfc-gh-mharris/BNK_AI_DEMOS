/*=============================================================================
  LENDING ANALYTICS - DATA GENERATION
  Database: BNK | Schema: LENDING | Warehouse: BNK_WH
  
  Populates all lending analytics tables with realistic synthetic data.
  Uses Snowflake GENERATOR for large tables and explicit INSERTs for
  reference data (lending policies).
  
  IMPORTANT: All INSERTs use INSERT INTO ... SELECT ... WHERE NOT EXISTS
  pattern or check row counts to support idempotent re-runs.
=============================================================================*/

USE DATABASE BNK;
USE SCHEMA BNK.LENDING;
USE WAREHOUSE BNK_WH;

-------------------------------------------------------------------------------
-- LENDING_POLICIES (25 realistic mortgage servicing policies)
-- Only insert if table is empty to support idempotent runs
-------------------------------------------------------------------------------
INSERT INTO BNK.LENDING.LENDING_POLICIES (policy_id, title, category, effective_date, content)
SELECT * FROM (
SELECT column1 AS policy_id, column2 AS title, column3 AS category, column4::DATE AS effective_date, column5 AS content
FROM VALUES
('pol-001', 'Conventional Mortgage Underwriting Standards', 'Underwriting', '2024-01-15',
'POLICY: Conventional Mortgage Underwriting Standards

SCOPE: All conventional (non-government) first-lien mortgage applications.

CREDIT REQUIREMENTS:
- Minimum FICO score: 620 for standard conforming loans
- Minimum FICO score: 680 for cash-out refinance transactions
- Minimum FICO score: 700 for investment property loans
- Credit score used: Middle of three bureau scores (or lower of two if only two available)
- No bankruptcy within 4 years (Chapter 7) or 2 years (Chapter 13)
- No foreclosure within 7 years

INCOME AND EMPLOYMENT:
- Maximum front-end DTI ratio: 28% (housing expense to gross income)
- Maximum back-end DTI ratio: 43% (total obligations to gross income)
- DTI may be exceeded up to 50% with compensating factors (reserves, low LTV, high credit score)
- Minimum 2 years continuous employment in same field required
- Self-employed borrowers require 2 years tax returns with stable or increasing income
- Verbal verification of employment required within 10 business days of closing

LOAN-TO-VALUE:
- Maximum LTV for purchase: 97% (with PMI)
- Maximum LTV for rate/term refinance: 97%
- Maximum LTV for cash-out refinance: 80%
- Maximum LTV for investment property: 75%
- Appraisal required for all loans; AVM acceptable for streamline refinances under $400,000

RESERVES:
- 2 months PITI reserves required for primary residence
- 6 months PITI reserves required for second homes
- 6 months PITI reserves required for each investment property owned'),

('pol-002', 'FHA Loan Underwriting Guidelines', 'Underwriting', '2024-02-01',
'POLICY: FHA Loan Underwriting Guidelines

SCOPE: All Federal Housing Administration insured mortgage applications (FHA 203b, 203k, streamline refinance).

ELIGIBILITY:
- Property must be owner-occupied primary residence
- Borrower must have valid Social Security Number
- Borrower must be lawful US resident
- Property must meet FHA Minimum Property Requirements (MPR)

CREDIT REQUIREMENTS:
- Minimum FICO 580: Eligible for 96.5% LTV (3.5% down payment)
- FICO 500-579: Maximum 90% LTV (10% down payment required)
- Below FICO 500: Not eligible for FHA insurance
- Collections and charge-offs do not require payoff but must be documented
- Housing event (foreclosure, short sale, deed-in-lieu): 3-year waiting period with extenuating circumstances

INCOME AND RATIOS:
- Maximum front-end DTI: 31% (may exceed with Energy Efficient Homes)
- Maximum back-end DTI: 43% standard, up to 57% with compensating factors via TOTAL Scorecard
- All income must be documented, stable, and likely to continue for 3 years
- Non-occupant co-borrowers permitted for qualification

MORTGAGE INSURANCE:
- Upfront MIP: 1.75% of base loan amount (may be financed)
- Annual MIP: 0.55% for loans with LTV > 90% (life of loan)
- Annual MIP: 0.50% for loans with LTV <= 90% (11 years if term > 15 years)

PROPERTY REQUIREMENTS:
- FHA appraisal valid for 120 days (may be extended once for 30 days)
- Health and safety deficiencies must be repaired prior to closing
- Roof must have minimum 2 years remaining useful life
- Lead paint testing required for homes built before 1978'),

('pol-003', 'VA Loan Origination Policy', 'Underwriting', '2024-01-20',
'POLICY: VA Loan Origination Policy

SCOPE: All Veterans Affairs guaranteed mortgage applications.

ELIGIBILITY:
- Active duty service members with 90 continuous days during wartime or 181 days during peacetime
- Veterans meeting minimum active duty service requirements
- National Guard/Reserve members with 6 years of service or 90 days of active duty under Title 10
- Surviving spouses of veterans who died in service or from service-connected disability
- Certificate of Eligibility (COE) required before processing

ENTITLEMENT:
- Full entitlement: No loan limit (first-time use or restored entitlement)
- Partial entitlement: County loan limits apply to remaining entitlement
- Entitlement restoration available upon payoff or assumption by eligible veteran

REQUIREMENTS:
- No minimum credit score required by VA; lender overlay minimum FICO 580
- Maximum DTI: No VA maximum; lender overlay 50% with residual income meeting thresholds
- Residual income analysis required (varies by family size, region, and loan amount)
- No down payment required for full entitlement up to county limit
- No PMI/MIP required

FUNDING FEE:
- First use purchase/cash-out: 2.15% (0% down), 1.50% (5% down), 1.25% (10%+ down)
- Subsequent use: 3.30% (0% down)
- Exempt: Veterans with service-connected disability rating
- May be financed into loan amount

OCCUPANCY:
- Must be primary residence
- Must intend to occupy within 60 days of closing (12 months for new construction)'),

('pol-004', 'Jumbo Loan Underwriting Standards', 'Underwriting', '2024-03-01',
'POLICY: Jumbo Loan Underwriting Standards

SCOPE: All mortgage applications with loan amounts exceeding current conforming loan limits ($766,550 for single-family in most areas; higher in designated high-cost areas).

CREDIT REQUIREMENTS:
- Minimum FICO: 700 for purchase transactions
- Minimum FICO: 720 for cash-out refinance
- Minimum FICO: 740 for interest-only products
- No mortgage lates within 24 months
- No bankruptcy or foreclosure within 7 years
- Maximum 3 revolving account lates (30-day) in prior 12 months

INCOME AND RATIOS:
- Maximum back-end DTI: 43% (no exceptions above 45%)
- Asset depletion income methodology permitted for retirees with minimum $1M liquid assets
- Minimum 3 years tax returns for self-employed (business must show positive trend)
- All income sources must be documented with original source documents

LOAN-TO-VALUE:
- Maximum LTV for purchase up to $1.5M: 80%
- Maximum LTV for purchase $1.5M-$2.5M: 75%
- Maximum LTV for purchase above $2.5M: 70%
- Maximum LTV for cash-out: 65%
- Two appraisals required for loan amounts above $2.0M

RESERVES:
- 12 months PITI reserves after closing for the subject property
- 6 months PITI reserves for each additional financed property
- Acceptable reserve sources: checking, savings, retirement (60% of vested value), investment accounts
- Gift funds not permitted for reserves'),

('pol-005', 'Adjustable Rate Mortgage (ARM) Disclosure and Origination', 'Underwriting', '2024-02-15',
'POLICY: Adjustable Rate Mortgage (ARM) Disclosure and Origination

SCOPE: All adjustable-rate mortgage products including 5/1, 7/1, 10/1, 5/6, and 7/6 ARM configurations.

PRODUCT SPECIFICATIONS:
- 5/1 ARM: Fixed for 5 years, adjusts annually thereafter. Caps: 2/2/5 (initial/periodic/lifetime)
- 7/1 ARM: Fixed for 7 years, adjusts annually thereafter. Caps: 2/2/5
- 10/1 ARM: Fixed for 10 years, adjusts annually thereafter. Caps: 2/2/5
- 5/6 ARM: Fixed for 5 years, adjusts every 6 months thereafter. Caps: 1/1/5
- 7/6 ARM: Fixed for 7 years, adjusts every 6 months thereafter. Caps: 1/1/5
- Index: Secured Overnight Financing Rate (SOFR) 30-day average
- Margin: 2.25% to 3.00% depending on credit tier and LTV

QUALIFICATION:
- Borrower must qualify at the higher of: note rate + 2% or fully-indexed rate (index + margin)
- ARM-specific disclosure must be provided within 3 business days of application
- Borrower must sign ARM disclosure acknowledging rate adjustment risk
- CHARM booklet must be provided at application

CONVERSION OPTION:
- One-time conversion to fixed rate available between months 13-60 on 5/1 and 7/1 products
- Conversion rate: Current 30-year fixed rate + 0.375%
- Conversion fee: $250 (non-refundable)
- Conversion not available if loan is delinquent at time of request'),

('pol-006', 'Rate Lock Policy and Procedures', 'Pricing', '2024-01-10',
'POLICY: Rate Lock Policy and Procedures

SCOPE: All mortgage loan applications during the rate lock commitment period.

LOCK PERIODS:
- 30-day lock: Standard for purchase transactions (no cost)
- 45-day lock: Extended for new construction or complex transactions (+0.125% to rate)
- 60-day lock: Available for documented delays (+0.250% to rate)
- 90-day lock: Requires VP approval, available for new construction only (+0.375% to rate)

LOCK PROCEDURES:
- Rate locks are executed by the loan officer via the pricing engine at time of borrower request
- Lock becomes effective upon confirmation email to borrower
- Lock is binding upon both the borrower and the lender
- Lock captures: rate, points, lock date, expiration date, loan program, loan amount

RENEGOTIATION (FLOAT-DOWN):
- One-time float-down available if market rates drop 0.25% or more after lock
- Float-down must be exercised at least 15 days before closing
- New rate will be the lower of: locked rate or current rate + 0.125%
- Float-down fee: 0.125 discount points

LOCK EXTENSIONS:
- First extension (7 days): 0.125 discount points
- Second extension (7 days): 0.250 discount points
- Extensions beyond 14 days require Senior VP approval
- No extensions permitted once lock has expired (must re-lock at current market)

LOCK EXPIRATION:
- Expired locks will be repriced at current market rates
- If market rates are higher, borrower assumes the higher rate
- If market rates are lower, borrower receives the lower rate (best efforts)
- Loan officer must notify borrower 5 business days before lock expiration'),

('pol-007', 'Forbearance Program Guidelines', 'Modification', '2024-04-01',
'POLICY: Forbearance Program Guidelines

SCOPE: Active mortgage borrowers experiencing temporary financial hardship who are unable to make their full monthly payment.

ELIGIBILITY:
- Borrower must demonstrate a qualifying hardship: job loss, income reduction, medical emergency, natural disaster, death of wage earner, divorce/separation, military deployment
- No minimum number of missed payments required to apply
- Available for all loan types (conventional, FHA, VA, Jumbo)
- Property must remain borrower''s primary residence (exception for military deployment)

FORBEARANCE TERMS:
- Initial forbearance period: Up to 6 months
- Extension: Up to 6 additional months (12 months total) with documented ongoing hardship
- Payment may be reduced or fully suspended during forbearance period
- Interest continues to accrue during forbearance (not forgiven)
- No late fees assessed during approved forbearance period
- No negative credit reporting during approved forbearance period

REPAYMENT OPTIONS (POST-FORBEARANCE):
- Reinstatement: Lump sum payment of all deferred amounts (if borrower has received windfall)
- Repayment plan: Deferred amount spread over 6-12 months added to regular payment
- Payment deferral: Deferred amount placed in non-interest-bearing subordinate lien due at payoff/maturity
- Loan modification: Permanent change to rate, term, or principal to achieve affordable payment
- Partial claim (FHA only): HUD pays deferred amount, recorded as subordinate lien

APPROVAL AUTHORITY:
- Standard forbearance (up to 6 months): Servicing Manager
- Extended forbearance (7-12 months): Servicing Director
- Non-owner-occupied exception: VP Loss Mitigation
- Portfolio loans over $1M: Chief Credit Officer'),

('pol-008', 'Loan Modification Waterfall', 'Modification', '2024-03-15',
'POLICY: Loan Modification Waterfall

SCOPE: Borrowers who have completed forbearance or are 60+ days delinquent and unable to resume regular payments.

MODIFICATION WATERFALL (applied in order until target payment achieved):
Step 1 - Rate Reduction: Reduce interest rate in 0.125% increments down to floor rate of 3.000%
Step 2 - Term Extension: Extend loan term up to 480 months from modification date (maximum 40 years)
Step 3 - Principal Forbearance: Defer up to 30% of unpaid principal as non-interest-bearing balloon due at maturity or payoff
Step 4 - Principal Reduction: Write down principal to achieve 31% front-end DTI (investor approval required)

TARGET PAYMENT:
- Modified payment must achieve front-end DTI of 31% or less
- If 31% target is not achievable after full waterfall, borrower may be evaluated for short sale or deed-in-lieu

ELIGIBILITY:
- Borrower must provide complete financial package (income documentation, hardship letter, bank statements)
- Property must be owner-occupied (investment property modifications have separate guidelines)
- Borrower must complete trial payment plan (3 months at modified payment) before final modification
- Net Present Value (NPV) test must show modification is more favorable to investor than foreclosure

DOCUMENTATION:
- Modification agreement must be recorded in county land records
- New first payment date established 30 days after trial plan completion
- Escrow account re-analyzed and new escrow payment established
- Credit bureau reporting updated to reflect modification status

RESTRICTIONS:
- Maximum one modification per 24-month period
- Cash-out refinance ineligible for 24 months post-modification
- Subordinate financing ineligible for 12 months post-modification'),

('pol-009', 'Collections Escalation Procedures', 'Collections', '2024-02-28',
'POLICY: Collections Escalation Procedures

SCOPE: All delinquent mortgage loans from first day past due through foreclosure referral.

EARLY-STAGE DELINQUENCY (1-29 DAYS PAST DUE):
- Day 1: Automated payment reminder email/text sent
- Day 5: Second automated reminder via preferred communication channel
- Day 15: Live agent outbound call attempt (minimum 2 attempts, different times of day)
- Day 16-29: Continued call attempts; right-party contact required before escalation
- Document all contact attempts in servicing system within 24 hours

MODERATE DELINQUENCY (30-59 DAYS PAST DUE):
- Day 30: Breach letter mailed via first-class mail (required by deed of trust)
- Day 31-35: Intensive calling campaign (minimum 3 attempts per week)
- Day 36: Loss mitigation packet mailed if no right-party contact achieved
- Day 45: Second breach letter mailed
- Day 45-59: Continue calling; evaluate for loss mitigation options if contact made
- Report 30-day late to credit bureaus at Day 30

SERIOUS DELINQUENCY (60-89 DAYS PAST DUE):
- Day 60: Demand letter issued (full amount past due required within 30 days)
- Day 60: Report 60-day late to credit bureaus
- Day 60: Assign to senior collector
- Day 65: Face-to-face contact attempt if property within servicer territory
- Day 75: Evaluate for loss mitigation vs. foreclosure path
- Day 80: Manager review of account; decision documented

SEVERE DELINQUENCY (90+ DAYS PAST DUE):
- Day 90: Report 90-day late to credit bureaus
- Day 90: Final loss mitigation evaluation
- Day 120: Foreclosure referral if no loss mitigation resolution achieved
- Day 120: Transfer to foreclosure attorney/trustee
- All state and federal pre-foreclosure notice requirements must be met
- SCRA (military) clearance required before foreclosure referral'),

('pol-010', 'Escrow Administration Policy', 'Servicing', '2024-01-25',
'POLICY: Escrow Administration Policy

SCOPE: All mortgage loans with established escrow accounts for property taxes and insurance.

ESCROW ESTABLISHMENT:
- Escrow required for all loans with LTV > 80% at origination
- Escrow required for all FHA and VA loans regardless of LTV
- Escrow optional for conventional loans with LTV <= 80% (borrower may waive with 0.25% rate premium)
- Initial escrow deposit: 2 months cushion above annual disbursement proration

ANNUAL ANALYSIS:
- Escrow analysis performed annually on the anniversary of the loan closing
- Analysis projects next 12 months of disbursements based on most recent tax and insurance bills
- New monthly escrow payment effective 30 days after analysis statement mailed
- Borrower must be notified of payment change at least 30 days in advance

SHORTAGE AND SURPLUS:
- Surplus greater than $50: Refund check issued within 30 days of analysis
- Surplus $50 or less: Applied to next year''s escrow balance
- Shortage: Borrower may pay lump sum within 30 days or spread over 12 months
- Maximum annual payment increase due to shortage spread: 1/12 of the shortage amount per month

DEFICIENCY:
- Deficiency occurs when escrow balance is projected to go negative
- Deficiency amount: May be collected over 12 months or in lump sum at borrower election
- Combined shortage + deficiency increase capped at 1/6 of projected annual escrow per RESPA

DISBURSEMENTS:
- Property taxes paid on or before penalty date per county schedule
- Insurance premiums paid 15 days before policy expiration
- If borrower changes insurance carrier, new policy must be effective before prior policy cancels
- Flood insurance disbursed separately if property is in FEMA-designated flood zone'),

('pol-011', 'Prepayment and Payoff Processing', 'Servicing', '2024-02-10',
'POLICY: Prepayment and Payoff Processing

SCOPE: All mortgage loans processing additional principal payments or full loan payoff.

ADDITIONAL PRINCIPAL PAYMENTS:
- Borrowers may make additional principal payments at any time without penalty
- Additional payments applied to principal reduction after current payment is satisfied
- Partial prepayments do not advance the due date (next regular payment still due)
- Minimum additional principal payment: $100 (or full outstanding balance for payoff)
- Bi-weekly payment program available: 26 half-payments per year (equivalent to 13 monthly payments)

PAYOFF REQUESTS:
- Payoff statement must be provided within 7 business days of written request (RESPA requirement)
- Payoff good-through date: 30 days from statement generation date
- Payoff amount includes: principal balance, accrued interest through good-through date, escrow advance balance, fees, and recording charges
- Per diem interest rate quoted for flexibility in closing date

PAYOFF PROCESSING:
- Wire payoffs: Funds must be received by 2:00 PM ET for same-day processing
- Check payoffs: 5 business day hold for check clearance before lien release
- Overnight mail payoffs: Processed next business day upon receipt
- Partial payoff not permitted (must pay in full or process as additional principal)

LIEN RELEASE:
- Satisfaction/reconveyance recorded within 30 days of payoff (60 days where state law permits)
- Original note marked "PAID" and returned to borrower within 60 days
- Escrow surplus refunded within 20 business days of payoff
- Reporting to credit bureaus: Account status updated to "Paid in Full" within 30 days

PREPAYMENT PENALTIES (LEGACY LOANS ONLY):
- No prepayment penalties on loans originated after January 2014 (QM rule)
- Legacy loans (pre-2014): Penalty applies per note terms, typically 2% of prepaid amount in years 1-3
- Penalty waived if borrower selling due to job relocation (documented transfer letter required)'),

('pol-012', 'Hardship Assessment Framework', 'Collections', '2024-03-20',
'POLICY: Hardship Assessment Framework

SCOPE: Evaluation of borrower hardship claims for loss mitigation eligibility.

QUALIFYING HARDSHIP EVENTS:
Category A - Income Disruption:
  - Involuntary job loss (layoff, position elimination, company closure)
  - Reduction in work hours or pay (documented by employer)
  - Business failure for self-employed borrowers
  - Loss of secondary income source (spousal income, rental income, alimony)

Category B - Expense Shock:
  - Medical emergency or ongoing medical treatment costs
  - Uninsured property damage (fire, flood not covered by policy)
  - Legal expenses (divorce, custody dispute, estate matter)
  - Unexpected tax obligation (audit, reassessment)

Category C - Life Events:
  - Death of borrower or co-borrower
  - Divorce or separation
  - Incarceration
  - Military deployment or PCS orders

DOCUMENTATION REQUIREMENTS:
- Hardship letter: Written explanation of circumstance, signed and dated
- Income documentation: Most recent 30 days pay stubs, 2 years W-2/tax returns
- Bank statements: Most recent 2 months all accounts
- Hardship-specific documentation:
  * Job loss: Termination letter, unemployment benefits statement
  * Medical: Bills, insurance EOB, doctor letter
  * Divorce: Filed petition, separation agreement
  * Military: Orders, LES (Leave and Earnings Statement)

ASSESSMENT CRITERIA:
- Hardship must be documented and verifiable
- Hardship must be the proximate cause of inability to pay
- Borrower must demonstrate inability to cure delinquency through other means
- Duration of hardship: Temporary (< 12 months expected) or permanent determines workout type'),

('pol-013', 'Fair Lending Compliance Standards', 'Compliance', '2024-01-05',
'POLICY: Fair Lending Compliance Standards

SCOPE: All mortgage lending activities including origination, servicing, and collections.

REGULATORY FRAMEWORK:
- Equal Credit Opportunity Act (ECOA) / Regulation B
- Fair Housing Act (FHA)
- Home Mortgage Disclosure Act (HMDA) / Regulation C
- Community Reinvestment Act (CRA)
- Unfair, Deceptive, or Abusive Acts or Practices (UDAAP)

PROHIBITED BASES:
Lending decisions must not consider, directly or through proxy: race, color, national origin, religion, sex, familial status, disability, age (provided applicant has capacity to contract), receipt of public assistance income, exercise of rights under Consumer Credit Protection Act.

PRICING CONTROLS:
- Rate sheet pricing applies uniformly to all borrowers with same risk profile
- Loan officer discretion limited to: waiving application fee, matching documented competitor rate
- Any deviation from rate sheet requires Fair Lending Officer approval and documented business justification
- Quarterly regression analysis of pricing by protected class status
- Annual third-party fair lending audit required

UNDERWRITING:
- Automated underwriting findings applied consistently
- Manual underwriting overrides (both approvals and denials) require second-level review
- Override rate monitored monthly by protected class
- Compensating factors applied using documented, objective criteria
- Adverse action notices must cite specific reasons from standard reason code list

MONITORING:
- HMDA LAR data reviewed quarterly for statistical anomalies
- Redlining risk assessment annually using branch/digital channel geographic analysis
- Matched-pair testing conducted semi-annually by third-party firm
- All fair lending findings reported to Board Risk Committee'),

('pol-014', 'TILA-RESPA Integrated Disclosure (TRID) Compliance', 'Compliance', '2024-02-20',
'POLICY: TILA-RESPA Integrated Disclosure (TRID) Compliance

SCOPE: All closed-end consumer mortgage transactions subject to Regulation Z.

LOAN ESTIMATE (LE):
- Must be delivered within 3 business days of receiving a complete application
- Complete application defined: borrower name, income, SSN, property address, estimated property value, mortgage loan amount sought
- LE valid for 10 business days from issuance
- Revised LE permitted only for valid changed circumstance (defined below)

CHANGED CIRCUMSTANCES (PERMITTING REVISED LE):
- Borrower-requested changes to loan terms
- Information provided at application found to be inaccurate or incomplete
- New information not reasonably available at time of original LE
- Natural disaster or other unexpected event affecting property or title
- Revised LE must be delivered within 3 business days of discovering changed circumstance

CLOSING DISCLOSURE (CD):
- Must be received by borrower at least 3 business days before consummation
- If delivered by mail: add 3 calendar days for receipt (6 business days before closing)
- Mandatory 3-day re-disclosure if: APR increases by more than 1/8% (fixed) or 1/4% (ARM), loan product changes, or prepayment penalty added

TOLERANCE CATEGORIES:
- Zero tolerance (no increase permitted): Lender fees, transfer taxes, fees paid to affiliate
- 10% cumulative tolerance: Third-party fees where lender selected provider, recording fees
- Unlimited tolerance: Fees where borrower selected provider from lender''s list, prepaid items, owner''s title insurance

CURING TOLERANCE VIOLATIONS:
- Refund to borrower required within 60 days of consummation for any tolerance violation
- Refund amount: Excess charged above tolerance threshold
- Document cure in loan file with explanation of violation cause'),

('pol-015', 'Qualified Mortgage (QM) Standards', 'Compliance', '2024-01-30',
'POLICY: Qualified Mortgage (QM) Standards

SCOPE: All first-lien residential mortgage originations evaluated for QM safe harbor or rebuttable presumption status.

GENERAL QM REQUIREMENTS (Effective March 2021):
- Loan must meet General QM DTI limit OR achieve DTI <= 43% with Appendix Q documentation
- General QM: Loan APR does not exceed APOR + 2.25% (first lien, conforming amount)
- Points and fees do not exceed 3% of total loan amount (5% for loans < $100,000)
- Loan term does not exceed 30 years
- No negative amortization, interest-only, or balloon features
- No prepayment penalty exceeding QM limits (none after 3 years)
- Creditor must verify and document income/assets at or before consummation

SAFE HARBOR vs. REBUTTABLE PRESUMPTION:
- APR <= APOR + 1.50%: Safe harbor (conclusive presumption of compliance)
- APR > APOR + 1.50% but <= APOR + 2.25%: Rebuttable presumption (borrower can challenge ATR)
- APR > APOR + 2.25%: Not a Qualified Mortgage (no ATR protection)

ABILITY TO REPAY (ATR) FACTORS:
All eight ATR factors must be considered and documented:
1. Current or reasonably expected income/assets
2. Current employment status
3. Monthly mortgage payment for the subject loan
4. Monthly payment on simultaneous loans
5. Monthly payment for property taxes, insurance, HOA
6. Current debt obligations, alimony, child support
7. Monthly DTI ratio or residual income
8. Credit history

DOCUMENTATION:
- W-2 transcripts or tax transcripts for income verification
- Asset statements not more than 60 days old
- Employment verification within 10 days of closing
- QM determination documented in loan file with supporting analysis'),

('pol-016', 'Property Appraisal Standards', 'Underwriting', '2024-03-10',
'POLICY: Property Appraisal Standards

SCOPE: All mortgage transactions requiring property valuation for underwriting or servicing decisions.

APPRAISER INDEPENDENCE:
- Appraisal must be ordered through approved AMC (Appraisal Management Company) or internal panel
- Loan officer and production staff prohibited from selecting appraiser or influencing value
- No communication of target value, purchase price (except as required on form), or desired outcome
- Appraiser Independence Requirements (AIR) per Dodd-Frank Section 1472

APPRAISAL REQUIREMENTS BY TRANSACTION TYPE:
- Purchase (any amount): Full interior/exterior appraisal (URAR Form 1004)
- Refinance > $400,000: Full interior/exterior appraisal
- Refinance <= $400,000, LTV <= 80%: AVM + exterior inspection acceptable
- HELOC/second lien: AVM acceptable if LTV <= 75% and loan amount <= $250,000
- Two appraisals required for: loans > $2M, flipped properties (< 180 days ownership), non-arm''s length

APPRAISAL REVIEW:
- All appraisals reviewed by certified reviewer within 48 hours of receipt
- Reviewer checks: comparable selection, adjustment reasoning, market conditions, property condition
- Value disputes escalated to Chief Appraiser for reconsideration or second appraisal
- Reconsideration of value permitted only with new comparable data (not pressure to hit target)

ALTERNATIVE VALUATION METHODS:
- AVM (Automated Valuation Model): Acceptable for limited cases per above; confidence score must exceed 0.70
- BPO (Broker Price Opinion): Acceptable for servicing decisions (modification, short sale) only; not for origination
- Desktop appraisal: Permitted for GSE-eligible loans meeting eligibility criteria per DU/LPA findings'),

('pol-017', 'Flood Insurance Compliance', 'Compliance', '2024-02-05',
'POLICY: Flood Insurance Compliance

SCOPE: All mortgage loans secured by improved real property in Special Flood Hazard Areas (SFHA) as determined by FEMA flood maps.

DETERMINATION:
- Standard Flood Hazard Determination Form (SFHDF) required for every mortgage transaction
- Determination performed by approved third-party vendor at application
- Life-of-loan tracking service required to monitor FEMA map changes
- Determination fee charged to borrower at closing (currently $20)

INSURANCE REQUIREMENTS:
- Properties in Zone A, AE, AH, AO, AR, V, VE: Flood insurance REQUIRED
- Minimum coverage: Lesser of outstanding loan balance or maximum NFIP coverage ($250,000 residential)
- Policy must be effective on or before closing date
- Acceptable policies: NFIP (National Flood Insurance Program) or private flood insurance meeting statutory requirements
- Detached structures/outbuildings: Contents coverage not required; building coverage at replacement cost

FORCE-PLACED INSURANCE:
- If borrower fails to maintain required flood insurance: 45-day notice sent
- If no evidence of coverage within 45 days: Force-place coverage
- Force-placed coverage billed to borrower escrow account
- Coverage retroactive to lapse date
- Excess premium refunded if borrower obtains own policy

PRIVATE FLOOD INSURANCE:
- Accepted if policy provides coverage at least as broad as NFIP
- Must include: dwelling coverage, deductible terms, cancellation notice provisions
- Policy must explicitly state it meets definition of private flood insurance under 42 USC 4012a(b)
- Lender must make determination of adequate coverage within 45 days of policy receipt'),

('pol-018', 'Assumption and Transfer Policy', 'Servicing', '2024-04-15',
'POLICY: Assumption and Transfer Policy

SCOPE: Requests to transfer mortgage obligation to a new borrower (assumption) or notification of property ownership transfer.

ASSUMABLE LOANS:
- FHA loans: Assumable with creditworthiness review of assumer
- VA loans: Assumable with creditworthiness review; original veteran''s entitlement remains encumbered unless substitution of entitlement processed
- Conventional loans: Generally NOT assumable (due-on-sale clause enforced)
- ARM loans originated before 1989: May be assumable per note terms

ASSUMPTION REQUIREMENTS:
- New borrower must complete full credit application
- Minimum FICO: Same as origination requirements for loan type
- Maximum DTI: Same as origination requirements for loan type
- Assumption fee: $900 processing fee plus third-party costs
- Title policy endorsement required reflecting new borrower

DUE-ON-SALE EXCEPTIONS (GARN-ST. GERMAIN ACT):
Transfer without triggering acceleration permitted for:
- Transfer to spouse or child upon death of borrower
- Transfer to spouse due to divorce/separation (per decree/agreement)
- Transfer to inter vivos trust where borrower remains beneficiary
- Transfer resulting from joint tenant''s death
- Transfer to relative upon borrower''s death

PROPERTY TRANSFER MONITORING:
- Public records monitored quarterly for title changes
- Upon detection of transfer: Verify if Garn-St. Germain exception applies
- If no exception: 30-day demand letter requiring payoff or assumption application
- If no response within 30 days: Acceleration of full loan balance'),

('pol-019', 'Interest Rate Pricing Methodology', 'Pricing', '2024-01-15',
'POLICY: Interest Rate Pricing Methodology

SCOPE: Determination of offered interest rates for all residential mortgage products.

BASE RATE DETERMINATION:
- Base rates derived from secondary market pricing (MBS pricing + servicing spread)
- Rates published daily by 9:00 AM ET via pricing engine
- Intraday repricing triggered if 10-year Treasury moves +/- 10 bps from morning lock
- Rate sheet posted to origination system and broker portal simultaneously

RISK-BASED PRICING ADJUSTMENTS (LLPAs):
Credit Score Adjustments:
- FICO >= 780: -0.250% (improvement)
- FICO 760-779: -0.125%
- FICO 740-759: Base (no adjustment)
- FICO 720-739: +0.125%
- FICO 700-719: +0.375%
- FICO 680-699: +0.625%
- FICO 660-679: +1.000%
- FICO 640-659: +1.500%
- FICO 620-639: +2.000%

LTV Adjustments (cumulative with credit):
- LTV <= 60%: -0.125%
- LTV 60.01-70%: Base
- LTV 70.01-75%: +0.125%
- LTV 75.01-80%: +0.250%
- LTV 80.01-85%: +0.375%
- LTV 85.01-90%: +0.500%
- LTV 90.01-95%: +0.750%
- LTV 95.01-97%: +1.000%

PRODUCT ADJUSTMENTS:
- Cash-out refinance: +0.500%
- Investment property: +0.750%
- 2-unit property: +0.250%
- 3-4 unit property: +0.500%
- Interest-only: +0.250%
- Subordinate financing: +0.250%

DISCOUNT POINTS AND CREDITS:
- Each discount point (1% of loan amount) reduces rate by approximately 0.25%
- Maximum discount points: 3.000
- Lender credit available up to 2.00% of loan amount (increases rate)'),

('pol-020', 'Bankruptcy and Foreclosure Waiting Periods', 'Underwriting', '2024-03-05',
'POLICY: Bankruptcy and Foreclosure Waiting Periods

SCOPE: Applicants with prior bankruptcy filings, foreclosures, short sales, or deeds-in-lieu of foreclosure.

CHAPTER 7 BANKRUPTCY:
- Conventional: 4 years from discharge date (2 years with extenuating circumstances + max 90% LTV)
- FHA: 2 years from discharge date (1 year with extenuating circumstances + counseling completion)
- VA: 2 years from discharge date
- Jumbo: 7 years from discharge date (no exceptions)

CHAPTER 13 BANKRUPTCY:
- Conventional: 2 years from discharge date, 4 years from dismissal date
- FHA: 1 year into repayment plan with court approval and satisfactory payment history
- VA: 1 year into repayment plan with court approval
- Jumbo: 4 years from discharge date, 7 years from dismissal date

FORECLOSURE:
- Conventional: 7 years from completion date (3 years with extenuating circumstances + max 90% LTV)
- FHA: 3 years from completion date (1 year with extenuating circumstances)
- VA: 2 years from completion date with restored entitlement
- Jumbo: 7 years (no exceptions)

SHORT SALE / DEED-IN-LIEU:
- Conventional: 4 years (2 years with extenuating circumstances + max 90% LTV)
- FHA: 3 years from transfer date
- VA: 2 years from transfer date
- Jumbo: 7 years (no exceptions)

EXTENUATING CIRCUMSTANCES:
- Must be non-recurring event beyond borrower''s control
- Documented evidence: death certificate, divorce decree, medical records, employer closure notice
- Credit re-established with no derogatory marks since the event
- Reduced waiting period + lower LTV cap applies as noted above'),

('pol-021', 'Loss Mitigation Retention Waterfall', 'Modification', '2024-04-10',
'POLICY: Loss Mitigation Retention Waterfall

SCOPE: Evaluation of delinquent borrowers for retention workout options prior to foreclosure.

EVALUATION ORDER (MOST FAVORABLE TO BORROWER FIRST):
1. Loan Modification (permanent payment reduction)
2. Forbearance Plan (temporary payment reduction/suspension)
3. Repayment Plan (cure delinquency over 6-12 months)
4. Partial Claim (FHA/VA only - subordinate lien for deferred amount)
5. Trial Period Plan (3 months qualifying for modification)

MODIFICATION ELIGIBILITY:
- Loan must be 60+ days delinquent OR imminent default (demonstrated inability to maintain current payment)
- Borrower must provide complete financial documentation package
- Modified payment must pass NPV test (modification NPV > foreclosure NPV)
- Occupancy confirmed as primary residence
- No active fraud investigation on the account

TRIAL PERIOD PLAN (TPP):
- Duration: 3 months at proposed modified payment amount
- Payment due by last business day of each month during trial
- One missed trial payment = automatic TPP failure; re-evaluation in 6 months
- Successful completion: Final modification documents issued within 30 days

WATERFALL NPV INPUTS:
- Current property value (BPO or AVM)
- Current unpaid principal balance
- Delinquent interest and advances
- Estimated foreclosure timeline and costs
- Property preservation costs
- REO holding and liquidation costs
- Probability of re-default (based on modification type and depth)

DUAL TRACKING PROHIBITION:
- Once borrower submits complete loss mitigation application: foreclosure activities paused
- Evaluation must be completed within 30 days of receiving complete package
- Borrower has 14 days to accept or reject offered workout
- Appeal process available for denied applications (30 days to appeal)'),

('pol-022', 'Private Mortgage Insurance (PMI) Management', 'Servicing', '2024-02-15',
'POLICY: Private Mortgage Insurance (PMI) Management

SCOPE: All conventional mortgage loans with private mortgage insurance.

PMI REQUIREMENT:
- PMI required on conventional loans with LTV > 80% at origination
- PMI obtained through approved MI company (MGIC, Radian, Genworth, Essent, NMI, Arch)
- Coverage percentage per GSE requirements based on LTV and term

AUTOMATIC TERMINATION (HOMEOWNERS PROTECTION ACT):
- PMI automatically terminates when scheduled LTV reaches 78% based on original amortization schedule and original property value
- No borrower action required; servicer must cancel coverage and cease billing
- Termination date: First day of month following month when 78% threshold is reached
- Final termination deadline: Midpoint of amortization schedule regardless of LTV

BORROWER-REQUESTED CANCELLATION:
- Borrower may request PMI cancellation when current LTV reaches 80%
- Requirements for lender-paid appraisal (borrower pays cost):
  * Current on payments (no 30-day lates in prior 12 months, no 60-day lates in prior 24 months)
  * Property value supports LTV <= 80% (original value used unless new appraisal ordered)
  * No subordinate liens added since origination
- If based on property appreciation:
  * LTV must reach 75% for cancellation within years 2-5 of origination
  * LTV must reach 80% for cancellation after year 5

PMI BILLING:
- Monthly PMI premium collected via escrow account
- Lender-paid PMI (LPMI): Higher interest rate in lieu of monthly premium; no cancellation available
- Split premium: Portion paid upfront at closing, reduced monthly amount
- Upon cancellation: Unearned premium refunded to borrower within 45 days'),

('pol-023', 'Servicing Transfer Notification Requirements', 'Servicing', '2024-03-25',
'POLICY: Servicing Transfer Notification Requirements

SCOPE: Transfer of mortgage servicing rights from one servicer to another.

NOTIFICATION TIMELINE:
- Transferring servicer: Must notify borrower at least 15 days before effective transfer date
- Receiving servicer: Must notify borrower no later than 15 days after effective transfer date
- Notifications may be combined into single notice if co-issued by both servicers

REQUIRED NOTICE CONTENTS:
Transferring servicer notice:
- Effective date of transfer
- Name, address, toll-free number of new servicer
- Date on which current servicer will stop accepting payments
- Statement regarding late fee protection during 60-day transition

Receiving servicer notice:
- Effective date of transfer
- Name, address, toll-free number of new servicer
- Date new servicer begins accepting payments
- Payment coupon or instructions for first payment to new servicer
- New online portal access instructions

BORROWER PROTECTIONS:
- 60-day safe harbor: No late fees during first 60 days after transfer if payment sent to prior servicer
- Payment forwarding: Prior servicer must forward misdirected payments to new servicer
- Escrow obligations: New servicer assumes all escrow obligations on effective date
- Loss mitigation continuity: In-process applications must be honored by receiving servicer
- No payment change: Transfer alone cannot trigger payment amount change

RECORDS TRANSFER:
- Complete servicing file transferred within 15 days of sale effective date
- Payment history: Minimum 36 months or life of loan
- Escrow analysis: Current and prior year
- Insurance policies: All active policies with declarations pages
- Loss mitigation files: Complete packages for any active workout
- Correspondence history: All borrower communications in prior 24 months'),

('pol-024', 'Anti-Money Laundering and BSA Compliance for Mortgage', 'Compliance', '2024-01-20',
'POLICY: Anti-Money Laundering and BSA Compliance for Mortgage Lending

SCOPE: Customer identification, due diligence, and suspicious activity reporting for all mortgage transactions.

CUSTOMER IDENTIFICATION PROGRAM (CIP):
- Obtain: Full legal name, date of birth, address, identification number (SSN or ITIN)
- Verify: Documentary (government-issued photo ID) OR non-documentary (credit bureau, database)
- Record: Retain copies of identification documents for 5 years after account closure
- Screen: All parties checked against OFAC SDN list, 314(a) requests, and FinCEN advisories

ENHANCED DUE DILIGENCE (EDD):
Required for:
- Non-resident alien borrowers
- Cash-intensive business owners (self-employed in cash businesses)
- Transactions involving foreign entities or funds from foreign sources
- All-cash purchases above $300,000 (even if not financed - Geographic Targeting Orders)
- PEP (Politically Exposed Person) identified borrowers

EDD PROCEDURES:
- Source of funds documentation for down payment and reserves
- Purpose of transaction (especially investment properties)
- Expected transaction pattern (rental income, seasonal use)
- Third-party involvement (power of attorney, trust transactions)
- Senior compliance officer review required

SUSPICIOUS ACTIVITY REPORTING:
- SAR filing required for transactions involving $5,000+ where suspicion exists
- Timing: File within 30 calendar days of detection
- Red flags specific to mortgage:
  * Significant unexplained cash deposits before closing
  * Multiple property purchases in short timeframe inconsistent with borrower profile
  * Rapid refinances with cash-out and no clear purpose
  * Nominee or straw buyer indicators
  * Value manipulation (inflated appraisal colluding with seller)

CURRENCY TRANSACTION REPORTING:
- CTR filed for cash transactions exceeding $10,000 in a single business day
- Structuring awareness: Patterns designed to avoid CTR reporting threshold'),

('pol-025', 'Credit Report and Score Requirements', 'Underwriting', '2024-02-25',
'POLICY: Credit Report and Score Requirements

SCOPE: Credit report ordering, scoring methodology, and handling for all mortgage applications.

CREDIT REPORT TYPE:
- Tri-merge residential mortgage credit report (RMCR) required for all applications
- Report must include data from all three bureaus: Equifax, Experian, TransUnion
- Reports ordered through approved credit vendors only (no consumer-pull reports accepted)
- In-file report (hard inquiry) required; soft inquiry reports not acceptable for underwriting

SCORE METHODOLOGY:
- Classic FICO scoring model required (FICO 2, FICO 4, FICO 5 depending on bureau)
- Transition to FICO 10T and VantageScore 4.0 per GSE timeline (implementation TBD)
- Representative score selection:
  * Single borrower, three scores: Use middle score
  * Single borrower, two scores: Use lower score
  * Multiple borrowers: Use lowest representative score among all borrowers

CREDIT REPORT VALIDITY:
- Report valid for 120 days from date pulled
- If closing occurs after 120 days: Refresh required (update credit with current tradeline data)
- Refresh may be tri-merge refresh or individual bureau update per investor guidelines
- Any material change in refresh (new accounts, increased balances, new inquiries) requires re-underwriting

CREDIT SUPPLEMENTS:
- Permitted to add: Accounts not reporting to bureaus (rent, utilities) via VOR/VOL
- Permitted to add: Corrected information with documentation (paid collections, identity theft)
- NOT permitted: Removing accurately reported negative information
- All supplements must be verified by original creditor or documented third-party source

CREDIT INQUIRIES:
- Inquiries within 30 days of report date: Borrower must explain purpose (LOX - Letter of Explanation)
- Multiple mortgage inquiries within 45-day window: Treated as single inquiry per FICO shopping window
- New credit obtained after application: Full underwriting review required; may impact approval'),

('pol-026', 'Digital Mortgage and Remote Online Notarization', 'Compliance', '2024-04-01',
'POLICY: Digital Mortgage and Remote Online Notarization (RON)

SCOPE: Electronic signatures, digital document delivery, and remote notarization for mortgage transactions.

ELECTRONIC SIGNATURES (E-SIGN):
- All borrowers must provide E-SIGN Act consent before electronic document delivery
- Consent disclosure: Describes hardware/software requirements, right to withdraw, paper copy availability
- Consent may be withdrawn at any time; paper delivery resumes within 5 business days
- Certain documents require wet ink regardless: negotiable instruments in some states (promissory note)

ELECTRONIC CLOSING (eClosing):
- Hybrid eClosing: Electronic signature on most documents; wet ink on note and notarized documents
- Full eClosing: All documents signed electronically including eNote and remotely notarized documents
- eNote: Electronic promissory note registered on MERS eRegistry; must meet MISMO standards
- eVault: Electronic original maintained in certified eVault (MISMO compliance required)

REMOTE ONLINE NOTARIZATION (RON):
- Available in states that have enacted RON legislation (currently 43 states + DC)
- Platform requirements: Identity proofing, knowledge-based authentication (KBA), credential analysis
- Recording: Audio-video recording of entire session retained for minimum 5 years
- Notary requirements: State-commissioned, RON-endorsed, trained on platform
- Multi-party sessions: Each signer must be individually authenticated
- Prohibited states: Must use in-person notarization in states without RON authorization

IDENTITY VERIFICATION FOR RON:
- Knowledge-Based Authentication: 5 questions, 4 correct within 2 minutes, maximum 2 attempts
- Credential analysis: AI-powered examination of government-issued ID (front and back)
- Comparison: Live video of signer compared to ID photo by notary
- If any verification step fails: Session terminated; in-person closing required

INVESTOR ACCEPTANCE:
- Fannie Mae: Accepts eNotes and RON per Selling Guide requirements
- Freddie Mac: Accepts eNotes and RON per Single-Family Seller/Servicer Guide
- Ginnie Mae: eNote acceptance per APM 19-06; RON per state-specific guidance
- Portfolio/Jumbo: Accepted per internal counsel approval'),

('pol-027', 'Adverse Action Notice Requirements', 'Compliance', '2024-03-01',
'POLICY: Adverse Action Notice Requirements

SCOPE: All declined mortgage applications and counteroffer situations where terms differ materially from those applied for.

ADVERSE ACTION DEFINITION:
- Denial of credit application
- Counteroffer of different terms not accepted by applicant
- Revocation of existing credit approval
- Denial of credit increase (for HELOCs)

TIMING:
- Notice must be provided within 30 days of denial decision
- If application is incomplete: Notice of incompleteness within 30 days; if no response within reasonable time, treat as withdrawn (not denied)
- Counteroffer: If applicant does not accept within 90 days, treat as denied and send adverse action notice

REQUIRED CONTENT (ECOA/REGULATION B):
- Statement that adverse action was taken
- Name and address of creditor
- ECOA notice of rights (anti-discrimination statement)
- Name, address, and phone number of federal supervisory agency
- Specific reason(s) for denial (minimum 1, maximum 4 from standard list)
- Credit score disclosure: Score used, range, key factors

SPECIFIC REASON CODES (MOST COMMON):
- Debt-to-income ratio exceeds guidelines
- Credit score below minimum requirement
- Insufficient employment history
- Property appraisal below purchase price/requested value
- Insufficient reserves after closing
- Derogatory credit history (bankruptcy, foreclosure, collections)
- Incomplete documentation not provided within required timeframe

CREDIT SCORE DISCLOSURE:
- Include: The score used in the decision, score range, date score was obtained
- Include: Up to 4 key factors that adversely affected the score
- Include: Contact information for credit reporting agency
- If multiple scores (co-borrower): Disclose score that was used in decision-making

RECORD RETENTION:
- Retain adverse action notices for 25 months (ECOA requirement)
- Retain complete application file for 25 months from notification date
- Retained records must include: Application, supporting documents, underwriting analysis, denial reason documentation'),

('pol-028', 'Maximum Loan Amount and High-Cost Mortgage Thresholds', 'Pricing', '2024-01-01',
'POLICY: Maximum Loan Amount and High-Cost Mortgage Thresholds

SCOPE: Conforming loan limits, high-balance area limits, and high-cost mortgage (HOEPA) compliance.

2024 CONFORMING LOAN LIMITS:
- Standard limit (most areas): $766,550 (single-family)
- High-cost area limit (maximum): $1,149,825 (single-family)
- 2-unit: $981,500 standard / $1,472,250 high-cost
- 3-unit: $1,186,350 standard / $1,779,525 high-cost
- 4-unit: $1,474,400 standard / $2,211,600 high-cost
- Alaska, Hawaii, Guam, U.S. Virgin Islands: High-cost limits apply regardless of area median

LOAN AMOUNT DETERMINATION:
- Conforming: Loan amount <= standard or high-cost area limit per FHFA designation
- Jumbo: Loan amount exceeds applicable conforming limit
- Super-Jumbo (internal designation): Loan amount exceeds $2,000,000

HIGH-COST MORTGAGE (HOEPA / SECTION 32):
Triggers (if ANY exceeded, loan is high-cost):
- APR trigger: First lien APR exceeds APOR + 6.5 percentage points
- Points and fees trigger: Exceed 5% of total loan amount (or $1,000 for loans < $20,000)
- Prepayment penalty trigger: Penalty charged more than 36 months after consummation, or exceeds 2% of amount prepaid

HIGH-COST MORTGAGE RESTRICTIONS (IF TRIGGERED):
- No balloon payments
- No prepayment penalties
- Pre-loan counseling from HUD-approved agency required (certificate retained in file)
- No financing of points and fees
- No modification/deferral fees
- No late fees exceeding 4% of past-due payment
- No acceleration without 30-day cure notice
- No negative amortization
- Payoff statement must be provided within 5 business days

HIGHER-PRICED MORTGAGE LOAN (HPML / SECTION 35):
- First lien: APR exceeds APOR + 1.5%
- Subordinate lien: APR exceeds APOR + 3.5%
- Requirements: Full interior appraisal, escrow account for minimum 5 years, ability to repay determination')
) t
WHERE NOT EXISTS (SELECT 1 FROM BNK.LENDING.LENDING_POLICIES LIMIT 1);

-------------------------------------------------------------------------------
-- BORROWERS (200,000 rows)
-- Distribution: Credit scores ~N(720, 60), Income ~LogNormal(11.35, 0.5)
--               Ages uniform 25-75, regional distribution per US population
-------------------------------------------------------------------------------
INSERT INTO BNK.LENDING.BORROWERS
SELECT
    UUID_STRING() AS borrower_id,
    -- First names from weighted common US names
    CASE MOD(SEQ4(), 20)
        WHEN 0 THEN 'James' WHEN 1 THEN 'Mary' WHEN 2 THEN 'Robert'
        WHEN 3 THEN 'Patricia' WHEN 4 THEN 'John' WHEN 5 THEN 'Jennifer'
        WHEN 6 THEN 'Michael' WHEN 7 THEN 'Linda' WHEN 8 THEN 'David'
        WHEN 9 THEN 'Elizabeth' WHEN 10 THEN 'William' WHEN 11 THEN 'Barbara'
        WHEN 12 THEN 'Richard' WHEN 13 THEN 'Susan' WHEN 14 THEN 'Joseph'
        WHEN 15 THEN 'Jessica' WHEN 16 THEN 'Thomas' WHEN 17 THEN 'Sarah'
        WHEN 18 THEN 'Christopher' ELSE 'Karen'
    END AS first_name,
    CASE MOD(SEQ4(), 25)
        WHEN 0 THEN 'Smith' WHEN 1 THEN 'Johnson' WHEN 2 THEN 'Williams'
        WHEN 3 THEN 'Brown' WHEN 4 THEN 'Jones' WHEN 5 THEN 'Garcia'
        WHEN 6 THEN 'Miller' WHEN 7 THEN 'Davis' WHEN 8 THEN 'Rodriguez'
        WHEN 9 THEN 'Martinez' WHEN 10 THEN 'Hernandez' WHEN 11 THEN 'Lopez'
        WHEN 12 THEN 'Gonzalez' WHEN 13 THEN 'Wilson' WHEN 14 THEN 'Anderson'
        WHEN 15 THEN 'Thomas' WHEN 16 THEN 'Taylor' WHEN 17 THEN 'Moore'
        WHEN 18 THEN 'Jackson' WHEN 19 THEN 'Martin' WHEN 20 THEN 'Lee'
        WHEN 21 THEN 'Perez' WHEN 22 THEN 'Thompson' WHEN 23 THEN 'White'
        ELSE 'Harris'
    END AS last_name,
    -- Age: Uniform 25-75
    25 + MOD(ABS(HASH(SEQ4() || 'age')), 51) AS age,
    -- Income: Lognormal approximation centered ~$85K with right skew
    ROUND(
        GREATEST(30000,
            LEAST(500000,
                EXP(11.35 + 0.5 * (RANDOM() / 4611686018427387904.0))
            )
        ), -2
    ) AS annual_income,
    -- Credit score: Normal distribution ~N(720, 60), clamped 300-850
    GREATEST(300,
        LEAST(850,
            ROUND(720 + 60 * (
                (RANDOM() / 4611686018427387904.0 + RANDOM() / 4611686018427387904.0 + RANDOM() / 4611686018427387904.0) / 3.0
            ))
        )
    )::INTEGER AS credit_score,
    -- Employment status: 70% Employed, 15% SelfEmployed, 10% Retired, 5% Unemployed
    CASE
        WHEN MOD(ABS(HASH(SEQ4() || 'emp')), 100) < 70 THEN 'Employed'
        WHEN MOD(ABS(HASH(SEQ4() || 'emp')), 100) < 85 THEN 'SelfEmployed'
        WHEN MOD(ABS(HASH(SEQ4() || 'emp')), 100) < 95 THEN 'Retired'
        ELSE 'Unemployed'
    END AS employment_status,
    -- Employer name (NULL for Retired/Unemployed handled in CASE)
    CASE
        WHEN MOD(ABS(HASH(SEQ4() || 'emp')), 100) >= 95 THEN NULL
        WHEN MOD(ABS(HASH(SEQ4() || 'emp')), 100) >= 85 THEN NULL
        ELSE
            CASE MOD(ABS(HASH(SEQ4() || 'employer')), 15)
                WHEN 0 THEN 'JPMorgan Chase' WHEN 1 THEN 'Amazon'
                WHEN 2 THEN 'UnitedHealth Group' WHEN 3 THEN 'Microsoft'
                WHEN 4 THEN 'Walmart' WHEN 5 THEN 'Alphabet Inc'
                WHEN 6 THEN 'Apple Inc' WHEN 7 THEN 'Johnson & Johnson'
                WHEN 8 THEN 'Lockheed Martin' WHEN 9 THEN 'Bank of America'
                WHEN 10 THEN 'Deloitte' WHEN 11 THEN 'Accenture'
                WHEN 12 THEN 'Northrop Grumman' WHEN 13 THEN 'HCA Healthcare'
                ELSE 'General Motors'
            END
    END AS employer_name,
    -- Years employed: 0.5-35, higher for older borrowers
    CASE
        WHEN MOD(ABS(HASH(SEQ4() || 'emp')), 100) >= 85 THEN NULL  -- Retired/Unemployed
        ELSE ROUND(GREATEST(0.5, LEAST(35.0,
            1.0 + MOD(ABS(HASH(SEQ4() || 'yrs')), 300) / 10.0
        )), 1)
    END AS years_employed,
    -- Region: Weighted by US population distribution
    CASE
        WHEN MOD(ABS(HASH(SEQ4() || 'region')), 100) < 18 THEN 'Northeast'
        WHEN MOD(ABS(HASH(SEQ4() || 'region')), 100) < 38 THEN 'Southeast'
        WHEN MOD(ABS(HASH(SEQ4() || 'region')), 100) < 58 THEN 'Midwest'
        WHEN MOD(ABS(HASH(SEQ4() || 'region')), 100) < 72 THEN 'Southwest'
        WHEN MOD(ABS(HASH(SEQ4() || 'region')), 100) < 88 THEN 'West'
        ELSE 'Pacific'
    END AS region,
    -- State: Mapped from region
    CASE
        WHEN MOD(ABS(HASH(SEQ4() || 'region')), 100) < 18 THEN
            CASE MOD(ABS(HASH(SEQ4() || 'state')), 6)
                WHEN 0 THEN 'NY' WHEN 1 THEN 'NJ' WHEN 2 THEN 'PA'
                WHEN 3 THEN 'CT' WHEN 4 THEN 'MA' ELSE 'NH'
            END
        WHEN MOD(ABS(HASH(SEQ4() || 'region')), 100) < 38 THEN
            CASE MOD(ABS(HASH(SEQ4() || 'state')), 8)
                WHEN 0 THEN 'FL' WHEN 1 THEN 'GA' WHEN 2 THEN 'NC'
                WHEN 3 THEN 'VA' WHEN 4 THEN 'TN' WHEN 5 THEN 'SC'
                WHEN 6 THEN 'AL' ELSE 'MS'
            END
        WHEN MOD(ABS(HASH(SEQ4() || 'region')), 100) < 58 THEN
            CASE MOD(ABS(HASH(SEQ4() || 'state')), 6)
                WHEN 0 THEN 'IL' WHEN 1 THEN 'OH' WHEN 2 THEN 'MI'
                WHEN 3 THEN 'IN' WHEN 4 THEN 'MN' ELSE 'WI'
            END
        WHEN MOD(ABS(HASH(SEQ4() || 'region')), 100) < 72 THEN
            CASE MOD(ABS(HASH(SEQ4() || 'state')), 4)
                WHEN 0 THEN 'TX' WHEN 1 THEN 'AZ' WHEN 2 THEN 'NM' ELSE 'OK'
            END
        WHEN MOD(ABS(HASH(SEQ4() || 'region')), 100) < 88 THEN
            CASE MOD(ABS(HASH(SEQ4() || 'state')), 4)
                WHEN 0 THEN 'CO' WHEN 1 THEN 'UT' WHEN 2 THEN 'NV' ELSE 'MT'
            END
        ELSE
            CASE MOD(ABS(HASH(SEQ4() || 'state')), 3)
                WHEN 0 THEN 'CA' WHEN 1 THEN 'WA' ELSE 'OR'
            END
    END AS state,
    -- Created date: Spread over last 10 years
    DATEADD(day, -MOD(ABS(HASH(SEQ4() || 'date')), 3650), CURRENT_DATE()) AS created_date
FROM TABLE(GENERATOR(ROWCOUNT => 200000))
WHERE NOT EXISTS (SELECT 1 FROM BNK.LENDING.BORROWERS LIMIT 1);

-------------------------------------------------------------------------------
-- MORTGAGES (300,000 rows)
-- Correlations: Income → loan size, credit → rate, proper LTV calculations
-------------------------------------------------------------------------------
INSERT INTO BNK.LENDING.MORTGAGES
SELECT
    UUID_STRING() AS mortgage_id,
    b.borrower_id,
    -- Property address
    (MOD(ABS(HASH(b.borrower_id || m.seq_num || 'addr')), 9000) + 100)::VARCHAR || ' ' ||
    CASE MOD(ABS(HASH(b.borrower_id || m.seq_num || 'street')), 12)
        WHEN 0 THEN 'Oak St' WHEN 1 THEN 'Maple Ave' WHEN 2 THEN 'Cedar Ln'
        WHEN 3 THEN 'Pine Dr' WHEN 4 THEN 'Elm Blvd' WHEN 5 THEN 'Main St'
        WHEN 6 THEN 'Park Ave' WHEN 7 THEN 'Lake Dr' WHEN 8 THEN 'River Rd'
        WHEN 9 THEN 'Highland Ave' WHEN 10 THEN 'Forest Way' ELSE 'Sunset Blvd'
    END || ', ' ||
    CASE MOD(ABS(HASH(b.borrower_id || m.seq_num || 'city')), 10)
        WHEN 0 THEN 'Springfield' WHEN 1 THEN 'Fairview' WHEN 2 THEN 'Madison'
        WHEN 3 THEN 'Georgetown' WHEN 4 THEN 'Franklin' WHEN 5 THEN 'Clinton'
        WHEN 6 THEN 'Arlington' WHEN 7 THEN 'Salem' WHEN 8 THEN 'Bristol'
        ELSE 'Greenville'
    END || ', ' || b.state AS property_address,
    -- Property value: Correlated with income (2.5x to 6x annual income)
    ROUND(
        b.annual_income * (2.5 + MOD(ABS(HASH(b.borrower_id || m.seq_num || 'pval')), 35) / 10.0),
        -3
    ) AS property_value,
    -- Loan amount: LTV between 60-95% of property value
    ROUND(
        (b.annual_income * (2.5 + MOD(ABS(HASH(b.borrower_id || m.seq_num || 'pval')), 35) / 10.0)) *
        (0.60 + MOD(ABS(HASH(b.borrower_id || m.seq_num || 'ltv')), 36) / 100.0),
        -3
    ) AS loan_amount,
    -- Interest rate: Inversely correlated with credit score (3.0-8.0%)
    ROUND(
        GREATEST(3.0,
            LEAST(8.0,
                8.5 - (b.credit_score - 300) * 0.009 + (MOD(ABS(HASH(b.borrower_id || m.seq_num || 'rate')), 100) - 50) / 100.0
            )
        ),
        3
    ) AS interest_rate,
    -- Term: 60% 30yr, 25% 15yr, 15% 20yr
    CASE
        WHEN MOD(ABS(HASH(b.borrower_id || m.seq_num || 'term')), 100) < 60 THEN 30
        WHEN MOD(ABS(HASH(b.borrower_id || m.seq_num || 'term')), 100) < 85 THEN 15
        ELSE 20
    END AS term_years,
    -- Loan type: Distributed realistically
    CASE
        WHEN MOD(ABS(HASH(b.borrower_id || m.seq_num || 'type')), 100) < 50 THEN 'Fixed'
        WHEN MOD(ABS(HASH(b.borrower_id || m.seq_num || 'type')), 100) < 65 THEN 'ARM'
        WHEN MOD(ABS(HASH(b.borrower_id || m.seq_num || 'type')), 100) < 80 THEN 'FHA'
        WHEN MOD(ABS(HASH(b.borrower_id || m.seq_num || 'type')), 100) < 90 THEN 'VA'
        ELSE 'Jumbo'
    END AS loan_type,
    -- Origination date: Spread over last 8 years
    DATEADD(day, -MOD(ABS(HASH(b.borrower_id || m.seq_num || 'orig')), 2920), CURRENT_DATE()) AS origination_date,
    -- Maturity date: Origination + term
    DATEADD(year,
        CASE
            WHEN MOD(ABS(HASH(b.borrower_id || m.seq_num || 'term')), 100) < 60 THEN 30
            WHEN MOD(ABS(HASH(b.borrower_id || m.seq_num || 'term')), 100) < 85 THEN 15
            ELSE 20
        END,
        DATEADD(day, -MOD(ABS(HASH(b.borrower_id || m.seq_num || 'orig')), 2920), CURRENT_DATE())
    ) AS maturity_date,
    -- LTV ratio: Derived from loan/property value
    ROUND(
        (0.60 + MOD(ABS(HASH(b.borrower_id || m.seq_num || 'ltv')), 36) / 100.0) * 100,
        2
    ) AS ltv_ratio,
    -- DTI ratio: 20-45%, correlated with loan size relative to income
    ROUND(
        GREATEST(20.0,
            LEAST(45.0,
                28.0 + (MOD(ABS(HASH(b.borrower_id || m.seq_num || 'dti')), 170) / 10.0)
            )
        ),
        2
    ) AS dti_ratio,
    -- Status: Majority current, with realistic delinquency distribution
    CASE
        WHEN MOD(ABS(HASH(b.borrower_id || m.seq_num || 'stat')), 1000) < 750 THEN 'Current'
        WHEN MOD(ABS(HASH(b.borrower_id || m.seq_num || 'stat')), 1000) < 820 THEN 'PaidOff'
        WHEN MOD(ABS(HASH(b.borrower_id || m.seq_num || 'stat')), 1000) < 880 THEN 'Refinanced'
        WHEN MOD(ABS(HASH(b.borrower_id || m.seq_num || 'stat')), 1000) < 920 THEN 'Delinquent30'
        WHEN MOD(ABS(HASH(b.borrower_id || m.seq_num || 'stat')), 1000) < 950 THEN 'Delinquent60'
        WHEN MOD(ABS(HASH(b.borrower_id || m.seq_num || 'stat')), 1000) < 975 THEN 'Delinquent90'
        ELSE 'Default'
    END AS status
FROM BNK.LENDING.BORROWERS b
CROSS JOIN (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS seq_num
    FROM TABLE(GENERATOR(ROWCOUNT => 2))
) m
WHERE MOD(ABS(HASH(b.borrower_id || m.seq_num)), 100) < 75  -- ~75% of 200K * 2 cross join = ~300K
  AND NOT EXISTS (SELECT 1 FROM BNK.LENDING.MORTGAGES LIMIT 1);

-------------------------------------------------------------------------------
-- PAYMENTS (1,000,000 rows)
-- Realistic payment patterns: 95% on-time, 3% late, 1.5% partial, 0.5% missed
-------------------------------------------------------------------------------
INSERT INTO BNK.LENDING.PAYMENTS
SELECT
    UUID_STRING() AS payment_id,
    m.mortgage_id,
    -- Payment date: Monthly payments spread from origination to now
    DATEADD(month,
        MOD(ABS(HASH(m.mortgage_id || p.seq_num)), 
            GREATEST(1, DATEDIFF(month, m.origination_date, CURRENT_DATE()))
        ),
        m.origination_date
    ) AS payment_date,
    -- Amount due: Approximate monthly payment (P&I + escrow)
    ROUND(
        (m.loan_amount * (m.interest_rate/100/12) * POWER(1 + m.interest_rate/100/12, m.term_years*12)) /
        (POWER(1 + m.interest_rate/100/12, m.term_years*12) - 1),
        2
    ) AS amount_due,
    -- Amount paid: Based on payment status
    CASE
        WHEN MOD(ABS(HASH(m.mortgage_id || p.seq_num || 'pstat')), 1000) < 950 THEN
            ROUND(
                (m.loan_amount * (m.interest_rate/100/12) * POWER(1 + m.interest_rate/100/12, m.term_years*12)) /
                (POWER(1 + m.interest_rate/100/12, m.term_years*12) - 1),
                2
            )
        WHEN MOD(ABS(HASH(m.mortgage_id || p.seq_num || 'pstat')), 1000) < 980 THEN
            ROUND(
                (m.loan_amount * (m.interest_rate/100/12) * POWER(1 + m.interest_rate/100/12, m.term_years*12)) /
                (POWER(1 + m.interest_rate/100/12, m.term_years*12) - 1),
                2
            )
        WHEN MOD(ABS(HASH(m.mortgage_id || p.seq_num || 'pstat')), 1000) < 995 THEN
            ROUND(
                ((m.loan_amount * (m.interest_rate/100/12) * POWER(1 + m.interest_rate/100/12, m.term_years*12)) /
                (POWER(1 + m.interest_rate/100/12, m.term_years*12) - 1)) * 0.6,
                2
            )
        ELSE 0.00
    END AS amount_paid,
    -- Principal portion: ~30-40% of payment for typical amortization
    ROUND(
        CASE
            WHEN MOD(ABS(HASH(m.mortgage_id || p.seq_num || 'pstat')), 1000) >= 995 THEN 0
            ELSE
                (m.loan_amount * (m.interest_rate/100/12) * POWER(1 + m.interest_rate/100/12, m.term_years*12)) /
                (POWER(1 + m.interest_rate/100/12, m.term_years*12) - 1) * 0.35
        END,
        2
    ) AS principal_portion,
    -- Interest portion: ~50-55% of payment
    ROUND(
        CASE
            WHEN MOD(ABS(HASH(m.mortgage_id || p.seq_num || 'pstat')), 1000) >= 995 THEN 0
            ELSE
                (m.loan_amount * (m.interest_rate/100/12) * POWER(1 + m.interest_rate/100/12, m.term_years*12)) /
                (POWER(1 + m.interest_rate/100/12, m.term_years*12) - 1) * 0.50
        END,
        2
    ) AS interest_portion,
    -- Escrow portion: ~15% of payment
    ROUND(
        CASE
            WHEN MOD(ABS(HASH(m.mortgage_id || p.seq_num || 'pstat')), 1000) >= 995 THEN 0
            ELSE
                (m.loan_amount * (m.interest_rate/100/12) * POWER(1 + m.interest_rate/100/12, m.term_years*12)) /
                (POWER(1 + m.interest_rate/100/12, m.term_years*12) - 1) * 0.15
        END,
        2
    ) AS escrow_portion,
    -- Days past due
    CASE
        WHEN MOD(ABS(HASH(m.mortgage_id || p.seq_num || 'pstat')), 1000) < 950 THEN 0
        WHEN MOD(ABS(HASH(m.mortgage_id || p.seq_num || 'pstat')), 1000) < 980 THEN
            MOD(ABS(HASH(m.mortgage_id || p.seq_num || 'dpd')), 25) + 1
        WHEN MOD(ABS(HASH(m.mortgage_id || p.seq_num || 'pstat')), 1000) < 995 THEN
            MOD(ABS(HASH(m.mortgage_id || p.seq_num || 'dpd')), 45) + 15
        ELSE MOD(ABS(HASH(m.mortgage_id || p.seq_num || 'dpd')), 60) + 30
    END AS days_past_due,
    -- Payment status
    CASE
        WHEN MOD(ABS(HASH(m.mortgage_id || p.seq_num || 'pstat')), 1000) < 950 THEN 'OnTime'
        WHEN MOD(ABS(HASH(m.mortgage_id || p.seq_num || 'pstat')), 1000) < 980 THEN 'Late'
        WHEN MOD(ABS(HASH(m.mortgage_id || p.seq_num || 'pstat')), 1000) < 995 THEN 'Partial'
        ELSE 'Missed'
    END AS payment_status
FROM BNK.LENDING.MORTGAGES m
CROSS JOIN (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS seq_num
    FROM TABLE(GENERATOR(ROWCOUNT => 4))
) p
WHERE MOD(ABS(HASH(m.mortgage_id || p.seq_num)), 100) < 83  -- ~83% of 300K * 4 ≈ 1M
  AND NOT EXISTS (SELECT 1 FROM BNK.LENDING.PAYMENTS LIMIT 1);

-------------------------------------------------------------------------------
-- RISK_SCORES (200,000 rows)
-- PD inversely correlated with credit score
-------------------------------------------------------------------------------
INSERT INTO BNK.LENDING.RISK_SCORES
SELECT
    UUID_STRING() AS score_id,
    b.borrower_id,
    -- Score date: Most recent month
    DATEADD(day, -MOD(ABS(HASH(b.borrower_id || 'scoredt')), 30), CURRENT_DATE()) AS score_date,
    -- Probability of default: Exponential decay from credit score
    -- PD = 0.5 * exp(-0.008 * (credit_score - 300))
    ROUND(
        GREATEST(0.001,
            LEAST(0.95,
                0.5 * EXP(-0.008 * (b.credit_score - 300)) +
                (MOD(ABS(HASH(b.borrower_id || 'pd')), 100) - 50) / 1000.0
            )
        ),
        4
    ) AS probability_of_default,
    -- Loss given default: 0.2 to 0.7, higher for higher LTV
    ROUND(
        GREATEST(0.10,
            LEAST(0.80,
                0.35 + (MOD(ABS(HASH(b.borrower_id || 'lgd')), 400) - 200) / 1000.0
            )
        ),
        4
    ) AS loss_given_default,
    -- Expected loss: PD * LGD * Exposure (estimated)
    ROUND(
        GREATEST(100,
            (0.5 * EXP(-0.008 * (b.credit_score - 300))) *
            (0.35 + (MOD(ABS(HASH(b.borrower_id || 'lgd')), 400) - 200) / 1000.0) *
            b.annual_income * 3.5
        ),
        2
    ) AS expected_loss,
    -- Refinance probability: Higher for good credit, existing high rates
    ROUND(
        GREATEST(0.01,
            LEAST(0.85,
                (b.credit_score - 550) / 500.0 +
                (MOD(ABS(HASH(b.borrower_id || 'refi')), 200) - 100) / 500.0
            )
        ),
        4
    ) AS refinance_probability,
    -- Model version
    CASE MOD(ABS(HASH(b.borrower_id || 'ver')), 3)
        WHEN 0 THEN 'v3.2.1'
        WHEN 1 THEN 'v3.2.0'
        ELSE 'v3.1.5'
    END AS model_version
FROM BNK.LENDING.BORROWERS b
WHERE NOT EXISTS (SELECT 1 FROM BNK.LENDING.RISK_SCORES LIMIT 1);

-------------------------------------------------------------------------------
-- REFINANCE_SIGNALS (50,000 rows)
-- Various signal types with confidence levels
-------------------------------------------------------------------------------
INSERT INTO BNK.LENDING.REFINANCE_SIGNALS
SELECT
    UUID_STRING() AS signal_id,
    b.borrower_id,
    -- Signal type distribution
    CASE MOD(ABS(HASH(b.borrower_id || 'sigtype')), 100)
        WHEN  0 THEN 'RateShop' WHEN  1 THEN 'RateShop' WHEN  2 THEN 'RateShop'
        WHEN  3 THEN 'RateShop' WHEN  4 THEN 'RateShop' WHEN  5 THEN 'RateShop'
        WHEN  6 THEN 'RateShop' WHEN  7 THEN 'RateShop' WHEN  8 THEN 'RateShop'
        WHEN  9 THEN 'RateShop' WHEN 10 THEN 'RateShop' WHEN 11 THEN 'RateShop'
        WHEN 12 THEN 'RateShop' WHEN 13 THEN 'RateShop' WHEN 14 THEN 'RateShop'
        WHEN 15 THEN 'RateShop' WHEN 16 THEN 'RateShop' WHEN 17 THEN 'RateShop'
        WHEN 18 THEN 'RateShop' WHEN 19 THEN 'RateShop' WHEN 20 THEN 'RateShop'
        WHEN 21 THEN 'RateShop' WHEN 22 THEN 'RateShop' WHEN 23 THEN 'RateShop'
        WHEN 24 THEN 'RateShop'
        WHEN 25 THEN 'CompetitorOffer' WHEN 26 THEN 'CompetitorOffer' WHEN 27 THEN 'CompetitorOffer'
        WHEN 28 THEN 'CompetitorOffer' WHEN 29 THEN 'CompetitorOffer' WHEN 30 THEN 'CompetitorOffer'
        WHEN 31 THEN 'CompetitorOffer' WHEN 32 THEN 'CompetitorOffer' WHEN 33 THEN 'CompetitorOffer'
        WHEN 34 THEN 'CompetitorOffer' WHEN 35 THEN 'CompetitorOffer' WHEN 36 THEN 'CompetitorOffer'
        WHEN 37 THEN 'CompetitorOffer' WHEN 38 THEN 'CompetitorOffer' WHEN 39 THEN 'CompetitorOffer'
        WHEN 40 THEN 'CompetitorOffer' WHEN 41 THEN 'CompetitorOffer' WHEN 42 THEN 'CompetitorOffer'
        WHEN 43 THEN 'CompetitorOffer' WHEN 44 THEN 'CompetitorOffer'
        WHEN 45 THEN 'PaymentStress' WHEN 46 THEN 'PaymentStress' WHEN 47 THEN 'PaymentStress'
        WHEN 48 THEN 'PaymentStress' WHEN 49 THEN 'PaymentStress' WHEN 50 THEN 'PaymentStress'
        WHEN 51 THEN 'PaymentStress' WHEN 52 THEN 'PaymentStress' WHEN 53 THEN 'PaymentStress'
        WHEN 54 THEN 'PaymentStress' WHEN 55 THEN 'PaymentStress' WHEN 56 THEN 'PaymentStress'
        WHEN 57 THEN 'PaymentStress' WHEN 58 THEN 'PaymentStress' WHEN 59 THEN 'PaymentStress'
        WHEN 60 THEN 'LifeEvent' WHEN 61 THEN 'LifeEvent' WHEN 62 THEN 'LifeEvent'
        WHEN 63 THEN 'LifeEvent' WHEN 64 THEN 'LifeEvent' WHEN 65 THEN 'LifeEvent'
        WHEN 66 THEN 'LifeEvent' WHEN 67 THEN 'LifeEvent' WHEN 68 THEN 'LifeEvent'
        WHEN 69 THEN 'LifeEvent' WHEN 70 THEN 'LifeEvent' WHEN 71 THEN 'LifeEvent'
        WHEN 72 THEN 'LifeEvent' WHEN 73 THEN 'LifeEvent' WHEN 74 THEN 'LifeEvent'
        WHEN 75 THEN 'CreditScoreChange' WHEN 76 THEN 'CreditScoreChange' WHEN 77 THEN 'CreditScoreChange'
        WHEN 78 THEN 'CreditScoreChange' WHEN 79 THEN 'CreditScoreChange' WHEN 80 THEN 'CreditScoreChange'
        WHEN 81 THEN 'CreditScoreChange' WHEN 82 THEN 'CreditScoreChange' WHEN 83 THEN 'CreditScoreChange'
        WHEN 84 THEN 'CreditScoreChange' WHEN 85 THEN 'CreditScoreChange' WHEN 86 THEN 'CreditScoreChange'
        WHEN 87 THEN 'CreditScoreChange' WHEN 88 THEN 'CreditScoreChange' WHEN 89 THEN 'CreditScoreChange'
        ELSE 'PropertyValueIncrease'
    END AS signal_type,
    -- Detected date: Within last 90 days
    DATEADD(day, -MOD(ABS(HASH(b.borrower_id || 'sigdt')), 90), CURRENT_DATE()) AS detected_date,
    -- Confidence: 0.4-0.95
    ROUND(0.40 + MOD(ABS(HASH(b.borrower_id || 'conf')), 55) / 100.0, 2) AS confidence,
    -- Details: Templated based on signal type
    CASE MOD(ABS(HASH(b.borrower_id || 'sigtype')), 100)
        WHEN 0 THEN '3 mortgage rate inquiries detected on credit bureau in past 14 days from competing lenders.'
        WHEN 5 THEN '2 rate inquiries from online lenders detected. Borrower visited comparison site.'
        WHEN 10 THEN 'Multiple soft pulls from mortgage lenders detected in 7-day window.'
        WHEN 15 THEN 'Hard inquiry from Wells Fargo Home Lending detected on credit file.'
        WHEN 20 THEN 'Rate shopping behavior: 4 mortgage inquiries across 3 lenders in 21 days.'
        WHEN 25 THEN 'Competitor direct mail campaign detected targeting borrowers in this rate tier.'
        WHEN 30 THEN 'Rocket Mortgage pre-qualification letter received (per credit bureau trigger).'
        WHEN 35 THEN 'Local credit union advertising rates 0.5% below current note rate in borrower ZIP.'
        WHEN 40 THEN 'Better.com targeted email campaign to borrowers with rates above 6%.'
        WHEN 45 THEN 'Payment amount increased to maximum auto-debit limit; potential rate sensitivity.'
        WHEN 50 THEN 'Borrower switched from auto-pay to manual payment; possible cash flow concern.'
        WHEN 55 THEN 'Two consecutive payments received on day 14 (previously day 1); declining payment priority.'
        WHEN 60 THEN 'Employer change detected via payroll verification; new position may enable better terms.'
        WHEN 65 THEN 'Marriage record detected in public records; potential for dual-income refinance.'
        WHEN 70 THEN 'Property listed on Zillow (not for sale); borrower researching home value.'
        WHEN 75 THEN 'Credit score improved 45 points in past 90 days; now eligible for better rate tier.'
        WHEN 80 THEN 'Credit score crossed 740 threshold; qualifies for best-execution pricing.'
        WHEN 85 THEN 'FICO improvement from 680 to 720; significant rate improvement available.'
        WHEN 90 THEN 'AVM indicates 15% property value increase since origination; LTV now below 75%.'
        WHEN 95 THEN 'County reassessment shows property value increase of $85K; improved equity position.'
        ELSE 'Behavioral analytics flagged refinance consideration based on multi-factor score.'
    END AS details,
    -- Actioned: 30% have been acted upon
    CASE WHEN MOD(ABS(HASH(b.borrower_id || 'action')), 100) < 30 THEN TRUE ELSE FALSE END AS actioned
FROM BNK.LENDING.BORROWERS b
WHERE MOD(ABS(HASH(b.borrower_id || 'signal_eligible')), 100) < 25  -- ~25% of 200K = 50K
  AND NOT EXISTS (SELECT 1 FROM BNK.LENDING.REFINANCE_SIGNALS LIMIT 1);

-------------------------------------------------------------------------------
-- INTERACTION_HISTORY (200,000 rows)
-- Diverse channels, topics, and template summaries
-------------------------------------------------------------------------------
INSERT INTO BNK.LENDING.INTERACTION_HISTORY
SELECT
    UUID_STRING() AS interaction_id,
    b.borrower_id,
    -- Channel distribution
    CASE MOD(ABS(HASH(b.borrower_id || i.seq_num || 'chan')), 100)
        WHEN 0 THEN 'Phone' WHEN 1 THEN 'Phone' WHEN 2 THEN 'Phone'
        WHEN 3 THEN 'Phone' WHEN 4 THEN 'Phone' WHEN 5 THEN 'Phone'
        WHEN 6 THEN 'Phone' WHEN 7 THEN 'Phone' WHEN 8 THEN 'Phone'
        WHEN 9 THEN 'Phone' WHEN 10 THEN 'Phone' WHEN 11 THEN 'Phone'
        WHEN 12 THEN 'Phone' WHEN 13 THEN 'Phone' WHEN 14 THEN 'Phone'
        WHEN 15 THEN 'Phone' WHEN 16 THEN 'Phone' WHEN 17 THEN 'Phone'
        WHEN 18 THEN 'Phone' WHEN 19 THEN 'Phone' WHEN 20 THEN 'Phone'
        WHEN 21 THEN 'Phone' WHEN 22 THEN 'Phone' WHEN 23 THEN 'Phone'
        WHEN 24 THEN 'Phone' WHEN 25 THEN 'Phone' WHEN 26 THEN 'Phone'
        WHEN 27 THEN 'Phone' WHEN 28 THEN 'Phone' WHEN 29 THEN 'Phone'
        WHEN 30 THEN 'Phone' WHEN 31 THEN 'Phone' WHEN 32 THEN 'Phone'
        WHEN 33 THEN 'Phone' WHEN 34 THEN 'Phone'
        WHEN 35 THEN 'Email' WHEN 36 THEN 'Email' WHEN 37 THEN 'Email'
        WHEN 38 THEN 'Email' WHEN 39 THEN 'Email' WHEN 40 THEN 'Email'
        WHEN 41 THEN 'Email' WHEN 42 THEN 'Email' WHEN 43 THEN 'Email'
        WHEN 44 THEN 'Email' WHEN 45 THEN 'Email' WHEN 46 THEN 'Email'
        WHEN 47 THEN 'Email' WHEN 48 THEN 'Email' WHEN 49 THEN 'Email'
        WHEN 50 THEN 'Email' WHEN 51 THEN 'Email' WHEN 52 THEN 'Email'
        WHEN 53 THEN 'Email' WHEN 54 THEN 'Email' WHEN 55 THEN 'Email'
        WHEN 56 THEN 'Email' WHEN 57 THEN 'Email' WHEN 58 THEN 'Email'
        WHEN 59 THEN 'Email'
        WHEN 60 THEN 'Branch' WHEN 61 THEN 'Branch' WHEN 62 THEN 'Branch'
        WHEN 63 THEN 'Branch' WHEN 64 THEN 'Branch' WHEN 65 THEN 'Branch'
        WHEN 66 THEN 'Branch' WHEN 67 THEN 'Branch' WHEN 68 THEN 'Branch'
        WHEN 69 THEN 'Branch'
        WHEN 70 THEN 'Portal' WHEN 71 THEN 'Portal' WHEN 72 THEN 'Portal'
        WHEN 73 THEN 'Portal' WHEN 74 THEN 'Portal' WHEN 75 THEN 'Portal'
        WHEN 76 THEN 'Portal' WHEN 77 THEN 'Portal' WHEN 78 THEN 'Portal'
        WHEN 79 THEN 'Portal' WHEN 80 THEN 'Portal' WHEN 81 THEN 'Portal'
        WHEN 82 THEN 'Portal' WHEN 83 THEN 'Portal' WHEN 84 THEN 'Portal'
        WHEN 85 THEN 'Portal' WHEN 86 THEN 'Portal' WHEN 87 THEN 'Portal'
        WHEN 88 THEN 'Portal' WHEN 89 THEN 'Portal'
        ELSE 'Chat'
    END AS channel,
    -- Interaction date: Spread over last 2 years
    DATEADD(day, -MOD(ABS(HASH(b.borrower_id || i.seq_num || 'idate')), 730), CURRENT_DATE()) AS interaction_date,
    -- Topic distribution
    CASE MOD(ABS(HASH(b.borrower_id || i.seq_num || 'topic')), 6)
        WHEN 0 THEN 'PaymentInquiry'
        WHEN 1 THEN 'RateQuestion'
        WHEN 2 THEN 'HardshipRequest'
        WHEN 3 THEN 'RefinanceInquiry'
        WHEN 4 THEN 'EscrowQuestion'
        ELSE 'PayoffRequest'
    END AS topic,
    -- Summary: Templated by topic
    CASE MOD(ABS(HASH(b.borrower_id || i.seq_num || 'topic')), 6)
        WHEN 0 THEN
            CASE MOD(ABS(HASH(b.borrower_id || i.seq_num || 'sum')), 5)
                WHEN 0 THEN 'Borrower called to confirm receipt of last monthly payment. Verified payment posted on ' || DATEADD(day, -MOD(ABS(HASH(b.borrower_id || i.seq_num)), 14), CURRENT_DATE())::VARCHAR || '. No issues found.'
                WHEN 1 THEN 'Borrower inquired about autopay setup. Walked through enrollment process and confirmed bank account details. Autopay will begin next billing cycle.'
                WHEN 2 THEN 'Borrower reported duplicate payment charged to checking account. Investigated and confirmed single payment processed. Provided transaction reference number.'
                WHEN 3 THEN 'Borrower asked about applying extra principal payment. Explained online portal process and confirmed $500 additional principal would not advance due date.'
                ELSE 'Borrower called regarding payment not reflected in online portal. Confirmed 2-business-day processing delay. Payment will appear by end of week.'
            END
        WHEN 1 THEN
            CASE MOD(ABS(HASH(b.borrower_id || i.seq_num || 'sum')), 5)
                WHEN 0 THEN 'Borrower inquired about current refinance rates. Quoted current 30-year fixed at 6.25%. Borrower expressed interest and asked about closing costs. Scheduled callback with loan officer.'
                WHEN 1 THEN 'Borrower asked if ARM rate adjustment is coming. Confirmed next adjustment date and explained SOFR index plus margin calculation. Current rate will adjust in 4 months.'
                WHEN 2 THEN 'Borrower comparing our rates to competitor offer of 5.75%. Discussed total cost comparison including closing costs. Offered to run refinance analysis.'
                WHEN 3 THEN 'Borrower asked about rate lock process for refinance. Explained 30-day and 45-day lock options with associated costs. Borrower wants to wait for further rate movement.'
                ELSE 'Borrower asked why their rate is higher than advertised rates. Explained LLPA adjustments based on credit score and LTV. Suggested credit improvement strategies for future refinance.'
            END
        WHEN 2 THEN
            CASE MOD(ABS(HASH(b.borrower_id || i.seq_num || 'sum')), 5)
                WHEN 0 THEN 'Borrower reported job loss and inability to make next payment. Discussed forbearance options. Mailed hardship application packet. Advised to return within 30 days with supporting documentation.'
                WHEN 1 THEN 'Borrower experiencing medical emergency with significant out-of-pocket costs. Explained forbearance program and COVID-era protections no longer available. Started loss mitigation intake.'
                WHEN 2 THEN 'Borrower going through divorce and requesting temporary payment reduction. Discussed forbearance and modification options. Borrower will submit hardship letter and financial documentation.'
                WHEN 3 THEN 'Follow-up call on existing forbearance case. Borrower confirmed continued hardship. Extended forbearance for additional 3 months per policy. New end date communicated.'
                ELSE 'Borrower requesting information about disaster forbearance following recent flooding. Confirmed property is in declared disaster area. Initiated 90-day disaster forbearance per FEMA declaration.'
            END
        WHEN 3 THEN
            CASE MOD(ABS(HASH(b.borrower_id || i.seq_num || 'sum')), 5)
                WHEN 0 THEN 'Borrower interested in cash-out refinance to consolidate debt. Discussed LTV requirements and estimated new payment. Borrower has sufficient equity. Transferred to refinance specialist.'
                WHEN 1 THEN 'Borrower asking about streamline refinance options. Confirmed FHA streamline eligibility (current on payments, net tangible benefit). Quoted reduced documentation requirements.'
                WHEN 2 THEN 'Borrower wants to refinance from ARM to fixed rate before next adjustment. Ran comparison showing fixed rate saves $200/month over remaining ARM life. Borrower requested formal application.'
                WHEN 3 THEN 'Borrower inquired about refinancing to remove PMI. Current LTV estimated at 72% based on recent AVM. Discussed options: refinance vs. PMI cancellation request. Borrower prefers cancellation path.'
                ELSE 'Borrower considering refinance to shorten term from 30 to 15 years. Ran amortization comparison showing interest savings of $145,000 over life of loan. Borrower needs to discuss with spouse.'
            END
        WHEN 4 THEN
            CASE MOD(ABS(HASH(b.borrower_id || i.seq_num || 'sum')), 5)
                WHEN 0 THEN 'Borrower received escrow analysis showing payment increase of $185/month due to property tax reassessment. Explained breakdown and offered to spread shortage over 12 months.'
                WHEN 1 THEN 'Borrower asking why escrow payment increased. Explained insurance premium renewal came in $800 higher than prior year. Suggested shopping for new insurance policy to reduce escrow.'
                WHEN 2 THEN 'Borrower requesting escrow account removal. Confirmed loan is conventional with LTV below 80%. Processed escrow waiver with 0.25% rate adjustment per policy.'
                WHEN 3 THEN 'Borrower reported receiving surplus escrow check and wants to confirm account is correct. Verified annual analysis showed $342 surplus. Account in good standing.'
                ELSE 'Borrower confused about escrow shortage vs. deficiency. Explained difference and offered lump-sum payoff option for shortage amount of $1,200. Borrower elected 12-month spread.'
            END
        ELSE
            CASE MOD(ABS(HASH(b.borrower_id || i.seq_num || 'sum')), 5)
                WHEN 0 THEN 'Borrower requesting payoff quote for planned home sale. Generated 30-day payoff statement and emailed to borrower. Closing scheduled for next month. Provided wire instructions.'
                WHEN 1 THEN 'Borrower asked about partial payoff to reduce balance below $100K. Explained minimum payment requirements and that partial payoff does not change monthly payment. Borrower proceeding.'
                WHEN 2 THEN 'Borrower inheriting property and wants to pay off existing mortgage. Explained payoff process, wire vs check options, and lien release timeline. Provided per diem interest amount.'
                WHEN 3 THEN 'Borrower refinancing with another lender and needs updated payoff. Generated payoff good through 30 days. New lender to wire funds per standard instructions.'
                ELSE 'Borrower asking about bi-weekly payment program to accelerate payoff. Explained program saves approximately 6 years on 30-year mortgage. Enrolled borrower in bi-weekly autopay.'
            END
    END AS summary,
    -- Agent name
    CASE MOD(ABS(HASH(b.borrower_id || i.seq_num || 'agent')), 12)
        WHEN 0 THEN 'Sarah Chen' WHEN 1 THEN 'Marcus Williams' WHEN 2 THEN 'Jennifer Park'
        WHEN 3 THEN 'David Rodriguez' WHEN 4 THEN 'Amanda Foster' WHEN 5 THEN 'Kevin O''Brien'
        WHEN 6 THEN 'Lisa Thompson' WHEN 7 THEN 'James Mitchell' WHEN 8 THEN 'Rachel Patel'
        WHEN 9 THEN 'Brian Jackson' WHEN 10 THEN 'Nicole Adams' ELSE 'Christopher Lee'
    END AS agent_name,
    -- Outcome
    CASE MOD(ABS(HASH(b.borrower_id || i.seq_num || 'outcome')), 8)
        WHEN 0 THEN 'Resolved'
        WHEN 1 THEN 'Resolved'
        WHEN 2 THEN 'Resolved'
        WHEN 3 THEN 'FollowUpScheduled'
        WHEN 4 THEN 'FollowUpScheduled'
        WHEN 5 THEN 'TransferredToSpecialist'
        WHEN 6 THEN 'EscalatedToSupervisor'
        ELSE 'RefinanceApplicationStarted'
    END AS outcome
FROM BNK.LENDING.BORROWERS b
CROSS JOIN (
    SELECT ROW_NUMBER() OVER (ORDER BY SEQ4()) AS seq_num
    FROM TABLE(GENERATOR(ROWCOUNT => 2))
) i
WHERE MOD(ABS(HASH(b.borrower_id || i.seq_num || 'interact')), 100) < 50  -- ~50% of 200K * 2 = 200K
  AND NOT EXISTS (SELECT 1 FROM BNK.LENDING.INTERACTION_HISTORY LIMIT 1);
