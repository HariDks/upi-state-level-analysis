# Appendix A. Methodology and detailed results

This appendix documents the estimator, sample, and full regression results that the body of the memo summarises. Data sources and construction are in Appendix B.

## A.1 Estimator and specification

The two regressions are pooled ordinary least squares with year fixed effects (early-UPI era) or year-window fixed effects (mature-UPI era) and standard errors clustered at the state level. The dependent variable and all continuous controls are log-transformed; coefficients are therefore elasticities. The fixed effects absorb the period-specific national level so the regression identifies cross-state variation rather than common time trends.

The early-UPI regression has four state-level controls: log(per-capita NSDP), log(urban share), log(PMJDY beneficiaries per adult), and log(bank offices per 100,000 population). The mature-UPI regression adds a fifth, log(internet density per 100 population), that becomes available only in that period. We do not run a within-state specification: with most controls largely time-invariant in the available data, state fixed effects would absorb the variation we are trying to identify. The research design is cross-state across multiple periods, with year/window FE absorbing common time trends.

The dependent variables are definitionally different across the two regressions and are not chained. The early-era DV is per-capita transactions on a five-rail composite (BHIM + IMPS + RuPay POS + UPI + USSD); the mature-era DV is per-capita pure UPI. Each regression is interpreted within its era; the cross-era comparison in A.5 reads coefficients on the four shared controls, not the dependent variables themselves.

A note on the timing of variables within a window. The dependent variable in the mature-era regression is a 12-month average of monthly per-capita UPI within each window. The state-level controls are not 12-month averages, they are point-in-time snapshots (PMJDY beneficiaries, bank-office density, internet density), annual figures (per-capita NSDP, literacy), or interpolated values (urban share) measured at or near the relevant window. This is the standard cross-section convention in economics: outcomes are aggregated over a window, slow-moving covariates are measured at a point in time near the window. For the variables we use, the asymmetry is not a substantive concern because the controls move only modestly within a 12-month period, urban share by less than 0.5 percentage points per year, PMJDY enrollment as a slow-growing cumulative stock, bank-office density by under 5 percent per year, literacy still more slowly. The cross-state ordering of each control would be essentially the same whether we used a snapshot or a hypothetical 12-month average; for variables published only at annual or quarterly frequency, a 12-month average is not even constructible. Appendix B documents the specific snapshot date used for each control and each window.

## A.2 Sample

The early-UPI regression is 35 states × 2 fiscal years (FY 2019-20 + FY 2020-21) = 70 state-FY observations, of which 66 enter the regression after dropping two states with persistently missing per-capita NSDP data (Lakshadweep, Dadra and Nagar Haveli and Daman and Diu). The sample is 35 states rather than 36 because the source treats Jammu and Kashmir as a single unit; Ladakh did not exist as a separate union territory until October 2019 and is absent from the early-era source.

The mature-UPI regression is 36 states × 3 twelve-month windows = 108 state-window observations. The three windows are April 2023 – March 2024, April 2024 – March 2025, and a rolling February 2025 – January 2026. The third window is rolling rather than fiscal-year-aligned because monthly data through March 2026 is not yet published; treating it as a twelve-month average preserves the same window length across observations. The regression sample drops three states with persistent missing data (Lakshadweep, Ladakh, Dadra and Nagar Haveli and Daman and Diu), leaving 99 state-window observations from 33 states.

Cluster counts are 33 in both regressions, which is at the comfortable side of the standard threshold for cluster-robust inference.

## A.3 Early-UPI era regression, column-by-column build-up

The four-column build-up adds controls one at a time. Column 1 has only log(per-capita NSDP) and the year fixed effects. The income elasticity is +0.95, statistically significant, and the regression already explains 54 percent of the within-year cross-state variation. Column 2 adds log(urban share); the urban elasticity is +0.20 and is not significant. Column 3 adds log(PMJDY beneficiaries per adult); the PMJDY elasticity is +0.53, marginally significant, and the R² jumps from 0.55 to 0.60, the largest single increment in the table. Column 4, the headline, adds log(bank offices per 100,000 population); the bank-office coefficient is −0.17, not significant. The PMJDY coefficient holds at +0.50.

| | (1) | (2) | (3) | (4) |
|---|---:|---:|---:|---:|
| log(per-capita NSDP) | 0.953*** (0.172) | 0.821*** (0.213) | 1.049*** (0.253) | 1.168** (0.442) |
| log(urban share) | | 0.195 (0.168) | 0.265 (0.194) | 0.251 (0.218) |
| log(PMJDY/adult) | | | 0.528\* (0.268) | 0.501\* (0.278) |
| log(bank offices/100k) | | | | −0.170 (0.415) |
| Year FE | yes | yes | yes | yes |
| State-clustered SE | yes | yes | yes | yes |
| N | 66 | 66 | 66 | 66 |
| R² | 0.542 | 0.550 | 0.595 | 0.596 |

Standard errors in parentheses. Significance: \* p<0.10, \*\* p<0.05, \*\*\* p<0.01.

## A.4 Mature-UPI era regression, column-by-column build-up

The five-column build-up adds controls one at a time, mirroring the early-era structure. Column 1 has only log(per-capita NSDP); income elasticity is +0.94 with R² of 0.70. Column 2 adds log(internet density); the internet elasticity is +0.27 and is not significant. Column 3 adds log(urban share); coefficient is essentially zero. Column 4 adds log(PMJDY/adult); the PMJDY elasticity is +0.38 and significant at the 5 percent level; R² rises from 0.70 to 0.74, again the largest single increment in the build-up. Column 5, the headline, adds log(bank offices per 100,000 population); the bank-office coefficient is −0.19 and not significant. The PMJDY coefficient holds at +0.34.

| | (1) | (2) | (3) | (4) | (5) |
|---|---:|---:|---:|---:|---:|
| log(per-capita NSDP) | 0.939*** (0.113) | 0.806*** (0.248) | 0.806*** (0.243) | 0.932*** (0.205) | 1.047*** (0.311) |
| log(internet/100) | | 0.270 (0.415) | 0.271 (0.454) | 0.299 (0.409) | 0.342 (0.415) |
| log(urban share) | | | −0.001 (0.140) | 0.085 (0.111) | 0.059 (0.126) |
| log(PMJDY/adult) | | | | 0.383** (0.148) | 0.341** (0.163) |
| log(bank offices/100k) | | | | | −0.194 (0.324) |
| Year-window FE | yes | yes | yes | yes | yes |
| State-clustered SE | yes | yes | yes | yes | yes |
| N | 99 | 99 | 99 | 99 | 99 |
| R² | 0.696 | 0.700 | 0.700 | 0.740 | 0.743 |

## A.5 Cross-era comparison

Setting the headline columns of the two regressions side by side, on the four shared controls plus internet density (mature-era only):

| Control | Early-UPI era | Mature-UPI era |
|---|---:|---:|
| log(per-capita NSDP) | 1.168** (0.442) | 1.047*** (0.311) |
| log(urban share) | 0.251 (0.218) | 0.059 (0.126) |
| log(PMJDY/adult) | 0.501* (0.278) | 0.341** (0.163) |
| log(bank offices/100k) | −0.170 (0.415) | −0.194 (0.324) |
| log(internet/100) | | 0.342 (0.415) |
| N | 66 | 99 |
| R² | 0.596 | 0.743 |

Two coefficients are positive and statistically significant in both eras: per-capita NSDP and PMJDY beneficiaries per adult. Two are statistically zero in both eras: urban share and bank-office density. None flip sign across periods. The standard-error bands on NSDP and PMJDY overlap across the two regressions, so the early-era and mature-era estimates are not statistically distinguishable from each other. Internet density appears in the mature era only and is not significant there; the asymmetric inclusion does not drive the cross-era picture.

## A.6 The literacy puzzle

A sixth state-level variable, log of the literacy rate (persons aged seven and above), was tried in both regressions. We documented the result in Appendix tables A.7 and A.8 below and excluded the variable from both headline specifications on measurement-validity grounds.

### What the regression does

Adding log(literacy) to the headline produces a strongly negative conditional elasticity in both eras: approximately **−4.2** in the early era (significant at 1 percent) and approximately **−2.4** in the mature era (also significant at 1 percent). Both are large magnitudes, a 10 percent relative increase in literacy would correspond to a 24 to 42 percent decrease in per-capita digital-payment use, conditional on the other controls.

The univariate relationship between literacy and per-capita digital-payment use is, by contrast, indistinguishable from zero. Regressed on its own, log(literacy) produces a coefficient of −1.57 in the early era (p > 0.27) and +0.38 in the mature era (p > 0.77). On their own, literacy and per-capita digital-payment use are not meaningfully correlated across Indian states.

The pattern is therefore: zero univariate relationship, large and negative conditional relationship. This is the puzzle, and it shows up in both eras.

### The diagnostic

Standard explanations were checked and ruled out.

Multicollinearity. The variance-inflation factor for log(literacy) is 1.73, the lowest of any control in the full specification, well below the standard concern threshold of five. NSDP, internet density, and bank-office density all have higher VIFs. Multicollinearity is not the explanation.

Outlier states. Re-fitting the conditional regression after dropping Kerala (high literacy, mid-level UPI use), the seven small north-eastern states (high literacy, low UPI use), and both groups together moves the literacy elasticity from approximately −4.5 in the full sample to approximately −2.2 to −2.5, still strongly negative throughout. The result is robust to obvious outlier candidates.

Sample restriction. The three states excluded for missing NSDP are too small in population to materially change a state-clustered regression. Sample restriction is not driving the result.

Functional form. Re-running with literacy in levels rather than logs gives the same qualitative pattern, large and negative conditional, near-zero univariate. The puzzle is not specific to the log specification.

### A measurement-validity reading

Our reading is that the literacy variable as conventionally measured is not the variable a regression of digital-payment use should be controlling for. The Census of India and Periodic Labour Force Survey define literacy as the share of persons aged seven and above who can "read and write a simple statement with understanding." That definition was constructed for the basic-education-access question. It is a coarse summary of cognitive engagement with text in a primary language.

A digital-payments regression would ideally control for something narrower: the share of the population who can navigate a smartphone interface, follow numeric prompts in a payments app, and complete a transaction. This depends on smartphone ownership, age structure (younger populations are more digitally fluent regardless of basic literacy), and exposure to digital workflows. The conventional literacy variable does not separate any of these from the underlying primary-language reading ability it was designed to measure.

The conditional negative coefficient is consistent with this. Once income, urban share, PMJDY enrollment, and (in the mature era) internet density are in the regression, the residual variation in literacy is what remains after the regression has absorbed the parts of literacy that do correlate with digital-payment use through those channels. What is left is whatever the variable picks up that the controls do not, and our reading is that this includes age structure, language composition, and rural-vs-urban primary-language fluency, none of which align well with smartphone-payment capability.

That the same pattern appears in both eras strengthens the diagnosis. If the literacy variable behaved differently across the two regimes, that would be evidence of an era-specific phenomenon. It does not, the same pattern, with the same direction and the same effect on PMJDY's significance, shows up five years apart with different dependent variables. The most parsimonious explanation is that the variable is consistently measuring something other than what a digital-payments regression wants.

A better state-level control for the underlying concept, smartphone literacy, age-stratified basic literacy, or first-language literacy specifically, would let us re-run this with a variable whose conditional behaviour we could trust. That data does not currently exist at the Indian state level.

### Tables

**Table A.7, Early-UPI era, with literacy added**

| | (Univariate: literacy) | (Headline, no lit.) | (Headline + literacy) |
|---|---:|---:|---:|
| log(per-capita NSDP) | | 1.168** (0.442) | 0.951** (0.370) |
| log(urban share) | | 0.251 (0.218) | 0.337 (0.242) |
| log(PMJDY/adult) | | 0.501* (0.278) | 0.102 (0.262) |
| log(bank offices/100k) | | −0.170 (0.415) | −0.017 (0.423) |
| log(literacy) | −1.574 (1.434) | | −4.214*** (0.808) |
| N | 66 | 66 | 66 |
| R² | 0.168 | 0.596 | 0.757 |

**Table A.8, Mature-UPI era, with literacy added**

| | (Univariate: literacy) | (Headline, no lit.) | (Headline + literacy) |
|---|---:|---:|---:|
| log(per-capita NSDP) | | 1.047*** (0.311) | 0.842** (0.314) |
| log(internet/100) | | 0.342 (0.415) | 0.474 (0.378) |
| log(urban share) | | 0.059 (0.126) | 0.184 (0.118) |
| log(PMJDY/adult) | | 0.341** (0.163) | 0.154 (0.169) |
| log(bank offices/100k) | | −0.194 (0.324) | −0.063 (0.354) |
| log(literacy) | 0.383 (1.353) | | −2.383*** (0.606) |
| N | 99 | 99 | 99 |
| R² | 0.089 | 0.743 | 0.799 |
