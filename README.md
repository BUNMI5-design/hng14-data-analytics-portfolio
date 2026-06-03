# Balogun Bunmi — HNG 14 Data Analytics Portfolio

**Data Analyst | SQL · Python · Power BI · dbt · Airflow · PostgreSQL**

This repository documents my complete journey through the HNG 14 Data Analytics Internship, one of Nigeria's most competitive tech internship programmes. I progressed through 8 stages, working on real-world data problems across analytics, data engineering, fraud detection and product research.

---

## Journey Summary

| Stage | Project | Tools | Achievement |
|---|---|---|---|
| Stage 3 | TradeZone — E-commerce SQL Analysis | SQL, PostgreSQL | Passed |
| Stage 4 | Climate Change Twitter Sentiment Analysis | SQL, PostgreSQL, Power BI | 3rd place out of 385 analysts |
| Stage 5 | Nigeria 2026 Budget — ₦58 Trillion But For Who? | Python, Excel | Top 5, Score 78.5 |
| Stage 6 | Anvila — AI Product Market Research | Google Trends, Keyword Planner | 1st place, Score 8.07 |
| Stage 7 | Fraud Detection in Blockchain Payments | Python, NetworkX, Plotly | Completed |
| Stage 8 | RetailCo Data Platform — End-to-End Pipeline | Python, dlt, dbt, Airflow, PostgreSQL, Docker | Completed |

---

## Projects

### Stage 3 — TradeZone E-commerce SQL Analysis
**Tools:** SQL, PostgreSQL

Analysed sales data for a fictional e-commerce platform called TradeZone. Wrote complex SQL queries to uncover revenue trends, top performing products and customer behaviour patterns.

[View Project](./stage-3-tradezone)

---

### Stage 4 — Climate Change Twitter Sentiment Analysis
**Tools:** SQL, PostgreSQL, Power BI
**Result: 3rd place out of 385 analysts**

Analysed 15.7 million tweets about climate change posted between 2006 and 2019. Built 15 analytical SQL views, ran 20 queries covering descriptive and diagnostic analytics, and delivered a 3-page Power BI dashboard.

Key findings:
- Climate believers grew from 16.67% to 79.40% over 14 years
- Climate deniers were 42.65% more aggressive than believers
- The Paris Agreement caused the largest single-year sentiment shift in the dataset
- 2.38 billion people were affected by climate-related disasters in the same period

[View Project](./stage-4-climate-twitter)

---

### Stage 5 — Nigeria 2026 Federal Budget Analysis
**Tools:** Python, Excel
**Result: Top 5, Score 78.5**

Led a 5-person team analysing Nigeria's 2026 Federal Government Budget. Extracted data from a 2,790-page government PDF using Python, structured 56 MDAs into a clean Excel workbook and cross-verified figures against two official government sources.

Story angle: **₦58 Trillion — But For Who?**

Key findings:
- Debt servicing received more than education, health and agriculture combined
- Infrastructure allocation dropped 12% compared to the previous year
- Only 6 MDAs received over 50% of the total budget

[View Project](./stage-5-nigeria-budget)

---

### Stage 6 — Anvila AI Product Market Research
**Tools:** Google Trends, Google Keyword Planner
**Result: 1st place, Score 8.07**

Conducted full market research for Anvila — an AI agent scaffolding and configuration tool. Researched 20 keywords, classified each by search intent, funnel layer, monthly volume and competition level. Identified zero-competition gap opportunities for a new AI product category. Also defined 3 user personas, TAM/SAM/SOM market sizing and 4 frontend analytics event tracking specifications.

[View Project](./stage-6-anvila)

---

### Stage 7 — Fraud Detection in Blockchain Payments
**Tools:** Python, NetworkX, Plotly, Pyvis, Pandas
**Dataset:** Elliptic Bitcoin Transaction Dataset — 203,769 transactions, 234,355 edges

Built a complete fraud detection pipeline on a real blockchain transaction dataset. Constructed a directed graph of 203,769 nodes, detected suspicious patterns using layering and fan-out analysis, and flagged 886 high-risk nodes using a composite risk score combining betweenness centrality, PageRank and degree centrality.

Key findings:
- 4,545 transactions confirmed illicit (2.2% of dataset)
- 886 nodes flagged as suspicious through pattern detection
- Highest risk activity concentrated at time steps 22 and 40
- Delivered a self-contained HTML compliance dashboard

[View Project](./stage-7-fraud-detection)

---

### Stage 8 — RetailCo Data Platform
**Tools:** Python, dlt, dbt, Apache Airflow, PostgreSQL, Docker
**Scale:** 876,511 records across 9 entities

Built a complete end-to-end data engineering pipeline for a fictional Nigerian retail chain with 4 stores across Lagos, Abuja, Port Harcourt and Kano. The pipeline automatically extracts data from a legacy ERP API, loads it into a data warehouse and transforms it into Kimball dimensional models ready for business analysis.

Key deliverables:
- Python extractor with incremental loading, watermarking, rate limit handling and idempotency
- dlt incremental load pipeline from lake to warehouse
- 9 dbt staging models, 6 dimensions, 4 fact tables, 1 data quality table
- SCD Type 2 on dim_customer and dim_product
- 106 out of 106 dbt tests passing
- Apache Airflow DAG running daily at 2am WAT
- Full Docker containerisation

Business insights delivered:
- Abuja leads revenue at ₦2.61 billion
- Revenue grew over 37,000% from 2024 to 2026
- 1,398 anomalous payments automatically caught and quarantined
- Average order delivery time of 13 days

[View Project](./stage-8-retailco-pipeline) · [Team GitHub Repo](https://github.com/R887645/RetailCo-Data-Platform-HNG-Stage-8_TeamF)

---

## Skills Demonstrated

| Skill | Stages |
|---|---|
| SQL and PostgreSQL | Stage 3, Stage 4 |
| Python — pandas, matplotlib, seaborn | Stage 5, Stage 7 |
| Power BI — DAX, Power Query, dashboards | Stage 4 |
| Excel — PivotTables, dashboards, data cleaning | Stage 5 |
| dbt — staging, snapshots, dimensions, facts, tests | Stage 8 |
| Apache Airflow — DAGs, scheduling, orchestration | Stage 8 |
| Docker and Docker Compose | Stage 8 |
| Graph analytics — NetworkX, PageRank, centrality | Stage 7 |
| Market research and keyword analysis | Stage 6 |
| Data storytelling and business reporting | Stage 4, Stage 5, Stage 6, Stage 7, Stage 8 |

---

## About Me

I am a data analyst based in Lagos, Nigeria with a B.Sc. in Actuarial Science from the University of Lagos. I am passionate about turning raw data into clear business insights and building reliable data systems that answer real questions.

Through the HNG 14 internship I worked across the full data spectrum, from writing SQL queries and building Power BI dashboards to building production-grade data pipelines with dbt and Airflow.

**Connect with me:**
- LinkedIn: [linkedin.com/in/balogunbunmi](https://linkedin.com/in/balogunbunmi)
- GitHub: [github.com/BUNMI5-design](https://github.com/BUNMI5-design)

---

*HNG 14 Data Analytics Internship — Lagos, Nigeria — 2026*
