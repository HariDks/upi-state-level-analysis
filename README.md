# Digital Payments Thesis — Rebuild

State-level analysis of digital payment adoption in India, rebuilding and
extending the undergraduate thesis "Determinants of Digital Payments in
India" (Shiv Nadar University, May 2024). The paper has three parts:
(I) determinants of early-stage adoption, 2017-18 to 2020-21, rebuilt from
clean data with improved methods; (II) UPI at scale, 2023-24 to 2025-26,
new state-level analysis; (III) comparative discussion of what changed.
Author: Hari Dharshini K.S.

See [CLAUDE.md](CLAUDE.md) for project rules, conventions, and data
discipline. Read it before contributing.

## How to run

Requirements: R ≥ 4.3, `renv`, a working LaTeX install for the paper.

```bash
# Clone, then restore the R environment
cd digital-payments-thesis
Rscript -e 'renv::restore()'

# Scripts run in order (01 → 05). Each writes to data/interim,
# data/processed, or output/ — never to data/raw/.
Rscript scripts/01_ingest/<source>.R
Rscript scripts/03_build/<panel>.R
Rscript scripts/04_analyze/<table>.R
```

Raw source files live in `data/raw/` and are not versioned. Pull each
source per the inventory in Phase 1 before running ingestion scripts.

## Status log

Append-only. Newest entries at the top. Update at the end of each session.

### 2026-04-23 — Phase 0 scaffold
- Repo moved out of iCloud to `~/projects/digital-payments-thesis` to avoid
  iCloud sync corrupting `.git/`.
- Directory tree from CLAUDE.md §4 created.
- `.gitignore`, `README.md`, and this status log added.
- `lookups/state_names.csv` seeded with 30-unit Part I panel (28 states +
  J&K as single unit + Puducherry) as confirmed from original thesis FE
  table (90 obs = 30 × 3 years, Andhra Pradesh is the omitted FE
  reference). Delhi was NOT in the original panel — flagged for
  reconsideration in Phase 1.
- Other UTs (Delhi, Chandigarh, A&N, Lakshadweep, merged DNHDD, Ladakh)
  included in the lookup but noted as outside Part I original sample.
- `renv` initialized (bare) and added to CLAUDE.md §3 package list.

Next: Phase 1 — data inventory and pulls. Start with the two Indiastat
series (Part I composite, Part II NPCI-UPI).
