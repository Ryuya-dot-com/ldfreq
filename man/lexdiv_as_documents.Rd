\name{lexdiv_as_documents}
\alias{lexdiv_as_documents}
\title{Convert Token Containers to Named Documents}
\usage{
lexdiv_as_documents(
  x,
  id_col = "document_id",
  token_col = "token"
)
}
\arguments{
\item{x}{A named list of character token vectors, a data frame or tibble with
one token per row, or a \pkg{quanteda} tokens object. Raw text is not tokenized.}
\item{id_col}{The document-ID column in data-frame input.}
\item{token_col}{The plain character token column in data-frame input.}
}
\description{
Preserves document identity and token order while converting supported
containers to the named-list input used by \code{\link{lexdiv_metrics_batch}}.
}
\value{
A plain named list of character vectors, preserving document and token order.
}
\examples{
tokens <- data.frame(document_id = c("a", "a", "b", "b"),
  token = c("one", "two", "three", "three"))
documents <- lexdiv_as_documents(tokens)
lexdiv_metrics_batch(documents, metrics = "ttr")
}
\seealso{\code{\link{lexdiv_metrics_batch}}, \code{\link{lexdiv_metrics_text_batch}}}
