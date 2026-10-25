\name{lexdiv_widen}
\alias{lexdiv_widen}
\alias{print.lexdiv_wide_results}
\title{Reshape metric results without recomputing values}
\usage{
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
}
\arguments{
\item{x}{A supported lexical-diversity result table.}
\item{id_cols}{Columns identifying rows. Defaults to \code{document_id}
 when present and no ID column otherwise.}
\item{names_from}{The column supplying wide field names. Defaults to
 \code{request_id} for profiles and \code{metric_id} otherwise.}
\item{values_from}{One or more result columns to widen.}
\item{mtld_diagnostics}{One \code{TRUE} or \code{FALSE}. Append scalar
 diagnostics for core sequential bidirectional MTLD, including saved legacy
 min10 results. Defaults to \code{FALSE}.}
\item{...}{Additional arguments passed to \code{print.data.frame()}.}
}
\description{Creates one row per document or declared identifier, retaining
selected values, statuses and measurement conditions. Duplicate cells or
incompatible specifications are errors.}
\value{A \code{lexdiv_wide_results} data frame. Print returns its input invisibly.}
\details{
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

For planned writer/task/occasion observations, first use the complete
plan-based batch result with \code{\link{lexdiv_study_table}}, then select a
response with \code{\link{lexdiv_study_model_data}}. The wide display table
does not replace that function's full measurement input or observation roster.
}
\examples{
long <- lexdiv_metrics_batch(list(a = c("one", "two", "one"),
  b = c("one", "two", "three")), metrics = c("ttr", "maas"))
lexdiv_widen(long)
lexdiv_widen(long, values_from = "value")

# Constructed short input illustrates support, not score reliability.
supported <- lexdiv_metrics_batch(list(
  one_tail = c(letters[1:8], "a", "a"), empty = character()), metrics = "mtld")
wide <- lexdiv_widen(supported, values_from = c("value", "status", "N"),
  mtld_diagnostics = TRUE)
wide[c("document_id", "mtld__value", "mtld__status",
  "mtld__tail_only", "mtld__gap_pct")]
}
\seealso{\code{\link{lexdiv_metrics_batch}}, \code{\link{lexdiv_study_table}}.}
