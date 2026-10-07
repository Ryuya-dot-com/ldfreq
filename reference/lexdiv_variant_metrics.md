# Explicit Maas and sequential-MTLD comparison variants

List or compute a bounded set of formula and aggregation variants
without changing the versioned twelve-method
[`lexdiv_metrics()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
core.

## Usage

``` r
lexdiv_variant_ids()

lexdiv_variant_metrics(
  tokens,
  variants = lexdiv_variant_ids()$method_id,
  mtld_thresholds = 0.72
)

# S3 method for class 'lexdiv_variant_results'
print(x, ...)
```

## Arguments

- tokens:

  A plain ordered character vector accepted by
  [`lexdiv_metrics()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md).

- variants:

  A plain, non-empty, duplicate-free character vector selected from the
  `method_id` column returned by `lexdiv_variant_ids()`.

- mtld_thresholds:

  One to 16 distinct finite numbers strictly between zero and one. Each
  requested MTLD method is expanded over these thresholds.

- x:

  A `lexdiv_variant_results` object.

- ...:

  Additional arguments passed to
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html).

## Details

The Maas rows distinguish \\a\\ from \\a^2\\ and natural-log from
base-10 definitions. These transformations are not numerically
interchangeable, even where they preserve rank order. For either
selected log base, `a_squared = (log(N) - log(V)) / log(N)^2`; the \\a\\
rows return its square root. For valid integer counts, the natural-log
\\a^2\\ variant ranges from zero to \\1 / \ln(2)\\ inclusive; changing
the log base or taking the square root changes that numerical range. The
method ID records both scale and log base.

The MTLD rows preserve the legacy core-contract 0.1.0 min10
directional-score mean and three final-tail factorization and
mean-factor-length aggregations. All four require at least ten tokens
per complete factor. The current no-minimum method is available
separately via `lexdiv_metrics(..., metrics = "mtld")`. Factor lengths
and proportions remain available in the diagnostics list-column.

Rows described as TAALED-relevant comparators identify only their
documented formula, factorization, and aggregation scope. They do not
assert official or end-to-end TAALED compatibility: preprocessing,
invalid-input policy, short-text handling, and licensed source-code
identity remain outside that claim. No third-party code is included or
translated.

## Formal contract

Every formula, log base, minimum-length rule, MTLD final-token rule,
factorization, and aggregation identity is installed in
`lexical-diversity-variant-contract.json`. Locate it with
`system.file("spec", "lexical-diversity-variant-contract.json", package = "ldfreq")`.
The `reference_label` and `comparison_scope` columns must remain
attached when results are reported.

## Value

`lexdiv_variant_ids()` returns a method catalog.
`lexdiv_variant_metrics()` returns a `lexdiv_variant_results` long data
frame. Maas rows occur once per method; MTLD rows occur once per
method-threshold combination. Contract identity, status, missing reason,
parameters, counts, reference label, comparison scope, and diagnostics
are explicit columns. The print method returns `x` invisibly.

## See also

[`lexdiv_metrics`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md),
[`lexdiv_preprocessing`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)

## Examples

``` r
tokens <- c(rep("a", 10), "b", "c", "d", "e")

catalog <- lexdiv_variant_ids()
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

variants <- lexdiv_variant_metrics(
  tokens,
  mtld_thresholds = c(0.72, 0.92)
)
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

contract_path <- system.file(
  "spec", "lexical-diversity-variant-contract.json", package = "ldfreq"
)
stopifnot(nzchar(contract_path))
basename(contract_path)
#> [1] "lexical-diversity-variant-contract.json"
```
