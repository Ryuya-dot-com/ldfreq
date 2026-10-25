# Tabulate TUBELEX profiles while retaining coverage and input conditions

Reference snapshots require a prior explicit download; see
[`lexdiv_download_resources`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_resources.md)
for terms and cache setup.

Combine existing profiles into document and summary tables, count
confirmed unmatched terms, and inspect term normalization. No resource
lookup, tokenization, annotation, model download, or learner scoring is
performed.

## Usage

``` r
tubelex_diagnostics(x, max_rows = 1e6)
```

## Arguments

- x:

  One unmodified
  [`tubelex_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md)
  result, or a plain named list as returned by
  [`tubelex_profile_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md).
  IDs must be unique, non-empty valid-UTF-8 strings. A single profile
  uses `document_1`. An empty named list is allowed. Profiles must use
  profile contract 0.2.0 and the currently cached resource; unsupported
  records must be recreated from their inputs.

- max_rows:

  Positive whole-number limit on total input lookup rows plus two
  summary rows per document, checked before constructing aggregate
  tables.

## Details

Input order and empty or failed documents are retained. Summary values
are copied after checking their consistency with lookup and coverage.
Missing results are not replaced by zero. A resource failure leaves
match status unresolved (`NA`); these terms are not counted as confirmed
unmatched. Validation checks structure and consistency, not authenticity
of saved profiles.

`condition_id` labels groups of identical recorded resource, query
normalization, input source, alignment declaration, and (where
available) tokenizer and text-preparation settings, in first-seen order.
Unmatched and mapping counts are computed separately within these
groups. IDs are local to each diagnostic call, not persistent analysis
identifiers. Matching settings for character vectors remain unverified;
a group is not evidence that the vectors used the same tokenizer or that
their segmentation matches TUBELEX. Keep externally recorded
tokenization metadata with the full profiles.

`token_count` is the number of occurrences; `document_count` is the
number of distinct input IDs containing the row's key. Counts are
ordered by decreasing occurrence count, with ties in input encounter
order. The tables retain text-derived strings; they are not anonymized
corpus summaries.

TUBELEX describes reference-corpus frequency and distribution across
videos and channels. These are properties of word forms, not
observations that a particular learner recognizes, recalls, or can use a
word. Reading-related lexical employability needs learner evidence and
an appropriate criterion; it is not inferred from high coverage, mean
Zipf frequency or channel prevalence.

## Value

A plain list containing:

- `summary`:

  Two rows per document, preserving token/type weighting, matched-only
  frequency and prevalence statistics, denominators and coverage. Adds
  `document_id`, `condition_id`, `status`, and `failure_reason`.

- `documents`:

  One row per document with status, all original coverage fields,
  resource version, query normalization and input alignment settings.
  Tokenizer fields are missing for character-vector inputs. Settings
  columns, including `keep_numbers`, are character labels.

- `unmatched_terms`:

  Counts by `condition_id` and `lookup_term`, including only confirmed
  non-matches.

- `normalization_mappings`:

  Counts by `condition_id`, original `term`, `lookup_term`, and logical
  `matched` (possibly missing). `lookup_changed` flags unequal
  original/query strings; `number_marker` identifies the exact query
  `<num>`. Neither flag is an annotation error or a difficulty
  classification.

- `provenance`, `diagnostics`:

  Named lists retaining each profile's complete records, including
  failure details and preprocessing.

Empty batches return typed zero-row tables and empty named metadata
lists. Keep the original profiles for occurrence positions and complete
lookup values.

## See also

[`tubelex_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md),
[`nj8_diagnostics`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_diagnostics.md);
[`lexdiv_compare_responses`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_compare_responses.md)
for separately collected, scored and paired binary responses. Frequency
profiles do not supply those responses. [vocabulary knowledge and use
guide](https://ryuya-dot-com.github.io/ldfreq/articles/vocabulary-knowledge-and-use.html)
for a worked separation of learner responses and corpus features.

## Examples

``` r
# Optional data: review and explicitly download these resources first.
if (all(lexdiv_resource_info(c("tubelex"))$available)) {
profiles <- tubelex_profile_batch(list(
  first = c("Apple", "apple", "zzunmatchedxyz"),
  second = c("the", "zzunmatchedxyz"), blank = character(),
  invalid = c("the", NA_character_)
))
audit <- tubelex_diagnostics(profiles)
audit$summary[, c("document_id", "status", "weighting", "coverage", "mean_zipf")]
audit$unmatched_terms
audit$normalization_mappings
}
```
