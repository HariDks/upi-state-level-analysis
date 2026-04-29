# 8. Part III: What changed, and what didn't

Parts I and II have produced two regressions that share a methodology, a specification, and four of their five state-level controls. They differ in the dependent variable — Part I uses a five-rail composite (BHIM + IMPS + RuPay POS + UPI + USSD) for FY 2019-20 and FY 2020-21, while Part II uses pure UPI for three twelve-month windows from April 2023 through January 2026 — and they differ in sample size (Part I has 66 state-FY observations from 33 states, Part II has 99 state-window observations from the same 33 states). The two regressions describe digital-payment use in two distinct stretches of UPI's evolution, roughly five years apart.

The point of this section is to set the coefficients on the four shared controls side by side, ask how stable the cross-state pattern has been across these two stretches, and read what that stability says about which state-level factors are durably associated with digital-payment adoption.

## The cross-era comparison

Table 8 puts Part I's headline column next to Part II's headline column. The four shared controls — log(per-capita NSDP), log(urban share), log(PMJDY beneficiaries per adult), log(bank offices per 100k population) — appear in both regressions. Internet density appears in Part II only.

Two findings stand out, and they are mirror images of each other. Two variables are positive and statistically significant in both eras: per-capita NSDP and PMJDY beneficiaries per adult. Two variables are insignificant in both eras: urban share and bank-office density. Nothing flips sign across the two periods. Nothing that mattered in the early era stops mattering in the mature era, and nothing that didn't matter in the early era starts mattering in the mature one. The cross-era picture is one of remarkable stability.

## Income: roughly unit-elastic in both eras

The income elasticity is **+1.17** in Part I (significant at the 5 percent level) and **+1.05** in Part II (significant at the 1 percent level). Both are statistically and substantively close to a unit elasticity, and the two estimates have overlapping standard-error bands — we cannot reject that they are the same number. A 10 percent increase in a state's per-capita NSDP is associated with about a 10 percent increase in its per-capita digital-payment use, and that relationship was already in place in 2019-21 and persists essentially unchanged in 2024-25.

This is the most durable single finding in the paper. Whatever else changed about UPI between the two eras — the sheer volume of transactions, the displacement of the four other rails by UPI alone, the doubling of bank-office density, the addition of hundreds of millions of PMJDY beneficiaries — the income gradient of digital-payment use has held its shape.

## PMJDY: positive and significant in both eras

The PMJDY elasticity is **+0.50** in Part I (significant at the 10 percent level) and **+0.34** in Part II (significant at the 5 percent level). Both are positive, both are economically meaningful, and both are statistically distinguishable from zero. The point estimates differ — Part I's is larger — but the standard-error bands overlap, so the difference is not statistically meaningful at conventional thresholds.

The substantive reading is that financial-inclusion *programs* — specifically, the cumulative beneficiary base of India's flagship account-creation scheme — have had explanatory power for state-level digital-payment use beyond what income alone captures, in both eras. By 2019-21, PMJDY had been running for five to six years and was still in its build-out phase; the variable was already detecting cross-state variation that the regression could associate with digital-payment activity. By 2024-25, with a decade of cumulative enrollment behind it, the variable continues to do that work, against a different and richer dataset, with a different dependent variable.

This is the policy-relevant finding of the paper. We return to it in §10.

## Urban share and bank-office density: null in both eras

Urban share is statistically indistinguishable from zero in both regressions: **+0.25** in Part I, **+0.06** in Part II. Bank-office density is also insignificant in both: **−0.17** in Part I, **−0.19** in Part II. The point estimates are small, the standard-error bands are wide, and neither variable adds meaningful explanatory power once income is in the regression.

The reason is the same in both eras and is not specific to the variables themselves. Bank-office density correlates with per-capita NSDP at roughly +0.85 across our state sample; urban share correlates with NSDP at around +0.7. Both are highly collinear with income in cross-section, which means the regression cannot identify a separate role for either of them beyond what NSDP already absorbs. PMJDY survives this same test only because, by design, the scheme deliberately targets the unbanked — its beneficiary density is *negatively* correlated with state income. That negative correlation gives PMJDY identification beyond income, and it is what distinguishes financial-inclusion *programs* from financial-inclusion *infrastructure* in the regression.

The substantive reading is not that urbanisation or banking infrastructure are irrelevant. They almost certainly matter for digital-payment adoption — they are real economic channels with clear theoretical claims. The reading is that, in our cross-section of Indian states, those channels move so tightly with state income that the regression cannot identify them separately. They show up *through* the income gradient, not *beyond* it.

## Internet density, the asymmetric control

Internet density appears in Part II only, with a coefficient of **+0.34** that is not statistically distinguishable from zero. Part I has no internet density variable. The only state-level source for internet penetration in India is TRAI, and TRAI's pre-2023 data is reported by Licensed Service Areas — several of which combine post-split states like Andhra Pradesh and Telangana, or Bihar and Jharkhand. Reliable state-level internet density therefore does not exist for the early-UPI era.

The Part II coefficient gives us a useful read on what the asymmetric control would have done if we had it for both eras. Internet density correlates with per-capita NSDP at about +0.86 in Part II — the same income-collinearity pattern that absorbs urban share and bank-office density. Even where we *do* have internet density, the variable does not survive the income control. This makes it unlikely that a hypothetical Part I version of the variable would have changed the cross-era picture. The asymmetry in the control set is not driving the cross-era stability we observe.

## What stability across eras implies

The stability we observe in this comparison is more than a methodological coincidence. The two regressions use different dependent variables; they cover different sample sizes and different time structures; they use somewhat different control vintages; and they look at digital-payment use during phases of UPI evolution that were qualitatively distinct. The cross-state coefficient pattern survives all of that. The same two variables — income and PMJDY beneficiary density — explain state-level digital-payment use in both eras, with statistically similar magnitudes. The same three variables — urban share, bank-office density, and (in the era for which we have it) internet density — fail to clear the income control.

For a policy reader, that stability suggests three things. First, income remains the dominant correlate of digital-payment adoption across Indian states, and any state-level intervention to expand digital payments is operating against a strong income gradient. Second, financial-inclusion programs that deliberately decouple account access from income — as PMJDY does by targeting the unbanked — leave a footprint in cross-state digital-payment use that survives controlling for the income gradient itself. Third, financial-inclusion infrastructure that scales with income — physical bank offices, telecom buildout, urban agglomeration — does not leave a footprint that survives the income control, even when the underlying mechanisms are real.

§10 takes up what these patterns mean for the design of digital-payments and financial-inclusion policy specifically. §9 first documents the one variable we set aside — literacy — which misbehaves in both eras for the same reason, and which therefore reinforces, rather than complicates, the cross-era picture above.
