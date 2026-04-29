# Digital Payments and Financial Inclusion in India

A state-level analysis of digital-payments adoption across two distinct stretches of India's UPI era: FY 2019-20 and FY 2020-21, when UPI was one of five rails making up the digital-payment stack, and April 2023 through January 2026, when UPI alone settled the bulk of retail digital payments.

The headline finding: across both eras, financial-inclusion programmes that explicitly decouple account access from income (PMJDY) leave a measurable footprint on per-capita digital-payment use beyond what income alone explains. Programmes whose access scales with income, bank-office expansion, telecom buildout, urban agglomeration, do not. The pattern is statistically indistinguishable across the two eras even though the dependent variable, sample size, and panel structure differ.

## Paper

The full paper draft is at **[paper/main.pdf](paper/main.pdf)** (~20 pages). It is structured as a policy memo: an executive summary on page 1, three findings supported by parallel regressions across both eras, policy implications, and detailed methodology and data-construction notes in the appendices.

The markdown source for each section lives under [paper/sections/](paper/sections/). The LaTeX source generated from the markdown is at [paper/main.tex](paper/main.tex).

## Repository structure

```
data/
  interim/      Cleaned single-source CSVs (state-level, by year/window)
  processed/    Final analysis panels (Part I and Part II)
  raw/          Source files (gitignored, must be obtained separately)

scripts/
  01_ingest/         One R script per data source; reads raw, writes interim
  03_build/          Panel construction from interim files
  04_analyze/        Regression and diagnostic scripts
  05_tables_figures/ Figure and descriptive-table generation
  06_paper/          HTML, LaTeX, and PDF build pipelines

paper/
  sections/     Markdown source for each paper section
  main.tex      Generated LaTeX document
  main.pdf      Compiled PDF
  figures/      Figures used in the paper

lookups/
  state_names.csv   Canonical state-name reconciliation (every spelling
                    encountered, fail-loud on unknown names)
```

## Reproducibility

Requirements: R 4.3+ with `renv`, plus a TeX distribution (BasicTeX or MacTeX) for the LaTeX compile.

```bash
# Restore the R environment
Rscript -e 'renv::restore()'

# Pull each raw source per the inventory in scripts/01_ingest/README.md;
# raw files are not versioned and must be obtained separately.

# Run the ingestion + panel-build + analysis pipeline
Rscript scripts/01_ingest/<source>.R
Rscript scripts/03_build/build_part1_panel.R
Rscript scripts/03_build/build_part2_panel.R
Rscript scripts/04_analyze/part1_headline_regression.R
Rscript scripts/04_analyze/part2_headline_regression.R
Rscript scripts/04_analyze/part3_comparison.R
Rscript scripts/05_tables_figures/<figure>.R    # for each figure
Rscript scripts/05_tables_figures/tab1_descriptive_stats.R

# Build the paper
bash scripts/06_paper/build_paper_html.sh
bash scripts/06_paper/build_paper_latex.sh
cd paper && xelatex main.tex && xelatex main.tex
```

## Data sources

- **State-level monthly UPI volumes:** Indiastat / NPCI compilations
- **Five-rail composite (BHIM + IMPS + RuPay POS + UPI + USSD), Part I dependent variable:** Indiastat / Lok Sabha Unstarred Question 1425, dated 28 July 2021
- **Population projections:** Ministry of Health and Family Welfare, *Population Projections for India and States 2011-2036*
- **Per-capita NSDP:** Indiastat, MoSPI state accounts (constant 2011-12 prices)
- **Literacy:** Indiastat compilation of PLFS-derived state-level literacy rates (persons aged 7+)
- **Bank-office density:** RBI Database on Indian Economy, Other STRBI Table 13 (state-wise number of functioning offices of commercial banks, quarterly)
- **PMJDY beneficiaries:** Department of Financial Services portal snapshots, captured via the Internet Archive's Wayback Machine
- **Internet density:** TRAI Yearly Performance Indicators (state-level, post-2023 reporting on a comparable basis)
- **Adult-share denominator:** PLFS 2023-24 Annual Report, Table 1 sample composition

Full provenance and parsing notes for every variable are in Appendix B of the paper.

## Author

Hari Dharshini Koundinya Swaminathen. The paper extends and corrects the analysis from my undergraduate thesis at Shiv Nadar University (May 2024), using updated data and improved methods.

The paper was drafted with assistance from an AI tool (Anthropic Claude); analytical decisions and editorial direction are mine. The "Note on tools" at the end of Appendix B in the paper provides full disclosure.
