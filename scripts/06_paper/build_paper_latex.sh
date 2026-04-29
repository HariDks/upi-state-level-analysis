#!/usr/bin/env bash
# scripts/06_paper/build_paper_latex.sh
#
# Generates paper/main.tex from the markdown sections via pandoc, plus
# a self-contained paper/figures/ directory. Suitable for compilation
# with pdflatex/xelatex/lualatex (xelatex recommended for ₹ and other
# unicode), or one-click upload to Overleaf.
#
# Run after build_paper_html.sh (which produces output/paper/combined.md
# from the section markdown files).

set -e
cd "$(dirname "$0")/../.."

COMBINED_MD="output/paper/combined.md"
if [ ! -f "$COMBINED_MD" ]; then
  echo "Run scripts/06_paper/build_paper_html.sh first to generate $COMBINED_MD"
  exit 1
fi

TEX_OUT="paper/main.tex"

# Custom header: packages and styling not in pandoc's default LaTeX template.
HEADER=$(mktemp -t paper_header.XXXXXX.tex)
cat > "$HEADER" <<'EOF'
\usepackage[margin=1in]{geometry}
\usepackage{booktabs}
\usepackage{longtable}
\usepackage{array}
\usepackage{microtype}
\usepackage{xcolor}
\setlength{\parskip}{0.5em}
\setlength{\parindent}{0pt}
\renewcommand{\arraystretch}{1.05}

% hyperref is loaded by pandoc's template AFTER this header. Use
% \AtBeginDocument to defer hypersetup until hyperref is present.
\AtBeginDocument{\hypersetup{colorlinks=true, linkcolor=black, urlcolor=blue, citecolor=blue}}

% Tighten footnote spacing
\setlength{\footnotesep}{0.4em}
EOF

pandoc "$COMBINED_MD" \
  --from markdown+raw_html+grid_tables+pipe_tables+yaml_metadata_block \
  --to latex \
  --standalone \
  --include-in-header="$HEADER" \
  --metadata title="Digital Payments and Financial Inclusion in India: A State-Level Look at the Early and Mature UPI Eras" \
  --metadata author="Hari Dharshini Koundinya Swaminathen" \
  --output "$TEX_OUT"

rm "$HEADER"

# Make paper/ self-contained: copy figures alongside main.tex and rewrite
# paths so that uploading paper/ to Overleaf "just works."
mkdir -p paper/figures
cp -f output/figures/fig2_state_ranking_w3.png paper/figures/
cp -f output/figures/fig4_convergence.png paper/figures/
cp -f output/figures/fig5_pmjdy_vs_upi.png paper/figures/
cp -f output/figures/fig6_bank_offices_vs_upi.png paper/figures/

# Source markdown uses ../figures/<name>.png relative to output/paper/.
# In main.tex (sitting in paper/), the same files now live at figures/.
sed -i.bak 's|\.\./figures/|figures/|g' "$TEX_OUT"
rm -f "${TEX_OUT}.bak"

# Light tidy: pandoc generates a status-note block-quote that uses
# pandoc's \begin{quote}; that's fine. Any further LaTeX-specific
# adjustments belong here.

echo "Wrote $TEX_OUT"
echo "Wrote paper/figures/ (4 PNGs copied from output/figures/)"
echo ""
echo "To compile locally (requires a TeX distribution — e.g. MacTeX):"
echo "  cd paper && xelatex main.tex && xelatex main.tex"
echo ""
echo "Or upload the paper/ directory to Overleaf and compile there"
echo "(Overleaf default is pdflatex; switch to xelatex via Menu > Compiler"
echo " for cleanest handling of ₹ and en-dashes)."
