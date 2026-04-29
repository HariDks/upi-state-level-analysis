# 2. Why this question matters

In January 2026, India processed 21.7 billion UPI transactions worth ₹28.33 lakh crore. That was a 28 percent increase over the same month a year earlier, and works out to roughly 700 million transactions every day.[^npci] UPI is now the largest retail payments system in the world by volume. In a single month it settles more transactions than the card networks of many large economies process in an entire year. The Indian government and the National Payments Corporation of India (NPCI), which operates the rail, regularly point to this scale as evidence that digital payments have meaningfully advanced financial inclusion.

That January 2026 figure is the latest point in a longer story. The story splits into two stretches worth analysing separately. The first is the early-UPI era of FY 2019-20 and FY 2020-21. UPI was one of several rails competing for digital-payment volume in that period. The state-level data publishes only a five-rail composite (BHIM + IMPS + RuPay POS + UPI + USSD). The second is the mature-UPI era from April 2023 through January 2026. By then UPI alone settled the bulk of retail digital payments, and state-level pure-UPI data became consistently available. Across the most recent twelve months (February 2025 through January 2026), the 36 states and union territories of India together processed about 142 billion state-attributable UPI transactions worth ₹197 lakh crore. That works out to roughly 8.3 transactions per person per month, weighted by population.[^panel] This note compares the two eras using a single set of state-level controls. That way, what changed about who uses digital payments, and what stayed the same, is visible in the coefficients.

[^npci]: National Payments Corporation of India, UPI Product Statistics, https://www.npci.org.in/what-we-do/upi/product-statistics. The January 2026 figures are reported in NPCI's monthly press release and in the business press (e.g., DD News and Business Standard, 1 February 2026).

[^panel]: Author's calculation from the panel constructed for this note. NPCI's all-India figure exceeds the state-summed total because a non-trivial share of transactions are reported under "Unclassified" and cannot be attributed to a specific state. The implications for the state-level analysis are discussed in section 3.

## The national average hides the state-level variation

The national figure of 8.3 monthly transactions per person hides a wide range across states. Tripura sits at the bottom with 3.4. Telangana and Goa sit at the top, both at 22.0. The gap is more than six-fold. The most-used states do about five times the per-capita volume of the most populous low-use states (figure 2, table 1). A national average that hides variation this large cannot tell us whether UPI's scale has reached people broadly. For policy purposes, the state is the right unit. Payments infrastructure, regulations, and inclusion programs are rolled out and evaluated at the state level. The populations they reach differ in ways a national average smooths over.

## Two readings of the gap, both true

The cross-state distribution can be read two ways. A useful policy account of UPI needs to hold both readings at once.

The first reading is that states are converging. Between April 2023 and January 2026, the cross-state coefficient of variation in monthly per-capita UPI fell by roughly ten percent per year. The standard deviation of log per-capita UPI fell at a similar rate (figure 4). In plain terms: low-use states are growing their per-capita UPI faster than high-use states are. The gap is closing.

The second reading is that the gap is still very large. The highest-use states do five to eight times what the lowest-use states do. The gap is narrowing, but it is far from closed.

## Why a financial-inclusion lens, specifically

UPI is routinely cited as a financial-inclusion success. But "UPI scaled" and "UPI scaled inclusively" are different claims, and the second is the more demanding one. The inclusion-relevant questions are state-comparable. Do states with more PMJDY beneficiaries, accounts opened under the government's flagship financial-inclusion scheme, actually use digital payments more? Does the density of bank branches and offices, the older form of financial-rail expansion, predict use in the same way that account access does? Does the income gradient absorb everything else once it is conditioned on? And do the answers look the same in the early and mature UPI eras, or has the relationship shifted as the rail matured? A two-period state-level analysis can answer these questions; a national time series cannot.

## What this note does

Section 3 sets the empirical stage with the cross-state snapshot for the most recent twelve months and the trend across the full 34 months of mature-era data. Section 4 presents three findings about what predicts state-level digital-payment use, each supported by two parallel regressions, one for the early-UPI era (FY 2019-20 and FY 2020-21) using the five-rail composite, one for the mature-UPI era (April 2023 through January 2026) using pure UPI data. Both regressions use the same set of state-level controls so the cross-era pattern is visible in the coefficients. Section 5 takes up what the findings imply for digital-payments and financial-inclusion policy. Methodology, full regression tables, and a diagnostic on one variable (literacy) that we set aside on measurement-validity grounds are in Appendix A; data sources and construction notes are in Appendix B.
