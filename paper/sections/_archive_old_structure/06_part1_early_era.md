# 6. Part I: What predicted state-level digital payment use in the early-UPI era

In the early-UPI era — FY 2019-20 and FY 2020-21 — UPI was one of five rails making up India's digital-payment stack: BHIM, IMPS, RuPay-on-POS, UPI, and USSD. State-level data for this period aggregates the five into a single transaction count, the only state-disaggregated digital-payment volume measure published for those years. This section asks what predicted state-level variation in that count.

The estimator is pooled ordinary least squares on a panel of 33 states/UTs across two fiscal years, for 66 observations. Year fixed effects absorb the period-specific national level — digital-payment use grew rapidly between the two fiscal years, and we are interested in which states sat above or below the national average in each year, not in that average itself. Standard errors are clustered at the state level. Four state-level controls enter the regression: per-capita state domestic product, urban population share, PMJDY beneficiaries per adult, and bank-office density per 100,000 population. A fifth candidate variable — internet density — is omitted from Part I because India's pre-2023 telecom data is reported by Licensed Service Areas, several of which combine post-split states (Andhra Pradesh and Telangana, Bihar and Jharkhand, others), which makes state-level internet density unreliable for this period. The same four controls will be carried forward into Part II so the two eras can be compared coefficient-for-coefficient. A sixth candidate — literacy as conventionally measured — misbehaves in the regression and is in the appendix; we discuss the puzzle separately in §9.

## The dependent variable

The five-rail composite is published state-by-state by Indiastat from a Lok Sabha Unstarred Question (No. 1425, 28 July 2021). UPI was already the largest of the five rails by volume in FY 2020-21, so the composite was UPI-heavy in practice. But it is not the same variable as Part II's dependent variable. We do not chain the two series.

The sample is 35 states/UTs, not 36: Series 1 reports Jammu and Kashmir as a single unit, consistent with our convention of treating it as a single unit throughout Part I. Ladakh did not exist as a separate union territory until October 2019. The regression sample drops two states with persistent missing per-capita NSDP data — Lakshadweep and the merged Dadra and Nagar Haveli and Daman and Diu — leaving 33 states across the two fiscal years. National per-capita digital-payment use rose from 11.7 transactions per person per year in FY 2019-20 to 19.0 in FY 2020-21, a 63 percent year-on-year jump that the year fixed effects absorb.

## The regression results

Table 5 shows the four-column build-up. Column 1 has only log(per-capita NSDP) and the year fixed effects. The income elasticity is **+0.95**, statistically significant, and the regression already explains 54 percent of the within-year cross-state variation in per-capita digital-payment use. Even before any other control is added, knowing one variable about a state — how rich it is per person — gets you most of the way to predicting how much digital-payment activity it had.

Column 2 adds log(urban share). The urban-share elasticity is **+0.20** and is not statistically distinguishable from zero with state-clustered standard errors. The NSDP coefficient drops slightly to +0.82, and the R² rises modestly. Column 3 adds log(PMJDY beneficiaries per adult). The PMJDY elasticity is **+0.53** with a state-clustered standard error of 0.27 — significant at the 10 percent level. The NSDP coefficient rises to +1.05 and the R² jumps from 0.55 to 0.60, the largest single increment in the build-up. Column 4, the headline, adds log(bank-office density). Its coefficient is **−0.17** and is not significant. The PMJDY coefficient stays at **+0.50** (still marginally significant). The NSDP elasticity rises slightly to **+1.17**, and the R² gains a fraction of a percentage point.

The headline column is therefore: a unit-ish income elasticity, a +0.50 PMJDY elasticity (marginally significant), and two insignificant controls (urban share and branches).

## The income result

Per-capita NSDP has an elasticity of about one with respect to per-capita digital-payment use throughout Part I's build-up, sitting between +0.95 and +1.17. A 10 percent increase in a state's per-capita income is associated with roughly a 10 percent increase in its per-capita digital-payment activity. The relationship between income and digital-payment use was already firmly in place in 2019-21, when UPI was one of several rails. The reading is associational, not causal — we cannot tell from this cross-section whether income drives digital adoption, whether digital adoption supports income growth, or whether both move together with common drivers — but the pattern is clear and it is robust across the four columns.

The income elasticity carries the same caveat it will carry in every section of this paper: any state-level variable that wants to be taken seriously as an explanatory factor for digital-payment use needs to survive controlling for income. That is the test PMJDY, urban share, and bank-office density face in this section.

## The PMJDY result

The PMJDY elasticity is **+0.50**, marginally significant at the 10 percent level. A 10 percent relative increase in PMJDY beneficiary enrollment per adult is associated with about a 5 percent increase in per-capita digital-payment use, holding income, urban share, and bank-office density constant. Among the four controls in Part I, PMJDY is the only one whose coefficient is statistically distinguishable from zero conditional on the rest.

The result is worth pausing on. PMJDY was launched in August 2014; by FY 2020-21 the scheme had been running for roughly six years and was still in its build-out phase. The variable we measure — cumulative beneficiary accounts opened, normalised by adult population — is a stock variable that rises monotonically as the program reaches more households. What the regression detects is that, even in this early period, the states where the program had reached more households had higher digital-payment use, controlling for income.

The mechanism is account access. PMJDY's design opens a basic savings account for unbanked households, and an account is the necessary condition for using a digital-payment rail. The univariate correlation between PMJDY enrollment and per-capita digital payments is *negative*, because PMJDY-heavy states are poor states and poor states use less digital payments overall. But conditional on income, the sign flips: among states at similar income levels, those with higher PMJDY enrollment had higher per-capita digital-payment use. This conditional positive elasticity is the substantive finding of the section.

## Urban share and bank-office density: same nulls, same reason

Urban share and bank-office density are both insignificant in the headline column, with elasticities of +0.25 and −0.17 respectively. Both variables correlate with per-capita NSDP in the cross-section: more urbanised states are richer states, and states with more bank offices per person are also richer states. Once income is in the regression, the marginal contribution of either variable beyond what NSDP already absorbs is indistinguishable from zero.

The substantive reading is not that urbanisation or banking infrastructure are irrelevant. They almost certainly matter for digital-payment adoption. The reading is that, in the cross-section of Indian states in 2019-21, those variables move so tightly with income that we cannot identify a separate role for them. PMJDY is the exception: because the scheme deliberately targets the unbanked, who are concentrated in poorer states, PMJDY enrollment is *negatively* correlated with income. That negative correlation is precisely what gives PMJDY identification beyond the income gradient.

## Literacy

A sixth candidate control — log of the literacy rate (persons aged 7 and above) — is not in the headline regression. Adding it produces a conditional behaviour we cannot interpret: a strongly negative coefficient despite a univariate correlation that is essentially zero, and an attendant collapse of the PMJDY coefficient's significance. We diagnose this as a measurement-validity problem with the literacy variable as conventionally defined and discuss it fully in §9; Part I's appendix table shows the spec with literacy added.

## What Part I has established

Part I has produced a clean four-control story for the early-UPI era. Per-capita state domestic product is the dominant correlate of per-capita digital-payment use, with a unit-ish elasticity. PMJDY beneficiary density adds explanatory power beyond what income alone captures. Urban share and bank-office density do not — they are absorbed by the income gradient. The literacy variable misbehaves and is set aside.

The natural next question is whether the same pattern holds when UPI alone takes over the rail. Part II runs the same controls — plus internet density, which becomes available in the mature era — against pure UPI volume across three twelve-month windows from April 2023 through January 2026. Whether the early-era coefficients survive into the mature era is the comparative question Part III takes up.
