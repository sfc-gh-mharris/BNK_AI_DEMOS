-- =============================================================================
-- KYC/AML — SEMANTIC VIEW
-- Schema: BNK.KYC_AML
--
-- Creates a Semantic View joining CLIENTS, KYC_CASES, DOCUMENTS_METADATA,
-- VERIFICATION_RESULTS, and ALERT_QUEUE for natural-language analytics via
-- Cortex Analyst in the KYC_AGENT.
--
-- Clause order: TABLES -> RELATIONSHIPS -> FACTS -> DIMENSIONS -> METRICS
-- =============================================================================

USE DATABASE BNK;
USE SCHEMA KYC_AML;
USE WAREHOUSE BNK_WH;

CREATE OR ALTER SEMANTIC VIEW BNK.KYC_AML.SV_KYC_AML
  TABLES (
    clients AS BNK.KYC_AML.CLIENTS PRIMARY KEY (client_id) COMMENT = 'Master KYC client registry covering individual and corporate banking relationships.',
    kyc_cases AS BNK.KYC_AML.KYC_CASES PRIMARY KEY (case_id) COMMENT = 'KYC review cases for onboarding, periodic reviews, trigger events, and enhanced due diligence.',
    documents AS BNK.KYC_AML.DOCUMENTS_METADATA PRIMARY KEY (doc_id) COMMENT = 'Uploaded KYC documents tracked across stage paths and AI extraction states.',
    verifications AS BNK.KYC_AML.VERIFICATION_RESULTS PRIMARY KEY (result_id) COMMENT = 'AI extraction outputs, confidence scores, and identity verification match outcomes.',
    alerts AS BNK.KYC_AML.ALERT_QUEUE PRIMARY KEY (alert_id) COMMENT = 'KYC/AML risk alerts from sanctions, adverse media, unusual activity, and document expiry monitoring.'
  )
  RELATIONSHIPS (
    cases_to_clients AS kyc_cases (client_id) REFERENCES clients (client_id),
    documents_to_cases AS documents (case_id) REFERENCES kyc_cases (case_id),
    verifications_to_documents AS verifications (doc_id) REFERENCES documents (doc_id),
    alerts_to_clients AS alerts (client_id) REFERENCES clients (client_id)
  )
  FACTS (
    documents.file_size_bytes AS file_size_bytes COMMENT = 'Uploaded document size in bytes.',
    documents.classification_confidence AS classification_confidence COMMENT = 'Confidence score (0.0 to 1.0) recorded on document metadata after AI processing.',
    verifications.confidence_score AS confidence_score COMMENT = 'Overall extraction confidence score (0.0 to 1.0) for the verification result.'
  )
  DIMENSIONS (
    clients.client_id AS client_id COMMENT = 'Unique client identifier (for example CL-DEMO-001 or UUID).',
    clients.entity_type AS entity_type COMMENT = 'Legal entity classification: Individual or Corporate.' SAMPLE_VALUES ('Individual', 'Corporate') IS_ENUM,
    clients.first_name AS first_name COMMENT = 'Individual client given name.',
    clients.last_name AS last_name COMMENT = 'Individual client family name / surname.',
    clients.date_of_birth AS date_of_birth COMMENT = 'Individual client date of birth (YYYY-MM-DD).',
    clients.company_name AS company_name COMMENT = 'Registered legal name for corporate clients.',
    clients.client_display_name AS COALESCE(first_name || ' ' || last_name, company_name) COMMENT = 'Display name for any client (full name for individuals, company name for corporates).',
    clients.nationality AS nationality COMMENT = 'ISO 3166-1 alpha-3 nationality or country of incorporation code (USA, GBR, DEU, FRA, ITA, ESP, NLD, CHE, CAN, IRL, JPN, SGP, HKG, AUS, IND, ARE, KOR).',
    clients.country_of_residence AS country_of_residence COMMENT = 'ISO 3166-1 alpha-3 primary residence or registered office country code.',
    clients.risk_rating AS risk_rating COMMENT = 'Composite KYC risk rating: Low, Medium, High, PEP, Sanctioned.' SAMPLE_VALUES ('Low', 'Medium', 'High', 'PEP', 'Sanctioned') IS_ENUM,
    clients.onboarding_date AS onboarding_date COMMENT = 'Date client relationship was established.',
    clients.relationship_manager AS relationship_manager COMMENT = 'Assigned Relationship Manager full name.',
    clients.client_status AS status COMMENT = 'Client lifecycle status: Active, UnderReview, Restricted, Exited.' SAMPLE_VALUES ('Active', 'UnderReview', 'Restricted', 'Exited') IS_ENUM,

    kyc_cases.case_id AS case_id COMMENT = 'Unique KYC case identifier (for example CASE-DEMO-001 or UUID).',
    kyc_cases.case_type AS case_type COMMENT = 'Type of KYC review: NewClient, PeriodicReview, TriggerEvent, EnhancedDueDiligence.' SAMPLE_VALUES ('NewClient', 'PeriodicReview', 'TriggerEvent', 'EnhancedDueDiligence') IS_ENUM,
    kyc_cases.case_status AS status COMMENT = 'Case workflow state: Open, InReview, PendingDocuments, Approved, Rejected, Escalated. Active/open cases have status NOT IN (Approved, Rejected).' SAMPLE_VALUES ('Open', 'InReview', 'PendingDocuments', 'Approved', 'Rejected', 'Escalated') IS_ENUM,
    kyc_cases.priority AS priority COMMENT = 'Case SLA priority tier: Low, Medium, High, Critical.' SAMPLE_VALUES ('Low', 'Medium', 'High', 'Critical') IS_ENUM,
    kyc_cases.assigned_analyst AS assigned_analyst COMMENT = 'KYC analyst assigned to the case.',
    kyc_cases.opened_date AS opened_date COMMENT = 'Date the KYC case was opened.',
    kyc_cases.due_date AS due_date COMMENT = 'SLA target due date for resolving the case.',
    kyc_cases.closed_date AS closed_date COMMENT = 'Date the case reached a terminal state (Approved or Rejected). NULL for active cases.',
    kyc_cases.is_overdue AS (status NOT IN ('Approved', 'Rejected') AND due_date < CURRENT_DATE()) COMMENT = 'TRUE when an active/open KYC case is past its SLA due_date.',
    kyc_cases.notes AS notes COMMENT = 'Analyst case notes and escalation summary.',

    documents.doc_id AS doc_id COMMENT = 'Unique document identifier.',
    documents.declared_doc_type AS doc_type COMMENT = 'Document category declared at upload: Passport, DriversLicense, NationalID, FinancialStatement, UtilityBill, CorporateRegistry, BeneficialOwnership.' SAMPLE_VALUES ('Passport', 'DriversLicense', 'NationalID', 'FinancialStatement', 'UtilityBill', 'CorporateRegistry', 'BeneficialOwnership') IS_ENUM,
    documents.file_path AS file_path COMMENT = 'Relative stage file path within @BNK.KYC_AML.KYC_DOCUMENTS (staged demo files start with clients/).',
    documents.upload_date AS upload_date COMMENT = 'Timestamp when the document was uploaded.',
    documents.extraction_status AS extraction_status COMMENT = 'AI document pipeline state: Pending, Processing, Completed, Failed.' SAMPLE_VALUES ('Pending', 'Processing', 'Completed', 'Failed') IS_ENUM,

    verifications.result_id AS result_id COMMENT = 'Unique verification result identifier.',
    verifications.ai_classification AS ai_classification COMMENT = 'Document type predicted by AI_CLASSIFY.',
    verifications.verified_by AS verified_by COMMENT = 'Actor that completed verification (SYSTEM or analyst name).',
    verifications.verification_date AS verification_date COMMENT = 'Timestamp when identity verification was completed.',
    verifications.match_status AS match_status COMMENT = 'Identity cross-reference outcome: Match, Partial, Mismatch, ManualReviewRequired.' SAMPLE_VALUES ('Match', 'Partial', 'Mismatch', 'ManualReviewRequired') IS_ENUM,

    alerts.alert_id AS alert_id COMMENT = 'Unique AML/KYC alert identifier.',
    alerts.alert_type AS alert_type COMMENT = 'Alert trigger category: SanctionsHit, AdverseMedia, UnusualActivity, DocumentExpiry, RiskRatingChange.' SAMPLE_VALUES ('SanctionsHit', 'AdverseMedia', 'UnusualActivity', 'DocumentExpiry', 'RiskRatingChange') IS_ENUM,
    alerts.severity AS severity COMMENT = 'Alert urgency level: Low, Medium, High, Critical.' SAMPLE_VALUES ('Low', 'Medium', 'High', 'Critical') IS_ENUM,
    alerts.created_date AS created_date COMMENT = 'Timestamp when the alert was created.',
    alerts.alert_status AS status COMMENT = 'Alert disposition status: New, Assigned, Investigating, Resolved, FalsePositive.' SAMPLE_VALUES ('New', 'Assigned', 'Investigating', 'Resolved', 'FalsePositive') IS_ENUM,
    alerts.assigned_to AS assigned_to COMMENT = 'Investigator assigned to the alert.'
  )
  METRICS (
    clients.client_count AS COUNT(DISTINCT client_id) COMMENT = 'Count of distinct clients.',
    kyc_cases.case_count AS COUNT(DISTINCT case_id) COMMENT = 'Count of distinct KYC cases.',
    kyc_cases.open_case_count AS COUNT_IF(status NOT IN ('Approved', 'Rejected')) COMMENT = 'Count of active/unresolved KYC cases.',
    kyc_cases.overdue_case_count AS COUNT_IF(status NOT IN ('Approved', 'Rejected') AND due_date < CURRENT_DATE()) COMMENT = 'Count of active KYC cases past their SLA due date.',
    documents.document_count AS COUNT(DISTINCT doc_id) COMMENT = 'Count of KYC documents.',
    documents.pending_document_count AS COUNT_IF(extraction_status = 'Pending') COMMENT = 'Count of documents awaiting AI extraction.',
    verifications.verification_count AS COUNT(DISTINCT result_id) COMMENT = 'Count of verification results.',
    verifications.avg_confidence_score AS AVG(confidence_score) COMMENT = 'Average extraction confidence score.',
    verifications.mismatch_count AS COUNT_IF(match_status = 'Mismatch') COMMENT = 'Count of identity verification mismatches.',
    alerts.alert_count AS COUNT(DISTINCT alert_id) COMMENT = 'Count of KYC/AML risk alerts.',
    alerts.open_alert_count AS COUNT_IF(status IN ('New', 'Assigned', 'Investigating')) COMMENT = 'Count of open/active alerts requiring action.',
    alerts.critical_alert_count AS COUNT_IF(severity = 'Critical') COMMENT = 'Count of Critical severity alerts.'
  )
  COMMENT = 'Semantic View for KYC/AML compliance analytics covering clients, review cases, overdue SLAs, uploaded documents, AI verification outcomes, and AML risk alerts.';
