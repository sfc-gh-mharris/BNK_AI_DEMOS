"""
SBA Borrower and Program Integrity Synthetic PDF Generator
==========================================================
Generates realistic SBA loan and contracting verification PDFs for the
BNK.SBA_VETTING Cortex Document AI pipeline:
  1. Form1919 - SBA Form 1919 Borrower Information and Principal Attestation
  2. IRSTaxTranscript_4506C - IRS Form 4506-C / Form 1120-S Business Tax Return Transcript
  3. OperatingAgreement - Multi-Tier LLC Operating Agreement & Governance Schedule
  4. OwnerGovernmentID - Principal U.S. Passport / State Driver License Verification Card

Includes 5 deterministic showcase documents (SBAID-DEMO-001 through SBAID-DEMO-005)
plus configurable additional synthetic batch documents.

Usage:
    uv run --with fpdf2 python3 generate_sba_pdfs.py --output ./pdfs --extra-count 15
"""

import argparse
import random
import string
import uuid
from datetime import date, timedelta
from pathlib import Path
from typing import Dict, List

from fpdf import FPDF


def _header_banner(pdf: FPDF, agency_line: str, form_title: str, subtitle: str) -> None:
    pdf.set_fill_color(12, 45, 90)
    pdf.set_text_color(255, 255, 255)
    pdf.set_font("Helvetica", "B", 11)
    pdf.cell(0, 8, agency_line, new_x="LMARGIN", new_y="NEXT", align="C", fill=True)
    pdf.set_text_color(12, 45, 90)
    pdf.set_font("Helvetica", "B", 13)
    pdf.ln(2)
    pdf.cell(0, 7, form_title, new_x="LMARGIN", new_y="NEXT", align="C")
    pdf.set_font("Helvetica", "", 9)
    pdf.set_text_color(60, 60, 60)
    pdf.cell(0, 5, subtitle, new_x="LMARGIN", new_y="NEXT", align="C")
    pdf.ln(3)
    pdf.set_draw_color(12, 45, 90)
    pdf.line(12, pdf.get_y(), 198, pdf.get_y())
    pdf.ln(4)


def _kv_row(pdf: FPDF, label: str, value: str, label_w: int = 72) -> None:
    pdf.set_font("Helvetica", "B", 9)
    pdf.set_text_color(40, 40, 40)
    pdf.cell(label_w, 6, label)
    pdf.set_font("Helvetica", "", 9)
    pdf.set_text_color(0, 0, 0)
    pdf.cell(0, 6, value, new_x="LMARGIN", new_y="NEXT")


def generate_tax_transcript_pdf(output_path: str, data: Dict) -> str:
    pdf = FPDF()
    pdf.add_page()
    pdf.set_auto_page_break(auto=True, margin=15)

    _header_banner(
        pdf,
        "INTERNAL REVENUE SERVICE - IVES FORM 4506-C TRANSCRIPT DELIVERY",
        "BUSINESS TAX RETURN TRANSCRIPT (FORM 1120-S)",
        f"Tax Period Ending: {data['tax_period']} | Requesting Agency: U.S. Small Business Administration",
    )

    pdf.set_font("Helvetica", "B", 10)
    pdf.set_text_color(12, 45, 90)
    pdf.cell(0, 7, "SECTION 1: TAXPAYER IDENTIFICATION", new_x="LMARGIN", new_y="NEXT")
    _kv_row(pdf, "Business Legal Name:", data["legal_name"])
    _kv_row(pdf, "Employer Identification Number (EIN):", data["ein"])
    _kv_row(pdf, "Business Street Address:", data["address"])
    _kv_row(pdf, "Primary NAICS Business Activity Code:", f"{data['naics_code']} ({data['naics_desc']})")
    _kv_row(pdf, "Incorporation / Election Date:", data["formation_date"])
    _kv_row(pdf, "Form 941 Reconciled W-2 Employee Count:", str(data["employees"]))
    pdf.ln(3)

    pdf.set_font("Helvetica", "B", 10)
    pdf.set_text_color(12, 45, 90)
    pdf.cell(0, 7, "SECTION 2: INCOME AND DEDUCTIONS (USD)", new_x="LMARGIN", new_y="NEXT")
    _kv_row(pdf, "Line 1a - Gross Receipts or Sales:", f"${data['gross_receipts']:,}")
    _kv_row(pdf, "Line 2 - Cost of Goods Sold:", f"${data['cogs']:,}")
    _kv_row(pdf, "Line 3 - Gross Profit:", f"${data['gross_receipts'] - data['cogs']:,}")
    _kv_row(pdf, "Line 7 & 8 - Officer + W-2 Salaries and Wages:", f"${data['payroll']:,}")
    _kv_row(pdf, "Line 21 - Ordinary Business Income (Loss):", f"${data['net_income']:,}")
    pdf.ln(3)

    pdf.set_font("Helvetica", "B", 10)
    pdf.set_text_color(12, 45, 90)
    pdf.cell(0, 7, "SECTION 3: SCHEDULE K-1 SHAREHOLDER SUMMARY", new_x="LMARGIN", new_y="NEXT")
    for idx, owner in enumerate(data["owners"], start=1):
        _kv_row(
            pdf,
            f"Shareholder {idx}:",
            f"{owner['name']} | Ownership: {owner['pct']}% | Citizenship: {owner['citizenship']} | DOB: {owner['dob']}",
            label_w=38,
        )

    pdf.ln(6)
    pdf.set_font("Helvetica", "I", 8)
    pdf.set_text_color(90, 90, 90)
    pdf.multi_cell(
        0,
        4.5,
        "IRS IVES Verification Record: Transmitted electronically to U.S. Small Business Administration Office of Capital Access "
        "pursuant to executed IRS Form 4506-C authorization under SBA SOP 50 10 8.1 pre-closing verification rules.",
    )

    pdf.output(output_path)
    return output_path


def generate_form_1919_pdf(output_path: str, data: Dict) -> str:
    pdf = FPDF()
    pdf.add_page()
    pdf.set_auto_page_break(auto=True, margin=15)

    _header_banner(
        pdf,
        "U.S. SMALL BUSINESS ADMINISTRATION",
        "SBA FORM 1919 - BORROWER INFORMATION FORM",
        f"Program: {data['program']} | OMB Control No. 3245-0348 | SOP 50 10 8.1 Edition",
    )

    pdf.set_font("Helvetica", "B", 10)
    pdf.set_text_color(12, 45, 90)
    pdf.cell(0, 7, "SECTION I: APPLICANT BUSINESS INFORMATION", new_x="LMARGIN", new_y="NEXT")
    _kv_row(pdf, "Applicant Business Legal Name:", data["legal_name"])
    _kv_row(pdf, "Employer Identification Number (EIN):", data["ein"])
    _kv_row(pdf, "Primary Business Address:", data["address"])
    _kv_row(pdf, "NAICS Code:", f"{data['naics_code']} ({data['naics_desc']})")
    _kv_row(pdf, "Requested SBA Loan Amount:", f"${data['loan_amount']:,}")
    _kv_row(pdf, "Applicant Stated Annual Gross Revenue:", f"${data['stated_revenue']:,}")
    _kv_row(pdf, "Applicant Stated Annual W-2 Payroll:", f"${data['stated_payroll']:,}")
    _kv_row(pdf, "Current Full-Time Equivalent Employees:", str(data["employees"]))
    _kv_row(pdf, "Loan Packager / Form 159 Agent ID:", data.get("packager_id", "NONE - Direct Submission"))
    pdf.ln(3)

    pdf.set_font("Helvetica", "B", 10)
    pdf.set_text_color(12, 45, 90)
    pdf.cell(
        0,
        7,
        "SECTION II: 100% DIRECT AND INDIRECT PRINCIPAL OWNERSHIP DISCLOSURE",
        new_x="LMARGIN",
        new_y="NEXT",
    )
    for idx, owner in enumerate(data["owners"], start=1):
        _kv_row(pdf, f"Principal {idx} Full Legal Name:", owner["name"])
        _kv_row(pdf, "  Title & Ownership Percentage:", f"{owner['title']} ({owner['pct']}% {owner['tier']})")
        _kv_row(pdf, "  Date of Birth (YYYY-MM-DD):", owner["dob"])
        _kv_row(pdf, "  SSN Last 4 Digits:", owner["ssn_last4"])
        _kv_row(pdf, "  Citizenship & U.S. Residency Status:", f"{owner['citizenship']} | Resides in U.S.: {owner['us_resident']}")
        pdf.ln(1)

    pdf.ln(3)
    pdf.set_font("Helvetica", "B", 10)
    pdf.set_text_color(12, 45, 90)
    pdf.cell(0, 7, "SECTION III: STATUTORY ELIGIBILITY ATTESTATIONS", new_x="LMARGIN", new_y="NEXT")
    _kv_row(
        pdf,
        "100% U.S. Citizen/National Ownership Attested:",
        "YES - Applicant certifies 0% foreign or non-resident ownership per Policy Notice 5000-876441.",
        label_w=82,
    )
    _kv_row(pdf, "Prior Federal Debt Default (CAIVRS) Disclosed:", data.get("caivrs_disclosed", "NO"), label_w=82)
    _kv_row(pdf, "Electronic Signature & Date:", f"{data['owners'][0]['name']} | Signed {data['signed_date']}", label_w=82)

    pdf.output(output_path)
    return output_path


def generate_operating_agreement_pdf(output_path: str, data: Dict) -> str:
    pdf = FPDF()
    pdf.add_page()
    pdf.set_auto_page_break(auto=True, margin=15)

    _header_banner(
        pdf,
        f"SECRETARY OF STATE FILING & CORPORATE GOVERNANCE RECORD - STATE OF {data['state'].upper()}",
        "AMENDED AND RESTATED LLC OPERATING AGREEMENT",
        f"Company: {data['legal_name']} | EIN: {data['ein']} | Effective Date: {data['effective_date']}",
    )

    pdf.set_font("Helvetica", "B", 10)
    pdf.set_text_color(12, 45, 90)
    pdf.cell(0, 7, "ARTICLE I: ENTITY FORMATION AND PURPOSE", new_x="LMARGIN", new_y="NEXT")
    _kv_row(pdf, "Registered Legal Entity Name:", data["legal_name"])
    _kv_row(pdf, "Employer Identification Number (EIN):", data["ein"])
    _kv_row(pdf, "SAM.gov Unique Entity Identifier (UEI):", data.get("uei", "N/A"))
    _kv_row(pdf, "Jurisdiction of Organization:", data["state"])
    _kv_row(pdf, "Registered Principal Office:", data["address"])
    pdf.ln(3)

    pdf.set_font("Helvetica", "B", 10)
    pdf.set_text_color(12, 45, 90)
    pdf.cell(
        0,
        7,
        "SCHEDULE A: COMPLETE DIRECT AND INDIRECT BENEFICIAL OWNERSHIP LEDGER",
        new_x="LMARGIN",
        new_y="NEXT",
    )
    for line in data["ownership_lines"]:
        pdf.set_font("Helvetica", "", 9)
        pdf.set_text_color(0, 0, 0)
        pdf.multi_cell(0, 5, f"- {line}", new_x="LMARGIN", new_y="NEXT")
    pdf.ln(2)
    _kv_row(pdf, "Effective U.S. Citizen Ownership Total:", f"{data['us_citizen_total_pct']}%")
    _kv_row(pdf, "Effective Ineligible Foreign/Non-Resident Total:", f"{data['ineligible_foreign_pct']}%")
    pdf.ln(3)

    pdf.set_font("Helvetica", "B", 10)
    pdf.set_text_color(12, 45, 90)
    pdf.cell(
        0,
        7,
        "ARTICLE IV & VI: MANAGEMENT CONTROL, SIGNATORY AUTHORITY, AND SUBCONTRACTING",
        new_x="LMARGIN",
        new_y="NEXT",
    )
    pdf.set_font("Helvetica", "", 9)
    pdf.set_text_color(0, 0, 0)
    pdf.multi_cell(0, 5, data["control_clause"], new_x="LMARGIN", new_y="NEXT")
    pdf.ln(2)
    pdf.multi_cell(0, 5, data["subcontract_clause"], new_x="LMARGIN", new_y="NEXT")
    pdf.ln(2)
    _kv_row(
        pdf,
        "Qualifying Disadvantaged Unconditional Control:",
        "YES" if data["unconditional_disadvantaged_control"] else "NO - Vested in Non-Disadvantaged Minority Member",
        label_w=82,
    )
    _kv_row(pdf, "Affiliate Subcontracting Pass-Through Ratio:", f"{data['subcontract_passthrough_pct']}%", label_w=82)

    pdf.output(output_path)
    return output_path


def generate_owner_id_pdf(output_path: str, data: Dict) -> str:
    pdf = FPDF()
    pdf.add_page()
    pdf.set_auto_page_break(auto=False)

    _header_banner(
        pdf,
        "UNITED STATES OF AMERICA - IDENTITY & CITIZENSHIP VERIFICATION RECORD",
        data["id_type"].upper(),
        f"Associated SBA Applicant Entity: {data['legal_name']} (EIN: {data['ein']})",
    )

    pdf.set_fill_color(210, 215, 222)
    pdf.rect(14, 48, 36, 44, "F")
    pdf.set_xy(14, 94)
    pdf.set_font("Helvetica", "", 7)
    pdf.set_text_color(90, 90, 90)
    pdf.cell(36, 4, "PRINCIPAL PHOTO", align="C")

    pdf.set_xy(58, 48)
    pdf.set_left_margin(58)
    _kv_row(pdf, "Full Legal Name:", data["full_name"], label_w=52)
    _kv_row(pdf, "Document Number:", data["doc_number"], label_w=52)
    _kv_row(pdf, "Citizenship / Nationality:", data["citizenship"], label_w=52)
    _kv_row(pdf, "Country Code:", data["country_code"], label_w=52)
    _kv_row(pdf, "Date of Birth:", data["dob"], label_w=52)
    _kv_row(pdf, "Residential Address:", data["address"], label_w=52)
    _kv_row(pdf, "Issue Date:", data["issue_date"], label_w=52)
    _kv_row(pdf, "Expiration Date:", data["expiry_date"], label_w=52)
    _kv_row(pdf, "Issuing Authority:", data["authority"], label_w=52)
    pdf.set_left_margin(10)

    pdf.output(output_path)
    return output_path


def generate_showcase_pdfs(apps_dir: Path) -> List[str]:
    created = []

    # 1. SBAID-DEMO-001: Apex Precision Machining LLC - Clean IRS 4506-C / 1120-S Transcript
    p1 = apps_dir / "IRSTaxTranscript_4506C_sba-doc-0001-4506c-apex.pdf"
    generate_tax_transcript_pdf(
        str(p1),
        {
            "tax_period": "2025-12-31",
            "legal_name": "Apex Precision Machining LLC",
            "ein": "34-8821904",
            "address": "4180 Euclid Industrial Pkwy, Cleveland, OH 44114",
            "naics_code": "332710",
            "naics_desc": "Machine Shops",
            "formation_date": "2014-06-12",
            "employees": 42,
            "gross_receipts": 4820000,
            "cogs": 2490000,
            "payroll": 1640000,
            "net_income": 612000,
            "owners": [
                {"name": "David R. Miller", "pct": 65.0, "citizenship": "U.S. Citizen (USA)", "dob": "1978-05-14"},
                {"name": "Sarah K. Miller", "pct": 35.0, "citizenship": "U.S. Citizen (USA)", "dob": "1980-11-22"},
            ],
        },
    )
    created.append(str(p1))

    # 2. SBAID-DEMO-002: Harborview Logistics Group LLC - Multi-Tier Operating Agreement with 10% Indirect Foreign Owner
    p2 = apps_dir / "OperatingAgreement_sba-doc-0002-opag-harbor.pdf"
    generate_operating_agreement_pdf(
        str(p2),
        {
            "state": "Texas",
            "legal_name": "Harborview Logistics Group LLC",
            "ein": "76-4410982",
            "uei": "H4L9V2X8M1N5",
            "effective_date": "2024-09-01",
            "address": "8800 Wallisville Rd, Houston, TX 77029",
            "ownership_lines": [
                "Tier 1 Direct Member 1: Michael T. Reynolds | 60.0% Direct Interest | U.S. Citizen | Residence: Houston, TX | DOB: 1975-03-09",
                "Tier 1 Direct Member 2: Harborview Holdings LP (Delaware Limited Partnership) | 40.0% Direct Interest",
                "Tier 2 Indirect Partner 2A (via Harborview Holdings LP): Elena V. Reynolds | 75.0% of Parent (30.0% Effective Indirect Interest) | U.S. Citizen | Residence: Houston, TX | DOB: 1977-08-21",
                "Tier 2 Indirect Partner 2B (via Harborview Holdings LP): Carlos Mendez-Silva | 25.0% of Parent (10.0% Effective Indirect Interest) | Foreign National (Non-U.S. Citizen) | Residence: Monterrey, Mexico | DOB: 1971-12-04",
            ],
            "us_citizen_total_pct": 90.0,
            "ineligible_foreign_pct": 10.0,
            "control_clause": (
                "Article IV Management: Day-to-day operational management and banking authority of Harborview Logistics Group LLC "
                "is vested in Managing Member Michael T. Reynolds."
            ),
            "subcontract_clause": (
                "Article VI Commercial Operations: Company operates commercial freight and port drayage services with its own W-2 workforce "
                "(0% federal set-aside subcontract pass-through)."
            ),
            "unconditional_disadvantaged_control": True,
            "subcontract_passthrough_pct": 0,
        },
    )
    created.append(str(p2))

    # 3. SBAID-DEMO-003: Sunbelt Staffing Solutions Inc - IRS 4506-C showing $410K revenue vs $3.40M claimed
    p3 = apps_dir / "IRSTaxTranscript_4506C_sba-doc-0003-4506c-sunbelt.pdf"
    generate_tax_transcript_pdf(
        str(p3),
        {
            "tax_period": "2025-12-31",
            "legal_name": "Sunbelt Staffing Solutions Inc",
            "ein": "59-7730218",
            "address": "7900 Biscayne Blvd, Suite 410, Miami, FL 33138",
            "naics_code": "561311",
            "naics_desc": "Employment Placement Agencies",
            "formation_date": "2021-02-18",
            "employees": 4,
            "gross_receipts": 410000,
            "cogs": 0,
            "payroll": 115000,
            "net_income": 28400,
            "owners": [
                {"name": "Victor M. Delgado", "pct": 100.0, "citizenship": "U.S. Citizen (USA)", "dob": "1982-07-19"},
            ],
        },
    )
    created.append(str(p3))

    # 4. SBAID-DEMO-004: Metro Property Restoration LLC - Form 1919 with DOB 1908-04-12 (Age 118 / Deceased SSN)
    p4 = apps_dir / "Form1919_sba-doc-0004-1919-metro.pdf"
    generate_form_1919_pdf(
        str(p4),
        {
            "program": "SBA Disaster Business Physical & Economic Injury Loan (EIDL)",
            "legal_name": "Metro Property Restoration LLC",
            "ein": "58-9034112",
            "address": "1420 Peachtree St NE, Atlanta, GA 30309",
            "naics_code": "236118",
            "naics_desc": "Residential Remodelers",
            "loan_amount": 500000,
            "stated_revenue": 1250000,
            "stated_payroll": 380000,
            "employees": 9,
            "packager_id": "PKG-9901",
            "owners": [
                {
                    "name": "Arthur H. Pendelton",
                    "title": "Sole Managing Member",
                    "pct": 100.0,
                    "tier": "Direct",
                    "dob": "1908-04-12",
                    "ssn_last4": "4409",
                    "citizenship": "U.S. Citizen (USA)",
                    "us_resident": "YES",
                }
            ],
            "caivrs_disclosed": "NO",
            "signed_date": "2026-11-12",
        },
    )
    created.append(str(p4))

    # 5. SBAID-DEMO-005: Potomac Cyber Defense LLC - Operating Agreement (uploaded as IRSTaxTranscript_4506C) exposing 8(a) pass-through front
    p5 = apps_dir / "OperatingAgreement_sba-doc-0005-opag-potomac.pdf"
    generate_operating_agreement_pdf(
        str(p5),
        {
            "state": "Virginia",
            "legal_name": "Potomac Cyber Defense LLC",
            "ein": "54-6198320",
            "uei": "J8K4M9P2Q7R1",
            "effective_date": "2025-04-15",
            "address": "1750 Tysons Blvd, Suite 900, McLean, VA 22102",
            "ownership_lines": [
                "Member 1 (Qualifying 8(a) Individual): Marcus A. Vance | 51.0% Direct Membership Interest | U.S. Citizen | Residence: Arlington, VA | DOB: 1984-02-11",
                "Member 2 (Non-Disadvantaged Minority Investor): Richard K. Sterling (President of Apex Federal Systems Corp) | 49.0% Direct Membership Interest | U.S. Citizen | Residence: Great Falls, VA | DOB: 1969-09-30",
            ],
            "us_citizen_total_pct": 100.0,
            "ineligible_foreign_pct": 0.0,
            "control_clause": (
                "Article IV Governance & Bank Control: Notwithstanding nominal equity percentages, sole operational bank signatory authority, "
                "executive compensation approval, and contract execution authority above $5,000 are vested exclusively in Minority Member "
                "Richard K. Sterling. Qualifying Member Marcus A. Vance may not hire officers or disburse company funds without written approval "
                "of Richard K. Sterling."
            ),
            "subcontract_clause": (
                "Article VI Mandatory Subcontracting Addendum: Company shall subcontract eighty-five percent (85%) of all gross billings from "
                "SBA 8(a) sole-source and set-aside federal contracts directly to affiliate Apex Federal Systems Corp."
            ),
            "unconditional_disadvantaged_control": False,
            "subcontract_passthrough_pct": 85,
        },
    )
    created.append(str(p5))

    return created


BATCH_COMPANIES = [
    (" Heartland Grain Milling Inc", "42-3109441", "311211", "Flour Milling", "Des Moines, IA 50309", "Iowa"),
    ("Blue Ridge HVAC Services LLC", "54-8823109", "238220", "Plumbing, Heating, and Air-Conditioning Contractors", "Roanoke, VA 24011", "Virginia"),
    ("Cascade Timber Fabricators Corp", "91-5540287", "321992", "Prefabricated Wood Building Manufacturing", "Tacoma, WA 98402", "Washington"),
    ("Great Lakes Tool & Die LLC", "38-7012945", "333514", "Special Die and Tool Manufacturing", "Grand Rapids, MI 49503", "Michigan"),
    ("Lone Star Medical Supply Inc", "75-6291034", "423450", "Medical Equipment Merchant Wholesalers", "Dallas, TX 75201", "Texas"),
    ("Palmetto Coastal Cold Storage LLC", "57-4902188", "493120", "Refrigerated Warehousing and Storage", "Charleston, SC 29401", "South Carolina"),
    ("Allegheny Robotics Automation Corp", "25-8391044", "333999", "Industrial Machinery Manufacturing", "Pittsburgh, PA 15222", "Pennsylvania"),
    ("Canyon State Solar Installers LLC", "86-3920175", "238210", "Electrical Contractors", "Phoenix, AZ 85004", "Arizona"),
    ("Keystone Specialty Packaging Inc", "23-7481920", "322211", "Corrugated and Solid Fiber Box Manufacturing", "Allentown, PA 18101", "Pennsylvania"),
    ("Prairie Wind Ag Equipment LLC", "48-5190322", "333111", "Farm Machinery and Equipment Manufacturing", "Wichita, KS 67202", "Kansas"),
    ("Buckeye Composite Materials Inc", "31-9045123", "326199", "Plastics Product Manufacturing", "Columbus, OH 43215", "Ohio"),
    ("Bayou Marine Repair Services LLC", "72-6084319", "336611", "Ship Building and Repairing", "Baton Rouge, LA 70801", "Louisiana"),
    ("Granite Peak Precision Optics Corp", "02-4418930", "333310", "Optical Instrument and Lens Manufacturing", "Nashua, NH 03060", "New Hampshire"),
    ("Hoosier Forging & Stamping LLC", "35-7729104", "332111", "Iron and Steel Forging", "Fort Wayne, IN 46802", "Indiana"),
    ("Cumberland Valley Logistics Inc", "62-5839201", "484121", "General Freight Trucking, Long-Distance", "Nashville, TN 37203", "Tennessee"),
]

OWNER_NAMES = [
    ("Robert J. Callahan", "1974-04-18"),
    ("agenda", "1979-09-12"),
]

BATCH_OWNERS = [
    ("Robert J. Callahan", "1974-04-18"),
    ("Patricia M. Alvarez", "1981-09-12"),
    ("Thomas E. Lindqvist", "1968-11-05"),
    ("Angela D. Brooks", "1979-02-27"),
    ("daniel K. Whitaker", "1985-07-30"),
    ("Rebecca L. Morales", "1976-12-14"),
    ("Gregory S. Okafor", "1972-06-03"),
    ("Hannah C. Zimmerman", "1983-08-22"),
    ("Kenneth P. McAllister", "1970-01-19"),
    ("natalie R. Cho", "1987-05-09"),
    ("Steven B. Kowalski", "1975-10-11"),
    ("monica J. Thibodeaux", "1980-03-25"),
    ("Claire E. Beaulieu", "1977-07-07"),
    ("mark A. Hendrickson", "1969-09-16"),
    ("Jason W. Boone", "1982-11-28"),
]


def generate_extra_batch_pdfs(apps_dir: Path, count: int) -> List[Dict]:
    rng = random.Random(20261118)
    manifest = []
    doc_types = ["Form1919", "IRSTaxTranscript_4506C", "OwnerGovernmentID"]

    for i in range(count):
        comp_name, ein, naics, naics_desc, city_zip, state_name = BATCH_COMPANIES[i % len(BATCH_COMPANIES)]
        comp_name = comp_name.strip()
        owner_raw, dob = BATCH_OWNERS[i % len(BATCH_OWNERS)]
        owner_name = " ".join(w.capitalize() if len(w) > 2 else w.upper() for w in owner_raw.split())
        dtype = doc_types[i % len(doc_types)]
        doc_id = f"sba-batch-{i + 1:04d}"
        file_name = f"{dtype}_{doc_id}.pdf"
        out_path = apps_dir / file_name
        rev = rng.randint(850, 6200) * 1000
        payroll = int(rev * 0.32)
        emps = rng.randint(8, 75)
        addr = f"{100 + i * 17} Commerce Park Dr, {city_zip}"

        if dtype == "IRSTaxTranscript_4506C":
            generate_tax_transcript_pdf(
                str(out_path),
                {
                    "tax_period": "2025-12-31",
                    "legal_name": comp_name,
                    "ein": ein,
                    "address": addr,
                    "naics_code": naics,
                    "naics_desc": naics_desc,
                    "formation_date": "2016-04-01",
                    "employees": emps,
                    "gross_receipts": rev,
                    "cogs": int(rev * 0.48),
                    "payroll": payroll,
                    "net_income": int(rev * 0.11),
                    "owners": [
                        {"name": owner_name, "pct": 100.0, "citizenship": "U.S. Citizen (USA)", "dob": dob}
                    ],
                },
            )
        elif dtype == "Form1919":
            generate_form_1919_pdf(
                str(out_path),
                {
                    "program": "SBA 7(a) Standard Loan Guaranty",
                    "legal_name": comp_name,
                    "ein": ein,
                    "address": addr,
                    "naics_code": naics,
                    "naics_desc": naics_desc,
                    "loan_amount": rng.randint(250, 1500) * 1000,
                    "stated_revenue": rev,
                    "stated_payroll": payroll,
                    "employees": emps,
                    "packager_id": "NONE - Direct Submission",
                    "owners": [
                        {
                            "name": owner_name,
                            "title": "President & Managing Principal",
                            "pct": 100.0,
                            "tier": "Direct",
                            "dob": dob,
                            "ssn_last4": f"{4100 + i:04d}",
                            "citizenship": "U.S. Citizen (USA)",
                            "us_resident": "YES",
                        }
                    ],
                    "caivrs_disclosed": "NO",
                    "signed_date": "2026-11-10",
                },
            )
        else:
            generate_owner_id_pdf(
                str(out_path),
                {
                    "id_type": "United States Passport Card",
                    "legal_name": comp_name,
                    "ein": ein,
                    "full_name": owner_name,
                    "doc_number": f"C{8300100 + i}",
                    "citizenship": "United States of America",
                    "country_code": "USA",
                    "dob": dob,
                    "address": addr,
                    "issue_date": "2022-05-15",
                    "expiry_date": "2032-05-14",
                    "authority": "U.S. Department of State",
                },
            )

        manifest.append(
            {
                "doc_id": doc_id,
                "doc_type": dtype,
                "file_path": f"applications/{file_name}",
                "legal_name": comp_name,
                "ein": ein,
                "naics": naics,
                "naics_desc": naics_desc,
                "state_name": state_name,
                "rev": rev,
                "payroll": payroll,
                "emps": emps,
                "owner_name": owner_name,
                "dob": dob,
            }
        )

    return manifest


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate SBA synthetic PDFs")
    parser.add_argument("--output", default="./pdfs", help="Output base directory")
    parser.add_argument("--extra-count", type=int, default=15, help="Additional batch PDFs beyond 5 showcase PDFs")
    args = parser.parse_args()

    apps_dir = Path(args.output) / "applications"
    apps_dir.mkdir(parents=True, exist_ok=True)

    showcase = generate_showcase_pdfs(apps_dir)
    batch = generate_extra_batch_pdfs(apps_dir, args.extra_count)
    print(f"Generated {len(showcase)} showcase PDFs and {len(batch)} batch PDFs in {apps_dir}")


if __name__ == "__main__":
    main()
