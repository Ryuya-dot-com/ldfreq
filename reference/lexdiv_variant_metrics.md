# Explicit Maas and sequential-MTLD comparison variants

List or compute a bounded set of formula and aggregation variants
without changing the versioned thirteen-method
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

Use `lexdiv_methods(scope = "variants")` to discover this catalog from
the common method-listing entry point. `lexdiv_variant_ids()` remains
supported and returns the same data frame. These IDs are selected with
`lexdiv_variant_metrics(variants = ...)`; they are not all accepted by
[`lexdiv_spec()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
or
[`lexdiv_plan()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md).

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

catalog <- lexdiv_methods(scope = "variants")
catalog

variants <- lexdiv_variant_metrics(
  tokens,
  mtld_thresholds = c(0.72, 0.92)
)
variants[, c("family", "method_id", "value", "status")]

contract_path <- system.file(
  "spec", "lexical-diversity-variant-contract.json", package = "ldfreq"
)
stopifnot(nzchar(contract_path))
basename(contract_path)
```
