# API and measurement lifecycle

## Current distribution

The current stable release is **1.0.0**. It provides a streamlined, cohesive
public API with unified entry points, modern R container compatibility
(`tibble` / `data.table` and named vectors), ergonomic metadata helpers, direct
raw-text-to-corpus bridges, and structured S3 results across all workflows.
Earlier pre-1.0 archives remain available in the release history for exact
reproduction of 0.x scripts. Pin the package archive used in an analysis and
use `citation("ldfreq")` to cite that exact version.

## Reference data

Third-party reference data are optional downloads with their own licenses.
Use `lexdiv_resource_info()` to inspect the terms, source, version and hash,
then explicitly use `lexdiv_download_resources(..., accept_license = TRUE)`.
Ordinary computation and installation never download resources.

## Metric identities and contracts in 1.0.0

Package version, metric method ID, metric-contract version, result schema,
preprocessing contract, and reference-resource identity remain explicit:

- Core lexical-diversity formulas (`ldfreq-lexical-diversity-core` 0.2.0) are
  unchanged: eleven default metrics, opt-in `mtld_ma`, and experimental
  `expected_ttr_d`.
- Preprocessing contract **1.0.0** sets practical defaults for raw English text
  (`case = "lower"`, `tokenizer = "english"`, `normalization = "NFC"`,
  `keep_numbers = FALSE`) while recording every choice in provenance and
  continuing to validate saved 0.2.0–0.4.0 tokenization objects.
- Generic norm profile contract **0.2.0** adds `lexdiv_norm_spec()` and
  `lexdiv_resource_meta()` constructors with ergonomic defaults.
- TUBELEX profile contract **0.3.0** upgrades `tubelex_profile_batch()` to a
  structured S3 batch object (`$summary`, `$lookup`, `$coverage`, `$profiles`)
  matching `nj8_profile_batch()` and `lexdiv_norm_profile_batch()`.

## Major API design in 1.0.0

- **Single canonical entry points**: Duplicate functions and pre-1.0 aliases
  are removed. Pass `plan = plan` directly to `lexdiv_metrics()`,
  `lexdiv_metrics_batch()`, `lexdiv_metrics_text()`, or
  `lexdiv_metrics_text_batch()`, and query variant definitions via
  `lexdiv_methods(scope = "variants")`.
- **Connected workflows**:
  - `lexdiv_as_annotations()` converts raw texts or `lexdiv_tokenization`
    objects directly into sealed `lexdiv_annotations` objects for
    `lexdiv_concordance()`, `lexdiv_collocations()`, `lexdiv_keyness()`, and
    `lexdiv_family_profile()`.
  - `lexdiv_lemmatize_batch()` and `lexdiv_flemmatize_batch()` annotate entire
    batches produced by `lexdiv_tokenize_batch()`.
  - `lexdiv_widen()`, `lexdiv_screen_lengths()`, and `lexdiv_study_table()`
    directly accept `lexdiv_text_results` / `lexdiv_text_batch_results`.
- **Consistent S3 classes and bounded printing**: Every analysis result carries
  an explicit S3 class with a concise `print()` method capped at 12 rows, and
  `plot.lexdiv_concordance()` uses zero-dependency Base R graphics.
