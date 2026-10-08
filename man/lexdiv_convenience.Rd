\name{lexdiv_convenience}
\alias{lexdiv_convenience}
\alias{lexdiv_as_documents}
\alias{lexdiv_widen}
\alias{print.lexdiv_wide_results}
\alias{plot.lexdiv_results}
\alias{plot.lexdiv_batch_results}
\alias{plot.lexdiv_profile_results}
\alias{plot.lexdiv_profile_batch_results}
\alias{plot.lexdiv_text_results}
\alias{plot.lexdiv_screen_results}
\alias{plot.tubelex_profile}
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
    "below_quality_floor", "metric_contract_id", "metric_contract_version",
    "requested_parameters", "effective_parameters", "N", "V"
  ),
  mtld_diagnostics = FALSE
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
  ...,
  monochrome = FALSE
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
  ...,
  monochrome = FALSE
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
  ...,
  monochrome = FALSE
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
  ...,
  monochrome = FALSE
)

\method{plot}{lexdiv_text_results}(x, ..., monochrome = FALSE)

\method{plot}{lexdiv_screen_results}(
  x,
  screen_id = NULL,
  col = NULL,
  pch = 19,
  main = NULL,
  xlab = "document / request",
  ylab = "tokens",
  ...,
  monochrome = FALSE
)

\method{plot}{tubelex_profile}(
  x,
  col = "#0072B2",
  main = NULL,
  ylab = "coverage",
  ...,
  monochrome = FALSE
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
  \item{mtld_diagnostics}{One \code{TRUE} or \code{FALSE}. Append scalar
  diagnostics for core sequential bidirectional MTLD, including saved legacy
  min10 results. The default \code{FALSE} retains the existing output.}
  \item{metric_id}{One exact metric ID to plot. It can be omitted only when the
  result contains one metric.}
  \item{request_id}{An optional profile request ID to select.}
  \item{screen_id}{One screen to plot. It can be omitted only when the result
  contains one screen.}
  \item{col, pch, main, xlab, ylab}{Base-graphics settings. By default metric
  results below their advisory token floor are orange and other finite results
  are blue.}
  \item{monochrome}{One \code{TRUE} or \code{FALSE} value; specify this argument by name. The default \code{FALSE} uses color. \code{TRUE} overrides \code{col} with black (gray for TUBELEX bars). In both color modes, unless \code{pch} is supplied, metric points below their advisory floor and screen points below their threshold use triangles; other points use circles.}
\item{...}{Additional arguments passed to the underlying base print or plot
  function.}
}
\description{
Provides explicit convenience operations around the versioned computation
core. Adapters expose document and token order; wide reshaping does not
recompute values; plot methods select one measurement specification so incompatible metric scales or parameters
are not silently compared.
}
\details{
\code{lexdiv_as_documents()} groups tidy token rows by first document
appearance while preserving row order within each document. A \pkg{quanteda}
tokens object is converted through its registered \code{as.list()} method, so
\pkg{ldfreq} does not add a runtime dependency on \pkg{quanteda}. Raw text is
not tokenized by this adapter.

\code{lexdiv_widen()} uses profile \code{request_id} values when available,
and checks that every output column has one contract, method, and requested
parameter identity. A request ID is only a plan-local label; combining plans
with reused labels and different parameters is rejected. Use
\code{names_from = "specification_id"} to give those conditions separate
columns. Default output retains parameters, contract identity, and N/V.
With one
\code{values_from} field, the output columns are named directly by metric or
request. With multiple fields they use \code{ID__field}. Duplicate output
cells are rejected rather than silently aggregated.

With \code{mtld_diagnostics = TRUE}, eight scalar columns are appended for each
supported MTLD specification only: \code{ID__forward_score},
\code{ID__reverse_score}, \code{ID__forward_complete_factors},
\code{ID__reverse_complete_factors}, \code{ID__forward_tail_credit},
\code{ID__reverse_tail_credit}, \code{ID__tail_only} and \code{ID__gap_pct}.
Ordinary column names do not change, including when \code{values_from = "value"}.
The first six fields copy existing diagnostics; absent or nonscalar/nonfinite
numeric fields become \code{NA}. Recorded zero counts remain zero.
The last two fields use the same calculation as the compact print method:
\code{tail_only} indicates zero complete factors in at least one direction;
\code{gap_pct} is \code{100 * abs(forward_score - reverse_score) /
mean(c(forward_score, reverse_score))}. Both require finite directional scores
and complete-factor counts; a nonpositive mean leaves the gap missing.
The gap describes order sensitivity, not a standard error or confidence
interval. It can be zero when both directions depend entirely on their tails.
Missing diagnostics are not recomputed, and no rows are removed.
These fields support the core no-minimum and legacy min10 linear-tail methods;
they do not reinterpret diagnostics from other MTLD variants. Zero-row inputs
retain only the requested ID columns. Keep the original long result in RDS to
preserve all diagnostics and provenance; selected scalar columns can be saved
as CSV for analysis.

Metric plots require a single specification, including when all rows share
the same metric ID. Select a request or subset the input by specification.
Their invisible return contains \code{label} followed by the complete selected
result rows, including parameter and contract columns. Missing results are
excluded from displayed points, but still participate in the specification check.
Metric plots include only finite rows with \code{status = "ok"}. TUBELEX plots
show token- and type-weighted match coverage on a fixed zero-to-one scale. All
plot methods return the plotted data invisibly for testing and reuse.
Plots have no automatic title. A sans serif font, horizontal tick labels and
an open frame are used by default. Override these with \code{family},
\code{las} or \code{bty} in \code{...}; cosmetic graphics parameters are
restored after drawing, including after an error. The default metric y-axis label is the uppercase metric ID.
Place figure numbers, titles and notes outside the image in the manuscript.
Explicit \code{main} remains available for custom base graphics.
\code{plot.lexdiv_text_results()} delegates to the unchanged
\code{results} component, so it accepts the same metric-selection arguments
and does not plot preprocessing coverage on a metric scale.
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

# A short constructed example exposes support; it is not a reliability example.
supported <- lexdiv_metrics_batch(list(
  one_tail = c(letters[1:8], "a", "a"), empty = character()
), metrics = "mtld")
wide <- lexdiv_widen(supported, values_from = c("value", "status", "N"),
  mtld_diagnostics = TRUE)
wide[c("document_id", "mtld__value", "mtld__status",
  "mtld__tail_only", "mtld__gap_pct")]

plot(long, metric_id = "ttr")
plot(long, metric_id = "ttr", monochrome = TRUE)

text_result <- lexdiv_metrics_text("Words repeat words.", metrics = "ttr")
plot(text_result)

profile <- tubelex_profile(c("the", "not-in-resource"))
plot(profile)
}
