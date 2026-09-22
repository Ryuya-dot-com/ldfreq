# ldfreq 0.2.0 (development)

## Compatibility and migration

- TUBELEX profiles now reject `lexdiv_tokenization` objects by default because
  their segmentation differs from the bundled Treebank resource. Prepare
  source-compatible term vectors externally; vector alignment remains
  unverified. The explicit `tokenization_mismatch = "allow"` override records
  a different-tokenizer sensitivity analysis. Coverage is not alignment evidence.
- Preprocessing contract 0.2.0 requires text hashes, token pattern, character
  counts, and a token-table fingerprint, and checks normalization consistency.
  Recreate objects saved under 0.1.0 from their original text and reapply
  annotations. Tokenizer rules and tokenizer version 0.1.0 are unchanged.
- `lexdiv_widen()` retains contract, requested/effective parameters, and N/V
  by default. It rejects column groups containing unlike specifications;
  plan-local request labels are not globally unique. Metric plots similarly
  require one specification and invisibly return all selected result fields.

## Corrections and additions

- Corrected cancellation near saturation in `expected_ttr_d_hypergeom_fit_v1`
  by computing expected duplicate-draw fractions and model residuals directly.
  The exact expected-TTR curve, objective, and method ID remain unchanged;
  record package version for numerical reproducibility. A one-doubleton,
  million-token regression agrees with an independent 80-digit reference.
  The earlier result was about 8.8% too small. No arbitrary D cap is introduced.
- Added `tubelex_profile_batch()` with one verified resource snapshot per call,
  document-local invalid results, a row budget, and complete per-document outputs.
- TUBELEX profile contract 0.2.0 records the input alignment boundary and adds
  explicit `normalization = "tubelex_apostrophe"` for internal apostrophe/prime
  typography. This does not provide Treebank segmentation. Default term-vector
  normalization, resource bytes, and lookup formulas are unchanged.
- Documented the frozen MTLD minimum-factor/tail discontinuity and added a
  regression example. Its definition has not been silently clamped or replaced.
- Added a worked research-design vignette distinguishing parameter sensitivity,
  computability, reference coverage, and evidence of construct validity.

# ldfreq 0.1.0

## Caller-supplied lexical norm profiles

- Added `lexdiv_norm_profile()` for exact, single-document profiling against
  caller-supplied lexical norm tables. One call can describe several measures
  while preserving each measure's construct, unit, direction, population, and
  resource provenance.
- Token- and exact-type means use observed matched values only. The result
  reports resource coverage, input-relative value coverage, and conditional
  annotation coverage separately; OOV terms and matched keys with missing
  annotations are never converted to zero or merged into one missing state.
- Added strict table and metadata validation, deterministic resource-row-order
  invariance, a whole-result row bound, bounded printing, an installed
  normative JSON contract, and randomized independent-oracle tests. The API
  performs no implicit normalization, fuzzy matching, thresholding, composite
  scoring, runtime download, or data-license inference.

## Local MATTR profile

- Added `lexdiv_mattr_profile()` to expose every complete step-one MATTR
  window, its local TTR, and position-only window exposure without retaining
  token strings. It accepts only canonical MATTR specifications from the
  existing `lexdiv_spec()` / `lexdiv_grid()` / `lexdiv_plan()` identity layer.
- The unchanged `lexdiv_profile()` rows remain the summary authority. Local
  means reconcile with the core value; empty, invalid, and too-short inputs
  retain canonical structured missingness and receive no fabricated detail
  rows.
- Added a combined row bound, bounded print method, and one-request-at-a-time
  plot method. The contract treats the output as a descriptive local
  trajectory and positional-exposure audit, not an inferential stability test,
  automatic window selector, or universal text-length rule.

## Reference coverage API

- Added `lexdiv_reference_coverage()` for the directional many-to-one question:
  what proportion of each document's tokens and distinct types occurs in one
  explicit reference term set? The document-major long summary retains measure
  and method IDs, numerators, denominators, input counts, match counts, status,
  missing reasons, and contract/schema identity.
- Kept matching exact and preprocessing-free. Document repetition affects only
  token-weighted coverage; reference repetition affects diagnostics but not set
  membership. Empty documents, an empty reference, invalid document vectors,
  and an invalid reference have distinct, tested behavior.
- Added named-list and explicit data-frame batch inputs, a whole-result row
  bound, opt-in term/count/match details with disclosure, path-free IDs, a
  bounded print method, and a one-weighting-at-a-time plot method that returns
  its plotted rows invisibly.

## Canonical public API names

- Established `nj8_profile()`, `nj8_profile_batch()`, `tubelex_profile()`, and
  `lexdiv_overlap_ids()` as the sole public names for their respective
  operations. The compact resource names and regular `_ids` catalog suffix keep
  autocomplete and installed help within one canonical vocabulary.
- Registered the corresponding result classes and S3 methods under the same
  canonical vocabulary, and synchronized it across README examples, installed
  help, vignettes, the offline smoke example, and pkgdown navigation.
- Added concise, lossless print methods for method specifications, grids, and
  plans, and made `plot()` on a raw-text metric result delegate to its
  unchanged core result table. Plot methods continue to return the displayed
  data invisibly for reuse.

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

- Made the documented-public-API audit part of ordinary pull-request CI, not
  only the exact-candidate path. Release-state classification now fails on an
  inconsistent package/scope/version or an unknown status instead of silently
  treating malformed candidate metadata as development.
- Excluded locally rendered pkgdown output from source-package builds and
  removed a documentation hyperlink whose upstream server rejects automated
  availability checks. The authoritative resource name and source remain
  stated without creating a false release-readiness signal.
- Documented every registered S3 method under an installed help alias and
  added a repository API audit that cross-checks exports, S3 registrations,
  value/examples, the public-surface inventory, and pkgdown navigation.
- MATTR plotting now rejects non-scalar or missing `add_global_mean` values
  instead of treating them as an implicit false choice. MATTR and reference
  coverage contracts now fix every reusable table's component and column
  topology.
- The package-resource inventory now discovers every installed `inst/spec`
  file automatically, so a new contract cannot bypass source/archive/install
  identity checks through omission from a hand-maintained list.
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
  used only for caching and is never copied to public provenance or results.
- Preprocessing contract `0.1.0` validates annotation provenance strictly,
  including explicit UPOS-backend identity. Serialized objects are revalidated
  before use; unsupported or manually altered provenance fails explicitly.
- Kept tokenizer and preprocessing contract identity at `0.1.0` because all
  corrected behavior is part of the first unpublished release.
- Versioned the installed, non-exported lexical-resource loader, manifest,
  lookup contract, and result schema as `0.1.0` without changing loading,
  matching, formulas, or resource behavior.
- Separated package-release review records from installed resource
  metadata. The installed manifest now contains only bundled-resource,
  provenance, license, identity, and runtime-boundary facts.
- Added a CC0 cross-language semantic fixture for the ten R/Python formulas
  that share method IDs. It compares parsed values, status meaning, and missing
  reasons, while recording the intentionally different R and Python MTLD
  boundary variants without claiming byte-level fixture identity.

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
  mappings. Fixed adapter identities, caller-declared resource/override labels,
  identity fallback, and match coverage are recorded without retaining local
  file names, content hashes, absolute paths, or redistributing the list.
- Added `lexdiv_variant_ids()` and `lexdiv_variant_metrics()` to compare four
  Maas definitions and four sequential-MTLD definitions. TAALED-related rows
  are formula comparators, not end-to-end compatibility claims.
- Added bounded method specifications, parameter grids, request plans,
  multi-document profiles, and independent token-length screens.
- Added `nj8_profile()` and its batch and plot methods for a
  caller-supplied New JACET 8000 list. Exact and cumulative Level 1--8 token
  and type rates retain off-list items in the denominator. The package neither
  bundles nor downloads the list.
- Added `tubelex_profile()` with explicit query normalization,
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
