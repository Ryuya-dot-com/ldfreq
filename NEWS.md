# ldfreq 0.1.0.9000

## Preprocessing, variants, and frequency-profile candidate

- Added `lexdiv_tokenize()` as a separate versioned Unicode raw-text adapter.
  NFC/NFKC/no-normalization choices, case handling, pure-number retention, token
  offsets, and source/processed text hashes remain visible in provenance.
- Added `lexdiv_lemmatize()` for caller-supplied annotations with mandatory
  backend identity and version, plus an optional `textstem` convenience
  backend. Missing lemmas and UPOS tags remain explicit.
- Added `lexdiv_flemmatize()` for deterministic form-to-family-lemma mapping
  from a caller-supplied local AntBNC list. Exact resource hashes, per-token
  AntBNC/override/identity rules, match coverage, and path-private provenance
  remain visible; the resource is neither bundled nor downloaded.
- Added `lexdiv_metrics_text()` without changing the normative eleven-method
  result schema. Surface/lemma/flemma and all/content-word decisions are
  returned in a
  separate preprocessing envelope with token-level exclusion reasons and
  coverage.
- Added `lexdiv_variant_ids()` and `lexdiv_variant_metrics()` as a separate
  sensitivity contract. Four Maas definitions distinguish natural/base-10 logs
  and a/a-squared scales; four sequential-MTLD methods distinguish the frozen
  core from final-tail and mean-factor-length aggregations. Multiple thresholds
  expand in long form. TAALED-relevant rows are formula/factorization
  comparators, not official end-to-end compatibility claims.
- Added `tubelex_frequency_profile()` with explicit identity or source-aligned
  query normalization, lossless token rows, token/type coverage, and
  matched-only token/type-weighted frequency and prevalence summaries.
  Unmatched terms remain missing rather than becoming fabricated zero-frequency
  observations.
- Added `new_jacet8000_profile()` for caller-supplied New JACET 8000 data.
  It reports exact and cumulative Level 1--8 token/type rates, retains a
  denominator-visible off-list category, supports surface, lemma, or flemma
  units, exposes selectable AntBNC-versus-wordlist headword conflicts, and
  includes a base-R bar-plus-cumulative-line plot method. The official `新J8`
  XLSX sheet and Japanese column names are detected automatically. The package
  neither bundles nor downloads the New JACET 8000 list.
- Added `new_jacet8000_profile_batch()` with explicit document identity, a
  one-read shared-resource path, document-major lossless lookup and profile
  tables, separate preprocessing provenance, and a pre-computation row bound.
- Added public preprocessing and TUBELEX-profile candidate contracts. The new
  TUBELEX public API scope is not release-approved until it receives a new
  independent review and final source/installed/binary inventory audit.
- Made New JACET rank-entry and flemma-override canonical hashes invariant to
  source row order, and made tokenization consumers reject corrupted offsets
  or number flags before computing downstream results.
- Superseded the earlier immutable 0.1.0 core release-candidate evidence. A new
  exact candidate, cross-platform check matrix, and go/no-go decision are
  required before the 0.1.0 tag or CRAN submission.

# ldfreq 0.1.0

## Initial public release

- Synchronized the package, NEWS, and citation versions for the 0.1.0 release
  candidate; added exact-artifact `--as-cran` checks and machine-readable
  package BOM, dependency SBOM, resource BOM, and provenance evidence.
- Made the release-candidate aggregate fail closed on upstream job failures,
  exact NOTE contents, recorded job environments, named evidence identities,
  and all three current-R resource-inventory audits; validated the SPDX creator
  shape and retained the declared R constraint.
- Corrected a stale TUBELEX measurement locator, synchronized the reproducing
  builder identity, and distinguished the PyPI TAALED 0.32 sdist's unknown
  license metadata from the linked repository's license statement.

- Recorded Komuro Ryuya as the package author and maintainer and aligned the
  package copyright notice with that full name.
- Froze the eleven-method public API, promoted its metric and orchestration
  identities from draft versions to normative `0.1.0`, and added lifecycle
  rules without changing numerical methods or result shapes.
- Deferred the separately named deterministic expected-TTR D candidate from
  v0.1 while preserving its design evidence outside the installed normative
  contract.
- Removed the unreachable design-gate status and missing-reason vocabulary from
  the normative v0.1 result contract.
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
- Added release-R source/platform/installed package inventory audits on Ubuntu,
  macOS, and Windows. The audit byte-compares every declared TUBELEX, legal,
  provenance, and inventory member, rejects undeclared `extdata`, and emits
  run-specific JSON evidence without claiming reproducible ordinary archives.
- Added a versioned, non-exported TUBELEX exact-match and result contract with
  input-preserving rows, explicit unmatched values, frozen frequency/prevalence
  transformations, token/type coverage diagnostics, structured propagation of
  resource failures, and no normalization, network, download, or fallback.
- Added the lookup contract and schema to source, platform-package, and
  installed-package inventory audits while retaining zero release-approved
  resources and no public lexical-resource API.
- Added a byte-pinned TUBELEX release-admission candidate and a non-exported,
  fail-closed evaluator for strict independent-review records. It rejects
  missing approval, self-approval, candidate/commit drift, incomplete scope,
  reviewer rejection, and altered evidence without network or fallback.
- Added a repository command wrapper and source/platform/installed membership
  auditing for the admission contract. A valid record can pass only the
  resource-admission gate; package release readiness remains false and no
  approval record is bundled.
- Defined evidence and decision-record requirements for possible future
  TUBELEX admission. Automation may support review but cannot supply the
  required independent identity, attestations, or decision.
- Added introductory documentation and cross-platform R package checks.
- Added a contract-derived direction and scale table, explicit interpretation
  nonclaims, and clearer advisory quality-screen guidance.
- Refined public terminology after a TAALED/TAALES literature audit: the eleven
  methods are described primarily as lexical-variety/repetition operationalizations,
  direction is limited to the exact method and design, and the frozen quality field
  name is explicitly separated from writing quality, validity, and reliability.
- Pinned TAALED usage-guidance links to version 0.32 and clarified that normalized
  hypergeometric HD-D is distinct from the deferred expected-TTR curve-fit D candidate.
- Added direct executable examples for every export and an installed offline
  smoke script covering single, batch, profile, profile-batch, and screen flows.
