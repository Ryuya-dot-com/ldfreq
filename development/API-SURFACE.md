# Public API surface

Current API inventory for **ldfreq 1.0.0**. Names, help and navigation are checked by
`Rscript development/audit-public-api.R .`. Scientific definitions are in the
installed method contracts; return columns and examples are in each help topic.

## Naming and unified entry points in 1.0.0

- Action-first names are the sole public entry points: `lexdiv_compare_ngrams()`,
  `lexdiv_build_ngram_reference()`, `lexdiv_sort_concordance()`, and
  `lexdiv_screen_lengths()`. All pre-1.0 legacy compatibility aliases are retired.
- `lexdiv_metrics(..., plan = plan)`, `lexdiv_metrics_batch(..., plan = plan)`,
  `lexdiv_metrics_text(..., plan = plan)`, and
  `lexdiv_metrics_text_batch(..., plan = plan)` are the unified calculation
  entry points. `lexdiv_methods(scope = "variants")` is the sole variant catalog.
- Raw-text functions (`lexdiv_tokenize*`, `lexdiv_metrics_text*`, and
  `lexdiv_as_annotations()`) default to `case = "lower", tokenizer = "english"`
  while recording exact preprocessing provenance.
- `lexdiv_as_annotations()` bridges raw texts or tokenizations directly into
  `lexdiv_concordance()`, `lexdiv_collocations()`, `lexdiv_keyness()`,
  `lexdiv_ambiguity_review()`, and `lexdiv_family_profile()`.
- `tibble` / `data.table` data frames and named 1D character vectors are
  transparently accepted across data-frame and term-vector inputs.

## Export inventory

| `bnccoca_data()` | Cached Nation BNC/COCA Level 6 membership; no inferred members | Reference resource, not document data | Base list | No | `$dictionary`, `$supplementary`, `$catalog`, `$resource`, `$provenance` |
| `lexdiv_align_annotations()` | Source-interval correspondence across different token segmentations; optional label evaluation on exact spans | Same source segment roster; preserves empty documents and both token indices | Classed `lexdiv_annotation_alignment` | No | `$summary`, `$documents`, `$groups`, `$members`, `$boundaries`, `$review_queue`, `$provenance` |
| `lexdiv_ambiguity_review()` | Source-verified KWIC and explicit lexical-candidate decisions | Complete imported annotations; O(1) integrity check | Classed `lexdiv_ambiguity_review` | No | `$occurrences`, `$candidates`, `$decisions`, `$summary`, `$source`, `$provenance` |
| `lexdiv_amod_pairs()` | Basic-UD ADJ-amod-NOUN extraction from source-checked annotations | Explicit document/sentence IDs; observed counts beside complete totals | Classed `lexdiv_amod_pairs` | No | `$occurrences`, `$counts`, `$segments`, `$documents`, `$summary`, `$annotations`, `$provenance` |
| `lexdiv_as_annotations()` | Bridges raw texts or `lexdiv_tokenization` objects into source-aligned `lexdiv_annotations` | Complete non-whitespace coverage with `is_word` and normalized `term` | Classed `lexdiv_annotations` | No | `$tokens`, `$segments`, `$documents`, `$provenance`, `$integrity_sha256` |
| `lexdiv_as_documents()` | Adapts named/tidy/tibble/quanteda tokens to a plain named list (`id_col`, `token_col`) | Creates the batch boundary | Base | No | Plain named list |
| `lexdiv_as_quanteda()` | Explicit token/segment tables to quanteda without closing gaps or retokenizing | Each segment maps to its original document | Base list | Through quanteda | `$tokens`, `$positions`, `$segments`, `$provenance` |
| `lexdiv_build_ngram_reference()` | Sequential accumulation of whole-document extractions into exact reference counts | Unique document IDs across chunks; ergonomic `resource` default | Classed `lexdiv_ngram_build` | No | `$reference`, `$sources`, `$documents`, `$provenance` |
| `lexdiv_collocations()` | Ordered eligible slot-pair opportunities, MI and t-score | Single-query default `query_id`; per-document audit beside pooled counts | Classed `lexdiv_collocations` | No | `$results`, `$pairs`, `$documents`, `$search`, `$settings`, `$provenance` |
| `lexdiv_compare_ambiguity()` | Descriptive agreement and unresolved decisions paired by occurrence ID | Two complete reviews of the same source and candidate snapshot | Classed `lexdiv_ambiguity_comparison` | No | `$summary`, `$terms`, `$pairs`, `$review_queue`, `$status_pairs`, `$reviews` |
| `lexdiv_compare_annotations()` | Validates identical source/tokenization before auditing changed lemma/UPOS/flemma labels | Single pair or named batches paired by ID | Classed `lexdiv_annotation_comparison` | No | `$documents`, `$changes`, before/after `$provenance` |
| `lexdiv_compare_ngrams()` | Reference choice, common-item means and baseline differences beside per-reference coverage | One target, named references; common set across all references | Classed `lexdiv_ngram_comparison` | No | `$summary`, `$lookup`, `$documents`, `$references`, `$provenance` |
| `lexdiv_compare_responses()` | Validates scored binary response pairs and composite IDs; preserves missingness | Explicit categorical strata | Classed `lexdiv_response_comparison` | No | `$responses`, `$counts`, `$summary`, `$provenance` |
| `lexdiv_concordance()` | Complete source-aligned token-pattern search | Declared source document roster including zero-match documents | Classed `lexdiv_concordance` | Base-R `plot()` draws positional barcode | `$occurrences`, `$counts`, `$documents`, `$source`, `$settings`, `$provenance` |
| `lexdiv_concordance_dispersion()` | Unnormalised single-token within-document DP and per-part exposure | Single-query default `query_id`; document rows | Classed `lexdiv_dispersion` | Position view belongs to `plot(concordance)` | `$documents`, `$parts`, `$occurrence_ids`, `$settings`, `$search_id` |
| `lexdiv_content_overlap()` | Annotated content-word overlap composite | Pair operation; no batch inference | Classed `lexdiv_overlap` | No | `$summary`, `$coverage`, term and exclusion tables |
| `lexdiv_download_resources()` | Explicit verified resource download | Requires license acknowledgement | Base | No | Invisible data frame |
| `lexdiv_evaluate_annotations()` | Single-label evaluation against an explicit reference on the same source segmentation | Per-document coverage and all-occurrence pairing | Classed `lexdiv_annotation_evaluation` | No | `$summary`, `$labels`, `$documents`, `$pairs`, `$confusion`, `$review_queue`, `$provenance` |
| `lexdiv_evaluate_contextual()` | Complete-inventory ranking and descriptive comparison to a reference review | Overall and per-target counts, coverage, and confusion | Classed `lexdiv_contextual_evaluation` | No | `$summary`, `$terms`, `$pairs`, `$confusion`, `$review_queue`, `$provenance` |
| `lexdiv_family_profile()` | Exact form/POS lookup against a caller-defined family table with optional review | Complete imported annotations with document IDs | Classed `lexdiv_family_profile` | No | `$occurrences`, `$candidates`, `$members`, `$documents`, `$summary`, `$provenance` |
| `lexdiv_flemmatize()` | Adds explicit flemma layer to `lexdiv_tokenization` | Single tokenization | Classed `lexdiv_tokenization` | No | `$tokens`, `$provenance` |
| `lexdiv_flemmatize_batch()` | Adds explicit flemma layer across a named batch of tokenizations with one parsed AntBNC list | Batch counterpart to `lexdiv_flemmatize()` | Named list | No | Named list of `lexdiv_tokenization` objects |
| `lexdiv_grid()` | Bounded ordered list of method specifications | Accepts `method_id` or `metric_id` shorthand | Classed `lexdiv_grid` | No | List of `lexdiv_spec` objects |
| `lexdiv_import_annotations()` | Exact alignment of complete external surfaces to original text with O(1) integrity hash | Accepts `data.frame` or `tibble` | Classed `lexdiv_annotations` | No | `$tokens`, `$segments`, `$documents`, `$provenance`, `$integrity_sha256` |
| `lexdiv_import_contextual()` | Source-checked external embeddings/scores, distinct from human decisions | Complete review with ID-paired output | Classed `lexdiv_contextual` | No | `$occurrences`, `$embeddings`, `$suggestions`, `$summary`, `$review`, `$provenance` |
| `lexdiv_keyness()` | Disjoint target/reference counts, G-squared and unsmoothed log-ratio | Default `preprocessing_id = "default"`; pooled totals with document counts | Classed `lexdiv_keyness` | No | `$results`, `$totals`, `$documents`, `$document_counts`, `$occurrences`, `$token_audit` |
| `lexdiv_keyness_concordance()` | Exact counted-term return to original contexts | Same retained source; no new comparison | Classed `lexdiv_keyness_concordance` | `plot($search)` | `$comparison_id`, `$term`, classed `$search` |
| `lexdiv_lemmatize()` | Adds explicit lemma/UPOS layers and dictionary fingerprints to `lexdiv_tokenization` | Single tokenization | Classed `lexdiv_tokenization` | No | `$tokens`, `$provenance` |
| `lexdiv_lemmatize_batch()` | Adds explicit lemma/UPOS layers across a named batch of tokenizations | Batch counterpart to `lexdiv_lemmatize()` | Named list | No | Named list of `lexdiv_tokenization` objects |
| `lexdiv_length_evidence()` | Evidence registry data frame | Not document data | Base data frame | No | Data frame |
| `lexdiv_mattr_profile()` | Canonical MATTR summary plus local-window and positional-exposure tables | Document-scoped; accepts a MATTR-only canonical plan | Classed `lexdiv_mattr_profile` | `plot()` draws local curve | `$summary`, `$windows`, `$exposure`, `$diagnostics` |
| `lexdiv_methods()` | Core or variant method catalog selected by `scope` | Shared discovery (`"core"` or `"variants"`) | Base data frame | No | Core parameters or variant metadata |
| `lexdiv_metric_ids()` | Core metric ID character vector | Catalog used by core calls | Base | No | Character vector |
| `lexdiv_metrics()` | Single-document metric rows, or full request profiles when `plan` is supplied | Paired with `lexdiv_metrics_batch()` | `lexdiv_results` / `lexdiv_profile_results` | Single selected metric/request | Data frame |
| `lexdiv_metrics_batch()` | Multi-document metric or plan result data frame | Accepts named list, `data.frame`, or `tibble` | `lexdiv_batch_results` / `lexdiv_profile_batch_results` | Single selected metric/request | Data frame |
| `lexdiv_metrics_text()` | Raw/prepared single-text metrics (or `plan` profile) plus token audit and provenance | Defaults to `case = "lower", tokenizer = "english"` | Classed `lexdiv_text_results` | Delegates to `$results` | `$results`, `$token_audit`, `$preprocessing` |
| `lexdiv_metrics_text_batch()` | Raw/prepared multi-document metrics (or `plan` profile) with audits and provenance | Defaults to `case = "lower", tokenizer = "english"`; feeds `lexdiv_study_table()` and `lexdiv_widen()` directly | Classed `lexdiv_text_batch_results` | Delegates to `$results` | `$results`, `$token_audit`, `$preprocessing` |
| `lexdiv_ngram_profile()` | Exact sequence lookup and available-value means | Per-document, per-n token/type summaries | Classed `lexdiv_ngram_profile` | No | `$summary`, `$lookup`, `$documents`, `$provenance` |
| `lexdiv_ngram_reference()` | Validated extraction or caller aggregate with completeness and opportunity totals | Reusable across targets | Classed `lexdiv_ngram_reference` | No | `$counts`, `$totals`, `$provenance` |
| `lexdiv_ngrams()` | Adjacent bigram/trigram extraction within explicit segments and consecutive positions | Accepts `data.frame` or `tibble` | Classed `lexdiv_ngrams` | No | `$occurrences`, `$counts`, `$document_counts`, `$documents`, `$totals`, `$provenance` |
| `lexdiv_norm_profile()` | Conditional lexical-norm means plus exact lookup and coverage | Ergonomic defaults via `lexdiv_norm_spec()` and `lexdiv_resource_meta()` | Classed `lexdiv_norm_profile` | No | `$summary`, `$lookup`, `$coverage`, `$provenance`, `$diagnostics` |
| `lexdiv_norm_profile_batch()` | Shared caller-supplied norm table applied across documents | Ergonomic defaults via `lexdiv_norm_spec()` and `lexdiv_resource_meta()` | Classed `lexdiv_norm_profile_batch` | No | `$summary`, `$lookup`, `$coverage`, `$provenance`, `$diagnostics` |
| `lexdiv_norm_spec()` | Concise constructor for 11-column lexical-norm `measure_specs` tables | Fills canonical sensible defaults in any column order | Base data frame | No | 11-column `measure_specs` data frame |
| `lexdiv_overlap_ids()` | Overlap measure ID character vector | Shared by pair overlap operations | Base | No | Character vector |
| `lexdiv_plan()` | Deduplicated bounded request plan | Shared by `lexdiv_metrics*` and `lexdiv_metrics_text*` | Classed `lexdiv_plan` | No | `$specifications` and plan identity fields |
| `lexdiv_presets()` | Preset registry data frame | Shared by `lexdiv_plan()` | Base data frame | No | Data frame |
| `lexdiv_read_masc()` | GrAF 1.0 Penn reader preserving supplied tokens, regions, text and hashes | Concise `print` hides full raw document text | Classed `lexdiv_masc` | No | `$tokens`, `$segments`, `$documents`, `$provenance` |
| `lexdiv_reference_coverage()` | Token/type coverage of many documents by one exact reference set | Many-to-one batch operation | Classed `lexdiv_reference_coverage` | One explicit weighting | `$summary`, `$documents`, `$reference`, optional `$terms` |
| `lexdiv_resource_info()` | Inspect optional resources and license terms | No network access | Base data frame | No | Data frame |
| `lexdiv_resource_meta()` | Concise constructor for 8-field caller lexical-resource metadata lists | Fills sensible defaults in canonical field order | Base list | No | 8-element `resource` metadata list |
| `lexdiv_score_contextual()` | Supervised centroid-cosine and training-frequency baselines over imported reviews | Same inventory, disjoint documents | Classed `lexdiv_contextual_scores` | No | `$centroid`, `$frequency`, `$candidates`, `$prototypes`, `$provenance` |
| `lexdiv_screen_lengths()` | Independent token-floor screen data frame | Accepts plan-based `lexdiv_metrics*` or `lexdiv_metrics_text*` results directly | Classed `lexdiv_screen_results` | One selected screen | Data frame |
| `lexdiv_sort_concordance()` | Sort saved concordance context nearest-token-first with `case_insensitive` flag | Same search and occurrence IDs | Base data frame | No | Ordered occurrence table |
| `lexdiv_spec()` | One normalized method/parameter request | Accepts `method_id` or `metric_id` shorthand (e.g. `"mtld"`) | Classed `lexdiv_spec` | No | Named list fields |
| `lexdiv_study_model_data()` | Explicit single-condition/request selection with metadata and exclusion audit | One row per observation and unique document | Classed `lexdiv_study_model_data` | No | `$data`, `$audit` |
| `lexdiv_study_table()` | Planned observations joined to plan results (including `lexdiv_text_batch_results` directly) | Accepts `data.frame` or `tibble`; auto-populates character counts from text batch | Base data frame | No | Complete ordinary table |
| `lexdiv_term_overlap()` | Exact term-set overlap composite | Pair operation; accepts named character vectors | Classed `lexdiv_overlap` | No | `$summary`, `$counts`, optional term tables |
| `lexdiv_tokenize()` | Lossless token rows and preprocessing provenance | Defaults to `case = "lower", tokenizer = "english"` | Classed `lexdiv_tokenization` | No | `$tokens`, `$provenance` |
| `lexdiv_tokenize_batch()` | Named raw-text vector or ID/text table to complete tokenizations | Defaults to `case = "lower", tokenizer = "english"` | Named list | No | Named list of `lexdiv_tokenization` objects |
| `lexdiv_variant_metrics()` | Cross-definition result data frame | Uses `lexdiv_methods(scope = "variants")` catalog | Classed `lexdiv_variant_results` | No | Data frame |
| `lexdiv_widen()` | Pure long-to-wide transformation | Directly unwraps `lexdiv_text_results` and `lexdiv_text_batch_results` | Classed `lexdiv_wide_results` | No | Data frame |
| `morpholex_data()` | Cached MorphoLex-en worksheet values and provenance | Reference resource | Base list | No | `$sheets`, `$provenance` |
| `morphynet_read_derivations()` | Local six-field derivational TSV reader | Reference resource | Base list | No | `$relations`, `$resource`, `$provenance` |
| `nj8_diagnostics()` | Counts unmatched terms and lexical-unit mappings for NJ8 profiles | Single or batch NJ8 profile | Classed `nj8_diagnostics` | No | `$unmatched_terms`, `$unit_mappings`, `$coverage`, `$exclusion_reasons` |
| `nj8_profile()` | NJ8 level summary, lookup, coverage, provenance, diagnostics | Paired with `nj8_profile_batch()` | Classed `nj8_profile` | One weighting and scale | Named component tables |
| `nj8_profile_batch()` | Document-major NJ8 level-profile composite | Accepts named list, `data.frame`, or `tibble` | Classed `nj8_profile_batch` | No | Named component tables with `document_id` |
| `tubelex_diagnostics()` | Reusable frequency tables, coverage, unmatched counts and query mappings | Accepts `tubelex_profile`, `tubelex_profile_batch`, or named list | Classed `tubelex_diagnostics` | No | `$summary`, `$documents`, `$unmatched_terms`, `$normalization_mappings` |
| `tubelex_profile()` | TUBELEX frequency/prevalence summary, lookup, coverage, provenance | Paired with `tubelex_profile_batch()` | Classed `tubelex_profile` | Token/type coverage | Named component tables |
| `tubelex_profile_batch()` | Structured document-major TUBELEX batch composite with retained `$profiles` | One verified resource load per batch call | Classed `tubelex_profile_batch` | Per-document coverage bars | `$summary`, `$lookup`, `$coverage`, `$profiles`, `$provenance`, `$diagnostics` |
