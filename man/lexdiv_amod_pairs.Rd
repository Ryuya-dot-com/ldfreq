\name{lexdiv_amod_pairs}
\alias{lexdiv_amod_pairs}
\title{Extract source-linked adjective and common-noun dependency pairs}
\description{
Validates supplied basic Universal Dependencies (UD) trees and extracts
\code{amod} relations from an \code{ADJ} dependent to a \code{NOUN} head.
This experimental function connects occurrences and original context to
document counts and annotation coverage. It runs no parser or model.
}
\usage{
lexdiv_amod_pairs(annotations, unit = c("surface", "lemma"),
  context_chars = 30L, max_tokens = 1e6)
}
\arguments{
\item{annotations}{An unmodified \code{\link{lexdiv_import_annotations}} result.
Each segment must represent one sentence, including all syntactic words and
punctuation in original order. Tokens require plain numeric \code{head}
(sentence-local \code{token_index}, with 0 for root), character \code{deprel}
(basic UD relation, optionally with a subtype), and character \code{upos}
(UD tags). Missing annotations use typed \code{NA}, not an underscore.
Empty segments and documents remain in the result.}
\item{unit}{Exact, case-sensitive \code{surface} (default) or \code{lemma}
values used to count ordered adjective--noun types. No lowercasing,
lemmatization, or fallback occurs. Missing lemmas do not remove detected
occurrences; type totals are unavailable if any detected pair lacks a unit.}
\item{context_chars}{Non-negative whole number of Unicode codepoints on each
side of the span enclosing both words, limited to the original segment.}
\item{max_tokens}{Positive whole-number input row limit, not a total memory
or source-text size limit.}
}
\details{
Every supplied head must refer to a different word in the same sentence or
be 0. Known cycles, out-of-range heads, multiple roots and inconsistent
root labels are rejected even in incomplete sentences. Complete basic trees
must have exactly one root. Structural validation does not establish
linguistic correctness or detect an incorrectly declared sentence boundary.

A sentence with any missing head, relation or UPOS is excluded in full.
Other complete sentences remain observable, but totals for a document
containing an incomplete sentence are \code{NA}, not zero.
Coverage is the number of tokens in complete sentences divided by all supplied
tokens, including punctuation. Empty documents have zero pair/type counts
and undefined token coverage. These counts are not lexical-diversity scores.

The feature includes \code{amod} subtypes and requires dependent \code{ADJ}
and head \code{NOUN}. Proper nouns (\code{PROPN}), pronouns and other parts
of speech are outside this explicitly narrow feature. It is not every UD
adjectival modifier, an idiom detector, or an exact replication of a study
using Penn tags. Direction and non-adjacent endpoints are retained.

Input must already represent source-aligned basic syntactic words. This is
not a CoNLL-U file reader. Multiword-token range rows, empty nodes, and words
that cannot be aligned individually to the original text are unsupported.
Supplied \code{deps}/\code{DEPS} columns containing enhanced edges are rejected;
callers must explicitly project to a basic tree and record that choice in
annotation provenance. Do not renumber only the token column: heads must use
the same sentence-local indices. No normalization or guessed offsets are used.

\code{counts} describes only observed pairs with both lexical values available.
Read it alongside coverage and \code{pairs_with_unit}; it is not automatically
a complete reference corpus. Mutual information, association strength,
sampling uncertainty and parser accuracy are not estimated.
}
\value{
A plain list with \code{occurrences} (both token indices, surfaces, POS,
terms and endpoints, relation, direction, token distance, enclosing span and
\code{pre}/\code{keyword}/\code{post} context), \code{counts} (observed
ordered term pairs and their frequencies), \code{segments} (missing annotation
counts, status and observed/total pairs), \code{documents} and \code{summary}
(sentence and token coverage, observed/total pairs and types), the complete
\code{annotations}, and \code{provenance} with the feature, unit, policies and
content hash. \code{keyword} includes intervening text, not just the two words.
Composite source IDs and both endpoints identify occurrences; row numbers
are not stable cross-analysis IDs. \code{pairs_with_unit} distinguishes unit
availability from syntactic detection. \code{observed_types} remains available
when a complete type total cannot be established.
}
\references{
Universal Dependencies, \emph{amod: adjectival modifier},
\url{https://universaldependencies.org/u/dep/amod.html}, and
\emph{CoNLL-U Format}, \url{https://universaldependencies.org/format.html}.
}
\seealso{\code{\link{lexdiv_import_annotations}},
\code{\link{lexdiv_align_annotations}}, \code{\link{lexdiv_ngrams}}}
\examples{
env <- new.env(parent = baseenv())
sys.source(system.file("examples", "amod-pairs.R", package = "ldfreq",
  mustWork = TRUE), env)
x <- env$amod_pairs_example
x$reference$occurrences[c("document_id", "dependent_term", "head_term", "keyword")]
x$predicted$documents
x$differences
}
