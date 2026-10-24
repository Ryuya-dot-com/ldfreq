\name{lexdiv_concordance}
\alias{lexdiv_concordance}
\alias{lexdiv_concordance_sort}
\alias{lexdiv_sort_concordance}
\alias{lexdiv_concordance_dispersion}
\alias{plot.lexdiv_concordance}
\title{Search source-aligned words and phrases and inspect their distribution}
\description{
\code{lexdiv_sort_concordance()} is the canonical name; \code{lexdiv_concordance_sort()} remains a compatibility alias.

Search complete annotations, preserving original text, token positions,
selection masks and zero-match documents. Sort saved contexts, draw positions,
or compute single-token within-document dispersion without searching again.
}
\usage{
lexdiv_sort_concordance(x, side = c("right", "left"), depth = 1L,
                        ignore_case = FALSE)

lexdiv_concordance(x, queries, term_col = "surface",
    valuetype = c("fixed", "glob", "regex"), case_insensitive = FALSE,
    keep = rep(TRUE, nrow(x$tokens)), window = 5L, max_cells = 1e6)
lexdiv_concordance_sort(x, side = c("right", "left"), depth = 1L,
                        ignore_case = FALSE)
lexdiv_concordance_dispersion(x, query_id, parts = 10L, max_cells = 1e6)
\method{plot}{lexdiv_concordance}(x, query_id, relative = TRUE,
                                 monochrome = FALSE, ...)
}
\arguments{
\item{x}{For searching, an unchanged complete
\code{\link{lexdiv_import_annotations}} result. Otherwise, an unchanged saved
concordance result. Sorting and dispersion also accept legacy plain-list results
from \code{concordance_search()}.}
\item{queries}{Named list with unique nonblank query IDs. Each element is a
nonempty character vector of token patterns: one token or one contiguous phrase.}
\item{term_col}{Character token column to search, such as \code{surface} or
supplied \code{lemma}. Missing/blank selected terms are unavailable.}
\item{valuetype}{Fixed, glob or regular-expression matching of token patterns
through optional \pkg{quanteda}; not regular expressions over raw text.}
\item{case_insensitive}{Logical switch for matching only; original text and
stored terms are unchanged.}
\item{keep}{One nonmissing logical value per original token. Excluded positions
remain gaps; a match cannot cross them or supplied segment boundaries.}
\item{window}{Nonnegative number of original surface-token slots on each side
to retain as context, bounded by the supplied segment.}
\item{max_cells}{Positive whole-number bound on input tokens, document/query
cells and stored match/context cells for search; on document/part cells for
dispersion. These are allocation bounds, not total memory guarantees.}
\item{side}{Context to sort, nearest token first.}
\item{depth}{Positive number of context tokens used as successive sort keys,
no larger than the saved window. Missing context sorts last; ties keep saved order.}
\item{ignore_case}{Logical switch for case-folding sort keys only.}
\item{query_id}{One exact saved query ID. Dispersion requires a single-token
query; position plots also support phrases.}
\item{parts}{Number of within-document parts, an integer of at least two.}
\item{relative}{If true, position is \code{(original_token_position - 0.5) / N},
where \code{N} counts original token slots in that document. Otherwise use the
original token index across its supplied segments.}
\item{monochrome}{Use black rather than the default colour.}
\item{...}{Reserved; unsupported arguments are rejected.}
}
\details{
Searching requires optional \pkg{quanteda} (>= 4.5.0). Sorting and dispersion
use the saved record; plotting requires optional \pkg{ggplot2}, but not quanteda.
None of these operations infer sentence boundaries or validate annotation accuracy.
Original character spans are segment-local inclusive Unicode codepoint positions.

For dispersion, original slots determine parts as
\code{floor((position - 1) * parts / source_tokens) + 1}. Expected shares are
the searchable-token shares of those parts. Unnormalised DP is half the sum of
absolute differences between observed and expected shares. No matches, no
searchable tokens, or fewer than two parts with positive exposure produce
reasoned \code{NA}. This is within-document dispersion, not across-document
dispersion, a frequency-independent score or a validity threshold.

The public search result adds the \code{lexdiv_concordance} class for
\code{plot()}. Its component layout and measurement rules preserve the previous
example contract. Legacy \code{examples/concordance.R} still defines the old
names and returns plain lists; \code{concordance_positions()} still returns a
ggplot object. Existing saved records remain accepted by the applicable
operations. Do not change classes or integrity hashes by hand; to obtain the new
plot interface for an old search, recreate it from its saved source and settings.
See \href{https://ryuya-dot-com.github.io/ldfreq/articles/concordance-and-dispersion.html}{concordance and dispersion guide}.
}
\value{
\code{lexdiv_concordance()} returns a classed list with \code{occurrences}
(query/document/segment IDs, token and character positions, contexts, matched
terms and occurrence IDs), \code{counts}, \code{documents} (source/kept/searchable
tokens and missing terms), full \code{source}, \code{queries}, \code{settings},
\code{provenance} and \code{integrity_sha256}. Hashes detect accidental changes;
they are not authentication. Save the complete object, which includes source text.

Sorting returns an ordered occurrence data frame without changing the record.
Dispersion returns a list with document summaries, per-part counts/exposures,
selected occurrence IDs, settings and the search ID. \code{plot()} draws the
saved positions and invisibly returns the displayed \code{occurrences},
\code{documents} and query \code{counts}, including empty and zero-match documents.
}
\examples{
segments <- data.frame(document_id = c("d1", "empty"), segment_id = "s1",
  text = c("a b a", ""))
tokens <- data.frame(document_id = "d1", segment_id = "s1",
  token_index = 1:3, surface = c("a", "b", "a"))
source <- lexdiv_import_annotations(tokens, segments, list(language = "en",
  analyzer = "authored", analyzer_version = "1", dictionary = "none",
  dictionary_version = "none", unit = "supplied tokens", normalization = "none"))
if (requireNamespace("quanteda", quietly = TRUE)) {
  search <- lexdiv_concordance(source, list(word = "a", phrase = c("a", "b")))
  lexdiv_sort_concordance(search)
  lexdiv_concordance_dispersion(search, "word", parts = 3)$documents
  if (requireNamespace("ggplot2", quietly = TRUE)) plot(search, "word")
}
}
