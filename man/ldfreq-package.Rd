\name{ldfreq-package}
\alias{ldfreq}
\alias{ldfreq-package}
\docType{package}
\title{Reproducible Lexical Diversity Profiles}
\description{
The \pkg{ldfreq} package computes explicitly versioned lexical-diversity
metrics from ordered pre-tokenized character vectors. It returns canonical
long-form records with method, parameter, schema, and contract provenance.
}
\details{
The initial development release performs no tokenization, normalization,
lemmatization, or lexical-resource lookup. Start with \code{lexdiv_metrics()}
for one document, \code{lexdiv_metrics_batch()} for multiple documents, or
\code{lexdiv_profile()} for explicit parameter variants.
}
\seealso{
\code{\link{lexdiv_metrics}}, \code{\link{lexdiv_profile}}
}
\keyword{package}
