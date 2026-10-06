\name{lexdiv_reference_coverage}
\alias{lexdiv_reference_coverage}
\alias{plot.lexdiv_reference_coverage}
\alias{print.lexdiv_reference_coverage}
\title{Compute Coverage of Multiple Documents by One Reference Term Set}
\description{
Compute token- and type-weighted directional coverage for multiple explicit
term vectors against one reference term set. Exact matching, denominators,
empty-input behavior, and optional term disclosure are explicit.
}
\usage{
lexdiv_reference_coverage(
  documents,
  reference,
  reference_id = "reference",
  id_col = "document_id",
  terms_col = "terms",
  details = "counts",
  max_rows = 1e6
)

\method{print}{lexdiv_reference_coverage}(x, ...)

\method{plot}{lexdiv_reference_coverage}(
  x,
  weighting = "token",
  col = "#0072B2",
  pch = 19,
  main = NULL,
  xlab = "document",
  ylab = "coverage",
  ylim = c(0, 1),
  ...,
  monochrome = FALSE
)
}
\arguments{
\item{documents}{Either a plain named list whose elements are term vectors, or
a data frame containing the columns selected by \code{id_col} and
\code{terms_col}. The selected ID column must contain unique character IDs;
the selected terms column must be a list-column with one element per row.}
\item{reference}{A plain character vector containing one complete reference
term per element.}
\item{reference_id}{One path-free, non-empty valid-UTF-8 reference identifier.
It must differ from every document ID.}
\item{id_col}{Name of the document-ID column for data-frame input.}
\item{terms_col}{Name of the term list-column for data-frame input.}
\item{details}{Either \code{"counts"}, which does not retain lexical strings,
or \code{"terms"}, which retains document types, document and reference
counts, and exact-match indicators in \code{$terms}.}
\item{max_rows}{One finite positive integer limiting the combined number of
rows in all returned data frames. The bound is checked before term-detail
allocation.}
\item{x}{A \code{lexdiv_reference_coverage} object.}
\item{weighting}{Exactly one of \code{"token"} or \code{"type"}. Plotting
never combines the two weighting definitions silently.}
\item{col, pch, main, xlab, ylab, ylim}{Base-graphics settings.}
\item{monochrome}{One \code{TRUE} or \code{FALSE} value; specify by name. Defaults to color; \code{TRUE} overrides \code{col} with black. No title is added automatically; place figure titles and notes outside the image.}
\item{...}{Additional arguments passed to the data-frame print method or
\code{graphics::plot()}, as appropriate.}
}
\details{
Plot defaults use a sans serif font, horizontal tick labels and an open frame.
Override these with \code{family}, \code{las} or \code{bty} in the plot
method's \code{...}. Cosmetic graphics parameters are restored after drawing.

Each element of each vector is treated as one complete lexical unit.
The function performs no tokenization, Unicode normalization, case conversion,
stemming, lemmatization, synonym expansion, or fuzzy matching. A single string
containing whitespace triggers a warning because it may be un-tokenized prose.

For document tokens \eqn{D}, distinct document types \eqn{T}, and the distinct
reference type set \eqn{R}, the two rows for each document are:

\tabular{lll}{
Weighting \tab Numerator \tab Denominator \cr
\code{token} \tab tokens in \eqn{D} whose term belongs to \eqn{R}
  \tab number of tokens in \eqn{D} \cr
\code{type} \tab types in \eqn{T} that belong to \eqn{R}
  \tab number of types in \eqn{T}
}

Document repetition therefore affects token coverage but not type coverage.
Reference repetition does not affect either value because the reference defines
membership, although reference token and type counts remain visible in the
result. This directional many-to-one estimand differs from
\code{lexdiv_term_overlap()}, whose Jaccard, Dice, and related measures compare
two distinct-type sets and use different denominators.
}
\section{Empty and invalid input}{
An empty document has a zero denominator, so both rows are \code{missing} with
\code{missing_reason = "empty_document"}. An empty reference yields zero
coverage for every non-empty valid document. An invalid document produces two
local \code{invalid_input} rows without preventing valid documents from being
computed. An invalid reference makes every document row invalid. Invalid term
elements are never removed silently. Structural errors in the document
container, selected columns, IDs, choices, or row bound stop the call.
}
\section{Result object}{
The returned list contains:
\describe{
  \item{\code{summary}}{A document-major long table with one token row and one
  type row per document. Each row includes the measure and method IDs, contract
  and schema identity, value, status, missing reason, numerator, denominator,
  document/reference counts, and matched counts.}
  \item{\code{documents}}{One diagnostic row per document with validation state
  and input token/type counts.}
  \item{\code{reference}}{One diagnostic row for the reference.}
  \item{\code{terms}}{A typed empty table by default. With
  \code{details = "terms"}, one row per distinct valid document term, including
  document and reference counts and the membership indicator. Reference-only
  terms are intentionally omitted because they do not enter either document
  denominator.}
  \item{\code{preprocessing}, \code{provenance}}{Exact matching settings,
  contract/schema identity, row bound, detail mode, and an explicit flag saying
  whether lexical strings are retained. Raw text, hashes, and absolute paths
  are not copied into the result.}
}
The print method shows the analysis rows and discloses retained term details.
The plot method selects one weighting, draws only finite \code{ok} rows, and
returns the plotted rows plus their positions invisibly for reuse.
}
\section{Interpretation boundary}{
Coverage states how much of each supplied document belongs to the supplied
reference set under exact matching. It does not validate the reference, infer
semantic similarity, or measure plagiarism, proficiency, writing quality, or
reference quality. Those claims require an independently justified reference,
preprocessing pipeline, and research design.
}
\section{Formal contract}{
The installed \file{reference-coverage-contract.json} file fixes formulas,
empty/invalid-input behavior, output shape, and the privacy boundary. Locate it
with \code{system.file("spec", "reference-coverage-contract.json",
package = "ldfreq")}.
}
\value{
\code{lexdiv_reference_coverage()} returns a
\code{lexdiv_reference_coverage} list. Its tables remain directly reusable;
no implicit flattening selects one component. The print method returns
\code{x} invisibly. The plot method invisibly returns the exact plotted rows
plus \code{position}.
}
\examples{
documents <- list(
  essay_a = c("cat", "cat", "run", "rare"),
  essay_b = c("bird", "run", "unknown")
)
coverage <- lexdiv_reference_coverage(
  documents,
  reference = c("cat", "bird", "run"),
  reference_id = "course_list",
  details = "terms"
)
coverage$summary[, c(
  "document_id", "weighting", "value", "numerator", "denominator", "status"
)]
coverage$documents
coverage$terms
plot_data <- plot(coverage, weighting = "type")
plot_data

document_frame <- data.frame(
  document_id = c("a", "b"),
  stringsAsFactors = FALSE
)
document_frame$terms <- list(c("a", "a", "b"), c("b", "c"))
lexdiv_reference_coverage(document_frame, c("a", "b"))$summary
}
\seealso{
\code{\link{lexdiv_overlap}}, \code{\link{lexdiv_metrics_batch}}
}
\keyword{text}
