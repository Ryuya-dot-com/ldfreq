# Profile One or More Documents with Caller-Supplied Lexical Norms

Computes token- and/or type-weighted arithmetic means for one or more
lexical-norm variables on one document or a multi-document corpus from
matched observed keys while reporting resource and annotation coverage
separately.

## Usage

``` r
lexdiv_norm_profile(
  x,
  norms,
  key,
  measure_specs = NULL,
  resource = lexdiv_resource_meta("caller_norms"),
  weightings = c("token", "type"),
  id_col = "document_id",
  term_col = "terms",
  max_rows = 1e+06
)

lexdiv_norm_spec(
  value_column,
  measure_id = NULL,
  construct_id = measure_id,
  value_unit = "unspecified",
  direction = "descriptive",
  language = "unspecified",
  variety = "unspecified",
  population_id = "unspecified",
  collection_year = "unspecified",
  valid_min = NA_real_,
  valid_max = NA_real_
)

lexdiv_resource_meta(
  resource_id = "caller_resource",
  resource_version = "unspecified",
  creator = "unspecified",
  source_reference = "unspecified",
  data_license = "unspecified",
  transformation_id = "none",
  lookup_unit = "exact_term",
  resource_key_normalization_id = "caller-prepared-v1"
)

# S3 method for class 'lexdiv_norm_profile'
print(x, ...)

# S3 method for class 'lexdiv_norm_profile_batch'
print(x, ...)
```

## Arguments

- x:

  For a single document, a character vector of caller-prepared lookup
  terms or a `lexdiv_tokenization` object. For multiple documents, a
  named list of term vectors, a `lexdiv_tokenization_batch` object, or a
  data frame/tibble with `id_col` and `term_col`. For
  [`print()`](https://rdrr.io/r/base/print.html), a
  `lexdiv_norm_profile` or `lexdiv_norm_profile_batch` object.

- norms:

  A data frame or tibble containing one unique key column and numeric
  norm columns. Non-numeric metadata columns are ignored automatically
  when `measure_specs = NULL`.

- key:

  One string naming the exact-match key column in `norms`.

- measure_specs:

  Optional data frame or tibble of 11 measure-specification columns
  (from `lexdiv_norm_spec()`). When `NULL`, defaults to all plain
  numeric columns in `norms` other than `key`, sanitizing non-identifier
  column names (such as `"%_known"` to `"pct_known"`).

- resource:

  Named list of 8 resource-metadata fields from
  `lexdiv_resource_meta()`.

- weightings:

  A non-empty subset of `c("token", "type")`.

- id_col:

  Document-ID column name for multi-document data-frame input.

- term_col:

  Term list-column name for multi-document data-frame input (default
  `"terms"`), or token column name for tokenization input (defaults to
  `"surface"` when omitted).

- max_rows:

  Positive whole-number row bound checked before allocation.

- value_column, measure_id, construct_id, value_unit, direction,
  language, variety, population_id, collection_year, valid_min,
  valid_max:

  Vectorized or scalar fields recycled across `value_column` by
  `lexdiv_norm_spec()`.

- resource_id, resource_version, creator, source_reference,
  data_license, transformation_id, lookup_unit,
  resource_key_normalization_id:

  Scalar provenance fields assembled by `lexdiv_resource_meta()`.

- ...:

  Additional arguments passed to
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html).

## Value

For a single document, `lexdiv_norm_profile()` returns a
`lexdiv_norm_profile` list with `status`, `summary`, `lookup`,
`coverage`, `provenance`, and `diagnostics`. For multiple documents, it
returns a `lexdiv_norm_profile_batch` list with document-major
`summary`, `lookup`, and `coverage` tables. `lexdiv_norm_spec()` returns
an 11-column specification data frame. `lexdiv_resource_meta()` returns
an 8-element metadata list.
[`print()`](https://rdrr.io/r/base/print.html) returns `x` invisibly.

## See also

[`nj8_profile`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/nj8_profile.md),
[`tubelex_profile`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/tubelex_profile.md)

## Examples

``` r
norms <- data.frame(
  term = c("book", "read", "rare"),
  familiarity = c(6, 5, NA_real_),
  aoa = c(4.2, 5.0, 11.5),
  note = c("noun", "verb", "adj")
)

# Single document (non-numeric 'note' column is ignored automatically):
quick <- lexdiv_norm_profile(c("book", "book", "rare", "unknown"), norms, "term")
quick
#> <lexdiv_norm_profile: ok; caller_norms@unspecified; 2 measures; 8 lookup rows; schema 0.1.0>
#>   measure_id weighting estimate status missing_reason resource_coverage
#>  familiarity     token 6.000000     ok           <NA>         0.7500000
#>  familiarity      type 6.000000     ok           <NA>         0.6666667
#>          aoa     token 6.633333     ok           <NA>         0.7500000
#>          aoa      type 7.850000     ok           <NA>         0.6666667
#>  annotation_coverage
#>            0.6666667
#>            0.5000000
#>            1.0000000
#>            1.0000000
#> Means are conditional on observed matched values; inspect $coverage.

# Multiple documents with explicit metadata:
specs <- lexdiv_norm_spec(
  c("familiarity", "aoa"),
  direction = c("higher", "lower"),
  valid_min = c(1, 0),
  valid_max = c(7, 25)
)
meta <- lexdiv_resource_meta("example_norms", resource_version = "2025-01")
batch <- lexdiv_norm_profile(
  list(d1 = c("book", "read"), d2 = c("rare", "unknown")),
  norms, "term", specs, meta
)
batch$summary[, c("document_id", "measure_id", "weighting", "estimate")]
#>   document_id  measure_id weighting estimate
#> 1          d1 familiarity     token      5.5
#> 2          d1 familiarity      type      5.5
#> 3          d1         aoa     token      4.6
#> 4          d1         aoa      type      4.6
#> 5          d2 familiarity     token       NA
#> 6          d2 familiarity      type       NA
#> 7          d2         aoa     token     11.5
#> 8          d2         aoa      type     11.5
```
