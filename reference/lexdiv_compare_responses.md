# Compare paired binary vocabulary responses with an explicit criterion

Checks pair identity and binary scores, preserves missing responses, and
tabulates agreement and directional disagreement with visible
denominators. This is a descriptive response comparison, not an
employability scale, automatic response scorer, or validation of the
chosen criterion.

## Usage

``` r
lexdiv_compare_responses(data, test, criterion,
  keys = c("learner_id", "item_id"), by = character())
```

## Arguments

- data:

  A data frame, one row per paired observation. All original columns are
  retained, including sense/context IDs, rubric versions, raters, task
  order, missingness reasons and corpus features when supplied.

- test,criterion:

  Names of two distinct columns containing numeric or logical 0
  (incorrect), 1 (correct), or `NA` (missing). Factors, character
  scores, partial credit, infinities and `NaN` are rejected. The caller
  must score and pair responses under explicit criteria before calling
  this function.

- keys:

  Non-empty character vector naming columns that jointly identify each
  pair. Values must be non-blank UTF-8 character strings or factors,
  without missing values. Add occasion, task or format IDs for repeated
  observations. Keys establish row identity, not statistical
  independence.

- by:

  Distinct categorical column names to tabulate separately, or
  [`character()`](https://rdrr.io/r/base/character.html) for one pooled
  table. Values must be non-blank UTF-8 character strings or factors.
  Missing group labels are retained as an `NA` stratum. Grouping is
  explicit: include relevant formats, occasions, groups or rubric
  versions; these are not detected automatically.

## Value

A plain list with four components:

- responses:

  Original rows and columns in input order, plus character
  `comparison_outcome`. The input is not modified.

- counts:

  Grouping columns followed by `outcome` and integer `n`. Every observed
  group has all seven outcomes, including zero counts: `both_correct`,
  `test_only`, `criterion_only`, `both_incorrect`, `missing_test`,
  `missing_criterion`, and `missing_both`. The first two missing
  categories mean exactly one score is missing. Unused factor levels do
  not create groups.

- summary:

  Grouping columns followed by `quantity`, `numerator`, `denominator`,
  and `proportion`. Five rows per observed group: agreement, test-only
  and criterion-only proportions among complete pairs; criterion failure
  among test-correct complete pairs; and the complete-pair fraction
  among all supplied pairs. Zero denominators give `NA`.

- provenance:

  `comparison_version`, selected `test`, `criterion`, `keys`, `by`, and
  `missing_policy`. This records the comparison specification, not an
  independent scoring audit.

Groups follow first occurrence. Empty ungrouped input returns seven zero
counts and five undefined proportions; empty grouped input returns
zero-row tables. Duplicate column names and output-name collisions are
rejected.

## Details

Use unique item IDs for different target senses or contexts even when
the surface form is identical. Joining on the surface form can duplicate
response rows. Repeated observations need additional key columns;
grouping alone does not resolve duplicate keys. A missing administration
must be represented by an explicit row with `NA` score(s) if it belongs
in the supplied-pair denominator. The function cannot detect unrecorded
scheduled observations.

The criterion is a caller-selected measurement and need not be
error-free. Each supplied pair contributes once; pooled proportions are
not averages of learner-level proportions when learners contribute
different numbers of pairs. Meaning recall can address a prerequisite of
reading; it does not establish fluent contextual comprehension or
productive use. TUBELEX values describe forms in a reference corpus and
are not response scores or learner abilities. Save the item dictionary,
complete resource profiles, scoring rubric/version and response records
alongside this result.

Missing scores are never converted to incorrect responses. An unanswered
item may count as incorrect only if a prespecified scoring policy
justifies it; preserve the original response and missingness reason
separately. Partial credit is not silently dichotomized. Observed
complete-pair proportions can be biased by informative missingness. An
absent essay word is not an incorrect elicited response. No confidence
intervals or tests are calculated because repeated learners/items and
sampling require an explicit inferential design.

## References

Kremmel, B. and Schmitt, N. (2016). Interpreting vocabulary test scores:
What do various item formats tell us about learners' ability to employ
words? Language Assessment Quarterly, 13(4), 377–392.
[doi:10.1080/15434303.2016.1237516](https://doi.org/10.1080/15434303.2016.1237516)
.

## See also

[`tubelex_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md),
[`tubelex_diagnostics`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_diagnostics.md)

## Examples

``` r
# Authored demonstration, not learner observations.
responses <- data.frame(learner_id = rep("example", 5),
  item_id = paste0("i", 1:5), recognition = c(1, 1, 0, 0, NA),
  recall = c(1, 0, 1, 0, 0))
comparison <- lexdiv_compare_responses(responses,
  test = "recognition", criterion = "recall")
comparison$counts
#>             outcome n
#> 1      both_correct 1
#> 2         test_only 1
#> 3    criterion_only 1
#> 4    both_incorrect 1
#> 5      missing_test 1
#> 6 missing_criterion 0
#> 7      missing_both 0
comparison$summary
#>                                              quantity denominator numerator
#> 1                      agreement_among_complete_pairs           4         2
#> 2                      test_only_among_complete_pairs           4         1
#> 3                 criterion_only_among_complete_pairs           4         1
#> 4 criterion_failure_among_test_correct_complete_pairs           2         1
#> 5                              complete_pair_fraction           5         4
#>   proportion
#> 1       0.50
#> 2       0.25
#> 3       0.25
#> 4       0.50
#> 5       0.80

repeated <- rbind(transform(responses, occasion_id = "pre"),
  transform(responses, occasion_id = "post"))
lexdiv_compare_responses(repeated, "recognition", "recall",
  keys = c("learner_id", "item_id", "occasion_id"),
  by = "occasion_id")$summary
#>    occasion_id                                            quantity denominator
#> 1          pre                      agreement_among_complete_pairs           4
#> 2          pre                      test_only_among_complete_pairs           4
#> 3          pre                 criterion_only_among_complete_pairs           4
#> 4          pre criterion_failure_among_test_correct_complete_pairs           2
#> 5          pre                              complete_pair_fraction           5
#> 6         post                      agreement_among_complete_pairs           4
#> 7         post                      test_only_among_complete_pairs           4
#> 8         post                 criterion_only_among_complete_pairs           4
#> 9         post criterion_failure_among_test_correct_complete_pairs           2
#> 10        post                              complete_pair_fraction           5
#>    numerator proportion
#> 1          2       0.50
#> 2          1       0.25
#> 3          1       0.25
#> 4          1       0.50
#> 5          4       0.80
#> 6          2       0.50
#> 7          1       0.25
#> 8          1       0.25
#> 9          1       0.50
#> 10         4       0.80
```
