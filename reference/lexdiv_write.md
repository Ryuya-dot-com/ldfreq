# Save and read portable recipes and analysis records

JSON preserves nested metadata and typed tables (column names, types and
arrays of values), including zero-row tables and character IDs. It
contains source text when saving an analysis. CSV is a scalar long
metric table: document x condition x request, with list columns encoded
as JSON strings. Keep the JSON record beside CSV; CSV alone is not a
reproducible analysis. Existing files are never overwritten. Unknown
schemas are rejected.

## Usage

``` r
lexdiv_write(x, path, format = c("json", "csv"))

lexdiv_read(path)
```

## Arguments

- x:

  A recipe or analysis produced by
  [`lexdiv_recipe()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_recipe.md)
  or
  [`lexdiv_run_recipe()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_run_recipe.md).

- path:

  Output or input file path.

- format:

  `"json"` for a recipe/analysis or `"csv"` for analysis metrics.

## Value

`lexdiv_write()` invisibly returns the output path. `lexdiv_read()`
returns a validated recipe or analysis without recalculating document
scores.

## Examples

``` r
if (requireNamespace("jsonlite", quietly = TRUE)) {
  recipe <- lexdiv_recipe(lexdiv_plan(presets = character(), specs = lexdiv_spec("ttr")))
  run <- lexdiv_run_recipe(c("001" = "One small example."), recipe)
  path <- tempfile(fileext = ".json")
  lexdiv_write(run, path)
  restored <- lexdiv_read(path)
  stopifnot(identical(restored$analysis$results, run$analysis$results))
  unlink(path)
}
```
