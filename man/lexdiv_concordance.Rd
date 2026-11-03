\name{lexdiv_concordance}
\alias{lexdiv_concordance}
\alias{lexdiv_sort_concordance}
\alias{lexdiv_concordance_dispersion}
\alias{print.lexdiv_concordance}
\alias{print.lexdiv_dispersion}
\alias{plot.lexdiv_concordance}
\title{Search Source-Aligned Words and Phrases and Inspect Their Distribution}
\description{
Search complete annotations (from \code{\link{lexdiv_import_annotations}} or
\code{\link{lexdiv_as_annotations}}), preserving original text, token positions,
selection masks and zero-match documents. Sort saved contexts, draw Base-R
positional barcode plots, or compute single-token within-document dispersion.
}
\usage{
lexdiv_concordance(
  x,
  queries,
  term_col = "surface",
  valuetype = c("fixed", "glob", "regex"),
  case_insensitive = FALSE,
  keep = rep(TRUE, nrow(x$tokens)),
  window = 5L,
  max_cells = 1e6
)

lexdiv_sort_concordance(
  x,
  side = c("right", "left"),
  depth = 1L,
  case_insensitive = FALSE
)

lexdiv_concordance_dispersion(
  x,
  query_id = NULL,
  parts = 10L,
  max_cells = 1e6
)

\method{print}{lexdiv_concordance}(x, ...)

\method{print}{lexdiv_dispersion}(x, ...)

\method{plot}{lexdiv_concordance}(
  x,
  query_id = NULL,
  relative = TRUE,
  monochrome = FALSE,
  col = NULL,
  main = NULL,
  xlab = NULL,
  ylab = "",
  ...
)
}
\arguments{
\item{x}{For \code{lexdiv_concordance()}, an unmodified
\code{lexdiv_annotations} object. For sorting, dispersion, and plotting, an
unmodified \code{lexdiv_concordance} object. For \code{print.lexdiv_dispersion},
a \code{lexdiv_dispersion} object.}
\item{queries}{Named list with unique nonblank query IDs.}
\item{term_col}{Character token column to search, such as \code{"surface"},
\code{"term"} (from \code{lexdiv_as_annotations()}), or \code{"lemma"}.}
\item{valuetype}{Fixed, glob or regex matching through optional \pkg{quanteda}.}
\item{case_insensitive}{Logical switch for case-insensitive matching or sorting.}
\item{keep}{One nonmissing logical value per original token.}
\item{window}{Nonnegative number of context surface-token slots on each side.}
\item{max_cells}{Positive whole-number allocation bound.}
\item{side}{Context side to sort, nearest token first.}
\item{depth}{Positive number of context tokens used as successive sort keys.}
\item{query_id}{Saved query ID to inspect. Defaults to the sole query when
\code{x} contains exactly one query.}
\item{parts}{Number of within-document parts (integer >= 2).}
\item{relative}{Plot relative positions in \code{[0, 1]} (\code{TRUE}) or raw
token positions (\code{FALSE}).}
\item{monochrome}{Use black rather than default color.}
\item{col, main, xlab, ylab}{Base-R graphics styling parameters.}
\item{...}{Additional Base-R graphics or \code{print.data.frame()} arguments.}
}
\value{
\code{lexdiv_concordance()} returns a sealed \code{lexdiv_concordance} object.
\code{lexdiv_sort_concordance()} returns an ordered occurrence data frame.
\code{lexdiv_concordance_dispersion()} returns a \code{lexdiv_dispersion}
object with \code{documents} and \code{parts}. \code{plot()} draws a Base-R
positional plot and invisibly returns \code{list(occurrences, documents, counts)}.
}
\examples{
ann <- lexdiv_as_annotations(c(d1 = "Cats chase cats and dogs.", empty = ""))
if (requireNamespace("quanteda", quietly = TRUE)) {
  search <- lexdiv_concordance(ann, list(cat = "cats"), term_col = "term")
  print(search)
  lexdiv_sort_concordance(search, case_insensitive = TRUE)
  lexdiv_concordance_dispersion(search, parts = 3)
  plot(search)
}
}
\seealso{\code{\link{lexdiv_as_annotations}}, \code{\link{lexdiv_collocations}},
\code{\link{lexdiv_keyness}}}
\keyword{text}
