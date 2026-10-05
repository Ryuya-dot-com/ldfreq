# Public API surface audit

Status: pre-CRAN audit for package version 0.2.0

Audited: 2026-10-05

This repository-only record checks whether each exported function has a clear
role, result boundary, batch relationship, standard R interaction, and
analysis-ready extraction path. It is not installed with the package or
rendered by pkgdown.

## Decisions

- Keep the 26 existing canonical export names selected for the initial 0.1.0
  release, and add the substantively distinct `lexdiv_reference_coverage()`,
  `lexdiv_mattr_profile()`, and `lexdiv_norm_profile()` APIs.
- Package 0.2.0 adds `tubelex_profile_batch()` to reuse a verified resource
  snapshot without a persistent cache or reduced result object.
- Add no convenience alias and no new exported extractor solely to shorten
  component access.
- Use custom `print()` only where an object-specific header or bounded display
  materially improves a raw list or result table.
- Use package `plot()` methods only when one explicit scale or selection rule
  prevents unlike measurements from being compared silently. Every package
  plot method returns the plotted data invisibly.
- Do not add package `summary()` methods. Long result objects are already
  analysis-ready data frames; composite objects already expose a component
  explicitly named `summary` beside coverage, exclusions, diagnostics, and
  provenance. A generic that returned only one component would make it too
  easy to report a score without its denominator or coverage boundary.
- Do not add `as.data.frame()` methods for composite objects. Choosing one of
  several lossless tables implicitly would discard information. Users should
  select `$results`, `$tokens`, `$summary`, `$lookup`, `$coverage`, or another
  named component deliberately.

The English tokenizer is an explicit option of `lexdiv_tokenize()`, rather
than a second competing single-document facade. `lexdiv_tokenize_batch()` adds
validated raw-text tables and IDs; `lexdiv_metrics_text_batch()` additionally
retains joined result/audit tables and complete document-local preprocessing.

## Export inventory

| Export | Role and return boundary | Batch relation | Print | Plot | Analysis-ready access |
|---|---|---|---|---|---|
| `lexdiv_score_contextual()` | Experimental supervised centroid-cosine and training-frequency baselines over separate imported reviews | Same supplied inventory, disjoint documents, explicit training/reference audit | Base list | No | `$centroid`, `$frequency`, `$candidates`, `$prototypes`, both occurrence audits and complete inputs |
| `lexdiv_evaluate_contextual()` | Experimental complete-inventory ranking and descriptive comparison to an explicit reference review | Overall and per-target counts, coverage, and term-specific confusion; source IDs preserved | Base list | No | `$summary`, `$terms`, `$pairs`, `$confusion`, `$review_queue`, complete inputs and policy |
| `lexdiv_import_contextual()` | Experimental source-checked external embeddings/scores, distinct from human decisions; no inference | One complete review with all-occurrence coverage and ID-paired output | Base list | No | `$occurrences`, `$embeddings`, `$suggestions`, `$summary`, complete `$review` and model `$provenance` |
| `lexdiv_metric_ids()` | Core metric ID character vector | Catalog used by both core calls | Base | No | Vector |
| `lexdiv_content_overlap()` | Annotated content-word overlap composite | Pair operation; no batch inference | Overlap method | No: denominators differ by measure | `$summary`, `$coverage`, term and exclusion tables |
| `lexdiv_lemmatize()` | Adds explicit lemma/UPOS layers and textstem dictionary fingerprints to `lexdiv_tokenization` | Tokenization object remains document-scoped | Tokenization method | No | `$tokens`, `$provenance` |
| `lexdiv_compare_annotations()` | Validates identical source/tokenization before auditing changed lemma/UPOS/flemma labels | Single pair or named batches paired by ID | Base list | No | `$documents`, `$changes`, before/after `$provenance` |
| `lexdiv_compare_responses()` | Validates scored binary response pairs and composite IDs; preserves missingness and explicit denominators | Explicit categorical strata; repeated observations require additional keys | Base list | No: select a quantity and stratum | `$responses`, `$counts`, `$summary`, `$provenance` |
| `lexdiv_flemmatize()` | Adds explicit flemma layer to `lexdiv_tokenization` | Tokenization object remains document-scoped | Tokenization method | No | `$tokens`, `$provenance` |
| `lexdiv_grid()` | Bounded ordered list of method specifications | Feeds a plan, not documents | Concise grid method | No | List elements remain complete specs |
| `lexdiv_as_documents()` | Adapts named/tidy/quanteda tokens to a plain named list | Creates the batch boundary | Base | No | Plain named list |
| `lexdiv_read_masc()` | Experimental GrAF 1.0 Penn reader preserving supplied tokens, regions, text and hashes | Explicit vector of headers and unique IDs | Base list | No | `$tokens`, `$segments`, `$documents`, `$provenance` |
| `lexdiv_import_annotations()` | Experimental exact alignment of complete external surfaces to original text, preserving feature columns and declared analyzer/dictionary metadata | Ordered segment roster includes empty documents | Base list | No | `$tokens`, `$segments`, `$documents`, `$provenance` |
| `lexdiv_as_quanteda()` | Explicit token/segment tables to quanteda without closing gaps or retokenizing | Each segment has a mapping to its original document | Base list | Through quanteda | `$tokens`, `$positions`, `$segments`, `$provenance` |
| `lexdiv_length_evidence()` | Evidence registry data frame | Not document data | Base data-frame | No | Data frame |
| `lexdiv_mattr_profile()` | Canonical MATTR summary plus local-window and positional-exposure tables | Document-scoped; accepts a MATTR-only canonical plan | Bounded composite method | One explicit request | `$summary`, `$windows`, `$exposure`, `$diagnostics` |
| `lexdiv_norm_profile()` | Conditional lexical-norm means plus exact lookup and separate resource/value coverage | Document-scoped; caller supplies one norm table and its provenance | Bounded composite method | No: measures may have unlike scales and directions | `$summary`, `$lookup`, `$coverage`, `$provenance`, `$diagnostics` |
| `lexdiv_norm_profile_batch()` | Shared caller-supplied reference table applied to explicit documents with unchanged single-document arithmetic | One resource validation and global row ceiling; no corpus pooling | Bounded composite method | No: select a document, construct and weighting explicitly | `$summary`, `$lookup`, `$coverage`, shared `$provenance`, document/batch `$diagnostics` |
| `lexdiv_ngrams()` | Adjacent bigram/trigram extraction within explicit segments and consecutive original positions | Multiple documents with optional empty-document roster | Bounded composite method | No | `$occurrences`, `$counts`, `$document_counts`, `$documents`, `$totals`, `$provenance` |
| `lexdiv_ngram_reference()` | Validated extraction or caller aggregate with completeness, opportunity totals and source metadata | One declared reference population per n; reusable across targets | Bounded composite method | No | `$counts`, `$totals`, `$provenance`; save/read RDS |
| `lexdiv_ngram_profile()` | Exact sequence lookup and available-value means with sample zeros distinguished from unlisted keys | Per-document, per-n token/type summaries, no pooling | Bounded composite method | No: select document, n and weighting | `$lookup`, `$summary`, `$documents`, `$provenance` |
| `lexdiv_ngram_compare()` | Reference choice, common-item means and baseline differences beside unchanged per-reference coverage | One target, named references; common set across all references, no pooling | Base list | No: select document, n, weighting and reference | `$lookup`, `$summary`, `$documents`, `$references`, `$provenance` |
| `lexdiv_methods()` | Method registry data frame | Shared by single and batch calls | Base data-frame | No | Data frame with list-column parameters |
| `lexdiv_metrics()` | One-row-per-metric long data frame | Paired with `lexdiv_metrics_batch()` | Result method | Single selected metric | Data frame |
| `lexdiv_metrics_batch()` | Document-major long metric data frame | Explicit batch form | Batch-result method | Single selected metric | Data frame |
| `lexdiv_metrics_text()` | Core results plus token audit and preprocessing | Paired with `lexdiv_metrics_text_batch()` | Text-result method | Delegates to unchanged `$results` | `$results`, `$token_audit`, `$preprocessing` |
| `lexdiv_metrics_text_batch()` | Raw/prepared document metrics with audits and provenance | Explicit text batch | Text-batch method | Delegates to complete `$results` | `$results`, `$token_audit`, `$preprocessing` |
| `lexdiv_overlap_ids()` | Overlap measure ID character vector | Shared by both pair operations | Base | No | Vector |
| `lexdiv_plan()` | Deduplicated bounded request plan | Shared by profile calls | Concise plan method | No | `$specifications` and plan identity fields |
| `lexdiv_presets()` | Preset registry data frame | Shared by profile calls | Base data-frame | No | Data frame |
| `lexdiv_profile()` | One-row-per-request long result data frame | Paired with `lexdiv_profile_batch()` | Profile-result method | Single selected request/metric | Data frame |
| `lexdiv_profile_batch()` | Document-major request-profile data frame | Explicit batch form | Profile-batch method | Single selected request/metric | Data frame |
| `lexdiv_reference_coverage()` | Token/type coverage of many documents by one exact reference set | Explicit many-to-one batch operation | Bounded composite method | One explicit weighting | `$summary`, `$documents`, `$reference`, optional `$terms` |
| `lexdiv_screen()` | Independent token-floor screen data frame | Accepts single or batch profile rows | Base data-frame | One selected screen | Data frame |
| `lexdiv_spec()` | One normalized method/parameter request | Feeds grids/plans | Concise spec method | No | Named list fields |
| `lexdiv_tokenize()` | Lossless token rows and preprocessing provenance | Document-scoped | Tokenization method | No | `$tokens`, `$provenance` |
| `lexdiv_tokenize_batch()` | Named raw-text vector or ID/text table to complete tokenizations | Explicit text batch | Base list | No | Named list of `$tokens` / `$provenance` objects |
| `lexdiv_term_overlap()` | Exact term-set overlap composite | Pair operation; no batch inference | Overlap method | No: denominators differ by measure | `$summary`, `$counts`, optional term tables |
| `lexdiv_variant_ids()` | Variant registry data frame | Not document data | Base data-frame | No | Data frame |
| `lexdiv_variant_metrics()` | Cross-definition result data frame | Document-scoped | Variant-result method | No: families and scales differ | Data frame |
| `lexdiv_widen()` | Pure long-to-wide transformation | Preserves document IDs when present | Wide-result method | No | Data frame |
| `nj8_profile()` | Level summary, lookup, coverage, provenance, diagnostics | Paired with `nj8_profile_batch()` | Level-profile method | One weighting and scale | Named component tables |
| `nj8_profile_batch()` | Document-major level-profile composite | Explicit batch form | Batch-level method | No: document selection must be explicit | Named component tables with `document_id` |
| `nj8_diagnostics()` | Counts unmatched terms and lexical-unit mappings; flags observable string changes while retaining coverage and provenance | Accepts a single or batch NJ8 profile without repeating lookup | Base | No: inspect count and mapping tables | `$unmatched_terms`, `$unit_mappings`, `$coverage`, `$exclusion_reasons` |
| `tubelex_diagnostics()` | Reusable frequency tables, coverage, unmatched counts and query mappings from existing profiles | Single profile or named batch, preserving empty and failed documents | Base list | No: choose weighting and condition explicitly | `$summary`, `$documents`, `$unmatched_terms`, `$normalization_mappings`, full per-document metadata |
| `tubelex_profile()` | Frequency/prevalence summary, lookup, coverage, provenance | Paired with `tubelex_profile_batch()` | TUBELEX method | Token/type coverage | Named component tables |
| `tubelex_profile_batch()` | Input-ordered named list of complete frequency profiles | One verified resource snapshot per batch call | Base list | No: choose a document explicitly | Each document retains summary, lookup, coverage, provenance |
| `lexdiv_ngram_reference_build()` | Experimental sequential accumulation of whole-document extractions into exact reference counts | Unique document IDs across chunks; no pruning | Base list | No | `$reference`, `$sources`, `$documents`, `$provenance` |
| `lexdiv_ambiguity_review()` | Experimental source-verified KWIC and explicit lexical-candidate decisions | Complete imported annotations; per-occurrence IDs and snapshot checks | Base list | No | `$occurrences`, `$candidates`, `$decisions`, `$summary`, complete `$source` and `$provenance` |
| `lexdiv_compare_ambiguity()` | Descriptive agreement and unresolved decisions paired by occurrence ID | Two complete reviews of the same source and candidate snapshot | Base list | No | `$summary`, `$terms`, `$pairs`, `$review_queue`, `$status_pairs`, original `$reviews` |

## Documentation and reuse gate

The audit requires all 45 exports to have an installed help alias, an explicit
value section, and an executable example. Shared help topics are acceptable
when aliases, usage, argument ownership, and return types remain unambiguous.
Every help topic must appear in the pkgdown reference index.

Composite-result help must name every analysis table and warn when interpreting
the primary summary without coverage or denominator information would be
unsafe. Plot help must state the selected scale and invisible return table.
Internal identity, caching, and release records must not become an implicit
analysis column or a public-site page.

## Findings resolved in this audit

1. Raw list printing for `lexdiv_spec`, `lexdiv_grid`, and `lexdiv_plan`
   exposed long canonical identity strings and made plans difficult to scan.
   Their new print methods show bounded request/method/parameter tables, keep
   the full object unchanged, and return it invisibly.
2. `lexdiv_metrics_text()` contained an unchanged `lexdiv_results` table but
   did not support the same safe single-metric plot interaction. Its plot
   method now delegates to `$results` and returns the plotted data invisibly.
3. No default plot was added for overlap results, cross-definition variants,
   or multi-document NJ8 profiles. A generic chart would conceal denominator,
   scale, family, or document-selection differences; their named tables are
   the intended inputs to caller-controlled graphics and statistical models.
4. Reference coverage has one safe shared range but two different denominators.
   Its plot therefore requires one token/type weighting at a time and returns
   the selected rows, including numerators and denominators, invisibly.
5. Local MATTR is a composite because its canonical summary, window trajectory,
   and position exposure answer different questions. `print()` remains bounded,
   `plot()` requires one request when several window lengths exist, and no
   `summary()` or `as.data.frame()` method silently discards detail tables.
6. Six registered print methods were callable but not directly discoverable by
   installed help. Their aliases, usages, arguments, and invisible return
   behavior are now documented. MATTR's `add_global_mean` plot choice now uses
   the same strict scalar-logical validation as other public plot flags.
7. The MATTR and reference-coverage contracts now enumerate every reusable
   result table and column. Contract tests compare those arrays with live
   results, preventing a nominally unchanged 0.1.0 schema from drifting.
8. Generic norm profiling remains separate from bundled-resource adapters.
   Exact caller-prepared keys, measure/resource metadata, matched-only means,
   and three distinct coverage denominators are explicit. No default plot,
   composite score, automatic threshold, normalization, or license inference
   is introduced.

## Release gate

Before the first CRAN submission, regenerate this inventory from `NAMESPACE`
and fail review if an export is missing, undocumented, absent from pkgdown, or
lacks an explicit reusable-data path. Re-run examples, vignettes, the offline
smoke test, the complete pkgdown build, and `R CMD check` after any S3 change.
The repository-only gate is executable as:

```sh
Rscript --vanilla development/audit-public-api.R .
```

It compares `NAMESPACE`, installed-help aliases, value/example sections, this
inventory, and pkgdown topics; requires every registered S3 method to be
discoverable by help; rejects retired public names; and enforces the decision
not to register information-discarding `summary()` or `as.data.frame()` methods
for composite table objects.
