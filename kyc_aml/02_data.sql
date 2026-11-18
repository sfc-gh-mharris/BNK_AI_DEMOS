/*=============================================================================
  KYC/AML — Data Population
  Database: BNK | Schema: KYC_AML | Warehouse: BNK_WH
  
  Populates all tables with realistic synthetic data.
  - KYC_POLICIES: 25 hand-crafted compliance policies (INSERT VALUES)
  - CLIENTS: 100,000 rows via GENERATOR
  - KYC_CASES: 200,000 rows via GENERATOR
  - DOCUMENTS_METADATA: 500,000 rows via GENERATOR
  - VERIFICATION_RESULTS: 500,000 rows via GENERATOR
  - ALERT_QUEUE: 50,000 rows via GENERATOR
=============================================================================*/

USE DATABASE BNK;
USE SCHEMA KYC_AML;
USE WAREHOUSE BNK_WH;

-------------------------------------------------------------------------------
-- Idempotent reset before loading data
-------------------------------------------------------------------------------
TRUNCATE TABLE IF EXISTS BNK.KYC_AML.ALERT_QUEUE;
TRUNCATE TABLE IF EXISTS BNK.KYC_AML.VERIFICATION_RESULTS;
TRUNCATE TABLE IF EXISTS BNK.KYC_AML.DOCUMENTS_METADATA;
TRUNCATE TABLE IF EXISTS BNK.KYC_AML.KYC_CASES;
TRUNCATE TABLE IF EXISTS BNK.KYC_AML.CLIENTS;
TRUNCATE TABLE IF EXISTS BNK.KYC_AML.KYC_POLICIES;

-------------------------------------------------------------------------------
-- KYC_POLICIES (25 realistic multi-paragraph compliance policies)
-------------------------------------------------------------------------------
INSERT INTO BNK.KYC_AML.KYC_POLICIES (policy_id, title, jurisdiction, category, effective_date, content)
SELECT * FROM VALUES
('POL-CDD-001', 'Standard Customer Due Diligence Requirements', 'Global', 'CDD', '2023-01-15',
 'All new clients must undergo standard Customer Due Diligence (CDD) prior to account opening. This includes: (1) Verification of identity using a government-issued photo identification document (passport, national ID card, or driver''s license). The document must be current and unexpired. (2) Verification of residential address using a utility bill, bank statement, or government correspondence dated within the last three months. (3) Understanding the purpose and intended nature of the business relationship. (4) Collection of source of funds information for anticipated transaction volumes exceeding USD 50,000 per month. The CDD process must be completed within 30 calendar days of the client''s initial application. Incomplete CDD files must be escalated to the Compliance team for review. All documentation must be retained for a minimum of 5 years after relationship termination.'),

('POL-CDD-002', 'Corporate Client Due Diligence Procedures', 'Global', 'CDD', '2023-03-01',
 'Corporate clients require enhanced identification beyond individual CDD. Required documentation includes: (1) Certificate of Incorporation or equivalent registration document. (2) Memorandum and Articles of Association (or equivalent constitutional documents). (3) Register of Directors with full names, dates of birth, and nationalities. (4) Register of Shareholders identifying all persons holding 25% or more of voting rights or ownership interest. (5) Latest audited financial statements (within 18 months). (6) Board resolution authorizing the account opening and designating authorized signatories. (7) Proof of registered office address. For complex corporate structures with multiple layers, a full organizational chart must be obtained showing all intermediate holding companies up to the Ultimate Beneficial Owner (UBO). Each entity in the chain must be identified with its jurisdiction of incorporation and ownership percentage.'),

('POL-EDD-001', 'Enhanced Due Diligence for High-Risk Clients', 'Global', 'EDD', '2023-02-01',
 'Enhanced Due Diligence (EDD) is mandatory for clients classified as High risk or above. EDD measures supplement standard CDD and include: (1) Senior management approval for establishing or continuing the business relationship — minimum VP-level sign-off required. (2) Enhanced source of wealth verification including documentation of the origin of the client''s total net worth (property valuations, business ownership records, inheritance documentation). (3) Enhanced source of funds verification with corroborating documentation for all incoming transfers exceeding USD 25,000. (4) Increased frequency of periodic reviews — minimum annually for High-risk, semi-annually for PEP/Sanctioned classifications. (5) Enhanced transaction monitoring with lower thresholds — automated alerts at 50% of standard thresholds. (6) Documented risk assessment narrative prepared by the assigned analyst explaining the rationale for maintaining the relationship despite elevated risk. All EDD files must be reviewed by the MLRO or Deputy MLRO within 14 days of completion.'),

('POL-EDD-002', 'Enhanced Due Diligence — Trigger Events', 'Global', 'EDD', '2023-04-15',
 'Trigger-based EDD reviews must be initiated within 48 hours of any of the following events: (1) Adverse media reports naming the client in connection with financial crime, corruption, or sanctions evasion. (2) Material change in client risk profile — e.g., appointment to a politically exposed position, change of nationality to a high-risk jurisdiction. (3) Transaction patterns inconsistent with the stated business profile (volume exceeding 3x the documented expected activity without explanation). (4) Receipt of a law enforcement inquiry, production order, or suspicious activity report filed by another institution naming the client. (5) Sanctions list update resulting in a potential match against the client or their known associates. (6) Failure to provide requested CDD refresh documentation within the prescribed SLA. Upon trigger identification, the assigned analyst must document the trigger event, escalate to their line manager, and initiate the EDD workflow within the KYC Case Management System. Cases not resolved within 30 days of the trigger event must be escalated to the MLRO.'),

('POL-PEP-001', 'Politically Exposed Persons — Identification and Screening', 'Global', 'PEP', '2023-01-20',
 'A Politically Exposed Person (PEP) is defined as an individual who holds or has held (within the last 12 months) a prominent public function. This includes: (1) Heads of State or Government, senior politicians, senior judicial officials. (2) Senior executives of state-owned enterprises and sovereign wealth funds. (3) High-ranking military officials (General/Admiral and above). (4) Members of governing bodies of political parties. (5) Senior officials of international organizations (Director-level and above). Family members and close associates of PEPs must be treated as PEPs themselves. Family members include: spouse/partner, children and their spouses, parents. Close associates include: known business partners, persons with joint beneficial ownership of legal entities, and any individual known to have a close social relationship. All clients must be screened against recognized PEP databases at onboarding and at minimum quarterly thereafter. Any new PEP matches must be escalated within 24 hours.'),

('POL-PEP-002', 'PEP Risk Management and Relationship Approval', 'UK', 'PEP', '2023-06-01',
 'Under the UK Money Laundering Regulations 2017 (as amended), PEP relationships require: (1) Approval from Senior Management (defined as a Board-level individual or their designated delegate at SVP level or above) before establishing or continuing the relationship. (2) Reasonable measures to establish the source of wealth and source of funds. Documentation must go beyond self-declaration — independent verification through public records, tax returns, or certified valuations is required. (3) Enhanced ongoing monitoring of the relationship — quarterly reviews of transaction activity against the documented profile. (4) Annual re-certification of PEP status by the Compliance team. (5) Domestic PEPs (UK-based) may be treated as standard CDD if the relationship presents no other high-risk indicators after a documented 12-month assessment period. This de-escalation requires MLRO approval. (6) All PEP decisions (accept, decline, exit) must be documented with full rationale and retained indefinitely. The FCA expects firms to apply a proportionate, risk-based approach — blanket de-risking of PEP categories is not acceptable.'),

('POL-SAN-001', 'Sanctions Screening — Procedures and Obligations', 'Global', 'Sanctions', '2023-01-10',
 'All clients, transactions, and counterparties must be screened against applicable sanctions lists. Mandatory lists include: (1) UN Security Council Consolidated List. (2) OFAC SDN List and Sectoral Sanctions (US exposure). (3) HM Treasury Consolidated List (UK exposure). (4) EU Consolidated Financial Sanctions List (EU exposure). (5) Relevant local sanctions lists for jurisdictions of operation. Screening frequency: (a) Real-time for all wire transfers and payment instructions. (b) At client onboarding and every CDD refresh event. (c) Within 24 hours of any sanctions list update. Potential matches (''hits'') must be reviewed by a trained analyst within 4 hours for real-time transaction screening and within 24 hours for batch screening. True matches require immediate action: freeze of assets, blocking of transactions, and reporting to the relevant national authority within the legally mandated timeframe (24 hours UK, 10 days US). False positives must be documented with the rationale for clearance.'),

('POL-SAN-002', 'Sanctions — Jurisdictional Complexity and Conflict of Laws', 'US', 'Sanctions', '2023-05-01',
 'US sanctions administered by OFAC apply to all US persons, entities organized under US law, and any transaction touching the US financial system (including USD-denominated transactions cleared through US correspondent banks). Secondary sanctions may apply to non-US persons engaging in significant transactions with sanctioned parties. Key compliance requirements: (1) All USD payments must be screened against the OFAC SDN and Consolidated Sanctions Lists before execution. (2) Entities owned 50% or more (individually or in aggregate) by a sanctioned person are themselves blocked — the ''50 Percent Rule'' requires ownership chain analysis. (3) OFAC General Licenses must be reviewed to determine if specific authorizations apply before blocking. (4) Voluntary Self-Disclosure (VSD) to OFAC is strongly encouraged for apparent violations discovered internally — VSD is a significant mitigating factor in enforcement actions. (5) Specific license applications must be coordinated through the central Sanctions Compliance team — business units must not correspond directly with OFAC.'),

('POL-BO-001', 'Beneficial Ownership — Identification Requirements', 'Global', 'BeneficialOwnership', '2023-02-15',
 'Beneficial Ownership identification is required for all legal entity clients. A Beneficial Owner is defined as any natural person who: (1) Directly or indirectly owns or controls 25% or more of the shares or voting rights of the entity. (2) Otherwise exercises control over the management of the entity (e.g., through shareholder agreements, rights to appoint/remove directors, or veto rights). (3) Is the beneficiary of 25% or more of the assets of a trust, foundation, or similar arrangement. Where no individual meets the 25% threshold, the senior managing official (CEO or equivalent) must be identified as the Beneficial Owner. For complex structures: (a) Ownership must be traced through all intermediate entities to the ultimate natural person(s). (b) Nominee shareholders and bearer share arrangements require identification of the underlying beneficiary. (c) Trusts require identification of settlor, trustees, beneficiaries, and any protector. All Beneficial Ownership declarations must be refreshed at minimum annually and upon any trigger event suggesting a change in ownership structure.'),

('POL-BO-002', 'Beneficial Ownership — EU 4th/5th AMLD Requirements', 'EU', 'BeneficialOwnership', '2023-07-01',
 'Under the EU Anti-Money Laundering Directives (4th AMLD as amended by 5th AMLD): (1) The beneficial ownership threshold is 25% for companies and 25% for trusts/similar legal arrangements. (2) Member States must maintain central registers of beneficial ownership information — firms should cross-reference client declarations against these registers where accessible. (3) Discrepancies between client-provided beneficial ownership information and public register entries must be reported to the relevant Financial Intelligence Unit (FIU). (4) Enhanced due diligence applies to all relationships involving complex multi-jurisdictional ownership structures with entities in jurisdictions identified by the European Commission as having strategic deficiencies in their AML/CFT regimes. (5) Corporate clients must provide a certified copy of their entry in the national beneficial ownership register. (6) For trusts: the entire class of beneficiaries must be identified where individual beneficiaries are not yet determined (e.g., ''my grandchildren''). (7) Bearer shares have been effectively abolished — any legacy bearer share arrangements must be immobilized or converted.'),

('POL-CDD-003', 'Ongoing Monitoring — Transaction Surveillance', 'Global', 'OngoingMonitoring', '2023-03-15',
 'Ongoing monitoring of client relationships is a continuous obligation, not limited to periodic review events. Requirements include: (1) Automated transaction monitoring calibrated to the client''s documented risk profile, business type, and expected transaction patterns. Monitoring rules must cover: volume/value thresholds, geographic risk (high-risk jurisdiction flows), structuring patterns, and rapid movement of funds. (2) Manual review of all alerts generated by the monitoring system within SLA (24 hours for High/Critical, 72 hours for Medium, 5 business days for Low). (3) Maintenance of up-to-date client profiles — any material deviation from expected behavior must be investigated and documented. (4) Periodic review of the business relationship at intervals determined by risk rating: Low risk — every 5 years, Medium risk — every 3 years, High risk — annually, PEP — annually. (5) Adverse media monitoring — automated screening of news sources at minimum weekly. (6) Sanctions re-screening within 24 hours of list updates.'),

('POL-CDD-004', 'Non-Face-to-Face Client Verification', 'UK', 'CDD', '2023-08-01',
 'For clients onboarded through non-face-to-face channels (digital onboarding, correspondent relationships), additional verification measures are required: (1) Electronic identity verification using at least two independent electronic data sources (credit reference agencies, electoral roll, government databases). (2) Liveness detection for biometric verification — static photograph submission is not sufficient. (3) Document verification using AI-assisted tools (AI_PARSE_DOCUMENT for OCR, AI_CLASSIFY for document type confirmation, AI_EXTRACT for field extraction) with a minimum confidence threshold of 0.85 for automated pass. Documents scoring below 0.85 must be manually reviewed. (4) First transaction must originate from an account in the client''s own name at a regulated financial institution. (5) Video verification call may be required for High-risk clients or where document verification produces inconclusive results. (6) IP geolocation and device fingerprinting data must be captured and compared against stated residence. All non-face-to-face onboarding decisions must be documented with the specific verification methods applied and their outcomes.'),

('POL-EDD-003', 'Enhanced Due Diligence — Correspondent Banking', 'US', 'EDD', '2023-04-01',
 'Correspondent banking relationships (including nested correspondent relationships) are inherently high-risk and require the following EDD measures per BSA/AML requirements and FinCEN guidance: (1) Comprehensive assessment of the respondent institution''s AML/CFT controls — obtain and review their AML policy, independent audit reports, and regulatory examination findings. (2) Determination of whether the respondent institution permits nested/downstream correspondent access — if yes, identify material downstream institutions. (3) No correspondent accounts shall be established or maintained for shell banks (entities with no physical presence in any country). (4) Senior management approval (C-suite or designated delegate) for all new correspondent relationships. (5) Annual review of all correspondent relationships including transaction flow analysis, jurisdiction risk assessment, and evaluation of the respondent''s ongoing compliance posture. (6) SWIFT KYC Registry data should be obtained where available. (7) Payable-through accounts require all measures applicable to the correspondent''s own customers.'),

('POL-SAN-003', 'Sanctions — APAC Regional Requirements', 'APAC', 'Sanctions', '2023-09-01',
 'APAC operations must comply with the following jurisdiction-specific sanctions requirements in addition to Global policy POL-SAN-001: (1) Japan (JFSA): Screen against the Ministry of Finance asset freeze list. Reporting to JAFIC within 3 business days of a confirmed match. (2) Singapore (MAS): Comply with MAS Notice 626 — screen against UNSC lists as gazetted under the Monetary Authority of Singapore (Sanctions and Freezing of Assets of Persons) Regulations. STR filing to STRO within 15 days. (3) Hong Kong (HKMA): Screen against the UN Sanctions (Afghanistan) Regulation and Weapons of Mass Destruction (Control of Provision of Services) Ordinance lists. STR to JFIU. (4) Australia (AUSTRAC): Screen against the DFAT Consolidated List. Reporting to AUSTRAC within 24 hours. (5) All APAC entities must also screen against the FATF high-risk jurisdictions list (''black list'' and ''grey list'') for enhanced geographic risk factors. (6) Cross-border payments involving DPRK, Iran, or Myanmar require enhanced review regardless of counterparty sanctions status.'),

('POL-OM-001', 'Ongoing Monitoring — Adverse Media Screening', 'Global', 'OngoingMonitoring', '2023-05-15',
 'Adverse media screening is a critical component of ongoing due diligence. Requirements: (1) All clients must be screened against adverse media sources at minimum weekly using automated tools. (2) Screening must cover: financial crime (money laundering, fraud, bribery, corruption, tax evasion), sanctions violations, terrorism financing, organized crime, environmental crime, human trafficking, and proliferation financing. (3) Sources must include: major international news agencies, local language media in the client''s country of operation, regulatory enforcement databases, court records, and watchlist databases. (4) Screening must cover the client, their known Beneficial Owners, directors, and (for PEPs) close associates. (5) Alert disposition: TRUE adverse media hit — escalate to EDD trigger event within 48 hours. INCONCLUSIVE — assign for analyst review within 5 days. FALSE POSITIVE — document rationale and suppress for future screening cycles. (6) All adverse media decisions must be documented and retained. (7) Language coverage must be appropriate to the client''s jurisdictions — English-only screening is insufficient for non-English-speaking markets.'),

('POL-CDD-005', 'Source of Funds and Source of Wealth Documentation', 'EU', 'CDD', '2023-06-15',
 'Under EU AMLD requirements, Source of Funds (SoF) and Source of Wealth (SoW) must be documented for all clients. SoF refers to the origin of funds for specific transactions; SoW refers to the origin of the client''s entire net worth. Minimum requirements: (1) Standard CDD clients: SoF declaration for the anticipated business activity (salary, business income, investment returns, inheritance). Self-declaration acceptable for Low-risk clients. (2) High-risk clients: Independent verification of SoF — e.g., employment verification letter, business accounts, tax returns. (3) PEPs: Both SoF and SoW must be independently verified. Acceptable evidence includes: property valuations, business ownership/dividend records, inheritance documentation, investment portfolio statements, historical tax filings. (4) Red flags requiring escalation: stated income inconsistent with transaction volumes; cash-intensive business without corresponding tax records; recent acquisition of significant assets without documented income history; declared inheritance without probate/succession documentation. (5) SoF/SoW documentation must be refreshed at every periodic review or upon material change in transaction patterns.'),

('POL-EDD-004', 'Enhanced Due Diligence — High-Risk Jurisdictions', 'Global', 'EDD', '2023-07-15',
 'Clients domiciled in, incorporated in, or conducting material business through high-risk jurisdictions require mandatory EDD. High-risk jurisdictions are determined by: (1) FATF ''Black List'' (call-for-action jurisdictions) — highest risk: business relationships only with explicit MLRO approval and a compelling commercial rationale. (2) FATF ''Grey List'' (under increased monitoring) — elevated risk: automatic EDD classification. (3) Internal risk assessment: jurisdictions with known deficiencies in AML/CFT supervision, high corruption indices (Transparency International CPI below 40), or known typologies for trade-based money laundering. (4) EU High-Risk Third Countries list as defined by EU Delegated Regulation. EDD measures for high-risk jurisdictions include: enhanced transaction monitoring with lowered thresholds (25% of standard); quarterly relationship reviews; senior management approval for continuation; documented rationale for maintaining the relationship; additional source of funds verification for all material transactions. Jurisdictions on the FATF Black List are subject to countermeasures — no new relationships without Board-level approval; existing relationships must be reviewed within 30 days of listing.'),

('POL-OM-002', 'Periodic Review — Risk-Based Scheduling', 'Global', 'OngoingMonitoring', '2023-04-01',
 'KYC periodic reviews must be conducted at intervals commensurate with client risk. Schedule: (1) Low Risk: every 5 years from onboarding or last review. (2) Medium Risk: every 3 years. (3) High Risk: annually. (4) PEP: annually (6-monthly if domestic PEP in a sensitive role). (5) Sanctioned: continuous monitoring — formal review quarterly. Review scope at minimum: (a) Confirm client identification details remain current. (b) Refresh beneficial ownership information. (c) Review transaction activity against documented profile — investigate material deviations. (d) Re-screen against sanctions, PEP, and adverse media databases. (e) Reassess risk rating considering any changes since last review. (f) Confirm source of funds/wealth remains consistent with observed activity. If the review identifies material changes or concerns: (i) Update risk rating immediately. (ii) If risk increases, initiate EDD workflow. (iii) If unresolvable concerns, escalate to MLRO for exit consideration. Reviews must be completed within the SLA: 30 days for Low/Medium priority, 14 days for High, 7 days for Critical. Overdue reviews must be escalated weekly to senior management.'),

('POL-CDD-006', 'Reliance on Third Parties for CDD', 'UK', 'CDD', '2023-09-15',
 'Under Regulation 39 of the UK MLRs 2017, the firm may rely on third parties to perform elements of CDD where: (1) The third party is a regulated firm within the UK, EU/EEA, or an equivalent jurisdiction. (2) A written agreement exists specifying the CDD elements delegated and the obligation to make copies of documentation available upon request. (3) The third party consents to forward copies of identification documents and any other relevant CDD documentation immediately upon request. (4) The firm has satisfied itself that the third party applies CDD standards at least equivalent to its own. (5) Ultimate responsibility for CDD compliance remains with the firm — reliance does not transfer liability. Limitations: (a) Reliance is NOT permitted for ongoing monitoring — this must always be performed in-house. (b) Reliance is NOT permitted where the client is in a high-risk jurisdiction or the relationship is otherwise subject to EDD. (c) Reliance on introducers from non-equivalent jurisdictions is prohibited. (d) The firm must maintain records of all third parties relied upon and review the adequacy of their CDD standards annually. (e) FCA may issue directions prohibiting reliance on specific jurisdictions or categories of institution.'),

('POL-PEP-003', 'De-escalation of Former PEP Status', 'EU', 'PEP', '2023-10-01',
 'Under EU AMLD guidance, former PEPs may be de-escalated from PEP-level EDD after a risk-based assessment. Requirements: (1) A minimum period of 12 months must have elapsed since the individual left public office. (2) A documented risk assessment must conclude that the individual no longer poses elevated ML/TF risk. Factors to consider: (a) level of (in)formal influence retained post-office; (b) jurisdiction risk (corruption index, rule of law); (c) nature of the former public function; (d) age and health of the individual; (e) whether any investigations or proceedings are pending. (3) De-escalation decision must be approved by the MLRO or equivalent senior compliance officer. (4) Even after de-escalation, the client must remain on enhanced adverse media monitoring for an additional 12 months. (5) De-escalation is reversible — if new information emerges suggesting continuing risk (e.g., appointment to a board of a state-owned enterprise, new corruption allegations), PEP classification must be immediately reinstated. (6) De-escalation decisions must be documented with full rationale and reviewed annually for the first 3 years post-de-escalation.'),

('POL-SAN-004', 'Secondary and Sectoral Sanctions Compliance', 'US', 'Sanctions', '2023-08-15',
 'Beyond primary OFAC SDN list screening, the following sectoral and secondary sanctions programs require specific compliance measures: (1) Sectoral Sanctions Identifications (SSI) List: Prohibits specific transaction types (debt >14/30/90 day tenor, equity, energy sector transactions) with listed entities rather than a full asset freeze. Screening must identify SSI-listed counterparties and apply the relevant transaction restrictions. (2) Non-SDN Menu-Based Sanctions (NS-MBS): Apply activity-specific restrictions — review the specific restrictions code for each listed party. (3) Correspondent Account and Payable-Through Account Sanctions (CAPTA): Certain foreign financial institutions are subject to specific correspondent account restrictions. (4) Secondary sanctions: Non-US persons may face sanctions exposure for facilitating significant transactions for SDN-listed parties, the Government of Iran, or other designated entities. While not legally binding on non-US persons, violation risks loss of access to the US financial system. (5) All sanctions screening must account for transliteration variants, aliases, date of birth variations, and the OFAC 50 Percent Rule. Fuzzy matching thresholds should be calibrated jurisdiction by jurisdiction.'),

('POL-BO-003', 'Trust and Foundation Beneficial Ownership', 'UK', 'BeneficialOwnership', '2023-11-01',
 'For trusts and foundations, beneficial ownership identification must cover all parties in the governance structure: (1) Settlor(s)/Founder(s): The natural person(s) who established the trust/foundation and provided the initial assets. (2) Trustee(s)/Board Members: All individuals and corporate trustees/directors — for corporate trustees, identify the natural persons controlling the corporate trustee. (3) Protector(s)/Guardian(s): Any person with power to appoint/remove trustees, veto distributions, or otherwise influence trust administration. (4) Beneficiaries: (a) Named beneficiaries — identify all natural persons. (b) Discretionary beneficiaries — identify the class (e.g., ''children of the settlor'') and any individuals who have received distributions in the past 12 months. (c) Default beneficiaries — those entitled on trust termination. (5) Any other natural person exercising ultimate effective control over the trust (e.g., investment advisor with discretionary mandate, letter of wishes). For trusts with underlying corporate structures, the trust and corporate BO identification requirements compound — all layers must be identified. UK trusts with tax consequences must be registered on the TRS (Trust Registration Service); cross-reference client declarations against TRS where possible.'),

('POL-OM-003', 'Suspicious Activity Reporting Obligations', 'UK', 'OngoingMonitoring', '2023-03-01',
 'Under Section 330 of the Proceeds of Crime Act 2002 and Section 21A of the Terrorism Act 2000, the firm has a legal obligation to report knowledge or suspicion of money laundering or terrorist financing. Key requirements: (1) Any employee who knows or suspects (or has reasonable grounds for suspecting) that a person is engaged in money laundering must make an internal report to the nominated officer (MLRO) as soon as practicable. (2) The MLRO must determine whether the internal report gives rise to knowledge or suspicion requiring an external SAR to the NCA. This determination must be made promptly — within 5 business days for non-urgent matters, same day for urgent cases. (3) Consent regime: Where a SAR is filed and the firm wishes to continue with a transaction, ''appropriate consent'' must be obtained from the NCA (Defence Against Money Laundering — DAML). The moratorium period is 7 working days from NCA acknowledgment (extendable by court order for a further 31 days). (4) Tipping off: It is a criminal offence to disclose that a SAR has been made or that an investigation is being conducted if that disclosure is likely to prejudice the investigation. (5) All internal reports, MLRO decisions, and external SARs must be retained in a secure, restricted-access system for a minimum of 5 years.'),

('POL-CDD-007', 'Document Acceptance Standards', 'Global', 'CDD', '2023-05-01',
 'The following standards apply to all identity and address verification documents accepted for CDD purposes: (1) Identity documents: Must be government-issued, bear a photograph, full legal name, date of birth, and a unique document number. Acceptable: passport, national identity card, driver''s license (where it meets photo and DOB requirements). Not acceptable: student cards, employer IDs, library cards. (2) Documents must be current (unexpired) at the time of verification. For periodic reviews, documents expiring within 90 days should trigger a refresh request. (3) Address documents: Must be dated within the last 3 months (6 months for annual statements). Acceptable: utility bills (gas, electric, water — not mobile phone), bank/building society statements, government tax correspondence, electoral roll confirmation. (4) Certified copies: Where original documents cannot be sighted, certified copies are acceptable if certified by a regulated professional (lawyer, notary, bank officer) with their full name, qualification, and date of certification. (5) Electronic documents: PDF downloads from verified online banking/utility portals are acceptable. Screenshots are NOT acceptable. (6) Translation: Non-English documents are acceptable but must be accompanied by a certified translation for jurisdictions where the firm does not maintain language capability.'),

('POL-EDD-005', 'Enhanced Due Diligence — Virtual Asset Service Providers', 'EU', 'EDD', '2024-01-15',
 'Clients identified as Virtual Asset Service Providers (VASPs) or entities with material cryptocurrency/digital asset activity require the following EDD measures in line with EU AMLD5 and the Transfer of Funds Regulation (TFR): (1) Verify the VASP is registered/licensed in its jurisdiction of operation — obtain and retain proof of registration. (2) Assess the VASP''s own AML/CFT controls — request and review their AML policy, transaction monitoring capabilities, and travel rule compliance. (3) Determine whether the VASP supports privacy coins, mixing services, or unhosted wallet transfers without counterparty identification — these present elevated risk factors. (4) Enhanced transaction monitoring for fiat-to-crypto and crypto-to-fiat flows with the client. (5) Source of funds verification for significant incoming transfers from the VASP — require transaction hash/blockchain evidence where applicable. (6) Quarterly review of the VASP''s regulatory standing and any enforcement actions. (7) Risk appetite: the firm does not onboard VASPs operating exclusively from jurisdictions without VASP registration requirements (FATF Recommendation 15 non-compliant). Existing relationships must be reviewed and risk-assessed within 90 days of this policy''s effective date.'),

('POL-OM-004', 'Transaction Monitoring — Calibration and Governance', 'US', 'OngoingMonitoring', '2023-11-15',
 'Transaction monitoring system calibration must follow FinCEN and OCC guidance on effective BSA/AML programs: (1) Scenarios must be risk-based — calibrated to the institution''s specific risk profile including customer base, products/services, geographic footprint. (2) Thresholds must be set to achieve an alert-to-SAR conversion rate between 10-30%. Rates below 5% suggest thresholds are too tight (excessive false positives); rates above 50% suggest thresholds may be too loose (potential for missed activity). (3) Model validation: All monitoring scenarios must be independently validated at minimum every 12 months, or upon material change. Validation must include above-the-line (effectiveness at detecting known typologies) and below-the-line (review of activity that did NOT generate alerts) testing. (4) Governance: Changes to monitoring thresholds, addition/retirement of scenarios, and model risk acceptance require approval by the BSA/AML Governance Committee. (5) Tuning proposals must be documented with statistical analysis demonstrating the impact on alert volumes, false positive rates, and detection effectiveness. (6) Gap analysis: Emerging typologies (e.g., funnel accounts, mule networks, trade-based ML) must be assessed annually for scenario coverage.'),

('POL-SAN-005', 'Sanctions — Screening System Requirements and Standards', 'Global', 'Sanctions', '2024-02-01',
 'All sanctions screening systems must meet the following minimum technical and operational standards: (1) List coverage: All mandatory lists per POL-SAN-001 must be loaded within 24 hours of publication by the issuing authority. (2) Matching algorithm: Must support phonetic matching (Soundex, Metaphone), transliteration variants (Cyrillic/Arabic/Chinese to Latin), abbreviated names, reversed name order, and date of birth tolerance (±1 year for transcription errors). (3) Fuzzy matching threshold: Minimum 85% for automated escalation. Matches between 70-85% must be routed to enhanced review. Below 70% may be auto-dismissed. (4) Name screening must account for compound names, hyphenated names, particles (de, von, al-, bin), titles, and known aliases. (5) Performance SLA: Real-time transaction screening must return a result within 500ms per payment. Batch screening must complete overnight processing within the maintenance window. (6) Audit trail: Complete logging of all screening events, match results, analyst dispositions, and rationale — retained for 7 years. (7) System access: Restricted to authorized compliance personnel. Segregation of duties between analysts (dispositioners) and system administrators (threshold management). (8) Testing: Annual regression testing with a known ''true positive'' dataset to verify detection rates have not degraded after list updates or system changes.')

;

-------------------------------------------------------------------------------
-- CLIENTS (99,995 synthetic + 5 hero showcase clients = 100,000 rows)
-------------------------------------------------------------------------------
INSERT INTO BNK.KYC_AML.CLIENTS (
    client_id, entity_type, first_name, last_name, date_of_birth,
    company_name, nationality, country_of_residence, risk_rating,
    onboarding_date, relationship_manager, status
)
WITH pools AS (
    SELECT
        ARRAY_CONSTRUCT(
            'James','Mary','Robert','Patricia','Michael','Jennifer','William','Elizabeth','David','Sarah',
            'Oliver','Amelia','George','Charlotte','Harry','Sophie','Thomas','Emily','Jack','Isabella',
            'Takeshi','Yuki','Hiroshi','Sakura','Kenji','Aiko','Wei','Mei','Jin','Hana',
            'Lukas','Emma','Maximilian','Sofia','Felix','Anna','Leon','Marie','Paul','Clara',
            'Ahmed','Fatima','Mohammed','Aisha','Omar','Layla','Hassan','Noor','Ali','Zara'
        ) AS first_names,
        ARRAY_CONSTRUCT(
            'Smith','Johnson','Williams','Brown','Jones','Davis','Miller','Wilson','Taylor','Anderson',
            'Thompson','Wright','Clarke','Roberts','Mitchell','Campbell','Stewart','Murray','Walker','Hughes',
            'Tanaka','Yamamoto','Sato','Suzuki','Watanabe','Chen','Wang','Liu','Kim','Park',
            'Mueller','Schmidt','Schneider','Fischer','Weber','Rossi','Bianchi','Dubois','Moreau','Martin',
            'Al-Rashid','Hassan','Ibrahim','Patel','Sharma','Khan','Singh','Nguyen','Tran','Lee'
        ) AS last_names,
        ARRAY_CONSTRUCT(
            'USA','USA','USA','CAN','GBR','GBR','IRL',
            'DEU','FRA','ITA','ESP','NLD','CHE',
            'JPN','SGP','HKG','AUS','IND','ARE','KOR'
        ) AS countries,
        ARRAY_CONSTRUCT(
            'Sarah Mitchell','James Crawford','Emma Richardson','Thomas Blackwell','Rachel Kim',
            'David Nakamura','Maria Santos','Alexander Petrov','Hannah O''Brien','Marcus Williams',
            'Yuki Tanaka','Robert Chen','Sophia Mueller','Ahmed Al-Fayed','Catherine Dubois'
        ) AS rm_names,
        ARRAY_CONSTRUCT(
            'Meridian Capital Holdings','Pacific Rim Trading Corp','Northern Star Investments','Golden Gate Ventures','Atlas Global Partners',
            'Pinnacle Financial Group','Sapphire Asset Management','Falcon Industries Ltd','Sterling Commerce International','Eastbridge Securities',
            'Nexus Technology Solutions','Sovereign Wealth Advisors','Crimson Bay Shipping','Titanium Resources Corp','Emerald Coast Properties',
            'Summit Peak Capital','Horizon Maritime Services','Quantum Trading LLC','Phoenix Global Logistics','Cobalt Energy Partners'
        ) AS company_names
),
gen AS (
    SELECT
        UUID_STRING() AS client_id,
        UNIFORM(1, 100, RANDOM()) AS r_entity,
        UNIFORM(0, 49, RANDOM()) AS idx_fn,
        UNIFORM(0, 49, RANDOM()) AS idx_ln,
        UNIFORM(0, 19, RANDOM()) AS idx_comp,
        UNIFORM(1, 999, RANDOM()) AS comp_num,
        UNIFORM(0, 19, RANDOM()) AS idx_nat,
        UNIFORM(0, 19, RANDOM()) AS idx_res,
        UNIFORM(0, 14, RANDOM()) AS idx_rm,
        UNIFORM(1, 100, RANDOM()) AS r_risk,
        UNIFORM(1, 100, RANDOM()) AS r_status,
        UNIFORM(9125, 27375, RANDOM()) AS dob_days_ago,
        UNIFORM(1, 3650, RANDOM()) AS onboard_days_ago
    FROM TABLE(GENERATOR(ROWCOUNT => 99995))
)
SELECT
    g.client_id,
    IFF(g.r_entity <= 70, 'Individual', 'Corporate') AS entity_type,
    IFF(g.r_entity <= 70, p.first_names[g.idx_fn]::VARCHAR, NULL) AS first_name,
    IFF(g.r_entity <= 70, p.last_names[g.idx_ln]::VARCHAR, NULL) AS last_name,
    IFF(g.r_entity <= 70, DATEADD('day', -g.dob_days_ago, CURRENT_DATE()), NULL) AS date_of_birth,
    IFF(g.r_entity > 70, p.company_names[g.idx_comp]::VARCHAR || ' ' || g.comp_num::VARCHAR, NULL) AS company_name,
    p.countries[g.idx_nat]::VARCHAR AS nationality,
    p.countries[g.idx_res]::VARCHAR AS country_of_residence,
    CASE
        WHEN g.r_risk <= 60 THEN 'Low'
        WHEN g.r_risk <= 85 THEN 'Medium'
        WHEN g.r_risk <= 95 THEN 'High'
        WHEN g.r_risk <= 99 THEN 'PEP'
        ELSE 'Sanctioned'
    END AS risk_rating,
    DATEADD('day', -g.onboard_days_ago, CURRENT_DATE()) AS onboarding_date,
    p.rm_names[g.idx_rm]::VARCHAR AS relationship_manager,
    CASE
        WHEN g.r_status <= 80 THEN 'Active'
        WHEN g.r_status <= 90 THEN 'UnderReview'
        WHEN g.r_status <= 97 THEN 'Restricted'
        ELSE 'Exited'
    END AS status
FROM gen g
CROSS JOIN pools p;

-- Insert 5 deterministic showcase clients matched to staged sample PDFs
INSERT INTO BNK.KYC_AML.CLIENTS (
    client_id, entity_type, first_name, last_name, date_of_birth,
    company_name, nationality, country_of_residence, risk_rating,
    onboarding_date, relationship_manager, status
)
SELECT
    column1, column2, column3, column4, TRY_TO_DATE(column5),
    column6, column7, column8, column9,
    DATEADD('day', column10, CURRENT_DATE()), column11, column12
FROM VALUES
    ('CL-DEMO-001', 'Individual', 'Oliver', 'Clarke', '1995-01-17', NULL, 'GBR', 'GBR', 'PEP', -420, 'Emma Richardson', 'UnderReview'),
    ('CL-DEMO-002', 'Individual', 'Jen', 'Muller', '1983-09-18', NULL, 'GBR', 'GBR', 'High', -380, 'Emma Richardson', 'UnderReview'),
    ('CL-DEMO-003', 'Individual', 'Marcus', 'Sterling', '1974-11-03', NULL, 'USA', 'USA', 'High', -30, 'James Crawford', 'Restricted'),
    ('CL-DEMO-004', 'Corporate', NULL, NULL, NULL, 'Nexus Technology Solutions GmbH', 'DEU', 'DEU', 'High', -540, 'Sophia Mueller', 'UnderReview'),
    ('CL-DEMO-005', 'Individual', 'James', 'Williams', '1966-02-25', NULL, 'DEU', 'JPN', 'Medium', -730, 'David Nakamura', 'Active');

-------------------------------------------------------------------------------
-- KYC_CASES (199,995 synthetic + 5 hero showcase cases = 200,000 rows)
-------------------------------------------------------------------------------
INSERT INTO BNK.KYC_AML.KYC_CASES (
    case_id, client_id, case_type, status, priority,
    assigned_analyst, opened_date, due_date, closed_date, notes
)
WITH numbered_clients AS (
    SELECT client_id, ROW_NUMBER() OVER (ORDER BY client_id) AS rn
    FROM BNK.KYC_AML.CLIENTS
    WHERE client_id NOT LIKE 'CL-DEMO-%'
),
pools AS (
    SELECT ARRAY_CONSTRUCT(
        'Lisa Park','Daniel Foster','Rebecca Okonkwo','Stuart MacLeod','Priya Sharma',
        'Marcus Thompson','Anna Kowalski','Yusuf Demir','Catherine Leung','Jonathan Price',
        'Ingrid Bergstrom','Rajesh Patel','Gabrielle Martin','Kenji Watanabe','Olivia Chen',
        'Samuel Edwards','Fatima Zahra','Henrik Johansson','Maria Gonzalez','Alistair Campbell'
    ) AS analysts
),
gen AS (
    SELECT
        SEQ4() AS seq,
        UUID_STRING() AS case_id,
        UNIFORM(1, 4, RANDOM()) AS r_type,
        UNIFORM(1, 6, RANDOM()) AS r_status,
        UNIFORM(1, 4, RANDOM()) AS r_priority,
        UNIFORM(0, 19, RANDOM()) AS idx_analyst,
        UNIFORM(1, 730, RANDOM()) AS opened_days_ago,
        UNIFORM(7, 60, RANDOM()) AS sla_days,
        UNIFORM(1, 30, RANDOM()) AS close_days,
        UNIFORM(1, 5, RANDOM()) AS r_note
    FROM TABLE(GENERATOR(ROWCOUNT => 199995))
)
SELECT
    g.case_id,
    c.client_id,
    CASE g.r_type
        WHEN 1 THEN 'NewClient'
        WHEN 2 THEN 'PeriodicReview'
        WHEN 3 THEN 'TriggerEvent'
        ELSE 'EnhancedDueDiligence'
    END AS case_type,
    CASE g.r_status
        WHEN 1 THEN 'Open'
        WHEN 2 THEN 'InReview'
        WHEN 3 THEN 'PendingDocuments'
        WHEN 4 THEN 'Approved'
        WHEN 5 THEN 'Rejected'
        ELSE 'Escalated'
    END AS status,
    CASE g.r_priority
        WHEN 1 THEN 'Low'
        WHEN 2 THEN 'Medium'
        WHEN 3 THEN 'High'
        ELSE 'Critical'
    END AS priority,
    p.analysts[g.idx_analyst]::VARCHAR AS assigned_analyst,
    DATEADD('day', -g.opened_days_ago, CURRENT_DATE()) AS opened_date,
    DATEADD('day', g.sla_days - g.opened_days_ago, CURRENT_DATE()) AS due_date,
    IFF(g.r_status IN (4, 5), DATEADD('day', g.close_days - g.opened_days_ago, CURRENT_DATE()), NULL) AS closed_date,
    CASE g.r_note
        WHEN 1 THEN 'Initial review completed. Awaiting additional documentation from client.'
        WHEN 2 THEN 'Escalated due to adverse media hit. Pending senior analyst review.'
        WHEN 3 THEN 'Standard periodic review. No concerns identified to date.'
        WHEN 4 THEN 'Client provided updated beneficial ownership declaration. Verification in progress.'
        ELSE 'Risk rating reassessment triggered by transaction monitoring alert.'
    END AS notes
FROM gen g
JOIN numbered_clients c ON c.rn = MOD(g.seq, 99995) + 1
CROSS JOIN pools p;

INSERT INTO BNK.KYC_AML.KYC_CASES (
    case_id, client_id, case_type, status, priority,
    assigned_analyst, opened_date, due_date, closed_date, notes
)
SELECT
    column1, column2, column3, column4, column5,
    column6, DATEADD('day', column7, CURRENT_DATE()), DATEADD('day', column8, CURRENT_DATE()), NULL, column9
FROM VALUES
    ('CASE-DEMO-001', 'CL-DEMO-001', 'PeriodicReview', 'PendingDocuments', 'Critical', 'Lisa Park', -21, -7, 'Annual UK PEP periodic review overdue. Updated UK passport uploaded and awaiting AI verification.'),
    ('CASE-DEMO-002', 'CL-DEMO-002', 'EnhancedDueDiligence', 'InReview', 'High', 'Daniel Foster', -10, 4, 'High-risk EDD refresh. Passport uploaded; checking transliteration variance on surname.'),
    ('CASE-DEMO-003', 'CL-DEMO-003', 'NewClient', 'Escalated', 'Critical', 'Rebecca Okonkwo', -5, -4, 'Digital onboarding flagged suspicious identity document upload for high-risk applicant.'),
    ('CASE-DEMO-004', 'CL-DEMO-004', 'PeriodicReview', 'InReview', 'High', 'Priya Sharma', -12, 2, 'Corporate CDD refresh for Nexus Technology Solutions GmbH. Uploaded file declared as Passport.'),
    ('CASE-DEMO-005', 'CL-DEMO-005', 'PeriodicReview', 'InReview', 'Medium', 'Kenji Watanabe', -8, 6, 'Routine 3-year periodic review. Japanese driver license submitted for identity confirmation.');

-------------------------------------------------------------------------------
-- DOCUMENTS_METADATA (499,975 synthetic + 25 real staged PDFs = 500,000 rows)
-------------------------------------------------------------------------------
INSERT INTO BNK.KYC_AML.DOCUMENTS_METADATA (
    doc_id, case_id, client_id, doc_type, file_path,
    upload_date, file_size_bytes, extraction_status, classification_confidence
)
WITH numbered_cases AS (
    SELECT case_id, client_id, ROW_NUMBER() OVER (ORDER BY case_id) AS rn
    FROM BNK.KYC_AML.KYC_CASES
    WHERE case_id NOT LIKE 'CASE-DEMO-%'
),
gen AS (
    SELECT
        SEQ4() AS seq,
        UUID_STRING() AS doc_id,
        UNIFORM(1, 7, RANDOM()) AS r_doctype,
        UNIFORM(1, 63072000, RANDOM()) AS upload_secs_ago,
        UNIFORM(50000, 15000000, RANDOM()) AS file_size_bytes,
        UNIFORM(1, 10, RANDOM()) AS r_status,
        ROUND(UNIFORM(60, 99, RANDOM()) / 100.0, 3) AS conf
    FROM TABLE(GENERATOR(ROWCOUNT => 499975))
)
SELECT
    g.doc_id,
    kc.case_id,
    kc.client_id,
    CASE g.r_doctype
        WHEN 1 THEN 'Passport'
        WHEN 2 THEN 'DriversLicense'
        WHEN 3 THEN 'NationalID'
        WHEN 4 THEN 'FinancialStatement'
        WHEN 5 THEN 'UtilityBill'
        WHEN 6 THEN 'CorporateRegistry'
        ELSE 'BeneficialOwnership'
    END AS doc_type,
    'synthetic/' || kc.client_id || '/' ||
    CASE g.r_doctype
        WHEN 1 THEN 'Passport'
        WHEN 2 THEN 'DriversLicense'
        WHEN 3 THEN 'NationalID'
        WHEN 4 THEN 'FinancialStatement'
        WHEN 5 THEN 'UtilityBill'
        WHEN 6 THEN 'CorporateRegistry'
        ELSE 'BeneficialOwnership'
    END || '_' || g.doc_id || '.pdf' AS file_path,
    DATEADD('second', -g.upload_secs_ago, CURRENT_TIMESTAMP()) AS upload_date,
    g.file_size_bytes,
    CASE g.r_status
        WHEN 1 THEN 'Pending'
        WHEN 2 THEN 'Processing'
        WHEN 10 THEN 'Failed'
        ELSE 'Completed'
    END AS extraction_status,
    IFF(g.r_status NOT IN (1, 2), g.conf, NULL) AS classification_confidence
FROM gen g
JOIN numbered_cases kc ON kc.rn = MOD(g.seq, 199995) + 1;

-- Register the 5 primary showcase PDFs onto CASE-DEMO-001..005 as Pending
INSERT INTO BNK.KYC_AML.DOCUMENTS_METADATA (
    doc_id, case_id, client_id, doc_type, file_path,
    upload_date, file_size_bytes, extraction_status, classification_confidence
)
SELECT
    column1, column2, column3, column4, column5,
    DATEADD('minute', column6, CURRENT_TIMESTAMP()), column7, 'Pending', NULL
FROM VALUES
    ('54866c22-96f2-4967-a248-1d6b72a2310f', 'CASE-DEMO-001', 'CL-DEMO-001', 'Passport', 'clients/Passport_54866c22-96f2-4967-a248-1d6b72a2310f.pdf', -15, 1680),
    ('99c221cb-eb27-44bd-88d7-b69929da359b', 'CASE-DEMO-002', 'CL-DEMO-002', 'Passport', 'clients/Passport_99c221cb-eb27-44bd-88d7-b69929da359b.pdf', -25, 1680),
    ('f89335ea-0fd0-4e9e-8b72-fedd94795d9a', 'CASE-DEMO-003', 'CL-DEMO-003', 'Passport', 'clients/Passport_f89335ea-0fd0-4e9e-8b72-fedd94795d9a.pdf', -35, 1680),
    ('f55f0a67-05dd-4903-9200-6e8c95d3e5d3', 'CASE-DEMO-004', 'CL-DEMO-004', 'Passport', 'clients/FinancialStatement_f55f0a67-05dd-4903-9200-6e8c95d3e5d3.pdf', -45, 2240),
    ('5b502551-c7ae-4ba5-a196-aafd4fb16d03', 'CASE-DEMO-005', 'CL-DEMO-005', 'DriversLicense', 'clients/DriversLicense_5b502551-c7ae-4ba5-a196-aafd4fb16d03.pdf', -55, 1450);

-- Register the remaining 20 staged sample PDFs onto synthetic cases so BATCH_PROCESS_DOCUMENTS can process any batch size up to 25
INSERT INTO BNK.KYC_AML.DOCUMENTS_METADATA (
    doc_id, case_id, client_id, doc_type, file_path,
    upload_date, file_size_bytes, extraction_status, classification_confidence
)
WITH batch_cases AS (
    SELECT case_id, client_id, ROW_NUMBER() OVER (ORDER BY case_id) AS rn
    FROM BNK.KYC_AML.KYC_CASES
    WHERE case_id NOT LIKE 'CASE-DEMO-%'
    QUALIFY rn <= 20
),
extra_pdfs AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY column1) AS rn,
        column1 AS doc_id,
        column2 AS doc_type,
        column3 AS file_path,
        column4 AS mins_ago,
        column5 AS file_size_bytes
    FROM VALUES
        ('0641f4b7-80e4-4d2f-85ba-a2c688d87571', 'DriversLicense', 'clients/DriversLicense_0641f4b7-80e4-4d2f-85ba-a2c688d87571.pdf', -120, 1450),
        ('15d74bb9-eb41-4abb-b3d9-b881bf3e45fa', 'DriversLicense', 'clients/DriversLicense_15d74bb9-eb41-4abb-b3d9-b881bf3e45fa.pdf', -130, 1450),
        ('23bd9be0-4d46-4ee2-a779-2bca8e785a86', 'DriversLicense', 'clients/DriversLicense_23bd9be0-4d46-4ee2-a779-2bca8e785a86.pdf', -140, 1450),
        ('280306fb-06de-4f1e-a4d7-4f11011fbefc', 'DriversLicense', 'clients/DriversLicense_280306fb-06de-4f1e-a4d7-4f11011fbefc.pdf', -150, 1450),
        ('2efa1d9f-6551-493a-a0e2-56e0f892b15b', 'DriversLicense', 'clients/DriversLicense_2efa1d9f-6551-493a-a0e2-56e0f892b15b.pdf', -160, 1450),
        ('3ba8b529-7871-44fe-92f2-b19c9367135f', 'DriversLicense', 'clients/DriversLicense_3ba8b529-7871-44fe-92f2-b19c9367135f.pdf', -170, 1450),
        ('f4f843f3-00ca-4cfa-8b6e-168b1f52fca3', 'DriversLicense', 'clients/DriversLicense_f4f843f3-00ca-4cfa-8b6e-168b1f52fca3.pdf', -180, 1450),
        ('12afa253-fdc1-485c-b56a-37aa7976f888', 'Passport', 'clients/Passport_12afa253-fdc1-485c-b56a-37aa7976f888.pdf', -190, 1680),
        ('19342e4a-a9bd-4cee-938e-4dc59d28c730', 'Passport', 'clients/Passport_19342e4a-a9bd-4cee-938e-4dc59d28c730.pdf', -200, 1680),
        ('7c180d6b-4dab-4ff7-bb2d-9c213916be36', 'Passport', 'clients/Passport_7c180d6b-4dab-4ff7-bb2d-9c213916be36.pdf', -210, 1680),
        ('7d486106-074f-4880-ad1f-911bd0caa2d7', 'Passport', 'clients/Passport_7d486106-074f-4880-ad1f-911bd0caa2d7.pdf', -220, 1680),
        ('9520d4db-c7b6-4da5-bbcc-fdee08a8f93f', 'Passport', 'clients/Passport_9520d4db-c7b6-4da5-bbcc-fdee08a8f93f.pdf', -230, 1680),
        ('966de983-a059-4003-8d06-0955ce25a605', 'Passport', 'clients/Passport_966de983-a059-4003-8d06-0955ce25a605.pdf', -240, 1680),
        ('9918196a-5af5-4698-b7a1-efbe3ee1a66a', 'Passport', 'clients/Passport_9918196a-5af5-4698-b7a1-efbe3ee1a66a.pdf', -250, 1680),
        ('9ad2c9ca-8b5a-4de6-90fb-81c7c82840cb', 'Passport', 'clients/Passport_9ad2c9ca-8b5a-4de6-90fb-81c7c82840cb.pdf', -260, 1680),
        ('ab0f02de-9a1f-4c5f-b431-28cd8adc81f5', 'Passport', 'clients/Passport_ab0f02de-9a1f-4c5f-b431-28cd8adc81f5.pdf', -270, 1680),
        ('ae6e0379-6808-41a6-b282-5374aa404692', 'Passport', 'clients/Passport_ae6e0379-6808-41a6-b282-5374aa404692.pdf', -280, 1680),
        ('ca057517-a077-404b-ab24-4f3963c22eee', 'Passport', 'clients/Passport_ca057517-a077-404b-ab24-4f3963c22eee.pdf', -290, 1680),
        ('f6f63947-4e0d-4383-8ba0-ffd2e16a7651', 'Passport', 'clients/Passport_f6f63947-4e0d-4383-8ba0-ffd2e16a7651.pdf', -300, 1680),
        ('fb30d168-4ec8-4396-a429-d49840ba9d3c', 'Passport', 'clients/Passport_fb30d168-4ec8-4396-a429-d49840ba9d3c.pdf', -310, 1680)
)
SELECT
    ep.doc_id,
    bc.case_id,
    bc.client_id,
    ep.doc_type,
    ep.file_path,
    DATEADD('minute', ep.mins_ago, CURRENT_TIMESTAMP()),
    ep.file_size_bytes,
    'Pending',
    NULL
FROM extra_pdfs ep
JOIN batch_cases bc ON bc.rn = ep.rn;

-------------------------------------------------------------------------------
-- VERIFICATION_RESULTS (1:1 for all Completed documents in DOCUMENTS_METADATA)
-------------------------------------------------------------------------------
INSERT INTO BNK.KYC_AML.VERIFICATION_RESULTS (
    result_id, doc_id, extracted_fields, confidence_score,
    ai_classification, verified_by, verification_date, match_status
)
WITH pools AS (
    SELECT ARRAY_CONSTRUCT(
        'SYSTEM','SYSTEM','SYSTEM','SYSTEM','SYSTEM','SYSTEM','SYSTEM','SYSTEM',
        'Lisa Park','Daniel Foster','Rebecca Okonkwo','Priya Sharma'
    ) AS verifiers
),
completed_docs AS (
    SELECT
        dm.doc_id,
        dm.doc_type,
        c.entity_type,
        c.first_name,
        c.last_name,
        c.date_of_birth,
        c.company_name,
        c.nationality,
        UNIFORM(0, 11, RANDOM()) AS idx_verifier,
        UNIFORM(1, 100, RANDOM()) AS r_match,
        UNIFORM(1, 31536000, RANDOM()) AS ver_secs_ago,
        ROUND(UNIFORM(72, 99, RANDOM()) / 100.0, 3) AS conf_score,
        UNIFORM(1, 10, RANDOM()) AS exp_years,
        UNIFORM(1000000, 9999999, RANDOM()) AS doc_seq
    FROM BNK.KYC_AML.DOCUMENTS_METADATA dm
    JOIN BNK.KYC_AML.CLIENTS c ON dm.client_id = c.client_id
    WHERE dm.extraction_status = 'Completed'
)
SELECT
    UUID_STRING() AS result_id,
    cd.doc_id,
    OBJECT_CONSTRUCT(
        'full_name', IFF(cd.entity_type = 'Individual', cd.first_name || ' ' || cd.last_name, cd.company_name),
        'date_of_birth', cd.date_of_birth::VARCHAR,
        'document_number', CASE cd.doc_type
            WHEN 'Passport' THEN 'P' || cd.doc_seq::VARCHAR
            WHEN 'DriversLicense' THEN 'DL-' || SUBSTR(cd.doc_seq::VARCHAR, 1, 6)
            WHEN 'NationalID' THEN 'NID-' || cd.doc_seq::VARCHAR
            ELSE 'REF-' || SUBSTR(cd.doc_seq::VARCHAR, 1, 6)
        END,
        'issuing_country_code', COALESCE(cd.nationality, 'GBR'),
        'nationality', COALESCE(cd.nationality, 'GBR'),
        'expiry_date', DATEADD('year', cd.exp_years, CURRENT_DATE())::VARCHAR
    ) AS extracted_fields,
    cd.conf_score AS confidence_score,
    cd.doc_type AS ai_classification,
    p.verifiers[cd.idx_verifier]::VARCHAR AS verified_by,
    DATEADD('second', -cd.ver_secs_ago, CURRENT_TIMESTAMP()) AS verification_date,
    CASE
        WHEN cd.r_match <= 70 THEN 'Match'
        WHEN cd.r_match <= 85 THEN 'Partial'
        WHEN cd.r_match <= 95 THEN 'ManualReviewRequired'
        ELSE 'Mismatch'
    END AS match_status
FROM completed_docs cd
CROSS JOIN pools p;

-------------------------------------------------------------------------------
-- ALERT_QUEUE (49,997 synthetic + 3 hero showcase alerts = 50,000 rows)
-------------------------------------------------------------------------------
INSERT INTO BNK.KYC_AML.ALERT_QUEUE (
    alert_id, client_id, alert_type, severity,
    created_date, status, assigned_to
)
WITH sampled_clients AS (
    SELECT client_id, ROW_NUMBER() OVER (ORDER BY client_id) AS rn
    FROM BNK.KYC_AML.CLIENTS
    WHERE client_id NOT LIKE 'CL-DEMO-%'
    QUALIFY rn <= 49997
),
pools AS (
    SELECT ARRAY_CONSTRUCT(
        'Lisa Park','Daniel Foster','Rebecca Okonkwo','Stuart MacLeod','Priya Sharma',
        'Marcus Thompson','Anna Kowalski','Yusuf Demir','Catherine Leung','Jonathan Price'
    ) AS investigators
),
gen AS (
    SELECT
        ROW_NUMBER() OVER (ORDER BY SEQ4()) AS rn,
        UUID_STRING() AS alert_id,
        UNIFORM(1, 5, RANDOM()) AS r_type,
        UNIFORM(1, 4, RANDOM()) AS r_sev,
        UNIFORM(1, 15768000, RANDOM()) AS secs_ago,
        UNIFORM(1, 5, RANDOM()) AS r_status,
        UNIFORM(0, 9, RANDOM()) AS idx_inv
    FROM TABLE(GENERATOR(ROWCOUNT => 49997))
)
SELECT
    g.alert_id,
    sc.client_id,
    CASE g.r_type
        WHEN 1 THEN 'SanctionsHit'
        WHEN 2 THEN 'AdverseMedia'
        WHEN 3 THEN 'UnusualActivity'
        WHEN 4 THEN 'DocumentExpiry'
        ELSE 'RiskRatingChange'
    END AS alert_type,
    CASE g.r_sev
        WHEN 1 THEN 'Low'
        WHEN 2 THEN 'Medium'
        WHEN 3 THEN 'High'
        ELSE 'Critical'
    END AS severity,
    DATEADD('second', -g.secs_ago, CURRENT_TIMESTAMP()) AS created_date,
    CASE g.r_status
        WHEN 1 THEN 'New'
        WHEN 2 THEN 'Assigned'
        WHEN 3 THEN 'Investigating'
        WHEN 4 THEN 'Resolved'
        ELSE 'FalsePositive'
    END AS status,
    IFF(g.r_status IN (2, 3), p.investigators[g.idx_inv]::VARCHAR, NULL) AS assigned_to
FROM gen g
JOIN sampled_clients sc ON sc.rn = g.rn
CROSS JOIN pools p;

INSERT INTO BNK.KYC_AML.ALERT_QUEUE (
    alert_id, client_id, alert_type, severity,
    created_date, status, assigned_to
)
SELECT
    column1, column2, column3, column4,
    DATEADD('hour', column5, CURRENT_TIMESTAMP()), column6, column7
FROM VALUES
    ('ALT-DEMO-001', 'CL-DEMO-001', 'AdverseMedia', 'Critical', -6, 'Investigating', 'Lisa Park'),
    ('ALT-DEMO-002', 'CL-DEMO-003', 'SanctionsHit', 'Critical', -2, 'New', NULL),
    ('ALT-DEMO-003', 'CL-DEMO-004', 'UnusualActivity', 'High', -18, 'Assigned', 'Priya Sharma');
