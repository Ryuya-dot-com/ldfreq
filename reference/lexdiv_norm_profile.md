# Profile Terms with Caller-Supplied Lexical Norms

Computes token- and/or type-weighted arithmetic means for one or more
lexical- norm variables. Matching is exact: the function neither
tokenizes nor normalizes the supplied terms. Means use observed values
from matched keys only. Resource coverage and annotation coverage are
therefore returned separately and should accompany every interpretation
of an estimate.

## Usage

``` r
lexdiv_norm_profile(
  terms,
  norms,
  key,
  measure_specs,
  resource,
  weightings = c("token", "type"),
  max_rows = 1e+06
)

# S3 method for class 'lexdiv_norm_profile'
print(x, ...)
```

## Arguments

- terms:

  A plain character vector with one caller-prepared lookup term per
  element. Zero length is allowed. Terms are retained in `lookup`.

- norms:

  An ordinary data frame containing one unique key column and the
  numeric norm columns named by `measure_specs`. Other columns are
  ignored and are not copied into the result.

- key:

  One string naming the exact-match key column in `norms`.

- measure_specs:

  An ordinary data frame with the exact ordered columns `measure_id`,
  `value_column`, `construct_id`, `value_unit`, `direction`, `language`,
  `variety`, `population_id`, `collection_year`, `valid_min`, and
  `valid_max`. IDs must be unique; `direction` is `"higher"`, `"lower"`,
  or `"descriptive"`; numeric bounds may be `NA`.

- resource:

  A plain named list with the exact ordered fields `resource_id`,
  `resource_version`, `creator`, `source_reference`, `data_license`,
  `transformation_id`, `lookup_unit`, and
  `resource_key_normalization_id`. These are caller assertions recorded
  for provenance; they do not establish redistribution rights.

- weightings:

  A non-empty subset of `c("token", "type")`, without duplicates. Type
  identity is the exact lookup term after no package-side
  transformation.

- max_rows:

  A positive whole-number bound on the combined rows planned for
  `lookup`, `summary`, and `coverage`, checked before result allocation.

- x:

  A `lexdiv_norm_profile` object.

- ...:

  Additional arguments passed to
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html).

## Value

A `lexdiv_norm_profile` list with `status`, `summary`, `lookup`,
`coverage`, `provenance`, and `diagnostics`. `summary` contains
conditional observed matched-only means and their denominators. `lookup`
contains one input-major, measure-minor row per term and measure.
`coverage` is the analysis-ready denominator projection of `summary`. No
missing value is imputed and no automatic coverage threshold is applied.
`print.lexdiv_norm_profile()` returns `x` invisibly.

## Details

For several documents sharing a reference table, use
[`lexdiv_norm_profile_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile_batch.md)
to validate the shared inputs once and retain separate document
estimates and coverage under a global row bound.

The three coverage rates have different denominators:
`resource_coverage = matched_units / input_units`,
`value_coverage = observed_value_units / input_units`, and
`annotation_coverage = observed_value_units / matched_units`. A matched
key with an `NA` norm is `missing_annotation`; an unmatched key is
`not_applicable_oov`. The function does not infer a universal direction,
compare unlike scales, form composite scores, or approve a data license.

## See also

[`vignette("japanese-norms", package = "ldfreq")`](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-norms.md)
for stimulus-item tables, local Japanese norm files, scale
interpretation and data terms.

## Examples

``` r
norms <- data.frame(
  term = c("book", "read", "rare"),
  familiarity = c(6, 5, NA_real_),
  stringsAsFactors = FALSE
)
specs <- data.frame(
  measure_id = "familiarity",
  value_column = "familiarity",
  construct_id = "subjective_familiarity",
  value_unit = "seven_point_rating",
  direction = "higher",
  language = "English",
  variety = "unspecified",
  population_id = "example_adults",
  collection_year = "2025",
  valid_min = 1,
  valid_max = 7,
  stringsAsFactors = FALSE
)
resource <- list(
  resource_id = "example_norms",
  resource_version = "2025-01",
  creator = "Example creator",
  source_reference = "Example citation",
  data_license = "Example terms; verify before redistribution",
  transformation_id = "none",
  lookup_unit = "lowercase_lemma",
  resource_key_normalization_id = "caller-prepared-v1"
)

profile <- lexdiv_norm_profile(
  c("book", "book", "rare", "unknown"),
  norms,
  "term",
  specs,
  resource
)
profile$summary
#>   result_order   resource_id resource_version  measure_id
#> 1            1 example_norms          2025-01 familiarity
#> 2            2 example_norms          2025-01 familiarity
#>             construct_id         value_unit direction language     variety
#> 1 subjective_familiarity seven_point_rating    higher  English unspecified
#> 2 subjective_familiarity seven_point_rating    higher  English unspecified
#>    population_id collection_year                             statistic_id
#> 1 example_adults            2025 arithmetic_mean_observed_matched_only_v1
#> 2 example_adults            2025 arithmetic_mean_observed_matched_only_v1
#>   weighting     type_identity estimate status missing_reason input_units
#> 1     token              <NA>        6     ok           <NA>           4
#> 2      type exact_lookup_term        6     ok           <NA>           3
#>   matched_units unmatched_units observed_value_units
#> 1             3               1                    2
#> 2             2               1                    1
#>   matched_missing_value_units resource_coverage value_coverage
#> 1                           1         0.7500000      0.5000000
#> 2                           1         0.6666667      0.3333333
#>   annotation_coverage
#> 1           0.6666667
#> 2           0.5000000
profile$coverage
#>   result_order   resource_id resource_version  measure_id weighting input_units
#> 1            1 example_norms          2025-01 familiarity     token           4
#> 2            2 example_norms          2025-01 familiarity      type           3
#>   matched_units unmatched_units observed_value_units
#> 1             3               1                    2
#> 2             2               1                    1
#>   matched_missing_value_units resource_coverage value_coverage
#> 1                           1         0.7500000      0.5000000
#> 2                           1         0.6666667      0.3333333
#>   annotation_coverage
#> 1           0.6666667
#> 2           0.5000000
profile$lookup
#>   input_index    term  measure_id       lookup_status value       value_status
#> 1           1    book familiarity    matched_resource     6           observed
#> 2           2    book familiarity    matched_resource     6           observed
#> 3           3    rare familiarity    matched_resource    NA missing_annotation
#> 4           4 unknown familiarity unknown_to_resource    NA not_applicable_oov
print(profile)
#> <lexdiv_norm_profile: ok; example_norms@2025-01; 1 measure; 4 lookup rows; schema 0.1.0>
#>   measure_id weighting estimate status missing_reason resource_coverage
#>  familiarity     token        6     ok           <NA>         0.7500000
#>  familiarity      type        6     ok           <NA>         0.6666667
#>  annotation_coverage
#>            0.6666667
#>            0.5000000
#> Means are conditional on observed matched values; inspect $coverage.
```
