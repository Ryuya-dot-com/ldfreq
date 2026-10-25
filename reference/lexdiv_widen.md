# Reshape metric results without recomputing values

Creates one row per document or declared identifier, retaining selected
values, statuses and measurement conditions. Duplicate cells or
incompatible specifications are errors.

## Usage

``` r
lexdiv_widen(
  x,
  id_cols = NULL,
  names_from = NULL,
  values_from = c(
    "value", "status", "missing_reason", "method_id",
    "below_quality_floor", "metric_contract_id", "metric_contract_version",
    "requested_parameters", "effective_parameters", "N", "V"
  ),
  mtld_diagnostics = FALSE
)

# S3 method for class 'lexdiv_wide_results'
print(x, ...)
```

## Arguments

- x:

  A supported lexical-diversity result table.

- id_cols:

  Columns identifying rows. Defaults to `document_id` when present and
  no ID column otherwise.

- names_from:

  The column supplying wide field names. Defaults to `request_id` for
  profiles and `metric_id` otherwise.

- values_from:

  One or more result columns to widen.

- mtld_diagnostics:

  One `TRUE` or `FALSE`. Append scalar diagnostics for core sequential
  bidirectional MTLD, including saved legacy min10 results. Defaults to
  `FALSE`.

- ...:

  Additional arguments passed to
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html).

## Value

A `lexdiv_wide_results` data frame. Print returns its input invisibly.

## Details

`lexdiv_widen()` uses profile `request_id` values when available, and
checks that every output column has one contract, method, and requested
parameter identity. A request ID is only a plan-local label; combining
plans with reused labels and different parameters is rejected. Use
`names_from = "specification_id"` to give those conditions separate
columns. Default output retains parameters, contract identity, and N/V.
With one `values_from` field, the output columns are named directly by
metric or request. With multiple fields they use `ID__field`. Duplicate
output cells are rejected rather than silently aggregated.

With `mtld_diagnostics = TRUE`, eight scalar columns are appended for
each supported MTLD specification only: `ID__forward_score`,
`ID__reverse_score`, `ID__forward_complete_factors`,
`ID__reverse_complete_factors`, `ID__forward_tail_credit`,
`ID__reverse_tail_credit`, `ID__tail_only` and `ID__gap_pct`. Ordinary
column names do not change, including when `values_from = "value"`. The
first six fields copy existing diagnostics; absent or
nonscalar/nonfinite numeric fields become `NA`. Recorded zero counts
remain zero. The last two fields use the same calculation as the compact
print method: `tail_only` indicates zero complete factors in at least
one direction; `gap_pct` is
`100 * abs(forward_score - reverse_score) / mean(c(forward_score, reverse_score))`.
Both require finite directional scores and complete-factor counts; a
nonpositive mean leaves the gap missing. The gap describes order
sensitivity, not a standard error or confidence interval. It can be zero
when both directions depend entirely on their tails. Missing diagnostics
are not recomputed, and no rows are removed. These fields support the
core no-minimum and legacy min10 linear-tail methods; they do not
reinterpret diagnostics from other MTLD variants. Zero-row inputs retain
only the requested ID columns. Keep the original long result in RDS to
preserve all diagnostics and provenance; selected scalar columns can be
saved as CSV for analysis.

For planned writer/task/occasion observations, first use the complete
plan-based batch result with
[`lexdiv_study_table`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_study_table.md),
then select a response with
[`lexdiv_study_model_data`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_study_table.md).
The wide display table does not replace that function's full measurement
input or observation roster.

## See also

[`lexdiv_metrics_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md),
[`lexdiv_study_table`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_study_table.md).

## Examples

``` r
long <- lexdiv_metrics_batch(list(a = c("one", "two", "one"),
  b = c("one", "two", "three")), metrics = c("ttr", "maas"))
lexdiv_widen(long)
#> <lexdiv_wide_results: 2 rows; 23 columns>
#>   document_id ttr__value ttr__status ttr__missing_reason  ttr__method_id
#> 1           a  0.6666667          ok                <NA> ttr_v_over_n_v1
#> 2           b  1.0000000          ok                <NA> ttr_v_over_n_v1
#>   ttr__below_quality_floor       ttr__metric_contract_id
#> 1                    FALSE ldfreq-lexical-diversity-core
#> 2                    FALSE ldfreq-lexical-diversity-core
#>   ttr__metric_contract_version ttr__requested_parameters
#> 1                        0.2.0                          
#> 2                        0.2.0                          
#>   ttr__effective_parameters ttr__N ttr__V maas__value maas__status
#> 1                                3      2   0.3359422           ok
#> 2                                3      3   0.0000000           ok
#>   maas__missing_reason maas__method_id maas__below_quality_floor
#> 1                 <NA>   maas_a2_ln_v1                     FALSE
#> 2                 <NA>   maas_a2_ln_v1                     FALSE
#>        maas__metric_contract_id maas__metric_contract_version
#> 1 ldfreq-lexical-diversity-core                         0.2.0
#> 2 ldfreq-lexical-diversity-core                         0.2.0
#>   maas__requested_parameters maas__effective_parameters maas__N maas__V
#> 1                                                             3       2
#> 2                                                             3       3
lexdiv_widen(long, values_from = "value")
#> <lexdiv_wide_results: 2 rows; 3 columns>
#>   document_id       ttr      maas
#> 1           a 0.6666667 0.3359422
#> 2           b 1.0000000 0.0000000

# Constructed short input illustrates support, not score reliability.
supported <- lexdiv_metrics_batch(list(
  one_tail = c(letters[1:8], "a", "a"), empty = character()), metrics = "mtld")
wide <- lexdiv_widen(supported, values_from = c("value", "status", "N"),
  mtld_diagnostics = TRUE)
wide[c("document_id", "mtld__value", "mtld__status",
  "mtld__tail_only", "mtld__gap_pct")]
#> <lexdiv_wide_results: 2 rows; 5 columns>
#>   document_id mtld__value mtld__status mtld__tail_only mtld__gap_pct
#> 1    one_tail          12           ok            TRUE      33.33333
#> 2       empty          NA      missing              NA            NA
```
