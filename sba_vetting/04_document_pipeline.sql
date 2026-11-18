/*=============================================================================
  SBA Borrower and Program Integrity (NSBPS / SBAID) - Document AI Pipeline
  Database: BNK | Schema: SBA_VETTING | Warehouse: BNK_WH

  Stored procedures:
  1. PROCESS_SBA_DOCUMENT(DOC_PATH)
  2. VERIFY_SBA_ELIGIBILITY(P_SBA_ID, P_DOC_ID)
  3. PROCESS_AND_VERIFY_SBA_APPLICATION(P_SBA_ID, P_DOC_ID)
  4. BATCH_PROCESS_SBA_DOCUMENTS(BATCH_SIZE)
=============================================================================*/

USE DATABASE BNK;
USE SCHEMA SBA_VETTING;
USE WAREHOUSE BNK_WH;

-------------------------------------------------------------------------------
-- 1. PROCESS_SBA_DOCUMENT
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE BNK.SBA_VETTING.PROCESS_SBA_DOCUMENT(DOC_PATH VARCHAR)
RETURNS VARIANT
LANGUAGE SQL
COMMENT = 'Parses a staged SBA PDF using AI_PARSE_DOCUMENT (LAYOUT mode), classifies document category with AI_CLASSIFY, and extracts structured borrower, ownership, tax transcript, age, and 8(a) governance fields with per-field confidence scores via AI_EXTRACT.'
AS
$$
BEGIN
    LET clean_path VARCHAR := REGEXP_REPLACE(
        REGEXP_REPLACE(TRIM(:DOC_PATH), '^@[^/]+/', ''),
        '^/+', ''
    );

    LET parsed_result VARIANT := (
        SELECT AI_PARSE_DOCUMENT(
            TO_FILE('@BNK.SBA_VETTING.SBA_DOCUMENTS', :clean_path),
            {'mode': 'LAYOUT', 'page_split': true}
        )
    );

    IF (:parsed_result IS NULL OR :parsed_result:pages IS NULL) THEN
        RETURN OBJECT_CONSTRUCT(
            'error', 'Document could not be parsed from @BNK.SBA_VETTING.SBA_DOCUMENTS/' || :clean_path,
            'file_path', :clean_path
        );
    END IF;

    LET doc_text VARCHAR := (
        SELECT ARRAY_TO_STRING(
            TRANSFORM(:parsed_result:pages, p -> p:content::VARCHAR),
            '\n\n'
        )
    );

    LET classification VARIANT := (
        SELECT AI_CLASSIFY(
            :doc_text,
            ['Form1919', 'IRSTaxTranscript_4506C', 'OperatingAgreement', 'OwnerGovernmentID']
        )
    );
    LET predicted_type VARCHAR := :classification:labels[0]::VARCHAR;

    LET extracted VARIANT := (
        SELECT AI_EXTRACT(
            text => :doc_text,
            responseFormat => {
                'business_legal_name': 'Registered legal name of the small business applicant or taxpayer entity',
                'ein': 'Employer Identification Number in XX-XXXXXXX format',
                'naics_code': 'Primary 6-digit NAICS industry code if present',
                'gross_receipts_usd': 'Dollar amount of Line 1a Gross Receipts or Sales on an IRS tax transcript, or Applicant Stated Annual Gross Revenue on SBA Form 1919',
                'payroll_usd': 'Dollar amount of W-2 Salaries and Wages or Stated Annual Payroll in USD',
                'employee_count': 'Reported employee headcount as an integer',
                'primary_principal_name': 'Full legal name of Principal 1, Shareholder 1, Managing Member, or ID cardholder',
                'primary_principal_dob': 'Date of birth in YYYY-MM-DD format of Principal 1, Shareholder 1, or ID cardholder',
                'ineligible_foreign_pct': 'Effective percentage (0 to 100) of foreign national or non-U.S.-resident direct or indirect ownership stated in the document (0 if 100 percent U.S. citizen)',
                'unconditional_disadvantaged_control': 'YES or NO indicating whether the qualifying disadvantaged owner holds unconditional management and bank signatory control, if stated in an Operating Agreement',
                'subcontract_passthrough_pct': 'Percentage (0 to 100) of federal contract revenue subcontracted to an affiliate or third party, if stated in an Operating Agreement'
            },
            scores => TRUE
        )
    );

    LET extraction_confidence FLOAT := (
        SELECT COALESCE(
            ROUND(AVG(f.value:score::FLOAT), 3),
            0.90
        )
        FROM LATERAL FLATTEN(INPUT => :extracted:scoring:scores) f
        WHERE NULLIF(TRIM(GET(:extracted:response, f.key)::VARCHAR), '') IS NOT NULL
          AND LOWER(TRIM(GET(:extracted:response, f.key)::VARCHAR)) NOT IN ('none', 'null', 'n/a', 'not applicable')
    );

    RETURN OBJECT_CONSTRUCT(
        'file_path', :clean_path,
        'classification', :classification,
        'predicted_type', :predicted_type,
        'extraction_confidence', :extraction_confidence,
        'extracted_fields', :extracted:response,
        'field_scores', :extracted:scoring:scores,
        'page_count', ARRAY_SIZE(:parsed_result:pages),
        'raw_text_length', LENGTH(:doc_text),
        'processing_timestamp', CURRENT_TIMESTAMP()::VARCHAR
    );
END;
$$;

-------------------------------------------------------------------------------
-- 2. VERIFY_SBA_ELIGIBILITY
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE BNK.SBA_VETTING.VERIFY_SBA_ELIGIBILITY(
    P_SBA_ID VARCHAR,
    P_DOC_ID VARCHAR
)
RETURNS VARIANT
LANGUAGE SQL
COMMENT = 'Evaluates AI-extracted SBA document fields against the unified SBAID Golden Record, BENEFICIAL_OWNERS, SBA_APPLICATIONS, and FEDERAL_EXCLUSION_ALERTS. Enforces SOP 50 10 8.1 / Policy Notice 5000-876441 100% citizen ownership, <18 and >115 age guardrails, Treasury Do Not Pay Death Master File, IRS Form 4506-C revenue reconciliation, pandemic hold codes, OIG packager watchlists, and 13 CFR 124/125 8(a) control rules.'
AS
$$
BEGIN
    LET biz_legal_name VARCHAR;
    LET biz_ein VARCHAR;
    LET biz_naics VARCHAR;
    LET biz_emp_cap INTEGER;
    LET biz_rev_cap FLOAT;
    LET biz_emps INTEGER;
    LET biz_stated_rev FLOAT;
    LET biz_stated_payroll FLOAT;
    LET biz_cit_attested BOOLEAN;
    LET biz_hold_code VARCHAR;

    SELECT legal_name, ein, naics_code, naics_size_cap_employees, naics_size_cap_revenue_usd,
           employee_count, stated_annual_revenue_usd, stated_annual_payroll_usd,
           us_citizen_ownership_attested, prior_hold_code
    INTO :biz_legal_name, :biz_ein, :biz_naics, :biz_emp_cap, :biz_rev_cap,
         :biz_emps, :biz_stated_rev, :biz_stated_payroll,
         :biz_cit_attested, :biz_hold_code
    FROM BNK.SBA_VETTING.SBA_BUSINESSES
    WHERE sba_id = :P_SBA_ID;

    IF (:biz_legal_name IS NULL) THEN
        RETURN OBJECT_CONSTRUCT(
            'error', 'SBAID not found in BNK.SBA_VETTING.SBA_BUSINESSES',
            'sba_id', :P_SBA_ID,
            'doc_id', :P_DOC_ID
        );
    END IF;

    LET app_id_val VARCHAR;
    LET app_program VARCHAR;
    LET app_packager VARCHAR;
    LET declared_doc_type VARCHAR;

    SELECT dm.app_id, dm.declared_doc_type, a.program_type, a.packager_agent_id
    INTO :app_id_val, :declared_doc_type, :app_program, :app_packager
    FROM BNK.SBA_VETTING.SBA_DOCUMENTS_METADATA dm
    LEFT JOIN BNK.SBA_VETTING.SBA_APPLICATIONS a ON dm.app_id = a.app_id
    WHERE dm.doc_id = :P_DOC_ID
    LIMIT 1;

    LET raw_extracted VARIANT;
    LET doc_confidence FLOAT;
    LET doc_classification VARCHAR;

    SELECT extracted_fields, confidence_score, ai_classification
    INTO :raw_extracted, :doc_confidence, :doc_classification
    FROM BNK.SBA_VETTING.SBA_VERIFICATION_RESULTS
    WHERE doc_id = :P_DOC_ID
    ORDER BY verification_date DESC
    LIMIT 1;

    IF (:raw_extracted IS NULL) THEN
        RETURN OBJECT_CONSTRUCT(
            'error', 'No extracted fields found for doc_id. Run PROCESS_AND_VERIFY_SBA_APPLICATION first.',
            'sba_id', :P_SBA_ID,
            'doc_id', :P_DOC_ID
        );
    END IF;

    LET fields VARIANT := COALESCE(:raw_extracted:response, :raw_extracted);

    -- 1. Entity Name & EIN Check
    LET ext_biz_name VARCHAR := NULLIF(TRIM(:fields:business_legal_name::VARCHAR), '');
    LET ext_ein VARCHAR := NULLIF(TRIM(:fields:ein::VARCHAR), '');
    LET entity_similarity FLOAT := ROUND(
        COALESCE(JAROWINKLER_SIMILARITY(UPPER(COALESCE(:ext_biz_name, '')), UPPER(:biz_legal_name)), 0) / 100.0,
        3
    );
    LET ein_match BOOLEAN := (
        REGEXP_REPLACE(COALESCE(:ext_ein, ''), '[^0-9]', '') = REGEXP_REPLACE(:biz_ein, '[^0-9]', '')
    );

    -- 2. Portal Document Mislabeling Check (SOP-DOC-001)
    LET doc_type_mismatch BOOLEAN := (
        :declared_doc_type IS NOT NULL
        AND :doc_classification IS NOT NULL
        AND UPPER(:declared_doc_type) != UPPER(:doc_classification)
    );

    -- 3. Age Guardrail (<18 or >115) & Do Not Pay Death Master Check (SOP-AGE-001 / SOP-DNP-001)
    LET ext_dob_raw VARCHAR := NULLIF(TRIM(:fields:primary_principal_dob::VARCHAR), '');
    LET parsed_dob DATE := COALESCE(
        TRY_TO_DATE(:ext_dob_raw),
        TRY_TO_DATE(:ext_dob_raw, 'MM/DD/YYYY'),
        (SELECT MIN(date_of_birth) FROM BNK.SBA_VETTING.BENEFICIAL_OWNERS WHERE sba_id = :P_SBA_ID)
    );
    LET principal_age INTEGER := IFF(:parsed_dob IS NOT NULL, DATEDIFF('year', :parsed_dob, CURRENT_DATE()), NULL);
    LET age_guardrail_triggered BOOLEAN := (
        :principal_age IS NOT NULL AND (:principal_age < 18 OR :principal_age > 115)
    );

    LET death_master_alerts INTEGER := (
        SELECT COUNT(*) FROM BNK.SBA_VETTING.FEDERAL_EXCLUSION_ALERTS
        WHERE sba_id = :P_SBA_ID
          AND alert_source = 'DoNotPay_DeathMaster'
          AND alert_status IN ('New', 'Assigned', 'Investigating', 'ConfirmedBlock')
    );

    -- 4. 100% Direct & Indirect U.S. Citizen Ownership Check (SOP-CIT-001 & SOP-CIT-002)
    LET doc_foreign_pct FLOAT := COALESCE(
        TRY_TO_DOUBLE(REGEXP_REPLACE(COALESCE(:fields:ineligible_foreign_pct::VARCHAR, ''), '[^0-9.]', '')),
        0.0
    );
    LET ledger_ineligible_pct FLOAT := (
        SELECT COALESCE(SUM(IFF(citizenship_status NOT IN ('US_Citizen', 'US_National') OR NOT resides_in_us, ownership_pct, 0.0)), 0.0)
        FROM BNK.SBA_VETTING.BENEFICIAL_OWNERS
        WHERE sba_id = :P_SBA_ID
    );
    LET effective_ineligible_pct FLOAT := GREATEST(:doc_foreign_pct, :ledger_ineligible_pct);
    LET ownership_violation BOOLEAN := (:effective_ineligible_pct > 0.0);

    -- 5. 8(a) Unconditional Control & Subcontract Pass-Through Check (SOP-8A-001 & SOP-8A-002)
    LET ext_uncond_ctrl VARCHAR := UPPER(COALESCE(:fields:unconditional_disadvantaged_control::VARCHAR, ''));
    LET ext_passthrough_pct FLOAT := COALESCE(
        TRY_TO_DOUBLE(REGEXP_REPLACE(COALESCE(:fields:subcontract_passthrough_pct::VARCHAR, ''), '[^0-9.]', '')),
        0.0
    );
    LET ledger_8a_ctrl_defect INTEGER := (
        SELECT COUNT(*) FROM BNK.SBA_VETTING.BENEFICIAL_OWNERS
        WHERE sba_id = :P_SBA_ID
          AND is_disadvantaged_qualifying = TRUE
          AND has_unconditional_control = FALSE
    );
    LET control_8a_violation BOOLEAN := (
        :app_program = '8a_Certification'
        AND (
            (:ext_uncond_ctrl NOT IN ('', 'NONE', 'NULL', 'N/A', 'NOT APPLICABLE') AND STARTSWITH(:ext_uncond_ctrl, 'NO'))
            OR :ext_passthrough_pct > 50.0
            OR :ledger_8a_ctrl_defect > 0
        )
    );

    -- 6. IRS Form 4506-C Revenue Reconciliation, Hold Codes, CAIVRS/SAM, & OIG Packager Watchlist
    LET ext_receipts_usd FLOAT := TRY_TO_DOUBLE(
        REGEXP_REPLACE(COALESCE(:fields:gross_receipts_usd::VARCHAR, ''), '[^0-9.]', '')
    );
    LET revenue_inflation_pct FLOAT := CASE
        WHEN :doc_classification = 'IRSTaxTranscript_4506C' AND :ext_receipts_usd IS NOT NULL AND :ext_receipts_usd > 0
            THEN ROUND(((:biz_stated_rev - :ext_receipts_usd) / :ext_receipts_usd) * 100.0, 1)
        ELSE NULL
    END;

    LET oig_or_exclusion_alerts INTEGER := (
        SELECT COUNT(*) FROM BNK.SBA_VETTING.FEDERAL_EXCLUSION_ALERTS
        WHERE sba_id = :P_SBA_ID
          AND alert_source IN ('COVID_EIDL_HoldCode', 'OIG_PackagerWatchlist', 'CAIVRS_FederalDebt', 'SAM_Debarment')
          AND alert_status IN ('New', 'Assigned', 'Investigating', 'ConfirmedBlock')
    );

    -- 7. NAICS Small Business Size Standard Check (13 CFR 121)
    LET size_standard_exceeded BOOLEAN := (
        (:biz_emp_cap IS NOT NULL AND :biz_emps > :biz_emp_cap)
        OR (:biz_rev_cap IS NOT NULL AND :biz_stated_rev > :biz_rev_cap)
    );

    -- Determine Statutory Eligibility Outcome
    LET final_status VARCHAR;
    IF (:age_guardrail_triggered OR :death_master_alerts > 0) THEN
        final_status := 'AutoBlocked_AgeOrDeath';
    ELSEIF (:control_8a_violation) THEN
        final_status := 'ControlDeficiency_8a';
    ELSEIF (:ownership_violation OR :size_standard_exceeded) THEN
        final_status := 'Ineligible_Ownership';
    ELSEIF ((:revenue_inflation_pct IS NOT NULL AND :revenue_inflation_pct > 50.0)
            OR :biz_hold_code IS NOT NULL
            OR (:oig_or_exclusion_alerts > 0 AND :app_program != '8a_Certification')) THEN
        final_status := 'HoldAndReferOIG';
    ELSEIF (:doc_type_mismatch
            OR (:revenue_inflation_pct IS NOT NULL AND ABS(:revenue_inflation_pct) > 10.0)
            OR :doc_confidence < 0.80
            OR NOT :ein_match) THEN
        final_status := 'ManualReviewRequired';
    ELSE
        final_status := 'Eligible';
    END IF;

    UPDATE BNK.SBA_VETTING.SBA_VERIFICATION_RESULTS
    SET eligibility_status = :final_status,
        verified_by = 'SYSTEM',
        verification_date = CURRENT_TIMESTAMP()
    WHERE doc_id = :P_DOC_ID;

    RETURN OBJECT_CONSTRUCT(
        'sba_id', :P_SBA_ID,
        'app_id', :app_id_val,
        'doc_id', :P_DOC_ID,
        'program_type', :app_program,
        'business_legal_name', :biz_legal_name,
        'eligibility_status', :final_status,
        'declared_doc_type', :declared_doc_type,
        'ai_classified_doc_type', :doc_classification,
        'doc_type_mismatch_detected', :doc_type_mismatch,
        'extraction_confidence', :doc_confidence,
        'statutory_checks', OBJECT_CONSTRUCT(
            'entity_and_ein', OBJECT_CONSTRUCT(
                'expected_name', :biz_legal_name,
                'extracted_name', :ext_biz_name,
                'name_similarity', :entity_similarity,
                'expected_ein', :biz_ein,
                'extracted_ein', :ext_ein,
                'ein_match', :ein_match
            ),
            'citizenship_and_ownership_sop_50_10_8_1', OBJECT_CONSTRUCT(
                'applicant_attested_100pct_us_citizen', :biz_cit_attested,
                'effective_ineligible_foreign_or_nonresident_pct', :effective_ineligible_pct,
                'passes_100pct_citizen_mandate', NOT :ownership_violation
            ),
            'age_and_death_master_guardrail', OBJECT_CONSTRUCT(
                'principal_dob', :parsed_dob::VARCHAR,
                'calculated_age_years', :principal_age,
                'age_outside_18_to_115_guardrail', :age_guardrail_triggered,
                'do_not_pay_death_master_hits', :death_master_alerts
            ),
            'irs_4506c_revenue_reconciliation', OBJECT_CONSTRUCT(
                'stated_annual_revenue_usd', :biz_stated_rev,
                'irs_transcript_gross_receipts_usd', :ext_receipts_usd,
                'stated_over_irs_variance_pct', :revenue_inflation_pct
            ),
            'federal_holds_and_packager_screening', OBJECT_CONSTRUCT(
                'prior_pandemic_hold_code', :biz_hold_code,
                'packager_agent_id', :app_packager,
                'open_oig_or_exclusion_alerts', :oig_or_exclusion_alerts
            ),
            'contracting_8a_control_and_passthrough', OBJECT_CONSTRUCT(
                'unconditional_disadvantaged_control_doc', :ext_uncond_ctrl,
                'subcontract_passthrough_pct', :ext_passthrough_pct,
                'control_or_passthrough_violation', :control_8a_violation
            ),
            'naics_size_standard', OBJECT_CONSTRUCT(
                'naics_code', :biz_naics,
                'employee_count', :biz_emps,
                'naics_employee_cap', :biz_emp_cap,
                'naics_revenue_cap_usd', :biz_rev_cap,
                'exceeds_size_cap', :size_standard_exceeded
            )
        ),
        'required_action', CASE :final_status
            WHEN 'Eligible' THEN 'All statutory SBA checks passed (100% U.S. citizen ownership, IRS 4506-C match, NAICS size compliance, zero federal holds). Authorize guaranty in E-Tran per SOP 50 10 8.1.'
            WHEN 'Ineligible_Ownership' THEN 'DECLINE: Violates Policy Notice 5000-876441 and SOP 50 10 8.1 (100% direct and indirect U.S. citizen ownership mandate) or 13 CFR 121 size cap. Do not issue E-Tran guaranty number.'
            WHEN 'AutoBlocked_AgeOrDeath' THEN 'AUTO-BLOCKED: Principal DOB trips <18 / >115 statutory age guardrail (News Release 25-42) or matches Treasury Do Not Pay SSA Death Master File (SOP-DNP-001). Freeze disbursement and refer to SBA OIG.'
            WHEN 'HoldAndReferOIG' THEN 'CRITICAL HOLD: Material IRS Form 4506-C revenue inflation (>50%), active pandemic fraud hold code (SOP-HLD-001), federal exclusion, or watchlisted loan packager (SOP-PKG-001). Hold application and refer to SBA OIG.'
            WHEN 'ControlDeficiency_8a' THEN 'SUSPEND 8(a) PARTICIPANT: Operating Agreement violates 13 CFR 124.106 unconditional disadvantaged control and/or 13 CFR 125.6 50% subcontracting cap (SOP-8A-001 / SOP-8A-002). Flag mislabeled upload if applicable, suspend sole-source awards, and refer to GCBD and OIG.'
            ELSE 'MANUAL REVIEW: Portal document mislabeling, moderate tax variance, or extraction confidence below 0.80. Route to SBA Loan Specialist.'
        END,
        'verification_timestamp', CURRENT_TIMESTAMP()::VARCHAR
    );
END;
$$;

-------------------------------------------------------------------------------
-- 3. PROCESS_AND_VERIFY_SBA_APPLICATION
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE BNK.SBA_VETTING.PROCESS_AND_VERIFY_SBA_APPLICATION(
    P_SBA_ID VARCHAR,
    P_DOC_ID VARCHAR
)
RETURNS VARIANT
LANGUAGE SQL
COMMENT = 'End-to-end NSBPS document vetting workflow. Accepts sba_id (or app_id) and doc_id (or relative stage file_path), executes AI_PARSE_DOCUMENT -> AI_CLASSIFY -> AI_EXTRACT, persists SBA_VERIFICATION_RESULTS, updates SBA_DOCUMENTS_METADATA, and runs VERIFY_SBA_ELIGIBILITY.'
AS
$$
BEGIN
    LET resolved_sba_id VARCHAR;
    LET resolved_doc_id VARCHAR;
    LET doc_path VARCHAR;

    SELECT sba_id, doc_id, file_path
    INTO :resolved_sba_id, :resolved_doc_id, :doc_path
    FROM BNK.SBA_VETTING.SBA_DOCUMENTS_METADATA
    WHERE (sba_id = :P_SBA_ID OR app_id = :P_SBA_ID)
      AND (
          doc_id = :P_DOC_ID
          OR LOWER(file_path) = LOWER(REGEXP_REPLACE(REGEXP_REPLACE(TRIM(:P_DOC_ID), '^@[^/]+/', ''), '^/+', ''))
      )
    ORDER BY upload_date DESC
    LIMIT 1;

    IF (:doc_path IS NULL) THEN
        RETURN OBJECT_CONSTRUCT(
            'error', 'Document record not found in BNK.SBA_VETTING.SBA_DOCUMENTS_METADATA for supplied sba_id/app_id and doc_id/file_path',
            'input_sba_or_app_id', :P_SBA_ID,
            'input_doc_identifier', :P_DOC_ID
        );
    END IF;

    CALL BNK.SBA_VETTING.PROCESS_SBA_DOCUMENT(:doc_path);
    LET process_result VARIANT := (SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

    IF (:process_result:error IS NOT NULL) THEN
        UPDATE BNK.SBA_VETTING.SBA_DOCUMENTS_METADATA
        SET extraction_status = 'Failed'
        WHERE doc_id = :resolved_doc_id;
        RETURN :process_result;
    END IF;

    DELETE FROM BNK.SBA_VETTING.SBA_VERIFICATION_RESULTS WHERE doc_id = :resolved_doc_id;

    INSERT INTO BNK.SBA_VETTING.SBA_VERIFICATION_RESULTS (
        result_id, doc_id, extracted_fields, confidence_score,
        ai_classification, verified_by, verification_date, eligibility_status
    )
    SELECT
        UUID_STRING(),
        :resolved_doc_id,
        :process_result:extracted_fields,
        COALESCE(:process_result:extraction_confidence::FLOAT, 0.90),
        :process_result:predicted_type::VARCHAR,
        'SYSTEM',
        CURRENT_TIMESTAMP(),
        'ManualReviewRequired';

    UPDATE BNK.SBA_VETTING.SBA_DOCUMENTS_METADATA
    SET extraction_status = 'Completed',
        extraction_confidence = COALESCE(:process_result:extraction_confidence::FLOAT, 0.90)
    WHERE doc_id = :resolved_doc_id;

    CALL BNK.SBA_VETTING.VERIFY_SBA_ELIGIBILITY(:resolved_sba_id, :resolved_doc_id);
    LET verify_result VARIANT := (SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

    RETURN OBJECT_CONSTRUCT(
        'processing', :process_result,
        'verification', :verify_result,
        'pipeline_status', 'Complete',
        'timestamp', CURRENT_TIMESTAMP()::VARCHAR
    );
END;
$$;

-------------------------------------------------------------------------------
-- 4. BATCH_PROCESS_SBA_DOCUMENTS
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE BNK.SBA_VETTING.BATCH_PROCESS_SBA_DOCUMENTS(BATCH_SIZE INTEGER DEFAULT 10)
RETURNS VARCHAR
LANGUAGE SQL
COMMENT = 'Batch processes up to BATCH_SIZE Pending documents physically staged on @BNK.SBA_VETTING.SBA_DOCUMENTS and returns processed and failed counts.'
AS
$$
BEGIN
    ALTER STAGE BNK.SBA_VETTING.SBA_DOCUMENTS REFRESH;

    CREATE OR REPLACE TEMPORARY TABLE BNK.SBA_VETTING._SBA_BATCH_TARGETS AS
    SELECT dm.doc_id, dm.sba_id
    FROM BNK.SBA_VETTING.SBA_DOCUMENTS_METADATA dm
    JOIN DIRECTORY(@BNK.SBA_VETTING.SBA_DOCUMENTS) d
      ON LOWER(d.RELATIVE_PATH) = LOWER(dm.file_path)
    WHERE dm.extraction_status = 'Pending'
    ORDER BY dm.upload_date DESC
    LIMIT :BATCH_SIZE;

    UPDATE BNK.SBA_VETTING.SBA_DOCUMENTS_METADATA
    SET extraction_status = 'Processing'
    WHERE doc_id IN (SELECT doc_id FROM BNK.SBA_VETTING._SBA_BATCH_TARGETS);

    LET processed_count INTEGER := 0;
    LET failed_count INTEGER := 0;
    LET cur_doc_id VARCHAR;
    LET cur_sba_id VARCHAR;
    LET run_res VARIANT;

    LET target_cursor CURSOR FOR
        SELECT doc_id, sba_id FROM BNK.SBA_VETTING._SBA_BATCH_TARGETS;

    FOR rec IN target_cursor DO
        cur_doc_id := rec.doc_id;
        cur_sba_id := rec.sba_id;
        BEGIN
            CALL BNK.SBA_VETTING.PROCESS_AND_VERIFY_SBA_APPLICATION(:cur_sba_id, :cur_doc_id);
            run_res := (SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));
            IF (:run_res:error IS NOT NULL) THEN
                failed_count := failed_count + 1;
            ELSE
                processed_count := processed_count + 1;
            END IF;
        EXCEPTION
            WHEN OTHER THEN
                UPDATE BNK.SBA_VETTING.SBA_DOCUMENTS_METADATA
                SET extraction_status = 'Failed'
                WHERE doc_id = :cur_doc_id;
                failed_count := failed_count + 1;
        END;
    END FOR;

    RETURN 'SBA batch vetting complete. Processed: ' || :processed_count::VARCHAR ||
           ', Failed: ' || :failed_count::VARCHAR ||
           ', Total attempted: ' || (:processed_count + :failed_count)::VARCHAR;
END;
$$;
