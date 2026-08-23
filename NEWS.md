# ldfreq 0.1.1

## New overlap API

- Added `lexdiv_term_overlap()` for exact distinct-term Jaccard, Dice,
  directional coverage, and overlap-coefficient results with explicit
  numerators, denominators, empty-set behavior, and optional term details.
- Added `lexdiv_content_overlap()` for exact overlap after explicit Universal
  POS content-word selection. It reports annotation coverage and fails by
  default when unit-relevant preprocessing or annotation settings differ or
  are unverifiable.
- Term-level detail remains opt-in. Results record whether exact lexical terms
  are retained, and the print method displays a disclosure when they are.
- Flemma comparisons now use disclosed caller-declared version labels rather
  than byte or canonical-content hashes. Strict comparison treats missing or
  different resource versions as unverifiable or mismatched. Two inputs with
  no overrides remain comparable; otherwise both must declare the same
  override version.

## Corrections and validation

- `lexdiv_metrics_text()` now forwards custom expected-TTR D sample sizes to
  the token-vector core.
- Lemma/UPOS and flemma annotation layers are validated against their recorded
  provenance before use; unsupported Universal POS tags now fail explicitly.
- UPOS backend identity is now required explicitly whenever any UPOS tag is
  present. It is never defaulted from lemma backend identity, including when
  one caller pipeline produced both layers.
- Flemma adapter and parser identities are fixed by `ldfreq`;
  `resource_version` and `override_version` are path-free caller labels that
  are disclosed in provenance and overlap comparability output. Callers must
  not put paths, secrets, or private hashes in these labels.
- Removed AntBNC source-file names and source/override SHA-256 fields from
  public flemma provenance and overlap comparison. The source-byte digest is
  used only as an internal, result-invariant parse-cache key.
- Preprocessing contract `0.1.1` validates annotation provenance strictly.
  `lexdiv_tokenization` objects serialized under `0.1.0` are not migrated
  automatically; recreate them from the original text with
  `lexdiv_tokenize()` and reapply annotations with current explicit IDs.
- Versioned the changed preprocessing behavior as contract `0.1.1`; tokenizer
  identity remains `0.1.0` because token boundaries did not change.
- Replaced pre-release wording such as "frozen" with "versioned" where it
  described public methods rather than an immutable method definition.
- Kept the existing TUBELEX resource-admission state unchanged; any promotion
  still requires evidence tied to the exact release artifact.

# ldfreq 0.1.0

## Initial release

- Added twelve versioned lexical-diversity metrics for ordered,
  pre-tokenized input: TTR, RTTR/Guiraud, CTTR, Herdan's C, Maas
  a-squared, MSTTR, MATTR, MTLD, HD-D, deterministic expected-TTR D,
  Yule's K, and Yule's I.
- Added `lexdiv_as_documents()` for named lists, tidy one-token-per-row data
  frames, and `quanteda` tokens objects without adding a runtime dependency on
  `quanteda`.
- Added `lexdiv_widen()` as a deterministic, computation-free long-to-wide
  transformation that keeps profile parameter requests distinct.
- Added base-R plot methods for metric, batch, profile, screen, TUBELEX
  coverage, and existing New JACET 8000 results.
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
- Added the deterministic expected-TTR curve-fit D under the explicit method
  ID `expected_ttr_d_hypergeom_fit_v1`. It uses exact finite-population
  expected TTR values, no random sampling, and makes no CLAN VOCD identity
  claim.
