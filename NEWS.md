# ldfreq (development version)

- Replaced the pre-release installation instructions with a version-pinned
  v0.1.0 installation path, a base-R fallback, and a separately labeled
  development-version path.
- Added a safe multiple-raw-text workflow that preserves each document's
  preprocessing and token audit, and clarified that
  `lexdiv_metrics_batch()` accepts pre-tokenized documents only. The beginner
  workflow now uses `lexdiv_read_texts()` for deterministic `.txt` discovery,
  exact UTF-8 reading, explicit document IDs, bounded input sizes, byte hashes,
  and a path-private filename manifest.
- Added `lexdiv_text_corpus()` as the narrow handoff from one-row-per-document
  data frames, including explicitly reshaped Excel imports, to named raw-text
  analysis. Text identities and caller-selected source metadata remain visible.
- Marked the repository as post-release development and synchronized the
  package website URL with the pkgdown configuration.

# ldfreq 0.1.0

## Initial release

- Added eleven versioned lexical-diversity metrics for ordered,
  pre-tokenized input: TTR, RTTR/Guiraud, CTTR, Herdan's C, Maas
  a-squared, MSTTR, MATTR, MTLD, HD-D, Yule's K, and Yule's I.
- Added `lexdiv_tokenize()` and `lexdiv_metrics_text()` for raw English text.
  Unicode normalization, case handling, number retention, token offsets, and
  lexical-unit selection are retained in preprocessing provenance.
- Added `lexdiv_lemmatize()` for caller-supplied annotations and an optional
  `textstem` backend. Missing lemmas and UPOS tags remain explicit.
- Added `lexdiv_flemmatize()` for caller-supplied AntBNC form-to-family-lemma
  mappings. Resource hashes, overrides, identity fallback, and match coverage
  are recorded without retaining absolute paths or redistributing the list.
- Added `lexdiv_variant_ids()` and `lexdiv_variant_metrics()` to compare four
  Maas definitions and four sequential-MTLD definitions. TAALED-related rows
  are formula comparators, not end-to-end compatibility claims.
- Added bounded method specifications, parameter grids, request plans,
  multi-document profiles, and independent token-length screens.
- Added `new_jacet8000_profile()` and its batch and plot methods for a
  caller-supplied New JACET 8000 list. Exact and cumulative Level 1--8 token
  and type rates retain off-list items in the denominator. The package neither
  bundles nor downloads the list.
- Added `tubelex_frequency_profile()` with explicit query normalization,
  lossless matched and unmatched rows, token and type coverage, and
  matched-only frequency and prevalence summaries.
- Added the slim TUBELEX-EN aggregate with its BSD-3-Clause notice,
  COPYRIGHTS entry, source identity, transformation provenance, and package
  inventory. Runtime lookup has no network, download, or fallback path.
- Added machine-readable contracts, schemas, hand fixtures, differential
  audits, executable examples, an offline smoke test, and cross-platform R
  package checks.
- Clarified that the metrics operationalize lexical variety and repetition;
  they are not direct measures of proficiency, writing quality, validity, or
  reliability. Resource-relative frequency and level profiles likewise require
  coverage-aware, corpus-specific interpretation.
- Kept the separately defined expected-TTR curve-fit D method outside the
  version 0.1.0 public metric set.
