\name{lexdiv_screen_lengths}
\alias{lexdiv_screen_lengths}
\title{Evaluate Independent Token-Count Screens Without Modifying Metric Values}
\description{
Describes which rows in a plan-based lexical-diversity result meet declared
token-count floors (and optionally at least one complete MTLD factor in both
directions) without removing or altering any metric calculation.
}
\usage{
lexdiv_screen_lengths(
  x,
  floors = c(tokens_50 = 50L, tokens_100 = 100L),
  require_mtld_factors = FALSE,
  max_rows = 2e+06
)
}
\arguments{
  \item{x}{A plan-based result returned by \code{\link{lexdiv_metrics}} or
  \code{\link{lexdiv_metrics_text}}.}
  \item{floors}{A non-empty named numeric vector of positive integer token-count
  screens. Names become \code{screen_id}; values become \code{minimum_tokens}.}
  \item{require_mtld_factors}{Logical; if \code{TRUE}, MTLD rows with
  \code{mtld_tail_only = TRUE} (zero complete factors in either direction) also
  receive \code{passes_screen = FALSE}.}
  \item{max_rows}{A positive integer bound on source-row-by-floor output rows,
  checked before allocation.}
}
\value{
A \code{lexdiv_screen_results} data frame with one row per source result and
named floor, containing \code{screen_id}, \code{minimum_tokens}, \code{N},
\code{mtld_tail_only}, and \code{passes_screen}. It deliberately omits metric
values so screening remains independent of score inspection.
}
\examples{
plan <- lexdiv_plan(presets = character(), specs = list(
  lexdiv_spec("ttr", request_id = "ttr")
))
res <- lexdiv_metrics_text(
  c(short = "a b c", longer = paste(rep("word", 60), collapse = " ")),
  plan = plan
)
screens <- lexdiv_screen_lengths(res)
screens[, c("document_id", "screen_id", "N", "minimum_tokens", "passes_screen")]
}
\seealso{\code{\link{lexdiv_plan}}, \code{\link{lexdiv_length_evidence}}}
\keyword{text}
