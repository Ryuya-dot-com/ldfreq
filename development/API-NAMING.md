# API naming conventions (v1.0.0)

General analysis functions use `lexdiv_`. Resource-specific operations use the
resource name (`nj8_`, `tubelex_`, `morpholex_`, `bnccoca_`, `morphynet_`).
This distinction identifies a resource dependency, not a different code license.

- Operations use action before object: `compare_annotations`, `compare_ngrams`,
  `build_ngram_reference`, `sort_concordance`, `screen_lengths`.
- Result constructors, bridges, and summaries use nouns: `metrics`,
  `study_table`, `concordance`, `keyness`, `ngram_profile`,
  `concordance_dispersion`, `norm_spec`, `resource_meta`, `as_annotations`,
  `as_documents`.
- Every `lexdiv_*` export contains at most three semantic words after the
  `lexdiv_` prefix.
- `_text` means raw text; `_batch` means separately identified documents
  (`lexdiv_tokenize_batch`, `lexdiv_lemmatize_batch`, `lexdiv_flemmatize_batch`,
  `lexdiv_metrics_batch`, `lexdiv_metrics_text_batch`, `nj8_profile_batch`,
  `tubelex_profile_batch`, `lexdiv_norm_profile_batch`).
- `_ids` returns character identifiers (`lexdiv_metric_ids`,
  `lexdiv_overlap_ids`). Multi-column catalog tables use `methods`, `presets`,
  or `resource_info`.
- Parameter names are unified across functions:
  - Document ID column selector: always `id_col = "document_id"`.
  - Case-insensitive matching/sorting flag: always `case_insensitive = FALSE`.
  - Raw-text preprocessing defaults: `normalization = "NFC"`,
    `case = "lower"`, `keep_numbers = FALSE`, `tokenizer = "english"`.

## Unified entry points in 1.0.0

Version 1.0.0 removes all duplicate entry points and pre-1.0 legacy aliases:

| Canonical v1.0.0 API | Retired pre-1.0 name |
|---|---|
| `lexdiv_compare_ngrams()` | (retired pre-1.0 alias) |
| `lexdiv_build_ngram_reference()` | (retired pre-1.0 alias) |
| `lexdiv_sort_concordance()` | (retired pre-1.0 alias) |
| `lexdiv_screen_lengths()` | (retired pre-1.0 alias) |
| `lexdiv_methods(scope = "variants")` | (retired data-frame `_ids` export) |
| `lexdiv_metrics(tokens, plan = plan)` | (retired separate single-doc plan runner) |
| `lexdiv_metrics_batch(docs, plan = plan)` | (retired separate batch plan runner) |

## Plot conventions

All package `plot()` methods use zero-dependency Base R graphics (no `ggplot2`
dependency is required to call `plot()` on any `ldfreq` object, including
`lexdiv_concordance` and `tubelex_profile_batch`):

- Default APA style: no embedded plot titles/subtitles (`main = NULL`), color
  by default (`#0072B2` / `#D55E00`), and `monochrome = TRUE` for black/grey
  print output.
- Graphics `par()` state is restored on exit via `.lex_plot_style()`.
