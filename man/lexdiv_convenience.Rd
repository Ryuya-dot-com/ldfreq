\name{lexdiv_convenience}
\alias{lexdiv_convenience}
\alias{lexdiv_as_documents}
\alias{lexdiv_widen}
\alias{print.lexdiv_wide_results}
\alias{plot.lexdiv_results}
\alias{plot.lexdiv_batch_results}
\alias{plot.lexdiv_profile_results}
\alias{plot.lexdiv_profile_batch_results}
\alias{plot.lexdiv_screen_results}
\alias{plot.tubelex_frequency_profile}
\title{Adapt, Reshape, and Plot Lexical-Diversity Results}
\usage{
lexdiv_as_documents(
  x,
  document_col = "document_id",
  token_col = "token"
)

lexdiv_widen(
  x,
  id_cols = NULL,
  names_from = NULL,
  values_from = c(
    "value", "status", "missing_reason", "method_id",
    "below_quality_floor"
  )
)

\method{print}{lexdiv_wide_results}(x, ...)

\method{plot}{lexdiv_results}(
  x,
  metric_id = NULL,
  request_id = NULL,
  col = NULL,
  pch = 19,
  main = NULL,
  xlab = "",
  ylab = NULL,
  ...
)

\method{plot}{lexdiv_batch_results}(
  x,
  metric_id = NULL,
  request_id = NULL,
  col = NULL,
  pch = 19,
  main = NULL,
  xlab = "",
  ylab = NULL,
  ...
)

\method{plot}{lexdiv_profile_results}(
  x,
  metric_id = NULL,
  request_id = NULL,
  col = NULL,
  pch = 19,
  main = NULL,
  xlab = "",
  ylab = NULL,
  ...
)

\method{plot}{lexdiv_profile_batch_results}(
  x,
  metric_id = NULL,
  request_id = NULL,
  col = NULL,
  pch = 19,
  main = NULL,
  xlab = "",
  ylab = NULL,
  ...
)

\method{plot}{lexdiv_screen_results}(
  x,
  screen_id = NULL,
  col = NULL,
  pch = 19,
  main = "Token-count screen",
  xlab = "document / request",
  ylab = "tokens",
  ...
)

\method{plot}{tubelex_frequency_profile}(
  x,
  col = "#0072B2",
  main = "TUBELEX match coverage",
  ylab = "coverage",
  ...
)
}
\arguments{
  \item{x}{For \code{lexdiv_as_documents()}, a named list, a data frame with
  one token per row, or a \pkg{quanteda} tokens object. For the other methods,
  a supported result object.}
  \item{document_col}{The document-ID column in tidy data-frame input.}
  \item{token_col}{The plain character token column in tidy data-frame input.}
  \item{id_cols}{Columns identifying output rows. The default is
  \code{document_id} when present and no ID column otherwise.}
  \item{names_from}{The column supplying wide field names. The default is
  \code{request_id} for profiles and \code{metric_id} otherwise.}
  \item{values_from}{One or more result columns to widen.}
  \item{metric_id}{One exact metric ID to plot. It can be omitted only when the
  result contains one metric.}
  \item{request_id}{An optional profile request ID to select.}
  \item{screen_id}{One screen to plot. It can be omitted only when the result
  contains one screen.}
  \item{col, pch, main, xlab, ylab}{Base-graphics settings. By default metric
  results below their advisory token floor are orange and other finite results
  are blue.}
  \item{...}{Additional arguments passed to the underlying base print or plot
  function.}
}
\description{
Provides explicit convenience operations around the versioned computation
core. Adapters expose document and token order; wide reshaping does not
recompute values; plot methods select one metric so incompatible metric scales
are not silently compared.
}
\details{
\code{lexdiv_as_documents()} groups tidy token rows by first document
appearance while preserving row order within each document. A \pkg{quanteda}
tokens object is converted through its registered \code{as.list()} method, so
\pkg{ldfreq} does not add a runtime dependency on \pkg{quanteda}. Raw text is
not tokenized by this adapter.

\code{lexdiv_widen()} uses profile \code{request_id} values when available,
which prevents parameter variants of the same metric from colliding. With one
\code{values_from} field, the output columns are named directly by metric or
request. With multiple fields they use \code{ID__field}. Duplicate output
cells are rejected rather than silently aggregated.

Metric plots include only finite rows with \code{status = "ok"}. TUBELEX plots
show token- and type-weighted match coverage on a fixed zero-to-one scale. All
plot methods return the plotted data invisibly for testing and reuse.
}
\value{
\code{lexdiv_as_documents()} returns a plain named list of plain character
vectors. \code{lexdiv_widen()} returns a \code{lexdiv_wide_results} data frame.
Print returns its input invisibly. Plot methods return their plot-data frame
invisibly.
}
\examples{
tidy_tokens <- data.frame(
  document_id = c("a", "a", "b", "b"),
  token = c("one", "two", "three", "three")
)
documents <- lexdiv_as_documents(tidy_tokens)
long <- lexdiv_metrics_batch(documents, metrics = c("ttr", "maas"))
lexdiv_widen(long, values_from = "value")

plot(long, metric_id = "ttr")

profile <- tubelex_frequency_profile(c("the", "not-in-resource"))
plot(profile)
}
