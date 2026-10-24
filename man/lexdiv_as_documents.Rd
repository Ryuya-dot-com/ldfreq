\name{lexdiv_as_documents}
\alias{lexdiv_as_documents}
\title{Convert token containers to named documents}
\usage{
lexdiv_as_documents(
  x,
  document_col = "document_id",
  token_col = "token"
)
}
\arguments{
\item{x}{A named list of plain character token vectors, a data frame with one
 token per row, or a \pkg{quanteda} tokens object. Raw text is not tokenized.}
\item{document_col}{The document-ID column in data-frame input.}
\item{token_col}{The plain character token column in data-frame input.}
}
\description{Preserves document identity and token order while converting
supported containers to the input used by \code{lexdiv_metrics_batch()}.}
\value{A plain named list of plain character vectors, preserving document and
 token order.}
\details{
\code{lexdiv_as_documents()} groups tidy token rows by first document
appearance while preserving row order within each document. A \pkg{quanteda}
tokens object is converted through its registered \code{as.list()} method, so
\pkg{ldfreq} does not add a runtime dependency on \pkg{quanteda}. Raw text is
not tokenized by this adapter.
Each selected ID or token column must occur exactly once. Empty lists and
zero-row token tables return the same named empty list, accepted by both
\code{lexdiv_metrics_batch()} and \code{lexdiv_profile_batch()}.
}
\examples{
tokens <- data.frame(document_id = c("a", "a", "b", "b"),
  token = c("one", "two", "three", "three"))
documents <- lexdiv_as_documents(tokens)
lexdiv_metrics_batch(documents, metrics = "ttr")
}
\seealso{\code{\link{lexdiv_metrics_batch}},
\code{\link{lexdiv_metrics_text_batch}} for raw text.}
