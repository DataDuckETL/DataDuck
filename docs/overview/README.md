# Overview

DataDuck ETL is a straightforward, effective extract-transform-load framework for data warehousing. If you want to set
up a data warehouse, DataDuck ETL makes it simple and straightforward to do.

## Getting Started

Getting started with DataDuck ETL takes just a few minutes. For instructions, read the
[getting started](/docs/overview/getting_started) page.

## Why Use a Data Warehouse

If you already have your data in your main database, and probably use a web analytics product like Google Analytics, you
may be wondering why you'd want a data warehouse anyway.

There's many advantages to using a data warehouse, including:

- integrating multiple data sources so you can analyze them together
- helping to ensure data quality by cleaning up the data and running data quality checks
- having a single source of truth that the entire company trusts
- connecting business intelligence products for reports and dashboards
- using the data warehouse to build models, which may get incorporated back in the product, or used for predictions and company decision making
- performance optimizations so your queries run fast
- ensuring sensitive data doesn't end up in reports, by not passing it to the data warehouse (encrypted passwords, salts, etc have no practical analytics value, so they are not ETLed)
