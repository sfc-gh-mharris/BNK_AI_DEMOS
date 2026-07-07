-- =============================================================================
-- WEALTH MANAGEMENT — SYNTHETIC DATA POPULATION
-- Schema: BNK.WEALTH_MGMT
--
-- Populates all tables with realistic wealth management data.
-- Small reference tables use hand-written INSERT VALUES.
-- Large transactional tables use GENERATOR-based bulk inserts.
--
-- Execution order: ADVISORS → RESEARCH_REPORTS → COMPLIANCE_DOCS →
--                  WM_CLIENTS → PORTFOLIOS → HOLDINGS → MARKET_DATA →
--                  TRADES → CLIENT_NOTES
-- =============================================================================

USE DATABASE BNK;
USE SCHEMA BNK.WEALTH_MGMT;
USE WAREHOUSE BNK_WH;

-- =============================================================================
-- ADVISORS (50 rows)
-- =============================================================================
INSERT INTO BNK.WEALTH_MGMT.ADVISORS (advisor_id, first_name, last_name, title, team, region, clients_count, total_aum_managed, certification)
SELECT * FROM VALUES
    ('adv-001','Michael','Harrison','MD','Private Wealth','Northeast',85,2450000000.00,'CFP'),
    ('adv-002','Sarah','Chen','SVP','Institutional Advisory','West',42,1890000000.00,'CFA'),
    ('adv-003','Robert','Williams','MD','Family Office','Northeast',28,4200000000.00,'CFA'),
    ('adv-004','Jennifer','Martinez','VP','Private Wealth','Southeast',65,980000000.00,'CFP'),
    ('adv-005','David','Thompson','SVP','Private Wealth','Midwest',72,1560000000.00,'ChFC'),
    ('adv-006','Emily','Anderson','MD','Institutional Advisory','West',35,3100000000.00,'CFA'),
    ('adv-007','James','Taylor','VP','Private Wealth','Southwest',58,720000000.00,'CFP'),
    ('adv-008','Amanda','Johnson','SVP','Family Office','Northeast',31,2800000000.00,'CAIA'),
    ('adv-009','Christopher','Lee','MD','Private Wealth','Pacific',48,1950000000.00,'CFA'),
    ('adv-010','Katherine','Brown','VP','Private Wealth','Southeast',62,850000000.00,'CFP'),
    ('adv-011','William','Davis','SVP','Institutional Advisory','Midwest',38,2200000000.00,'CFA'),
    ('adv-012','Rachel','Wilson','VP','Private Wealth','Northeast',71,1100000000.00,'CFP'),
    ('adv-013','Thomas','Garcia','MD','Family Office','West',25,3800000000.00,'CFA'),
    ('adv-014','Stephanie','Moore','SVP','Private Wealth','Southeast',55,1450000000.00,'ChFC'),
    ('adv-015','Daniel','Jackson','VP','Private Wealth','Southwest',68,920000000.00,'CFP'),
    ('adv-016','Nicole','Martin','SVP','Institutional Advisory','Northeast',33,2650000000.00,'CFA'),
    ('adv-017','Andrew','White','MD','Private Wealth','Pacific',45,1780000000.00,'CFP'),
    ('adv-018','Megan','Harris','VP','Private Wealth','Midwest',63,780000000.00,'CFP'),
    ('adv-019','Mark','Clark','SVP','Family Office','West',29,3400000000.00,'CAIA'),
    ('adv-020','Lauren','Lewis','VP','Private Wealth','Southeast',59,680000000.00,'ChFC'),
    ('adv-021','Steven','Robinson','MD','Institutional Advisory','Northeast',40,2950000000.00,'CFA'),
    ('adv-022','Ashley','Walker','VP','Private Wealth','Southwest',66,890000000.00,'CFP'),
    ('adv-023','Paul','Young','SVP','Private Wealth','Midwest',52,1320000000.00,'CFP'),
    ('adv-024','Victoria','Hall','MD','Family Office','Pacific',27,4100000000.00,'CFA'),
    ('adv-025','Kenneth','Allen','VP','Private Wealth','Southeast',70,960000000.00,'ChFC'),
    ('adv-026','Catherine','King','SVP','Institutional Advisory','West',36,2400000000.00,'CFA'),
    ('adv-027','Joshua','Wright','VP','Private Wealth','Northeast',61,750000000.00,'CFP'),
    ('adv-028','Olivia','Scott','SVP','Private Wealth','Midwest',49,1680000000.00,'CFP'),
    ('adv-029','Anthony','Adams','MD','Family Office','Southwest',26,3600000000.00,'CAIA'),
    ('adv-030','Hannah','Nelson','VP','Private Wealth','Pacific',64,830000000.00,'CFP'),
    ('adv-031','Richard','Hill','SVP','Institutional Advisory','Northeast',37,2550000000.00,'CFA'),
    ('adv-032','Samantha','Green','VP','Private Wealth','Southeast',57,710000000.00,'CFP'),
    ('adv-033','Matthew','Baker','MD','Private Wealth','West',44,1850000000.00,'CFA'),
    ('adv-034','Natalie','Gonzalez','VP','Private Wealth','Southwest',67,870000000.00,'ChFC'),
    ('adv-035','Donald','Perez','SVP','Family Office','Midwest',30,3200000000.00,'CAIA'),
    ('adv-036','Margaret','Roberts','VP','Private Wealth','Northeast',60,790000000.00,'CFP'),
    ('adv-037','Charles','Turner','MD','Institutional Advisory','Pacific',34,2700000000.00,'CFA'),
    ('adv-038','Jessica','Phillips','SVP','Private Wealth','Southeast',53,1400000000.00,'CFP'),
    ('adv-039','Joseph','Campbell','VP','Private Wealth','West',69,940000000.00,'ChFC'),
    ('adv-040','Elizabeth','Parker','MD','Family Office','Northeast',24,4500000000.00,'CFA'),
    ('adv-041','Brian','Evans','SVP','Private Wealth','Midwest',51,1250000000.00,'CFP'),
    ('adv-042','Michelle','Edwards','VP','Private Wealth','Southwest',63,680000000.00,'CFP'),
    ('adv-043','Timothy','Collins','MD','Institutional Advisory','Pacific',39,2350000000.00,'CFA'),
    ('adv-044','Rebecca','Stewart','SVP','Private Wealth','Southeast',56,1150000000.00,'ChFC'),
    ('adv-045','Patrick','Sanchez','VP','Family Office','West',32,2900000000.00,'CAIA'),
    ('adv-046','Christina','Morris','VP','Private Wealth','Northeast',66,820000000.00,'CFP'),
    ('adv-047','Kevin','Rogers','SVP','Private Wealth','Midwest',47,1520000000.00,'CFP'),
    ('adv-048','Heather','Reed','MD','Institutional Advisory','Southwest',41,2100000000.00,'CFA'),
    ('adv-049','Gregory','Cook','VP','Private Wealth','Pacific',73,1050000000.00,'CFP'),
    ('adv-050','Diana','Morgan','SVP','Family Office','Northeast',28,3700000000.00,'CFA')
WHERE NOT EXISTS (SELECT 1 FROM BNK.WEALTH_MGMT.ADVISORS LIMIT 1);

-- =============================================================================
-- RESEARCH_REPORTS (30 rows with full multi-paragraph content)
-- =============================================================================
INSERT INTO BNK.WEALTH_MGMT.RESEARCH_REPORTS (report_id, title, analyst_name, publish_date, sector, ticker_coverage, rating, target_price, content)
SELECT * FROM VALUES
('rpt-001', 'Apple Inc. (AAPL) — AI Integration Accelerates Services Revenue Growth', 'Sarah Chen', '2025-03-15', 'Technology', 'AAPL', 'Buy', 245.00,
'Investment Thesis: Apple continues to deliver robust earnings growth driven by its services segment, which now accounts for over 25% of total revenue. The integration of on-device AI capabilities across iPhone, Mac, and iPad product lines creates a compelling upgrade cycle that we believe will drive hardware revenue acceleration through 2026. Services revenue grew 18% year-over-year, supported by Apple TV+, iCloud, and the App Store ecosystem. We see further upside from the AI-powered features driving higher iPhone average selling prices and reducing churn in the installed base. Valuation: Trading at 28x forward earnings, AAPL commands a premium relative to hardware peers, justified by its recurring services revenue mix shift and unmatched ecosystem lock-in. Our $245 price target implies 14% upside from current levels. Key Risks: Antitrust scrutiny of App Store economics, China demand softness, and potential services margin compression from content investments.'),

('rpt-002', 'NVIDIA Corp (NVDA) — Data Center Demand Remains Insatiable', 'Michael Rodriguez', '2025-04-02', 'Technology', 'NVDA', 'StrongBuy', 1050.00,
'Investment Thesis: NVIDIA remains the undisputed leader in AI accelerated computing with over 80% market share in data center GPUs. The Blackwell architecture is ramping faster than Hopper did at the same point in its cycle, with hyperscaler demand outstripping supply through at least mid-2026. Data center revenue grew 154% year-over-year to $22.6 billion in the most recent quarter. Enterprise adoption of AI inference workloads is the next major growth vector, expanding the TAM beyond training. We estimate the AI infrastructure market will reach $500B by 2028, and NVIDIA is positioned to capture 60-70% of the compute layer. Valuation: At 35x forward earnings, NVDA trades at a premium but we believe this is warranted given 50%+ revenue growth visibility. Our $1,050 target represents 40x our CY2026 EPS estimate of $26.25. Key Risks: Customer concentration in hyperscalers, potential supply chain disruptions, and emergence of custom silicon alternatives from major cloud providers.'),

('rpt-003', 'Microsoft Corp (MSFT) — Azure AI Monetization Inflecting', 'Sarah Chen', '2025-03-28', 'Technology', 'MSFT', 'Buy', 480.00,
'Investment Thesis: Microsoft Azure cloud revenue growth reaccelerated to 33% driven by AI workloads contributing 12 percentage points of growth. The Copilot suite is gaining enterprise traction with 60% of Fortune 500 companies now deploying at least one Copilot product. We model Azure revenue reaching $110B annualized by FY2026, with AI services representing 25% of the mix. The combination of infrastructure (Azure), platform (GitHub Copilot, Microsoft 365 Copilot), and application layers (Dynamics 365) gives Microsoft the most complete AI stack among hyperscalers. Valuation: Our $480 target is based on a sum-of-parts analysis valuing Azure at 12x revenue, Productivity at 25x earnings, and LinkedIn/Gaming segments at peer multiples. Key Risks: AI infrastructure spending rationalization by enterprises, competitive pressure from AWS and Google Cloud, and regulatory scrutiny of the Activision acquisition.'),

('rpt-004', 'Amazon.com Inc (AMZN) — AWS Reacceleration and Retail Margin Expansion', 'David Park', '2025-04-10', 'Technology', 'AMZN', 'Buy', 225.00,
'Investment Thesis: Amazon delivered a strong quarter with AWS revenue growth reaccelerating to 19% as enterprises resumed cloud migration projects paused during the optimization cycle. Retail operating margins expanded 200bps year-over-year as same-day delivery regionalization reduces fulfillment costs. Advertising revenue grew 27% to $14.6B, making Amazon the third-largest digital ad platform globally. We see AWS AI services (Bedrock, SageMaker) as key growth catalysts, with AI-related revenue now exceeding a $10B annual run rate. Valuation: Trading at 22x 2026E EBITDA, we see upside to $225 based on continued margin expansion in retail and sustained 20%+ AWS growth. Key Risks: FTC antitrust challenges, potential AWS margin pressure from AI infrastructure investments, and macro sensitivity in consumer discretionary spending.'),

('rpt-005', 'Meta Platforms Inc (META) — Reels Monetization and AI Assistant Adoption', 'Michael Rodriguez', '2025-02-20', 'Technology', 'META', 'Buy', 580.00,
'Investment Thesis: Meta delivered exceptional results with Family of Apps revenue growing 24% year-over-year to $40.1B. Reels monetization efficiency reached 75% of Feed levels, up from 50% a year ago, while AI-driven ad targeting improvements drove a 12% increase in average revenue per user globally. Meta AI has reached 700 million monthly active users, creating a new engagement surface for future monetization. Reality Labs losses are narrowing as Quest headset volumes grow. Valuation: At 24x forward earnings, META trades at a discount to big tech peers despite superior revenue growth. Our $580 target implies 27x our 2026 EPS estimate. Key Risks: Regulatory headwinds in EU (Digital Markets Act), Reality Labs continued losses, and advertiser budget sensitivity to macro conditions.'),

('rpt-006', 'Salesforce Inc (CRM) — Agentforce Drives Next Growth Wave', 'Sarah Chen', '2025-03-05', 'Technology', 'CRM', 'Hold', 290.00,
'Investment Thesis: Salesforce Agentforce launch represents the most significant product cycle since the shift to cloud. Early adoption metrics are encouraging with 1,000+ enterprise deployments, though monetization remains nascent. Core CRM growth has stabilized at 9% but margin expansion continues with operating margins reaching 33%. The Data Cloud platform is gaining traction as a differentiated AI data layer. However, valuation adequately reflects near-term growth expectations at 27x forward earnings. Valuation: Our $290 hold target reflects 6.5x CY2026 revenue, a slight premium to enterprise software peers given margin profile. We would become more constructive on evidence of Agentforce revenue contribution exceeding $1B annualized. Key Risks: Competitive pressure from Microsoft Copilot in core CRM, elongated enterprise sales cycles, and integration challenges from recent acquisitions.'),

('rpt-007', 'Tesla Inc (TSLA) — Autonomy Timeline Uncertainty Weighs on Valuation', 'David Park', '2025-04-15', 'Technology', 'TSLA', 'Sell', 155.00,
'Investment Thesis: Tesla auto deliveries declined 8% year-over-year as aging model lineup faces intensifying competition from Chinese EV manufacturers and legacy OEMs. Automotive gross margins compressed to 16.4% as price cuts continue to support volume. While the FSD and robotaxi narrative provides optionality, regulatory approval timelines remain highly uncertain and we see limited near-term revenue contribution. Energy storage grew 67% but represents only 8% of total revenue. Valuation: At 65x forward earnings, the stock prices in significant autonomous driving value that we believe remains years from material monetization. Our $155 target reflects 30x our 2026 auto earnings plus $25/share for energy and services. Key Risks to our thesis: Faster-than-expected FSD regulatory approval, robotaxi launch success, or meaningful margin improvement from next-gen manufacturing platform.'),

('rpt-008', 'Alphabet Inc (GOOGL) — Search AI Evolution Protects Moat', 'Michael Rodriguez', '2025-03-22', 'Technology', 'GOOGL', 'Buy', 195.00,
'Investment Thesis: Google Search revenue grew 14% year-over-year as AI Overviews increase query engagement without cannibalizing ad clicks. YouTube advertising reached $10B quarterly revenue with Shorts monetization accelerating. Google Cloud revenue grew 28% to $10.3B with AI infrastructure demand driving above-market growth. Waymo autonomous rides exceeded 200K per week, providing long-term optionality. Capital allocation improving with $70B buyback program and inaugural dividend. Valuation: At 22x forward earnings, GOOGL trades at a discount to mega-cap tech peers despite comparable growth. Our $195 target implies 24x 2026 EPS. Key Risks: DOJ antitrust remedy potentially requiring search distribution changes, AI search competition from OpenAI/Perplexity, and YouTube regulatory challenges.'),

('rpt-009', 'UnitedHealth Group (UNH) — Diversified Healthcare Platform Sustains Premium Growth', 'Laura Kim', '2025-03-10', 'Healthcare', 'UNH', 'Buy', 620.00,
'Investment Thesis: UnitedHealth delivered 13% revenue growth to $100.8B, driven by Optum Health membership growth of 11% and UnitedHealthcare commercial enrollment gains. The integration of health services (Optum) with insurance (UHC) creates a vertically integrated model generating $32B in annual operating cash flow. Optum Rx processed 1.6B scripts annually with biosimilar adoption driving improved unit economics. AI-powered claims processing reduced medical cost ratio by 40bps. Valuation: Trading at 17x forward earnings, UNH warrants its premium to managed care peers given superior growth and diversification. Our $620 target implies 19x 2026 EPS of $32.60. Key Risks: Medicare Advantage rate pressure, DOJ investigation of Optum practices, and potential regulatory changes to pharmacy benefit manager economics.'),

('rpt-010', 'Pfizer Inc (PFE) — Pipeline Optionality Not Reflected in Valuation', 'Laura Kim', '2025-02-28', 'Healthcare', 'PFE', 'Buy', 34.00,
'Investment Thesis: Pfizer shares have declined 50% from pandemic peaks as COVID revenue normalized, but the base business is inflecting positively. Oncology revenue grew 25% driven by Padcev and Adcetris acquisitions, and the pipeline has 112 programs in clinical development. The Seagen acquisition is exceeding synergy targets with $1.5B in cost savings achieved. At 10x forward earnings with a 6.2% dividend yield, we see asymmetric upside as the market underappreciates pipeline optionality. Valuation: Our $34 target implies 12x 2026 EPS, still below the historical 15x average, reflecting ongoing investor skepticism. We see upside catalysts from 4 Phase 3 readouts in 2025. Key Risks: Pipeline clinical failures, continued COVID revenue decline, and patent cliff exposure in 2027-2028.'),

('rpt-011', 'Eli Lilly & Co (LLY) — GLP-1 Leadership Justifies Premium', 'Laura Kim', '2025-04-05', 'Healthcare', 'LLY', 'StrongBuy', 950.00,
'Investment Thesis: Eli Lilly has established dominant positioning in the GLP-1 obesity and diabetes market, which we estimate will reach $150B globally by 2030. Mounjaro and Zepbound combined revenue reached $12B annualized with demand still exceeding supply. Orforglipron (oral GLP-1) Phase 3 data showed comparable efficacy to injectable formulations, potentially expanding the addressable market by 3x. Manufacturing capacity investments of $20B will relieve supply constraints by 2026. Valuation: At 55x forward earnings, LLY commands the highest multiple in large-cap pharma, justified by 30%+ revenue growth visibility through 2028. Our $950 target applies 50x to our 2026 EPS estimate of $19.00. Key Risks: GLP-1 safety signals (thyroid C-cell tumors in rodents), manufacturing execution, and competitive entry from Novo Nordisk next-gen compounds.'),

('rpt-012', 'Johnson & Johnson (JNJ) — MedTech Recovery and Pharma Pipeline', 'Laura Kim', '2025-03-18', 'Healthcare', 'JNJ', 'Hold', 165.00,
'Investment Thesis: Post-Kenvue consumer health spinoff, JNJ is a focused pharma/medtech company with improving growth characteristics. Innovative Medicine grew 6% organically led by Darzalex ($10B+), Tremfya, and Erleada. MedTech grew 5% with orthopedic recovery and surgical robotics gains. However, biosimilar erosion for Stelara ($14B peak) beginning in 2025 creates a meaningful revenue headwind. Valuation: At 15x forward earnings, JNJ is fairly valued for mid-single-digit growth with best-in-class dividend credentials. Key Risks: Stelara LOE impact, talc litigation resolution costs, and MedTech competitive pressure.'),

('rpt-013', 'AbbVie Inc (ABBV) — Humira LOE Navigated, Growth Resuming', 'Laura Kim', '2025-02-14', 'Healthcare', 'ABBV', 'Buy', 210.00,
'Investment Thesis: AbbVie has successfully navigated the Humira loss of exclusivity with immunology successors Skyrizi and Rinvoq growing 50%+ combined to reach $16B annualized revenue. Aesthetics (Botox) and neuroscience (Vraylar) provide diversification beyond immunology. The company raised FY2025 guidance reflecting confidence in growth resumption after the Humira transition trough. Free cash flow of $24B annually supports a 3.6% dividend yield plus $10B in annual buybacks. Valuation: At 14x forward earnings with 12% EPS growth, ABBV is attractively valued. Our $210 target implies 16x 2026 EPS. Key Risks: Rinvoq safety label updates, aesthetics market cyclicality, and pipeline clinical setbacks.'),

('rpt-014', 'Merck & Co (MRK) — Keytruda Franchise Extension Critical', 'Laura Kim', '2025-03-30', 'Healthcare', 'MRK', 'Hold', 130.00,
'Investment Thesis: Keytruda remains the worlds best-selling drug at $28B annualized with continued label expansions in earlier-line oncology settings. However, patent expiration in 2028 creates a significant cliff requiring successful subcutaneous formulation approval and pipeline diversification. The Prometheus acquisition ($11B) adds autoimmune assets. Animal health division provides stable 8% growth. Valuation: At 13x forward earnings, the stock reflects meaningful Keytruda cliff discount. Our $130 hold rating acknowledges the balanced risk/reward. Key Risks: Keytruda subQ formulation regulatory delay, competitive displacement in lung cancer, and pipeline clinical failures.'),

('rpt-015', 'JPMorgan Chase & Co (JPM) — Best-in-Class Banking Franchise', 'William Foster', '2025-03-12', 'Financials', 'JPM', 'StrongBuy', 240.00,
'Investment Thesis: JPMorgan delivered record annual net income of $50.6B driven by net interest income expansion and market share gains across all business lines. The bank gained 200bps of deposit market share during the regional banking crisis, solidifying its position as the dominant US franchise. CIB revenue grew 18% with investment banking fees recovering to $8.2B. Consumer banking added 2.3M new checking accounts. AI investments across operations, risk, and advisory are enhancing operating efficiency. Valuation: At 12.5x forward earnings and 2.0x tangible book value, JPM warrants a premium to money center peers. Our $240 target implies 13.5x 2026 EPS of $17.80. Key Risks: Credit cycle deterioration in commercial real estate, net interest income normalization as rates decline, and regulatory capital requirements (Basel III endgame).'),

('rpt-016', 'Goldman Sachs Group (GS) — Capital Markets Recovery Leader', 'William Foster', '2025-04-08', 'Financials', 'GS', 'Buy', 530.00,
'Investment Thesis: Goldman Sachs is the primary beneficiary of capital markets recovery with M&A advisory revenue growing 35% as sponsor-backed deal activity rebounds. FICC and Equities trading revenue reached $8.5B quarterly. Asset and Wealth Management AUM grew to $3.1T with 22% fee-based revenue growth. Strategic refocusing away from consumer banking and toward the asset management fee stream improves earnings quality and multiple deserved. Valuation: At 11x forward earnings and 1.5x TBV, GS is attractively positioned for capital markets recovery. Our $530 target implies 12.5x 2026 EPS. Key Risks: Capital markets activity slowdown, trading revenue volatility, and regulatory constraints on principal investments.'),

('rpt-017', 'Bank of America Corp (BAC) — Rate Sensitivity Creates Upside', 'William Foster', '2025-02-25', 'Financials', 'BAC', 'Buy', 48.00,
'Investment Thesis: Bank of America is the most interest rate-sensitive of the large US banks with each 25bps Fed funds increase adding $1.4B to annual NII. Consumer banking delivered 9% revenue growth with digital engagement metrics industry-leading at 78% active digital users. Wealth management AUM reached $4.2T. Credit quality remains strong with NCOs at 55bps, well below through-cycle averages. The stock trades at a meaningful discount to JPM despite comparable credit quality. Valuation: At 10.5x forward earnings and 1.3x TBV, BAC offers 30%+ upside in a rising rate environment. Our $48 target is based on 12x normalized EPS of $4.00. Key Risks: Faster-than-expected rate cuts compressing NIM, CRE loan deterioration, and regulatory capital surcharges.'),

('rpt-018', 'BlackRock Inc (BLK) — Secular Winner in Asset Management', 'William Foster', '2025-03-20', 'Financials', 'BLK', 'Buy', 920.00,
'Investment Thesis: BlackRock AUM reached $11.6T driven by $150B in quarterly net inflows across ETFs, institutional, and private markets. The iShares ETF platform captured 35% of US industry flows. Private markets AUM doubled to $430B following the GIP acquisition, diversifying revenue beyond passive equity beta. Technology services (Aladdin) reached $1.6B in annual revenue with 8% organic growth. Operating margin of 44% reflects scale advantages. Valuation: At 23x forward earnings, BLK commands a premium to traditional asset managers but below technology multiples despite its tech-enabled platform. Our $920 target implies 25x 2026 EPS. Key Risks: Passive fee compression, equity market decline reducing AUM, and private markets fundraising slowdown.'),

('rpt-019', 'Morgan Stanley (MS) — Wealth Management Drives Steady Growth', 'William Foster', '2025-04-01', 'Financials', 'MS', 'Hold', 105.00,
'Investment Thesis: Morgan Stanleys wealth management transformation is largely complete with the division now contributing 55% of firm revenue and 60% of pre-tax income. Client assets reached $7.2T with fee-based flows of $30B quarterly providing revenue stability. Investment management added $15B in long-term flows. However, institutional securities revenue remains volatile and the stock reflects fair value at current levels. Valuation: At 13x forward earnings, MS is fairly valued relative to growth prospects. Wealth management stability supports the floor but upside requires capital markets outperformance. Key Risks: Advisor attrition to RIA channels, equity market decline reducing fee revenue, and fixed income trading normalization.'),

('rpt-020', 'ExxonMobil Corp (XOM) — Upstream Discipline and Pioneer Integration', 'James Wright', '2025-03-08', 'Energy', 'XOM', 'Buy', 128.00,
'Investment Thesis: ExxonMobil delivered record production of 4.6M BOE/d following Pioneer Natural Resources integration, making it the largest Permian Basin operator. Upstream unit costs declined to $9.50/BOE, best-in-class among supermajors. The low-carbon solutions segment reached $2B annual revenue from carbon capture and biofuels. Shareholder returns totaled $36B in buybacks plus $15B in dividends. Balance sheet remains fortress-grade with net debt/EBITDA of 0.5x. Valuation: At 11x forward earnings with a 3.4% dividend yield, XOM offers compelling value in a constructive oil price environment ($70-90 Brent). Our $128 target implies 12x 2026 EPS. Key Risks: Oil price decline below $60, Permian decline rates accelerating, and ESG-driven institutional divestment.'),

('rpt-021', 'Chevron Corp (CVX) — Permian and LNG Growth Underappreciated', 'James Wright', '2025-02-18', 'Energy', 'CVX', 'Buy', 175.00,
'Investment Thesis: Chevron Permian production grew 15% to 1.2M BOE/d with unit costs declining 8% year-over-year. The Hess acquisition (pending) adds Guyana exposure — one of the highest-return upstream assets globally. LNG portfolio expansion (Wheatstone, Gorgon) provides secular gas demand exposure. Free cash flow of $22B at $75 Brent supports both the 4.1% dividend yield and $17.5B annual buyback. Valuation: At 10.5x forward earnings, CVX trades at a slight discount to XOM despite comparable return on capital. Our $175 target implies 11.5x 2026 EPS of $15.20. Key Risks: Hess arbitration outcome, LNG contract renegotiation in Australia, and oil price volatility.'),

('rpt-022', 'ConocoPhillips (COP) — Pure-Play E&P with Superior Returns', 'James Wright', '2025-03-25', 'Energy', 'COP', 'Hold', 118.00,
'Investment Thesis: ConocoPhillips is the largest independent E&P globally with 2.1M BOE/d production and a deep 20-year inventory of sub-$40/BOE breakeven wells. The Marathon Oil acquisition extended Permian and Eagle Ford positions. Capital discipline (reinvestment rate below 50%) generates $12B annual free cash flow at $70 WTI. However, organic growth is decelerating and the stock adequately reflects the quality premium. Valuation: At 11x forward earnings, COP is fairly valued relative to E&P peers. Our $118 hold reflects balanced risk/reward. Key Risks: Oil price decline, inventory depletion faster than replenishment, and Alaska regulatory challenges.'),

('rpt-023', 'Devon Energy Corp (DVN) — Variable Dividend Model Under Pressure', 'James Wright', '2025-04-12', 'Energy', 'DVN', 'Sell', 38.00,
'Investment Thesis: Devon variable-plus-fixed dividend model has reduced total shareholder yield as oil prices moderate. Delaware Basin production grew 5% but capital intensity is rising as tier-1 inventory depletes. Acquisition of remaining Permian bolt-ons provides only modest production additions at higher costs. The free cash flow yield at $70 WTI compressed to 8%, below peer average of 10%. We see better risk/reward in XOM and CVX which offer diversification. Valuation: At 8x forward earnings, Devon appears cheap but growth deceleration and rising capital intensity warrant a discount. Our $38 target reflects 7x 2026 EPS. Key Risks to our thesis: Oil price surge above $90, accretive M&A, or significant cost reduction.'),

('rpt-024', 'Home Depot Inc (HD) — Housing Recovery and Pro Segment Growth', 'Anna Patel', '2025-03-14', 'ConsumerDiscretionary', 'HD', 'Buy', 420.00,
'Investment Thesis: Home Depot is positioned for a housing-driven recovery cycle as existing home sales begin normalizing from 30-year lows. The Pro segment (45% of sales) grew 8% driven by complex project demand and SRS Distribution acquisition synergies. Comparable store sales turned positive for the first time in 6 quarters. HD One supply chain transformation is reducing delivery times while improving margins. Total addressable market in home improvement expanded to $950B. Valuation: At 24x forward earnings, HD warrants a premium multiple given its dominant market position and recovery cycle leverage. Our $420 target implies 26x 2026 EPS. Key Risks: Housing affordability constraining existing home turnover, tariff impact on imported goods (30% of COGS), and Pro project delays from labor shortages.'),

('rpt-025', 'Costco Wholesale Corp (COST) — Membership Moat Widens', 'Anna Patel', '2025-02-10', 'ConsumerDiscretionary', 'COST', 'Hold', 780.00,
'Investment Thesis: Costco delivered 8.5% comparable sales growth with membership renewal rates at a record 93.4%. The recent membership fee increase ($5 for Gold, $10 for Executive) will add $650M to annual high-margin revenue. E-commerce grew 22% with same-day delivery expansion. However, at 43x forward earnings, the stock prices in near-perfect execution with limited margin of safety. The quality is unquestioned but valuation leaves little room for upside. Valuation: Our $780 hold target reflects the stocks appropriate premium for best-in-class retail execution but limited upside from current levels. Key Risks: Membership growth deceleration, fresh food margin pressure from inflation, and warehouse expansion cannibalization.'),

('rpt-026', 'Nike Inc (NKE) — Brand Reset Taking Longer Than Expected', 'Anna Patel', '2025-04-18', 'ConsumerDiscretionary', 'NKE', 'Sell', 72.00,
'Investment Thesis: Nikes brand reset under new leadership is progressing slower than expected with North America revenue declining 8% and China growth decelerating to 2%. DTC channel revenue fell 12% as the company rebalances toward wholesale after over-rotating direct. Innovation pipeline (Air Max Dn, Pegasus Premium) is showing early traction but insufficient to offset near-term headwinds. Inventory management has improved but gross margins remain 200bps below pre-pandemic levels. Valuation: At 28x forward earnings with negative near-term EPS growth, NKE is overvalued relative to the execution risk in its turnaround. Our $72 target reflects 22x our reduced 2026 EPS estimate of $3.28. Key Risks to our thesis: Faster wholesale recovery, China demand acceleration, or successful Olympics-driven brand momentum.'),

('rpt-027', 'Caterpillar Inc (CAT) — Infrastructure Spending Supports Multi-Year Cycle', 'Robert Chang', '2025-03-06', 'Industrials', 'CAT', 'StrongBuy', 400.00,
'Investment Thesis: Caterpillar is the primary beneficiary of a generational infrastructure spending cycle driven by IIJA, CHIPS Act, and private data center construction. Construction Industries revenue grew 12% with North America non-residential the strongest end market. Resource Industries grew 8% driven by mining capital replacement cycles. Services revenue reached 25% of total, providing margin stability through cycles. Operating margin expanded to 22.4%, reflecting pricing power and manufacturing efficiency. Valuation: At 17x forward earnings, CAT trades below its historical average despite structural margin improvement. Our $400 target implies 19x 2026 EPS, reflecting the multi-year infrastructure tailwind. Key Risks: US government spending sequestration, China construction activity decline, and dealer inventory destocking.'),

('rpt-028', 'Honeywell International (HON) — Aerospace Aftermarket Drives Growth', 'Robert Chang', '2025-04-06', 'Industrials', 'HON', 'Hold', 215.00,
'Investment Thesis: Honeywell Aerospace Technologies grew 14% driven by commercial aftermarket strength as global flight hours recovered to pre-pandemic levels. The planned three-way separation (Aerospace, Automation, Advanced Materials) could unlock sum-of-parts value. Industrial Automation faces mixed demand with warehouse automation declining 5% while process control grew 8%. Advanced Materials saw 6% growth from electronics and sustainable technologies. Valuation: At 21x forward earnings, HON is fairly valued pending clarity on separation execution and standalone entity multiples. Key Risks: Separation execution complexity, aerospace OEM production rate delays, and automation cyclical downturn.'),

('rpt-029', 'NextEra Energy (NEE) — Renewable Leader Benefiting from Data Center Demand', 'Robert Chang', '2025-02-22', 'Utilities', 'NEE', 'StrongBuy', 88.00,
'Investment Thesis: NextEra Energy is the worlds largest generator of wind and solar energy with 73GW of capacity in operation or backlog. Data center power demand is creating unprecedented growth in renewable PPAs with backlog additions of 15GW in the last year alone. Florida Power & Light rate base grew 10% with allowed ROE of 11.5%. NextEra Energy Resources signed 12GW of new contracts in the latest quarter. The regulatory environment for utility-scale renewables remains highly constructive. Valuation: At 25x forward earnings, NEE warrants its utility-sector premium given 10%+ EPS growth versus peer average of 5-6%. Our $88 target implies 27x 2026 EPS. Key Risks: Interest rate impact on project economics, permitting delays, and PPA counterparty credit risk.'),

('rpt-030', 'Duke Energy Corp (DUK) — Regulated Utility with Clean Energy Transition', 'Robert Chang', '2025-03-30', 'Utilities', 'DUK', 'Hold', 108.00,
'Investment Thesis: Duke Energy offers regulated utility stability with 85% of earnings from regulated operations across six states. Rate base growth of 7% annually is supported by grid modernization and clean energy investments totaling $73B through 2028. The Carolinas are seeing accelerated demand growth from manufacturing reshoring and data center development. Dividend yield of 4.0% is well-covered at 65% payout ratio. However, regulatory lag in North Carolina creates near-term earnings headwinds. Valuation: At 17x forward earnings with 5-7% EPS growth, DUK is fairly valued for a regulated utility. Our $108 hold rating reflects adequate compensation for the risk profile. Key Risks: NC regulatory outcomes below authorized ROE, storm cost recovery delays, and rising interest expense on debt-funded capex program.')
WHERE NOT EXISTS (SELECT 1 FROM BNK.WEALTH_MGMT.RESEARCH_REPORTS LIMIT 1);

-- =============================================================================
-- COMPLIANCE_DOCS (20 rows with full regulatory content)
-- =============================================================================
INSERT INTO BNK.WEALTH_MGMT.COMPLIANCE_DOCS (doc_id, title, category, effective_date, content)
SELECT * FROM VALUES
('cmp-001', 'Regulation Best Interest — Care Obligation', 'RegBI', '2024-07-01',
'This policy establishes the firms obligations under SEC Regulation Best Interest (RegBI) Rule 15l-1, specifically addressing the Care Obligation. All associated persons making recommendations to retail customers must exercise reasonable diligence, care, and skill to (1) understand the potential risks, rewards, and costs associated with the recommendation, (2) have a reasonable basis to believe the recommendation is in the best interest of the customer based on their investment profile, and (3) have a reasonable basis to believe that a series of recommended transactions is not excessive. The investment profile includes but is not limited to: age, financial situation, tax status, investment objectives, investment experience, investment time horizon, liquidity needs, risk tolerance, and any other information disclosed by the customer. Documentation of the basis for each recommendation must be maintained in the client file for a minimum of six years per SEC Rule 17a-4.'),

('cmp-002', 'Regulation Best Interest — Disclosure Obligation', 'RegBI', '2024-07-01',
'Under the Disclosure Obligation of RegBI, the firm must provide retail customers with a written disclosure (Form CRS) at or before the time of recommendation, containing: (1) all material facts relating to the scope and terms of the relationship, (2) all material facts relating to conflicts of interest associated with the recommendation, (3) the capacity in which the associated person is acting, and (4) material limitations on the recommendations. Conflicts disclosure must include compensation arrangements, revenue sharing, proprietary product preferences, and any financial incentive that could influence the recommendation. Form CRS must be updated within 30 days of any material change and filed with the SEC via EDGAR. Delivery confirmation must be documented in the client record. Failure to provide adequate disclosure constitutes a violation of Exchange Act Section 15(l)(1).'),

('cmp-003', 'Suitability Determination — Investment Recommendations', 'Suitability', '2024-01-15',
'All investment recommendations must satisfy the firms suitability requirements prior to execution. The suitability assessment must consider: (1) Customer-specific suitability — the recommendation is suitable for the specific customer based on their documented investment profile, (2) Reasonable-basis suitability — the advisor has a reasonable basis to believe the recommendation is suitable for at least some investors, and (3) Quantitative suitability — a series of transactions is not excessive in frequency or cost given the customers profile. For concentrated positions exceeding 10% of portfolio value, enhanced suitability documentation is required including written acknowledgment of concentration risk. For alternative investments, additional suitability criteria include verification of accredited investor status, liquidity assessment, and maximum allocation limits based on net worth (generally 20% for alternatives). All suitability determinations must be documented contemporaneously.'),

('cmp-004', 'Suitability — Senior Investor Protections', 'Suitability', '2024-03-01',
'Enhanced suitability protections apply to customers aged 65 and older or customers identified as potentially vulnerable. For senior investors, the firm requires: (1) designation of a trusted contact person on file, (2) review of any recommendation involving illiquid investments, complex products, or concentrated positions by the branch manager within 48 hours, (3) documentation of cognitive capacity assessment if concerns arise during client interactions, (4) temporary hold authorization for disbursements where financial exploitation is suspected (per FINRA Rule 2165, hold period not to exceed 25 business days with 10 business day extension), and (5) annual review of risk tolerance and investment objectives to capture life changes. Advisors must complete annual senior investor training and report any suspected exploitation to the firms designated senior protection coordinator within 24 hours.'),

('cmp-005', 'Suitability — Complex Products Approval', 'Suitability', '2024-05-01',
'Recommendations of complex products require pre-approval through the Complex Products Review Committee. Complex products include: structured notes, leveraged/inverse ETFs, options strategies beyond covered calls, private placements, non-traded REITs, interval funds, and cryptocurrency-related products. Pre-approval process: (1) Advisor completes Complex Product Suitability Form documenting client qualification, (2) Form reviewed by designated Complex Products principal within 2 business days, (3) Verification that client meets minimum requirements (net worth, income, investment experience), (4) Written client acknowledgment of product risks and liquidity limitations. Maximum allocations for complex products: 25% for accredited investors, 15% for non-accredited investors. Leveraged/inverse ETFs require same-day review of holding period to ensure alignment with short-term tactical use.'),

('cmp-006', 'Suitability — Risk Tolerance Framework', 'Suitability', '2024-01-15',
'The firms risk tolerance framework classifies clients into four categories with corresponding investment constraints: CONSERVATIVE — Maximum equity allocation 40%, minimum fixed income 40%, no alternatives without specific approval, maximum single-position weight 5%. MODERATE — Maximum equity allocation 65%, minimum fixed income 20%, alternatives up to 15%, maximum single-position weight 8%. AGGRESSIVE — Maximum equity allocation 85%, minimum fixed income 10%, alternatives up to 25%, maximum single-position weight 10%. VERY AGGRESSIVE — Maximum equity allocation 95%, fixed income optional, alternatives up to 35%, maximum single-position weight 15% with written concentration acknowledgment. Risk tolerance must be reassessed: (1) at minimum annually during periodic review, (2) upon notification of material life change, (3) when recommended transaction would result in allocation outside permitted ranges. Any trade that would breach these limits requires prior written client consent and supervisory pre-approval.'),

('cmp-007', 'Best Execution — Order Routing and Review', 'BestExecution', '2024-06-01',
'The firm is obligated under FINRA Rule 5310 and SEC Rule 606 to seek best execution for all client orders. Best execution requires regular and rigorous review of execution quality across venues, considering: (1) speed of execution, (2) price improvement relative to NBBO, (3) likelihood of execution at quoted size, (4) costs of transaction (explicit and implicit), and (5) overall quality of executions across orders. The Best Execution Committee meets quarterly to review order routing arrangements and execution quality statistics. Payment-for-order-flow arrangements must be disclosed on Form CRS and may not compromise execution quality. For fixed income securities, at least three competitive quotes must be obtained for trades exceeding $250,000 face value. Report 606 quarterly disclosure must include material routing arrangements and any conflicts of interest.'),

('cmp-008', 'Best Execution — Trade Cost Analysis', 'BestExecution', '2024-06-01',
'Monthly trade cost analysis (TCA) reports are generated for all advisory accounts. TCA methodology includes: (1) Implementation shortfall — comparing execution price to decision price at time of recommendation, (2) VWAP analysis — comparing execution versus volume-weighted average price during execution window, (3) Arrival price comparison — versus midpoint at time of order entry. Accounts flagged for excessive trading costs (defined as implementation shortfall exceeding 50bps for equity trades or 25bps for fixed income) require branch manager review and client communication within 15 business days. Annual best execution review report submitted to Board of Directors by March 31 for prior calendar year. Client complaints regarding execution quality must be escalated to the Best Execution Committee within 5 business days.'),

('cmp-009', 'Best Execution — Fixed Income Markups', 'BestExecution', '2024-06-01',
'Fixed income transactions executed as principal require markup/markdown disclosure and must be reasonable relative to prevailing market conditions. Markup guidelines: Municipal bonds — maximum 2% for institutional, 3% for retail. Corporate bonds — maximum 1.5% for institutional, 2.5% for retail. Government securities — maximum 0.5%. Markup reasonableness factors include: (1) type of security and market conditions, (2) transaction size, (3) cost of hedging, (4) credit quality, and (5) maturity. Markups exceeding guidelines require pre-approval from the Fixed Income Compliance desk. All principal transactions must disclose markup/markdown amount on trade confirmation per FINRA Rule 2232. Monthly reporting of average markups by security type to senior management.'),

('cmp-010', 'Form ADV Part 2A — Firm Brochure', 'FormADV', '2024-01-01',
'Wealth Management Advisory Services, LLC is a registered investment advisor with the Securities and Exchange Commission. We provide investment advisory services including portfolio management, financial planning, and retirement planning. Our advisory fees are charged as a percentage of assets under management, ranging from 0.25% to 1.50% annually depending on account size and service level. We may also receive compensation from mutual fund 12b-1 fees, which creates a conflict of interest that we mitigate through disclosure and our fiduciary duty. We manage client assets on a discretionary basis using individual securities, ETFs, mutual funds, and alternative investments. Our investment strategies range from conservative fixed income to aggressive growth equity, selected based on client suitability assessment. We do not guarantee investment results and past performance is not indicative of future returns.'),

('cmp-011', 'Form ADV Part 2A — Conflicts of Interest', 'FormADV', '2024-01-01',
'Material conflicts of interest in our advisory practice include: (1) Revenue sharing — certain mutual fund families pay us revenue sharing fees of up to 25bps, which may incentivize recommendation of these funds. We mitigate by disclosing all revenue sharing arrangements and requiring that recommended funds are independently suitable regardless of revenue sharing status. (2) Proprietary products — the firm offers proprietary model portfolios that generate additional fee revenue. Advisors are not incentivized to recommend proprietary over third-party solutions. (3) Compensation differentials — advisors receive higher payouts on certain product types. We mitigate through supervisory review of product mix concentration. (4) Client referrals — the firm pays solicitor fees to CPAs and attorneys for client referrals. These arrangements are disclosed per Rule 206(4)-3. All conflicts are reviewed annually by the Chief Compliance Officer and reported to the Board.'),

('cmp-012', 'Form ADV Part 2A — Custody and Account Statements', 'FormADV', '2024-01-01',
'Client assets are held at qualified custodians (Pershing LLC and Charles Schwab & Co). Clients receive account statements directly from the custodian at least quarterly. These statements will reflect all positions, transactions, and advisory fees deducted. The firm also provides its own performance reports which may vary from custodian statements due to different calculation methodologies. Clients should compare the firms statements with custodian statements and report any discrepancies. The firm undergoes an annual surprise examination by our independent public accountant per SEC Rule 206(4)-2 to verify client assets. The firm does not have physical custody of client funds or securities. We have custody solely by virtue of our authority to deduct advisory fees directly from client accounts, which is disclosed and authorized in the advisory agreement.'),

('cmp-013', 'Proxy Voting Policy', 'ProxyVoting', '2024-02-01',
'The firm votes proxies on behalf of advisory clients in their best interest per our fiduciary duty under the Investment Advisers Act. Our proxy voting guidelines are: (1) Routine matters (auditor ratification, director elections for uncontested seats) — generally vote with management unless governance concerns identified, (2) Executive compensation — vote against if pay exceeds 3x peer median without corresponding outperformance, (3) Environmental/social proposals — evaluate on a case-by-case basis considering materiality to shareholder value, (4) Mergers and acquisitions — independent analysis of deal terms relative to intrinsic value estimate, (5) Anti-takeover provisions (poison pills, classified boards) — generally vote against as reducing shareholder rights. The firm utilizes ISS Proxy Advisory Services for research and vote execution. Clients may request copies of our complete voting record for their holdings. Conflicts of interest in proxy voting (e.g., where issuers are also clients) are escalated to the Proxy Voting Committee.'),

('cmp-014', 'Proxy Voting — ESG Integration Guidelines', 'ProxyVoting', '2024-02-01',
'For clients who have opted into ESG-integrated proxy voting, additional guidelines apply: (1) Climate-related proposals — support requests for climate risk disclosure aligned with TCFD framework when deemed material to long-term value, (2) Board diversity — support proposals for disclosure of board composition statistics and vote against nominating committee chairs where boards lack gender or ethnic diversity without adequate explanation, (3) Supply chain — support reasonable requests for human rights due diligence disclosure in high-risk industries, (4) Lobbying — support disclosure of political spending and lobbying activities where amounts are material. ESG proxy voting preferences must be documented in the clients Investment Policy Statement and confirmed annually. Clients may override any ESG guideline for specific votes by providing written instruction at least 5 business days prior to the vote deadline.'),

('cmp-015', 'Client Agreement — Standard Advisory Terms', 'ClientAgreement', '2024-01-01',
'The Investment Advisory Agreement establishes the terms under which the firm provides advisory services. Key provisions include: (1) Discretionary authority — the firm manages client assets on a fully discretionary basis, meaning we may execute transactions without prior client approval, subject to the Investment Policy Statement constraints, (2) Fee schedule — annual advisory fee based on tiered AUM breakpoints: first $1M at 1.00%, $1M-$5M at 0.80%, $5M-$10M at 0.60%, above $10M at 0.40%, (3) Billing frequency — fees calculated and deducted quarterly in arrears based on average daily balance, (4) Termination — either party may terminate with 30 days written notice; fees prorated to termination date, (5) Arbitration — disputes resolved through FINRA arbitration, (6) Assignment — agreement may not be assigned without client consent per Section 205 of the Advisers Act.'),

('cmp-016', 'Client Agreement — Fee Schedule and Breakpoints', 'ClientAgreement', '2024-01-01',
'Advisory fees are assessed on a tiered basis applied to total household assets under management. Fee schedule: Tier 1 (first $500K): 1.25%, Tier 2 ($500K-$1M): 1.00%, Tier 3 ($1M-$3M): 0.85%, Tier 4 ($3M-$5M): 0.70%, Tier 5 ($5M-$10M): 0.55%, Tier 6 ($10M-$25M): 0.40%, Tier 7 ($25M+): negotiable, minimum 0.25%. Household aggregation: Accounts of immediate family members (spouse, children, parents) may be aggregated for breakpoint purposes with written authorization. Minimum account size: $250,000 for standard advisory relationships. Minimum fee: $2,500 per quarter. Fee reductions are available for select client categories including firm employees (50% discount), charitable organizations (25% discount), and legacy relationships. Alternative fee structures (flat fee, hourly, performance-based) available for qualified clients meeting SEC requirements.'),

('cmp-017', 'Anti-Money Laundering — Customer Identification Program', 'AntiMoneyLaundering', '2024-04-01',
'The firms Customer Identification Program (CIP) is established pursuant to Section 326 of the USA PATRIOT Act and FINRA Rule 3310. For all new accounts, the firm must collect and verify: (1) Name, (2) Date of birth (individuals), (3) Address (residential or business), (4) Government-issued identification number (SSN for US persons, passport or alien ID for non-US persons). Verification procedures: Documentary verification requires unexpired government-issued photo ID. Non-documentary verification uses commercially available databases (LexisNexis, Equifax) to corroborate identity. For legal entity customers, the firm must also identify and verify beneficial owners owning 25% or more, and one individual with significant management control per FinCEN CDD Rule. Enhanced verification required for: non-US persons, high-risk jurisdictions (FATF grey list), and PEPs. Records retained for 5 years after account closure.'),

('cmp-018', 'Anti-Money Laundering — Suspicious Activity Reporting', 'AntiMoneyLaundering', '2024-04-01',
'All employees must report suspicious activity to the designated AML Compliance Officer (AMLCO) immediately upon detection. Suspicious activity indicators include: (1) transactions inconsistent with known business or investment profile, (2) structuring — multiple transactions below $10,000 to avoid CTR reporting, (3) rapid movement of funds without apparent business purpose, (4) reluctance to provide identification or beneficial ownership information, (5) transactions involving high-risk jurisdictions without documented business rationale, (6) unusual wire transfer patterns (multiple international transfers, funds from unknown sources). The AMLCO evaluates reports within 5 business days and files SARs with FinCEN as required (30 calendar days from detection). No employee may disclose SAR filing to the subject of the report (tipping off is a federal offense). Annual AML training required for all employees, with enhanced training for client-facing staff. Independent AML audit conducted annually per FINRA Rule 3310(c).'),

('cmp-019', 'Regulation Best Interest — Conflicts of Interest Obligation', 'RegBI', '2024-07-01',
'The Conflict of Interest Obligation under RegBI requires the firm to establish, maintain, and enforce written policies and procedures reasonably designed to: (1) Identify all conflicts of interest associated with recommendations to retail customers, (2) Disclose or eliminate all identified conflicts, (3) Mitigate conflicts that create incentives for associated persons to place their interests ahead of the customers interest. Specifically, the firm must address: compensation arrangements that could incentivize recommendations of one product over another, sales contests or quotas, proprietary product preferences, and revenue sharing arrangements. Mitigation measures include: eliminating sales contests tied to specific products, implementing product-neutral compensation grids, requiring supervisory review of concentrated proprietary product recommendations, and maintaining a restricted products list for high-conflict situations. The Conflicts Committee reviews all identified conflicts quarterly and reports to the Board annually.'),

('cmp-020', 'Regulation Best Interest — Documentation Requirements', 'RegBI', '2024-07-01',
'All RegBI-covered recommendations require contemporaneous documentation sufficient to demonstrate compliance with the Care, Disclosure, Conflict of Interest, and Compliance Obligations. Required documentation elements: (1) Recommendation details — security, quantity, direction, and rationale, (2) Customer investment profile — verified within 12 months of recommendation, (3) Reasonable basis analysis — why the recommendation is in the customers best interest considering alternatives, (4) Cost analysis — comparison of costs relative to reasonably available alternatives, (5) Quantitative analysis — if series of transactions, documentation that frequency is not excessive, (6) Conflict disclosure — confirmation that Form CRS and applicable conflict disclosures were delivered. Documentation must be created no later than end of business day of recommendation. Records maintained per SEC Rule 17a-4 (6 years, first 2 in easily accessible location). Supervisory review of RegBI documentation: sampled at minimum 10% of recommendations monthly by the designated supervising principal.')
WHERE NOT EXISTS (SELECT 1 FROM BNK.WEALTH_MGMT.COMPLIANCE_DOCS LIMIT 1);

-- =============================================================================
-- WM_CLIENTS (100,000 rows)
-- =============================================================================
INSERT INTO BNK.WEALTH_MGMT.WM_CLIENTS
WITH raw_data AS (
    SELECT
        UUID_STRING() AS client_id,
        ARRAY_CONSTRUCT('James','Robert','Michael','William','David','Richard','Joseph','Thomas','Charles','Christopher','Daniel','Matthew','Anthony','Mark','Andrew','Steven','Paul','Joshua','Kenneth','Brian','Sarah','Jennifer','Jessica','Emily','Elizabeth','Ashley','Megan','Hannah','Samantha','Lauren','Rachel','Katherine','Nicole','Stephanie','Amanda','Victoria','Olivia','Catherine','Natalie','Margaret')[UNIFORM(0,39,RANDOM())]::VARCHAR AS first_name,
        ARRAY_CONSTRUCT('Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Rodriguez','Martinez','Anderson','Taylor','Thomas','Moore','Jackson','Martin','Lee','Thompson','White','Harris','Clark','Lewis','Robinson','Walker','Young','Hall','Allen','King','Wright','Scott','Adams','Nelson','Hill','Baker','Green')[UNIFORM(0,34,RANDOM())]::VARCHAR AS last_name,
        'adv-' || LPAD(UNIFORM(1,50,RANDOM())::VARCHAR, 3, '0') AS advisor_id,
        UNIFORM(1,100,RANDOM()) AS segment_rand,
        UNIFORM(1,100,RANDOM()) AS risk_rand,
        UNIFORM(1,100,RANDOM()) AS obj_rand,
        DATEADD('day', -UNIFORM(30, 3650, RANDOM()), CURRENT_DATE()) AS onboarding_date,
        DATEADD('day', -UNIFORM(365, 7300, RANDOM()), CURRENT_DATE()) AS relationship_start_date,
        UNIFORM(1,100,RANDOM()) AS status_rand
    FROM TABLE(GENERATOR(ROWCOUNT => 100000))
)
SELECT
    client_id,
    first_name,
    last_name,
    advisor_id,
    CASE WHEN segment_rand <= 40 THEN 'MassAffluent' WHEN segment_rand <= 75 THEN 'HNWI' WHEN segment_rand <= 95 THEN 'UHNWI' ELSE 'Institutional' END AS segment,
    CASE
        WHEN segment_rand <= 40 THEN UNIFORM(250000, 999999, RANDOM())
        WHEN segment_rand <= 75 THEN UNIFORM(1000000, 9999999, RANDOM())
        WHEN segment_rand <= 95 THEN UNIFORM(10000000, 99999999, RANDOM())
        ELSE UNIFORM(50000000, 500000000, RANDOM())
    END::DECIMAL(18,2) AS total_aum,
    CASE WHEN risk_rand <= 25 THEN 'Conservative' WHEN risk_rand <= 55 THEN 'Moderate' WHEN risk_rand <= 85 THEN 'Aggressive' ELSE 'VeryAggressive' END AS risk_tolerance,
    CASE WHEN obj_rand <= 30 THEN 'Growth' WHEN obj_rand <= 50 THEN 'Income' WHEN obj_rand <= 75 THEN 'Balanced' WHEN obj_rand <= 90 THEN 'Preservation' ELSE 'Speculation' END AS investment_objective,
    ARRAY_CONSTRUCT('Taxable','Taxable','Taxable','TaxExempt','Qualified','Qualified')[UNIFORM(0,5,RANDOM())]::VARCHAR AS tax_status,
    onboarding_date,
    relationship_start_date,
    CASE WHEN status_rand <= 80 THEN 'Active' WHEN status_rand <= 92 THEN 'Inactive' WHEN status_rand <= 98 THEN 'Closed' ELSE 'Pending' END AS status
FROM raw_data;

-- =============================================================================
-- PORTFOLIOS (150,000 rows)
-- =============================================================================
INSERT INTO BNK.WEALTH_MGMT.PORTFOLIOS
SELECT
    UUID_STRING() AS portfolio_id,
    (SELECT client_id FROM BNK.WEALTH_MGMT.WM_CLIENTS SAMPLE (150000 ROWS) LIMIT 1) AS client_id_placeholder,
    ARRAY_CONSTRUCT('Growth Equity','Core Equity','Balanced Portfolio','Fixed Income','International Growth','Dividend Income','Tax-Efficient','Multi-Asset','Alternative Strategies','Index Core','Retirement Income','Capital Preservation')[UNIFORM(0,11,RANDOM())]::VARCHAR AS portfolio_name,
    ARRAY_CONSTRUCT('Equity','Equity','FixedIncome','Balanced','Alternative','MultiAsset')[UNIFORM(0,5,RANDOM())]::VARCHAR AS portfolio_type,
    ARRAY_CONSTRUCT('ActiveGrowth','ValueIncome','IndexCore','TacticalAllocation','AbsoluteReturn')[UNIFORM(0,4,RANDOM())]::VARCHAR AS strategy,
    DATEADD('day', -UNIFORM(90, 5475, RANDOM()), CURRENT_DATE()) AS inception_date,
    ARRAY_CONSTRUCT('SP500','SP500','MSCIWORLD','BARCLAYSAGG','HFRI','Custom')[UNIFORM(0,5,RANDOM())]::VARCHAR AS benchmark,
    (UNIFORM(400, 1200, RANDOM()) / 100.0)::DECIMAL(5,2) AS target_return,
    ARRAY_CONSTRUCT(25,50,60,75,85,100,125,150)[UNIFORM(0,7,RANDOM())]::INTEGER AS management_fee_bps
FROM TABLE(GENERATOR(ROWCOUNT => 150000));

-- Fix client_id references to point to actual clients
UPDATE BNK.WEALTH_MGMT.PORTFOLIOS p
SET client_id = (
    SELECT c.client_id
    FROM BNK.WEALTH_MGMT.WM_CLIENTS c
    WHERE c.status = 'Active'
    ORDER BY RANDOM()
    LIMIT 1
)
WHERE client_id = client_id;

-- Better approach: re-insert with proper FK
DELETE FROM BNK.WEALTH_MGMT.PORTFOLIOS;
INSERT INTO BNK.WEALTH_MGMT.PORTFOLIOS
WITH client_pool AS (
    SELECT client_id, ROW_NUMBER() OVER (ORDER BY RANDOM()) AS rn
    FROM BNK.WEALTH_MGMT.WM_CLIENTS
    WHERE status = 'Active'
)
SELECT
    UUID_STRING() AS portfolio_id,
    (SELECT client_id FROM client_pool WHERE rn = MOD(SEQ4(), (SELECT COUNT(*) FROM client_pool)) + 1) AS client_id,
    ARRAY_CONSTRUCT('Growth Equity','Core Equity','Balanced Portfolio','Fixed Income','International Growth','Dividend Income','Tax-Efficient','Multi-Asset','Alternative Strategies','Index Core','Retirement Income','Capital Preservation')[UNIFORM(0,11,RANDOM())]::VARCHAR AS portfolio_name,
    ARRAY_CONSTRUCT('Equity','Equity','FixedIncome','Balanced','Alternative','MultiAsset')[UNIFORM(0,5,RANDOM())]::VARCHAR AS portfolio_type,
    ARRAY_CONSTRUCT('ActiveGrowth','ValueIncome','IndexCore','TacticalAllocation','AbsoluteReturn')[UNIFORM(0,4,RANDOM())]::VARCHAR AS strategy,
    DATEADD('day', -UNIFORM(90, 5475, RANDOM()), CURRENT_DATE()) AS inception_date,
    ARRAY_CONSTRUCT('SP500','SP500','MSCIWORLD','BARCLAYSAGG','HFRI','Custom')[UNIFORM(0,5,RANDOM())]::VARCHAR AS benchmark,
    (UNIFORM(400, 1200, RANDOM()) / 100.0)::DECIMAL(5,2) AS target_return,
    ARRAY_CONSTRUCT(25,50,60,75,85,100,125,150)[UNIFORM(0,7,RANDOM())]::INTEGER AS management_fee_bps
FROM TABLE(GENERATOR(ROWCOUNT => 150000));

-- =============================================================================
-- HOLDINGS (1,000,000 rows)
-- =============================================================================
INSERT INTO BNK.WEALTH_MGMT.HOLDINGS
WITH portfolio_pool AS (
    SELECT portfolio_id, ROW_NUMBER() OVER (ORDER BY RANDOM()) AS rn, COUNT(*) OVER () AS total_count
    FROM BNK.WEALTH_MGMT.PORTFOLIOS
),
ticker_data AS (
    SELECT column1 AS ticker, column2 AS security_name, column3 AS asset_class, column4 AS sector
    FROM VALUES
        ('AAPL','Apple Inc','USEquity','Technology'),
        ('MSFT','Microsoft Corp','USEquity','Technology'),
        ('GOOGL','Alphabet Inc','USEquity','Technology'),
        ('AMZN','Amazon.com Inc','USEquity','Technology'),
        ('NVDA','NVIDIA Corp','USEquity','Technology'),
        ('META','Meta Platforms Inc','USEquity','CommServices'),
        ('TSLA','Tesla Inc','USEquity','ConsumerDiscretionary'),
        ('CRM','Salesforce Inc','USEquity','Technology'),
        ('JPM','JPMorgan Chase','USEquity','Financials'),
        ('BAC','Bank of America','USEquity','Financials'),
        ('WFC','Wells Fargo','USEquity','Financials'),
        ('GS','Goldman Sachs','USEquity','Financials'),
        ('BLK','BlackRock Inc','USEquity','Financials'),
        ('JNJ','Johnson & Johnson','USEquity','Healthcare'),
        ('PFE','Pfizer Inc','USEquity','Healthcare'),
        ('UNH','UnitedHealth Group','USEquity','Healthcare'),
        ('ABBV','AbbVie Inc','USEquity','Healthcare'),
        ('LLY','Eli Lilly','USEquity','Healthcare'),
        ('MRK','Merck & Co','USEquity','Healthcare'),
        ('XOM','ExxonMobil','USEquity','Energy'),
        ('CVX','Chevron Corp','USEquity','Energy'),
        ('COP','ConocoPhillips','USEquity','Energy'),
        ('HD','Home Depot','USEquity','ConsumerDiscretionary'),
        ('NKE','Nike Inc','USEquity','ConsumerDiscretionary'),
        ('COST','Costco Wholesale','USEquity','ConsumerDiscretionary'),
        ('CAT','Caterpillar Inc','USEquity','Industrials'),
        ('HON','Honeywell Intl','USEquity','Industrials'),
        ('GE','GE Aerospace','USEquity','Industrials'),
        ('NEE','NextEra Energy','USEquity','Utilities'),
        ('DUK','Duke Energy','USEquity','Utilities'),
        ('AMT','American Tower','USEquity','RealEstate'),
        ('DIS','Walt Disney','USEquity','CommServices')
)
SELECT
    UUID_STRING() AS holding_id,
    (SELECT portfolio_id FROM portfolio_pool WHERE rn = MOD(SEQ4(), total_count) + 1 LIMIT 1) AS portfolio_id,
    t.ticker,
    t.security_name,
    t.asset_class,
    t.sector,
    UNIFORM(10, 5000, RANDOM())::DECIMAL(18,4) AS quantity,
    UNIFORM(5000, 500000, RANDOM())::DECIMAL(18,2) AS market_value,
    UNIFORM(4000, 480000, RANDOM())::DECIMAL(18,2) AS cost_basis,
    (UNIFORM(100, 2500, RANDOM()) / 100.0)::DECIMAL(7,4) AS weight_pct,
    0::DECIMAL(18,2) AS unrealized_gain_loss,
    DATEADD('day', -UNIFORM(0, 30, RANDOM()), CURRENT_DATE()) AS as_of_date
FROM TABLE(GENERATOR(ROWCOUNT => 1000000)) g,
    LATERAL (SELECT * FROM ticker_data WHERE ticker = (SELECT ticker FROM ticker_data ORDER BY RANDOM() LIMIT 1)) t;

-- Update unrealized_gain_loss as derived field
UPDATE BNK.WEALTH_MGMT.HOLDINGS SET unrealized_gain_loss = market_value - cost_basis;

-- =============================================================================
-- MARKET_DATA (500,000 rows)
-- =============================================================================
INSERT INTO BNK.WEALTH_MGMT.MARKET_DATA
WITH tickers AS (
    SELECT column1 AS ticker, column2 AS base_price, column3 AS sector
    FROM VALUES
        ('AAPL',195.0,'Technology'),('MSFT',415.0,'Technology'),('GOOGL',160.0,'Technology'),
        ('AMZN',190.0,'Technology'),('NVDA',700.0,'Technology'),('META',450.0,'CommServices'),
        ('TSLA',220.0,'ConsumerDiscretionary'),('CRM',285.0,'Technology'),('JPM',195.0,'Financials'),
        ('BAC',37.0,'Financials'),('WFC',57.0,'Financials'),('GS',440.0,'Financials'),
        ('BLK',825.0,'Financials'),('JNJ',155.0,'Healthcare'),('PFE',28.0,'Healthcare'),
        ('UNH',530.0,'Healthcare'),('ABBV',175.0,'Healthcare'),('LLY',800.0,'Healthcare'),
        ('MRK',122.0,'Healthcare'),('XOM',110.0,'Energy'),('CVX',155.0,'Energy'),
        ('COP',115.0,'Energy'),('HD',370.0,'ConsumerDiscretionary'),('NKE',95.0,'ConsumerDiscretionary'),
        ('COST',740.0,'ConsumerDiscretionary'),('CAT',330.0,'Industrials'),('HON',205.0,'Industrials'),
        ('GE',160.0,'Industrials'),('NEE',72.0,'Utilities'),('DUK',102.0,'Utilities'),
        ('AMT',215.0,'RealEstate'),('DIS',98.0,'CommServices')
),
date_series AS (
    SELECT DATEADD('day', -SEQ4(), CURRENT_DATE()) AS trade_date
    FROM TABLE(GENERATOR(ROWCOUNT => 504))
    WHERE DAYOFWEEK(DATEADD('day', -SEQ4(), CURRENT_DATE())) NOT IN (0, 6)
)
SELECT
    t.ticker,
    d.trade_date,
    (t.base_price * (1 + (UNIFORM(-500, 500, RANDOM()) / 10000.0)))::DECIMAL(12,4) AS open_price,
    (t.base_price * (1 + (UNIFORM(-500, 500, RANDOM()) / 10000.0)))::DECIMAL(12,4) AS close_price,
    (t.base_price * (1 + (UNIFORM(0, 800, RANDOM()) / 10000.0)))::DECIMAL(12,4) AS high_price,
    (t.base_price * (1 - (UNIFORM(0, 800, RANDOM()) / 10000.0)))::DECIMAL(12,4) AS low_price,
    UNIFORM(1000000, 80000000, RANDOM())::BIGINT AS volume,
    (t.base_price * UNIFORM(50000000, 3000000000, RANDOM()) / 1000000.0)::DECIMAL(18,2) AS market_cap,
    UNIFORM(800, 6000, RANDOM()) / 100.0::DECIMAL(8,2) AS pe_ratio,
    UNIFORM(0, 500, RANDOM()) / 10000.0::DECIMAL(6,4) AS dividend_yield,
    t.sector
FROM tickers t
CROSS JOIN date_series d;

-- =============================================================================
-- TRADES (500,000 rows)
-- =============================================================================
INSERT INTO BNK.WEALTH_MGMT.TRADES
SELECT
    UUID_STRING() AS trade_id,
    (SELECT portfolio_id FROM BNK.WEALTH_MGMT.PORTFOLIOS ORDER BY RANDOM() LIMIT 1) AS portfolio_id,
    ARRAY_CONSTRUCT('AAPL','MSFT','GOOGL','AMZN','NVDA','META','TSLA','JPM','BAC','JNJ','PFE','UNH','XOM','CVX','HD','COST','CAT','NEE','GS','BLK','LLY','MRK','NKE','HON','DIS')[UNIFORM(0,24,RANDOM())]::VARCHAR AS ticker,
    CASE WHEN UNIFORM(1,100,RANDOM()) <= 55 THEN 'Buy' ELSE 'Sell' END AS direction,
    UNIFORM(5, 2000, RANDOM())::DECIMAL(18,4) AS quantity,
    UNIFORM(2000, 90000, RANDOM()) / 100.0::DECIMAL(12,4) AS price,
    0::DECIMAL(18,2) AS total_value,
    DATEADD('day', -UNIFORM(0, 730, RANDOM()), CURRENT_DATE()) AS trade_date,
    DATEADD('day', -UNIFORM(0, 730, RANDOM()) + 1, CURRENT_DATE()) AS settlement_date,
    ARRAY_CONSTRUCT('Market','Market','Market','Limit','Limit','Stop')[UNIFORM(0,5,RANDOM())]::VARCHAR AS order_type,
    ARRAY_CONSTRUCT('Rebalance','Rebalance','TaxLoss','ClientRequest','ClientRequest','ModelChange','Dividend')[UNIFORM(0,6,RANDOM())]::VARCHAR AS reason
FROM TABLE(GENERATOR(ROWCOUNT => 500000));

UPDATE BNK.WEALTH_MGMT.TRADES SET total_value = quantity * price;
UPDATE BNK.WEALTH_MGMT.TRADES SET settlement_date = DATEADD('day', 1, trade_date) WHERE settlement_date < trade_date;

-- =============================================================================
-- CLIENT_NOTES (100,000 rows)
-- =============================================================================
INSERT INTO BNK.WEALTH_MGMT.CLIENT_NOTES
SELECT
    UUID_STRING() AS note_id,
    (SELECT client_id FROM BNK.WEALTH_MGMT.WM_CLIENTS ORDER BY RANDOM() LIMIT 1) AS client_id,
    'adv-' || LPAD(UNIFORM(1,50,RANDOM())::VARCHAR, 3, '0') AS advisor_id,
    DATEADD('day', -UNIFORM(0, 1095, RANDOM()), CURRENT_DATE()) AS note_date,
    ARRAY_CONSTRUCT('Meeting','Meeting','Call','Call','Email','Review','Rebalance')[UNIFORM(0,6,RANDOM())]::VARCHAR AS note_type,
    ARRAY_CONSTRUCT(
        'Discussed portfolio rebalancing strategy. Client is comfortable with current allocation but wants to increase international exposure by 5%. Will implement next quarter after tax-loss harvesting review.',
        'Annual review meeting completed. Portfolio returned 12.3% YTD vs benchmark 10.8%. Client pleased with performance. Discussed upcoming retirement timeline and potential shift toward income-generating assets.',
        'Client called regarding recent market volatility. Reassured that portfolio is well-diversified and aligned with long-term objectives. No changes requested. Reminded of quarterly review next month.',
        'Discussed tax-loss harvesting opportunities in the technology sleeve. Identified $45K in unrealized losses that can offset capital gains from Q1 rebalancing. Client approved execution.',
        'Quarterly review completed. Portfolio is tracking 150bps ahead of benchmark YTD. Discussed increasing allocation to alternatives from 8% to 12% to reduce correlation with equity markets.',
        'Client expressed interest in ESG integration for their taxable account. Reviewed available sustainable equity strategies and impact on expected return. Will present formal proposal next meeting.',
        'Meeting to discuss estate planning implications of new trust structure. Coordinating with clients attorney on asset titling. Need to update beneficiary designations on IRA accounts.',
        'Client requested review of fee structure given AUM growth past $5M threshold. Confirmed tier breakpoint reduces fee from 85bps to 70bps effective next billing cycle. Client satisfied.',
        'Discussed concentration risk in NVDA position (currently 12% of portfolio). Client acknowledges risk but wants to maintain position through next earnings. Set stop-loss at 15% below current price.',
        'Rebalance discussion following significant equity market rally. Portfolio equity allocation drifted to 72% vs 65% target. Client approved systematic rebalancing over 30 days to minimize market impact.'
    )[UNIFORM(0,9,RANDOM())]::VARCHAR AS note_text
FROM TABLE(GENERATOR(ROWCOUNT => 100000));
