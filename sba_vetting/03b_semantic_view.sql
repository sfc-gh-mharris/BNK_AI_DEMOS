/*=============================================================================
  SBA Borrower and Program Integrity (NSBPS / SBAID) - Semantic View
  Database: BNK | Schema: SBA_VETTING | Warehouse: BNK_WH
=============================================================================*/

USE DATABASE BNK;
USE SCHEMA SBA_VETTING;
USE WAREHOUSE BNK_WH;

CREATE OR ALTER SEMANTIC VIEW BNK.SBA_VETTING.SV_SBA_VETTING
  TABLES (
    businesses AS BNK.SBA_VETTING.SBA_BUSINESSES PRIMARY KEY (sba_id) COMMENT = 'Unified NSBPS small business profiles keyed by persistent SBAID across all SBA loan and contracting programs.',
    owners AS BNK.SBA_VETTING.BENEFICIAL_OWNERS PRIMARY KEY (owner_id) COMMENT = 'Direct and indirect beneficial owners and guarantors with citizenship, residency, DOB, and 8(a) control attributes.',
    applications AS BNK.SBA_VETTING.SBA_APPLICATIONS PRIMARY KEY (app_id) COMMENT = 'Cross-program SBA intake queue covering 7(a), Made in America 7(a), 504 CDC, Disaster EIDL, and 8(a) certifications.',
    documents AS BNK.SBA_VETTING.SBA_DOCUMENTS_METADATA PRIMARY KEY (doc_id) COMMENT = 'Uploaded SBA Form 1919, IRS Form 4506-C tax transcripts, LLC Operating Agreements, and Owner IDs.',
    verifications AS BNK.SBA_VETTING.SBA_VERIFICATION_RESULTS PRIMARY KEY (result_id) COMMENT = 'AI extraction results and statutory SBA eligibility decisions.',
    alerts AS BNK.SBA_VETTING.FEDERAL_EXCLUSION_ALERTS PRIMARY KEY (alert_id) COMMENT = 'Pre-award federal exclusion and fraud alerts from CAIVRS, SAM.gov, Treasury Do Not Pay, COVID hold codes, and OIG packager watchlists.'
  )
  RELATIONSHIPS (
    owners_to_businesses AS owners (sba_id) REFERENCES businesses (sba_id),
    apps_to_businesses AS applications (sba_id) REFERENCES businesses (sba_id),
    docs_to_apps AS documents (app_id) REFERENCES applications (app_id),
    verifs_to_docs AS verifications (doc_id) REFERENCES documents (doc_id),
    alerts_to_businesses AS alerts (sba_id) REFERENCES businesses (sba_id)
  )
  FACTS (
    businesses.employee_count AS employee_count COMMENT = 'Applicant-reported employee headcount including affiliates.',
    businesses.stated_annual_revenue_usd AS stated_annual_revenue_usd COMMENT = 'Applicant-stated gross annual receipts in USD.',
    businesses.stated_annual_payroll_usd AS stated_annual_payroll_usd COMMENT = 'Applicant-stated annual W-2 payroll in USD.',
    businesses.naics_size_cap_employees AS naics_size_cap_employees COMMENT = '13 CFR 121 employee-based size standard cap for the primary NAICS code.',
    businesses.naics_size_cap_revenue_usd AS naics_size_cap_revenue_usd COMMENT = '13 CFR 121 receipts-based size standard cap in USD for the primary NAICS code.',
    owners.ownership_pct AS ownership_pct COMMENT = 'Effective equity ownership percentage held by principal.',
    applications.requested_amount_usd AS requested_amount_usd COMMENT = 'Requested SBA loan or guaranty amount in USD.',
    documents.file_size_bytes AS file_size_bytes COMMENT = 'Document file size in bytes.',
    documents.extraction_confidence AS extraction_confidence COMMENT = 'Mean AI_EXTRACT field confidence score (0.0 to 1.0).',
    verifications.confidence_score AS confidence_score COMMENT = 'Overall extraction confidence score (0.0 to 1.0).'
  )
  DIMENSIONS (
    businesses.sba_id AS sba_id COMMENT = 'Persistent cross-program SBAID (for example SBAID-DEMO-001 through SBAID-DEMO-005).',
    businesses.ein AS ein COMMENT = 'Employer Identification Number (EIN).',
    businesses.uei_sam AS uei_sam COMMENT = 'SAM.gov 12-character Unique Entity Identifier.',
    businesses.legal_name AS legal_name COMMENT = 'Registered legal business name.',
    businesses.entity_structure AS entity_structure COMMENT = 'Legal form: LLC, S_Corp, C_Corp, SoleProprietorship, LimitedPartnership.' SAMPLE_VALUES ('LLC', 'S_Corp', 'C_Corp', 'SoleProprietorship', 'LimitedPartnership') IS_ENUM,
    businesses.naics_code AS naics_code COMMENT = 'Primary 6-digit NAICS industry code.',
    businesses.naics_description AS naics_description COMMENT = 'NAICS industry title.',
    businesses.state_code AS state_code COMMENT = 'Two-letter U.S. state code.',
    businesses.formation_date AS formation_date COMMENT = 'Business formation date.',
    businesses.us_citizen_ownership_attested AS us_citizen_ownership_attested COMMENT = 'TRUE if applicant attested 100% U.S. citizen direct and indirect ownership in E-Tran.',
    businesses.prior_ppp_eidl_status AS prior_ppp_eidl_status COMMENT = 'Prior pandemic loan compliance status: None, Forgiven_PaidInFull, Active_Performing, HoldCode_FraudReview, ChargedOff_Delinquent.' SAMPLE_VALUES ('None', 'Forgiven_PaidInFull', 'Active_Performing', 'HoldCode_FraudReview', 'ChargedOff_Delinquent') IS_ENUM,
    businesses.prior_hold_code AS prior_hold_code COMMENT = 'Active SBA pandemic hold code (for example HOLD-EIDL-09 or HOLD-PPP-14).',
    businesses.risk_tier AS risk_tier COMMENT = 'NSBPS pre-funding risk tier: Low, Medium, High, EDD.' SAMPLE_VALUES ('Low', 'Medium', 'High', 'EDD') IS_ENUM,

    owners.owner_id AS owner_id COMMENT = 'Unique beneficial owner identifier.',
    owners.owner_full_name AS full_name COMMENT = 'Full legal name of beneficial owner or guarantor.',
    owners.owner_title AS title COMMENT = 'Principal title.',
    owners.ownership_type AS ownership_type COMMENT = 'Direct or Indirect_ParentEntity.' SAMPLE_VALUES ('Direct', 'Indirect_ParentEntity') IS_ENUM,
    owners.parent_entity_name AS parent_entity_name COMMENT = 'Intermediate holding company name for indirect owners.',
    owners.citizenship_status AS citizenship_status COMMENT = 'US_Citizen, US_National, LawfulPermanentResident, ForeignNational_NonResident, Undocumented_Ineligible.' SAMPLE_VALUES ('US_Citizen', 'US_National', 'LawfulPermanentResident', 'ForeignNational_NonResident', 'Undocumented_Ineligible') IS_ENUM,
    owners.resides_in_us AS resides_in_us COMMENT = 'TRUE if principal primary residence is in the United States.',
    owners.owner_dob AS date_of_birth COMMENT = 'Principal date of birth.',
    owners.owner_age_years AS DATEDIFF('year', date_of_birth, CURRENT_DATE()) COMMENT = 'Approximate principal age in years used for <18 and >115 statutory age guardrails.',
    owners.is_disadvantaged_qualifying AS is_disadvantaged_qualifying COMMENT = 'TRUE if principal is the qualifying 8(a) disadvantaged owner.',
    owners.has_unconditional_control AS has_unconditional_control COMMENT = 'TRUE if principal holds unconditional day-to-day and bank signatory control under 13 CFR 124.106.',

    applications.app_id AS app_id COMMENT = 'Unique SBA application ID (for example APP-DEMO-001 through APP-DEMO-005).',
    applications.program_type AS program_type COMMENT = 'SBA program: 7a_Standard, MadeInAmerica_7a, 504_CDC, Disaster_EIDL, 8a_Certification.' SAMPLE_VALUES ('7a_Standard', 'MadeInAmerica_7a', '504_CDC', 'Disaster_EIDL', '8a_Certification') IS_ENUM,
    applications.lender_or_office AS lender_or_office COMMENT = 'Submitting 7(a) PLP lender, 504 CDC, Disaster office, or GCBD division.',
    applications.packager_agent_id AS packager_agent_id COMMENT = 'Third-party fee-based loan packager or Form 159 agent ID (for example PKG-4412).',
    applications.app_status AS app_status COMMENT = 'Workflow status: Submitted, InVetting, PendingDocuments, Approved_ETran, Declined_Ineligible, Hold_OIGReferral.' SAMPLE_VALUES ('Submitted', 'InVetting', 'PendingDocuments', 'Approved_ETran', 'Declined_Ineligible', 'Hold_OIGReferral') IS_ENUM,
    applications.priority AS priority COMMENT = 'SLA priority tier: Low, Medium, High, Critical.' SAMPLE_VALUES ('Low', 'Medium', 'High', 'Critical') IS_ENUM,
    applications.assigned_specialist AS assigned_specialist COMMENT = 'Assigned SBA Loan Specialist or Business Opportunity Specialist.',
    applications.submitted_date AS submitted_date COMMENT = 'Application intake date.',
    applications.sla_due_date AS sla_due_date COMMENT = 'Target SLA completion date.',
    applications.decision_date AS decision_date COMMENT = 'Decision date for closed applications.',
    applications.is_overdue AS (app_status NOT IN ('Approved_ETran', 'Declined_Ineligible') AND sla_due_date < CURRENT_DATE()) COMMENT = 'TRUE when an active SBA application is past its SLA due date.',
    applications.specialist_notes AS specialist_notes COMMENT = 'Specialist intake and review notes.',

    documents.doc_id AS doc_id COMMENT = 'Unique uploaded document identifier.',
    documents.declared_doc_type AS declared_doc_type COMMENT = 'Portal-declared document type: Form1919, IRSTaxTranscript_4506C, OperatingAgreement, OwnerGovernmentID.' SAMPLE_VALUES ('Form1919', 'IRSTaxTranscript_4506C', 'OperatingAgreement', 'OwnerGovernmentID') IS_ENUM,
    documents.file_path AS file_path COMMENT = 'Relative stage file path inside @BNK.SBA_VETTING.SBA_DOCUMENTS.',
    documents.upload_date AS upload_date COMMENT = 'Upload timestamp.',
    documents.extraction_status AS extraction_status COMMENT = 'AI extraction state: Pending, Processing, Completed, Failed.' SAMPLE_VALUES ('Pending', 'Processing', 'Completed', 'Failed') IS_ENUM,

    verifications.result_id AS result_id COMMENT = 'Unique verification result ID.',
    verifications.ai_classification AS ai_classification COMMENT = 'Document category detected by AI_CLASSIFY.',
    verifications.verified_by AS verified_by COMMENT = 'SYSTEM or specialist name.',
    verifications.verification_date AS verification_date COMMENT = 'Verification timestamp.',
    verifications.eligibility_status AS eligibility_status COMMENT = 'Statutory outcome: Eligible, Ineligible_Ownership, HoldAndReferOIG, AutoBlocked_AgeOrDeath, ControlDeficiency_8a, ManualReviewRequired.' SAMPLE_VALUES ('Eligible', 'Ineligible_Ownership', 'HoldAndReferOIG', 'AutoBlocked_AgeOrDeath', 'ControlDeficiency_8a', 'ManualReviewRequired') IS_ENUM,

    alerts.alert_id AS alert_id COMMENT = 'Unique federal exclusion or fraud alert ID.',
    alerts.alert_source AS alert_source COMMENT = 'Screening source: CAIVRS_FederalDebt, SAM_Debarment, DoNotPay_DeathMaster, COVID_EIDL_HoldCode, OIG_PackagerWatchlist, CrossProgramStacking.' SAMPLE_VALUES ('CAIVRS_FederalDebt', 'SAM_Debarment', 'DoNotPay_DeathMaster', 'COVID_EIDL_HoldCode', 'OIG_PackagerWatchlist', 'CrossProgramStacking') IS_ENUM,
    alerts.severity AS severity COMMENT = 'Alert urgency: Low, Medium, High, Critical.' SAMPLE_VALUES ('Low', 'Medium', 'High', 'Critical') IS_ENUM,
    alerts.created_date AS created_date COMMENT = 'Alert creation timestamp.',
    alerts.alert_status AS alert_status COMMENT = 'Disposition: New, Assigned, Investigating, Cleared, ConfirmedBlock.' SAMPLE_VALUES ('New', 'Assigned', 'Investigating', 'Cleared', 'ConfirmedBlock') IS_ENUM,
    alerts.assigned_investigator AS assigned_investigator COMMENT = 'Assigned OCA or OIG investigator.',
    alerts.alert_detail AS alert_detail COMMENT = 'Detailed summary of the federal hit, hold code, or packager ring.'
  )
  METRICS (
    businesses.business_count AS COUNT(DISTINCT sba_id) COMMENT = 'Count of distinct small businesses (SBAIDs).',
    businesses.hold_code_business_count AS COUNT_IF(prior_hold_code IS NOT NULL) COMMENT = 'Count of small businesses carrying an unresolved pandemic assistance hold code.',
    owners.owner_count AS COUNT(DISTINCT owner_id) COMMENT = 'Count of beneficial owners and guarantors.',
    owners.ineligible_owner_count AS COUNT_IF(citizenship_status NOT IN ('US_Citizen', 'US_National') OR NOT resides_in_us) COMMENT = 'Count of beneficial owners ineligible under SOP 50 10 8.1 / Policy Notice 5000-876441.',
    applications.application_count AS COUNT(DISTINCT app_id) COMMENT = 'Count of SBA loan and certification applications.',
    applications.active_application_count AS COUNT_IF(app_status NOT IN ('Approved_ETran', 'Declined_Ineligible')) COMMENT = 'Count of active unresolved SBA applications.',
    applications.overdue_application_count AS COUNT_IF(app_status NOT IN ('Approved_ETran', 'Declined_Ineligible') AND sla_due_date < CURRENT_DATE()) COMMENT = 'Count of active SBA applications past their SLA due date.',
    applications.total_requested_amount_usd AS SUM(requested_amount_usd) COMMENT = 'Total requested SBA loan or guaranty volume in USD.',
    applications.packager_submitted_count AS COUNT_IF(packager_agent_id IS NOT NULL) COMMENT = 'Count of applications submitted via a third-party loan packager or Form 159 agent.',
    documents.document_count AS COUNT(DISTINCT doc_id) COMMENT = 'Count of uploaded SBA documents.',
    documents.pending_document_count AS COUNT_IF(extraction_status = 'Pending') COMMENT = 'Count of uploaded documents awaiting AI extraction.',
    verifications.verification_count AS COUNT(DISTINCT result_id) COMMENT = 'Count of statutory verification results.',
    verifications.ineligible_or_hold_count AS COUNT_IF(eligibility_status IN ('Ineligible_Ownership', 'HoldAndReferOIG', 'AutoBlocked_AgeOrDeath', 'ControlDeficiency_8a')) COMMENT = 'Count of verifications resulting in statutory ineligibility, automatic block, or OIG hold.',
    alerts.alert_count AS COUNT(DISTINCT alert_id) COMMENT = 'Count of federal exclusion and OIG alerts.',
    alerts.open_alert_count AS COUNT_IF(alert_status IN ('New', 'Assigned', 'Investigating')) COMMENT = 'Count of open active federal exclusion or fraud alerts.',
    alerts.critical_alert_count AS COUNT_IF(severity = 'Critical') COMMENT = 'Count of Critical severity federal screening alerts.'
  )
  COMMENT = 'Semantic View for U.S. Small Business Administration (SBA) National Small Business Profile Service (NSBPS) pre-award borrower vetting, citizenship and ownership compliance, IRS 4506-C tax reconciliation, SLA queues, loan-packager rings, and federal exclusion alerts.';
