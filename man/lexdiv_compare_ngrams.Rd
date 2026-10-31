\name{lexdiv_compare_ngrams}
\alias{lexdiv_compare_ngrams}
\alias{print.lexdiv_ngram_comparison}
\title{Compare N-gram References on the Same Target Items}
\description{
Applies multiple reference frequency tables to one unchanged target extraction.
Reports each reference's coverage and available-value mean, then compares rates
on the items with defined values in every reference.
}
\usage{
lexdiv_compare_ngrams(x, references, baseline = NULL, max_rows = 1e6)

\method{print}{lexdiv_ngram_comparison}(x, ...)
}
\arguments{
\item{x}{For \code{lexdiv_compare_ngrams()}, an unmodified \code{lexdiv_ngrams}
result. For \code{print()}, a \code{lexdiv_ngram_comparison} object.}
\item{references}{A plain named list of at least two unmodified
\code{lexdiv_ngram_reference} results.}
\item{baseline}{One name in \code{references}. Defaults to the first reference.}
\item{max_rows}{Positive whole-number ceiling on combined lookup and summary
rows across references, checked before profiling.}
\item{...}{Additional arguments passed to \code{print.data.frame()}.}
}
\value{
A \code{lexdiv_ngram_comparison} list containing \code{summary}, \code{lookup},
\code{documents}, \code{references}, and \code{provenance} (with
\code{content_sha256}). \code{print()} displays up to 12 summary rows and
returns \code{x} invisibly.
}
\examples{
tokens <- data.frame(document_id = "item", segment_id = "s",
  token_index = 1:3, term = c("make", "a", "choice"))
target <- lexdiv_ngrams(tokens, "authored-v1", n = 2)
resource <- lexdiv_resource_meta(
  "authored_demo",
  lookup_unit = "adjacent_surface_ngram"
)
counts <- data.frame(n = 2L, term1 = c("make", "a"),
  term2 = c("a", "decision"), term3 = NA_character_, count = c(3, 2),
  document_count = c(2, 1))
totals <- data.frame(n = 2L, opportunities = 5, documents = 2)
full <- lexdiv_ngram_reference(counts, resource, totals, "authored-v1", TRUE)
partial <- lexdiv_ngram_reference(counts[1, ], resource, totals, "authored-v1", FALSE)
compared <- lexdiv_compare_ngrams(target, list(full = full, partial = partial))
compared
}
\seealso{\code{\link{lexdiv_ngrams}}, \code{\link{lexdiv_build_ngram_reference}}}
\keyword{text}
