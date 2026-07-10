# policy-revenue-leakage-detection

# Insurance Claims Leakage & KPI Trust Control Tower

## Project Overview

This project is an end-to-end insurance analytics solution built using Snowflake, dbt, SQL, and Power BI. It transforms raw insurance claims, premiums, policies, customers, agents, and claim adjustment data into tested BI-ready marts for executive KPI reporting and claims leakage investigation.

The goal of this project is to monitor premium performance, paid claims, loss ratio, claim severity, policy risk, regional trends, and potential claims leakage using a modern BI workflow.

## Tech Stack

- Snowflake
- dbt
- SQL
- Power BI Desktop
- DAX
- Data Modeling
- Data Quality Testing
- Business Intelligence Reporting

## Business Problem

Insurance companies need reliable reporting to understand claim payouts, premium collection, policy risk, and possible claims leakage. Raw operational data is often spread across claims, policies, premiums, customers, agents, and adjustment tables.

This project builds a trusted reporting layer that helps answer:

- Which policy types have the highest loss ratio?
- Which regions have the highest paid claims?
- Which claims may be duplicate or suspicious?
- Which claims occurred after policy expiration?
- Which claims were paid without premium collection?
- Which claims should be prioritized for investigation?

## dbt Model Layers
## Staging Layer

The staging layer standardizes raw Snowflake tables:

stg_customers
stg_agents
stg_policies
stg_premiums
stg_claims
stg_claim_adjustments
## Intermediate Layer

The intermediate layer builds business logic:

int_policy_premium_summary
int_policy_claim_summary
int_claim_leakage_flags
## Mart Layer

The final mart layer creates BI-ready reporting tables:

mart_insurance_performance
mart_claims_leakage
## Key Business Logic

The claims leakage model flags:

Duplicate claims
Claims after policy end date
Claims without paid premium
High-severity claims
Claims with adjustment activity

A leakage risk score is assigned to help prioritize claim investigation.

## Power BI Dashboard Pages
## Executive Overview

Tracks paid premium, paid claims, loss ratio, policy count, claim count, risk claims, premium vs claims by policy type, claims by region, and policy status distribution.

## Claims Leakage Investigation

Tracks leakage rule summary, risk concentration by region and claim type, paid amount vs leakage risk score, paid amount by claim severity, and top high-risk claims for investigation.

## Data Quality Testing

dbt tests were implemented for:

Not null checks
Unique key checks
Relationship checks
Accepted value checks
Business-rule validation
## Project Outcome

This project demonstrates the ability to build a modern BI solution using Snowflake, dbt, SQL, and Power BI. It covers raw data ingestion, data modeling, transformation logic, data quality validation, KPI reporting, and claims leakage investigation.

## Data Pipeline

```text
CSV Files
   ↓
Snowflake Raw Tables
   ↓
dbt Staging Models
   ↓
dbt Intermediate Business Logic
   ↓
dbt Final Marts
   ↓
Power BI Dashboard
