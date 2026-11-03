# Profile Terms with Caller-Supplied Lexical Norms

Computes token- and/or type-weighted arithmetic means for one or more
lexical-norm variables from matched observed keys while reporting
resource and annotation coverage separately.

## Usage

``` r
lexdiv_norm_profile(
  terms,
  norms,
  key,
  measure_specs = lexdiv_norm_spec(setdiff(names(norms), key)),
  resource = lexdiv_resource_meta("caller_norms"),
  weightings = c("token", "type"),
  max_rows = 1e+06
)

lexdiv_norm_spec(
  value_column,
  measure_id = value_column,
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
```

## Arguments

- terms:

  A character vector with one caller-prepared lookup term per element.
  Zero length and named vectors are allowed.

- norms:

  A data frame or tibble containing one unique key column and the
  numeric norm columns named by `measure_specs`.

- key:

  One string naming the exact-match key column in `norms`.

- measure_specs:

  Data frame or tibble of 11 measure-specification columns (in any
  column order). Defaults to:

      lexdiv_norm_spec(setdiff(names(norms), key))

- resource:

  Named list of 8 resource-metadata fields (in any field order), with
  default:

      lexdiv_resource_meta("caller_norms")

- weightings:

  A non-empty subset of `c("token", "type")`.

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

- x:

  A `lexdiv_norm_profile` object.

- ...:

  Additional arguments passed to
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html).

## Value

`lexdiv_norm_profile()` returns a `lexdiv_norm_profile` list with
`status`, `summary`, `lookup`, `coverage`, `provenance`, and
`diagnostics`. `lexdiv_norm_spec()` returns an 11-column specification
data frame. `lexdiv_resource_meta()` returns an 8-element metadata list.
[`print()`](https://rdrr.io/r/base/print.html) returns `x` invisibly.

## See also

[`lexdiv_norm_profile_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile_batch.md)

## Examples

``` r
norms <- data.frame(
  term = c("book", "read", "rare"),
  familiarity = c(6, 5, NA_real_),
  aoa = c(4.2, 5.0, 11.5)
)

# Concise call with automatic measure_specs and resource defaults:
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

# Explicit publication-ready metadata via helpers:
specs <- lexdiv_norm_spec(
  c("familiarity", "aoa"),
  direction = c("higher", "lower"),
  valid_min = c(1, 0),
  valid_max = c(7, 25)
)
meta <- lexdiv_resource_meta("example_norms", resource_version = "2025-01")
profile <- lexdiv_norm_profile(c("book", "read"), norms, "term", specs, meta)
profile$summary[, c("measure_id", "weighting", "estimate", "value_coverage")]
#>    measure_id weighting estimate value_coverage
#> 1 familiarity     token      5.5              1
#> 2 familiarity      type      5.5              1
#> 3         aoa     token      4.6              1
#> 4         aoa      type      4.6              1
```
