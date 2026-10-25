# Prepare and display lexical-diversity results

Choose the operation you need:

- Prepare token input:

  [`lexdiv_as_documents`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_as_documents.md)
  converts token containers to named documents without tokenizing raw
  prose.

- Make a wide table:

  [`lexdiv_widen`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_widen.md)
  retains selected values, statuses and measurement conditions without
  recomputing scores.

- Draw results:

  [`plot.lexdiv_results`](https://ryuya-dot-com.github.io/ldfreq/reference/plot.lexdiv_results.md)
  selects one metric or length screen, or draws TUBELEX coverage.

These operations preserve the original result. Save the complete result
as RDS when retaining all diagnostics and provenance matters.

## See also

[`lexdiv_metrics`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md),
[`lexdiv_study_table`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_study_table.md).
