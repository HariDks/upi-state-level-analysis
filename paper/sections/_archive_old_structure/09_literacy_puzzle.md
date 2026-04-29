# 9. The literacy puzzle

Both Part I and Part II excluded literacy from their headline regressions and pointed forward to this section. We document the empirical pattern here, walk through the diagnostic checks, and explain why we read the result as a problem with the literacy variable rather than a substantive finding about the relationship between literacy and digital-payment use.

## What the regression does

Adding log(literacy) to the headline specification produces a strongly negative conditional elasticity in both eras. In Part I, the coefficient is approximately **−4.2**, statistically significant at the 1 percent level. In Part II, the coefficient is approximately **−2.4**, also significant at the 1 percent level. Both magnitudes are large in elasticity terms — a 10 percent relative increase in literacy would correspond to a 24 to 42 percent decrease in per-capita digital-payment use, holding income and the other controls constant.

The univariate relationship between literacy and per-capita digital-payment use is, by contrast, indistinguishable from zero. A regression of log(per-capita UPI) on log(literacy) alone produces a coefficient of −1.57 in Part I (standard error 1.43; p > 0.27) and +0.38 in Part II (standard error 1.35; p > 0.77). On their own, literacy and per-capita digital-payment use are not meaningfully correlated across Indian states.

The pattern in both eras is therefore: zero univariate relationship, large and negative conditional relationship. This is the puzzle.

## The diagnostic

Several explanations are available for a pattern of this shape. A standard checklist:

*Multicollinearity.* If literacy were highly correlated with one or more of the other controls in the regression, its conditional coefficient could pick up an artifact of the joint distribution rather than its own marginal effect. We computed variance-inflation factors (VIFs) for every regressor in the headline-plus-literacy specification. The VIF for log(literacy) is 1.73 — the *lowest* among all six controls, well below the standard concern threshold of five. Per-capita NSDP, internet density, and bank-office density all have higher VIFs than literacy does. Multicollinearity is not the explanation.

*Outlier states.* If a small number of unusual states were driving the conditional coefficient, removing them should change it. We re-fit the conditional regression after dropping Kerala (high literacy, mid-level UPI use), after dropping the seven small north-eastern states (high literacy, low UPI use), and after dropping both groups together. The literacy elasticity moves from −4.5 to roughly −2.2 to −2.5 across these specifications in Part I, and remains strongly negative throughout. The result is robust to the obvious outlier candidates.

*Sample restriction.* If our regression sample (33 states) were systematically excluding states whose inclusion would change the conditional pattern, that would be a reason to be cautious about the result. The three excluded states (Lakshadweep, Ladakh, Dadra and Nagar Haveli and Daman and Diu) are excluded for missing per-capita NSDP data. None of them are large enough in population to materially change a state-clustered regression even if their values were imputed. Sample restriction is not driving the result.

*Functional form.* We use log(literacy) rather than levels for consistency with the rest of the regression specification. Re-running with literacy in levels (a percentage from 60 to 99) gives the same qualitative pattern: large and negative conditional, near-zero univariate. The puzzle is not specific to the log specification.

We are therefore left with a result that is not driven by any of the obvious statistical pathologies. The conditional negative coefficient is a real feature of the data we have. The question is what it means.

## A measurement-validity reading

Our reading is that the literacy variable as conventionally measured is not the variable a regression of per-capita digital-payment use should be controlling for. The Census of India and Periodic Labour Force Survey define literacy as the share of persons aged seven and above who can "read and write a simple statement with understanding." This definition was designed for a quite different policy question — the basic-education-access question that the literacy variable was originally constructed to monitor. It is a coarse summary of cognitive engagement with text in a primary language.

What a digital-payments regression would ideally control for is something narrower: the share of the population who can navigate a smartphone interface, follow numeric prompts in a payments app, and complete a transaction without intermediary help. This is a different concept. It depends on smartphone ownership, age structure (younger populations are more digitally fluent regardless of basic literacy), and exposure to digital workflows in everyday life. The conventional literacy variable does not separate any of these from the underlying primary-language reading ability it was designed to measure.

The conditional negative coefficient is consistent with this measurement-validity argument. Once income, urban share, PMJDY enrollment, and (in the mature era) internet density are in the regression, the residual variation in literacy is what is left over after the regression has absorbed the parts of literacy that do correlate with digital-payment use through those channels. What remains is whatever the variable picks up that the controls do not — and our reading is that what remains includes age structure, language composition, and rural-vs-urban primary-language fluency, none of which align well with smartphone-payment capability. The coefficient is not zero because something is happening. It is negative because the residual variation is not the variation a digital-payments researcher would want.

The fact that the same pattern appears in both Part I and Part II — five years apart, with different dependent variables — strengthens the diagnosis rather than complicating it. If the literacy variable behaved differently in the two eras, that would be evidence of an era-specific phenomenon. It does not. The same pattern, with the same direction and roughly the same effect on PMJDY's significance, shows up in both regressions. The most parsimonious explanation is that the variable is consistently measuring something other than what a digital-payments regression wants.

## Why the variable is in the appendix, not the headline

A control whose conditional behaviour we cannot interpret should not appear in the main result. Including literacy in the headline specification would force us either to report and defend a coefficient we believe is artefactual, or to report it and disclaim it — neither of which leaves the reader in a clean position. The appendix tables for Parts I and II show the with-literacy specifications in full so the result is documented and a reader who wants to inspect it can. The headline regressions exclude it, and Part III's cross-era comparison runs only on the four shared controls whose conditional behaviour we *can* read.

A better state-level control for the underlying concept — smartphone literacy, or age-stratified basic literacy, or first-language literacy specifically — would let us re-run this with a variable whose conditional behaviour we could trust. That data does not currently exist at the Indian state level. Until it does, the cleanest reading is that this paper has nothing reliable to say about the relationship between literacy and digital-payment use, and the headline regression is the right place to acknowledge that.
