"""
KYC/AML Data Generation Logic — Documentation Script
=====================================================
NOT shared with customer. Internal reference for the synthetic data
generation approach used in 02_data.sql.

This script documents the data distributions, generation strategies,
and business logic behind the synthetic KYC/AML dataset.
"""

import random
import uuid
from datetime import date, timedelta
from typing import Dict, List, Tuple

# =============================================================================
# DISTRIBUTION CONSTANTS
# These match the GENERATOR-based SQL in 02_data.sql
# =============================================================================

# Client entity type distribution (70% Individual, 30% Corporate)
ENTITY_TYPE_WEIGHTS = {"Individual": 0.70, "Corporate": 0.30}

# Risk rating distribution
RISK_RATING_WEIGHTS = {
    "Low": 0.60,
    "Medium": 0.25,
    "High": 0.10,
    "PEP": 0.04,
    "Sanctioned": 0.01,
}

# Client status distribution
CLIENT_STATUS_WEIGHTS = {
    "Active": 0.80,
    "UnderReview": 0.10,
    "Restricted": 0.07,
    "Exited": 0.03,
}

# Case type distribution (equal weight)
CASE_TYPE_WEIGHTS = {
    "NewClient": 0.25,
    "PeriodicReview": 0.25,
    "TriggerEvent": 0.25,
    "EnhancedDueDiligence": 0.25,
}

# Case status distribution (equal weight across states)
CASE_STATUS_WEIGHTS = {
    "Open": 1 / 6,
    "InReview": 1 / 6,
    "PendingDocuments": 1 / 6,
    "Approved": 1 / 6,
    "Rejected": 1 / 6,
    "Escalated": 1 / 6,
}

# Document type distribution (equal weight)
DOC_TYPE_OPTIONS = [
    "Passport",
    "DriversLicense",
    "NationalID",
    "FinancialStatement",
    "UtilityBill",
    "CorporateRegistry",
    "BeneficialOwnership",
]

# Extraction status distribution (70% Completed, 10% Pending, 10% Processing, 10% Failed)
EXTRACTION_STATUS_WEIGHTS = {
    "Pending": 0.10,
    "Processing": 0.10,
    "Completed": 0.70,
    "Failed": 0.10,
}

# Alert type distribution (equal weight)
ALERT_TYPE_OPTIONS = [
    "SanctionsHit",
    "AdverseMedia",
    "UnusualActivity",
    "DocumentExpiry",
    "RiskRatingChange",
]

# Alert severity distribution (equal weight)
ALERT_SEVERITY_OPTIONS = ["Low", "Medium", "High", "Critical"]

# Alert status distribution (equal weight)
ALERT_STATUS_OPTIONS = ["New", "Assigned", "Investigating", "Resolved", "FalsePositive"]

# Match status distribution
MATCH_STATUS_WEIGHTS = {
    "Match": 0.70,
    "Partial": 0.15,
    "ManualReviewRequired": 0.10,
    "Mismatch": 0.05,
}

# =============================================================================
# NAME POOLS
# International names across US, UK, EU, APAC regions
# =============================================================================

FIRST_NAMES = {
    "US": ["James", "Mary", "Robert", "Patricia", "Michael", "Jennifer", "William", "Elizabeth", "David", "Sarah"],
    "UK": ["Oliver", "Amelia", "George", "Charlotte", "Harry", "Sophie", "Thomas", "Emily", "Jack", "Isabella"],
    "APAC": ["Takeshi", "Yuki", "Hiroshi", "Sakura", "Kenji", "Aiko", "Wei", "Mei", "Jin", "Hana",
             "Ahmed", "Fatima", "Mohammed", "Aisha", "Omar", "Layla", "Hassan", "Noor", "Ali", "Zara"],
    "EU": ["Lukas", "Emma", "Maximilian", "Sofia", "Felix", "Anna", "Leon", "Marie", "Paul", "Clara"],
}

LAST_NAMES = {
    "US": ["Smith", "Johnson", "Williams", "Brown", "Jones", "Davis", "Miller", "Wilson", "Taylor", "Anderson"],
    "UK": ["Thompson", "Wright", "Clarke", "Roberts", "Mitchell", "Campbell", "Stewart", "Murray", "Walker", "Hughes"],
    "APAC": ["Tanaka", "Yamamoto", "Sato", "Suzuki", "Watanabe", "Chen", "Wang", "Liu", "Kim", "Park",
             "Al-Rashid", "Hassan", "Ibrahim", "Patel", "Sharma", "Khan", "Singh", "Nguyen", "Tran", "Lee"],
    "EU": ["Mueller", "Schmidt", "Schneider", "Fischer", "Weber", "Rossi", "Bianchi", "Dubois", "Moreau", "Martin"],
}

# ISO 3166-1 alpha-3 country codes by region
COUNTRIES = {
    "US": ["USA", "USA", "USA", "CAN"],  # Weighted toward USA
    "UK": ["GBR", "GBR", "IRL"],
    "EU": ["DEU", "FRA", "ITA", "ESP", "NLD", "CHE"],
    "APAC": ["JPN", "SGP", "HKG", "AUS", "IND", "ARE", "KOR"],
}

COMPANY_NAME_PREFIXES = [
    "Meridian", "Pacific Rim", "Northern Star", "Golden Gate", "Atlas",
    "Pinnacle", "Sapphire", "Falcon", "Sterling", "Eastbridge",
    "Nexus", "Sovereign", "Crimson Bay", "Titanium", "Emerald Coast",
    "Summit Peak", "Horizon", "Quantum", "Phoenix", "Cobalt",
]

COMPANY_NAME_SUFFIXES = [
    "Capital Holdings", "Trading Corp", "Investments", "Ventures", "Global Partners",
    "Financial Group", "Asset Management", "Industries Ltd", "Commerce International", "Securities",
    "Technology Solutions", "Wealth Advisors", "Shipping", "Resources Corp", "Properties",
]

RELATIONSHIP_MANAGERS = [
    "Sarah Mitchell", "James Crawford", "Emma Richardson", "Thomas Blackwell", "Rachel Kim",
    "David Nakamura", "Maria Santos", "Alexander Petrov", "Hannah O'Brien", "Marcus Williams",
    "Yuki Tanaka", "Robert Chen", "Sophia Mueller", "Ahmed Al-Fayed", "Catherine Dubois",
]

KYC_ANALYSTS = [
    "Lisa Park", "Daniel Foster", "Rebecca Okonkwo", "Stuart MacLeod", "Priya Sharma",
    "Marcus Thompson", "Anna Kowalski", "Yusuf Demir", "Catherine Leung", "Jonathan Price",
    "Ingrid Bergstrom", "Rajesh Patel", "Gabrielle Martin", "Kenji Watanabe", "Olivia Chen",
    "Samuel Edwards", "Fatima Zahra", "Henrik Johansson", "Maria Gonzalez", "Alistair Campbell",
]


# =============================================================================
# GENERATION LOGIC
# =============================================================================

def generate_client() -> Dict:
    """Generate a single synthetic client record."""
    entity_type = random.choices(
        list(ENTITY_TYPE_WEIGHTS.keys()),
        weights=list(ENTITY_TYPE_WEIGHTS.values()),
    )[0]

    region = random.choice(["US", "UK", "EU", "APAC"])

    if entity_type == "Individual":
        first_name = random.choice(FIRST_NAMES[region])
        last_name = random.choice(LAST_NAMES[region])
        company_name = None
    else:
        first_name = None
        last_name = None
        company_name = f"{random.choice(COMPANY_NAME_PREFIXES)} {random.choice(COMPANY_NAME_SUFFIXES)} {random.randint(1, 999)}"

    risk_rating = random.choices(
        list(RISK_RATING_WEIGHTS.keys()),
        weights=list(RISK_RATING_WEIGHTS.values()),
    )[0]

    onboarding_date = date.today() - timedelta(days=random.randint(1, 3650))

    return {
        "client_id": str(uuid.uuid4()),
        "entity_type": entity_type,
        "first_name": first_name,
        "last_name": last_name,
        "company_name": company_name,
        "nationality": random.choice(COUNTRIES[region]),
        "country_of_residence": random.choice(COUNTRIES[region]),
        "risk_rating": risk_rating,
        "onboarding_date": onboarding_date,
        "relationship_manager": random.choice(RELATIONSHIP_MANAGERS),
        "status": random.choices(
            list(CLIENT_STATUS_WEIGHTS.keys()),
            weights=list(CLIENT_STATUS_WEIGHTS.values()),
        )[0],
    }


def generate_case(client_id: str) -> Dict:
    """Generate a single KYC case for a client."""
    case_type = random.choices(
        list(CASE_TYPE_WEIGHTS.keys()),
        weights=list(CASE_TYPE_WEIGHTS.values()),
    )[0]

    status = random.choices(
        list(CASE_STATUS_WEIGHTS.keys()),
        weights=list(CASE_STATUS_WEIGHTS.values()),
    )[0]

    opened_date = date.today() - timedelta(days=random.randint(1, 730))
    due_date = opened_date + timedelta(days=random.randint(7, 60))

    return {
        "case_id": str(uuid.uuid4()),
        "client_id": client_id,
        "case_type": case_type,
        "status": status,
        "priority": random.choice(["Low", "Medium", "High", "Critical"]),
        "assigned_analyst": random.choice(KYC_ANALYSTS),
        "opened_date": opened_date,
        "due_date": due_date,
        "closed_date": opened_date + timedelta(days=random.randint(1, 30)) if status in ("Approved", "Rejected") else None,
    }


def generate_extracted_fields(client: Dict, doc_type: str) -> Dict:
    """Generate realistic extracted_fields VARIANT JSON."""
    full_name = (
        f"{client['first_name']} {client['last_name']}"
        if client["entity_type"] == "Individual"
        else client["company_name"]
    )

    dob = date.today() - timedelta(days=random.randint(25 * 365, 75 * 365))
    expiry = date.today() + timedelta(days=random.randint(365, 3650))

    doc_number_prefix = {
        "Passport": "P",
        "DriversLicense": "DL-",
        "NationalID": "NID",
        "FinancialStatement": "REF-",
        "UtilityBill": "REF-",
        "CorporateRegistry": "REF-",
        "BeneficialOwnership": "REF-",
    }

    prefix = doc_number_prefix.get(doc_type, "REF-")
    doc_number = f"{prefix}{random.randint(1000000, 9999999)}"

    return {
        "full_name": full_name,
        "date_of_birth": dob.isoformat(),
        "document_number": doc_number,
        "issuing_country": client["nationality"],
        "expiry_date": expiry.isoformat(),
        "extraction_timestamp": date.today().isoformat(),
    }


# =============================================================================
# ROW COUNT TARGETS
# =============================================================================

TARGET_COUNTS = {
    "CLIENTS": 100_000,
    "KYC_CASES": 200_000,
    "DOCUMENTS_METADATA": 500_000,
    "VERIFICATION_RESULTS": 500_000,
    "ALERT_QUEUE": 50_000,
    "KYC_POLICIES": 25,  # Hand-crafted in 02_data.sql
}


if __name__ == "__main__":
    print("KYC/AML Data Generation Logic")
    print("=" * 50)
    print(f"\nTarget row counts:")
    for table, count in TARGET_COUNTS.items():
        print(f"  {table}: {count:,}")
    print(f"\nDistributions:")
    print(f"  Entity types: {ENTITY_TYPE_WEIGHTS}")
    print(f"  Risk ratings: {RISK_RATING_WEIGHTS}")
    print(f"  Match statuses: {MATCH_STATUS_WEIGHTS}")
    print(f"\nNote: Actual data generation uses Snowflake GENERATOR() in 02_data.sql")
    print("This script documents the distributions and logic for reference only.")
