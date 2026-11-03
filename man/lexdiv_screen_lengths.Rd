\name{lexdiv_screen_lengths}
\alias{lexdiv_screen_lengths}
\title{Evaluate Independent Token-Count Screens Without Modifying Metric Values}
\description{
Describes which rows in a plan-based lexical-diversity result meet declared
token-count floors without removing or altering any metric calculation.
}
\usage{
lexdiv_screen_lengths(
  x,
  floors = c(tokens_50 = 50L, tokens_100 = 100L),
  max_rows = 2e+06
)
}
\arguments{
  \item{x}{A plan-based result returned by \code{\link{lexdiv_metrics}},
  \code{\link{lexdiv_metrics_batch}}, \code{\link{lexdiv_metrics_text}}, or
  \code{\link{lexdiv_metrics_text_batch}}.}
  \item{floors}{A non-empty named numeric vector of positive integer token-count
  screens. Names become \code{screen_id}; values become \code{minimum_tokens}.}
  \item{max_rows}{A positive integer bound on source-row-by-floor output rows,
  checked before allocation.}
}
\value{
A \code{lexdiv_screen_results} data frame with one row per source result and
named floor, containing \code{screen_id}, \code{minimum_tokens}, \code{N}, and
\code{passes_screen}. It deliberately omits metric values so screening remains
independent of score inspection.
}
\examples{
plan <- lexdiv_plan(presets = character(), specs = list(
  lexdiv_spec("ttr", request_id = "ttr")
))
res <- lexdiv_metrics_text_batch(
  c(short = "a b c", longer = paste(rep("word", 60), collapse = " ")),
  plan = plan
)
screens <- lexdiv_screen_lengths(res)
screens[, c("document_id", "screen_id", "N", "minimum_tokens", "passes_screen")]
}
\seealso{\code{\link{lexdiv_plan}}, \code{\link{lexdiv_length_evidence}}}
\keyword{text}
