# Package index

## Overview

- [`ldfreq`](https://ryuya-dot-com.github.io/ldfreq/reference/ldfreq-package.md)
  [`ldfreq-package`](https://ryuya-dot-com.github.io/ldfreq/reference/ldfreq-package.md)
  : Reproducible Lexical Diversity and Frequency Profiles

## Core metrics

- [`lexdiv_metric_ids()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
  [`lexdiv_metrics()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
  [`lexdiv_metrics_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
  [`print(`*`<lexdiv_batch_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
  [`print(`*`<lexdiv_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
  : Compute Versioned Lexical-Diversity Metric Variants

## Raw text and lexical units

- [`lexdiv_tokenize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
  [`lexdiv_lemmatize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
  [`lexdiv_metrics_text()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
  [`print(`*`<lexdiv_tokenization>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
  [`print(`*`<lexdiv_text_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
  : Versioned raw-text preprocessing for lexical-diversity metrics
- [`lexdiv_compare_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_compare_annotations.md)
  : Compare annotation versions on identical tokenized documents
- [`lexdiv_import_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md)
  : Align complete external token annotations with original text
- [`lexdiv_evaluate_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_evaluate_annotations.md)
  : Evaluate external annotation labels against an explicit reference
- [`lexdiv_align_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_align_annotations.md)
  : Align different token segmentations using original source positions
- [`lexdiv_amod_pairs()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_amod_pairs.md)
  : Extract source-linked adjective and common-noun dependency pairs
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
- [`lexdiv_tokenize_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md)
  [`lexdiv_metrics_text_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md)
  [`print(`*`<lexdiv_text_batch_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md)
  [`plot(`*`<lexdiv_text_batch_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md)
  : Tokenize and analyze multiple texts with explicit document IDs
- [`lexdiv_flemmatize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_flemmatize.md)
  : Add flemmas from a caller-supplied AntBNC lemma list
- [`lexdiv_family_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_family_profile.md)
  : Count resource-defined word families while retaining source
  occurrences

## Exact lexical overlap and coverage

- [`lexdiv_overlap_ids()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_overlap.md)
  [`lexdiv_term_overlap()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_overlap.md)
  [`lexdiv_content_overlap()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_overlap.md)
  [`print(`*`<lexdiv_overlap>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_overlap.md)
  : Compute Exact Type Overlap Between Two Texts
- [`lexdiv_reference_coverage()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_reference_coverage.md)
  [`print(`*`<lexdiv_reference_coverage>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_reference_coverage.md)
  [`plot(`*`<lexdiv_reference_coverage>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_reference_coverage.md)
  : Compute Coverage of Multiple Documents by One Reference Term Set

## Formula variants

- [`lexdiv_variant_ids()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_variant_metrics.md)
  [`lexdiv_variant_metrics()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_variant_metrics.md)
  [`print(`*`<lexdiv_variant_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_variant_metrics.md)
  : Explicit Maas and sequential-MTLD comparison variants

## Profiles and screens

- [`lexdiv_spec()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
  [`lexdiv_grid()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
  [`lexdiv_plan()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
  [`print(`*`<lexdiv_spec>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
  [`print(`*`<lexdiv_grid>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
  [`print(`*`<lexdiv_plan>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
  [`lexdiv_methods()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
  [`lexdiv_presets()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
  [`lexdiv_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
  [`lexdiv_profile_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
  [`lexdiv_screen()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
  : Build and Evaluate Explicit Lexical-Diversity Method Plans
- [`lexdiv_mattr_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_mattr_profile.md)
  [`print(`*`<lexdiv_mattr_profile>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_mattr_profile.md)
  : Inspect the local MATTR trajectory and positional exposure
- [`plot(`*`<lexdiv_mattr_profile>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/plot.lexdiv_mattr_profile.md)
  : Plot one local MATTR trajectory

## Caller-supplied lexical norms

- [`lexdiv_norm_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile.md)
  [`print(`*`<lexdiv_norm_profile>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile.md)
  : Profile Terms with Caller-Supplied Lexical Norms
- [`lexdiv_norm_profile_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile_batch.md)
  [`print(`*`<lexdiv_norm_profile_batch>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile_batch.md)
  : Apply Caller-Supplied Lexical Norms to Multiple Documents

## Scored vocabulary responses

- [`lexdiv_compare_responses()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_compare_responses.md)
  : Compare paired binary vocabulary responses with an explicit
  criterion

## Adjacent n-gram frequencies

- [`lexdiv_ngrams()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
  [`lexdiv_ngram_reference()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
  [`lexdiv_ngram_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
  [`print(`*`<lexdiv_ngrams>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
  [`print(`*`<lexdiv_ngram_reference>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
  [`print(`*`<lexdiv_ngram_profile>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
  : Adjacent Bigrams and Trigrams with Local Reference Frequencies
- [`lexdiv_ngram_reference_build()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngram_reference_build.md)
  : Build an N-gram Reference from Whole-document Chunks
- [`lexdiv_ngram_compare()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngram_compare.md)
  : Compare N-gram References on the Same Target Items
- [`lexdiv_read_masc()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_read_masc.md)
  [`lexdiv_as_quanteda()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_read_masc.md)
  : Read local MASC Penn annotations and retain positions in quanteda

## Reference-resource profiles

- [`morpholex_data()`](https://ryuya-dot-com.github.io/ldfreq/reference/morpholex_data.md)
  : Read the Bundled MorphoLex English Database
- [`bnccoca_data()`](https://ryuya-dot-com.github.io/ldfreq/reference/bnccoca_data.md)
  : Read Nation's BNC/COCA Level 6 Word-Family Lists
- [`morphynet_read_derivations()`](https://ryuya-dot-com.github.io/ldfreq/reference/morphynet_read_derivations.md)
  : Read MorphyNet Derivational Relations from a Local File
- [`nj8_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md)
  [`nj8_profile_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md)
  [`print(`*`<lexical_level_profile>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md)
  [`print(`*`<nj8_profile_batch>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md)
  [`plot(`*`<lexical_level_profile>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md)
  : Profile lexical coverage by New JACET 8000 frequency level
- [`nj8_diagnostics()`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_diagnostics.md)
  : Diagnose NJ8 non-matches and lexical-unit transformations
- [`tubelex_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md)
  [`tubelex_profile_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md)
  [`print(`*`<tubelex_profile>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md)
  : Coverage-aware TUBELEX frequency and prevalence profile
- [`tubelex_diagnostics()`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_diagnostics.md)
  : Tabulate TUBELEX profiles while retaining coverage and input
  conditions

## Output and visualization

- [`lexdiv_as_documents()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md)
  [`lexdiv_widen()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md)
  [`print(`*`<lexdiv_wide_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md)
  [`plot(`*`<lexdiv_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md)
  [`plot(`*`<lexdiv_batch_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md)
  [`plot(`*`<lexdiv_profile_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md)
  [`plot(`*`<lexdiv_profile_batch_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md)
  [`plot(`*`<lexdiv_text_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md)
  [`plot(`*`<lexdiv_screen_results>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md)
  [`plot(`*`<tubelex_profile>`*`)`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md)
  : Adapt, Reshape, and Plot Lexical-Diversity Results

## Evidence

- [`lexdiv_length_evidence()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_length_evidence.md)
  : Inspect Context-Specific Token-Length Evidence
