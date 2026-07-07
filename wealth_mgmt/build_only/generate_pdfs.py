"""
=============================================================================
WEALTH MANAGEMENT — BUILD ONLY: Synthetic PDF Generator
=============================================================================
Purpose: Generates synthetic onboarding documents (W-9 forms, Investment Policy
         Statements, Client Agreements) as PDFs for upload to 
         @BNK.WEALTH_MGMT.ONBOARDING_DOCS stage.

This script is NOT shared with the customer — it is internal tooling used to
produce the synthetic documents that demonstrate the AI_PARSE_DOCUMENT pipeline.

Requirements:
    pip install fpdf2

Usage:
    python generate_pdfs.py --output ./onboarding_docs --count 50
    
    Then upload to Snowflake:
    PUT file://./onboarding_docs/*.pdf @BNK.WEALTH_MGMT.ONBOARDING_DOCS;
=============================================================================
"""

import random
import string
import os
from datetime import date, timedelta
from fpdf import FPDF

# --- Configuration ---
FIRST_NAMES = [
    'James', 'Robert', 'Michael', 'William', 'David', 'Richard', 'Joseph',
    'Thomas', 'Charles', 'Christopher', 'Sarah', 'Jennifer', 'Jessica',
    'Emily', 'Elizabeth', 'Ashley', 'Megan', 'Hannah', 'Olivia', 'Catherine'
]

LAST_NAMES = [
    'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller',
    'Davis', 'Rodriguez', 'Martinez', 'Anderson', 'Taylor', 'Thompson',
    'White', 'Harris', 'Clark', 'Lewis', 'Walker', 'Hall', 'Allen'
]

STATES = ['NY', 'CA', 'TX', 'FL', 'IL', 'PA', 'OH', 'GA', 'NC', 'MA',
           'CT', 'NJ', 'VA', 'WA', 'CO', 'AZ', 'TN', 'MD', 'MN', 'WI']

RISK_LEVELS = ['Conservative', 'Moderate', 'Moderately Aggressive', 'Aggressive']

OBJECTIVES = ['Capital Preservation', 'Income Generation', 'Balanced Growth and Income',
              'Long-term Capital Appreciation', 'Aggressive Growth']

ACCOUNT_TYPES = ['Individual', 'Joint Tenants with Rights of Survivorship',
                 'Revocable Living Trust', 'Traditional IRA', 'Roth IRA',
                 'SEP IRA', 'Corporate Investment Account']


def random_ssn_last_four():
    return f"{random.randint(1000, 9999)}"


def random_ein():
    return f"{random.randint(10,99)}-{random.randint(1000000,9999999)}"


def random_address():
    num = random.randint(100, 9999)
    streets = ['Main St', 'Oak Ave', 'Park Blvd', 'Elm Dr', 'Cedar Ln',
               'Maple Way', 'River Rd', 'Lake View Dr', 'Highland Ave', 'Sunset Blvd']
    cities = ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix',
              'San Francisco', 'Boston', 'Seattle', 'Denver', 'Atlanta']
    state = random.choice(STATES)
    zipcode = f"{random.randint(10000, 99999)}"
    return f"{num} {random.choice(streets)}, {random.choice(cities)}, {state} {zipcode}"


def random_date_in_range(start_year=1950, end_year=1990):
    start = date(start_year, 1, 1)
    end = date(end_year, 12, 31)
    delta = (end - start).days
    return start + timedelta(days=random.randint(0, delta))


class W9Generator:
    """Generates a synthetic W-9 (Request for Taxpayer Identification Number) PDF."""

    def generate(self, output_path: str, client_name: str = None):
        pdf = FPDF()
        pdf.add_page()
        pdf.set_font('Helvetica', 'B', 14)

        first = random.choice(FIRST_NAMES)
        last = random.choice(LAST_NAMES)
        name = client_name or f"{first} {last}"

        pdf.cell(0, 10, 'Form W-9 (Rev. October 2018)', ln=True, align='C')
        pdf.set_font('Helvetica', '', 10)
        pdf.cell(0, 6, 'Request for Taxpayer Identification Number and Certification', ln=True, align='C')
        pdf.cell(0, 6, 'Department of the Treasury - Internal Revenue Service', ln=True, align='C')
        pdf.ln(10)

        pdf.set_font('Helvetica', 'B', 10)
        pdf.cell(0, 6, '1. Name (as shown on your income tax return):', ln=True)
        pdf.set_font('Helvetica', '', 10)
        pdf.cell(0, 8, f'   {name}', ln=True)

        pdf.set_font('Helvetica', 'B', 10)
        pdf.cell(0, 6, '2. Business name/disregarded entity name:', ln=True)
        pdf.set_font('Helvetica', '', 10)
        pdf.cell(0, 8, f'   {name} Family Trust' if random.random() > 0.5 else '   N/A', ln=True)

        pdf.set_font('Helvetica', 'B', 10)
        pdf.cell(0, 6, '3. Federal tax classification:', ln=True)
        pdf.set_font('Helvetica', '', 10)
        classification = random.choice(['Individual/sole proprietor', 'Trust/estate', 'C Corporation', 'S Corporation'])
        pdf.cell(0, 8, f'   [X] {classification}', ln=True)

        pdf.set_font('Helvetica', 'B', 10)
        pdf.cell(0, 6, '5. Address:', ln=True)
        pdf.set_font('Helvetica', '', 10)
        pdf.cell(0, 8, f'   {random_address()}', ln=True)

        pdf.set_font('Helvetica', 'B', 10)
        pdf.cell(0, 6, '6. Social Security Number:', ln=True)
        pdf.set_font('Helvetica', '', 10)
        pdf.cell(0, 8, f'   XXX-XX-{random_ssn_last_four()}', ln=True)

        pdf.ln(10)
        pdf.set_font('Helvetica', 'B', 10)
        pdf.cell(0, 6, 'Part II - Certification', ln=True)
        pdf.set_font('Helvetica', '', 9)
        pdf.multi_cell(0, 5,
            'Under penalties of perjury, I certify that: (1) The number shown on this form is my correct '
            'taxpayer identification number, (2) I am not subject to backup withholding, (3) I am a U.S. citizen '
            'or other U.S. person, and (4) The FATCA code(s) entered on this form (if any) indicating that I am '
            'exempt from FATCA reporting is correct.')

        pdf.ln(10)
        pdf.cell(0, 6, f'Signature: {name}', ln=True)
        pdf.cell(0, 6, f'Date: {date.today().strftime("%m/%d/%Y")}', ln=True)

        pdf.output(output_path)


class IPSGenerator:
    """Generates a synthetic Investment Policy Statement PDF."""

    def generate(self, output_path: str, client_name: str = None):
        pdf = FPDF()
        pdf.add_page()

        first = random.choice(FIRST_NAMES)
        last = random.choice(LAST_NAMES)
        name = client_name or f"{first} {last}"

        risk = random.choice(RISK_LEVELS)
        objective = random.choice(OBJECTIVES)
        time_horizon = random.randint(5, 30)
        annual_income = random.randint(150000, 5000000)
        net_worth = random.randint(1000000, 50000000)

        pdf.set_font('Helvetica', 'B', 16)
        pdf.cell(0, 12, 'INVESTMENT POLICY STATEMENT', ln=True, align='C')
        pdf.set_font('Helvetica', '', 10)
        pdf.cell(0, 6, f'Prepared for: {name}', ln=True, align='C')
        pdf.cell(0, 6, f'Date: {date.today().strftime("%B %d, %Y")}', ln=True, align='C')
        pdf.ln(10)

        pdf.set_font('Helvetica', 'B', 12)
        pdf.cell(0, 8, '1. Client Profile', ln=True)
        pdf.set_font('Helvetica', '', 10)
        pdf.cell(0, 6, f'Name: {name}', ln=True)
        pdf.cell(0, 6, f'Account Type: {random.choice(ACCOUNT_TYPES)}', ln=True)
        pdf.cell(0, 6, f'Annual Income: ${annual_income:,.0f}', ln=True)
        pdf.cell(0, 6, f'Estimated Net Worth: ${net_worth:,.0f}', ln=True)
        pdf.cell(0, 6, f'Investment Time Horizon: {time_horizon} years', ln=True)
        pdf.ln(6)

        pdf.set_font('Helvetica', 'B', 12)
        pdf.cell(0, 8, '2. Investment Objectives', ln=True)
        pdf.set_font('Helvetica', '', 10)
        pdf.cell(0, 6, f'Primary Objective: {objective}', ln=True)
        pdf.cell(0, 6, f'Risk Tolerance: {risk}', ln=True)
        pdf.ln(6)

        pdf.set_font('Helvetica', 'B', 12)
        pdf.cell(0, 8, '3. Target Asset Allocation', ln=True)
        pdf.set_font('Helvetica', '', 10)

        if risk == 'Conservative':
            alloc = 'US Equity: 25%, Intl Equity: 10%, Fixed Income: 50%, Alternatives: 5%, Cash: 10%'
        elif risk == 'Moderate':
            alloc = 'US Equity: 40%, Intl Equity: 15%, Fixed Income: 30%, Alternatives: 10%, Cash: 5%'
        elif risk == 'Moderately Aggressive':
            alloc = 'US Equity: 50%, Intl Equity: 20%, Fixed Income: 15%, Alternatives: 12%, Cash: 3%'
        else:
            alloc = 'US Equity: 55%, Intl Equity: 25%, Fixed Income: 5%, Alternatives: 13%, Cash: 2%'

        pdf.cell(0, 6, f'Target: {alloc}', ln=True)
        pdf.ln(6)

        pdf.set_font('Helvetica', 'B', 12)
        pdf.cell(0, 8, '4. Constraints and Restrictions', ln=True)
        pdf.set_font('Helvetica', '', 10)
        pdf.multi_cell(0, 5,
            f'The portfolio shall maintain diversification such that no single security exceeds 10% of '
            f'total portfolio value. Minimum allocation to fixed income shall not fall below '
            f'{"20%" if risk in ["Conservative", "Moderate"] else "5%"}. '
            f'ESG considerations: {"Exclude fossil fuel companies" if random.random() > 0.7 else "No specific exclusions"}.')

        pdf.ln(6)
        pdf.set_font('Helvetica', 'B', 12)
        pdf.cell(0, 8, '5. Signatures', ln=True)
        pdf.set_font('Helvetica', '', 10)
        pdf.ln(10)
        pdf.cell(0, 6, f'Client Signature: {name}', ln=True)
        pdf.cell(0, 6, f'Date: {date.today().strftime("%m/%d/%Y")}', ln=True)
        pdf.ln(6)
        advisor = f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}, CFP"
        pdf.cell(0, 6, f'Advisor Signature: {advisor}', ln=True)
        pdf.cell(0, 6, f'Date: {date.today().strftime("%m/%d/%Y")}', ln=True)

        pdf.output(output_path)


class ClientAgreementGenerator:
    """Generates a synthetic Client Advisory Agreement PDF."""

    def generate(self, output_path: str, client_name: str = None):
        pdf = FPDF()
        pdf.add_page()

        first = random.choice(FIRST_NAMES)
        last = random.choice(LAST_NAMES)
        name = client_name or f"{first} {last}"
        fee_bps = random.choice([50, 75, 85, 100, 125, 150])

        pdf.set_font('Helvetica', 'B', 14)
        pdf.cell(0, 10, 'INVESTMENT ADVISORY AGREEMENT', ln=True, align='C')
        pdf.set_font('Helvetica', '', 9)
        pdf.ln(8)

        pdf.multi_cell(0, 5,
            f'This Investment Advisory Agreement ("Agreement") is entered into as of '
            f'{date.today().strftime("%B %d, %Y")} by and between {name} ("Client") and '
            f'Wealth Management Advisory Services, LLC ("Advisor"), a registered investment '
            f'advisor with the Securities and Exchange Commission.')
        pdf.ln(4)

        pdf.set_font('Helvetica', 'B', 11)
        pdf.cell(0, 8, '1. SERVICES', ln=True)
        pdf.set_font('Helvetica', '', 9)
        pdf.multi_cell(0, 5,
            'Advisor shall provide continuous investment management services, including but not limited '
            'to: portfolio construction, security selection, asset allocation, rebalancing, tax-loss '
            'harvesting, and periodic performance reporting. Advisor will manage Client assets on a '
            'discretionary basis in accordance with the Investment Policy Statement.')
        pdf.ln(4)

        pdf.set_font('Helvetica', 'B', 11)
        pdf.cell(0, 8, '2. FEES', ln=True)
        pdf.set_font('Helvetica', '', 9)
        pdf.multi_cell(0, 5,
            f'Client agrees to pay Advisor an annual management fee of {fee_bps} basis points '
            f'({fee_bps/100:.2f}%) of assets under management, calculated quarterly based on the '
            f'average daily balance and deducted directly from Client accounts. This fee covers all '
            f'advisory services including financial planning consultations.')
        pdf.ln(4)

        pdf.set_font('Helvetica', 'B', 11)
        pdf.cell(0, 8, '3. CUSTODY', ln=True)
        pdf.set_font('Helvetica', '', 9)
        pdf.multi_cell(0, 5,
            'Client assets shall be held in custody at a qualified custodian. Client will receive '
            'account statements directly from the custodian on at least a quarterly basis. Advisor '
            'shall not have physical custody of Client funds or securities at any time.')
        pdf.ln(4)

        pdf.set_font('Helvetica', 'B', 11)
        pdf.cell(0, 8, '4. TERMINATION', ln=True)
        pdf.set_font('Helvetica', '', 9)
        pdf.multi_cell(0, 5,
            'Either party may terminate this Agreement upon thirty (30) days written notice. '
            'Upon termination, Advisor shall provide Client with all relevant account information '
            'and cease all trading activity unless otherwise directed.')
        pdf.ln(10)

        pdf.set_font('Helvetica', '', 10)
        pdf.cell(0, 6, f'Client: {name}', ln=True)
        pdf.cell(0, 6, f'Date: {date.today().strftime("%m/%d/%Y")}', ln=True)
        pdf.cell(0, 6, f'SSN (last 4): XXX-XX-{random_ssn_last_four()}', ln=True)

        pdf.output(output_path)


def generate_documents(output_dir: str, count: int = 50):
    """Generate a mix of onboarding documents."""
    os.makedirs(output_dir, exist_ok=True)

    generators = [
        (W9Generator(), 'w9', 0.35),
        (IPSGenerator(), 'ips', 0.40),
        (ClientAgreementGenerator(), 'agreement', 0.25),
    ]

    generated = []
    for i in range(count):
        # Pick document type based on weights
        r = random.random()
        if r < 0.35:
            gen, prefix, _ = generators[0]
        elif r < 0.75:
            gen, prefix, _ = generators[1]
        else:
            gen, prefix, _ = generators[2]

        filename = f"{prefix}_{i+1:04d}.pdf"
        filepath = os.path.join(output_dir, filename)
        gen.generate(filepath)
        generated.append(filename)
        print(f"Generated: {filename}")

    print(f"\nTotal documents generated: {len(generated)}")
    print(f"Output directory: {output_dir}")
    print(f"\nTo upload to Snowflake:")
    print(f"  PUT file://{output_dir}/*.pdf @BNK.WEALTH_MGMT.ONBOARDING_DOCS;")

    return generated


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description='Generate synthetic onboarding PDFs')
    parser.add_argument('--output', default='./onboarding_docs', help='Output directory')
    parser.add_argument('--count', type=int, default=50, help='Number of documents')
    args = parser.parse_args()

    generate_documents(args.output, args.count)
