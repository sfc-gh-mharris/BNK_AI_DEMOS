import streamlit as st
from snowflake.snowpark.context import get_active_session
from datetime import date

session = get_active_session()

USE_CASES = {
    "Customer 360": {
        "schema": "BNK.CUSTOMER_360",
        "canary": ("TRANSACTIONS", "TXN_DATE"),
        "updates": [
            ("CUSTOMERS", ["CREATED_DATE"]),
            ("ACCOUNTS", ["OPENED_DATE"]),
            ("TRANSACTIONS", ["TXN_DATE"]),
            ("INTERACTIONS", ["INTERACTION_DATE"]),
            ("OFFERS", ["SENT_DATE", "EXPIRES_DATE"]),
            ("CUSTOMER_NOTES", ["NOTE_DATE"]),
        ],
        "recalculations": [],
    },
    "KYC/AML": {
        "schema": "BNK.KYC_AML",
        "canary": ("ALERT_QUEUE", "CREATED_DATE"),
        "updates": [
            ("CLIENTS", ["ONBOARDING_DATE"]),
            ("KYC_CASES", ["OPENED_DATE", "DUE_DATE", "CLOSED_DATE"]),
            ("DOCUMENTS_METADATA", ["UPLOAD_DATE"]),
            ("VERIFICATION_RESULTS", ["VERIFICATION_DATE"]),
            ("ALERT_QUEUE", ["CREATED_DATE"]),
        ],
        "recalculations": [],
    },
    "Lending": {
        "schema": "BNK.LENDING",
        "canary": ("PAYMENTS", "PAYMENT_DATE"),
        "updates": [
            ("BORROWERS", ["CREATED_DATE"]),
            ("MORTGAGES", ["ORIGINATION_DATE"]),
            ("PAYMENTS", ["PAYMENT_DATE"]),
            ("RISK_SCORES", ["SCORE_DATE"]),
            ("REFINANCE_SIGNALS", ["DETECTED_DATE"]),
            ("INTERACTION_HISTORY", ["INTERACTION_DATE"]),
        ],
        "recalculations": [
            "UPDATE {schema}.MORTGAGES SET MATURITY_DATE = DATEADD(year, TERM_YEARS, ORIGINATION_DATE)",
        ],
    },
    "Wealth Management": {
        "schema": "BNK.WEALTH_MGMT",
        "canary": ("TRADES", "TRADE_DATE"),
        "updates": [
            ("WM_CLIENTS", ["ONBOARDING_DATE", "RELATIONSHIP_START_DATE"]),
            ("PORTFOLIOS", ["INCEPTION_DATE"]),
            ("HOLDINGS", ["AS_OF_DATE"]),
            ("MARKET_DATA", ["TRADE_DATE"]),
            ("TRADES", ["TRADE_DATE", "SETTLEMENT_DATE"]),
            ("CLIENT_NOTES", ["NOTE_DATE"]),
        ],
        "recalculations": [],
    },
}


def get_freshness(schema, table, column):
    try:
        row = session.sql(
            f"SELECT MAX({column})::DATE AS max_dt FROM {schema}.{table}"
        ).collect()
        if row and row[0]["MAX_DT"]:
            max_dt = row[0]["MAX_DT"]
            if isinstance(max_dt, str):
                max_dt = date.fromisoformat(max_dt)
            return max_dt, (date.today() - max_dt).days
    except Exception:
        pass
    return None, None


def refresh_use_case(config):
    schema = config["schema"]
    canary_table, canary_col = config["canary"]
    _, days_stale = get_freshness(schema, canary_table, canary_col)

    if days_stale is None:
        return "No data"
    if days_stale == 0:
        return "Already current"

    offset = days_stale
    for table, columns in config["updates"]:
        set_clauses = ", ".join(f"{col} = DATEADD(day, {offset}, {col})" for col in columns)
        session.sql(f"UPDATE {schema}.{table} SET {set_clauses}").collect()

    for recalc in config["recalculations"]:
        session.sql(recalc.format(schema=schema)).collect()

    return "Done"


st.title("Synthetic Data Manager")

# Build status table
rows = []
for name, config in USE_CASES.items():
    schema = config["schema"]
    canary_table, canary_col = config["canary"]
    max_dt, days_stale = get_freshness(schema, canary_table, canary_col)
    if max_dt is None:
        status = "NO DATA"
    elif days_stale == 0:
        status = "CURRENT"
    else:
        status = f"STALE ({days_stale}d)"
    rows.append({"Use Case": name, "Schema": schema, "Most Recent Date": str(max_dt or "—"), "Status": status})

select_all = st.checkbox("Select all", value=True)
selected = []

for row in rows:
    checked = st.checkbox(
        f"{row['Use Case']}  |  {row['Schema']}  |  {row['Most Recent Date']}  |  {row['Status']}",
        value=select_all,
        key=row["Use Case"],
    )
    if checked:
        selected.append(row["Use Case"])

if st.button("Refresh Selected"):
    if not selected:
        st.warning("Nothing selected.")
    else:
        for name in selected:
            config = USE_CASES[name]
            result = refresh_use_case(config)
            st.write(f"{name}: {result}")
