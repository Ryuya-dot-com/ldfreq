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
  resource_version = NULL,
  override_version = NULL
)
}
\arguments{
  \item{x}{An object created by \code{lexdiv_tokenize()}.}
  \item{resource}{Path to a caller-supplied AntBNC lemma-list text file in
  \code{headword<TAB>-><TAB>form...} format.}
  \item{overrides}{Optional data frame with unique \code{form} and
  \code{flemma} columns. Overrides are applied after resource lookup and before
  identity fallback.}
  \item{override_version}{Optional caller-declared version label for a
  non-empty override table. Supplying it without overrides is an error. Strict
  flemma overlap treats overrides without a version as unverifiable.}
  \item{normalization}{\code{"nfkc_lower"} applies NFKC, trimming, and
  locale-fixed English lowercasing to resource entries, overrides, and queries.
  \code{"identity"} performs exact matching.}
  \item{resource_version}{Optional caller-declared resource version label.
  Strict flemma overlap treats a missing version as unverifiable; the package
  does not infer content identity from file bytes.}
}
\details{
Flemma counting groups inflected forms without distinguishing part of speech.
It is therefore not interchangeable with a POS-sensitive lemma analysis.

The parser requires unique normalized headwords and a deterministic one-to-one
form-to-headword mapping. The output records whether each token used
\code{"antbnc"}, an explicit \code{"override"}, or normalized-surface
\code{"identity"} fallback. Identity fallback prevents an unknown resource
form from disappearing before an off-list or diversity analysis.

The flemma adapter, parser, and AntBNC resource IDs are fixed by \pkg{ldfreq}.
\code{resource_version} and \code{override_version} are caller labels, not
byte-identity proofs. They are included in public provenance and may appear in
overlap comparability output. Labels must be path-free and non-sensitive;
callers must not put paths, credentials, private hashes, or machine-specific
details in them. When strict flemma overlap is requested, resource versions
must be present and equal. If neither side used overrides, their override
setting is comparable; otherwise both sides need the same non-missing
override version.

The raw AntBNC list is only an approximation to New Word Level Checker (NWLC)
processing. NWLC uses a manually modified AntBNC mapping aligned to its selected
word lists. Use \code{new_jacet8000_profile()} conflict diagnostics and explicit
overrides rather than claiming unverified NWLC equivalence.
}
\section{Resource and path boundary}{
The AntBNC payload is read only from the path supplied by the caller. It is
never bundled, downloaded, or copied into the result. Its local file name,
absolute directory, and content hash are not retained in public provenance.
A source-byte digest is used only for caching, is never copied to public
provenance or results, and is not used to decide overlap comparability.
Package-generated file-access errors do not echo the supplied path.
}
\value{
The input \code{lexdiv_tokenization} object with three token columns:
\code{flemma}, \code{flemma_matched}, and \code{flemma_match_rule}. A
\code{flemma_annotation} record is added to preprocessing provenance with
fixed adapter/parser/resource IDs, caller-declared versions,
match/override/fallback counts, and coverage.
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
  "backend_id", "backend_version", "resource_id", "resource_version",
  "matched_coverage"
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
  resource_version = "004",
  override_version = "analysis-overrides-v1"
)

lexdiv_metrics_text(real_flemmas, unit = "flemma", metrics = "ttr")
}
}
\seealso{
\code{\link{lexdiv_preprocessing}},
\code{\link{new_jacet8000_profile}}
}
\keyword{text}
