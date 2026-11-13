# Retail Customer Segmentation & Revenue Analysis

## Business Question
Which customers drive the most revenue for an online retailer, which valuable customers are at risk of leaving, and how much revenue could a win-back campaign recover?

## Dataset
- **Source:** [UCI Online Retail II](https://archive.ics.uci.edu/dataset/502/online+retail+ii) (CC BY 4.0)
- **What it is:** Transactions from a UK-based online gift-ware retailer, 01/12/2009 to 09/12/2011. Many customers are wholesalers.
- **Columns:** Invoice, StockCode, Description, Quantity, InvoiceDate, Price, Customer ID, Country
- The raw file is not included in this repo because of its size. Download it from the link above.

## Tools
PostgreSQL, Python (pandas, SQLAlchemy, matplotlib), Power BI (DAX)

## Data Cleaning
| Step | Rule | Rows remaining |
|---|---|---|
| 1 | Raw data | [raw rows] |
| 2 | Remove rows with no Customer ID | [rows] |
| 3 | Remove cancelled invoices (start with "C") | [rows] |
| 4 | Remove quantity <= 0 or price <= 0 | [rows] |
| 5 | Keep product stock codes only (removes POST, M, etc.) | [rows] |
| 6 | Remove exact duplicate rows | [clean rows] |

**Why:** Customers without an ID can't be tracked, cancellations would subtract from revenue, and non-product codes are fees, not sales.

## Methodology

### 1. Churn cutoff (data-driven)
Instead of assuming 90 days, I grouped product rows into one row per order, then calculated the days between each customer's consecutive orders. The 90th percentile of those gaps is **134 days**. A customer silent for longer than that is flagged as churned.

### 2. RFM scoring
For each customer I calculated:
- **Recency:** days since last purchase (relative to the day after the last transaction in the data)
- **Frequency:** number of distinct orders
- **Monetary:** total revenue

Each metric was ranked and split into quintiles with `pd.qcut` (rank first to avoid tie errors):
- R labels `[5,4,3,2,1]` (fewer days is better)
- F labels `[1,2,3,4,5]`
- M labels `[1,2,3,4,5]`

### 3. Segment rules (based on R and F scores)
| Rule | Segment |
|---|---|
| R >= 4 and F >= 4 | Champion |
| R >= 3 and F >= 3 | Loyal |
| R >= 4 and F <= 2 | New/Promising |
| R <= 2 and F >= 4 | At Risk |
| R <= 2 and F <= 2 | Lost |
| Everything else | Need Attention |

### 4. Validation
After scoring, I checked that the average recency, frequency and revenue moved in the expected direction across scores 1 to 5, and that each segment's averages matched its label. This caught a bug where the scores were reversed (see "Lessons learned").

## Key Findings
Total customers analysed: **5,878**

| Segment | Customers | Avg recency (days) | Avg revenue | Revenue share |
|---|---|---|---|---|
| Champion | 1,473 | 20 | £8,135 | 68.97% |
| Loyal | 1,229 | 78 | £2,075 | 14.68% |
| At Risk | 354 | 344 | £3,084 | 6.28% |
| Need Attention | 855 | 261 | £822 | 4.04% |
| Lost | 1,526 | 459 | £430 | 3.77% |
| New/Promising | 441 | 28 | £889 | 2.26% |

- **Revenue is highly concentrated.** Champions are about 25% of customers but generate about 69% of revenue (£11.98M).
- **Lost is the largest segment** by customer count (1,526) but contributes under 4% of revenue.
- **At Risk customers are the best win-back target.** They have not bought in about 11 months but previously averaged £3,084 each, about £1.09M of historical revenue in total.

## Recommendations
1. **Protect Champions** with loyalty rewards and early access, since losing a few would hurt revenue disproportionately.
2. **Run a win-back campaign for At Risk customers** first, as they combine high past spend with lapsed activity.
3. **Don't spend heavily on Lost customers.** They are numerous but low value.
4. **Nurture New/Promising customers** with a second-purchase offer to move them toward Loyal.

### Revenue recovery estimate
Assumption: reactivated customers spend their historical average (£3,084).

| Scenario | Reactivation rate | Customers won back | Recovered revenue |
|---|---|---|---|
| Low | 5% | ~18 | ~£55K |
| Base | 10% | ~35 | ~£109K |
| High | 15% | ~53 | ~£164K |

## Dashboard
Power BI dashboard with segment KPI cards, revenue and customer count by segment, a segment summary table, and slicers for date, country, segment and churn status.

## Limitations
- Data covers 2009 to 2011 for a single UK retailer, so patterns may not generalise.
- There is no cost, margin or marketing-spend data, so this estimates revenue recovery, not profit or campaign ROI.
- The churn cutoff is based on repeat buyers only. Single-purchase customers have no gaps to measure.
- The reactivation rates are assumptions, and past spend does not guarantee future spend.
- Segment rules use R and F scores only. The M score is calculated but not used in the rules.

## Lessons Learned
My first run produced reversed scores: the "Champion" group had the worst recency. I caught it by checking the average recency and revenue per segment, and fixed it by removing `ascending=False` from the `rank()` calls so that only R's labels were reversed. This is why I added validation checks after scoring.

## Repo Structure
```
├── sql/            cleaning and analysis queries
├── notebooks/      rfm_analysis.ipynb
├── dashboard/      .pbix file and screenshots
└── README.md
```
