# ldfreq 0.1.0.9000

## Initial public development baseline

- Added eleven contract-backed lexical-diversity metrics for pre-tokenized input.
- Added narrow multi-document batch processing with explicit document identity.
- Added bounded method specifications, request plans, profiles, and independent
  token-length screens.
- Added row-level metric-contract and result-schema provenance.
- Added hand fixtures, property tests, and an installed-API differential audit
  covering 500 independent MTLD comparisons, 1,000 direct formula/window/
  hypergeometric comparisons, and 73,809 exhaustive local-measure comparisons.
- Added strict handling of invalid, empty, and short documents.
- Added a non-exported, byte-pinned local-resource loader with fixed failure
  precedence, one-read hashing/decoding, bounded inventories, and no network or
  fallback behavior. Only CC0 synthetic fixtures are admitted at this stage.
- Added `digest` as the portable raw-byte SHA-256 backend and an explicit R 4.1
  CI lane to verify the declared minimum R version.
- Added the separately licensed slim TUBELEX-EN aggregate as a non-exported
  development candidate with a byte-pinned DCF manifest, build provenance,
  BSD-3-Clause NOTICE/COPYRIGHTS records, and a machine-readable package
  inventory that still reports zero release-approved resources.
- Added bounded one-read gzip decoding and a strict 515,292-row TUBELEX
  frequency/prevalence adapter. The runtime has no download or fallback path.
- Added installed-package tamper/membership audits and Ubuntu/Windows
  reproduction of the fixed-source R builder, cleanup, lock, and cooperative
  concurrency invariants as inputs to the required CI aggregate.
- Added introductory documentation and cross-platform R package checks.
