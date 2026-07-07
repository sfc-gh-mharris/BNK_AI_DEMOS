"""
Lending Analytics - Data Generation Logic Documentation
========================================================

This script documents the data generation methodology and distribution choices
for the BNK.LENDING schema synthetic data. The actual data generation is performed
via Snowflake SQL GENERATOR functions in 02_data.sql, but this Python script
explains the statistical reasoning and can be used for local testing/validation.

Database: BNK
Schema: BNK.LENDING
Target Warehouse: BNK_WH
"""

import numpy as np
from dataclasses import dataclass
from typing import List, Tuple


# =============================================================================
# DISTRIBUTION PARAMETERS
# =============================================================================

@dataclass
class BorrowerDistributions:
    """
    Statistical distributions for borrower attribute generation.
    
    These parameters are chosen to mirror real US mortgage borrower demographics
    based on publicly available HMDA data and FICO score distributions.
    """
    
    # Credit Score: Normal distribution
    # Rationale: FICO scores in the mortgage population are approximately normal,
    # centered higher than general population (selection bias - people who qualify
    # for mortgages have better credit). Mean of 720 with std 60 gives:
    #   - ~2.5% below 600 (subprime, mostly excluded)
    #   - ~16% between 600-660 (near-prime)
    #   - ~34% between 660-720 (prime)
    #   - ~34% between 720-780 (super-prime)
    #   - ~14% above 780 (exceptional)
    credit_score_mean: float = 720.0
    credit_score_std: float = 60.0
    credit_score_min: int = 300
    credit_score_max: int = 850
    
    # Annual Income: Lognormal distribution
    # Rationale: Income is classically lognormal. Parameters chosen to produce:
    #   - Median: ~$85,000 (typical mortgage borrower)
    #   - Mean: ~$95,000 (right-skewed by high earners)
    #   - 10th percentile: ~$45,000
    #   - 90th percentile: ~$175,000
    # ln(85000) ≈ 11.35, sigma=0.5 gives good spread
    income_log_mean: float = 11.35  # exp(11.35) ≈ $85,000
    income_log_std: float = 0.5
    income_min: float = 30000.0
    income_max: float = 500000.0
    
    # Age: Uniform 25-75
    # Rationale: Mortgage borrowers span working-age adults through retirees.
    # True distribution is slightly bell-shaped with peak at 35-45 but uniform
    # is simpler and still realistic for demo purposes.
    age_min: int = 25
    age_max: int = 75
    
    # Employment Status: Categorical
    # Rationale: Based on labor force statistics for homeowners
    employment_weights: dict = None
    
    # Region: Weighted by US population
    # Rationale: Approximate Census region distribution
    region_weights: dict = None
    
    def __post_init__(self):
        self.employment_weights = {
            'Employed': 0.70,       # Majority are traditional W-2 employees
            'SelfEmployed': 0.15,   # Growing segment, esp. in higher income tiers
            'Retired': 0.10,        # Retirees with existing mortgages or reverse mtg
            'Unemployed': 0.05,     # Small slice - inherited loans or recent job loss
        }
        self.region_weights = {
            'Northeast': 0.18,   # NY, NJ, PA, CT, MA, NH
            'Southeast': 0.20,   # FL, GA, NC, VA, TN, SC, AL, MS
            'Midwest': 0.20,     # IL, OH, MI, IN, MN, WI
            'Southwest': 0.14,   # TX, AZ, NM, OK
            'West': 0.16,        # CO, UT, NV, MT
            'Pacific': 0.12,     # CA, WA, OR
        }


@dataclass
class MortgageDistributions:
    """
    Statistical distributions for mortgage loan generation.
    
    Key correlations maintained:
    - Higher income → larger loan amounts (2.5x-6x income)
    - Lower credit score → higher interest rate (risk-based pricing)
    - Proper LTV calculation from loan/property value
    - DTI within regulatory bounds (20-45%)
    """
    
    # Loan-to-Value Ratio: Uniform 60-95%
    # Rationale: 
    #   - Minimum 60% (borrowers with large down payments or equity)
    #   - Maximum 95% (FHA with 3.5% down ≈ 96.5%, conventional 97%)
    #   - Most cluster around 75-85% for conventional loans
    ltv_min: float = 60.0
    ltv_max: float = 95.0
    
    # Interest Rate: Inversely correlated with credit score
    # Formula: rate = 8.5 - 0.009 * (credit_score - 300) + noise
    # This produces:
    #   - FICO 750: ~4.4% (excellent credit)
    #   - FICO 720: ~4.7% (good credit)
    #   - FICO 680: ~5.1% (fair credit)
    #   - FICO 620: ~5.6% (minimum qualifying)
    #   Plus random noise of ±0.5% for market conditions
    rate_base: float = 8.5
    rate_credit_factor: float = 0.009  # Rate decrease per credit score point
    rate_min: float = 3.0
    rate_max: float = 8.0
    
    # Debt-to-Income: Uniform 20-45%
    # Rationale:
    #   - QM rule maximum: 43% (with exceptions up to 50%)
    #   - Minimum realistic DTI: ~20% (small loan relative to income)
    #   - Most borrowers cluster 28-38% per underwriting guidelines
    dti_min: float = 20.0
    dti_max: float = 45.0
    
    # Term distribution
    term_weights: dict = None
    
    # Loan type distribution
    loan_type_weights: dict = None
    
    # Status distribution
    status_weights: dict = None
    
    def __post_init__(self):
        self.term_weights = {
            30: 0.60,   # Majority choose 30-year for lower monthly payment
            15: 0.25,   # Popular for refinances and higher-income borrowers
            20: 0.15,   # Middle ground, growing in popularity
        }
        self.loan_type_weights = {
            'Fixed': 0.50,    # Dominant product type
            'ARM': 0.15,      # Popular when rates are high (rate differential)
            'FHA': 0.15,      # First-time buyers, lower credit
            'VA': 0.10,       # Military/veterans
            'Jumbo': 0.10,    # High-value properties
        }
        self.status_weights = {
            'Current': 0.750,       # Performing loans
            'PaidOff': 0.070,       # Matured or sold property
            'Refinanced': 0.060,    # Refinanced with us or competitor
            'Delinquent30': 0.040,  # 30-day delinquent
            'Delinquent60': 0.030,  # 60-day delinquent
            'Delinquent90': 0.025,  # 90-day delinquent
            'Default': 0.025,       # In foreclosure/loss mitigation
        }


@dataclass
class PaymentDistributions:
    """
    Payment behavior distributions.
    
    Based on MBA National Delinquency Survey historical averages:
    - ~95% of mortgage payments are made on time
    - ~3% are late (received but after due date)
    - ~1.5% are partial (less than full amount)
    - ~0.5% are missed entirely
    """
    status_weights: dict = None
    
    def __post_init__(self):
        self.status_weights = {
            'OnTime': 0.950,    # Vast majority pay on time
            'Late': 0.030,      # Full payment but after due date
            'Partial': 0.015,   # Some amount paid but not full
            'Missed': 0.005,    # No payment received
        }


@dataclass
class RiskScoreDistributions:
    """
    Risk model output distributions.
    
    Probability of Default (PD):
    - Exponential decay: PD = 0.5 * exp(-0.008 * (credit_score - 300))
    - This produces realistic PD values:
        - FICO 750: PD ≈ 1.3% (low risk)
        - FICO 700: PD ≈ 2.2% (moderate risk)
        - FICO 650: PD ≈ 3.7% (elevated risk)
        - FICO 600: PD ≈ 6.2% (high risk)
        - FICO 550: PD ≈ 10.4% (very high risk)
    
    Loss Given Default (LGD):
    - Centered at 35% with ±20% variation
    - Higher for high-LTV loans (less equity cushion)
    - Historical average for US residential mortgages: 25-45%
    
    Refinance Probability:
    - Higher for borrowers with:
        - Good/improving credit scores
        - Current rates significantly above market
        - High equity (low LTV)
        - Approaching ARM adjustment dates
    """
    pd_base: float = 0.5
    pd_decay_rate: float = 0.008  # Exponential decay per credit score point
    
    lgd_mean: float = 0.35
    lgd_variation: float = 0.20
    
    refinance_prob_credit_factor: float = 1.0 / 500.0  # Linear with credit score


# =============================================================================
# PROPERTY VALUE CORRELATION
# =============================================================================

def calculate_property_value(annual_income: float, multiplier_range: Tuple[float, float] = (2.5, 6.0)) -> float:
    """
    Property value correlates with income.
    
    Rationale: Housing affordability guidelines suggest homes cost 2.5-5x income.
    We extend to 6x to capture high-cost markets (CA, NY, etc.) where borrowers
    stretch more. The multiplier is randomized per borrower:
    
    - 2.5x: Conservative buyer or low-cost market
    - 4.0x: Typical buyer in moderate market
    - 6.0x: Stretch buyer in high-cost market (often Jumbo loan territory)
    """
    multiplier = np.random.uniform(*multiplier_range)
    return round(annual_income * multiplier, -3)  # Round to nearest $1000


def calculate_interest_rate(credit_score: int, loan_type: str = 'Fixed') -> float:
    """
    Interest rate is primarily driven by credit score (risk-based pricing).
    
    The formula models LLPA (Loan-Level Price Adjustment) structure used by
    Fannie Mae and Freddie Mac, where each credit tier adds basis points:
    
    base_rate (market rate) - credit_benefit + loan_type_adjustment + noise
    
    ARM loans get a small discount (initial teaser), FHA slightly higher
    (MIP effectively increases cost), Jumbo slightly higher (liquidity premium).
    """
    base = 8.5 - 0.009 * (credit_score - 300)
    noise = np.random.normal(0, 0.25)
    
    type_adj = {
        'Fixed': 0.0,
        'ARM': -0.75,     # Initial rate lower than fixed
        'FHA': +0.25,     # Higher effective rate due to MIP
        'VA': -0.125,     # VA funding fee priced in, slightly better rate
        'Jumbo': +0.375,  # Liquidity premium for non-conforming
    }
    
    rate = base + type_adj.get(loan_type, 0.0) + noise
    return round(max(3.0, min(8.0, rate)), 3)


# =============================================================================
# SIGNAL GENERATION LOGIC
# =============================================================================

REFINANCE_SIGNAL_TYPES = {
    'RateShop': {
        'weight': 0.25,
        'description': 'Credit inquiries from other mortgage lenders detected',
        'typical_confidence': (0.60, 0.95),
    },
    'CompetitorOffer': {
        'weight': 0.20,
        'description': 'Competitor marketing or pre-qualification detected',
        'typical_confidence': (0.50, 0.85),
    },
    'PaymentStress': {
        'weight': 0.15,
        'description': 'Payment behavior suggesting rate sensitivity',
        'typical_confidence': (0.40, 0.75),
    },
    'LifeEvent': {
        'weight': 0.15,
        'description': 'Life event detected that may trigger refinance consideration',
        'typical_confidence': (0.45, 0.80),
    },
    'CreditScoreChange': {
        'weight': 0.15,
        'description': 'Significant FICO score improvement enabling better terms',
        'typical_confidence': (0.70, 0.95),
    },
    'PropertyValueIncrease': {
        'weight': 0.10,
        'description': 'AVM/appraisal indicates equity gain enabling PMI removal or better LTV tier',
        'typical_confidence': (0.65, 0.90),
    },
}


# =============================================================================
# INTERACTION HISTORY TEMPLATES
# =============================================================================

INTERACTION_TOPICS = {
    'PaymentInquiry': [
        'Borrower called to confirm receipt of last monthly payment. Verified payment posted. No issues found.',
        'Borrower inquired about autopay setup. Walked through enrollment process and confirmed bank account details.',
        'Borrower reported duplicate payment charged to checking account. Investigated and confirmed single payment processed.',
        'Borrower asked about applying extra principal payment. Explained process and confirmed additional principal would not advance due date.',
        'Borrower called regarding payment not reflected in online portal. Confirmed 2-business-day processing delay.',
    ],
    'RateQuestion': [
        'Borrower inquired about current refinance rates. Quoted current 30-year fixed. Borrower expressed interest.',
        'Borrower asked if ARM rate adjustment is coming. Confirmed next adjustment date and explained index plus margin calculation.',
        'Borrower comparing our rates to competitor offer. Discussed total cost comparison including closing costs.',
        'Borrower asked about rate lock process for refinance. Explained 30-day and 45-day lock options.',
        'Borrower asked why their rate is higher than advertised. Explained LLPA adjustments based on credit and LTV.',
    ],
    'HardshipRequest': [
        'Borrower reported job loss and inability to make next payment. Discussed forbearance options. Mailed hardship application.',
        'Borrower experiencing medical emergency with significant costs. Explained forbearance program. Started loss mitigation intake.',
        'Borrower going through divorce and requesting temporary payment reduction. Discussed forbearance and modification options.',
        'Follow-up call on existing forbearance case. Borrower confirmed continued hardship. Extended forbearance per policy.',
        'Borrower requesting disaster forbearance following recent flooding. Confirmed property in declared disaster area.',
    ],
    'RefinanceInquiry': [
        'Borrower interested in cash-out refinance to consolidate debt. Discussed LTV requirements. Transferred to refinance specialist.',
        'Borrower asking about streamline refinance options. Confirmed eligibility. Quoted reduced documentation requirements.',
        'Borrower wants to refinance from ARM to fixed rate. Ran comparison showing savings. Borrower requested application.',
        'Borrower inquired about refinancing to remove PMI. Current LTV supports cancellation. Discussed options.',
        'Borrower considering refinance to shorten term from 30 to 15 years. Ran amortization comparison showing savings.',
    ],
    'EscrowQuestion': [
        'Borrower received escrow analysis showing payment increase. Explained breakdown and offered 12-month spread option.',
        'Borrower asking why escrow increased. Explained insurance premium renewal increase. Suggested shopping for new policy.',
        'Borrower requesting escrow account removal. Confirmed eligibility. Processed waiver with rate adjustment per policy.',
        'Borrower reported receiving surplus escrow check. Verified annual analysis showed surplus. Account in good standing.',
        'Borrower confused about escrow shortage vs deficiency. Explained difference and offered lump-sum payoff option.',
    ],
    'PayoffRequest': [
        'Borrower requesting payoff quote for planned home sale. Generated 30-day payoff statement. Provided wire instructions.',
        'Borrower asked about partial payoff to reduce balance. Explained minimum requirements and that monthly payment unchanged.',
        'Borrower inheriting property and wants to pay off mortgage. Explained process and lien release timeline.',
        'Borrower refinancing elsewhere and needs payoff. Generated payoff good through 30 days. Provided wire instructions.',
        'Borrower asking about bi-weekly payment to accelerate payoff. Explained program. Enrolled in bi-weekly autopay.',
    ],
}


# =============================================================================
# ROW COUNT TARGETS
# =============================================================================

ROW_TARGETS = {
    'BORROWERS': 200_000,
    'MORTGAGES': 300_000,          # ~1.5 mortgages per borrower (some have multiple)
    'PAYMENTS': 1_000_000,         # ~3.3 payments per mortgage (sampling from history)
    'RISK_SCORES': 200_000,        # 1 per borrower (most recent score)
    'REFINANCE_SIGNALS': 50_000,   # ~25% of borrowers have active signals
    'LENDING_POLICIES': 28,        # Hand-crafted policy documents
    'INTERACTION_HISTORY': 200_000, # ~1 interaction per borrower on average
}


# =============================================================================
# VALIDATION CHECKS
# =============================================================================

def validate_distributions():
    """
    Run sanity checks on generated data distributions.
    Used for testing before deploying SQL generation.
    """
    np.random.seed(42)
    n = 10000
    
    # Credit scores
    scores = np.random.normal(720, 60, n).clip(300, 850).astype(int)
    print(f"Credit Score - Mean: {scores.mean():.0f}, Std: {scores.std():.0f}")
    print(f"  Below 620: {(scores < 620).mean()*100:.1f}%")
    print(f"  620-680: {((scores >= 620) & (scores < 680)).mean()*100:.1f}%")
    print(f"  680-740: {((scores >= 680) & (scores < 740)).mean()*100:.1f}%")
    print(f"  Above 740: {(scores >= 740).mean()*100:.1f}%")
    
    # Income
    incomes = np.random.lognormal(11.35, 0.5, n).clip(30000, 500000)
    print(f"\nIncome - Median: ${np.median(incomes):,.0f}, Mean: ${incomes.mean():,.0f}")
    print(f"  10th pctile: ${np.percentile(incomes, 10):,.0f}")
    print(f"  90th pctile: ${np.percentile(incomes, 90):,.0f}")
    
    # Interest rates (correlated with credit)
    rates = [calculate_interest_rate(s) for s in scores[:1000]]
    print(f"\nInterest Rate - Mean: {np.mean(rates):.2f}%, Std: {np.std(rates):.2f}%")
    
    # PD (correlated with credit)
    pds = 0.5 * np.exp(-0.008 * (scores - 300))
    pds = pds.clip(0.001, 0.95)
    print(f"\nProbability of Default - Mean: {pds.mean()*100:.2f}%, Median: {np.median(pds)*100:.2f}%")
    print(f"  FICO 750 avg PD: {pds[scores == 750].mean()*100:.2f}%" if (scores == 750).any() else "")
    print(f"  FICO 650 avg PD: {pds[scores == 650].mean()*100:.2f}%" if (scores == 650).any() else "")


if __name__ == '__main__':
    print("=" * 60)
    print("LENDING ANALYTICS - DATA DISTRIBUTION VALIDATION")
    print("=" * 60)
    validate_distributions()
    print("\n" + "=" * 60)
    print(f"Target row counts:")
    for table, count in ROW_TARGETS.items():
        print(f"  {table}: {count:,}")
    print("=" * 60)
