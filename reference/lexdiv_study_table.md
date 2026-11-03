# Join Planned Observations to Saved Measurements and Select Model Rows

Preserve planned observations, submitted documents and measurement
identities in an ordinary research table, and select one response
specification with an explicit exclusion audit for statistical
modelling.

## Usage

``` r
lexdiv_study_table(
  planned,
  submissions,
  results,
  plan,
  condition_id,
  reporting = NULL,
  max_rows = 1e6
)

lexdiv_study_model_data(
  study,
  condition_id,
  request_id,
  required = c("writer_id", "task", "occasion")
)

# S3 method for class 'lexdiv_study_model_data'
print(x, ...)
```

## Arguments

- planned:

  Data frame or tibble with unique nonblank character `observation_id`,
  plus `writer_id`, `task` and `occasion`.

- submissions:

  Data frame or tibble with `observation_id` and `document_id`, plus
  `input_characters` (automatically populated from preprocessing
  provenance if omitted when `results` is a `lexdiv_text_batch_results`
  object).

- results:

  Complete result from
  [`lexdiv_metrics_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
  or
  [`lexdiv_metrics_text_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md),
  computed with `plan = plan`.

- plan:

  The explicit
  [`lexdiv_plan`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_plan.md)
  used for `results`.

- condition_id:

  Nonblank character label for the selected analysis condition.

- reporting:

  Optional data frame/tibble with `document_id`, `request_id`,
  `reporting_status`, and `reporting_reason`.

- max_rows:

  Positive whole-number row limit.

- study:

  Complete study table returned by `lexdiv_study_table()`.

- request_id:

  One request ID in the saved plan.

- required:

  Metadata column names required to be complete for model rows.

- x:

  A `lexdiv_study_model_data` object.

- ...:

  Additional arguments passed to
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html).

## Value

`lexdiv_study_table()` returns a data frame joining planned metadata,
submission/input/computation/reporting states, and measurement columns.
`lexdiv_study_model_data()` returns a `lexdiv_study_model_data` object
with `data` and `audit`. [`print()`](https://rdrr.io/r/base/print.html)
displays up to 12 selected model rows and returns `x` invisibly.

## See also

[`lexdiv_metrics_text_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md),
[`lexdiv_plan`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_plan.md)

## Examples

``` r
plan <- lexdiv_plan(presets = character(), specs = list(
  lexdiv_spec("ttr", request_id = "ttr")
))
planned <- data.frame(
  observation_id = c("o1", "o2"),
  writer_id = c("001", "002"),
  task = "essay",
  occasion = 1
)
submissions <- data.frame(observation_id = "o1", document_id = "d1")
results <- lexdiv_metrics_text_batch(c(d1 = "Cats chase cats."), plan = plan)
reporting <- data.frame(
  document_id = "d1", request_id = "ttr",
  reporting_status = "report", reporting_reason = "Planned specification"
)
study <- lexdiv_study_table(
  planned, submissions, results, plan, "surface-all", reporting
)
selected <- lexdiv_study_model_data(study, "surface-all", "ttr")
selected
#> <lexdiv_study_model_data: 1/2 observations included>
#>  observation_id writer_id  task occasion document_id request_id     value N
#>              o1       001 essay        1          d1        ttr 0.6666667 3
```
