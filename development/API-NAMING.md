# API naming conventions (2.0.0 development)

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
- `_text` means raw text (`lexdiv_metrics_text()`). Single-document and
  multi-document inputs share a single polymorphic entry point without `_batch`
  duplicate exports (`lexdiv_tokenize()`, `lexdiv_lemmatize()`,
  `lexdiv_flemmatize()`, `lexdiv_metrics()`, `lexdiv_metrics_text()`,
  `nj8_profile()`, `tubelex_profile()`, `lexdiv_norm_profile()`).
- `_ids` returns character identifiers (`lexdiv_metric_ids()`,
  `lexdiv_overlap_ids()`). Multi-column catalog tables use `methods`, `presets`,
  or `resource_info`.
- Parameter names are unified across functions:
  - Document ID column selector: always `id_col = "document_id"`.
  - Token/term column selector: always `term_col` (with domain default `"tokens"`, `"terms"`, `"token"`, or `"term"`).
  - Optional resource cache directory override: always `cache_dir = NULL`.
  - Case-insensitive matching/sorting flag: always `case_insensitive = FALSE`.
  - Raw-text preprocessing defaults: `normalization = "NFC"`,
    `case = "lower"`, `keep_numbers = FALSE`, `tokenizer = "english"`.

## Unified entry points in 2.0.0-dev

Version 2.0.0-dev retires the 8 duplicate `*_batch` exports in favor of polymorphic single/multi-document entry points (67 exports total):

| Canonical 2.0.0-dev API | Retired 1.0.x duplicate |
|---|---|
| `lexdiv_tokenize(x, ...)` | `lexdiv_tokenize_batch()` |
| `lexdiv_lemmatize(x, ...)` | `lexdiv_lemmatize_batch()` |
| `lexdiv_flemmatize(x, ...)` | `lexdiv_flemmatize_batch()` |
| `lexdiv_metrics(x, ...)` | `lexdiv_metrics_batch()` |
| `lexdiv_metrics_text(x, ...)` | `lexdiv_metrics_text_batch()` |
| `nj8_profile(x, ...)` | `nj8_profile_batch()` |
| `tubelex_profile(x, ...)` | `tubelex_profile_batch()` |
| `lexdiv_norm_profile(x, ...)` | `lexdiv_norm_profile_batch()` |

Note: `nj8_profile_batch`, `tubelex_profile_batch`, and `lexdiv_norm_profile_batch` remain the S3 result classes returned by multi-document calls for downstream `print()` and `plot()` dispatch.

## Plot conventions

All package `plot()` methods use zero-dependency Base R graphics (no `ggplot2`
dependency is required to call `plot()` on any `ldfreq` object, including
`lexdiv_concordance` and `tubelex_profile_batch`):

- Default APA style: no embedded plot titles/subtitles (`main = NULL`), color
  by default (`#0072B2` / `#D55E00`), and `monochrome = TRUE` for black/grey
  print output.
- Graphics `par()` state is restored on exit via `.lex_plot_style()`.
