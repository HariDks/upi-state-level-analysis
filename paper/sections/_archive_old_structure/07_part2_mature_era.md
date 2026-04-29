# 7. Part II: What predicts state-level UPI use in the mature era

Part I established the cross-state pattern in the early-UPI era: per-capita state domestic product is the dominant correlate of digital-payment use, with a unit-ish elasticity; PMJDY beneficiary density adds explanatory power beyond income; urban share and bank-office density are absorbed by the income gradient and are not significant on their own. The question this section asks is whether the same pattern holds in the mature UPI era, when UPI alone settles the bulk of retail digital payments and the panel is larger.

We use the same four state-level controls Part I used (per-capita NSDP, urban share, PMJDY beneficiaries per adult, bank-office density), plus one additional control that becomes available only in this era — internet density. The full mature-era specification therefore has five controls. Part III will compare the early-era and mature-era regressions on the four shared controls; internet density is discussed within Part II only.

The estimator follows Part I's: pooled ordinary least squares with year fixed effects and standard errors clustered at the state level. The panel here is larger. Pure UPI state-level data is published monthly from April 2023, and we have 34 months through January 2026. We aggregate this to three twelve-month windows: April 2023 – March 2024 (W1), April 2024 – March 2025 (W2), and a rolling February 2025 – January 2026 (W3). The third window is rolling rather than fiscal-year-aligned because monthly data through March 2026 is not yet published; treating it as a twelve-month average lets us use the most recent year of data without creating a partial-year asymmetry across observations.

The panel is 36 states/UTs across three windows, for 108 observations before any sample cuts. The regression sample drops three states with persistent missing data — Lakshadweep, the merged Dadra and Nagar Haveli and Daman and Diu, and Ladakh — leaving **99 state-window observations from 33 states**. Literacy is again in the appendix (it misbehaves in the same way it did in Part I, possibly more strongly); we discuss the puzzle separately in §9.

## The univariate picture, before the regression

Before adding controls, look at how each variable correlates with per-capita UPI use one at a time. Figure 3 plots the four candidate controls available for both eras (per-capita NSDP, literacy, internet density, and urban share) against per-capita UPI use across states, with each panel on a log–log scale. All four show positive univariate correlations, with NSDP the strongest. Richer states use more UPI per person; more urbanised, more connected, and more literate states do as well. None of this is surprising on its own.

Figure 5 plots PMJDY beneficiaries per adult against per-capita UPI use. The univariate correlation is *negative* — Pearson r in log–log of about −0.32. That looks counterintuitive at first, but it is exactly what the scheme's targeting predicts. PMJDY was designed to bring unbanked households into the formal financial system; its beneficiary density is therefore highest in poorer states, which are also lower-UPI states. The univariate negative correlation is a description of where PMJDY enrollment is concentrated, not a description of what PMJDY does for digital payments. Disentangling those two requires the regression.

Figure 6 plots bank-office density against per-capita UPI use. Here the univariate correlation is positive, with Pearson r in log–log of about +0.58. States with more physical banking infrastructure per capita do use more UPI per capita, in the unconditional cross-section. Whether this survives controlling for income is the question the regression will answer.

## The regression results

Table 6 shows the build-up. Column 1 has only log(per-capita NSDP) and the year-window fixed effects. The income elasticity is +0.94 — close to a unit elasticity — and the regression already explains 70 percent of the within-window cross-state variation in per-capita UPI. In other words, knowing one variable about a state — how rich it is per person — gets you most of the way to predicting how much UPI it uses per person. That is a useful baseline against which to assess whether the other variables earn their place.

Column 2 adds internet density. The internet elasticity is +0.27 and is not statistically distinguishable from zero with state-clustered standard errors. The NSDP coefficient drops slightly to +0.81, but the overall fit barely improves (R² rises from 0.70 to 0.70). Column 3 adds urban share. The urban-share elasticity is essentially zero (+0.00), again not significant. R² stays at 0.70.

Column 4 adds PMJDY beneficiaries per adult. The PMJDY elasticity is **+0.38** with a state-clustered standard error of 0.15 — significant at the 5 percent level. The NSDP coefficient stays at +0.93 and the R² jumps from 0.70 to 0.74, the largest single increment in the table. PMJDY is the only control that adds material explanatory power once income is in the regression. Column 5, the headline, adds bank-office density. Its coefficient is −0.19 and is not significant. The PMJDY coefficient stays at **+0.34** (still significant at 5 percent). The NSDP elasticity rises slightly to **+1.05**. The R² gains another 0.4 percentage points, but the bank-office variable does not earn its place.

The headline column is therefore: a unit-ish income elasticity, a +0.34 PMJDY elasticity, and three insignificant controls (internet, urban, branches). The next sections walk through what each of these means and why the insignificant ones look the way they do.

## The income result

Per-capita NSDP has an elasticity of about one with respect to per-capita UPI throughout the build-up. A 10 percent increase in a state's per-capita income is associated with about a 10 percent increase in its per-capita UPI use. The coefficient sits in the range of +0.81 to +1.05 across the five columns, never far from the column-1 baseline of +0.94. This is the firmest single empirical finding in Part II. It is also unsurprising: digital-payment volume scales with both the money households have to spend and the share of that spending that flows through commerce that supports digital settlement, and both of those things grow with income.

The right reading of this coefficient is associational, not causal. Income and UPI use grow together across Indian states. The data here cannot tell us whether income drives UPI adoption, UPI adoption supports income growth, or — most likely — both effects operate alongside common drivers like urbanisation and connectivity. What the result *does* establish is that any state-level UPI variable that wants to be taken seriously needs to survive controlling for income. That is the test the next four variables face, and most of them fail it.

## The PMJDY result

The headline finding of Part II is the **+0.34 elasticity on PMJDY beneficiaries per adult**, conditional on income and the other three controls. A 10 percent relative increase in PMJDY enrollment per adult is associated with about a 3.4 percent increase in per-capita UPI use, holding income, internet, urban share, and bank-office density constant.

The flip from the univariate negative correlation to the conditional positive elasticity has a clean interpretation. Unconditionally, PMJDY-heavy states are poor states, and poor states use less UPI — the negative univariate correlation is income masquerading as PMJDY. Once we condition on income, the question becomes: among states at similar income levels, do those with higher PMJDY enrollment use more UPI per capita? The answer is yes, and meaningfully so. Among the financial-inclusion variables we test, PMJDY enrollment is the one that survives the income control.

What PMJDY beneficiary density measures is account access — specifically, the cumulative number of basic savings accounts opened under the scheme since 2014, normalised by adult population. The coefficient says that this measure of account access predicts UPI use beyond what income alone does. The reading is not that PMJDY *caused* UPI adoption — the data here cannot establish that — but that *programmatic* financial inclusion has a measurable association with digital-payments use, conditional on the income gradient. The Part I result was the same finding in the earlier era; that the relationship survives the move from the five-rail composite to pure UPI, and from a 2-FY panel to a 3-window panel, is itself a robustness statement. We return to the cross-era comparison in Part III and to the policy reading in §10.

## The three null results, and why

Three of the five controls are not significant in the headline column: internet density, urban share, and bank-office density. The reason is the same in each case, but most starkly visible for branches. The diagnostic shows the problem.

Bank-office density correlates with per-capita NSDP at r = +0.88 in log–log. Internet density correlates with NSDP at r = +0.86. Urban share correlates with NSDP at r = +0.72. All three are highly collinear with income. Their variance-inflation factors in the headline regression are 5.2 (branches), 4.8 (internet), and 2.7 (urban share) — branches and internet are at the threshold where collinearity starts compromising the estimates. The three variables capture economically real and theoretically distinct channels — physical banking infrastructure, telecom infrastructure, and urban agglomeration — but in our cross-section those channels move together with state income tightly enough that the regression cannot separately identify their contributions beyond what NSDP already absorbs.

The interesting contrast is with PMJDY. PMJDY enrollment per adult correlates with NSDP at r = −0.62 — strongly *negatively*, because the scheme deliberately targets the unbanked, who are concentrated in poorer states. That negative correlation with the dominant control variable is precisely what gives PMJDY identification in the regression: conditioning on income does not collapse PMJDY's variation, because income and PMJDY move in opposite directions across states.

The substantive reading is therefore not that bank branches or internet penetration are irrelevant to UPI adoption. They almost certainly matter. The reading is that, in the cross-section of Indian states in the mature UPI era, those variables move so tightly with income that we cannot identify a separate role for them. Financial-inclusion *programs*, which are designed precisely to break the correlation between financial access and income, can be identified separately. Financial-inclusion *infrastructure*, which is allocated by markets and grows with income, cannot.

## Literacy

A sixth candidate control — log of the literacy rate — is not in the headline regression here, for the same reasons it was not in Part I's. Part II's appendix table shows the spec with literacy added; the cross-era diagnostic and the measurement-validity argument are in §9.

## Bridge to Part III

The mature-era pattern, then, is: per-capita NSDP and PMJDY beneficiaries per adult are the two state-level variables that survive joint inclusion in the cross-state regression of per-capita UPI use. Internet density, urban share, and bank-office density are absorbed by income. The pattern is the same as Part I's at a qualitative level — and, as we will show in Part III, quantitatively close as well. Part III takes the early-era and mature-era coefficients side by side and asks two questions: how stable is the pattern across the two eras, and what does that stability (or the small differences within it) imply for digital-payments policy.
