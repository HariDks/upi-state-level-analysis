# scripts/01_ingest/_utils_state_names.R
#
# Purpose: canonical state-name reconciliation for all ingestion scripts.
# Inputs:  a character vector of state names from a raw source; a label
#          identifying that source for error messages.
# Outputs: a tibble with columns
#            original            - input string, unchanged
#            state_canonical     - canonical name from lookups/state_names.csv
#            state_code          - two-letter code
#            include_in_analysis - logical flag from the lookup table
#
# Every ingestion script under scripts/01_ingest/ MUST pass source state
# names through reconcile_states() before writing to data/interim/. On any
# unrecognized input the function stops with a loud error listing the
# offending strings; the fix is to add them to the `variants` column in
# lookups/state_names.csv (pipe-separated) and re-run. Do not silently
# drop rows. Do not fuzzy-match. See CLAUDE.md section 5.

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(readr)
  library(stringr)
  library(tibble)
})

# Walk upward from getwd() until CLAUDE.md is found; error if not.
.find_project_root <- function(start = getwd()) {
  d <- normalizePath(start, mustWork = TRUE)
  repeat {
    if (file.exists(file.path(d, "CLAUDE.md"))) return(d)
    parent <- dirname(d)
    if (parent == d) {
      stop(
        "Could not locate project root: no CLAUDE.md found in any ",
        "ancestor of '", start, "'. Run this script with the working ",
        "directory inside the digital-payments-thesis repository."
      )
    }
    d <- parent
  }
}

.state_lookup_path <- function() {
  file.path(.find_project_root(), "lookups", "state_names.csv")
}

# Load the lookup and expand the pipe-separated variants column so that
# every accepted spelling (plus each canonical name itself) appears as
# one row keyed by the `variant` column.
load_state_lookup <- function(path = .state_lookup_path()) {
  lu <- readr::read_csv(
    path,
    show_col_types = FALSE,
    col_types = readr::cols(
      state_canonical     = readr::col_character(),
      state_code          = readr::col_character(),
      variants            = readr::col_character(),
      include_in_analysis = readr::col_logical(),
      notes               = readr::col_character()
    )
  )

  expanded <- lu |>
    tidyr::separate_rows(variants, sep = "\\|") |>
    dplyr::mutate(variant = stringr::str_trim(variants)) |>
    dplyr::select(variant, state_canonical, state_code, include_in_analysis)

  canonical <- lu |>
    dplyr::transmute(
      variant             = state_canonical,
      state_canonical,
      state_code,
      include_in_analysis
    )

  dplyr::bind_rows(expanded, canonical) |>
    dplyr::filter(!is.na(variant), variant != "") |>
    dplyr::distinct()
}

# Map a vector of raw source state names to canonical rows. Fails loud on
# any unrecognized input. Whitespace is trimmed before matching; case is
# matched strictly against the enumerated variants (add new case forms to
# the lookup rather than normalizing case here).
reconcile_states <- function(x, source_label = "unnamed source") {
  if (!(is.character(x) || is.factor(x))) {
    stop("reconcile_states(): `x` must be character or factor, got ", class(x)[1])
  }

  lu <- load_state_lookup()

  input <- tibble::tibble(original = as.character(x)) |>
    dplyr::mutate(variant = stringr::str_trim(original))

  joined <- dplyr::left_join(input, lu, by = "variant")

  unmatched <- joined |> dplyr::filter(is.na(state_canonical))
  if (nrow(unmatched) > 0) {
    bad <- sort(unique(unmatched$original))
    stop(
      "reconcile_states() failed for source '", source_label, "'.\n",
      "Unrecognized state name(s) (", length(bad), "):\n  - ",
      paste(bad, collapse = "\n  - "),
      "\n\nAdd each new spelling to the `variants` column in ",
      "lookups/state_names.csv (pipe-separated, trim whitespace) and ",
      "re-run. Do not silently drop rows. Do not fuzzy-match. ",
      "See CLAUDE.md section 5.",
      call. = FALSE
    )
  }

  dplyr::select(joined, original, state_canonical, state_code, include_in_analysis)
}

# Self-test when the script is executed directly (Rscript _utils_state_names.R).
if (identical(environment(), globalenv()) && sys.nframe() == 0L) {
  message("Running self-tests for reconcile_states() ...")

  # 1. Canonical names pass through.
  t1 <- reconcile_states(c("Maharashtra", "Tamil Nadu"), "self-test canonical")
  stopifnot(identical(t1$state_canonical, c("Maharashtra", "Tamil Nadu")))

  # 2. Enumerated variants resolve.
  t2 <- reconcile_states(c("ORISSA", "Pondicherry", "J&K"), "self-test variants")
  stopifnot(identical(
    t2$state_canonical,
    c("Odisha", "Puducherry", "Jammu and Kashmir")
  ))

  # 3. Trailing whitespace is tolerated.
  t3 <- reconcile_states("Andhra Pradesh  ", "self-test whitespace")
  stopifnot(t3$state_canonical == "Andhra Pradesh")

  # 4. "All India" resolves but is flagged for exclusion.
  t4 <- reconcile_states("All India", "self-test aggregate")
  stopifnot(t4$include_in_analysis == FALSE)

  # 5. Unknown spelling fails loud.
  err <- tryCatch(
    reconcile_states(c("Maharashtra", "Bombay Presidency"), "self-test bad"),
    error = function(e) conditionMessage(e)
  )
  stopifnot(grepl("Bombay Presidency", err))

  message("All self-tests passed.")
}
