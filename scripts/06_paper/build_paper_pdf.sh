#!/usr/bin/env bash
# scripts/06_paper/build_paper_pdf.sh
#
# Render output/paper/paper_draft.html to a PDF using headless Chrome.
# No LaTeX install needed — Chrome handles unicode (₹, en/em-dashes),
# embeds images, and respects the existing paper.css.

set -e
cd "$(dirname "$0")/../.."

HTML="output/paper/paper_draft.html"
PDF="output/paper/paper_draft.pdf"

if [ ! -f "$HTML" ]; then
  echo "Run scripts/06_paper/build_paper_html.sh first to generate $HTML"
  exit 1
fi

# Add a print-specific stylesheet alongside the screen one. We append the
# print CSS to the existing paper.css so Chrome picks it up automatically
# at print-time. Idempotent — strips any prior @media print block first.
CSS="output/paper/paper.css"
TMP=$(mktemp -t paper_css.XXXXXX.css)
awk '/^@media print {/{flag=1} !flag; /^}$/{flag=0}' "$CSS" > "$TMP"

cat >> "$TMP" <<'EOF'

@media print {
  body { max-width: none; margin: 0; padding: 0; font-size: 11pt; line-height: 1.45; }
  h1 { page-break-before: auto; font-size: 1.7em; }
  h1:first-of-type { page-break-before: avoid; }
  h2 { page-break-after: avoid; font-size: 1.25em; }
  h3 { page-break-after: avoid; }
  table { page-break-inside: avoid; font-size: 9.5pt; }
  img { page-break-inside: avoid; max-width: 90%; }
  blockquote { page-break-inside: avoid; }
  @page { size: letter; margin: 0.85in 0.95in; }
}
EOF

mv "$TMP" "$CSS"

# Resolve absolute file URL for the HTML so Chrome can load relative
# image and CSS paths correctly.
ABS_HTML="file://$(cd "$(dirname "$HTML")" && pwd)/$(basename "$HTML")"

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

"$CHROME" \
  --headless \
  --disable-gpu \
  --no-pdf-header-footer \
  --print-to-pdf="$PDF" \
  --print-to-pdf-no-header \
  --virtual-time-budget=10000 \
  "$ABS_HTML" 2>/dev/null

if [ -f "$PDF" ]; then
  echo "Wrote $PDF"
  echo "Size: $(ls -lh "$PDF" | awk '{print $5}')"
else
  echo "Chrome failed to produce a PDF. Check $HTML opens normally in a browser first."
  exit 1
fi
