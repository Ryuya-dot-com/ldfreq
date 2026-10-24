# Public API surface audit

Status: maintained API inventory for development version 0.4.0.9006.
Eight study/corpus entry points and a concordance plot method are added.
Existing formulas, legacy return shapes and saved records remain supported.

Initial inventory audit: 2026-10-06; subsequent API decisions through 2026-10-08
are recorded below. Reference/status review: 2026-10-14. Current scope and
publication evidence are in [ROADMAP.md](ROADMAP.md) and
[PUBLICATION-20261004.md](PUBLICATION-20261004.md#current-identity-and-completion-evidence).
This inventory does not schedule a CRAN submission.

This repository-only record checks whether each exported function has a clear
role, result boundary, batch relationship, standard R interaction, and
analysis-ready extraction path. It is not installed with the package or
rendered by pkgdown.

## Decisions

- Development 0.4.0.9006 adopts public study-table construction/selection,
  concordance/sorting/within-document dispersion, collocations and keyness with
  an exact-term concordance handoff. These eight operations have distinct input
  and denominator contracts not supplied by existing metrics, widening, n-grams
  or review calls. Validators remain internal. The new concordance facade adds
  a class for `plot()`, whose invisible return includes displayed occurrences,
  document roster and query counts. Old source files delegate to the same
  internal implementations and keep old plain-list/ggplot outputs and signatures.
  Existing old saved records remain accepted. No dependencies or formulas change.
  Other examples are not promoted by this decision. The blanket export freeze
  is replaced by the individual naming, compatibility and integration gate.


- Development 0.4.0.9004 adds explicitly sourced `ddl_material()` and
  `ddl_material_write()` examples for teacher preparation. They validate an
  existing phrase-review record and explicit accepted selection, activity text
  and source notices. Learner HTML, teacher CSV and full private RDS have separate
  contents. Reopening requires no search; all existing exports, S3 registrations,
  dependencies, numerical contracts and review helpers remain unchanged.

- Development 0.4.0.9003 adds explicitly sourced `textbook_progression()` and
  `textbook_progression_plot()` examples. They consume one unchanged concordance
  record, an ordered section roster and teaching introductions. Page/Unit
  missingness, selected scope, known-match lower bounds and follow-up availability
  remain explicit. No export, S3 registration, required dependency or existing
  numerical/result contract changes.

- Development 0.4.0.9002 adds an optional named `labels` argument only to the
  sourced MCA plotting helper. The label-to-ID mapping affects display and its
  returned table; original IDs, fitted objects, exports and defaults are unchanged.

- Development 0.4.0.9001 adds explicitly sourced occurrence-MCA helpers, not new
  exports, classes or S3 methods. They reuse complete annotation inputs and
  optional `ca::ca()` on the indicator matrix; source-bound categories, exclusions,
  unadjusted diagnostics and complete saved records remain distinct from the
  document-term CA interface. Existing CA/MDS records still validate.

- The 0.3.0.9018 lexical-ordination example uses complete source annotations
  and an explicit document roster to prepare counts for optional `ca::ca()`
  and Jaccard/Hellinger `stats::cmdscale()`. Example records retain source rows,
  whole-document missingness exclusions, feature selection, geometry diagnostics
  and separate document/term maps. This adds `ca` to Suggests but no export,
  class, S3 registration or change to core numerical/schema contracts. MCA,
  nonmetric MDS, automatic corrections and inferential tests are not included.

These decisions describe the released interface. The
[2026-10-14 consolidation review](#2026-10-14-api-consolidation-review)
reassesses shared entry points. The continuation adopts only the
[9007 entry points](#9007-adopted-entry-points); the export freeze remained
in force at that checkpoint; the 9006 decision above supersedes that blanket rule. A current absence of a plot/summary method is not, by
itself, proof that an explicit selected view could never be supported safely.

- The 0.3.0.9005 text-batch `metadata` argument preserves explicit document-level
  information in an optional separate component. It uses the same document-ID
  validation as the batch input and checks the exact roster. No automatic
  extraction from raw-input extra columns, inference of study labels, insertion
  into core/token rows or new export is introduced. `NULL` keeps the existing
  three-component return and preprocessing/core contracts; imported annotation
  tables retain their separate workflow. Full RDS preserves column types.

- The 0.3.0.9004 `lexdiv_widen(mtld_diagnostics = TRUE)` refinement appends
  eight scalar fields for recognized core sequential MTLD specifications only.
  It reads saved diagnostics and shares derived flags with printing; it never
  recalculates metrics or changes long-result schemas, exports or dependencies.
  Default output remains identical, unavailable fields remain NA, and columns
  from different specifications or colliding names cannot overwrite each other.

- The 0.3.0.9003 phrase-list review is an explicitly sourced example, not an
  export or an extension of the single-token ambiguity API. It reuses the exact
  phrase search and the existing full-worksheet validation pattern. Decisions
  apply to source-bound occurrences under one declared criterion. Per-document
  and per-phrase state counts retain zeros; accepted-token union coverage is
  separate from candidate coverage and incomplete-review reporting. Original
  tokenization, lexical-diversity calculations and all 57 exports are unchanged.

- The 2026-10-07 core review freezes new feature exports. `lexdiv_methods()`
  adds a `stability` metadata column and marks expected-TTR D experimental;
  the coordinated core-contract 0.2.0 migration excludes it from defaults and
  uses no-minimum MTLD with a new method ID. Old min10 remains explicit, with
  no new export or numeric result field. Presets now have 11/13 requests. Existing
  compact result print methods are now used directly in the README.

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

The sourced `japanese-frequency-documents.R` recipes reuse the existing norm batch
API for document summaries, retain full anchored key/selection tables and all-token
coverage, and compare same-source/same-reference complete observed spans. Original
text, unresolved keys, exclusions and empty documents remain available. The optional
Japanese TUBELEX reader adds a complete local `reference` component for batches and
replay; no new export, class, core formula or dependency is introduced.

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
| `lexdiv_study_table()` | Planned observations joined to saved plan results; ordinary data frame with distinct submission/computation/reporting states | One selected document per observation; no recomputation or model fitting | Base | No | Complete ordinary table |
| `lexdiv_study_model_data()` | Explicit single-condition/request selection with metadata and exclusion audit | One row per observation and unique document | Base list | No | `$data`, `$audit` |
| `lexdiv_concordance()` | Complete source-aligned token-pattern search; classed full record | Declared source document roster including empty/zero-match documents | Base list | `plot()` selects one query, returns displayed tables invisibly | `$occurrences`, `$counts`, `$documents`, full `$source`, settings/provenance |
| `lexdiv_concordance_sort()` | Sort saved context nearest-token-first with stable ties | Same search and occurrence IDs | Base table | No | Ordered occurrence table |
| `lexdiv_concordance_dispersion()` | Unnormalised single-token within-document DP and per-part exposure | Document rows, not across-document dispersion | Base list | Position view belongs to search | `$documents`, `$parts`, occurrence IDs/settings/search ID |
| `lexdiv_collocations()` | Ordered eligible slot-pair opportunities, MI and t-score | Per-document audit beside pooled counts; not n-gram reference frequency | Base list | No | `$results`, `$pairs`, `$documents`, complete `$search`, settings/provenance |
| `lexdiv_keyness()` | Explicit disjoint target/reference counts, G-squared and unsmoothed log-ratio; no tests | Pooled token totals with document counts and coverage | Base list | No | `$results`, `$totals`, `$documents`, `$document_counts`, `$occurrences`, `$token_audit`, full `$source` |
| `lexdiv_keyness_concordance()` | Exact counted-term return to original contexts | Same retained source; no new comparison | Base list | `plot($search)` | Comparison ID, term and classed `$search` |
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
| `lexdiv_methods()` | Core or comparison method catalog selected by scope | Shared discovery; executor documented per scope | Base data-frame | No | Core parameters or comparison metadata |
| `lexdiv_metrics()` | Metric rows, or full request profiles with `plan` | Paired with `lexdiv_metrics_batch()` | Result/profile method | Single selected metric/request | Data frame |
| `lexdiv_metrics_batch()` | Document-major metric or plan result data frame | Explicit batch form; plan row bound | Batch/profile-batch method | Single selected metric/request | Data frame |
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

## API change verification

When the public API changes, reconcile this inventory with `NAMESPACE` and
fail review if an export is missing, undocumented, absent from pkgdown, or
lacks an explicit reusable-data path. Verify affected callers, examples,
vignettes, installed behavior and rendered documentation. Use full package/site
checks for broad changes; reuse valid evidence for unchanged code and artifacts
when only documentation or records change. The repository-only audit is:

```sh
Rscript --vanilla development/audit-public-api.R .
```

It compares `NAMESPACE`, installed-help aliases, value/example sections, this
inventory, and pkgdown topics; requires every registered S3 method to be
discoverable by help; rejects retired public names; and enforces the decision
not to register information-discarding `summary()` or `as.data.frame()` methods
for composite table objects.

## 2026-10-14 API consolidation review

Scope: inspect the 57-export inventory and installed signatures, all 11 registered
plot methods and 23 print methods, and the connected implementations of adjacent
families below. This is an interface-design review, not a new feature, a full
numerical revalidation or a human usability study. No runtime, schema, help,
resource, dependency or export changed. Candidate calls below are **not yet
supported** unless explicitly described as existing.

### How to decide what belongs together

1. Start with the user's operation. Rendering an existing result, computing a
   result, importing data and evaluating against a reference are different tasks.
   Similar prefixes alone are insufficient grounds for a merge.
2. Use an argument for a choice within the task: selected metric, weighting,
   component, presentation or an explicit calculation plan. Use typed dispatch
   when an existing class identifies the relevant implementation. R's
   [S3 dispatch](https://stat.ethz.ch/R-manual/R-devel/library/base/html/UseMethod.html)
   is ordinarily based on the first argument; a two-input comparison must still
   validate the second input and the relationship between them.
3. Different validators or supplementary output tables do not rule out a shared
   generic. Specify the common result meaning, per-method additions and where
   the complete record remains available. A selected plotting/summary view need
   not reproduce every table; it must not silently replace the saved full result.
4. Count required concepts, mode strings and invalid argument combinations as
   well as function names. Reject conflicting settings early. Never silently
   ignore tokenizer settings on prepared inputs or metric settings already
   fixed in a plan. Preserve current named as well as positional calls.
5. Preserve cost and failure boundaries. Plotting saved data must not recalculate
   metrics or fetch resources. Batch calls must retain all document IDs, including
   empty documents, and shared-resource validation and global row limits.
6. Preserve the statistical target: units, denominators, common-item sets,
   missingness and reference scope. Common output columns do not make distinct
   estimands interchangeable. Do not pool unlike measures or treat missing as zero.
7. Evaluate compatibility, not just the proposed clean syntax. Old names may
   temporarily delegate during migration; adding a new generic plus permanent
   synonymous wrappers alone enlarges the surface. Existing RDS classes,
   extraction paths, examples, registration and documentation are part of the
   migration. The published interface is not disposable because it is pre-CRAN.

### Families and candidate decisions

| Family | Existing implementation and judgement | Boundary for a useful consolidation |
| --- | --- | --- |
| Plot and print | Already consolidated through `plot()` and `print()`: 11 and 23 registered methods, no separately exported `plot_*` functions. Four metric/profile plot registrations share one function; both text-result wrappers delegate to `$results`. Preserve this model. | The common entry point does not require a single large function with every argument. Keep specialized methods and shared drawing helpers. `metric_id`, `request_id`, `weighting`, `scale`, `show_cumulative` and `monochrome` already express choices. |
| Additional plot views | A promising extension is a selected trajectory/exposure view on an existing MATTR result; selected quantities for norm/resource results or an explicit document for a batch can be assessed similarly. | A proposed `view` selects stored data; existing graphics `type` still selects points/lines. Define one measure, specification, weighting and document scope; return exactly the displayed data invisibly. Norms and batch results may need new S3 methods/classes, not new `plot_*` exports. No automatic difference plot, missing-to-zero conversion or cross-construct pooling. |
| Method catalogs | Prefer assessing `lexdiv_methods(scope = "variants")` over adding the proposed `lexdiv_variant_methods()` name. Both current functions list supported methods with interpretation metadata. | Current catalogs have different columns and one shared ID. Define common fields, source/accepted execution entry points and treatment of duplicates; do not just concatenate rows. Listing a variant must not imply it is accepted by core plans. Preserve existing no-argument output and the legacy variant catalog during migration. |
| Core metrics and method plans | Prefer assessing `lexdiv_metrics(tokens, plan = plan)` over standalone `lexdiv_run_plan()`. `lexdiv_profile()` already calls the core calculator and adds a plan envelope; its result inherits `lexdiv_results`. The batch relation is analogous. | Reject simultaneous explicit plan and competing metric/parameter requests, rather than choosing one silently. Keep request/specification IDs and plan fingerprints and preserve the full profile result class/fields when a plan is supplied. No-plan calls keep their existing contract. |
| Resource diagnostics and token screens | NJ8 and TUBELEX diagnostics answer the common task of inspecting an existing result without recalculation. A future typed `lexdiv_diagnostics(x, ...)` is a plausible shared entry point; token-floor screening could be a result-specific method if the meaning is clearly documented. | Single NJ8/TUBELEX objects have distinguishable classes. TUBELEX batches are plain lists, including an empty batch; a broad `list` method cannot safely infer their role. Plan class/adapter compatibility and retain resource-specific tables, IDs, coverage and row limits. Length screens remain advisory and must not filter metric rows or imply validity. |
| Single-document and batch pairs | Seven explicit pairs exist across metrics, text metrics, tokenization, plans, norms, NJ8 and TUBELEX. A common entry point is technically possible with explicit input roles or typed document collections; keep it as a bounded design candidate. | Raw text and tokens can both be character data; raw and token tables are both data frames. Several batches are plain lists. Do not infer role from length, names or available columns alone. Preserve ID validation, empty-document and zero-document behavior, return shapes, metadata and one-reference-load optimization. A single-document call cannot silently become a one-row batch. |
| Term and content overlap | Both share `.lexoverlap_term_overlap_impl()`. A future shared overlap operation could select `word_inclusion`/`unit` explicitly for annotated inputs. This is more coherent than a generic combining every kind of comparison. | Validate both inputs, source comparability and required annotation layers. Keep exclusion/coverage tables and existing default units. Dispatch must not make content-word filtering an unnoticed consequence of input class. A compatibility extension of an existing entry point should be considered before another export. |
| Reference coverage versus overlap | Keep the different operations recognizable even though they share matching concepts. Reference coverage reports token and type denominators for multiple documents; pair overlap measures distinct term sets. | For tokens `a,a,b` and reference `a`, token coverage is 2/3 and type coverage is 1/2. A directional type-overlap score of 1/2 cannot replace both. Shared low-level counting is possible; an interchangeable top-level alias is not. |
| NJ8, TUBELEX and generic norm profiles | A common resource-profile operation is not categorically impossible. It would need explicit resource kinds/adapters and a documented common result envelope, with resource-specific tables preserved. Lower priority than catalogs or metric plans. | Current resource identity, normalization, completeness, rank levels, frequencies and norm scales differ. Do not force them into one interchangeable score or infer a resource kind from a data-frame shape. Additional adapter constructors may offset any reduction in names. |
| N-gram reference constructor and builder | Keep building from chunks separate from validating/constructing an in-memory reference. The builder already finishes through `lexdiv_ngram_reference()`. | The builder invokes a caller callback, checks unique documents across chunks, enforces `max_types` and returns source/document manifests beside `$reference`. Putting it behind a `build = TRUE` flag would hide material cost and error boundaries. Sharing the final constructor already avoids duplicated numerical validation. |
| N-gram profile and reference comparison | Keep a distinction between applying one reference and comparing several references. The comparison already calls `lexdiv_ngram_profile()` for each reference. | Comparison additionally defines the intersection of available target items across all references and a baseline. A multi-reference mode is possible only if this changed estimand and its returned tables remain explicit; it is not ordinary batch processing. |
| Annotation compare, evaluate and align | Retain the visible distinctions: before/after label changes, reference-based evaluation on identical tokens, and correspondence between different segmentations. The evaluator and aligner already share `.lexann_score()`. | Alignment's optional label evaluation is conditional on exact spans, unlike evaluation on the supplied common tokenization. A universal mode must not silently substitute one population for the other. Common internals and consistent selected plots are preferable to collapsing the tasks now. |
| Ambiguity, contextual and response comparisons | Candidate review/agreement, imported model scores, training-based scoring, reference evaluation and paired binary response summaries represent distinct stages or evidence. No universal `compare()`/`evaluate()` switch is recommended at present. | Their imports are often ordinary lists rather than distinct S3 classes; the reference alone does not identify the intended analysis. Keep human decisions, model scores, training/reference roles and missingness separate. A shared verb without a shared user operation does not reduce learning. |
| Tokenization, lemma/flemma and family analysis | Existing tokenizer and lemmatizer arguments already select implementations where the operation is shared. Retain explicit stages and lexical-unit choices. | Flemma mapping and family membership change the unit and ambiguity/fallback rules. An option that computes all representations eagerly would add resource work and hide unresolved choices. Do not fold annotation import, external models and scoring into a single implicit preprocessing call. |
| Resource readers and adapters | MorphoLex/Nation data access, local MorphyNet parsing, MASC reading, annotation import, document adaptation and quanteda adaptation have different source/target roles. Group them in help by input task; no universal reader/converter is required by this review. | Preserve local-file versus bundled-data behavior, optional dependencies, declared versions, coordinates and provenance. A `format`/`to` argument is reasonable only when it simplifies actual call sequences; it must not infer licenses or download sources. |
| Specifications, grids and plans | Keep their roles visible: one method request, expansion over parameter settings, and a normalized plan. Share constructors internally where appropriate. | Some parameters are themselves vectors, such as expected-TTR sample sizes. Automatically treating every vector as a grid would change meaning. Removing constructor names must not erase the distinction between a parameter vector and multiple requests. |
| Widening, summaries and extraction | `lexdiv_widen()` already chooses fields and optional MTLD diagnostics by arguments. An explicit selected summary/coercion view is not inherently unsafe merely because the full result has several tables; assess its actual benefit over `$summary`/`$lookup` and widening. | Preserve denominators, IDs and original objects; never silently pick the first table. Current `audit-public-api.R` rejects all summary/as.data.frame registrations, including explicit ones. Any adopted exception requires a coordinated policy/audit/help/test change; this review leaves that guard intact. |

### Focused executable evidence

The verified installed 9006 archive was used with small authored inputs; no full
suite or resource build was repeated. Inspection of its exports and signatures
confirms the same 57 exports, 11 plot registrations and 23 print registrations.

- The method catalog has 12 rows and 10 columns; the variant catalog has eight
  rows and six columns. `maas_a2_ln_v1` appears in both. A common catalog needs
  explicit schema and execution-scope decisions before implementation.
- The same character value `"Cats chase cats."` is one supplied token under the
  core API (N=1, V=1, TTR=1, with the likely-raw-text warning), and three words
  under explicit English tokenization and lowercasing (N=3, V=2, TTR=2/3).
  The core returns a data frame; text analysis returns results, token audit and
  preprocessing. This demonstrates an input ambiguity, not equivalent analyses.
- Tokenization batches and TUBELEX batches are ordinary named lists. NJ8's
  single and batch classes are distinct. Executed NJ8/TUBELEX diagnostics also
  confirm their different supplementary tables; shared dispatch cannot be
  inferred from the word "profile" or the presence of `$summary` alone.
- A TTR-only plan and the direct core call on `a,a,b` agree in N, V and value.
  The plan adds seven envelope columns and inherits
  `lexdiv_profile_results/lexdiv_results/data.frame`. This supports assessing
  an explicit plan branch without discarding plan metadata.
- Executed reference coverage and term overlap confirm the 2/3 versus 1/2
  denominator example. Color and monochrome `plot()` calls on a text result
  return identical selected data invisibly. Existing plot-style tests cover
  all eleven registered result forms; those unchanged tests were not rerun.

### Order of the next design decisions

First assess the catalog scope and explicit metric-plan option using concrete
old/new calls, invalid combinations and result examples. These alternatives
take priority over the earlier standalone rename candidates; neither is adopted
by this review. For visualization, evaluate an actual requested second view
through `plot()` before introducing a plotting function. Next consider typed
diagnostics if it removes repeated resource-specific decisions. Treat wholesale
single/batch/input unification as a larger migration, not a prerequisite for
using or improving the current package.

Adoption requires targeted evidence for named/positional compatibility, selected
data and invisible returns, conflicting/irrelevant arguments, unknown or mixed
classes, empty/short/all-missing cases, IDs/metadata, saved-object replay and
resource reuse. Reconcile NAMESPACE, S3 registrations, installed help, examples,
NEWS, the API audit and site only for the actually adopted change. Do not rerun
unchanged numerical validation just to publish this internal assessment.

### 9007 adopted entry points

The subsequent continuation adopts only catalog scope and explicit plan execution.
`lexdiv_methods()` retains its complete 12-row, 10-column default output.
`scope = "variants"` returns the unchanged eight-row, six-column variant catalog.
The common fields are `method_id`, `direction` and `scale`; the shared Maas ID
occurs once per selected catalog. There is no combined table, deduplication,
new executor membership or new export. Help names the accepted executor for
each scope; the legacy catalog entry point remains supported.

`lexdiv_metrics(..., plan = plan)` and `lexdiv_metrics_batch(..., plan = plan)`
delegate to the existing profile executors. They retain all classes, attributes,
request/specification identities, hashes, missingness and batch ordering.
Explicit metric arguments conflict with a non-NULL plan even at default values.
The batch `plan` and `max_rows` formals follow `...`, preserving prior positional
metric forwarding. `max_rows` is accepted only with a plan and preserves the
existing pre-allocation bound. `NULL` retains ordinary metric behavior.

The original profile functions and old objects remain supported. Raw-text
functions, diagnostics, plotting and wholesale single/batch unification are
outside this implementation. 57 exports, 34 S3 registrations and 37 help topics
remain. Validation and publication evidence belongs to the existing publication
record; the executable tests cover output identity and failure boundaries,
not a claim of measured novice usability.
