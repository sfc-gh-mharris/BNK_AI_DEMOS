/*=============================================================================
  KYC/AML — Document Processing Pipeline
  Database: BNK | Schema: KYC_AML | Warehouse: BNK_WH

  AI-powered document processing using:
  - AI_PARSE_DOCUMENT: OCR and layout extraction from uploaded PDFs
  - AI_CLASSIFY: Document type classification (catches mislabeled uploads)
  - AI_EXTRACT (with scores => TRUE): Structured field extraction + confidence
  - VERIFY_IDENTITY: Fuzzy cross-reference against CLIENTS master data
=============================================================================*/

USE DATABASE BNK;
USE SCHEMA KYC_AML;
USE WAREHOUSE BNK_WH;

-------------------------------------------------------------------------------
-- PROCESS_KYC_DOCUMENT
-- Processes a single KYC document through the full AI pipeline:
-- parse -> classify -> extract (with per-field confidence scores).
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE BNK.KYC_AML.PROCESS_KYC_DOCUMENT(DOC_PATH VARCHAR)
RETURNS VARIANT
LANGUAGE SQL
COMMENT = 'Processes a single KYC document through AI_PARSE_DOCUMENT (LAYOUT mode), AI_CLASSIFY, and AI_EXTRACT (with scores => TRUE). Input: relative file path within @BNK.KYC_AML.KYC_DOCUMENTS stage. Returns VARIANT with classification, extracted fields, field confidence scores, and parsed pages.'
AS
$$
BEGIN
    -- Normalize stage path in case caller included @BNK.KYC_AML.KYC_DOCUMENTS/ or leading slash
    LET clean_path VARCHAR := REGEXP_REPLACE(
        REGEXP_REPLACE(TRIM(:DOC_PATH), '^@[^/]+/', ''),
        '^/+', ''
    );

    -- Step 1: Parse the document using AI_PARSE_DOCUMENT with LAYOUT mode
    LET parsed_result VARIANT := (
        SELECT AI_PARSE_DOCUMENT(
            TO_FILE('@BNK.KYC_AML.KYC_DOCUMENTS', :clean_path),
            {'mode': 'LAYOUT', 'page_split': true}
        )
    );

    IF (:parsed_result IS NULL OR :parsed_result:pages IS NULL) THEN
        RETURN OBJECT_CONSTRUCT(
            'error', 'Document could not be parsed from @BNK.KYC_AML.KYC_DOCUMENTS/' || :clean_path,
            'file_path', :clean_path
        );
    END IF;

    -- Step 2: Concatenate Markdown text across all parsed pages
    LET doc_text VARCHAR := (
        SELECT ARRAY_TO_STRING(
            TRANSFORM(:parsed_result:pages, p -> p:content::VARCHAR),
            '\n\n'
        )
    );

    -- Step 3: Classify the document type using AI_CLASSIFY
    LET classification VARIANT := (
        SELECT AI_CLASSIFY(
            :doc_text,
            ['Passport', 'DriversLicense', 'NationalID', 'FinancialStatement', 'UtilityBill', 'CorporateRegistry', 'BeneficialOwnership']
        )
    );
    LET predicted_type VARCHAR := :classification:labels[0]::VARCHAR;

    -- Step 4: Extract structured fields and per-field confidence scores using AI_EXTRACT
    LET extracted VARIANT := (
        SELECT AI_EXTRACT(
            text => :doc_text,
            responseFormat => {
                'full_name': 'Full legal name of the person (First Last) or legal company name printed on the document',
                'date_of_birth': 'Date of birth in YYYY-MM-DD format if this is an individual identity document',
                'document_number': 'Unique passport number, driver license number, or registration number',
                'issuing_authority': 'Government body, country, or authority that issued this document',
                'issuing_country_code': 'Three-letter ISO 3166-1 alpha-3 country code (such as USA, GBR, DEU, FRA, JPN, SGP, AUS, CAN, ITA, IND) of nationality or issuing country',
                'nationality': 'Nationality or country of citizenship or jurisdiction stated on the document',
                'expiry_date': 'Document expiration date in YYYY-MM-DD format if present',
                'address': 'Full residential or registered address if present on the document',
                'reporting_date': 'Financial statement reporting date in YYYY-MM-DD format if this is a financial statement',
                'total_assets_usd_millions': 'Total assets amount if this is a balance sheet or financial statement'
            },
            scores => TRUE
        )
    );

    -- Compute average extraction confidence across populated fields
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
        'classification_confidence', :extraction_confidence,
        'extraction_confidence', :extraction_confidence,
        'extracted_fields', :extracted:response,
        'field_scores', :extracted:scoring:scores,
        'parsed_pages', :parsed_result:pages,
        'raw_text_length', LENGTH(:doc_text),
        'page_count', ARRAY_SIZE(:parsed_result:pages),
        'processing_timestamp', CURRENT_TIMESTAMP()::VARCHAR
    );
END;
$$;

-------------------------------------------------------------------------------
-- VERIFY_IDENTITY
-- Cross-references AI-extracted document fields against client master data.
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE BNK.KYC_AML.VERIFY_IDENTITY(P_CLIENT_ID VARCHAR, P_DOC_ID VARCHAR)
RETURNS VARIANT
LANGUAGE SQL
COMMENT = 'Cross-references AI-extracted document fields against client master data in CLIENTS. Compares full name (Jaro-Winkler similarity across name orderings), date of birth, ISO nationality code, document expiry, and declared vs AI-classified document type.'
AS
$$
BEGIN
    LET client_first_name VARCHAR;
    LET client_last_name VARCHAR;
    LET client_dob DATE;
    LET client_nationality VARCHAR;
    LET client_residence VARCHAR;
    LET client_entity_type VARCHAR;
    LET client_company VARCHAR;

    SELECT first_name, last_name, date_of_birth, nationality, country_of_residence, entity_type, company_name
    INTO :client_first_name, :client_last_name, :client_dob, :client_nationality, :client_residence, :client_entity_type, :client_company
    FROM BNK.KYC_AML.CLIENTS
    WHERE client_id = :P_CLIENT_ID;

    IF (:client_entity_type IS NULL) THEN
        RETURN OBJECT_CONSTRUCT(
            'error', 'Client ID not found in BNK.KYC_AML.CLIENTS',
            'client_id', :P_CLIENT_ID,
            'doc_id', :P_DOC_ID
        );
    END IF;

    LET declared_doc_type VARCHAR := (
        SELECT doc_type FROM BNK.KYC_AML.DOCUMENTS_METADATA WHERE doc_id = :P_DOC_ID LIMIT 1
    );

    LET extracted VARIANT;
    LET doc_confidence FLOAT;
    LET doc_classification VARCHAR;

    SELECT extracted_fields, confidence_score, ai_classification
    INTO :extracted, :doc_confidence, :doc_classification
    FROM BNK.KYC_AML.VERIFICATION_RESULTS
    WHERE doc_id = :P_DOC_ID
    ORDER BY verification_date DESC
    LIMIT 1;

    IF (:extracted IS NULL) THEN
        RETURN OBJECT_CONSTRUCT(
            'error', 'No verification extraction found for doc_id. Run PROCESS_AND_VERIFY_DOCUMENT first.',
            'client_id', :P_CLIENT_ID,
            'doc_id', :P_DOC_ID
        );
    END IF;

    -- Support both unwrapped and .response-wrapped AI_EXTRACT payloads
    LET fields VARIANT := COALESCE(:extracted:response, :extracted);

    LET extracted_name VARCHAR := TRIM(:fields:full_name::VARCHAR);
    LET expected_name VARCHAR := CASE
        WHEN :client_entity_type = 'Individual' THEN TRIM(:client_first_name || ' ' || :client_last_name)
        ELSE TRIM(:client_company)
    END;
    LET expected_name_reversed VARCHAR := CASE
        WHEN :client_entity_type = 'Individual' THEN TRIM(:client_last_name || ', ' || :client_first_name)
        ELSE TRIM(:client_company)
    END;
    LET expected_name_rev_nocomma VARCHAR := CASE
        WHEN :client_entity_type = 'Individual' THEN TRIM(:client_last_name || ' ' || :client_first_name)
        ELSE TRIM(:client_company)
    END;

    LET name_similarity FLOAT := (
        SELECT ROUND(
            GREATEST(
                COALESCE(JAROWINKLER_SIMILARITY(UPPER(:extracted_name), UPPER(:expected_name)), 0),
                COALESCE(JAROWINKLER_SIMILARITY(UPPER(:extracted_name), UPPER(:expected_name_reversed)), 0),
                COALESCE(JAROWINKLER_SIMILARITY(UPPER(:extracted_name), UPPER(:expected_name_rev_nocomma)), 0)
            ) / 100.0,
            3
        )
    );
    LET name_match BOOLEAN := (:name_similarity >= 0.98);

    -- Normalize country / nationality to ISO-3 for accurate comparison
    LET raw_country VARCHAR := UPPER(TRIM(COALESCE(
        NULLIF(:fields:issuing_country_code::VARCHAR, ''),
        NULLIF(:fields:issuing_country::VARCHAR, ''),
        NULLIF(:fields:nationality::VARCHAR, '')
    )));

    LET normalized_country VARCHAR := CASE
        WHEN :raw_country IN ('USA','GBR','DEU','FRA','ITA','ESP','NLD','CHE','CAN','IRL','JPN','SGP','HKG','AUS','IND','ARE','KOR') THEN :raw_country
        WHEN :raw_country LIKE '%UNITED KINGDOM%' OR :raw_country IN ('UK', 'BRITISH') THEN 'GBR'
        WHEN :raw_country LIKE '%UNITED STATES%' OR :raw_country IN ('US', 'AMERICAN') THEN 'USA'
        WHEN :raw_country LIKE '%GERMAN%' THEN 'DEU'
        WHEN :raw_country LIKE '%FRANCE%' OR :raw_country = 'FRENCH' THEN 'FRA'
        WHEN :raw_country LIKE '%ITAL%' THEN 'ITA'
        WHEN :raw_country LIKE '%JAPAN%' THEN 'JPN'
        WHEN :raw_country LIKE '%SINGAPORE%' THEN 'SGP'
        WHEN :raw_country LIKE '%AUSTRALIA%' THEN 'AUS'
        WHEN :raw_country LIKE '%CANAD%' THEN 'CAN'
        WHEN :raw_country LIKE '%INDIA%' THEN 'IND'
        WHEN :raw_country IN ('NONE', 'NULL', 'N/A', 'NOT APPLICABLE') THEN NULL
        ELSE :raw_country
    END;

    LET nationality_match BOOLEAN := CASE
        WHEN :normalized_country IS NULL THEN NULL
        WHEN :normalized_country = UPPER(:client_nationality) THEN TRUE
        WHEN :doc_classification IN ('DriversLicense', 'UtilityBill') AND :normalized_country = UPPER(:client_residence) THEN TRUE
        ELSE FALSE
    END;

    -- Parse and compare Date of Birth for Individual clients
    LET raw_dob VARCHAR := NULLIF(TRIM(:fields:date_of_birth::VARCHAR), '');
    LET extracted_dob DATE := COALESCE(
        TRY_TO_DATE(:raw_dob),
        TRY_TO_DATE(:raw_dob, 'DD MON YYYY'),
        TRY_TO_DATE(:raw_dob, 'MM/DD/YYYY')
    );
    LET dob_match BOOLEAN := CASE
        WHEN :client_entity_type != 'Individual' OR :client_dob IS NULL OR :extracted_dob IS NULL THEN NULL
        ELSE (:extracted_dob = :client_dob)
    END;

    -- Check document expiration
    LET raw_expiry VARCHAR := NULLIF(TRIM(:fields:expiry_date::VARCHAR), '');
    LET expiry_date DATE := COALESCE(
        TRY_TO_DATE(:raw_expiry),
        TRY_TO_DATE(:raw_expiry, 'DD MON YYYY'),
        TRY_TO_DATE(:raw_expiry, 'MM/DD/YYYY')
    );
    LET is_expired BOOLEAN := CASE
        WHEN :expiry_date IS NULL THEN FALSE
        ELSE (:expiry_date < CURRENT_DATE())
    END;

    -- Detect mislabeled uploads (for example FinancialStatement uploaded as Passport)
    LET doc_type_mismatch BOOLEAN := (
        :declared_doc_type IS NOT NULL
        AND :doc_classification IS NOT NULL
        AND UPPER(:declared_doc_type) != UPPER(:doc_classification)
    );

    -- Determine overall match status
    LET overall_status VARCHAR;
    IF (:is_expired) THEN
        overall_status := 'ManualReviewRequired';
    ELSEIF (:client_entity_type = 'Corporate') THEN
        IF (:name_similarity >= 0.90) THEN
            overall_status := 'Match';
        ELSEIF (:name_similarity >= 0.78) THEN
            overall_status := 'Partial';
        ELSE
            overall_status := 'Mismatch';
        END IF;
    ELSE
        IF (:name_similarity < 0.75 OR (:dob_match IS NOT NULL AND NOT :dob_match) OR (:nationality_match IS NOT NULL AND NOT :nationality_match AND :name_similarity < 0.90)) THEN
            overall_status := 'Mismatch';
        ELSEIF (:name_similarity >= 0.95 AND COALESCE(:nationality_match, TRUE) AND COALESCE(:dob_match, TRUE)) THEN
            overall_status := 'Match';
        ELSEIF (:name_similarity >= 0.80 AND COALESCE(:dob_match, TRUE)) THEN
            overall_status := 'Partial';
        ELSE
            overall_status := 'ManualReviewRequired';
        END IF;
    END IF;

    UPDATE BNK.KYC_AML.VERIFICATION_RESULTS
    SET match_status = :overall_status,
        verified_by = 'SYSTEM',
        verification_date = CURRENT_TIMESTAMP()
    WHERE doc_id = :P_DOC_ID;

    RETURN OBJECT_CONSTRUCT(
        'client_id', :P_CLIENT_ID,
        'doc_id', :P_DOC_ID,
        'overall_match_status', :overall_status,
        'declared_doc_type', :declared_doc_type,
        'ai_classified_doc_type', :doc_classification,
        'doc_type_mismatch_detected', :doc_type_mismatch,
        'extraction_confidence', :doc_confidence,
        'field_comparisons', OBJECT_CONSTRUCT(
            'name', OBJECT_CONSTRUCT(
                'extracted', :extracted_name,
                'expected', :expected_name,
                'exact_match', :name_match,
                'similarity_score', :name_similarity
            ),
            'date_of_birth', OBJECT_CONSTRUCT(
                'extracted', :extracted_dob::VARCHAR,
                'expected', :client_dob::VARCHAR,
                'match', :dob_match
            ),
            'nationality', OBJECT_CONSTRUCT(
                'extracted_raw', :raw_country,
                'extracted_iso3', :normalized_country,
                'expected_nationality_iso3', :client_nationality,
                'expected_residence_iso3', :client_residence,
                'match', :nationality_match
            ),
            'document_expiry', OBJECT_CONSTRUCT(
                'expiry_date', :expiry_date::VARCHAR,
                'is_expired', :is_expired
            )
        ),
        'verification_timestamp', CURRENT_TIMESTAMP()::VARCHAR,
        'recommendation', CASE
            WHEN :overall_status = 'Match' AND :doc_type_mismatch THEN 'Entity verified, but upload was mislabeled as ' || :declared_doc_type || ' (AI classified as ' || :doc_classification || '). Re-index document type in DMS.'
            WHEN :overall_status = 'Match' THEN 'Identity verified across all fields. Proceed with KYC workflow per client risk tier.'
            WHEN :overall_status = 'Partial' THEN 'Partial match on client name (likely transliteration or abbreviated given name) with matching DOB/nationality. Route to KYC analyst for sign-off.'
            WHEN :overall_status = 'Mismatch' THEN 'CRITICAL: Identity discrepancy between uploaded document and client master record. Hold onboarding/refresh and escalate to senior AML investigator.'
            ELSE 'Automated verification inconclusive or document expired. Manual analyst review required within SLA.'
        END
    );
END;
$$;

-------------------------------------------------------------------------------
-- PROCESS_AND_VERIFY_DOCUMENT
-- End-to-end pipeline: parse, classify, extract, persist, and verify against CLIENTS.
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE BNK.KYC_AML.PROCESS_AND_VERIFY_DOCUMENT(
    P_CLIENT_ID VARCHAR,
    P_DOC_ID VARCHAR
)
RETURNS VARIANT
LANGUAGE SQL
COMMENT = 'End-to-end document verification pipeline. Accepts client_id and either doc_id or relative stage file_path, runs AI_PARSE_DOCUMENT -> AI_CLASSIFY -> AI_EXTRACT, writes VERIFICATION_RESULTS, updates DOCUMENTS_METADATA, and runs VERIFY_IDENTITY.'
AS
$$
BEGIN
    LET resolved_doc_id VARCHAR;
    LET doc_path VARCHAR;

    SELECT doc_id, file_path
    INTO :resolved_doc_id, :doc_path
    FROM BNK.KYC_AML.DOCUMENTS_METADATA
    WHERE client_id = :P_CLIENT_ID
      AND (doc_id = :P_DOC_ID OR LOWER(file_path) = LOWER(REGEXP_REPLACE(REGEXP_REPLACE(TRIM(:P_DOC_ID), '^@[^/]+/', ''), '^/+', '')))
    LIMIT 1;

    IF (:doc_path IS NULL) THEN
        RETURN OBJECT_CONSTRUCT(
            'error', 'Document record not found in BNK.KYC_AML.DOCUMENTS_METADATA for supplied client_id and doc_id/file_path',
            'client_id', :P_CLIENT_ID,
            'input_doc_identifier', :P_DOC_ID
        );
    END IF;

    CALL BNK.KYC_AML.PROCESS_KYC_DOCUMENT(:doc_path);
    LET process_result VARIANT := (SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

    IF (:process_result:error IS NOT NULL) THEN
        UPDATE BNK.KYC_AML.DOCUMENTS_METADATA
        SET extraction_status = 'Failed'
        WHERE doc_id = :resolved_doc_id;
        RETURN :process_result;
    END IF;

    DELETE FROM BNK.KYC_AML.VERIFICATION_RESULTS WHERE doc_id = :resolved_doc_id;

    INSERT INTO BNK.KYC_AML.VERIFICATION_RESULTS (
        result_id, doc_id, extracted_fields, confidence_score,
        ai_classification, verified_by, verification_date, match_status
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

    UPDATE BNK.KYC_AML.DOCUMENTS_METADATA
    SET extraction_status = 'Completed',
        classification_confidence = COALESCE(:process_result:extraction_confidence::FLOAT, 0.90)
    WHERE doc_id = :resolved_doc_id;

    CALL BNK.KYC_AML.VERIFY_IDENTITY(:P_CLIENT_ID, :resolved_doc_id);
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
-- BATCH_PROCESS_DOCUMENTS
-- Processes Pending documents whose PDF files exist on @BNK.KYC_AML.KYC_DOCUMENTS.
-------------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE BNK.KYC_AML.BATCH_PROCESS_DOCUMENTS(BATCH_SIZE INTEGER DEFAULT 10)
RETURNS VARCHAR
LANGUAGE SQL
COMMENT = 'Batch processes up to BATCH_SIZE Pending documents that are physically staged on @BNK.KYC_AML.KYC_DOCUMENTS. Runs PROCESS_AND_VERIFY_DOCUMENT on each staged file and returns processed/failed counts.'
AS
$$
BEGIN
    ALTER STAGE BNK.KYC_AML.KYC_DOCUMENTS REFRESH;

    CREATE OR REPLACE TEMPORARY TABLE BNK.KYC_AML._KYC_BATCH_TARGETS AS
    SELECT dm.doc_id, dm.file_path, dm.client_id
    FROM BNK.KYC_AML.DOCUMENTS_METADATA dm
    JOIN DIRECTORY(@BNK.KYC_AML.KYC_DOCUMENTS) d
      ON LOWER(d.RELATIVE_PATH) = LOWER(dm.file_path)
    WHERE dm.extraction_status = 'Pending'
    ORDER BY dm.upload_date DESC
    LIMIT :BATCH_SIZE;

    UPDATE BNK.KYC_AML.DOCUMENTS_METADATA
    SET extraction_status = 'Processing'
    WHERE doc_id IN (SELECT doc_id FROM BNK.KYC_AML._KYC_BATCH_TARGETS);

    LET processed_count INTEGER := 0;
    LET failed_count INTEGER := 0;
    LET current_doc_id VARCHAR;
    LET current_client_id VARCHAR;
    LET run_res VARIANT;

    LET target_cursor CURSOR FOR
        SELECT doc_id, client_id FROM BNK.KYC_AML._KYC_BATCH_TARGETS;

    FOR doc IN target_cursor DO
        current_doc_id := doc.doc_id;
        current_client_id := doc.client_id;
        BEGIN
            CALL BNK.KYC_AML.PROCESS_AND_VERIFY_DOCUMENT(:current_client_id, :current_doc_id);
            run_res := (SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));
            IF (:run_res:error IS NOT NULL) THEN
                failed_count := failed_count + 1;
            ELSE
                processed_count := processed_count + 1;
            END IF;
        EXCEPTION
            WHEN OTHER THEN
                UPDATE BNK.KYC_AML.DOCUMENTS_METADATA
                SET extraction_status = 'Failed'
                WHERE doc_id = :current_doc_id;
                failed_count := failed_count + 1;
        END;
    END FOR;

    RETURN 'Batch processing complete. Processed: ' || :processed_count::VARCHAR ||
           ', Failed: ' || :failed_count::VARCHAR ||
           ', Total attempted: ' || (:processed_count + :failed_count)::VARCHAR;
END;
$$;
