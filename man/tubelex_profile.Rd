\name{tubelex_profile}
\alias{tubelex_profile}
\alias{print.tubelex_profile}
\alias{print.tubelex_profile_batch}
\alias{plot.tubelex_profile_batch}
\title{Coverage-Aware TUBELEX Frequency and Prevalence Profile}
\description{
Look up surface-form frequency, video prevalence, and channel prevalence for one
document or a multi-document corpus in the byte-pinned TUBELEX-EN Treebank
aggregate downloaded separately via \code{\link{lexdiv_download_resources}}.
}
\usage{
tubelex_profile(
  x,
  normalization = "tubelex",
  tokenization_mismatch = "error",
  id_col = "document_id",
  term_col = "terms",
  max_rows = 1e+06,
  cache_dir = NULL
)

\method{print}{tubelex_profile}(x, ...)

\method{print}{tubelex_profile_batch}(x, ...)

\method{plot}{tubelex_profile_batch}(
  x,
  weighting = c("token", "type"),
  col = "#0072B2",
  main = NULL,
  ylab = NULL,
  ...,
  monochrome = FALSE
)
}
\arguments{
\item{x}{For a single document, an ordered character vector of Treebank-aligned
terms or a \code{lexdiv_tokenization} object (with
\code{tokenization_mismatch = "allow"}). For multiple documents, a named list of
term vectors/tokenizations, a \code{lexdiv_tokenization_batch} object, or a data
frame/tibble with \code{id_col} and \code{term_col}. For \code{print()} and
\code{plot()}, a \code{tubelex_profile} or \code{tubelex_profile_batch} object.}
\item{normalization}{\code{"tubelex"}, \code{"tubelex_apostrophe"}, or
\code{"identity"}.}
\item{tokenization_mismatch}{\code{"error"} (default) or \code{"allow"}.}
\item{id_col, term_col}{Column names for multi-document data-frame input.}
\item{max_rows}{Positive whole-number row bound checked before resource loading.}
\item{cache_dir}{Optional directory containing downloaded optional resources.}
\item{weighting}{Weighting (\code{"token"} or \code{"type"}) for batch coverage
barplot.}
\item{col, main, ylab}{Base-R barplot styling arguments.}
\item{monochrome}{Logical switch for black/grey barplot styling.}
\item{...}{Additional arguments passed to \code{print.data.frame()} or
\code{graphics::barplot()}.}
}
\value{
For a single document, \code{tubelex_profile()} returns a \code{tubelex_profile}
list containing \code{status}, \code{failure_reason}, \code{summary},
\code{lookup}, \code{coverage}, \code{provenance}, and \code{diagnostics}.

For multiple documents, \code{tubelex_profile()} returns a structured
\code{tubelex_profile_batch} object containing document-major \code{summary},
\code{lookup}, and \code{coverage} tables alongside \code{profiles} (the
input-ordered named list of complete per-document \code{tubelex_profile}
objects), \code{provenance}, and \code{diagnostics}.
}
\examples{
if (all(lexdiv_resource_info("tubelex")$available)) {
  tokens <- c("I", "do", "n't", "think", "it", "'s", "John", "'s", "book")
  profile <- tubelex_profile(tokens)
  print(profile)

  batch <- tubelex_profile(list(d1 = tokens, d2 = c("hello", "world")))
  print(batch)
  plot(batch)
}
}
\seealso{\code{\link{tubelex_diagnostics}}, \code{\link{lexdiv_download_resources}}}
\keyword{text}
