# Package index

## Package overview

High-level map of inputs, workflows, measurement boundaries, and
citations.

- [`ldfreq`](https://ryuya-dot-com.github.io/ldfreq/reference/ldfreq-package.md)
  [`ldfreq-package`](https://ryuya-dot-com.github.io/ldfreq/reference/ldfreq-package.md)
  : Reproducible Lexical Diversity and Frequency Profiles

## Core lexical-diversity metrics

Compute eleven default lexical-diversity measures, moving-average MTLD,
and experimental expected-TTR D from pre-tokenized word vectors.

- [`lexdiv_metric_ids()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
  [`lexdiv_metrics()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
  [`lexdiv_metrics_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
  [`print(`*`<lexdiv_batch_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
  [`print(`*`<lexdiv_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
  : Compute Versioned Lexical-Diversity Metric Variants
- [`lexdiv_variant_metrics()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_variant_metrics.md)
  [`print(`*`<lexdiv_variant_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_variant_metrics.md)
  : Explicit Maas and Sequential-MTLD Comparison Variants

## Raw text, tokenization, and word units

Tokenize raw English texts, attach lemma or AntBNC flemma layers, bridge
raw texts into corpus annotations, or import Japanese/external
annotations.

- [`lexdiv_tokenize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
  [`lexdiv_lemmatize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
  [`lexdiv_lemmatize_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
  [`lexdiv_metrics_text()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
  [`print(`*`<lexdiv_tokenization>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
  [`print(`*`<lexdiv_text_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
  : Versioned Raw-Text Preprocessing for Lexical-Diversity Metrics
- [`lexdiv_tokenize_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md)
  [`lexdiv_metrics_text_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md)
  [`print(`*`<lexdiv_text_batch_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md)
  [`plot(`*`<lexdiv_text_batch_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md)
  : Tokenize and Analyze Multiple Texts with Explicit Document IDs
- [`lexdiv_flemmatize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_flemmatize.md)
  [`lexdiv_flemmatize_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_flemmatize.md)
  : Add Flemmas from a Caller-Supplied AntBNC Lemma List
- [`lexdiv_import_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md)
  [`lexdiv_as_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md)
  [`print(`*`<lexdiv_annotations>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md)
  : Import External Annotations or Bridge Raw Texts to Corpus
  Annotations
- [`lexdiv_family_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_family_profile.md)
  : Count resource-defined word families while retaining source
  occurrences
- [`lexdiv_read_masc()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_read_masc.md)
  [`lexdiv_as_quanteda()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_read_masc.md)
  : Read local MASC Penn annotations and retain positions in quanteda

## Plans, local MATTR trajectories, and token-floor screens

Define multi-parameter measurement plans, inspect window-by-window MATTR
profiles, and evaluate empirical token-count floors without altering
scores.

- [`lexdiv_spec()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_plan.md)
  [`lexdiv_grid()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_plan.md)
  [`lexdiv_plan()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_plan.md)
  [`lexdiv_methods()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_plan.md)
  [`lexdiv_presets()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_plan.md)
  [`print(`*`<lexdiv_spec>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_plan.md)
  [`print(`*`<lexdiv_grid>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_plan.md)
  [`print(`*`<lexdiv_plan>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_plan.md)
  [`print(`*`<lexdiv_profile_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_plan.md)
  [`print(`*`<lexdiv_profile_batch_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_plan.md)
  : Build Explicit Lexical-Diversity Method Plans
- [`lexdiv_mattr_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_mattr_profile.md)
  [`print(`*`<lexdiv_mattr_profile>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_mattr_profile.md)
  : Inspect the local MATTR trajectory and positional exposure
- [`plot(`*`<lexdiv_mattr_profile>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/plot.lexdiv_mattr_profile.md)
  : Plot one local MATTR trajectory
- [`lexdiv_screen_lengths()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_screen_lengths.md)
  : Evaluate Independent Token-Count Screens Without Modifying Metric
  Values
- [`lexdiv_length_evidence()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_length_evidence.md)
  : Inspect Context-Specific Token-Length Evidence

## Recipes, portable records, and reporting

Reuse resolved settings, inspect differences, and export results or
calculation descriptions without changing the measurement engine.

- [`lexdiv_recipe()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_recipe.md)
  [`print(`*`<lexdiv_recipe>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_recipe.md)
  : Reusable raw-text analysis recipes
- [`lexdiv_run_recipe()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_run_recipe.md)
  [`print(`*`<lexdiv_analysis>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_run_recipe.md)
  : Run a saved recipe through the R calculation APIs
- [`lexdiv_write()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_write.md)
  [`lexdiv_read()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_write.md)
  : Save and read portable recipes and analysis records
- [`lexdiv_compare_analyses()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_compare_analyses.md)
  : Inspect differences between saved analysis conditions
- [`lexdiv_methods_text()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_methods_text.md)
  : Describe saved calculations in English or Japanese

## Reference-vocabulary and morphology profiles

Inspect license terms, download SHA-256-verified optional datasets, and
profile vocabulary with TUBELEX, New JACET 8000, BNC/COCA, MorphoLex, or
MorphyNet.

- [`lexdiv_resource_info()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_resources.md)
  [`lexdiv_download_resources()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_resources.md)
  : Inspect and explicitly download optional reference data
- [`tubelex_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md)
  [`tubelex_profile_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md)
  [`print(`*`<tubelex_profile>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md)
  [`print(`*`<tubelex_profile_batch>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md)
  [`plot(`*`<tubelex_profile_batch>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md)
  : Coverage-Aware TUBELEX Frequency and Prevalence Profile
- [`tubelex_diagnostics()`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_diagnostics.md)
  : Tabulate TUBELEX profiles while retaining coverage and input
  conditions
- [`nj8_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md)
  [`nj8_profile_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md)
  [`print(`*`<lexical_level_profile>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md)
  [`print(`*`<nj8_profile_batch>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md)
  [`plot(`*`<lexical_level_profile>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md)
  : Profile lexical coverage by New JACET 8000 frequency level
- [`nj8_diagnostics()`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_diagnostics.md)
  : Diagnose NJ8 non-matches and lexical-unit transformations
- [`bnccoca_data()`](https://ryuya-dot-com.github.io/ldfreq/reference/bnccoca_data.md)
  : Read Nation's BNC/COCA Level 6 Word-Family Lists
- [`morpholex_data()`](https://ryuya-dot-com.github.io/ldfreq/reference/morpholex_data.md)
  : Read the Cached MorphoLex English Database
- [`morphynet_read_derivations()`](https://ryuya-dot-com.github.io/ldfreq/reference/morphynet_read_derivations.md)
  : Read MorphyNet Derivational Relations from a Local File

## Custom lexical norms, overlap, and n-grams

Apply your own familiarity/AoA/frequency tables, measure exact lexical
overlap or set coverage, and build or compare adjacent n-gram
references.

- [`lexdiv_norm_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile.md)
  [`lexdiv_norm_spec()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile.md)
  [`lexdiv_resource_meta()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile.md)
  [`print(`*`<lexdiv_norm_profile>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile.md)
  : Profile Terms with Caller-Supplied Lexical Norms
- [`lexdiv_norm_profile_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile_batch.md)
  [`print(`*`<lexdiv_norm_profile_batch>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile_batch.md)
  : Apply Caller-Supplied Lexical Norms to Multiple Documents
- [`lexdiv_overlap_ids()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_overlap.md)
  [`lexdiv_term_overlap()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_overlap.md)
  [`lexdiv_content_overlap()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_overlap.md)
  [`print(`*`<lexdiv_overlap>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_overlap.md)
  : Compute Exact Type Overlap Between Two Texts
- [`lexdiv_reference_coverage()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_reference_coverage.md)
  [`print(`*`<lexdiv_reference_coverage>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_reference_coverage.md)
  [`plot(`*`<lexdiv_reference_coverage>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_reference_coverage.md)
  : Compute Coverage of Multiple Documents by One Reference Term Set
- [`lexdiv_ngrams()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
  [`lexdiv_ngram_reference()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
  [`lexdiv_ngram_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
  [`print(`*`<lexdiv_ngrams>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
  [`print(`*`<lexdiv_ngram_reference>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
  [`print(`*`<lexdiv_ngram_profile>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
  : Adjacent Bigrams and Trigrams with Local Reference Frequencies
- [`lexdiv_build_ngram_reference()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_build_ngram_reference.md)
  [`print(`*`<lexdiv_ngram_build>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_build_ngram_reference.md)
  : Build an N-gram Reference from Whole-Document Chunks
- [`lexdiv_compare_ngrams()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_compare_ngrams.md)
  [`print(`*`<lexdiv_ngram_comparison>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_compare_ngrams.md)
  : Compare N-gram References on the Same Target Items

## Study tables and source-linked corpus exploration

Prepare longitudinal mixed-model tables, search KWIC concordances, and
compute within-document dispersion, collocations, keyness, or response
pairs.

- [`lexdiv_study_table()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_study_table.md)
  [`lexdiv_study_model_data()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_study_table.md)
  [`print(`*`<lexdiv_study_model_data>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_study_table.md)
  : Join Planned Observations to Saved Measurements and Select Model
  Rows
- [`lexdiv_concordance()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_concordance.md)
  [`lexdiv_sort_concordance()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_concordance.md)
  [`lexdiv_concordance_dispersion()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_concordance.md)
  [`print(`*`<lexdiv_concordance>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_concordance.md)
  [`print(`*`<lexdiv_dispersion>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_concordance.md)
  [`plot(`*`<lexdiv_concordance>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_concordance.md)
  : Search Source-Aligned Words and Phrases and Inspect Their
  Distribution
- [`lexdiv_collocations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_collocations.md)
  : Count collocation opportunities and descriptive association scores
- [`lexdiv_keyness()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_keyness.md)
  [`lexdiv_keyness_concordance()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_keyness.md)
  : Compare word frequencies in explicit target and reference corpora
- [`lexdiv_compare_responses()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_compare_responses.md)
  : Compare paired binary vocabulary responses with an explicit
  criterion

## Annotation review, alignment, and contextual models

Audit changed tags, align different segmentations, record human KWIC
disambiguation decisions, and evaluate external contextual model
proposals.

- [`lexdiv_compare_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_compare_annotations.md)
  : Compare annotation versions on identical tokenized documents
- [`lexdiv_evaluate_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_evaluate_annotations.md)
  : Evaluate external annotation labels against an explicit reference
- [`lexdiv_align_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_align_annotations.md)
  : Align different token segmentations using original source positions
- [`lexdiv_ambiguity_review()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ambiguity_review.md)
  : Review lexical candidates in their original contexts
- [`lexdiv_compare_ambiguity()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_compare_ambiguity.md)
  : Compare two contextual lexical-candidate reviews
- [`lexdiv_import_contextual()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_contextual.md)
  : Attach external model outputs to verified contextual occurrences
- [`lexdiv_evaluate_contextual()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_evaluate_contextual.md)
  : Compare contextual candidate scores with an explicit reference
  review
- [`lexdiv_score_contextual()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_score_contextual.md)
  : Score contextual candidates using separate labeled training examples
- [`lexdiv_amod_pairs()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_amod_pairs.md)
  : Extract source-linked adjective and common-noun dependency pairs

## Reshaping, container conversion, and plotting

Convert tidy or quanteda token containers, reshape long results to wide
reporting tables, and draw publication-ready Base-R figures.

- [`lexdiv_as_documents()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_as_documents.md)
  : Convert Token Containers to Named Documents
- [`lexdiv_widen()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_widen.md)
  [`print(`*`<lexdiv_wide_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_widen.md)
  : Reshape metric results without recomputing values
- [`plot(`*`<lexdiv_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/plot.lexdiv_results.md)
  [`plot(`*`<lexdiv_batch_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/plot.lexdiv_results.md)
  [`plot(`*`<lexdiv_profile_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/plot.lexdiv_results.md)
  [`plot(`*`<lexdiv_profile_batch_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/plot.lexdiv_results.md)
  [`plot(`*`<lexdiv_text_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/plot.lexdiv_results.md)
  [`plot(`*`<lexdiv_screen_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/plot.lexdiv_results.md)
  [`plot(`*`<tubelex_profile>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/plot.lexdiv_results.md)
  : Plot one metric, a length screen or TUBELEX coverage
- [`lexdiv_convenience`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md)
  : Prepare and display lexical-diversity results
