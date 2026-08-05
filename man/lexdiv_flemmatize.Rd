\name{lexdiv_flemmatize}
\alias{lexdiv_flemmatize}
\title{Add flemmas from a caller-supplied AntBNC lemma list}
\description{
Maps token surface forms to family lemmas (flemmas) using a local AntBNC
lemma-list file. No resource is bundled or downloaded. Unknown forms retain
their normalized surface form so that downstream analyses keep them visible.
}
\usage{
lexdiv_flemmatize(
  x,
  resource,
  overrides = NULL,
  normalization = "nfkc_lower",
  resource_version = NULL
)
}
\arguments{
  \item{x}{An object created by \code{lexdiv_tokenize()}.}
  \item{resource}{Path to a caller-supplied AntBNC lemma-list text file in
  \code{headword<TAB>-><TAB>form...} format.}
  \item{overrides}{Optional data frame with unique \code{form} and
  \code{flemma} columns. Overrides are applied after resource lookup and before
  identity fallback.}
  \item{normalization}{\code{"nfkc_lower"} applies NFKC, trimming, and
  locale-fixed English lowercasing to resource entries, overrides, and queries.
  \code{"identity"} performs exact matching.}
  \item{resource_version}{Optional caller-supplied version label. If
  \code{NULL}, an exact-file-SHA-256 label is used.}
}
\details{
Flemma counting groups inflected forms without distinguishing part of speech.
It is therefore not interchangeable with a POS-sensitive lemma analysis.

The parser requires unique normalized headwords and a deterministic one-to-one
form-to-headword mapping. The output records whether each token used
\code{"antbnc"}, an explicit \code{"override"}, or normalized-surface
\code{"identity"} fallback. Identity fallback prevents an unknown resource
form from disappearing before an off-list or diversity analysis.

The raw AntBNC list is only an approximation to New Word Level Checker (NWLC)
processing. NWLC uses a manually modified AntBNC mapping aligned to its selected
word lists. Use \code{new_jacet8000_profile()} conflict diagnostics and explicit
overrides rather than claiming unverified NWLC equivalence.
}
\section{Resource and path boundary}{
The AntBNC payload is read only from the path supplied by the caller. It is
never bundled, downloaded, or copied into the result. Provenance retains its
basename and exact SHA-256, but not its absolute directory. Package-generated
file-access errors do not echo the supplied path.
}
\value{
The input \code{lexdiv_tokenization} object with three token columns:
\code{flemma}, \code{flemma_matched}, and \code{flemma_match_rule}. A
\code{flemma_annotation} record is added to preprocessing provenance with
resource identity, parser identity, match/override/fallback counts, and
coverage.
}
\examples{
fixture <- tempfile(fileext = ".txt")
writeLines(
  c(
    "cat\t->\tcat\tcats",
    "see\t->\tsaw\tsee",
    "the\t->\tthe"
  ),
  fixture,
  useBytes = TRUE
)

tokens <- lexdiv_tokenize("The cats saw an unknownword.", case = "lower")
flemmas <- lexdiv_flemmatize(
  tokens,
  fixture,
  resource_version = "synthetic-help-fixture"
)
unlink(fixture)

flemmas$tokens[, c(
  "surface", "flemma", "flemma_matched", "flemma_match_rule"
)]
flemmas$provenance$flemma_annotation[c(
  "resource_source_file", "resource_source_sha256", "matched_coverage"
)]
lexdiv_metrics_text(flemmas, unit = "flemma", metrics = "ttr")

\dontrun{
# Replace the synthetic fixture with a legitimately obtained AntBNC list.
real_flemmas <- lexdiv_flemmatize(
  lexdiv_tokenize("Interesting studies went outside."),
  "/path/to/antbnc_lemmas_ver_004.txt",
  overrides = data.frame(
    form = "interesting",
    flemma = "interesting"
  ),
  resource_version = "004"
)

lexdiv_metrics_text(real_flemmas, unit = "flemma", metrics = "ttr")
}
}
\seealso{
\code{\link{lexdiv_preprocessing}},
\code{\link{new_jacet8000_profile}}
}
\keyword{text}
