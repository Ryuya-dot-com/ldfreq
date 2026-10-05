# ldfreq 0.2.0 (development)

## Source alignment across token segmentations

- Added experimental `lexdiv_align_annotations()` for complete imports of the
  same original segments with different token boundaries. Source-interval
  groups retain split/merge/complex relations, both token IDs and original KWIC.
- Exact token-span coverage and internal-junction agreement have separate
  denominators. Optional label evaluation is conditional on exact span pairs;
  unmatched tokens and missing labels remain visible. Existing same-segmentation
  evaluation retains its strict contract and results.
- Added an offline English/Japanese example and guide connecting whole-input
  token/type counts, TTR and fixed-window MATTR to saved-input replay. No corpus,
  model or required dependency was added. These examples do not establish
  analyzer accuracy or psychological validity.


## Reference-based annotation evaluation

- Added experimental `lexdiv_evaluate_annotations()` for complete external
  annotations with identical source segmentation and an explicit reference.
  It returns per-label TP/FP/FN, precision/recall/F1, document coverage, sparse
  confusion counts and every occurrence with original-text character context.
- Unavailable references are not scored as negatives; missing predictions on
  available references count as false negatives. Empty documents and original
  review/failure metadata survive. Reference independence remains a declaration.
- A new guide and offline English/Japanese example connect changed noun
  selections to document TTR, retaining incomplete and empty documents. Equal
  noun counts can hide different selected words. No analyzer, model, corpus or
  new dependency is added; different segmentations and dependency-head accuracy
  are outside this evaluator's contract.

## Annotation sensitivity example

- Added explicitly sourced offline scripts linking changes in supplied lemmas
  and UPOS to source-text context, TTR/MATTR and NJ8 coverage. Paired differences
  retain non-computable results; selection and reference denominators remain
  separate, including missing annotations and empty documents.
- The vocabulary-audit guide explains original-text checks, position mapping,
  fixed analysis conditions and saved-input replay. Authored examples show why
  changed labels need not change scores and unchanged counts can hide different
  exclusions. No new export, dependency, corpus or annotation-accuracy claim is
  introduced.

## Source-aligned phrase-list example

- Added an explicitly sourced helper and an offline English/Japanese example
  linking caller-supplied phrase components to quanteda search, original-text
  KWIC, per-ID counts and union token coverage. Long, nested and overlapping
  expressions retain source positions; exclusions remain gaps.
- The annotated-corpora guide explains segmentation, exact surface matching,
  case/Unicode policy, punctuation, empty documents, denominators, RDS replay
  and separate human interpretation. No new export, dependency or external
  phrase inventory is added.

## Reusable contextual study example

- Added three installed R scripts connecting authored source/annotation inputs,
  document/group split checks, development evaluation, frozen settings and
  training inputs, test scoring before reference access, and read-only replay.
- The contextual-model guide explains replacing the illustration with real
  annotations and model outputs. Reports retain each method's coverage,
  common-occurrence comparisons, unresolved references and individual judgments.
  The example does not establish independent labels or empirical accuracy;
  no new exported API, inference, corpus, model or dependency is added.

## Supervised contextual baselines

- Added experimental `lexdiv_score_contextual()` with centroid-cosine and
  training-frequency scores, using selected training references without reading
  query labels or prior suggestions. Both outputs feed contextual evaluation.
- Checks disjoint document IDs, identical target-context copies, candidate/
  resource snapshots and embedding declarations/dimensions. These checks do not
  establish a leak-free study or independent human labels.
- Retains per-candidate training counts, normalized prototypes, zero/missing
  vectors, canceling centroids, original model reasons and complete inputs.
  Unseen candidates remain missing for cosine and zero-count for an observed
  surface's frequency baseline. Unseen surfaces receive no scores. No fallback,
  smoothing, tie breaking, inference or new dependency is implicit.
- The English/Japanese guide connects authored training examples, separate query
  references, coverage-aware baseline comparison, KWIC inspection and RDS replay.

## Comparing model suggestions with reference judgments

- Added experimental `lexdiv_evaluate_contextual()` with explicit score direction
  and absolute tie tolerance. Predictions require scores for the complete
  supplied inventory and one best candidate; missing rivals and ties abstain.
- Overall/per-term summaries report matching predictions, conditional agreement,
  reference/prediction/pair coverage, singleton predictions and unscored reference
  candidates. Term-specific confusion counts and a KWIC review queue retain
  unavailable comparisons. Human judgments are not overwritten.
- Reference protocol, model exposure and evaluation role are recorded as caller
  declarations. The guide distinguishes reference agreement from validated WSD
  accuracy and illustrates high conditional agreement with low coverage. No
  model inference, new dependency, external data or tuning procedure is added.

## External contextual model outputs

- Added experimental `lexdiv_import_contextual()` to check occurrence IDs,
  source text/spans and review identity before attaching external embeddings
  or candidate scores. Human decisions remain separate; skipped, failed and
  absent output stays in the coverage denominator. Scores are not converted
  to probabilities or automatic selections.
- Added an offline English/Japanese guide and an explicitly invoked Python
  example using separately cached, commit-pinned Hugging Face models. It checks
  exact target subword coverage and skips overlong contexts without truncation.
  R does not invoke inference, install software or download models. No model
  weights, corpus data or new R dependency is included.

## Reviewed Japanese polysemy estimates

- Added explicitly sourced `read_wlsp_polysemy()` and
  `review_wlsp_polysemy_items()` examples for the separately obtained, pinned
  WLSP-norms v1.0 file. Exact WIDs, decorated words, classifications, signed
  estimates, mapping reasons and unselected items remain visible.
- Added a guide joining reviewed items and KWIC occurrences to these values,
  reusing the existing norm-profile and ambiguity APIs. Full-item coverage is
  separate from the selected-record profile. Values are not rescaled into raw
  ratings, sense counts or sense-specific frequencies. No new exported API,
  dependency or external rating data is added.

## Contextual ambiguity review

- Added `lexdiv_compare_ambiguity()` to pair two intact reviews by occurrence
  ID, retain both decisions and KWIC contexts, and return disagreements and
  other open cases for review. Conditional agreement, its numerator/denominator,
  joint-selection coverage and status pairs are explicit. Missing/unresolved
  choices never count as semantic agreements; no kappa or automatic adjudication
  is computed. Review results now include a whole-result fingerprint.
- Extended the separately sourced WLSP example with `wlsp_ambiguity_candidates()`
  to connect the verified local v4.0 file to KWIC candidates. Record IDs,
  readings, classifications, coverage and source terms survive. Record counts
  are not treated as validated counts of distinct senses; no data are bundled.
- Added experimental `lexdiv_ambiguity_review()` for complete imported
  annotations. It reuses optional quanteda KWIC search and retains original
  segment text, token positions, candidate counts, and occurrence identities.
- Caller-supplied candidates and explicit decisions stay separate. Single
  candidates are not selected automatically; unreviewed, selected, unresolved
  and no-candidate occurrences remain distinguishable. Decisions include a
  reviewer and reason and are checked against the source/candidate snapshot.
- Added an offline English/Japanese guide with reordered decisions and an
  RDS round trip. No semantic model, dictionary, corpus, automatic sense
  disambiguation, sense-specific reference frequencies or new dependency is added.

## Japanese frequency and stimulus review

- UTF-8 frequency fields are read without conversion to the native locale.
  The optional gibasa recipe requires R >= 4.2; the core remains R >= 4.1.
- Added an explicitly sourced local-file helper for the pinned Japanese
  TUBELEX orthographic-base table. It records original/reviewed/normalized
  forms, unresolved and unmatched items, source hash and published denominators;
  frequencies and video/channel proportions reuse `lexdiv_norm_profile()`.
- Added a stimulus-selection guide joining TUBELEX, WLSP-familiarity, AoA and
  BOI by study item ID, with per-condition missingness, distributions, explicit
  WLSP choices and an RDS round trip. The optional gibasa annotation workflow
  connects reviewed base forms while retaining original token positions.
- No Japanese data tables or new mandatory dependencies are bundled. The
  helper performs reviewed key lookup, not full TUBELEX tokenizer replication.

## Japanese norms for stimulus items

- Added an explicitly sourced WLSP-familiarity example for reviewing all
  exact-spelling candidates and recording item-to-record choices with reasons.
  It preserves unmatched and unreviewed items separately, checks record IDs
  against the intended spelling, and retains five published estimates without
  choosing a candidate automatically. Norm data are obtained separately.
- Added a guide and an explicitly sourced example for separately obtained
  Japanese AoA or BOI aggregate files. It reuses `lexdiv_norm_profile()` and
  retains study IDs, experimental conditions, source IDs, rating counts, SDs,
  unmatched items, source hashes and data terms. Each resource works independently.
- Documented age-category interpretation, condition-specific missingness and
  ambiguous spelling/reading keys. No external norm values, new dependencies,
  automatic downloads or new exported functions are included.

## External annotations and a Japanese input workflow

- Added experimental `lexdiv_import_annotations()` to align complete external
  token tables with original segment text. It retains lexical forms, POS,
  missing annotations, original token indices, empty documents, dictionary
  declarations and source hashes. Positions use segment-local Unicode
  codepoints; omitted non-whitespace text and normalization mismatches fail.
- Added an offline Japanese illustration and an optional R-only gibasa/UniDic
  recipe. The importer needs no new mandatory dependency; gibasa is suggested
  for the recipe and dictionaries are obtained separately. Filtering preserves
  gaps for the existing n-gram and quanteda interfaces. English tokenizer,
  bundled resources and all existing metric definitions are unchanged.
- This does not bundle Japanese frequency norms or add a new morphological analyzer,
  split/merge comparison, or evidence of cross-language measurement equivalence.

## Building references from larger local inputs

- Added `lexdiv_ngram_reference_build()` to read whole-document extraction
  chunks sequentially and retain exact type counts, document counts,
  denominators and source fingerprints. Occurrence tables are released after
  each chunk. Distinct types and document IDs still occupy memory; there is
  no disk-backed index, pruning or automatic resume. No dependency was added.
- MASC reader interface 0.2.0 accepts `documentHeader`/`.hdr` references as
  well as Mini-MASC's `cesHeader`/`.anc` layout. Boundary checks are unchanged.
  An audit of all 392 official MASC 3.0.0 documents accepted 122 and rejected
  270 under these checks; this is not validated whole-corpus support.

## Comparing reference choices

- Added `lexdiv_ngram_compare()` to apply named references to the same target,
  retain each reference's available-value mean and coverage, and compare rates
  on target items with defined values in every reference. Common-set means,
  differences from an explicit baseline, source positions, denominators and
  metadata stay together; undefined comparisons remain missing.
- Added an offline example showing that pruning can raise a conditional mean
  while frequencies on the common items remain unchanged. Existing frequency
  arithmetic is reused; there are no new dependencies or automatic rankings.
- Clarified that the quanteda adapter's UTF-8 requirement concerns the running
  R session, including on macOS. `C.UTF-8` is UTF-8-capable and differs from
  the plain `C` locale used in a stress test.

## Annotated corpus input and quanteda integration

- Added experimental `lexdiv_read_masc()` for local GrAF 1.0 Penn annotations,
  verified with Mini-MASC 1.0. It retains supplied token boundaries, lemma/POS
  features, sentence/utterance IDs, source coordinates, original text and file
  fingerprints. Overlapping, discontinuous or unresolved spans are rejected.
  Source anchors may explicitly use Unicode codepoints or UTF-16 code units.
- Added `lexdiv_as_quanteda()` for explicit token and segment tables, preserving
  excluded positions, empty segments and mappings back to source rows. It uses
  quanteda's public APIs without retokenization; quanteda is an optional
  dependency. Existing core calculations and tokenizer defaults are unchanged.
  Non-ASCII imports require a UTF-8 locale; the adapter verifies imported
  terms and positions and never changes the user's locale.
- Added an offline guide and original, MIT-licensed annotation example.
  MASC/OANC corpus data are not bundled or automatically downloaded. Other
  annotation layers and OANC are not validated reader inputs. See the
  MASC 3.0.0 scope above before using that release.

## Adjacent n-grams with local references

- Added `lexdiv_ngrams()` for adjacent bigrams and trigrams from explicit
  document/segment IDs and original positions. It retains occurrences, corpus
  and document counts, eligible-window totals, empty documents and provenance.
  Position gaps break adjacency; no sentence splitting or normalization is
  inferred. An occurrence-row ceiling is checked before output allocation.
- Added `lexdiv_ngram_reference()` for local extractions or external aggregate
  tables with explicit totals and source metadata, and `lexdiv_ngram_profile()`
  for per-document token/type means and coverage. Complete-reference sample
  zeros and unlisted incomplete-reference keys have different states. Rates
  divide by eligible n-gram opportunities. RDS preserves full provenance.
- Added an offline guide with authored examples, boundary counterexamples,
  CSV import and RDS reuse. No n-gram corpus, new dependency, association score
  or automatic download is added. Contract version starts at 0.1.0.

## Open-access academic texts

- Added an explicitly run example and guide using three CC BY 4.0 JOSS papers.
  The recipe checks pinned source hashes and licenses, records paragraph
  extraction, and saves attribution, metadata, diagnostics and full results.
  Paper text is obtained only when requested and is not bundled. `xml2` is an
  optional dependency for this recipe. Author L1 remains unknown; the example
  describes academic English without assigning a native-speaker label.

## Caller-supplied references across corpora

- Added `lexdiv_norm_profile_batch()` with one shared resource validation,
  a global output-row bound, and document-specific summary, lookup and coverage
  tables. Single-document arithmetic and missingness are unchanged. Empty
  documents and unmatched/missing annotations remain explicit.
- Added a guide for custom reference data, exact word units, document metadata,
  three coverage denominators and reproducible saving. No new dependencies or
  external datasets are required. Third-party copyright notices are now also
  referenced from DESCRIPTION.

## Corpus scope and study design

- Clarified native-speaker and learner corpus applications, including
  within-population register comparisons. The comparison guide distinguishes
  analysis samples, reference resources and matched comparison samples, with
  spoken-data boundaries and language-background metadata kept explicit.
  The vocabulary-use guide remains one application, not an input requirement.

## Paired vocabulary responses

- Added `lexdiv_compare_responses()` for already scored binary response pairs.
  It checks composite pair IDs, separates directional disagreement and three
  missingness patterns, and reports numerators and denominators by explicit
  groups. Original metadata remain attached. It does not score free text,
  dichotomize partial credit, or estimate lexical employability.
- The vocabulary-use guide now includes CSV input, item/sense matching,
  rubric metadata and repeated-occasion examples using this function.

## TUBELEX diagnostics and vocabulary-use evidence

- Added `tubelex_diagnostics()` to turn existing profiles into reusable summary
  and document tables, count confirmed unmatched terms, and inspect query
  normalization. It retains empty/failed documents and unresolved matches,
  separates recorded input conditions, and performs no new resource lookup.
- Added a worked guide connecting TUBELEX word-form features to explicitly
  scored learner-by-item responses. It distinguishes recognition, meaning recall
  and contextual use, preserves missing pairs and directional disagreement, and
  does not interpret corpus frequency as an employability score.

## Reproducible lemma dictionaries

- `lexdiv_lemmatize(method = "textstem")` now accepts `dictionary`,
  `dictionary_id` and `dictionary_version`. It records the actual dictionary's
  SHA-256 fingerprint and lookup locale, including for the default lexicon
  dictionary. Save the dictionary separately for reruns. It remains an optional,
  context-free backend; aligned supplied annotations support contextual review.
- Preprocessing contract 0.4.0 retains reading of 0.3.0 objects and 0.2.0
  Unicode objects. Lexical-overlap contract 0.2.0 checks dictionary records for
  lemma comparisons involving textstem; absent legacy records cannot establish
  strict comparability. Metric formulas and result schemas are unchanged.

## Annotation comparisons

- Added `lexdiv_compare_annotations()` to compare lemma, UPOS and flemma
  annotations on the same tokenized text or named document batches. It checks
  original text and token alignment, pairs by document ID, retains empty
  documents and missing annotations, and preserves both provenance records.
  Differences identify changed labels, not errors or proficiency gains.

## NJ8 diagnostics

- Added `nj8_diagnostics()` for existing single or batch profiles. It counts
  unmatched terms and surface-to-unit mappings by occurrences and documents,
  flags introduced numeric/whitespace labels, and preserves coverage,
  exclusions and provenance. It does not rerun lookup, correct annotations or
  label unmatched terms as difficult words.
- Added a worked guide to surface/lemma coverage and parameter sensitivity,
  using authored examples that run without an external model or corpus.
  It includes paired document/condition tables that retain uncomputable rows,
  and a fixed-frequency example separating MATTR position effects from HD-D.

## English text and document tables

- Added an opt-in `tokenizer = "english"` using R and the existing stringi
  dependency. It retains contractions, hyphenated words and dotted initialisms,
  canonicalizes apostrophe/hyphen typography, and records excluded URLs,
  emails and number-like spans with processed-text offsets and fingerprints.
  Existing Unicode-tokenizer defaults and numerical definitions are unchanged.
- Added `lexdiv_tokenize_batch()` for named text vectors or explicit ID/text
  tables, and `lexdiv_metrics_text_batch()` for raw or prepared documents.
  Document IDs, empty documents, full metric rows, token audits, and preprocessing
  records survive the batch workflow; missing texts produce identified errors.
- Preprocessing contract 0.3.0 supports both tokenizer identities. Saved 0.2.0
  Unicode objects remain valid. Neither tokenizer claims Treebank equivalence.
- Added a tokenizer guide with worked segmentation differences, CSV/UTF-8 text
  input, NJ8 coverage, and reporting guidance.

## Bundled vocabulary and research workflows

- New JACET 8000 is bundled with JACET's permission and source attribution.
  `nj8_profile()` and `nj8_profile_batch()` now default to this versioned table;
  explicit external tables remain supported. The level-profile contract advances
  to 0.2.0, recording bundled/external identity and the bundled source citation.
- Checked all 8,000 rank/entry pairs against the official workbook. Corrected
  three entries in the supplied snapshot: restore `nan` at rank 6926, and
  lowercase `true`/`false` at ranks 326/2382. Source and correction records are
  installed with the data. Lookup checks the bundled file before use.
- Added a complete text-to-report example, resource/method citation guidance,
  and an optional external NLTK recipe for TUBELEX input. Python remains optional
  and is not called by any R calculation.
- Reorganized the introduction around comparison conditions and reference
  coverage, with an explicit comparison to existing R packages.

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

## Other corrections

- `lexdiv_metrics_text()` forwards custom expected-TTR D sample sizes to
  the token-vector core.
- Lemma, UPOS, and flemma annotations are checked against their recorded
  settings before use. UPOS identity is explicit even when the same pipeline
  generates lemmas and tags.
- MATTR plotting validates `add_global_mean`; plots return their selected
  data invisibly. S3 methods are documented in installed help.

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
- Added `nj8_profile()` and its batch and plot methods, initially for a
  caller-supplied New JACET 8000 list. Exact and cumulative Level 1--8 token
  and type rates retain off-list items in the denominator. Version 0.1.0 did
  not bundle the list; version 0.2.0 adds the permitted reference table.
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
