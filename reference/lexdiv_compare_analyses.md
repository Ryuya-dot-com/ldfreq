# Inspect differences between saved analysis conditions

Measurement equality concerns definitions, preprocessing and resources,
not research validity. Different configurations can be compared
deliberately in sensitivity analyses; this function never pools or
removes observations. Length differences are cautions, not universal
exclusion thresholds. Equal settings do not establish comparable tasks,
populations or independent units. Length checks include both the batch
distribution and counts for shared document IDs. A shared ID alone does
not establish paired observations. Difference values use JSON and
require the optional package `jsonlite`.

## Usage

``` r
lexdiv_compare_analyses(x, y)
```

## Arguments

- x, y:

  Analysis records or paths to their JSON exports.

## Value

A list with `measurement` (`"same"` or `"different"`),
`study_comparability = "not_established"`, and a `differences` data
frame with field, severity, left/right values and an explanation.
Malformed or unsupported records fail validation rather than being
labelled comparable.

## Examples

``` r
recipe <- lexdiv_recipe(lexdiv_plan(presets = character(), specs = lexdiv_spec("ttr")))
a <- lexdiv_run_recipe(c(a = "One short text."), recipe)
b <- lexdiv_run_recipe(c(b = "A different and somewhat longer text."), recipe)
if (requireNamespace("jsonlite", quietly = TRUE)) lexdiv_compare_analyses(a, b)
#> $measurement
#> [1] "same"
#> 
#> $study_comparability
#> [1] "not_established"
#> 
#> $differences
#>                   field severity left right
#> 1 selected_token_counts  caution    3     6
#>                                                                                                      explanation
#> 1 Document counts or length distributions differ. Evaluate length sensitivity for each measure and study design.
#> 
```
