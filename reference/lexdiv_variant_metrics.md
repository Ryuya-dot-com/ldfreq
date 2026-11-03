# Explicit Maas and Sequential-MTLD Comparison Variants

Computes a bounded set of formula and aggregation variants without
changing the versioned thirteen-method
[`lexdiv_metrics`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
core. Discover available variant identifiers with
`lexdiv_methods(scope = "variants")`.

## Usage

``` r
lexdiv_variant_metrics(
  tokens,
  variants = lexdiv_methods(scope = "variants")$method_id,
  mtld_thresholds = 0.72
)

# S3 method for class 'lexdiv_variant_results'
print(x, ...)
```

## Arguments

- tokens:

  An ordered character vector accepted by
  [`lexdiv_metrics()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md).

- variants:

  A non-empty, duplicate-free character vector selected from
  `lexdiv_methods(scope = "variants")$method_id`.

- mtld_thresholds:

  One to 16 distinct finite numbers strictly between zero and one.

- x:

  A `lexdiv_variant_results` object.

- ...:

  Additional arguments passed to
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html).

## Value

A `lexdiv_variant_results` long data frame with formula, log-base,
factorization, status, and diagnostic columns.
[`print()`](https://rdrr.io/r/base/print.html) returns `x` invisibly.

## See also

[`lexdiv_methods`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_plan.md),
[`lexdiv_metrics`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)

## Examples

``` r
tokens <- c(rep("a", 10), "b", "c", "d", "e")
catalog <- lexdiv_methods(scope = "variants")
catalog
#>   family                                               method_id direction
#> 1   maas                                           maas_a2_ln_v1     lower
#> 2   maas                                            maas_a_ln_v1     lower
#> 3   maas                                        maas_a2_log10_v1     lower
#> 4   maas                                         maas_a_log10_v1     lower
#> 5   mtld          mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1    higher
#> 6   mtld     mtld_seq_bidir_dirmean_lt_min10_finaltail_linear_v1    higher
#> 7   mtld mtld_seq_bidir_mfl_dirmean_lt_min10_finaltail_linear_v1    higher
#> 8   mtld  mtld_seq_bidir_mfl_pooled_lt_min10_finaltail_linear_v1    higher
#>                    scale             reference_label
#> 1              a-squared            ldfreq-core:maas
#> 2                      a    common-formula:maas-a-ln
#> 3              a-squared            TAALED-0.32:maas
#> 4                      a common-formula:maas-a-log10
#> 5      tokens-per-factor      ldfreq-core-0.1.0:mtld
#> 6      tokens-per-factor           TAALED-0.32:mtldo
#> 7 adjusted-factor-length          TAALED-0.32:mtldav
#> 8 adjusted-factor-length            TAALED-0.32:mtld
#>                                                                      comparison_scope
#> 1                                                                  ldfreq-core-method
#> 2                                                             formula-comparison-only
#> 3               formula-aligned-with-taaled-0.32-maas-not-full-pipeline-compatibility
#> 4                                                             formula-comparison-only
#> 5                                                           legacy-ldfreq-core-method
#> 6 factorization-and-aggregation-comparator-for-taaled-0.32-not-official-compatibility
#> 7 factorization-and-aggregation-comparator-for-taaled-0.32-not-official-compatibility
#> 8 factorization-and-aggregation-comparator-for-taaled-0.32-not-official-compatibility

variants <- lexdiv_variant_metrics(tokens, mtld_thresholds = c(0.72, 0.92))
variants[, c("family", "method_id", "value", "status")]
#> <lexdiv_variant_results: 12 rows; contract 0.1.0>
#>    family                                               method_id     value
#> 1    maas                                           maas_a2_ln_v1 0.1478356
#> 2    maas                                            maas_a_ln_v1 0.3844940
#> 3    maas                                        maas_a2_log10_v1 0.3404041
#> 4    maas                                         maas_a_log10_v1 0.5834416
#> 5    mtld          mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1 8.9029126
#> 6    mtld          mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1 7.6746988
#> 7    mtld     mtld_seq_bidir_dirmean_lt_min10_finaltail_linear_v1 8.9029126
#> 8    mtld     mtld_seq_bidir_dirmean_lt_min10_finaltail_linear_v1 7.6746988
#> 9    mtld mtld_seq_bidir_mfl_dirmean_lt_min10_finaltail_linear_v1 7.8733333
#> 10   mtld mtld_seq_bidir_mfl_dirmean_lt_min10_finaltail_linear_v1 7.6066667
#> 11   mtld  mtld_seq_bidir_mfl_pooled_lt_min10_finaltail_linear_v1 7.1644444
#> 12   mtld  mtld_seq_bidir_mfl_pooled_lt_min10_finaltail_linear_v1 6.8088889
#>    status
#> 1      ok
#> 2      ok
#> 3      ok
#> 4      ok
#> 5      ok
#> 6      ok
#> 7      ok
#> 8      ok
#> 9      ok
#> 10     ok
#> 11     ok
#> 12     ok
```
