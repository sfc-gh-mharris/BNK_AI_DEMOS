"""
KYC/AML Synthetic PDF Document Generator
==========================================
Generates realistic sample KYC documents for the document processing pipeline.
Run this locally to create PDFs, then upload them to the Snowflake stage.

Generates three document types:
1. Passports — templated identity document with MRZ-like formatting
2. Driver's Licenses — address + identity document
3. Financial Statements — corporate balance sheet

Requirements:
    pip install fpdf2

Usage:
    python generate_pdfs.py --output ./pdfs --count 20

    # Then upload to Snowflake:
    PUT file://./pdfs/clients/*/*.pdf @BNK.KYC_AML.KYC_DOCUMENTS/clients/ AUTO_COMPRESS=FALSE;
"""

import argparse
import os
import random
import string
import uuid
from datetime import date, timedelta
from pathlib import Path
from typing import Dict, Optional

from fpdf import FPDF


# =============================================================================
# DATA POOLS
# =============================================================================

FIRST_NAMES = [
    "James", "Mary", "Robert", "Patricia", "Michael", "Jennifer",
    "Oliver", "Amelia", "George", "Charlotte", "Harry", "Sophie",
    "Takeshi", "Yuki", "Hiroshi", "Sakura", "Wei", "Mei",
    "Lukas", "Emma", "Maximilian", "Sofia", "Felix", "Anna",
    "Ahmed", "Fatima", "Mohammed", "Aisha", "Omar", "Hassan",
]

LAST_NAMES = [
    "Smith", "Johnson", "Williams", "Brown", "Jones",
    "Thompson", "Wright", "Clarke", "Roberts", "Mitchell",
    "Tanaka", "Yamamoto", "Sato", "Chen", "Wang",
    "Mueller", "Schmidt", "Schneider", "Rossi", "Dubois",
    "Al-Rashid", "Ibrahim", "Patel", "Sharma", "Khan",
]

NATIONALITIES = [
    ("United States of America", "USA"),
    ("United Kingdom", "GBR"),
    ("Germany", "DEU"),
    ("France", "FRA"),
    ("Japan", "JPN"),
    ("Singapore", "SGP"),
    ("Australia", "AUS"),
    ("Canada", "CAN"),
    ("Italy", "ITA"),
    ("India", "IND"),
]

ADDRESSES = [
    "42 Maple Street, Springfield, IL 62701, United States",
    "17 King's Road, Chelsea, London SW3 4RP, United Kingdom",
    "Hauptstraße 23, 80331 München, Germany",
    "15 Rue de Rivoli, 75001 Paris, France",
    "2-4-1 Marunouchi, Chiyoda-ku, Tokyo 100-0005, Japan",
    "88 Orchard Road, #12-01, Singapore 238839",
    "45 Collins Street, Melbourne VIC 3000, Australia",
    "200 Bay Street, Suite 1500, Toronto ON M5J 2J2, Canada",
    "Via Roma 10, 20121 Milano, Italy",
    "Bandra Kurla Complex, Mumbai 400051, India",
]

COMPANY_NAMES = [
    "Meridian Capital Holdings Pte Ltd",
    "Pacific Rim Trading Corporation",
    "Northern Star Investment Partners",
    "Atlas Global Advisors LLC",
    "Pinnacle Financial Group AG",
    "Sapphire Asset Management Ltd",
    "Sterling Commerce International",
    "Eastbridge Securities Corp",
    "Nexus Technology Solutions GmbH",
    "Phoenix Global Logistics SA",
]


# =============================================================================
# PDF GENERATORS
# =============================================================================

class PassportGenerator:
    """
    Generates a synthetic passport-style PDF document.
    
    Template structure:
    - Header: Country name and "PASSPORT" title
    - Photo placeholder (grey rectangle)
    - Personal details: Name, DOB, Nationality, Sex, Place of Birth
    - Document details: Passport No, Date of Issue, Date of Expiry
    - Authority line
    - MRZ zone (two lines of machine-readable text)
    """

    def generate(self, output_path: str, person: Dict) -> str:
        pdf = FPDF()
        pdf.add_page()
        pdf.set_auto_page_break(auto=False)

        # Header — Country and Document Type
        pdf.set_font("Helvetica", "B", 16)
        pdf.set_text_color(0, 51, 102)  # Navy blue
        pdf.cell(0, 10, person["nationality_full"].upper(), ln=True, align="C")
        pdf.set_font("Helvetica", "", 12)
        pdf.cell(0, 8, "PASSPORT", ln=True, align="C")
        pdf.ln(5)

        # Photo placeholder (grey box)
        pdf.set_fill_color(200, 200, 200)
        pdf.rect(15, 40, 35, 45, "F")
        pdf.set_xy(15, 87)
        pdf.set_font("Helvetica", "", 6)
        pdf.set_text_color(100, 100, 100)
        pdf.cell(35, 4, "PHOTO", align="C")

        # Personal details (right of photo)
        pdf.set_xy(60, 40)
        pdf.set_text_color(0, 0, 0)
        self._add_field(pdf, "Type", "P")
        self._add_field(pdf, "Country Code", person["nationality_code"])
        self._add_field(pdf, "Passport No.", person["document_number"])
        self._add_field(pdf, "Surname", person["last_name"].upper())
        self._add_field(pdf, "Given Names", person["first_name"].upper())
        self._add_field(pdf, "Nationality", person["nationality_full"])
        self._add_field(pdf, "Date of Birth", person["dob"].strftime("%d %b %Y"))
        self._add_field(pdf, "Sex", random.choice(["M", "F"]))
        self._add_field(pdf, "Place of Birth", person["nationality_full"])
        self._add_field(pdf, "Date of Issue", person["issue_date"].strftime("%d %b %Y"))
        self._add_field(pdf, "Date of Expiry", person["expiry_date"].strftime("%d %b %Y"))
        self._add_field(pdf, "Authority", f"Government of {person['nationality_full']}")

        # MRZ Zone (Machine Readable Zone)
        pdf.ln(15)
        pdf.set_font("Courier", "", 10)
        pdf.set_text_color(0, 0, 0)
        mrz_line1 = self._generate_mrz_line1(person)
        mrz_line2 = self._generate_mrz_line2(person)
        pdf.set_x(15)
        pdf.cell(0, 6, mrz_line1, ln=True)
        pdf.set_x(15)
        pdf.cell(0, 6, mrz_line2, ln=True)

        pdf.output(output_path)
        return output_path

    def _add_field(self, pdf: FPDF, label: str, value: str):
        """Add a label/value field pair."""
        x = pdf.get_x()
        y = pdf.get_y()
        pdf.set_font("Helvetica", "", 7)
        pdf.set_text_color(100, 100, 100)
        pdf.cell(0, 3, label, ln=True)
        pdf.set_font("Helvetica", "B", 10)
        pdf.set_text_color(0, 0, 0)
        pdf.cell(0, 5, value, ln=True)
        pdf.ln(1)

    def _generate_mrz_line1(self, person: Dict) -> str:
        """Generate first MRZ line: P<NATIONALITY<SURNAME<<GIVENNAMES<<<..."""
        surname = person["last_name"].upper().replace(" ", "<")
        given = person["first_name"].upper().replace(" ", "<")
        line = f"P<{person['nationality_code']}{surname}<<{given}"
        return line.ljust(44, "<")

    def _generate_mrz_line2(self, person: Dict) -> str:
        """Generate second MRZ line: passport number + checksums."""
        pnum = person["document_number"].replace("-", "")
        dob = person["dob"].strftime("%y%m%d")
        exp = person["expiry_date"].strftime("%y%m%d")
        line = f"{pnum}{'<' * 1}{person['nationality_code']}{dob}{'<' * 1}M{exp}"
        return line.ljust(44, "<")[:44]


class DriversLicenseGenerator:
    """
    Generates a synthetic driver's license PDF.
    
    Template structure:
    - Header: Jurisdiction name and "DRIVER LICENSE" title
    - Photo placeholder
    - Personal details: Name, DOB, Address
    - License details: License No, Class, Issue/Expiry dates
    - Restrictions/Endorsements
    """

    def generate(self, output_path: str, person: Dict) -> str:
        pdf = FPDF(orientation="L", format=(54, 85.6))  # ID card size (mm)
        pdf.add_page()
        pdf.set_auto_page_break(auto=False)

        # Header
        pdf.set_font("Helvetica", "B", 8)
        pdf.set_text_color(0, 51, 102)
        pdf.cell(0, 4, f"{person['nationality_full']} - DRIVER LICENSE", ln=True, align="C")
        pdf.ln(2)

        # Photo placeholder
        pdf.set_fill_color(200, 200, 200)
        pdf.rect(3, 10, 18, 22, "F")

        # Details (right of photo)
        pdf.set_xy(24, 10)
        pdf.set_text_color(0, 0, 0)

        pdf.set_font("Helvetica", "", 5)
        pdf.set_text_color(100, 100, 100)
        pdf.cell(0, 2, "LICENSE NUMBER", ln=True)
        pdf.set_x(24)
        pdf.set_font("Helvetica", "B", 7)
        pdf.set_text_color(0, 0, 0)
        pdf.cell(0, 3, person["document_number"], ln=True)
        pdf.set_x(24)

        pdf.set_font("Helvetica", "", 5)
        pdf.set_text_color(100, 100, 100)
        pdf.cell(0, 2, "NAME", ln=True)
        pdf.set_x(24)
        pdf.set_font("Helvetica", "B", 7)
        pdf.set_text_color(0, 0, 0)
        pdf.cell(0, 3, f"{person['last_name'].upper()}, {person['first_name'].upper()}", ln=True)
        pdf.set_x(24)

        pdf.set_font("Helvetica", "", 5)
        pdf.set_text_color(100, 100, 100)
        pdf.cell(0, 2, "DATE OF BIRTH", ln=True)
        pdf.set_x(24)
        pdf.set_font("Helvetica", "B", 7)
        pdf.set_text_color(0, 0, 0)
        pdf.cell(0, 3, person["dob"].strftime("%m/%d/%Y"), ln=True)
        pdf.set_x(24)

        pdf.set_font("Helvetica", "", 5)
        pdf.set_text_color(100, 100, 100)
        pdf.cell(0, 2, "ADDRESS", ln=True)
        pdf.set_x(24)
        pdf.set_font("Helvetica", "", 6)
        pdf.set_text_color(0, 0, 0)
        pdf.multi_cell(58, 2.5, person["address"])

        # Footer with dates
        pdf.set_xy(3, 38)
        pdf.set_font("Helvetica", "", 5)
        pdf.set_text_color(100, 100, 100)
        pdf.cell(25, 2, "ISSUED", align="L")
        pdf.cell(25, 2, "EXPIRES", align="L")
        pdf.ln(2)
        pdf.set_x(3)
        pdf.set_font("Helvetica", "B", 6)
        pdf.set_text_color(0, 0, 0)
        pdf.cell(25, 3, person["issue_date"].strftime("%m/%d/%Y"), align="L")
        pdf.cell(25, 3, person["expiry_date"].strftime("%m/%d/%Y"), align="L")

        pdf.output(output_path)
        return output_path


class FinancialStatementGenerator:
    """
    Generates a synthetic corporate financial statement PDF.
    
    Template structure:
    - Company header and reporting period
    - Balance Sheet section with Assets and Liabilities
    - Randomized financial figures (in millions)
    - Auditor's note
    """

    def generate(self, output_path: str, company: Dict) -> str:
        pdf = FPDF()
        pdf.add_page()
        pdf.set_auto_page_break(auto=True, margin=15)

        # Company Header
        pdf.set_font("Helvetica", "B", 14)
        pdf.set_text_color(0, 51, 102)
        pdf.cell(0, 10, company["name"], ln=True, align="C")
        pdf.set_font("Helvetica", "", 10)
        pdf.set_text_color(0, 0, 0)
        pdf.cell(0, 6, "CONSOLIDATED BALANCE SHEET", ln=True, align="C")
        pdf.cell(0, 6, f"As at {company['reporting_date'].strftime('%d %B %Y')}", ln=True, align="C")
        pdf.cell(0, 5, "(All amounts in USD millions unless otherwise stated)", ln=True, align="C")
        pdf.ln(10)

        # Assets section
        pdf.set_font("Helvetica", "B", 11)
        pdf.cell(0, 7, "ASSETS", ln=True)
        pdf.set_draw_color(0, 51, 102)
        pdf.line(10, pdf.get_y(), 200, pdf.get_y())
        pdf.ln(3)

        total_assets = 0
        asset_items = [
            ("Cash and cash equivalents", random.randint(500, 5000)),
            ("Trading securities", random.randint(1000, 15000)),
            ("Loans and advances to customers", random.randint(10000, 80000)),
            ("Investment securities", random.randint(5000, 30000)),
            ("Property, plant and equipment", random.randint(500, 3000)),
            ("Goodwill and intangible assets", random.randint(200, 2000)),
            ("Derivative financial assets", random.randint(1000, 10000)),
            ("Other assets", random.randint(500, 5000)),
        ]

        for item_name, amount in asset_items:
            total_assets += amount
            self._add_line_item(pdf, item_name, amount)

        pdf.ln(2)
        pdf.set_font("Helvetica", "B", 10)
        pdf.cell(120, 6, "TOTAL ASSETS")
        pdf.cell(40, 6, f"{total_assets:,}", align="R", ln=True)
        pdf.ln(5)

        # Liabilities section
        pdf.set_font("Helvetica", "B", 11)
        pdf.cell(0, 7, "LIABILITIES", ln=True)
        pdf.line(10, pdf.get_y(), 200, pdf.get_y())
        pdf.ln(3)

        total_liabilities = 0
        liability_items = [
            ("Customer deposits", int(total_assets * random.uniform(0.45, 0.60))),
            ("Borrowings", int(total_assets * random.uniform(0.10, 0.20))),
            ("Derivative financial liabilities", random.randint(800, 8000)),
            ("Provisions", random.randint(100, 1000)),
            ("Other liabilities", random.randint(500, 3000)),
            ("Subordinated debt", random.randint(1000, 5000)),
        ]

        for item_name, amount in liability_items:
            total_liabilities += amount
            self._add_line_item(pdf, item_name, amount)

        pdf.ln(2)
        pdf.set_font("Helvetica", "B", 10)
        pdf.cell(120, 6, "TOTAL LIABILITIES")
        pdf.cell(40, 6, f"{total_liabilities:,}", align="R", ln=True)
        pdf.ln(5)

        # Equity
        equity = total_assets - total_liabilities
        pdf.set_font("Helvetica", "B", 11)
        pdf.cell(0, 7, "SHAREHOLDERS' EQUITY", ln=True)
        pdf.line(10, pdf.get_y(), 200, pdf.get_y())
        pdf.ln(3)

        equity_items = [
            ("Share capital", int(equity * 0.20)),
            ("Retained earnings", int(equity * 0.60)),
            ("Other reserves", int(equity * 0.20)),
        ]

        for item_name, amount in equity_items:
            self._add_line_item(pdf, item_name, amount)

        pdf.ln(2)
        pdf.set_font("Helvetica", "B", 10)
        pdf.cell(120, 6, "TOTAL EQUITY")
        pdf.cell(40, 6, f"{equity:,}", align="R", ln=True)

        # Auditor's note
        pdf.ln(15)
        pdf.set_font("Helvetica", "I", 8)
        pdf.set_text_color(80, 80, 80)
        pdf.multi_cell(0, 4,
            "These financial statements have been prepared in accordance with International Financial Reporting Standards (IFRS) "
            "as issued by the International Accounting Standards Board. The financial statements were approved by the Board of "
            f"Directors on {company['reporting_date'].strftime('%d %B %Y')} and signed on their behalf."
        )

        pdf.output(output_path)
        return output_path

    def _add_line_item(self, pdf: FPDF, name: str, amount: int):
        """Add a single balance sheet line item."""
        pdf.set_font("Helvetica", "", 9)
        pdf.cell(120, 5, f"  {name}")
        pdf.cell(40, 5, f"{amount:,}", align="R", ln=True)


# =============================================================================
# ORCHESTRATION
# =============================================================================

def generate_person_data() -> Dict:
    """Generate random person data for document generation."""
    first = random.choice(FIRST_NAMES)
    last = random.choice(LAST_NAMES)
    nat_full, nat_code = random.choice(NATIONALITIES)
    dob = date.today() - timedelta(days=random.randint(25 * 365, 65 * 365))
    issue_date = date.today() - timedelta(days=random.randint(30, 5 * 365))
    expiry_date = issue_date + timedelta(days=10 * 365)

    return {
        "client_id": str(uuid.uuid4()),
        "first_name": first,
        "last_name": last,
        "nationality_full": nat_full,
        "nationality_code": nat_code,
        "dob": dob,
        "address": random.choice(ADDRESSES),
        "issue_date": issue_date,
        "expiry_date": expiry_date,
        "document_number": f"P{''.join(random.choices(string.digits, k=7))}",
    }


def generate_company_data() -> Dict:
    """Generate random company data for financial statements."""
    return {
        "name": random.choice(COMPANY_NAMES),
        "reporting_date": date(
            random.choice([2023, 2024]),
            random.choice([3, 6, 9, 12]),
            random.choice([28, 30, 31]),
        ),
        "client_id": str(uuid.uuid4()),
    }


def main(output_dir: str, count: int):
    """
    Generate synthetic KYC documents.
    
    Output structure mirrors the Snowflake stage layout:
        output_dir/clients/<client_id>/Passport_<doc_id>.pdf
        output_dir/clients/<client_id>/DriversLicense_<doc_id>.pdf
        output_dir/clients/<client_id>/FinancialStatement_<doc_id>.pdf
    """
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    passport_gen = PassportGenerator()
    license_gen = DriversLicenseGenerator()
    statement_gen = FinancialStatementGenerator()

    generated = {"Passport": 0, "DriversLicense": 0, "FinancialStatement": 0}

    for i in range(count):
        doc_type = random.choices(
            ["Passport", "DriversLicense", "FinancialStatement"],
            weights=[0.5, 0.3, 0.2],
        )[0]

        doc_id = str(uuid.uuid4())

        if doc_type in ("Passport", "DriversLicense"):
            person = generate_person_data()
            client_id = person["client_id"]

            if doc_type == "Passport":
                person["document_number"] = f"P{''.join(random.choices(string.digits, k=7))}"
            else:
                person["document_number"] = f"DL-{''.join(random.choices(string.digits, k=6))}"
        else:
            company = generate_company_data()
            client_id = company["client_id"]

        # Create client directory
        client_dir = output_path / "clients" / client_id
        client_dir.mkdir(parents=True, exist_ok=True)

        # Generate document
        file_name = f"{doc_type}_{doc_id}.pdf"
        file_path = str(client_dir / file_name)

        if doc_type == "Passport":
            passport_gen.generate(file_path, person)
        elif doc_type == "DriversLicense":
            license_gen.generate(file_path, person)
        else:
            statement_gen.generate(file_path, company)

        generated[doc_type] += 1

        if (i + 1) % 10 == 0:
            print(f"  Generated {i + 1}/{count} documents...")

    print(f"\nGeneration complete!")
    print(f"  Passports: {generated['Passport']}")
    print(f"  Driver's Licenses: {generated['DriversLicense']}")
    print(f"  Financial Statements: {generated['FinancialStatement']}")
    print(f"\nOutput directory: {output_path}")
    print(f"\nTo upload to Snowflake stage:")
    print(f"  PUT file://{output_path}/clients/*/*.pdf @BNK.KYC_AML.KYC_DOCUMENTS/clients/ AUTO_COMPRESS=FALSE;")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Generate synthetic KYC documents for demo")
    parser.add_argument("--output", default="./output_pdfs", help="Output directory (default: ./output_pdfs)")
    parser.add_argument("--count", type=int, default=50, help="Number of documents to generate (default: 50)")
    args = parser.parse_args()

    print(f"Generating {args.count} synthetic KYC documents...")
    main(args.output, args.count)
