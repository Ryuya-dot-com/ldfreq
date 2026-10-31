\name{lexdiv_flemmatize}
\alias{lexdiv_flemmatize}
\alias{lexdiv_flemmatize_batch}
\title{Add Flemmas from a Caller-Supplied AntBNC Lemma List}
\description{
Maps token surface forms to family lemmas (flemmas) using a local AntBNC
lemma-list file on either a single tokenization (\code{lexdiv_flemmatize()}) or
a named batch of tokenizations (\code{lexdiv_flemmatize_batch()}).
}
\usage{
lexdiv_flemmatize(
  x,
  resource,
  overrides = NULL,
  normalization = "nfkc_lower",
  resource_version = NULL,
  override_version = NULL
)

lexdiv_flemmatize_batch(
  documents,
  resource,
  overrides = NULL,
  normalization = "nfkc_lower",
  resource_version = NULL,
  override_version = NULL
)
}
\arguments{
  \item{x}{An object created by \code{\link{lexdiv_tokenize}}.}
  \item{documents}{A named list of \code{lexdiv_tokenization} objects (such as
  from \code{\link{lexdiv_tokenize_batch}}).}
  \item{resource}{Path to a caller-supplied AntBNC lemma-list text file in
  \code{headword<TAB>-><TAB>form...} format.}
  \item{overrides}{Optional data frame with unique \code{form} and
  \code{flemma} columns.}
  \item{normalization}{\code{"nfkc_lower"} (default) or \code{"identity"}.}
  \item{resource_version, override_version}{Optional path-free caller version
  labels.}
}
\value{
\code{lexdiv_flemmatize()} returns a \code{lexdiv_tokenization} object with
\code{flemma}, \code{flemma_matched}, and \code{flemma_match_rule} columns.
\code{lexdiv_flemmatize_batch()} returns an input-ordered named list of
flemma-annotated \code{lexdiv_tokenization} objects.
}
\examples{
fixture <- tempfile(fileext = ".txt")
writeLines(c("cat\t->\tcat\tcats", "see\t->\tsaw\tsee", "the\t->\tthe"),
  fixture, useBytes = TRUE)

batch <- lexdiv_tokenize_batch(c(d1 = "The cats saw.", d2 = "Cats see."))
flem_batch <- lexdiv_flemmatize_batch(
  batch, fixture, resource_version = "synthetic-help-fixture"
)
unlink(fixture)

lexdiv_metrics_text_batch(flem_batch, unit = "flemma", metrics = "ttr")$results
}
\seealso{\code{\link{lexdiv_preprocessing}}, \code{\link{nj8_profile}}}
\keyword{text}
