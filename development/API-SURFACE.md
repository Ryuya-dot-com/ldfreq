# Public API surface audit

Status: pre-CRAN audit for package version 0.2.0

Audited: 2026-10-06

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
- All eleven plot methods use color by default and accept the named argument
  `monochrome = TRUE`, without a new export or dependency. No automatic title
  is added; plots retain their existing selection and return contracts.
  Color and shape jointly encode advisory status in both modes. Cosmetic
  defaults restore device settings and do not change plot coordinates/layout.
  An undefined NJ8 proportion now raises an error instead of displaying zeros.
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

`lexdiv_family_profile()` adds a distinct resource-defined family operation.
It cannot be a flemma option without changing that adapter's AntBNC mapping,
identity-fallback and tokenization-object contracts. The new function instead
requires complete imported annotations, allows multiple family candidates,
abstains on unresolved occurrences and returns explicit document tables.
There is no new class, generic, alias or metric formula;
the example reuses core metrics only for complete selected sequences. The
optional `review` argument now accepts the existing ambiguity-review result,
prepared through `$review_input`; this reuses its judgments and source checks
without a competing reviewer API or new dependency. Per-occurrence record
eligibility and a full family-policy snapshot guard application. The default
lookup behavior is unchanged; affix analysis remains outside this contract.

The explicitly sourced `word-parts.R` helper and optional
`morpholex-word-parts.R` reader remain example recipes, not exports. Their
separate analyses/parts tables retain source IDs, canonical parts, roles,
processes and declared scope. Candidate ambiguity and partial analyses are
explicit; no derivation tree or occurrence-review application is implemented.
The MorphoLex parts reader retains original selected rows and workbook identity.
It defaults to the bundled snapshot, and supports an optional external workbook.
`morpholex_data()` is a separate, narrow public data reader: no existing entry
point exposes the complete heterogeneous sheets and provenance. It returns a
plain list without introducing a class, S3 method, morphology analyzer or new
dependency. The full data and dictionary retain CC BY-NC-SA 4.0 conditions;
the independent code remains MIT. The distribution declares use restrictions.

`bnccoca_data()` adds one resource-branded data reader, not a second family
profiler or analyzer. Existing entry points do not expose Nation's actual
inventory and supplementary categories. Its plain list supplies the dictionary
and scalar resource declaration to `lexdiv_family_profile()`, beside separated
supplements, a source-file catalog and conversion provenance. No arguments,
new class, dependency, automatic grouping or convenience aliases are needed.
CC BY-SA 4.0 applies to the data/conversion. J-UniMorph remains a researched
candidate; no new general morphological analyzer is implied.

`morphynet_read_derivations()` adds a local-file reader for six-column source
relations, not a family adapter or inference engine. Neither existing reader
accepts this source/target/POS/affix schema. It validates fields and row bounds,
retains alternatives, raw POS and file identity, and returns plain relations,
resource and provenance components. Explicit language/version declarations
prevent file-name guessing. The sourced example reuses the existing optional
quanteda review API. A single selected edge is a declared study choice, not
unique truth or the complete affix structure. Only an attributed nine-row
CC BY-SA 3.0 excerpt is installed; full data remain local input. No class,
dependency or generic reviewer is added.

## Export inventory

The explicitly sourced `japanese-document-profile.R` recipe consumes an unchanged
complete annotation import, a complete anchored selection and caller-supplied
POS groups. It returns document accounting, codepoint/feature tables, source
rows, inputs and policy. Character populations and token denominators remain
separate; missing labels and unmapped POS do not disappear. It adds no export,
class, analyzer or dependency. Lexical review remains a separate saved component.

The explicitly sourced `candidate-proposals.R` recipe handles categorical
choices/abstentions without fabricating scores for `lexdiv_import_contextual()`.
Its offline prepare/import helpers retain source/candidate identity, all-review
coverage and separate human/model columns. The optional OpenAI caller uses httr2,
explicit paid opt-in and saved request/result files; it is not an export or an
automatic preprocessing step. It adds httr2 only to Suggests. Provider-neutral
category transport remains an example contract pending broader use; no new
class, evaluator or implicit human decision is introduced.

| Export | Role and return boundary | Batch relation | Print | Plot | Analysis-ready access |
|---|---|---|---|---|---|
| `morphynet_read_derivations()` | Local six-field derivational TSV reader; preserves source/target/POS, affix position, alternatives and file identity | Reference resource; not a document profiler | Base list | No | `$relations`, scalar `$resource` for candidate review, `$provenance`; example preserves source row mapping and occurrence decisions |
| `bnccoca_data()` | Bundled Nation BNC/COCA Level 6 membership, Version 1.0.0; no inferred members | Reference resource, not document data | Base list | No | `$dictionary`, separate `$supplementary`, `$catalog`, `$resource` for family lookup, `$provenance` for source/conversion identity |
| `morpholex_data()` | Bundled MorphoLex-en worksheet values and provenance; all sheets or an explicit ordered subset | Reference resource, not document data | Base list | No | `$sheets` (character-valued original data frames), `$provenance` including source identity, license and complete sheet catalog |
| `lexdiv_family_profile()` | Experimental exact form/POS lookup against a caller-defined family table; optional source/policy-bound occurrence review; retains original lookup, ambiguity and missingness | Complete imported annotations with document IDs; pooled summary explicitly separate from document metrics | Base list | No | `$occurrences`, `$candidates`, `$members`, `$documents`, `$summary`, complete `$annotations`, `$dictionary`, `$review_input`, `$review`, `$provenance` |
| `lexdiv_amod_pairs()` | Experimental basic-UD ADJ–amod–NOUN extraction from complete source-checked annotations; validates trees and distinguishes missing sentences from zero pairs | Explicit document/sentence IDs; observed counts beside complete totals and coverage | Base list | No: select counts, types or coverage explicitly; guide overlays original count distributions | `$occurrences`, `$counts`, `$segments`, `$documents`, `$summary`, complete `$annotations` and `$provenance` |
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
| `lexdiv_evaluate_annotations()` | Experimental single-label evaluation against an explicit reference on the same imported source segmentation | Per-document coverage and all-occurrence pairing in reference order | Base list | No: select a label and denominator | `$summary`, `$labels`, `$documents`, `$pairs`, `$confusion`, `$review_queue`, complete inputs and declared policy |
| `lexdiv_align_annotations()` | Experimental source-interval correspondence across different token segmentations; optional label evaluation on exact spans only | Same source segment roster; preserves empty documents and both token indices | Base list | No: select geometry or conditional labels explicitly | `$summary`, `$documents`, `$groups`, `$members`, `$boundaries`, `$review_queue`, optional `$annotation_evaluation`, complete inputs and policy |
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

The audit requires every export to have an installed help alias, an explicit
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
