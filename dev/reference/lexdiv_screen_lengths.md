# Evaluate Independent Token-Count Screens Without Modifying Metric Values

Describes which rows in a plan-based lexical-diversity result meet
declared token-count floors (and optionally at least one complete MTLD
factor in both directions) without removing or altering any metric
calculation.

## Usage

``` r
lexdiv_screen_lengths(
  x,
  floors = c(tokens_50 = 50L, tokens_100 = 100L),
  require_mtld_factors = FALSE,
  max_rows = 2e+06
)
```

## Arguments

- x:

  A plan-based result returned by
  [`lexdiv_metrics`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_metrics.md)
  or
  [`lexdiv_metrics_text`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_preprocessing.md).

- floors:

  A non-empty named numeric vector of positive integer token-count
  screens. Names become `screen_id`; values become `minimum_tokens`.

- require_mtld_factors:

  Logical; if `TRUE`, MTLD rows with `mtld_tail_only = TRUE` (zero
  complete factors in either direction) also receive
  `passes_screen = FALSE`.

- max_rows:

  A positive integer bound on source-row-by-floor output rows, checked
  before allocation.

## Value

A `lexdiv_screen_results` data frame with one row per source result and
named floor, containing `screen_id`, `minimum_tokens`, `N`,
`mtld_tail_only`, and `passes_screen`. It deliberately omits metric
values so screening remains independent of score inspection.

## See also

[`lexdiv_plan`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_plan.md),
[`lexdiv_length_evidence`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_length_evidence.md)

## Examples

``` r
plan <- lexdiv_plan(presets = character(), specs = list(
  lexdiv_spec("ttr", request_id = "ttr")
))
res <- lexdiv_metrics_text(
  c(short = "a b c", longer = paste(rep("word", 60), collapse = " ")),
  plan = plan
)
screens <- lexdiv_screen_lengths(res)
screens[, c("document_id", "screen_id", "N", "minimum_tokens", "passes_screen")]
#>   document_id  screen_id  N minimum_tokens passes_screen
#> 1       short  tokens_50  3             50         FALSE
#> 2       short tokens_100  3            100         FALSE
#> 3      longer  tokens_50 60             50          TRUE
#> 4      longer tokens_100 60            100         FALSE
```
