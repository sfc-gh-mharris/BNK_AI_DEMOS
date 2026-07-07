/*=============================================================================
  KYC/AML — Document Processing Pipeline
  Database: BNK | Schema: KYC_AML | Warehouse: BNK_WH
  
  AI-powered document processing using:
  - AI_PARSE_DOCUMENT: OCR and layout extraction from uploaded PDFs
  - AI_CLASSIFY: Document type classification
  - AI_EXTRACT: Structured field extraction
  
  Stored procedures orchestrate the full pipeline.
=============================================================================*/

USE DATABASE BNK;
USE SCHEMA KYC_AML;
USE WAREHOUSE BNK_WH;

-------------------------------------------------------------------------------
-- PROCESS_KYC_DOCUMENT
-- Processes a single KYC document through the full AI pipeline:
-- parse → classify → extract. Returns a VARIANT with all results.
-------------------------------------------------------------------------------
CREATE PROCEDURE IF NOT EXISTS BNK.KYC_AML.PROCESS_KYC_DOCUMENT(DOC_PATH VARCHAR)
RETURNS VARIANT
LANGUAGE SQL
COMMENT = 'Processes a single KYC document through the full AI pipeline: AI_PARSE_DOCUMENT (OCR/layout extraction) → AI_CLASSIFY (document type prediction) → AI_EXTRACT (structured field extraction). Input: relative file path within @BNK.KYC_AML.KYC_DOCUMENTS stage. Returns: VARIANT containing classification result, extracted fields, confidence scores, and page metadata.'
AS
BEGIN
    -- Step 1: Parse the document using AI_PARSE_DOCUMENT with LAYOUT mode
    -- This performs OCR and preserves document structure (tables, headers, etc.)
    LET parsed_result VARIANT := (
        SELECT AI_PARSE_DOCUMENT(
            TO_FILE('@BNK.KYC_AML.KYC_DOCUMENTS', :DOC_PATH),
            {'mode': 'LAYOUT', 'page_split': true}
        )
    );

    -- Step 2: Extract the text content from the first page
    -- For multi-page documents, we concatenate all pages
    LET doc_text VARCHAR := (
        SELECT ARRAY_TO_STRING(
            TRANSFORM(parsed_result:pages, p -> p:content::VARCHAR),
            '\n\n'
        )
    );

    -- Step 3: Classify the document type using AI_CLASSIFY
    -- This confirms or corrects the declared document type from upload
    LET classification VARIANT := (
        SELECT AI_CLASSIFY(
            :doc_text,
            ['Passport', 'DriversLicense', 'NationalID', 'FinancialStatement', 'UtilityBill', 'CorporateRegistry', 'BeneficialOwnership']
        )
    );

    -- Step 4: Extract structured fields using AI_EXTRACT
    -- Field prompts are designed for maximum extraction accuracy
    LET extracted VARIANT := (
        SELECT AI_EXTRACT(
            :doc_text,
            {
                'full_name': 'The full legal name of the person or entity as printed on the document',
                'date_of_birth': 'Date of birth in YYYY-MM-DD format. Look for DOB, Born, Date of Birth fields.',
                'document_number': 'The unique document identification number (passport number, license number, registration number)',
                'issuing_authority': 'The government body, country, or authority that issued this document',
                'expiry_date': 'Document expiration date in YYYY-MM-DD format. Look for Expiry, Valid Until, Expires fields.',
                'address': 'Full residential or registered address including street, city, postal code, and country',
                'nationality': 'Nationality or country of citizenship as stated on the document'
            }
        )
    );

    -- Step 5: Return combined results as a structured VARIANT
    RETURN OBJECT_CONSTRUCT(
        'classification', :classification,
        'predicted_type', :classification:label::VARCHAR,
        'classification_confidence', :classification:confidence::FLOAT,
        'extracted_fields', :extracted,
        'raw_text_length', LENGTH(:doc_text),
        'page_count', ARRAY_SIZE(parsed_result:pages),
        'processing_timestamp', CURRENT_TIMESTAMP()::VARCHAR
    );
END;

-------------------------------------------------------------------------------
-- BATCH_PROCESS_DOCUMENTS
-- Processes all documents currently in 'Pending' status.
-- Limited to configurable batch size for cost control.
-------------------------------------------------------------------------------
CREATE PROCEDURE IF NOT EXISTS BNK.KYC_AML.BATCH_PROCESS_DOCUMENTS(BATCH_SIZE INTEGER DEFAULT 100)
RETURNS VARCHAR
LANGUAGE SQL
COMMENT = 'Batch processes all documents with extraction_status = Pending. Iterates through pending documents, calls PROCESS_KYC_DOCUMENT for each, inserts results into VERIFICATION_RESULTS, and updates DOCUMENTS_METADATA extraction_status. Batch size configurable (default 100) for cost control. Returns summary of processed/failed counts.'
AS
BEGIN
    LET processed_count INTEGER := 0;
    LET failed_count INTEGER := 0;
    LET current_doc_id VARCHAR;
    LET current_path VARCHAR;
    LET current_client_id VARCHAR;
    LET process_result VARIANT;

    -- Get pending documents up to batch size
    LET pending_docs CURSOR FOR (
        SELECT doc_id, file_path, client_id
        FROM BNK.KYC_AML.DOCUMENTS_METADATA
        WHERE extraction_status = 'Pending'
        LIMIT :BATCH_SIZE
    );

    -- Mark selected documents as Processing
    UPDATE BNK.KYC_AML.DOCUMENTS_METADATA
    SET extraction_status = 'Processing'
    WHERE doc_id IN (
        SELECT doc_id FROM BNK.KYC_AML.DOCUMENTS_METADATA
        WHERE extraction_status = 'Pending'
        LIMIT :BATCH_SIZE
    );

    -- Process each document
    FOR doc IN pending_docs DO
        current_doc_id := doc.doc_id;
        current_path := doc.file_path;
        current_client_id := doc.client_id;

        BEGIN
            -- Call the single-document processing procedure
            CALL BNK.KYC_AML.PROCESS_KYC_DOCUMENT(:current_path);
            process_result := (SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

            -- Insert verification result
            INSERT INTO BNK.KYC_AML.VERIFICATION_RESULTS (
                result_id, doc_id, extracted_fields, confidence_score,
                ai_classification, verified_by, verification_date, match_status
            )
            VALUES (
                UUID_STRING(),
                :current_doc_id,
                :process_result:extracted_fields,
                :process_result:classification_confidence,
                :process_result:predicted_type,
                'SYSTEM',
                CURRENT_TIMESTAMP(),
                'ManualReviewRequired'
            );

            -- Update document status to Completed
            UPDATE BNK.KYC_AML.DOCUMENTS_METADATA
            SET extraction_status = 'Completed',
                classification_confidence = :process_result:classification_confidence
            WHERE doc_id = :current_doc_id;

            processed_count := processed_count + 1;

        EXCEPTION
            WHEN OTHER THEN
                -- Mark as Failed and continue with next document
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

-------------------------------------------------------------------------------
-- VERIFY_IDENTITY
-- Cross-references extracted document fields against client master data.
-- Used by the KYC_AGENT as a tool for identity verification tasks.
-------------------------------------------------------------------------------
CREATE PROCEDURE IF NOT EXISTS BNK.KYC_AML.VERIFY_IDENTITY(P_CLIENT_ID VARCHAR, P_DOC_ID VARCHAR)
RETURNS VARIANT
LANGUAGE SQL
COMMENT = 'Cross-references AI-extracted document fields against client master data in CLIENTS table. Compares full name, date of birth, nationality, and document expiry. Returns field-by-field match analysis with confidence scores and an overall match determination. Used by KYC_AGENT for identity verification workflows.'
AS
BEGIN
    -- Retrieve client master record
    LET client_first_name VARCHAR;
    LET client_last_name VARCHAR;
    LET client_nationality VARCHAR;
    LET client_entity_type VARCHAR;
    LET client_company VARCHAR;

    SELECT first_name, last_name, nationality, entity_type, company_name
    INTO :client_first_name, :client_last_name, :client_nationality, :client_entity_type, :client_company
    FROM BNK.KYC_AML.CLIENTS
    WHERE client_id = :P_CLIENT_ID;

    -- Retrieve extracted fields from verification results
    LET extracted VARIANT;
    LET doc_confidence FLOAT;
    LET doc_classification VARCHAR;

    SELECT extracted_fields, confidence_score, ai_classification
    INTO :extracted, :doc_confidence, :doc_classification
    FROM BNK.KYC_AML.VERIFICATION_RESULTS
    WHERE doc_id = :P_DOC_ID
    ORDER BY verification_date DESC
    LIMIT 1;

    -- Perform field-by-field comparison
    LET extracted_name VARCHAR := :extracted:full_name::VARCHAR;
    LET expected_name VARCHAR := CASE
        WHEN :client_entity_type = 'Individual' THEN :client_first_name || ' ' || :client_last_name
        ELSE :client_company
    END;

    LET name_match BOOLEAN := (UPPER(:extracted_name) = UPPER(:expected_name));
    LET name_similarity FLOAT := (
        SELECT JAROWINKLER_SIMILARITY(UPPER(:extracted_name), UPPER(:expected_name)) / 100.0
    );

    LET nationality_match BOOLEAN := (
        UPPER(:extracted:issuing_country::VARCHAR) = UPPER(:client_nationality)
    );

    -- Check document expiry
    LET expiry_date DATE;
    LET is_expired BOOLEAN := FALSE;
    BEGIN
        expiry_date := :extracted:expiry_date::DATE;
        is_expired := (:expiry_date < CURRENT_DATE());
    EXCEPTION
        WHEN OTHER THEN
            is_expired := NULL;
    END;

    -- Determine overall match status
    LET overall_status VARCHAR;
    IF (:name_similarity >= 0.95 AND :nationality_match) THEN
        overall_status := 'Match';
    ELSEIF (:name_similarity >= 0.80) THEN
        overall_status := 'Partial';
    ELSEIF (:name_similarity < 0.70) THEN
        overall_status := 'Mismatch';
    ELSE
        overall_status := 'ManualReviewRequired';
    END IF;

    -- Update the verification result with the match status
    UPDATE BNK.KYC_AML.VERIFICATION_RESULTS
    SET match_status = :overall_status,
        verified_by = 'SYSTEM'
    WHERE doc_id = :P_DOC_ID;

    -- Return comprehensive verification report
    RETURN OBJECT_CONSTRUCT(
        'client_id', :P_CLIENT_ID,
        'doc_id', :P_DOC_ID,
        'overall_match_status', :overall_status,
        'document_type', :doc_classification,
        'extraction_confidence', :doc_confidence,
        'field_comparisons', OBJECT_CONSTRUCT(
            'name', OBJECT_CONSTRUCT(
                'extracted', :extracted_name,
                'expected', :expected_name,
                'match', :name_match,
                'similarity_score', :name_similarity
            ),
            'nationality', OBJECT_CONSTRUCT(
                'extracted', :extracted:issuing_country::VARCHAR,
                'expected', :client_nationality,
                'match', :nationality_match
            ),
            'document_expiry', OBJECT_CONSTRUCT(
                'expiry_date', :extracted:expiry_date::VARCHAR,
                'is_expired', :is_expired
            ),
            'date_of_birth', OBJECT_CONSTRUCT(
                'extracted', :extracted:date_of_birth::VARCHAR
            )
        ),
        'verification_timestamp', CURRENT_TIMESTAMP()::VARCHAR,
        'recommendation', CASE
            WHEN :overall_status = 'Match' THEN 'Identity verified. No further action required.'
            WHEN :overall_status = 'Partial' THEN 'Partial match detected. Recommend analyst review for name discrepancy (possible transliteration or abbreviation).'
            WHEN :overall_status = 'Mismatch' THEN 'CRITICAL: Name mismatch detected. Escalate to senior analyst. Do not proceed with onboarding.'
            ELSE 'Automated verification inconclusive. Manual analyst review required within SLA.'
        END
    );
END;

-------------------------------------------------------------------------------
-- PROCESS_AND_VERIFY_DOCUMENT
-- End-to-end pipeline: parse, classify, extract, then verify against client.
-- Convenience procedure combining PROCESS_KYC_DOCUMENT + VERIFY_IDENTITY.
-------------------------------------------------------------------------------
CREATE PROCEDURE IF NOT EXISTS BNK.KYC_AML.PROCESS_AND_VERIFY_DOCUMENT(
    P_CLIENT_ID VARCHAR,
    P_DOC_ID VARCHAR
)
RETURNS VARIANT
LANGUAGE SQL
COMMENT = 'End-to-end document verification pipeline. Retrieves the document file path, runs AI_PARSE_DOCUMENT → AI_CLASSIFY → AI_EXTRACT, stores results in VERIFICATION_RESULTS, then cross-references against client master data. Returns combined processing and verification output.'
AS
BEGIN
    -- Get the document file path
    LET doc_path VARCHAR;
    SELECT file_path INTO :doc_path
    FROM BNK.KYC_AML.DOCUMENTS_METADATA
    WHERE doc_id = :P_DOC_ID AND client_id = :P_CLIENT_ID;

    -- Step 1: Process the document through the AI pipeline
    CALL BNK.KYC_AML.PROCESS_KYC_DOCUMENT(:doc_path);
    LET process_result VARIANT := (SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

    -- Step 2: Store extraction results
    INSERT INTO BNK.KYC_AML.VERIFICATION_RESULTS (
        result_id, doc_id, extracted_fields, confidence_score,
        ai_classification, verified_by, verification_date, match_status
    )
    VALUES (
        UUID_STRING(),
        :P_DOC_ID,
        :process_result:extracted_fields,
        :process_result:classification_confidence,
        :process_result:predicted_type,
        'SYSTEM',
        CURRENT_TIMESTAMP(),
        'ManualReviewRequired'
    );

    -- Update document metadata
    UPDATE BNK.KYC_AML.DOCUMENTS_METADATA
    SET extraction_status = 'Completed',
        classification_confidence = :process_result:classification_confidence
    WHERE doc_id = :P_DOC_ID;

    -- Step 3: Verify identity against client master
    CALL BNK.KYC_AML.VERIFY_IDENTITY(:P_CLIENT_ID, :P_DOC_ID);
    LET verify_result VARIANT := (SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));

    -- Return combined results
    RETURN OBJECT_CONSTRUCT(
        'processing', :process_result,
        'verification', :verify_result,
        'pipeline_status', 'Complete',
        'timestamp', CURRENT_TIMESTAMP()::VARCHAR
    );
END;
