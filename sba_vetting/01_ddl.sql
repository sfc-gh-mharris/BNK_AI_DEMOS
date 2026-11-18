/*=============================================================================
  SBA Borrower and Program Integrity (NSBPS / SBAID) - DDL
  Database: BNK | Schema: SBA_VETTING | Warehouse: BNK_WH
=============================================================================*/

USE DATABASE BNK;
USE SCHEMA SBA_VETTING;
USE WAREHOUSE BNK_WH;

-------------------------------------------------------------------------------
-- SBA_BUSINESSES (NSBPS Unified Small Business Golden Record / SBAID)
-------------------------------------------------------------------------------
CREATE OR ALTER TABLE BNK.SBA_VETTING.SBA_BUSINESSES (
    sba_id                     VARCHAR(36)    NOT NULL COMMENT 'Persistent cross-program National Small Business Profile Service identifier (SBAID).',
    ein                        VARCHAR(12)    NOT NULL COMMENT 'IRS Employer Identification Number (XX-XXXXXXX).',
    uei_sam                    VARCHAR(12)             COMMENT 'SAM.gov 12-character Unique Entity Identifier for federal contracting and exclusions.',
    legal_name                 VARCHAR(255)   NOT NULL COMMENT 'Registered legal business name with Secretary of State.',
    dba_name                   VARCHAR(255)            COMMENT 'Trade or Doing Business As name if applicable.',
    entity_structure           VARCHAR(40)    NOT NULL COMMENT 'Legal structure: LLC, S_Corp, C_Corp, SoleProprietorship, LimitedPartnership.',
    naics_code                 VARCHAR(6)     NOT NULL COMMENT 'Primary 6-digit NAICS industry code.',
    naics_description          VARCHAR(200)   NOT NULL COMMENT 'NAICS industry description.',
    naics_size_cap_employees   INTEGER                 COMMENT '13 CFR 121 employee-based small business size standard for this NAICS (if employee-based).',
    naics_size_cap_revenue_usd NUMBER(15,2)            COMMENT '13 CFR 121 receipts-based small business size standard in USD (if receipts-based).',
    state_code                 VARCHAR(2)     NOT NULL COMMENT 'Two-letter U.S. state or territory code of principal office.',
    formation_date             DATE           NOT NULL COMMENT 'Secretary of State business formation date.',
    employee_count             INTEGER        NOT NULL COMMENT 'Applicant-reported employee headcount including affiliates.',
    stated_annual_revenue_usd  NUMBER(15,2)   NOT NULL COMMENT 'Applicant-stated gross annual receipts in USD on Form 1919 or portal intake.',
    stated_annual_payroll_usd  NUMBER(15,2)   NOT NULL COMMENT 'Applicant-stated annual W-2 payroll in USD.',
    us_citizen_ownership_attested BOOLEAN     NOT NULL COMMENT 'TRUE if applicant attested in E-Tran/MySBA that 100% of direct and indirect owners are eligible U.S. citizens or nationals residing in the U.S.',
    prior_ppp_eidl_status      VARCHAR(30)    NOT NULL COMMENT 'Prior pandemic assistance status: None, Forgiven_PaidInFull, Active_Performing, HoldCode_FraudReview, ChargedOff_Delinquent.',
    prior_hold_code            VARCHAR(30)             COMMENT 'Active SBA compliance hold code from prior PPP, EIDL, RRF, or SVOG assistance (for example HOLD-EIDL-09).',
    risk_tier                  VARCHAR(20)    NOT NULL COMMENT 'NSBPS composite pre-funding risk tier: Low, Medium, High, EDD.',

    CONSTRAINT pk_sba_businesses PRIMARY KEY (sba_id)
)
COMMENT = 'Unified SBAID small business profile linking identity, NAICS size standards, stated financials, and prior SBA pandemic loan compliance status across programs.';

-------------------------------------------------------------------------------
-- BENEFICIAL_OWNERS (Direct and Multi-Tier Indirect Principals)
-------------------------------------------------------------------------------
CREATE OR ALTER TABLE BNK.SBA_VETTING.BENEFICIAL_OWNERS (
    owner_id                   VARCHAR(36)    NOT NULL COMMENT 'Unique beneficial owner or guarantor record ID.',
    sba_id                     VARCHAR(36)    NOT NULL COMMENT 'Foreign key to SBA_BUSINESSES (SBAID).',
    full_name                  VARCHAR(150)   NOT NULL COMMENT 'Full legal name of individual principal or guarantor.',
    title                      VARCHAR(80)             COMMENT 'Corporate officer or managing member title.',
    ownership_pct              FLOAT          NOT NULL COMMENT 'Effective equity ownership percentage in the applicant business (0 to 100).',
    ownership_type             VARCHAR(25)    NOT NULL COMMENT 'Direct or Indirect_ParentEntity.',
    parent_entity_name         VARCHAR(200)            COMMENT 'Intermediate holding company name when ownership_type = Indirect_ParentEntity.',
    citizenship_status         VARCHAR(35)    NOT NULL COMMENT 'US_Citizen, US_National, LawfulPermanentResident, ForeignNational_NonResident, Undocumented_Ineligible.',
    resides_in_us              BOOLEAN        NOT NULL COMMENT 'TRUE if principal primary residence is within the United States or territories.',
    date_of_birth              DATE           NOT NULL COMMENT 'Principal date of birth used for <18 and >115 statutory age guardrails and Death Master File checks.',
    ssn_last4                  VARCHAR(4)     NOT NULL COMMENT 'Last 4 digits of SSN/ITIN on Form 1919.',
    is_disadvantaged_qualifying BOOLEAN       NOT NULL COMMENT 'TRUE if principal is the qualifying socially/economically disadvantaged, veteran, or woman owner for contracting certification.',
    has_unconditional_control  BOOLEAN        NOT NULL COMMENT 'TRUE if principal holds unconditional day-to-day management and bank signatory control under 13 CFR 124.106.',

    CONSTRAINT pk_beneficial_owners PRIMARY KEY (owner_id),
    CONSTRAINT fk_owners_sba_id FOREIGN KEY (sba_id) REFERENCES BNK.SBA_VETTING.SBA_BUSINESSES(sba_id)
)
COMMENT = 'Direct and indirect beneficial owners and guarantors disclosed on SBA Form 1919, Operating Agreements, and MySBA Certify filings.';

-------------------------------------------------------------------------------
-- SBA_APPLICATIONS (E-Tran 7(a)/504, Disaster EIDL, and 8(a) Cert Queue)
-------------------------------------------------------------------------------
CREATE OR ALTER TABLE BNK.SBA_VETTING.SBA_APPLICATIONS (
    app_id                     VARCHAR(36)    NOT NULL COMMENT 'Unique loan guaranty, disaster loan, or certification review application ID.',
    sba_id                     VARCHAR(36)    NOT NULL COMMENT 'Foreign key to SBA_BUSINESSES (SBAID).',
    program_type               VARCHAR(30)    NOT NULL COMMENT 'SBA program: 7a_Standard, MadeInAmerica_7a, 504_CDC, Disaster_EIDL, 8a_Certification.',
    requested_amount_usd       NUMBER(15,2)   NOT NULL COMMENT 'Requested loan or guaranty amount in USD (0 for 8a_Certification reviews).',
    lender_or_office           VARCHAR(150)   NOT NULL COMMENT 'Submitting 7(a) lender, Certified Development Company (CDC), Office of Disaster Recovery, or GCBD field office.',
    packager_agent_id          VARCHAR(30)             COMMENT 'Fee-based loan packager, broker, or Form 159 agent identifier if third-party prepared.',
    app_status                 VARCHAR(30)    NOT NULL COMMENT 'Workflow status: Submitted, InVetting, PendingDocuments, Approved_ETran, Declined_Ineligible, Hold_OIGReferral.',
    priority                   VARCHAR(15)    NOT NULL COMMENT 'Review SLA priority: Low, Medium, High, Critical.',
    assigned_specialist        VARCHAR(100)   NOT NULL COMMENT 'SBA Loan Specialist or Business Opportunity Specialist assigned.',
    submitted_date             DATE           NOT NULL COMMENT 'Date application entered E-Tran or MySBA.',
    sla_due_date               DATE           NOT NULL COMMENT 'Target SLA completion date prior to guaranty authorization or certification decision.',
    decision_date              DATE                    COMMENT 'Date terminal decision was recorded; NULL for active applications.',
    specialist_notes           VARCHAR(2000)           COMMENT 'Loan or certification specialist review notes.',

    CONSTRAINT pk_sba_applications PRIMARY KEY (app_id),
    CONSTRAINT fk_apps_sba_id FOREIGN KEY (sba_id) REFERENCES BNK.SBA_VETTING.SBA_BUSINESSES(sba_id)
)
COMMENT = 'Cross-program SBA intake and underwriting queue across 7(a), Made in America 7(a), 504, Disaster EIDL, and 8(a) Business Development certifications.';

-------------------------------------------------------------------------------
-- SBA_DOCUMENTS_METADATA (Application Documents on @BNK.SBA_VETTING.SBA_DOCUMENTS)
-------------------------------------------------------------------------------
CREATE OR ALTER TABLE BNK.SBA_VETTING.SBA_DOCUMENTS_METADATA (
    doc_id                     VARCHAR(36)    NOT NULL COMMENT 'Unique document identifier.',
    app_id                     VARCHAR(36)    NOT NULL COMMENT 'Foreign key to SBA_APPLICATIONS.',
    sba_id                     VARCHAR(36)    NOT NULL COMMENT 'Foreign key to SBA_BUSINESSES.',
    declared_doc_type          VARCHAR(40)    NOT NULL COMMENT 'Portal-declared category: Form1919, IRSTaxTranscript_4506C, OperatingAgreement, OwnerGovernmentID.',
    file_path                  VARCHAR(500)   NOT NULL COMMENT 'Relative stage path inside @BNK.SBA_VETTING.SBA_DOCUMENTS (staged demo PDFs start with applications/).',
    upload_date                TIMESTAMP_NTZ  NOT NULL COMMENT 'Timestamp document was uploaded.',
    file_size_bytes            INTEGER        NOT NULL COMMENT 'File size in bytes.',
    extraction_status          VARCHAR(20)    NOT NULL COMMENT 'Pipeline status: Pending, Processing, Completed, Failed.',
    extraction_confidence      FLOAT                   COMMENT 'Mean AI_EXTRACT field confidence score (0.0 to 1.0) once processed.',

    CONSTRAINT pk_sba_docs PRIMARY KEY (doc_id),
    CONSTRAINT fk_sba_docs_app FOREIGN KEY (app_id) REFERENCES BNK.SBA_VETTING.SBA_APPLICATIONS(app_id),
    CONSTRAINT fk_sba_docs_biz FOREIGN KEY (sba_id) REFERENCES BNK.SBA_VETTING.SBA_BUSINESSES(sba_id)
)
COMMENT = 'Metadata and AI pipeline status for uploaded borrower, tax transcript, ownership, and identity documents.';

-------------------------------------------------------------------------------
-- SBA_VERIFICATION_RESULTS (AI Extraction + Statutory Eligibility Decisions)
-------------------------------------------------------------------------------
CREATE OR ALTER TABLE BNK.SBA_VETTING.SBA_VERIFICATION_RESULTS (
    result_id                  VARCHAR(36)    NOT NULL COMMENT 'Unique verification result identifier.',
    doc_id                     VARCHAR(36)    NOT NULL COMMENT 'Foreign key to SBA_DOCUMENTS_METADATA.',
    extracted_fields           VARIANT        NOT NULL COMMENT 'Structured JSON extracted via AI_EXTRACT from Form 1919, IRS 4506-C/1120-S, Operating Agreement, or Owner ID.',
    confidence_score           FLOAT          NOT NULL COMMENT 'Aggregate extraction confidence score (0.0 to 1.0).',
    ai_classification          VARCHAR(40)    NOT NULL COMMENT 'Document type detected by AI_CLASSIFY.',
    verified_by                VARCHAR(100)   NOT NULL COMMENT 'SYSTEM or specialist name.',
    verification_date          TIMESTAMP_NTZ  NOT NULL COMMENT 'Timestamp statutory verification ran.',
    eligibility_status         VARCHAR(40)    NOT NULL COMMENT 'Statutory determination: Eligible, Ineligible_Ownership, HoldAndReferOIG, AutoBlocked_AgeOrDeath, ControlDeficiency_8a, ManualReviewRequired.',

    CONSTRAINT pk_sba_verif PRIMARY KEY (result_id),
    CONSTRAINT fk_sba_verif_doc FOREIGN KEY (doc_id) REFERENCES BNK.SBA_VETTING.SBA_DOCUMENTS_METADATA(doc_id)
)
COMMENT = 'AI-extracted fields and statutory SBA eligibility determinations across citizenship, age guardrails, IRS 4506-C revenue variance, federal hold codes, and 8(a) control.';

-------------------------------------------------------------------------------
-- FEDERAL_EXCLUSION_ALERTS (CAIVRS, SAM.gov, Do Not Pay, Hold Codes, OIG Rings)
-------------------------------------------------------------------------------
CREATE OR ALTER TABLE BNK.SBA_VETTING.FEDERAL_EXCLUSION_ALERTS (
    alert_id                   VARCHAR(36)    NOT NULL COMMENT 'Unique federal screening or fraud alert identifier.',
    sba_id                     VARCHAR(36)    NOT NULL COMMENT 'Foreign key to SBA_BUSINESSES (SBAID).',
    alert_source               VARCHAR(40)    NOT NULL COMMENT 'Trigger system: CAIVRS_FederalDebt, SAM_Debarment, DoNotPay_DeathMaster, COVID_EIDL_HoldCode, OIG_PackagerWatchlist, CrossProgramStacking.',
    severity                   VARCHAR(15)    NOT NULL COMMENT 'Alert urgency: Low, Medium, High, Critical.',
    created_date               TIMESTAMP_NTZ  NOT NULL COMMENT 'Timestamp alert fired.',
    alert_status               VARCHAR(25)    NOT NULL COMMENT 'Disposition state: New, Assigned, Investigating, Cleared, ConfirmedBlock.',
    assigned_investigator      VARCHAR(100)            COMMENT 'Assigned OCA or OIG investigator.',
    alert_detail               VARCHAR(1000)           COMMENT 'Summary of federal database hit, hold code, or packager ring linkage.',

    CONSTRAINT pk_fed_alerts PRIMARY KEY (alert_id),
    CONSTRAINT fk_fed_alerts_biz FOREIGN KEY (sba_id) REFERENCES BNK.SBA_VETTING.SBA_BUSINESSES(sba_id)
)
COMMENT = 'Pre-award federal database hits and cross-program fraud alerts across CAIVRS, SAM.gov, Treasury Do Not Pay, pandemic hold codes, and OIG loan-packager watchlists.';

-------------------------------------------------------------------------------
-- SBA_SOP_POLICIES (SBA SOP 50 10 8.1, 13 CFR, Policy Notices, OIG Directives)
-------------------------------------------------------------------------------
CREATE OR ALTER TABLE BNK.SBA_VETTING.SBA_SOP_POLICIES (
    policy_id                  VARCHAR(25)    NOT NULL COMMENT 'Unique SBA SOP or CFR rule identifier (for example SOP-CIT-001).',
    title                      VARCHAR(300)   NOT NULL COMMENT 'Rule or policy notice title.',
    program_scope              VARCHAR(30)    NOT NULL COMMENT 'Applicable scope: 7a_504, AllPrograms, Disaster, 8a_Contracting, OIG_Enforcement.',
    category                   VARCHAR(40)    NOT NULL COMMENT 'Domain: CitizenshipOwnership, TaxVerification, AgeIdentityGuardrail, FederalExclusions, SizeAndNAICS, ContractingControl, PackagerOversight.',
    effective_date             DATE           NOT NULL COMMENT 'Effective date of SOP revision, CFR rule, or Policy Notice.',
    authority_citation         VARCHAR(150)   NOT NULL COMMENT 'Authoritative citation (for example SOP 50 10 8.1 / Policy Notice 5000-876441).',
    content                    VARCHAR(16000) NOT NULL COMMENT 'Full regulatory and operational guidance indexed by Cortex Search.',

    CONSTRAINT pk_sba_policies PRIMARY KEY (policy_id)
)
COMMENT = 'Authoritative SBA Standard Operating Procedures, Policy Notices, 13 CFR eligibility rules, and OIG fraud referral standards.';
