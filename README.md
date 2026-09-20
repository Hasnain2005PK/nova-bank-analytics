# Nova Bank — Retail Portfolio Analytics

An end-to-end data analyst project on a simulated retail bank: 12,000 customers, 18,704 accounts,
259,230 transactions and 5,520 loans — taken from a messy raw extract through SQL analysis to a
3-page Power BI dashboard.

---

## Dashboard Preview

**Overview**
![Overview](Dashboard%20Image%201.png)

**Customers & Deposits**
![Customers & Deposits](Dashboard%20Image%201.png)

**Credit Risk & Loan Book**
![Credit Risk](Dashboard%20Image%203.png)

---

## Project Workflow


| Stage | Tool | What happened |
|---|---|---|
| Data generation | — | Simulated core-banking extract with realistic data quality issues |
| Cleaning | Python (pandas) | Fixed duplicates, mixed date formats, inconsistent city names, missing values, outliers |
| Warehouse | MySQL | Loaded 5 clean tables, added primary/foreign keys, built ER diagram |
| Analysis | SQL | 11 business questions using JOINs, CASE WHEN, window functions (RANK, NTILE), CTEs |
| Visualization | Power BI | 3-page dashboard with DAX measures, KPI cards, and custom navigation |

---

## Repository Structure


---

## Data Cleaning — Issues Found & Fixed

| Issue | Rows affected | Fix |
|---|---|---|
| Duplicate customer records | 320 | Dropped, kept first occurrence |
| Dates in two formats (YYYY-MM-DD and DD/MM/YYYY) | ~3,500 | Parsed both into one column |
| City names inconsistent (casing, abbreviations like "LHR", "Isb") | 25 → 11 unique values | Standardised to canonical names |
| Missing income | 807 | Imputed with occupation-level median |
| Missing credit score | 452 | Imputed with portfolio median |
| Negative account balances | 63 | Nulled and flagged — not silently corrected |
| Duplicate transaction IDs | 900 | De-duplicated |
| Missing transaction amounts | 774 | Dropped — no reliable way to impute |
| Extreme transaction amounts | 260 | Capped at 99.9th percentile, original value retained |
| Missing loan interest rates | 288 | Imputed with product-level median |

---

## Key Findings

**Deposit value is heavily concentrated.** The top 10% of customers hold **39.05%** of all deposits.

**Nearly half of customers go quiet after their first month.** Month-1 drop-off is **48.3%**,
based on a cohort anchored to each customer's first transaction (not onboarding date, which
would have hidden this pattern).

**One segment needs urgent attention.** "At Risk — High Value" customers — 11.6% of the base —
hold 22% of transaction value but haven't transacted in an average of 448 days.

**Default rate climbs sharply with debt-to-income ratio**, and **Credit Card is the riskiest
product** in the loan book, consistent with it being unsecured and revolving credit.

---

## SQL Highlights

The `sql/business_questions.sql` file includes:
- Window functions: `RANK() OVER (PARTITION BY ...)`, `NTILE(10)`, `LAG()`
- CTEs (`WITH ... AS`) for multi-step analysis
- Conditional aggregation with `CASE WHEN`
- Multi-table `JOIN`s across a 5-table relational schema

---

## Tools

Python (pandas) · MySQL · Power BI (DAX, data modeling) · SQL (window functions, CTEs)

---

## Notes

- Data is fully simulated to mirror realistic Pakistani retail banking patterns and injected with
  deliberate data quality defects for the cleaning exercise.
- Some Power BI metrics (cohort retention curve, RFM segmentation) were calculated in Python and
  imported as tables, since these calculations were too computationally heavy for DAX on a
  259K-row transaction table.
