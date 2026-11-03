\name{lexdiv_build_ngram_reference}
\alias{lexdiv_build_ngram_reference}
\alias{print.lexdiv_ngram_build}
\title{Build an N-gram Reference from Whole-Document Chunks}
\description{
Reads successive extractions and accumulates exact frequency and document
frequency without retaining every chunk's occurrence table.
}
\usage{
lexdiv_build_ngram_reference(
  sources,
  read_chunk,
  resource = lexdiv_resource_meta("caller_ngram_reference"),
  max_types = 1e6
)

\method{print}{lexdiv_ngram_build}(x, ...)
}
\arguments{
\item{sources}{Nonempty character vector of unique, nonempty UTF-8 source
labels, in processing order.}
\item{read_chunk}{Function taking one source label and returning an unmodified
\code{lexdiv_ngrams} result.}
\item{resource}{Resource metadata list created by \code{\link{lexdiv_resource_meta}}
or supplied explicitly.}
\item{max_types}{Positive whole-number limit on accumulated distinct n-gram
types across all requested \code{n}.}
\item{x}{A \code{lexdiv_ngram_build} object.}
\item{...}{Additional arguments passed to \code{print.data.frame()}.}
}
\value{
A \code{lexdiv_ngram_build} list containing \code{reference} (a complete
\code{lexdiv_ngram_reference}), \code{sources}, \code{documents}, and
\code{provenance}. \code{print()} displays reference totals and returns
\code{x} invisibly.
}
\examples{
documents <- list(first = c("make", "a", "choice"),
                  second = c("make", "a", "plan"))
read <- function(id) {
  tokens <- data.frame(document_id = id, segment_id = "s",
    token_index = seq_along(documents[[id]]), term = documents[[id]])
  lexdiv_ngrams(tokens, "authored-v1")
}
built <- lexdiv_build_ngram_reference(names(documents), read)
built
}
\seealso{\code{\link{lexdiv_ngrams}}, \code{\link{lexdiv_compare_ngrams}}}
\keyword{text}
