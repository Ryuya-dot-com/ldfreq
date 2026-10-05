\name{lexdiv_ambiguity_review}
\alias{lexdiv_ambiguity_review}
\title{Review lexical candidates in their original contexts}
\description{
Connects source-verified token occurrences to quanteda keyword-in-context
(KWIC) displays, caller-supplied lexical candidates and explicit reviewer
decisions. No readings or senses are inferred. This experimental interface
requires the optional \pkg{quanteda} package.
}
\usage{
lexdiv_ambiguity_review(x, targets, candidates, resource,
  decisions = NULL, window = 5, max_tokens = 1e6)
}
\arguments{
\item{x}{An unmodified result of \code{\link{lexdiv_import_annotations}},
including complete tokens, original segment text and provenance. Alignment
and snapshot identity are checked again. Do not filter or normalize it first.}
\item{targets}{Non-empty character vector of exact, case-sensitive surface
forms to review. Duplicate targets are removed. Each target matches one token;
phrases, whitespace, regular expressions and implicit case folding are not
supported. An absent target remains in the summary with zero occurrences.}
\item{candidates}{Plain data frame with character \code{term},
\code{candidate_id} and \code{label} columns. Terms must belong to
\code{targets}; each term/ID pair must be unique. Zero rows are allowed.
Optional columns, such as reading, pronunciation, POS, lexeme ID, sense ID or
gloss, are preserved without interpretation. Supply candidates for the chosen
resource and research question; the function does not discover them.}
\item{resource}{Plain named list of non-empty scalar strings including
\code{resource_id}, \code{resource_version}, \code{source_reference} and
\code{data_license}. Additional scalar strings may describe transformations
or inventory scope. These are caller declarations, not license verification.}
\item{decisions}{\code{NULL}, or a plain data frame containing
\code{review_id}, \code{occurrence_id}, \code{status}, \code{candidate_id},
\code{reviewer} and \code{reason}. Copy the first two from an initial review.
Each occurrence may appear at most once, in any order. Use
\code{status = "selected"} with a valid candidate ID, or
\code{status = "unresolved"} with \code{candidate_id = NA_character_}.
Reviewer and reason must be non-blank strings. Omitted occurrences remain
unreviewed or without candidates. Extra columns are retained in the returned
decision table, for example an annotation date or an adjudication reference.}
\item{window}{One non-negative whole number giving quanteda's context window
in token positions on each side, bounded by the supplied segment. Explicit
whitespace-only tokens remain padding at their original positions.}
\item{max_tokens}{Positive whole-number ceiling on all source token slots,
checked before KWIC search. This is not a byte-size or total memory ceiling.}
}
\details{
The function reuses \code{\link{lexdiv_as_quanteda}} and
\code{quanteda::kwic()} with fixed, case-sensitive matching, then verifies
exact source/query equality to distinguish canonically equivalent Unicode
spellings. It never retokenizes. A token containing both whitespace and non-whitespace characters
is not supported by this adapter. Non-ASCII tokens require a UTF-8 R session.

The \code{pre}, \code{keyword} and \code{post} columns are quanteda's
reconstructed display, with spaces between tokens. Consult
\code{segment_text} for exact original spelling, whitespace and punctuation.
The \code{start}/\code{end} columns index that original segment using 1-based,
inclusive Unicode codepoints, not bytes or positions in the KWIC display.
Document and segment IDs link to all original segments in \code{source};
the caller supplies sentence/turn boundaries, which are not inferred.

Unreviewed occurrences with candidates have status \code{"unreviewed"}, even
when there is only one candidate. Those without candidates have status
\code{"no_candidates"}; this does not establish that they are unambiguous.
An explicit \code{"unresolved"} decision records that review did not settle
the interpretation. \code{"selected"} verifies ID membership, not semantic
correctness. Missing selections remain missing and input annotations are not
overwritten. No homonymy/polysemy classification, similarity score, sense
frequency or learner-knowledge inference is computed.

Occurrence IDs depend on document/segment identity, source text and token
position/span. Review IDs additionally bind the complete imported snapshot,
target set, candidate table and resource declarations. Reordering targets,
candidate rows or decisions, or changing the displayed window, retains review
identity. Changes to the source, annotation metadata, target set, candidate
values or resource invalidate old decisions. Review the new snapshot and
explicitly reconsider decisions; replacing IDs mechanically defeats this
check. Hashes detect changes, not authorship or scientific validity.

The returned whole-result fingerprint allows \code{\link{lexdiv_compare_ambiguity}}
to detect modified review outputs without rerunning KWIC. Change decisions by
calling this function again, not by editing the returned occurrence table.

Candidates are canonically ordered by term and ID. Their count measures the
supplied inventory, not a person's number of known meanings. Readings,
phonemes, lexemes, word senses and synonym-set concepts are different units.
Selecting a sense does not split a TUBELEX or other aggregate frequency count.
}
\value{
A plain list with \code{occurrences} (one row per matched source token,
including original token columns, KWIC, source text, IDs, candidate count and
decision fields), \code{candidates}, \code{decisions}, and \code{summary}
(one row per target with candidate count, occurrences and the four status
counts). Absent targets and empty source segments/documents are retained.
The complete imported object is returned as \code{source}; \code{provenance}
records review identity, resource declarations, quanteda adapter/version and
context settings. Use \code{saveRDS()} to retain this complete review object.
It contains source text and inherits the input data's sharing restrictions.
}
\examples{
tokens <- data.frame(document_id = "d", segment_id = "s1", token_index = 1:5,
  surface = c("The", "bank", "lent", "money", "."))
segments <- data.frame(document_id = "d", segment_id = "s1",
  text = "The bank lent money.")
x <- lexdiv_import_annotations(tokens, segments, list(
  language = "en", analyzer = "authored", analyzer_version = "1",
  dictionary = "none", dictionary_version = "not-applicable",
  unit = "authored-example", normalization = "none"))
candidates <- data.frame(term = c("bank", "bank"),
  candidate_id = c("financial", "river"), label = c("financial institution", "river edge"))
resource <- list(resource_id = "authored-example", resource_version = "1",
  source_reference = "Authored illustration, not a dictionary", data_license = "MIT")
if (requireNamespace("quanteda", quietly = TRUE)) {
  review <- lexdiv_ambiguity_review(x, "bank", candidates, resource)
  review$occurrences[c("pre", "keyword", "post", "candidate_count", "status")]
  decisions <- review$occurrences[c("review_id", "occurrence_id")]
  decisions$status <- "selected"
  decisions$candidate_id <- "financial"
  decisions$reviewer <- "example-reviewer"
  decisions$reason <- "The context describes lending money."
  reviewed <- lexdiv_ambiguity_review(x, "bank", candidates, resource, decisions)
  reviewed$summary
}
}
\seealso{\code{\link{lexdiv_compare_ambiguity}},
\code{\link{lexdiv_import_annotations}}, \code{\link{lexdiv_as_quanteda}},
\code{vignette("ambiguity-review", package = "ldfreq")}}
