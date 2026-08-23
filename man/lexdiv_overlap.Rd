\name{lexdiv_overlap}
\alias{lexdiv_overlap}
\alias{lexdiv_overlap_measure_ids}
\alias{lexdiv_term_overlap}
\alias{lexdiv_content_overlap}
\title{Compute Exact Type Overlap Between Two Texts}
\description{
Compute Jaccard, Dice, directional coverage, and overlap-coefficient values
from two exact term sets. A separate adapter selects explicitly annotated
Universal POS content words before applying the same term core.
}
\usage{
lexdiv_overlap_measure_ids()

lexdiv_term_overlap(
  terms_a,
  terms_b,
  measures = lexdiv_overlap_measure_ids(),
  document_ids = c("text_a", "text_b"),
  details = "counts"
)

lexdiv_content_overlap(
  x,
  y,
  unit = "lemma",
  measures = lexdiv_overlap_measure_ids(),
  document_ids = c("text_a", "text_b"),
  details = "counts",
  mismatch = "error"
)
}
\arguments{
\item{terms_a, terms_b}{Plain character vectors with one complete lexical
unit per element. Missing or empty terms, invalid UTF-8, and
\code{bytes}- or \code{latin1}-marked strings invalidate the pair instead of
being silently removed.}
\item{measures}{A non-empty, duplicate-free vector from
\code{lexdiv_overlap_measure_ids()}.}
\item{document_ids}{Two distinct, path-free, plain, non-empty valid-UTF-8
identifiers for documents A and B. Control characters are not accepted.}
\item{details}{Either \code{"counts"}, which does not retain lexical items, or
\code{"terms"}, which returns shared and side-unique exact terms with token
counts.}
\item{x, y}{Objects created by \code{lexdiv_tokenize()} and annotated with
\code{lexdiv_lemmatize()}, including explicit \code{upos_backend_id} and
\code{upos_backend_version} whenever UPOS tags are present. Raw character
strings are not accepted because \pkg{ldfreq} does not infer UPOS tags.
Flemma comparison additionally requires \code{lexdiv_flemmatize()}.}
\item{unit}{One of \code{"lemma"}, \code{"surface"}, or \code{"flemma"}.
The default is explicit lemma comparison. The selected units are not normalized
again.}
\item{mismatch}{Action when A and B record different or unverifiable
unit-relevant settings. The default \code{"error"} fails closed;
\code{"warn"} and \code{"allow"} must be selected explicitly. This controls
only the diagnostic action; it never transforms either input.}
}
\details{
\code{lexdiv_term_overlap()} converts each valid input to a set of distinct
exact strings. Token order and repetition do not affect overlap values. It does
not perform tokenization, Unicode normalization, case conversion, stemming,
lemmatization, synonym expansion, or fuzzy matching.

For type sets \eqn{A} and \eqn{B}, intersection \eqn{I}, and union \eqn{U},
the measures are:

\tabular{lll}{
Measure ID \tab Numerator and denominator \tab Symmetric \cr
\code{jaccard_types} \tab \eqn{|I| / |U|} \tab yes \cr
\code{dice_types} \tab \eqn{2|I| / (|A| + |B|)} \tab yes \cr
\code{a_covered_by_b_types} \tab \eqn{|I| / |A|} \tab no \cr
\code{b_covered_by_a_types} \tab \eqn{|I| / |B|} \tab no \cr
\code{overlap_coefficient_types} \tab \eqn{|I| / \min(|A|, |B|)} \tab yes
}

The summary always carries the numeric numerator and denominator. Directional
rows also identify the source (denominator) document and reference document, so
A-in-B cannot be confused with B-in-A.

\code{lexdiv_content_overlap()} uses the same content set as
\code{lexdiv_metrics_text(..., word_inclusion = "content")}: \code{ADJ},
\code{ADV}, \code{NOUN}, \code{PROPN}, and \code{VERB}. Missing UPOS,
non-content UPOS, and missing selected units are excluded for different reasons
and counted separately. The \code{coverage} table should be interpreted beside
the overlap values. The \code{comparability} table records whether A and B use
the same relevant preprocessing and annotation settings. It has exactly four
columns: \code{component}, \code{value_a}, \code{value_b}, and
\code{matches}. The values are disclosed; there is no
\code{values_disclosed} column.

The compared components depend on \code{unit}. Surface comparison uses
tokenizer settings and UPOS backend identity. Lemma comparison additionally
uses the lemma method and backend. Flemma comparison instead adds the fixed
flemma adapter/parser and its resource/override settings; it intentionally
ignores lemma method/backend because \code{lexdiv_flemmatize()} consumes
surface forms rather than lemmas.

For flemma input, adapter/parser/resource IDs are fixed by \pkg{ldfreq}.
Strict comparison requires both caller-declared resource versions to be present
and equal. When neither side used overrides, the override setting is comparable
without an override version. If either side used overrides, both sides must use
overrides and declare the same non-missing version. Missing labels are
unverifiable, different labels are mismatches, and no raw or canonical content
hash is compared. Because declared labels appear in the table, callers must not
put paths, secrets, private hashes, or machine-specific details in them.
}
\section{Empty sets and invalid input}{
When both type sets are empty, every measure is \code{missing}; empty sets are
not treated as perfect overlap. When only one set is empty, Jaccard and Dice are
zero. A directional measure is missing only when its own denominator set is
empty; the other direction is zero. The overlap coefficient is missing when
either set is empty.

Invalid term input makes all requested rows \code{invalid_input}. The
\code{missing_reason} identifies whether A, B, or both inputs were invalid.
Structural request errors such as unknown measure IDs stop the call.
}
\section{Result object}{
Both functions return a list inheriting from \code{lexdiv_overlap}. Its
components are:
\describe{
  \item{\code{summary}}{One row per requested measure, including method and
  schema identity, value, status, numerator, denominator, document direction,
  set counts, lexical unit, and analysis scope.}
  \item{\code{counts}}{One pair-level row with token and type denominators.}
  \item{\code{coverage}}{One row per document. Content overlap reports UPOS,
  content-word, selected-unit, and flemma identity-fallback coverage.}
  \item{\code{shared_terms}, \code{unique_to_a}, \code{unique_to_b}}{Typed
  empty tables under \code{details = "counts"}; exact lexical details under
  \code{details = "terms"}.}
  \item{\code{exclusions}}{Aggregated content-word exclusion counts.}
  \item{\code{comparability}}{A/B preprocessing and annotation comparisons
  in the four columns \code{component}, \code{value_a}, \code{value_b}, and
  \code{matches}.}
  \item{\code{preprocessing}, \code{provenance}}{Measurement settings and
  contract identity. \code{provenance$contains_lexical_terms} states whether
  the three term-detail tables retain exact lexical strings. The print method
  displays a notice when they do. Raw text, text hashes, flemma resource or
  override hashes, local resource file names, and absolute paths are not copied
  into the overlap result.}
}
}
\section{Interpretation boundary}{
These functions describe exact lexical sharing under the selected unit and
content-word annotations. They are not plagiarism detectors or direct measures
of semantic similarity, coherence, language proficiency, or writing quality.
Such claims require a separate validated design. Jaccard, Dice, directional
coverage, and the overlap coefficient have different denominators and are not
interchangeable labels for one generic overlap percentage.
}
\section{Formal contract}{
The installed \file{lexical-overlap-contract.json} file fixes measure formulas,
empty-set behavior, content-word eligibility, comparability diagnostics, and
the privacy boundary. Locate it with \code{system.file("spec",
"lexical-overlap-contract.json", package = "ldfreq")}.
}
\value{
\code{lexdiv_overlap_measure_ids()} returns a character vector.
\code{lexdiv_term_overlap()} returns a \code{lexdiv_term_overlap} object;
\code{lexdiv_content_overlap()} returns a \code{lexdiv_content_overlap}
object. Both also inherit from \code{lexdiv_overlap}.
}
\examples{
term_overlap <- lexdiv_term_overlap(
  c("cat", "dog", "run"),
  c("cat", "bird", "run"),
  details = "terms"
)
term_overlap$summary
term_overlap$shared_terms

x <- lexdiv_lemmatize(
  lexdiv_tokenize("Cats and dogs ran.", case = "lower"),
  lemmas = c("cat", "and", "dog", "run"),
  upos = c("NOUN", "CCONJ", "NOUN", "VERB"),
  backend_id = "documented-example-annotations",
  backend_version = "1",
  upos_backend_id = "documented-example-upos",
  upos_backend_version = "1"
)
y <- lexdiv_lemmatize(
  lexdiv_tokenize("Cats and birds ran.", case = "lower"),
  lemmas = c("cat", "and", "bird", "run"),
  upos = c("NOUN", "CCONJ", "NOUN", "VERB"),
  backend_id = "documented-example-annotations",
  backend_version = "1",
  upos_backend_id = "documented-example-upos",
  upos_backend_version = "1"
)
content_overlap <- lexdiv_content_overlap(
  x,
  y,
  details = "terms",
  document_ids = c("essay", "reference")
)
content_overlap$summary
content_overlap$coverage
content_overlap$shared_terms
}
\seealso{
\code{\link{lexdiv_preprocessing}}, \code{\link{lexdiv_metrics}}
}
\keyword{text}
