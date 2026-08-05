\name{tubelex_frequency_profile}
\alias{tubelex_frequency_profile}
\title{Coverage-aware TUBELEX frequency and prevalence profile}
\description{
Look up surface-form frequency, video prevalence, and channel prevalence in the
byte-pinned TUBELEX-EN Treebank aggregate bundled with \pkg{ldfreq}.
}
\usage{
tubelex_frequency_profile(terms, normalization = "tubelex")
}
\arguments{
\item{terms}{A plain ordered character vector, or an object returned by
\code{lexdiv_tokenize()}. Order and duplicate tokens are retained.}
\item{normalization}{\code{"tubelex"} applies the recorded NFKC, trim, and
locale-fixed English lowercase query transform. \code{"identity"} performs an
exact case- and normalization-sensitive lookup.}
}
\details{
Unmatched terms remain missing. They are not converted to zero counts or to a
maximum-sophistication category. Summary means are therefore conditional on
matched terms and must be interpreted beside token and type coverage.

The token-weighted row retains repetition in the input. The type-weighted row
uses each distinct normalized lookup term once. The output records both the
original and normalized type counts so that normalization-induced collisions
remain visible.

TUBELEX is a general YouTube subtitle frequency space. Its values are relative
to that corpus and are not direct measures of proficiency, writing quality,
academic register, or context-independent lexical sophistication.
}
\value{
A \code{tubelex_frequency_profile} list containing \code{status},
\code{failure_reason}, token- and type-weighted \code{summary}, lossless
\code{lookup} rows, \code{coverage}, versioned \code{provenance}, and
\code{diagnostics}.
}
\examples{
tokens <- lexdiv_tokenize("The apple and the missingword.")
profile <- tubelex_frequency_profile(tokens)
profile$summary
profile$coverage
profile$lookup
}
\seealso{\code{\link{lexdiv_tokenize}}, \code{\link{lexdiv_metrics_text}}}
\keyword{text}
