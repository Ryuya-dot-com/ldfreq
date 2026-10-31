# ldfreq 1.0.0

Initial stable release of **ldfreq** for reproducible lexical-diversity measurement, reference-vocabulary profiling, and source-linked corpus analysis in R.

## Highlights

### Lexical diversity from raw text or pre-tokenized words

- **Core metrics (`lexdiv_metrics()`, `lexdiv_metrics_batch()`)**: Eleven default measures (`ttr`, `rttr`, `cttr`, `herdan`, `maas`, `msttr`, `mattr`, `mtld`, `hdd`, `yule_k`, `yule_i`), plus opt-in moving-average MTLD (`mtld_ma`) and experimental deterministic expected-TTR *D* (`expected_ttr_d`).
- **Auditable raw-text workflows (`lexdiv_metrics_text()`, `lexdiv_metrics_text_batch()`)**: Tokenize and measure English texts directly (defaulting to `tokenizer = "english"` and `case = "lower"`), retaining counted words (`$token_audit`), excluded spans, and exact preprocessing settings.
- **Explicit annotation layers (`lexdiv_tokenize()`, `lexdiv_lemmatize()`, `lexdiv_flemmatize()`, and `_batch()` counterparts)**: Attach lemmas, Universal POS tags, or AntBNC word-family lemmas (`flemma`) for surface, lemma, flemma, or content-word analyses without hidden model downloads.
- **Multi-parameter plans and sensitivity checks (`lexdiv_plan()`, `lexdiv_spec()`, `lexdiv_grid()`, `lexdiv_mattr_profile()`, `lexdiv_variant_metrics()`, `lexdiv_screen_lengths()`)**: Evaluate parameter grids across documents, inspect local moving-window MATTR trajectories, compare Maas and MTLD formula variants (`lexdiv_methods(scope = "variants")`), and check empirical token-count floors without altering calculated scores.

### Vocabulary frequency, level, norm, and morphology profiles

- **Optional, separately licensed reference resources (`lexdiv_resource_info()`, `lexdiv_download_resources()`)**: Review license terms and download SHA-256-verified snapshots on demand for **TUBELEX** (`tubelex_profile()`, `tubelex_profile_batch()`, `tubelex_diagnostics()`), **New JACET 8000** (`nj8_profile()`, `nj8_profile_batch()`, `nj8_diagnostics()`), **MorphoLex-en** (`morpholex_data()`), **Nation's BNC/COCA Level 6 families** (`bnccoca_data()`), and a **MorphyNet** derivational teaching excerpt (`morphynet_read_derivations()`).
- **Custom lexical norms and coverage (`lexdiv_norm_profile()`, `lexdiv_norm_profile_batch()`, `lexdiv_norm_spec()`, `lexdiv_resource_meta()`)**: Profile documents against your own familiarity, AoA, concreteness, or frequency tables while keeping out-of-vocabulary terms and missing norm values distinct.
- **Word-family, overlap, and n-gram profiles (`lexdiv_family_profile()`, `lexdiv_term_overlap()`, `lexdiv_content_overlap()`, `lexdiv_reference_coverage()`, `lexdiv_ngrams()`, `lexdiv_ngram_reference()`, `lexdiv_build_ngram_reference()`, `lexdiv_compare_ngrams()`)**: Measure directional lexical overlap, set coverage, and adjacent bigram/trigram frequencies with exact denominators.

### Source-linked corpus exploration and contextual review

- **Annotation import and 1-line raw-text bridge (`lexdiv_import_annotations()`, `lexdiv_as_annotations()`, `lexdiv_read_masc()`, `lexdiv_as_quanteda()`)**: Verify external morphological annotations (including Japanese `gibasa`/MeCab or Sudachi outputs) against original text, or convert raw texts directly into source-aligned annotation objects.
- **Concordance, dispersion, collocations, and keyness (`lexdiv_concordance()`, `lexdiv_sort_concordance()`, `lexdiv_concordance_dispersion()`, `lexdiv_collocations()`, `lexdiv_keyness()`, `lexdiv_keyness_concordance()`)**: Search words or multi-token phrases with preserved exclusion gaps, compute within-document *DP*, MI, *t*-scores, $G^2$, and log-ratios, and return directly to original contexts.
- **Ambiguity and contextual review (`lexdiv_ambiguity_review()`, `lexdiv_compare_ambiguity()`, `lexdiv_import_contextual()`, `lexdiv_evaluate_contextual()`, `lexdiv_score_contextual()`, `lexdiv_evaluate_annotations()`, `lexdiv_align_annotations()`, `lexdiv_amod_pairs()`)**: Record human KWIC review decisions, compare raters, evaluate segmentation or tagger correspondence, and attach external contextual model suggestions separately from reviewer judgments.

### Longitudinal study tables, visualization, and R ecosystem integration

- **Planned-observation and mixed-model preparation (`lexdiv_study_table()`, `lexdiv_study_model_data()`, `lexdiv_compare_responses()`)**: Join planned writer/task/occasion schedules to document submissions and metric plans with a complete inclusion/exclusion audit.
- **Seamless R container support and reshaping (`lexdiv_as_documents()`, `lexdiv_widen()`)**: Accept base `data.frame`, `tibble`, `data.table`, named vectors, and `quanteda` tokens, and reshape results cleanly for reporting.
- **Zero-dependency Base-R visualization (`plot()`)**: Publication-ready color and `monochrome = TRUE` graphics across metric results, local MATTR curves, NJ8 levels, TUBELEX coverage, reference coverage, length screens, and concordance position barcodes, requiring only `digest` and `stringi` at runtime.
