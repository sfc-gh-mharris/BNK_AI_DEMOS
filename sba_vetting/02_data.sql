/*=============================================================================
  SBA Borrower and Program Integrity (NSBPS / SBAID) - Data Population
  Database: BNK | Schema: SBA_VETTING | Warehouse: BNK_WH

  Populates:
  - SBA_SOP_POLICIES: 16 authoritative SBA SOP 50 10 8.1 / 13 CFR / OIG rules
  - SBA_BUSINESSES: 50,000 unified SBAID small business profiles
  - BENEFICIAL_OWNERS: 75,000 direct and indirect principals
  - SBA_APPLICATIONS: 100,000 cross-program E-Tran, Disaster, and 8(a) filings
  - SBA_DOCUMENTS_METADATA: 200,000 document records (including 20 staged PDFs)
  - SBA_VERIFICATION_RESULTS: 1:1 baseline results for Completed synthetic docs
  - FEDERAL_EXCLUSION_ALERTS: 25,000 CAIVRS, SAM.gov, Do Not Pay, and OIG alerts
=============================================================================*/

USE DATABASE BNK;
USE SCHEMA SBA_VETTING;
USE WAREHOUSE BNK_WH;

-------------------------------------------------------------------------------
-- Idempotent reset in reverse foreign-key order
-------------------------------------------------------------------------------
TRUNCATE TABLE IF EXISTS BNK.SBA_VETTING.FEDERAL_EXCLUSION_ALERTS;
TRUNCATE TABLE IF EXISTS BNK.SBA_VETTING.SBA_VERIFICATION_RESULTS;
TRUNCATE TABLE IF EXISTS BNK.SBA_VETTING.SBA_DOCUMENTS_METADATA;
TRUNCATE TABLE IF EXISTS BNK.SBA_VETTING.SBA_APPLICATIONS;
TRUNCATE TABLE IF EXISTS BNK.SBA_VETTING.BENEFICIAL_OWNERS;
TRUNCATE TABLE IF EXISTS BNK.SBA_VETTING.SBA_BUSINESSES;
TRUNCATE TABLE IF EXISTS BNK.SBA_VETTING.SBA_SOP_POLICIES;

-------------------------------------------------------------------------------
-- 1. SBA_SOP_POLICIES (16 authoritative SBA SOP / Policy Notice / 13 CFR rules)
-------------------------------------------------------------------------------
INSERT INTO BNK.SBA_VETTING.SBA_SOP_POLICIES (
    policy_id, title, program_scope, category, effective_date, authority_citation, content
)
SELECT
    column1, column2, column3, column4, TRY_TO_DATE(column5), column6, column7
FROM VALUES
('SOP-CIT-001',
 '100 Percent U.S. Citizen Direct and Indirect Ownership Requirement',
 '7a_504', 'CitizenshipOwnership', '2026-03-01',
 'SBA SOP 50 10 8.1 Ch. 2 Para. F / SBA Policy Notice 5000-876441',
 'Effective March 1, 2026 under SBA Policy Notice 5000-876441 and codified in SOP 50 10 8.1, 100 percent of all direct and indirect owners, guarantors, and key principals of an Applicant small business for 7(a) and 504 loans must be United States citizens or United States nationals whose primary residence is within the United States or its territories. The prior allowance permitting up to 5 percent foreign or non-resident ownership and the prior eligibility of Lawful Permanent Residents (LPRs) are rescinded for applications submitted or approved on or after March 1, 2026. Any direct or indirect ownership interest greater than 0 percent held by a foreign national, non-resident individual, or undocumented alien renders the Applicant statutorily ineligible for SBA financial assistance unless that ineligible interest is 100 percent divested prior to application submission. Lenders and SBA Loan Specialists must enter date of birth and citizenship verification confirmations for 100 percent of owners into E-Tran prior to loan guaranty number issuance.'),

('SOP-CIT-002',
 'Multi-Tier Holding Company and Beneficial Ownership Tracing',
 'AllPrograms', 'CitizenshipOwnership', '2026-03-01',
 'SBA SOP 50 10 8.1 / SBA Form 1919 Ownership Disclosure Rules',
 'When any equity interest in an SBA Applicant is held by a legal entity such as a parent LLC, corporation, trust, or limited partnership, the Lender and SBA reviewer must obtain the Operating Agreement, partnership ledger, or corporate shareholder register for every intermediate tier until 100 percent of effective ownership is traced to natural persons. Applicant self-attestation on SBA Form 1919 is insufficient when entity owners exist. If a parent entity owns 40 percent of the Applicant and a foreign non-resident individual owns 25 percent of that parent entity, the Applicant has 10 percent effective indirect foreign ownership and must be declined as Ineligible_Ownership under SOP-CIT-001. Any discrepancy between the applicant''s E-Tran 100 percent U.S. citizen attestation and the underlying Operating Agreement must be logged in the loan file and flagged for false-statement review.'),

('SOP-AGE-001',
 'Mandatory Date of Birth Verification and Statutory Age Fraud Guardrails',
 'AllPrograms', 'AgeIdentityGuardrail', '2025-04-10',
 'SBA News Release 25-42 / OCA Identity Verification Controls',
 'All SBA loan and disaster assistance applications require verified Date of Birth (DOB) entry for every sole proprietor, 20 percent or greater owner, managing member, and guarantor. Following federal audits that uncovered improper pandemic disbursements to synthetic or stolen identities of minors and centenarians, SBA enforces automatic pre-disbursement age guardrails: (1) Any principal whose extracted or entered DOB indicates an age younger than 18 years old at application date is automatically blocked from approval. (2) Any principal whose DOB indicates an age older than 115 years old is automatically flagged as a high-probability deceased or synthetic SSN identity and placed in AutoBlocked_AgeOrDeath status with zero disbursement permitted. Automatic age blocks require cross-checking against Social Security Administration records and referral to the SBA Office of Inspector General (OIG).'),

('SOP-DNP-001',
 'Treasury Do Not Pay and SSA Death Master File Pre-Award Screening',
 'AllPrograms', 'AgeIdentityGuardrail', '2025-06-01',
 'Payment Integrity Information Act (31 U.S.C. 3354) / SBA SOP 50 10 8.1',
 'Prior to issuing an E-Tran loan guaranty number, disbursing Disaster EIDL funds, or conferring contracting certification, SBA screens the Applicant EIN, UEI, and all principal SSNs/TINs against the U.S. Department of the Treasury Do Not Pay portal, including the Social Security Administration Death Master File (DMF). A positive Death Master File match on a listed guarantor or 100 percent owner triggers an immediate Critical alert (DoNotPay_DeathMaster), places the application in AutoBlocked_AgeOrDeath status, prohibits fund disbursement, and generates an automated fraud referral package for SBA OIG.'),

('SOP-TAX-001',
 'Mandatory Pre-Closing IRS Form 4506-C Tax Transcript Verification',
 '7a_504', 'TaxVerification', '2025-06-01',
 'SBA SOP 50 10 8 / SOP 50 10 8.1 Financial Verification Requirements',
 'SBA has rescinded streamlined underwriting exceptions that omitted independent tax verification. For all 7(a) and 504 loans, Lenders and SBA specialists must execute IRS Form 4506-C through the IRS Income Verification Express Service (IVES) to obtain official business tax return transcripts (IRS Form 1120, Form 1120-S, Form 1065, or Schedule C) prior to loan closing and disbursement. Reviewers must reconcile Line 1a Gross Receipts and W-2 Payroll on the IRS transcript against the stated annual revenue and payroll on SBA Form 1919: (1) Variances up to 10 percent may be cleared with CPA accrual-to-cash workpapers. (2) Variances between 10 percent and 50 percent require manual underwriting re-sizing. (3) Stated revenue exceeding IRS transcript gross receipts by more than 50 percent constitutes a critical misrepresentation indicator requiring immediate application hold (HoldAndReferOIG) and referral to SBA OIG.'),

('SOP-EXC-001',
 'CAIVRS Federal Debt Delinquency and Prior Loss Screening',
 'AllPrograms', 'FederalExclusions', '2025-06-01',
 '31 CFR 285.13 / SBA SOP 50 10 8.1 CAIVRS Mandate',
 'Every Applicant business and every owner or guarantor with 20 percent or greater equity must be screened through the Credit Alert Verification Reporting System (CAIVRS) and retained in the loan file. Under 31 CFR 285.13 and SBA SOP 50 10 8.1, an Applicant is ineligible for SBA financial assistance if the business or any principal has an unresolved delinquent federal debt, defaulted FHA/VA/USDA/HUD loan, charged-off prior SBA loan, or unpaid federal tax lien reported in CAIVRS, unless the creditor agency issues written confirmation that the delinquency is resolved or in a compliant repayment plan.'),

('SOP-EXC-002',
 'SAM.gov Debarment, Suspension, and Federal Exclusion Screening',
 'AllPrograms', 'FederalExclusions', '2025-06-01',
 '2 CFR Part 180 / 2 CFR Part 2700 / SBA SOP 50 10 8.1',
 'SBA and participating lenders must verify the Applicant entity (by Legal Name, EIN, and UEI), all principals, and any Form 159 fee-based agent against the System for Award Management (SAM.gov) Exclusions database. Any active debarment, suspension, proposed debarment, or voluntary exclusion disqualifies the Applicant from 7(a), 504, Disaster EIDL, and federal contracting programs immediately.'),

('SOP-HLD-001',
 'Unresolved Pandemic Assistance Hold Codes (COVID EIDL and PPP)',
 'AllPrograms', 'FederalExclusions', '2025-10-01',
 'SBA OIG Report 26-01 / OCA Cross-Program Hold Code Policy',
 'Before approving any new 7(a), Made in America 7(a), 504, or Disaster loan, SBA cross-references the unified small business identifier (SBAID) and principal SSNs against legacy Paycheck Protection Program (PPP), COVID-19 EIDL, Restaurant Revitalization Fund (RRF), and SVOG compliance ledgers. If the Applicant or any common beneficial owner carries an active unresolved fraud, identity theft, or eligibility hold code (such as HOLD-EIDL-09 or HOLD-PPP-14), new loan authorization is prohibited. The specialist must place the application in Hold_OIGReferral status until the Office of Capital Access (OCA) Compliance Review Committee or SBA OIG formally clears the hold code.'),

('SOP-PKG-001',
 'Fee-Based Loan Packagers, Brokers, and Form 159 Agent Fraud Controls',
 '7a_504', 'PackagerOversight', '2025-12-18',
 '13 CFR Part 103 / SBA Form 159 / SBA OIG Report 26-01',
 'SBA OIG investigations have identified recurring fraud rings orchestrated by fee-based loan packagers and unregistered agents submitting fabricated tax returns and inflated payroll schedules across dozens of unrelated shell companies. Every third-party packager, referral agent, or broker compensated by the Applicant or Lender must be disclosed on SBA Form 159 with a unique Packager Agent ID. Any application associated with a Packager Agent ID on the OIG_PackagerWatchlist requires mandatory Enhanced Due Diligence (EDD): direct IRS IVES 4506-C transcript verification, independent bank statement verification, beneficial-owner ring link analysis across all SBAIDs sharing that packager, and supervisory sign-off (or OIG referral if discrepancies appear).'),

('SOP-SIZ-001',
 'Small Business Size Standards and Affiliation Aggregation',
 'AllPrograms', 'SizeAndNAICS', '2025-06-01',
 '13 CFR Part 121 / SBA Table of Small Business Size Standards',
 'To qualify as a small business for SBA lending and contracting, the Applicant combined with all domestic and foreign affiliates (entities under common ownership or control under 13 CFR 121.301) must not exceed the numerical size standard for its primary 6-digit NAICS industry code. Manufacturing industries (NAICS 31-33) are governed by employee headcount caps (for example, 500 employees for NAICS 332710 Machine Shops), calculated as average employment over the preceding 24 calendar months. Service and construction industries are typically governed by 5-year average annual receipts caps (for example, $45.0M for NAICS 236220 Commercial Building Construction and $34.0M for NAICS 541512 Computer Systems Design).'),

('SOP-MIA-001',
 'Made in America Manufacturing 7(a) Guaranty Eligibility and Priority Review',
 '7a_504', 'SizeAndNAICS', '2026-01-15',
 'SBA Made in America Manufacturing Initiative / SOP 50 10 8.1',
 'Small business manufacturers operating in NAICS Sectors 31, 32, or 33 (such as precision machining, tool and die, electronics assembly, and metal fabrication) qualify for priority Made in America 7(a) working capital and equipment guarantees up to $5,000,000 when they satisfy four criteria: (1) 100 percent verified U.S. citizen direct and indirect ownership under SOP-CIT-001, (2) employee headcount within the 13 CFR 121 NAICS cap, (3) clean IRS Form 4506-C tax transcript reconciliation within 10 percent of stated Form 1919 receipts, and (4) zero open CAIVRS, SAM.gov, Do Not Pay, or pandemic hold-code alerts.'),

('SOP-8A-001',
 '8(a) Business Development Unconditional Ownership and Control Audit',
 '8a_Contracting', 'ContractingControl', '2025-06-27',
 '13 CFR 124.105 & 124.106 / SBA News Release 25-56 (8(a) Full-Scale Audit)',
 'Under 13 CFR 124.105 and 124.106, an 8(a) participant must be at least 51 percent unconditionally and directly owned by one or more socially and economically disadvantaged U.S. citizens, AND those qualifying individuals must control both the board/strategic governance and day-to-day management and banking operations. Operating Agreement clauses that vest sole bank signatory authority, executive compensation veto rights, or contract-binding vetoes in a non-disadvantaged minority member or corporate investor violate 13 CFR 124.106 unconditional control requirements. Pursuant to Administrator Loeffler''s full-scale 8(a) audit directive, any participant whose Operating Agreement or financial records reveal non-disadvantaged control must be flagged as ControlDeficiency_8a, placed on contract award suspension, and initiated for 8(a) program termination and OIG review.'),

('SOP-8A-002',
 'Limitations on Subcontracting and Pass-Through Front Enforcement',
 '8a_Contracting', 'ContractingControl', '2025-12-05',
 '13 CFR 125.6 / 13 CFR 124.510 / SBA Mandatory 8(a) Financial Record Review',
 'To prevent illegal pass-through fronts in federal small-business set-aside contracting, 13 CFR 125.6 prohibits an 8(a), WOSB, VetCert SDVOSB, or HUBZone prime contractor on a services contract from paying more than 50 percent of the amount paid by the federal agency to firms that are not similarly situated small businesses (85 percent cap for general construction). Any Operating Agreement addendum, joint-venture schedule, or financial ledger showing that an 8(a) firm subcontracts more than 50 percent of contract revenue (for example 85 percent pass-through to a non-disadvantaged investor''s affiliate) constitutes a severe pass-through violation requiring immediate ControlDeficiency_8a classification, contracting officer notification, suspension, and OIG False Claims Act referral.'),

('SOP-DIS-001',
 'Disaster Business Loan (EIDL) Pre-Disbursement Identity and Operations Verification',
 'Disaster', 'AgeIdentityGuardrail', '2025-06-01',
 '13 CFR Part 123 / SBA Office of Disaster Recovery & Resilience Controls',
 'Prior to approving or disbursing any physical or Economic Injury Disaster Loan (EIDL), SBA Disaster specialists must verify: (1) active Secretary of State business registration predating the declared disaster date, (2) principal identity and statutory age guardrails (<18 and >115 checks) plus Do Not Pay Death Master File clearance, (3) IRS Form 4506-C pre-disaster tax return transcript confirming pre-disaster economic operations, and (4) physical occupancy evidence in the declared disaster county.'),

('SOP-STK-001',
 'Cross-Program Loan Stacking and Beneficial-Owner Ring Detection',
 'AllPrograms', 'PackagerOversight', '2026-01-15',
 'SBA SOP 50 10 8.1 Aggregate Guaranty Cap ($5M) / NSBPS SBAID Standard',
 'Under 15 U.S.C. 636(a)(3), the maximum aggregate SBA-guaranteed 7(a) exposure to any Applicant together with its affiliates (entities sharing 20 percent+ common beneficial owners, EINs, or management control resolved under a common SBAID cluster) cannot exceed $5,000,000 ($5,500,000 for 504 manufacturing/energy projects). Concurrent applications submitted across multiple 7(a) lenders, CDCs, and Disaster offices within a 90-day window trigger a CrossProgramStacking alert requiring unified SBAID exposure aggregation and fraud velocity review before E-Tran authorization.'),

('SOP-DOC-001',
 'Portal Document Mislabeling Detection and AI Extraction Review Thresholds',
 'AllPrograms', 'TaxVerification', '2026-01-15',
 'SBA OCIO / OCA Automated Document Vetting Standard',
 'Applicants and lenders frequently upload incorrect document types into E-Tran and MySBA Certify slots (for example uploading an internal LLC Operating Agreement or unaudited QuickBooks sheet into the mandatory IRS Form 4506-C Tax Transcript slot). Automated AI classification must verify that the document content matches the declared_doc_type; any mismatch sets doc_type_mismatch_detected = TRUE, blocks automated approval, and requires re-indexing and upload of the missing statutory artifact. Extracted fields with confidence scores below 0.80 require human specialist inspection.');

-------------------------------------------------------------------------------
-- 2. SBA_BUSINESSES (49,995 synthetic + 5 isolated hero showcase SBAIDs = 50,000)
-------------------------------------------------------------------------------
INSERT INTO BNK.SBA_VETTING.SBA_BUSINESSES (
    sba_id, ein, uei_sam, legal_name, dba_name, entity_structure,
    naics_code, naics_description, naics_size_cap_employees, naics_size_cap_revenue_usd,
    state_code, formation_date, employee_count, stated_annual_revenue_usd,
    stated_annual_payroll_usd, us_citizen_ownership_attested,
    prior_ppp_eidl_status, prior_hold_code, risk_tier
)
WITH pools AS (
    SELECT
        ARRAY_CONSTRUCT(
            'Summit','Heartland','Blue Ridge','Cascade','Great Lakes','Lone Star','Palmetto','Allegheny','Keystone','Prairie',
            'Buckeye','Bayou','Granite','Hoosier','Cumberland','Chesapeake','Front Range','Redwood','Ozark','Shenandoah',
            'Ironworks','Pioneer','Patriot','Continental','Vanguard','Midwest','Atlantic','Pacific','Centennial','Liberty'
        ) AS prefixes,
        ARRAY_CONSTRUCT(
            'Precision Machining','HVAC Services','Timber Fabricators','Tool and Die','Medical Supply',
            'Cold Storage','Industrial Automation','Electrical Contractors','Specialty Packaging','Agri Equipment',
            'Composite Materials','Commercial Plumbing','Freight Logistics','Cyber Solutions','Dental Partners',
            'Sheet Metal Works','Civil Engineering','Food Processing','Auto Diagnostics','Environmental Testing'
        ) AS cores,
        ARRAY_CONSTRUCT('LLC','Inc','Corp','LLC','S Corp') AS suffixes,
        ARRAY_CONSTRUCT('LLC','S_Corp','C_Corp','SoleProprietorship','LimitedPartnership') AS structures,
        ARRAY_CONSTRUCT('332710','238220','321992','333514','423450','493120','541512','238210','322211','484121') AS naics_codes,
        ARRAY_CONSTRUCT(
            'Machine Shops','Plumbing and HVAC Contractors','Prefabricated Wood Manufacturing','Special Die and Tool Manufacturing','Medical Equipment Wholesalers',
            'Refrigerated Warehousing','Computer Systems Design Services','Electrical Contractors','Corrugated Box Manufacturing','General Freight Trucking'
        ) AS naics_descs,
        ARRAY_CONSTRUCT(500, NULL, 500, 500, 200, NULL, NULL, NULL, 750, NULL) AS emp_caps,
        ARRAY_CONSTRUCT(NULL, 19000000, NULL, NULL, NULL, 36500000, 34000000, 19000000, NULL, 34000000) AS rev_caps,
        ARRAY_CONSTRUCT(
            'OH','TX','FL','VA','GA','PA','MI','NC','IL','IN',
            'TN','MO','WI','AZ','WA','CO','SC','AL','KY','IA'
        ) AS states
),
gen AS (
    SELECT
        SEQ4() AS seq,
        'SBAID-' || LPAD(SEQ4()::VARCHAR, 7, '0') AS sba_id,
        LPAD(UNIFORM(10, 98, RANDOM())::VARCHAR, 2, '0') || '-' || LPAD(UNIFORM(1000000, 9999999, RANDOM())::VARCHAR, 7, '0') AS ein,
        UPPER(SUBSTR(REPLACE(UUID_STRING(), '-', ''), 1, 12)) AS uei_sam,
        UNIFORM(0, 29, RANDOM()) AS idx_pre,
        UNIFORM(0, 19, RANDOM()) AS idx_core,
        UNIFORM(0, 4, RANDOM()) AS idx_suf,
        UNIFORM(0, 9, RANDOM()) AS idx_naics,
        UNIFORM(0, 19, RANDOM()) AS idx_state,
        UNIFORM(365, 9000, RANDOM()) AS form_days_ago,
        UNIFORM(3, 180, RANDOM()) AS emp_cnt,
        UNIFORM(250, 18000, RANDOM()) * 1000 AS rev_usd,
        UNIFORM(1, 100, RANDOM()) AS r_cit,
        UNIFORM(1, 100, RANDOM()) AS r_prior,
        UNIFORM(1, 100, RANDOM()) AS r_risk
    FROM TABLE(GENERATOR(ROWCOUNT => 49995))
)
SELECT
    g.sba_id,
    g.ein,
    g.uei_sam,
    p.prefixes[g.idx_pre]::VARCHAR || ' ' || p.cores[g.idx_core]::VARCHAR || ' ' || (g.seq % 900 + 100)::VARCHAR || ' ' || p.suffixes[g.idx_suf]::VARCHAR AS legal_name,
    NULL AS dba_name,
    p.structures[g.idx_suf]::VARCHAR AS entity_structure,
    p.naics_codes[g.idx_naics]::VARCHAR AS naics_code,
    p.naics_descs[g.idx_naics]::VARCHAR AS naics_description,
    p.emp_caps[g.idx_naics]::INTEGER AS naics_size_cap_employees,
    p.rev_caps[g.idx_naics]::NUMBER(15,2) AS naics_size_cap_revenue_usd,
    p.states[g.idx_state]::VARCHAR AS state_code,
    DATEADD('day', -g.form_days_ago, CURRENT_DATE()) AS formation_date,
    g.emp_cnt AS employee_count,
    g.rev_usd::NUMBER(15,2) AS stated_annual_revenue_usd,
    ROUND(g.rev_usd * 0.31, 2)::NUMBER(15,2) AS stated_annual_payroll_usd,
    IFF(g.r_cit <= 97, TRUE, FALSE) AS us_citizen_ownership_attested,
    CASE
        WHEN g.r_prior <= 45 THEN 'None'
        WHEN g.r_prior <= 80 THEN 'Forgiven_PaidInFull'
        WHEN g.r_prior <= 93 THEN 'Active_Performing'
        WHEN g.r_prior <= 97 THEN 'HoldCode_FraudReview'
        ELSE 'ChargedOff_Delinquent'
    END AS prior_ppp_eidl_status,
    CASE
        WHEN g.r_prior BETWEEN 94 AND 97 THEN 'HOLD-EIDL-09'
        WHEN g.r_prior > 97 THEN 'HOLD-PPP-14'
        ELSE NULL
    END AS prior_hold_code,
    CASE
        WHEN g.r_risk <= 62 THEN 'Low'
        WHEN g.r_risk <= 85 THEN 'Medium'
        WHEN g.r_risk <= 95 THEN 'High'
        ELSE 'EDD'
    END AS risk_tier
FROM gen g
CROSS JOIN pools p;

-- Insert the 5 deterministic SBA Showcase Businesses (SBAID-DEMO-001 through SBAID-DEMO-005)
INSERT INTO BNK.SBA_VETTING.SBA_BUSINESSES (
    sba_id, ein, uei_sam, legal_name, dba_name, entity_structure,
    naics_code, naics_description, naics_size_cap_employees, naics_size_cap_revenue_usd,
    state_code, formation_date, employee_count, stated_annual_revenue_usd,
    stated_annual_payroll_usd, us_citizen_ownership_attested,
    prior_ppp_eidl_status, prior_hold_code, risk_tier
)
SELECT
    column1, column2, column3, column4, column5, column6,
    column7, column8, column9, column10,
    column11, TRY_TO_DATE(column12), column13, column14,
    column15, column16, column17, column18, column19
FROM VALUES
    ('SBAID-DEMO-001', '34-8821904', 'A1P9E4X7M2C8', 'Apex Precision Machining LLC', 'Apex Machining', 'LLC',
     '332710', 'Machine Shops', 500, NULL,
     'OH', '2014-06-12', 42, 4820000.00, 1640000.00, TRUE,
     'Forgiven_PaidInFull', NULL, 'Low'),
    ('SBAID-DEMO-002', '76-4410982', 'H4L9V2X8M1N5', 'Harborview Logistics Group LLC', NULL, 'LLC',
     '484121', 'General Freight Trucking, Long-Distance', NULL, 34000000.00,
     'TX', '2019-03-20', 64, 9100000.00, 3250000.00, TRUE,
     'Active_Performing', NULL, 'High'),
    ('SBAID-DEMO-003', '59-7730218', 'S7B3N8L2K9M4', 'Sunbelt Staffing Solutions Inc', NULL, 'S_Corp',
     '561311', 'Employment Placement Agencies', NULL, 34000000.00,
     'FL', '2021-02-18', 28, 3400000.00, 920000.00, TRUE,
     'HoldCode_FraudReview', 'HOLD-EIDL-09', 'EDD'),
    ('SBAID-DEMO-004', '58-9034112', 'M2P8R5T1K6W3', 'Metro Property Restoration LLC', NULL, 'LLC',
     '236118', 'Residential Remodelers', NULL, 45000000.00,
     'GA', '2022-08-05', 9, 1250000.00, 380000.00, TRUE,
     'None', NULL, 'EDD'),
    ('SBAID-DEMO-005', '54-6198320', 'J8K4M9P2Q7R1', 'Potomac Cyber Defense LLC', NULL, 'LLC',
     '541512', 'Computer Systems Design Services', NULL, 34000000.00,
     'VA', '2020-11-09', 19, 6450000.00, 1180000.00, TRUE,
     'None', NULL, 'High');

-------------------------------------------------------------------------------
-- 3. BENEFICIAL_OWNERS (74,991 synthetic + 9 showcase principals = 75,000 rows)
-------------------------------------------------------------------------------
INSERT INTO BNK.SBA_VETTING.BENEFICIAL_OWNERS (
    owner_id, sba_id, full_name, title, ownership_pct, ownership_type,
    parent_entity_name, citizenship_status, resides_in_us, date_of_birth,
    ssn_last4, is_disadvantaged_qualifying, has_unconditional_control
)
WITH synth_biz AS (
    SELECT sba_id, ROW_NUMBER() OVER (ORDER BY sba_id) AS rn
    FROM BNK.SBA_VETTING.SBA_BUSINESSES
    WHERE sba_id NOT LIKE 'SBAID-DEMO-%'
),
pools AS (
    SELECT
        ARRAY_CONSTRUCT(
            'Robert','Patricia','Michael','Jennifer','David','Sarah','William','Elizabeth','Richard','Angela',
            'Thomas','Rebecca','Daniel','Hannah','Matthew',' Rachel','Anthony','Monica','Steven','Claire',
            'Carlos','Elena','Marcus','Priya','Kenneth','Natalie','Gregory','Laura','Jason','Megan'
        ) AS first_names,
        ARRAY_CONSTRUCT(
            'Miller','Callahan','Alvarez','Brooks','Whitaker','Morales','Okafor','Zimmerman','McAllister','Cho',
            'Kowalski','Beaulieu','Hendrickson','Boone','Reynolds','Vance','Delgado','Campbell','Foster','bennett',
            'Sullivan','ramirez','Nguyen','Patel','Peterson','Coleman','Jenkins','Powell','Perry','Long'
        ) AS last_names,
        ARRAY_CONSTRUCT('Managing Member','President','CEO','Vice President','Co-Owner') AS titles
),
gen AS (
    SELECT
        SEQ4() AS seq,
        UUID_STRING() AS owner_id,
        UNIFORM(0, 29, RANDOM()) AS idx_fn,
        UNIFORM(0, 29, RANDOM()) AS idx_ln,
        UNIFORM(0, 4, RANDOM()) AS idx_title,
        UNIFORM(1, 100, RANDOM()) AS r_cit,
        UNIFORM(10000, 26000, RANDOM()) AS dob_days_ago,
        LPAD(UNIFORM(1000, 9999, RANDOM())::VARCHAR, 4, '0') AS ssn4
    FROM TABLE(GENERATOR(ROWCOUNT => 74991))
)
SELECT
    g.owner_id,
    sb.sba_id,
    TRIM(p.first_names[g.idx_fn]::VARCHAR) || ' ' || INITCAP(TRIM(p.last_names[g.idx_ln]::VARCHAR)) AS full_name,
    p.titles[g.idx_title]::VARCHAR AS title,
    IFF(g.seq < 49995, 100.0, 50.0) AS ownership_pct,
    IFF(g.r_cit <= 92, 'Direct', 'Indirect_ParentEntity') AS ownership_type,
    IFF(g.r_cit <= 92, NULL, 'Regional Holdings Group LLC') AS parent_entity_name,
    CASE
        WHEN g.r_cit <= 95 THEN 'US_Citizen'
        WHEN g.r_cit <= 97 THEN 'US_National'
        WHEN g.r_cit = 98 THEN 'LawfulPermanentResident'
        WHEN g.r_cit = 99 THEN 'ForeignNational_NonResident'
        ELSE 'Undocumented_Ineligible'
    END AS citizenship_status,
    IFF(g.r_cit <= 98, TRUE, FALSE) AS resides_in_us,
    DATEADD('day', -g.dob_days_ago, CURRENT_DATE()) AS date_of_birth,
    g.ssn4 AS ssn_last4,
    IFF(MOD(g.seq, 5) = 0, TRUE, FALSE) AS is_disadvantaged_qualifying,
    TRUE AS has_unconditional_control
FROM gen g
JOIN synth_biz sb ON sb.rn = MOD(g.seq, 49995) + 1
CROSS JOIN pools p;

-- Showcase Beneficial Owners (exact match to staged PDFs)
INSERT INTO BNK.SBA_VETTING.BENEFICIAL_OWNERS (
    owner_id, sba_id, full_name, title, ownership_pct, ownership_type,
    parent_entity_name, citizenship_status, resides_in_us, date_of_birth,
    ssn_last4, is_disadvantaged_qualifying, has_unconditional_control
)
SELECT
    column1, column2, column3, column4, column5, column6,
    column7, column8, column9, TRY_TO_DATE(column10),
    column11, column12, column13
FROM VALUES
    ('OWN-DEMO-001A', 'SBAID-DEMO-001', 'David R. Miller', 'Managing Member', 65.0, 'Direct', NULL, 'US_Citizen', TRUE, '1978-05-14', '3108', FALSE, TRUE),
    ('OWN-DEMO-001B', 'SBAID-DEMO-001', 'Sarah K. Miller', 'Member & CFO', 35.0, 'Direct', NULL, 'US_Citizen', TRUE, '1980-11-22', '7742', FALSE, TRUE),
    ('OWN-DEMO-002A', 'SBAID-DEMO-002', 'Michael T. Reynolds', 'Managing Member', 60.0, 'Direct', NULL, 'US_Citizen', TRUE, '1975-03-09', '5521', FALSE, TRUE),
    ('OWN-DEMO-002B', 'SBAID-DEMO-002', 'Elena V. Reynolds', 'Limited Partner', 30.0, 'Indirect_ParentEntity', 'Harborview Holdings LP', 'US_Citizen', TRUE, '1977-08-21', '5529', FALSE, FALSE),
    ('OWN-DEMO-002C', 'SBAID-DEMO-002', 'Carlos Mendez-Silva', 'Foreign Limited Partner', 10.0, 'Indirect_ParentEntity', 'Harborview Holdings LP', 'ForeignNational_NonResident', FALSE, '1971-12-04', '0000', FALSE, FALSE),
    ('OWN-DEMO-003A', 'SBAID-DEMO-003', 'Victor M. Delgado', 'President & Sole Shareholder', 100.0, 'Direct', NULL, 'US_Citizen', TRUE, '1982-07-19', '8834', FALSE, TRUE),
    ('OWN-DEMO-004A', 'SBAID-DEMO-004', 'Arthur H. Pendelton', 'Sole Managing Member', 100.0, 'Direct', NULL, 'US_Citizen', TRUE, '1908-04-12', '4409', FALSE, TRUE),
    ('OWN-DEMO-005A', 'SBAID-DEMO-005', 'Marcus A. Vance', 'Nominal CEO (Qualifying 8a)', 51.0, 'Direct', NULL, 'US_Citizen', TRUE, '1984-02-11', '6190', TRUE, FALSE),
    ('OWN-DEMO-005B', 'SBAID-DEMO-005', 'Richard K. Sterling', 'Minority Member (Controlling Signatory)', 49.0, 'Direct', NULL, 'US_Citizen', TRUE, '1969-09-30', '2045', FALSE, TRUE);

-------------------------------------------------------------------------------
-- 4. SBA_APPLICATIONS (99,995 synthetic + 5 isolated showcase apps = 100,000)
-------------------------------------------------------------------------------
INSERT INTO BNK.SBA_VETTING.SBA_APPLICATIONS (
    app_id, sba_id, program_type, requested_amount_usd, lender_or_office,
    packager_agent_id, app_status, priority, assigned_specialist,
    submitted_date, sla_due_date, decision_date, specialist_notes
)
WITH synth_biz AS (
    SELECT sba_id, ROW_NUMBER() OVER (ORDER BY sba_id) AS rn
    FROM BNK.SBA_VETTING.SBA_BUSINESSES
    WHERE sba_id NOT LIKE 'SBAID-DEMO-%'
),
pools AS (
    SELECT
        ARRAY_CONSTRUCT(
            'Huntington National Bank (PLP)','Live Oak Banking Company (PLP)','Celtic Bank Corp (PLP)','Newtek Small Business Finance',
            'Readycap Lending LLC','U.S. Bank NA (PLP)','Empire State CDC (504)','Florida First Capital Finance CDC',
            'SBA Office of Disaster Recovery - Fort Worth','SBA GCBD 8(a) Review Division - Washington DC'
        ) AS lenders,
        ARRAY_CONSTRUCT(
            'Karen Caldwell','Derrick Washington','Melissa Cho','Brian Kowalski','Teresa Morales',
            'Gregory Vance','Angela Okafor','steven Lindqvist','Rachel Zimmerman','jonathan McAllister',
            'Priya Deshmukh','Marcus Holloway','Sandra Thibodeaux','Kevin Beaulieu','Laura Hendrickson'
        ) AS specialists,
        ARRAY_CONSTRUCT(NULL, NULL, NULL, NULL, NULL, NULL, 'PKG-1020', 'PKG-2185', 'PKG-3310', 'PKG-4412') AS packagers
),
gen AS (
    SELECT
        SEQ4() AS seq,
        'APP-' || LPAD(SEQ4()::VARCHAR, 8, '0') AS app_id,
        UNIFORM(1, 100, RANDOM()) AS r_prog,
        UNIFORM(50, 4800, RANDOM()) * 1000 AS amt_usd,
        UNIFORM(0, 9, RANDOM()) AS idx_lender,
        UNIFORM(0, 14, RANDOM()) AS idx_spec,
        UNIFORM(0, 9, RANDOM()) AS idx_pkg,
        UNIFORM(1, 6, RANDOM()) AS r_status,
        UNIFORM(1, 4, RANDOM()) AS r_prio,
        UNIFORM(1, 540, RANDOM()) AS sub_days_ago,
        UNIFORM(5, 30, RANDOM()) AS sla_days
    FROM TABLE(GENERATOR(ROWCOUNT => 99995))
)
SELECT
    g.app_id,
    sb.sba_id,
    CASE
        WHEN g.r_prog <= 42 THEN '7a_Standard'
        WHEN g.r_prog <= 58 THEN 'MadeInAmerica_7a'
        WHEN g.r_prog <= 75 THEN '504_CDC'
        WHEN g.r_prog <= 90 THEN 'Disaster_EIDL'
        ELSE '8a_Certification'
    END AS program_type,
    IFF(g.r_prog > 90, 0, g.amt_usd)::NUMBER(15,2) AS requested_amount_usd,
    p.lenders[g.idx_lender]::VARCHAR AS lender_or_office,
    p.packagers[g.idx_pkg]::VARCHAR AS packager_agent_id,
    CASE g.r_status
        WHEN 1 THEN 'Submitted'
        WHEN 2 THEN 'InVetting'
        WHEN 3 THEN 'PendingDocuments'
        WHEN 4 THEN 'Approved_ETran'
        WHEN 5 THEN 'Declined_Ineligible'
        ELSE 'Hold_OIGReferral'
    END AS app_status,
    CASE g.r_prio
        WHEN 1 THEN 'Low'
        WHEN 2 THEN 'Medium'
        WHEN 3 THEN 'High'
        ELSE 'Critical'
    END AS priority,
    INITCAP(p.specialists[g.idx_spec]::VARCHAR) AS assigned_specialist,
    DATEADD('day', -g.sub_days_ago, CURRENT_DATE()) AS submitted_date,
    DATEADD('day', g.sla_days - g.sub_days_ago, CURRENT_DATE()) AS sla_due_date,
    IFF(g.r_status IN (4, 5), DATEADD('day', 4 - g.sub_days_ago, CURRENT_DATE()), NULL) AS decision_date,
    'Automated NSBPS pre-award intake queued for citizenship, IRS 4506-C, and federal exclusion verification.' AS specialist_notes
FROM gen g
JOIN synth_biz sb ON sb.rn = MOD(g.seq, 49995) + 1
CROSS JOIN pools p;

-- Showcase SBA Applications (APP-DEMO-001 through APP-DEMO-005)
INSERT INTO BNK.SBA_VETTING.SBA_APPLICATIONS (
    app_id, sba_id, program_type, requested_amount_usd, lender_or_office,
    packager_agent_id, app_status, priority, assigned_specialist,
    submitted_date, sla_due_date, decision_date, specialist_notes
)
SELECT
    column1, column2, column3, column4, column5,
    column6, column7, column8, column9,
    DATEADD('day', column10, CURRENT_DATE()), DATEADD('day', column11, CURRENT_DATE()), NULL, column12
FROM VALUES
    ('APP-DEMO-001', 'SBAID-DEMO-001', 'MadeInAmerica_7a', 1850000.00, 'Huntington National Bank (PLP)',
     NULL, 'InVetting', 'High', 'Karen Caldwell',
     -4, 3, 'Domestic CNC machining expansion loan. IRS 4506-C 1120-S transcript uploaded and awaiting automated NSBPS reconciliation.'),
    ('APP-DEMO-002', 'SBAID-DEMO-002', '504_CDC', 3200000.00, 'Lone Star Certified Development Corp',
     NULL, 'InVetting', 'High', 'Derrick Washington',
     -9, -1, '504 warehouse acquisition. Applicant attested 100% U.S. citizen ownership in E-Tran; multi-tier Operating Agreement uploaded for indirect owner review.'),
    ('APP-DEMO-003', 'SBAID-DEMO-003', '7a_Standard', 950000.00, 'Newtek Small Business Finance',
     'PKG-4412', 'Hold_OIGReferral', 'Critical', 'Melissa Cho',
     -7, -3, 'Submitted via watchlisted loan packager PKG-4412. Applicant claimed $3.40M revenue; IRS 4506-C transcript uploaded and prior COVID EIDL hold code detected.'),
    ('APP-DEMO-004', 'SBAID-DEMO-004', 'Disaster_EIDL', 500000.00, 'SBA Office of Disaster Recovery - Fort Worth',
     'PKG-9901', 'Submitted', 'Critical', 'Brian Kowalski',
     -2, 2, 'Hurricane disaster loan intake. Form 1919 uploaded; pre-disbursement DOB guardrail and Treasury Do Not Pay Death Master check pending.'),
    ('APP-DEMO-005', 'SBAID-DEMO-005', '8a_Certification', 0.00, 'SBA GCBD 8(a) Review Division - Washington DC',
     NULL, 'InVetting', 'Critical', 'Teresa Morales',
     -14, -2, 'Mandatory FY2026 8(a) full-scale audit submission. Contractor uploaded governance file into the IRS Tax Transcript slot.');

-------------------------------------------------------------------------------
-- 5. SBA_DOCUMENTS_METADATA (199,980 synthetic + 5 showcase + 15 batch = 200,000)
-------------------------------------------------------------------------------
INSERT INTO BNK.SBA_VETTING.SBA_DOCUMENTS_METADATA (
    doc_id, app_id, sba_id, declared_doc_type, file_path,
    upload_date, file_size_bytes, extraction_status, extraction_confidence
)
WITH synth_apps AS (
    SELECT app_id, sba_id, ROW_NUMBER() OVER (ORDER BY app_id) AS rn
    FROM BNK.SBA_VETTING.SBA_APPLICATIONS
    WHERE app_id NOT LIKE 'APP-DEMO-%'
),
gen AS (
    SELECT
        SEQ4() AS seq,
        UUID_STRING() AS doc_id,
        UNIFORM(1, 4, RANDOM()) AS r_dtype,
        UNIFORM(60, 45000000, RANDOM()) AS secs_ago,
        UNIFORM(40000, 6500000, RANDOM()) AS fsize,
        UNIFORM(1, 10, RANDOM()) AS r_stat,
        ROUND(UNIFORM(76, 99, RANDOM()) / 100.0, 3) AS conf
    FROM TABLE(GENERATOR(ROWCOUNT => 199980))
)
SELECT
    g.doc_id,
    sa.app_id,
    sa.sba_id,
    CASE g.r_dtype
        WHEN 1 THEN 'Form1919'
        WHEN 2 THEN 'IRSTaxTranscript_4506C'
        WHEN 3 THEN 'OperatingAgreement'
        ELSE 'OwnerGovernmentID'
    END AS declared_doc_type,
    'synthetic/' || sa.sba_id || '/' || g.doc_id || '.pdf' AS file_path,
    DATEADD('second', -g.secs_ago, CURRENT_TIMESTAMP()) AS upload_date,
    g.fsize AS file_size_bytes,
    CASE g.r_stat
        WHEN 1 THEN 'Pending'
        WHEN 2 THEN 'Processing'
        WHEN 10 THEN 'Failed'
        ELSE 'Completed'
    END AS extraction_status,
    IFF(g.r_stat NOT IN (1, 2), g.conf, NULL) AS extraction_confidence
FROM gen g
JOIN synth_apps sa ON sa.rn = MOD(g.seq, 99995) + 1;

-- Register the 5 primary SBA showcase PDFs on APP-DEMO-001..005 as Pending
INSERT INTO BNK.SBA_VETTING.SBA_DOCUMENTS_METADATA (
    doc_id, app_id, sba_id, declared_doc_type, file_path,
    upload_date, file_size_bytes, extraction_status, extraction_confidence
)
SELECT
    column1, column2, column3, column4, column5,
    DATEADD('minute', column6, CURRENT_TIMESTAMP()), column7, 'Pending', NULL
FROM VALUES
    ('sba-doc-0001-4506c-apex', 'APP-DEMO-001', 'SBAID-DEMO-001', 'IRSTaxTranscript_4506C', 'applications/IRSTaxTranscript_4506C_sba-doc-0001-4506c-apex.pdf', -12, 2407),
    ('sba-doc-0002-opag-harbor', 'APP-DEMO-002', 'SBAID-DEMO-002', 'OperatingAgreement', 'applications/OperatingAgreement_sba-doc-0002-opag-harbor.pdf', -20, 2462),
    ('sba-doc-0003-4506c-sunbelt', 'APP-DEMO-003', 'SBAID-DEMO-003', 'IRSTaxTranscript_4506C', 'applications/IRSTaxTranscript_4506C_sba-doc-0003-4506c-sunbelt.pdf', -28, 2369),
    ('sba-doc-0004-1919-metro', 'APP-DEMO-004', 'SBAID-DEMO-004', 'Form1919', 'applications/Form1919_sba-doc-0004-1919-metro.pdf', -35, 2323),
    ('sba-doc-0005-opag-potomac', 'APP-DEMO-005', 'SBAID-DEMO-005', 'IRSTaxTranscript_4506C', 'applications/OperatingAgreement_sba-doc-0005-opag-potomac.pdf', -42, 2584);

-- Register the 15 additional staged PDFs onto synthetic applications so BATCH_PROCESS_SBA_DOCUMENTS works out of the box
INSERT INTO BNK.SBA_VETTING.SBA_DOCUMENTS_METADATA (
    doc_id, app_id, sba_id, declared_doc_type, file_path,
    upload_date, file_size_bytes, extraction_status, extraction_confidence
)
WITH batch_apps AS (
    SELECT app_id, sba_id, ROW_NUMBER() OVER (ORDER BY app_id) AS rn
    FROM BNK.SBA_VETTING.SBA_APPLICATIONS
    WHERE app_id NOT LIKE 'APP-DEMO-%'
    QUALIFY rn <= 15
),
extra_files AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY column1) AS rn,
        column1 AS doc_id,
        column2 AS declared_doc_type,
        column3 AS file_path,
        column4 AS mins_ago,
        column5 AS fsize
    FROM VALUES
        ('sba-batch-0001', 'Form1919', 'applications/Form1919_sba-batch-0001.pdf', -90, 2315),
        ('sba-batch-0002', 'IRSTaxTranscript_4506C', 'applications/IRSTaxTranscript_4506C_sba-batch-0002.pdf', -95, 2399),
        ('sba-batch-0003', 'OwnerGovernmentID', 'applications/OwnerGovernmentID_sba-batch-0003.pdf', -100, 1767),
        ('sba-batch-0004', 'Form1919', 'applications/Form1919_sba-batch-0004.pdf', -105, 2329),
        ('sba-batch-0005', 'IRSTaxTranscript_4506C', 'applications/IRSTaxTranscript_4506C_sba-batch-0005.pdf', -110, 2391),
        ('sba-batch-0006', 'OwnerGovernmentID', 'applications/OwnerGovernmentID_sba-batch-0006.pdf', -115, 1774),
        ('sba-batch-0007', 'Form1919', 'applications/Form1919_sba-batch-0007.pdf', -120, 2336),
        ('sba-batch-0008', 'IRSTaxTranscript_4506C', 'applications/IRSTaxTranscript_4506C_sba-batch-0008.pdf', -125, 2378),
        ('sba-batch-0009', 'OwnerGovernmentID', 'applications/OwnerGovernmentID_sba-batch-0009.pdf', -130, 1773),
        ('sba-batch-0010', 'Form1919', 'applications/Form1919_sba-batch-0010.pdf', -135, 2324),
        ('sba-batch-0011', 'IRSTaxTranscript_4506C', 'applications/IRSTaxTranscript_4506C_sba-batch-0011.pdf', -140, 2395),
        ('sba-batch-0012', 'OwnerGovernmentID', 'applications/OwnerGovernmentID_sba-batch-0012.pdf', -145, 1776),
        ('sba-batch-0013', 'Form1919', 'applications/Form1919_sba-batch-0013.pdf', -150, 2332),
        ('sba-batch-0014', 'IRSTaxTranscript_4506C', 'applications/IRSTaxTranscript_4506C_sba-batch-0014.pdf', -155, 2377),
        ('sba-batch-0015', 'OwnerGovernmentID', 'applications/OwnerGovernmentID_sba-batch-0015.pdf', -160, 1769)
)
SELECT
    ef.doc_id,
    ba.app_id,
    ba.sba_id,
    ef.declared_doc_type,
    ef.file_path,
    DATEADD('minute', ef.mins_ago, CURRENT_TIMESTAMP()),
    ef.fsize,
    'Pending',
    NULL
FROM extra_files ef
JOIN batch_apps ba ON ba.rn = ef.rn;

-------------------------------------------------------------------------------
-- 6. SBA_VERIFICATION_RESULTS (1:1 baseline for Completed synthetic documents)
-------------------------------------------------------------------------------
INSERT INTO BNK.SBA_VETTING.SBA_VERIFICATION_RESULTS (
    result_id, doc_id, extracted_fields, confidence_score,
    ai_classification, verified_by, verification_date, eligibility_status
)
WITH completed_docs AS (
    SELECT
        dm.doc_id,
        dm.declared_doc_type,
        dm.extraction_confidence,
        b.legal_name,
        b.ein,
        b.stated_annual_revenue_usd,
        UNIFORM(1, 100, RANDOM()) AS r_elig,
        UNIFORM(60, 30000000, RANDOM()) AS ver_secs_ago
    FROM BNK.SBA_VETTING.SBA_DOCUMENTS_METADATA dm
    JOIN BNK.SBA_VETTING.SBA_BUSINESSES b ON dm.sba_id = b.sba_id
    WHERE dm.extraction_status = 'Completed'
)
SELECT
    UUID_STRING() AS result_id,
    cd.doc_id,
    OBJECT_CONSTRUCT(
        'business_legal_name', cd.legal_name,
        'ein', cd.ein,
        'gross_receipts_usd', cd.stated_annual_revenue_usd::VARCHAR,
        'ineligible_foreign_pct', '0'
    ) AS extracted_fields,
    COALESCE(cd.extraction_confidence, 0.91) AS confidence_score,
    cd.declared_doc_type AS ai_classification,
    'SYSTEM' AS verified_by,
    DATEADD('second', -cd.ver_secs_ago, CURRENT_TIMESTAMP()) AS verification_date,
    CASE
        WHEN cd.r_elig <= 74 THEN 'Eligible'
        WHEN cd.r_elig <= 83 THEN 'ManualReviewRequired'
        WHEN cd.r_elig <= 90 THEN 'Ineligible_Ownership'
        WHEN cd.r_elig <= 96 THEN 'HoldAndReferOIG'
        WHEN cd.r_elig <= 98 THEN 'ControlDeficiency_8a'
        ELSE 'AutoBlocked_AgeOrDeath'
    END AS eligibility_status
FROM completed_docs cd;

-------------------------------------------------------------------------------
-- 7. FEDERAL_EXCLUSION_ALERTS (24,995 synthetic + 5 showcase alerts = 25,000)
-------------------------------------------------------------------------------
INSERT INTO BNK.SBA_VETTING.FEDERAL_EXCLUSION_ALERTS (
    alert_id, sba_id, alert_source, severity,
    created_date, alert_status, assigned_investigator, alert_detail
)
WITH synth_biz AS (
    SELECT sba_id, ROW_NUMBER() OVER (ORDER BY sba_id) AS rn
    FROM BNK.SBA_VETTING.SBA_BUSINESSES
    WHERE sba_id NOT LIKE 'SBAID-DEMO-%'
    QUALIFY rn <= 24995
),
pools AS (
    SELECT ARRAY_CONSTRUCT(
        'Marcus Holloway','Priya Deshmukh','Karen Caldwell','Derrick Washington','Melissa Cho',
        'Brian Kowalski','Teresa Morales','Gregory Vance','Angela Okafor','Steven Lindqvist'
    ) AS investigators
),
gen AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY SEQ4()) AS rn,
        'SBA-ALT-' || LPAD(SEQ4()::VARCHAR, 7, '0') AS alert_id,
        UNIFORM(1, 6, RANDOM()) AS r_src,
        UNIFORM(1, 4, RANDOM()) AS r_sev,
        UNIFORM(60, 15000000, RANDOM()) AS secs_ago,
        UNIFORM(1, 5, RANDOM()) AS r_stat,
        UNIFORM(0, 9, RANDOM()) AS idx_inv
    FROM TABLE(GENERATOR(ROWCOUNT => 24995))
)
SELECT
    g.alert_id,
    sb.sba_id,
    CASE g.r_src
        WHEN 1 THEN 'CAIVRS_FederalDebt'
        WHEN 2 THEN 'SAM_Debarment'
        WHEN 3 THEN 'DoNotPay_DeathMaster'
        WHEN 4 THEN 'COVID_EIDL_HoldCode'
        WHEN 5 THEN 'OIG_PackagerWatchlist'
        ELSE 'CrossProgramStacking'
    END AS alert_source,
    CASE g.r_sev
        WHEN 1 THEN 'Low'
        WHEN 2 THEN 'Medium'
        WHEN 3 THEN 'High'
        ELSE 'Critical'
    END AS severity,
    DATEADD('second', -g.secs_ago, CURRENT_TIMESTAMP()) AS created_date,
    CASE g.r_stat
        WHEN 1 THEN 'New'
        WHEN 2 THEN 'Assigned'
        WHEN 3 THEN 'Investigating'
        WHEN 4 THEN 'Cleared'
        ELSE 'ConfirmedBlock'
    END AS alert_status,
    IFF(g.r_stat IN (2, 3), p.investigators[g.idx_inv]::VARCHAR, NULL) AS assigned_investigator,
    'Automated NSBPS federal pre-award screening hit requiring statutory review prior to E-Tran guaranty.' AS alert_detail
FROM gen g
JOIN synth_biz sb ON sb.rn = g.rn
CROSS JOIN pools p;

-- Showcase Federal Exclusion & OIG Alerts (cleanly mapped to SBAID-DEMO-003, 004, 005; SBAID-DEMO-001 has 0 alerts)
INSERT INTO BNK.SBA_VETTING.FEDERAL_EXCLUSION_ALERTS (
    alert_id, sba_id, alert_source, severity,
    created_date, alert_status, assigned_investigator, alert_detail
)
SELECT
    column1, column2, column3, column4,
    DATEADD('hour', column5, CURRENT_TIMESTAMP()), column6, column7, column8
FROM VALUES
    ('SBA-ALT-DEMO-001', 'SBAID-DEMO-003', 'COVID_EIDL_HoldCode', 'Critical', -8, 'Investigating', 'Melissa Cho',
     'Active unresolved COVID-19 EIDL fraud hold code HOLD-EIDL-09 ($500,000 2021 disbursement under OIG identity & revenue review). Blocks new 7(a) approval under SOP-HLD-001.'),
    ('SBA-ALT-DEMO-002', 'SBAID-DEMO-003', 'OIG_PackagerWatchlist', 'Critical', -6, 'New', NULL,
     'Submitting Form 159 agent PKG-4412 (South Florida Capital Packagers) is on active SBA OIG fraud watchlist across 14 applications exhibiting fabricated IRS revenue claims.'),
    ('SBA-ALT-DEMO-003', 'SBAID-DEMO-004', 'DoNotPay_DeathMaster', 'Critical', -2, 'New', NULL,
     'Treasury Do Not Pay / SSA Death Master File positive match on sole guarantor Arthur H. Pendelton (SSN ending 4409, DOB 1908-04-12, deceased 1994-11-02; stated age 118 exceeds statutory 115-year cap).'),
    ('SBA-ALT-DEMO-004', 'SBAID-DEMO-002', 'CrossProgramStacking', 'Medium', -14, 'Assigned', 'Derrick Washington',
     'Parent holding partnership Harborview Holdings LP appears on two concurrent CDC 504 applications; verify indirect ownership citizenship and aggregate $5M guaranty cap.'),
    ('SBA-ALT-DEMO-005', 'SBAID-DEMO-005', 'SAM_Debarment', 'High', -10, 'Investigating', 'Teresa Morales',
     'Minority affiliate Apex Federal Systems Corp (49% member and 85% subcontractor) flagged in GCBD/OIG 8(a) pass-through audit inquiry.');
