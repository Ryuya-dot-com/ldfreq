# Public API surface

Current API inventory for 0.5.0.9001. Names, help and navigation are checked by
`Rscript development/audit-public-api.R .`. Scientific definitions are in the
installed method contracts; return columns and examples are in each help topic.

## Naming and compatibility

Use action-first names for compare, build, sort and screen operations.
`lexdiv_metrics(..., plan = plan)` is the common calculation entry point;
`lexdiv_profile()` retains compatibility. `lexdiv_methods(scope = "variants")`
is the variant catalog; the legacy `lexdiv_variant_ids()` data-frame return is
unchanged. `_ids` names otherwise return character identifiers. `_text` marks
raw input and `_batch` marks identified multi-document input. Resource-branded
readers/profiles retain their resource prefix. No implicit token/text guessing.

## Export inventory

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
| `morpholex_data()` | Cached MorphoLex-en worksheet values and provenance; all sheets or an explicit ordered subset | Reference resource, not document data | Base list | No | `$sheets` (character-valued original data frames), `$provenance` including source identity, license and complete sheet catalog |
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
| `lexdiv_resource_info()` | Inspect optional resources and terms | data.frame | No download |
| `lexdiv_download_resources()` | Explicit verified resource download | invisible data.frame | Requires license acknowledgement |
| `lexdiv_compare_ngrams()` | Canonical name for `lexdiv_ngram_compare()` | Same signature and result | Compatibility alias retained |
| `lexdiv_build_ngram_reference()` | Canonical name for `lexdiv_ngram_reference_build()` | Same signature and result | Compatibility alias retained |
| `lexdiv_screen_lengths()` | Canonical name for `lexdiv_screen()` | Same signature and result | Compatibility alias retained |
| `lexdiv_sort_concordance()` | Canonical name for `lexdiv_concordance_sort()` | Same signature and result | Compatibility alias retained |
