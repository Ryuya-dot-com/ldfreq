\name{lexdiv_ngrams}
\alias{lexdiv_ngrams}
\alias{lexdiv_ngram_reference}
\alias{lexdiv_ngram_profile}
\alias{print.lexdiv_ngrams}
\alias{print.lexdiv_ngram_reference}
\alias{print.lexdiv_ngram_profile}
\title{Adjacent Bigrams and Trigrams with Local Reference Frequencies}
\usage{
lexdiv_ngrams(data, preprocessing_id, n = c(2L, 3L),
  documents = NULL, id_col = "document_id", segment_col = "segment_id",
  position_col = "token_index", term_col = "term", max_ngrams = 1e6)

lexdiv_ngram_reference(x, resource, totals = NULL,
  preprocessing_id = NULL, complete = NULL)

lexdiv_ngram_profile(x, reference)

\method{print}{lexdiv_ngrams}(x, ...)
\method{print}{lexdiv_ngram_reference}(x, ...)
\method{print}{lexdiv_ngram_profile}(x, ...)
}
\arguments{
\item{data}{A plain data frame of prepared tokens. Document and segment IDs
and terms must be nonempty character strings without missing values. Terms
must contain no whitespace. Each document/segment pair must occupy one
contiguous block with strictly increasing positive whole-number original
positions. Gaps are allowed and break adjacency. Input is never sorted.}
\item{preprocessing_id}{Required nonempty character label describing the
actual segmentation, tokenization, exclusion, lexical-unit and normalization
rules. Target and reference labels must agree. The label is a caller assertion,
not verification of the preparation. Inherit it from an extraction when
constructing a reference from that result.}
\item{n}{A nonempty unique selection of \code{2L} and \code{3L}, in the
desired output order. Overlapping occurrences are counted.}
\item{documents}{Optional unique character document-ID roster, including
all IDs in \code{data}. It preserves zero-token documents and sets summary
order. Defaults to IDs in first-seen input order.}
\item{id_col,segment_col,position_col,term_col}{Four distinct column names.
Extra input columns are ignored; retain research metadata separately by ID.}
\item{max_ngrams}{Positive whole-number upper bound on extracted occurrence
rows, checked before occurrence tables and tallies are allocated. This is not
a bound on total memory or all result rows. The default is one million.}
\item{x}{For reference construction, either an unmodified
\code{lexdiv_ngrams} result or a plain count data frame. For profiling, an
unmodified \code{lexdiv_ngrams} result. For printing, the corresponding result.}
\item{resource}{Named list with exactly these ordered nonempty character
fields: \code{resource_id}, \code{resource_version}, \code{creator},
\code{source_reference}, \code{data_license}, \code{transformation_id},
\code{lookup_unit}, \code{resource_key_normalization_id}. These describe the
reference; the package does not establish its suitability or permissions.}
\item{totals}{For external counts, a data frame with unique \code{n} rows
and nonnegative whole-number \code{opportunities} and \code{documents}.
Opportunities count eligible adjacent windows before any frequency pruning,
not all word tokens. Required with a count table; inherited from an extraction.}
\item{complete}{Whether the reference lists every observed n-gram in its
declared population. Defaults to \code{TRUE} for an extraction and \code{FALSE}
for an external table. Complete count sums must equal opportunities for each
\code{n}; incomplete sums must not exceed them. This check cannot prove that
the declared population or completeness is accurate.}
\item{reference}{An unmodified \code{lexdiv_ngram_reference} result. It must
declare totals for every \code{n} requested in the target extraction.}
\item{...}{Additional arguments passed to \code{print.data.frame()}.}
}
\description{
Extracts adjacent two- and three-term sequences within explicit segments,
constructs or imports local reference counts, and reports document-level
frequency and coverage. No reference corpus, sentence parser, download or
implicit normalization is required or supplied by these functions.
}
\value{
\code{lexdiv_ngrams()} returns a \code{lexdiv_ngrams} list:
\describe{
\item{occurrences}{\code{document_id}, \code{segment_id}, \code{n},
\code{start_index}, \code{end_index}, \code{term1}, \code{term2},
\code{term3}. Rows follow requested \code{n}, then input start-row order.
For bigrams, \code{term3} is \code{NA_character_}.}
\item{counts}{\code{n}, \code{term1}, \code{term2}, \code{term3},
\code{count}, \code{document_count}. Each distinct sequence retains its
occurrence count and number of distinct documents, in first-occurrence order.}
\item{document_counts}{\code{document_id}, the four sequence columns, and
\code{count}, in first-occurrence order.}
\item{documents}{Document-major, then requested-\code{n}-major rows with
\code{document_id}, \code{n}, \code{input_tokens}, \code{opportunities},
\code{ngram_types}, \code{status}. Status is \code{"empty_document"},
\code{"no_ngrams"} or \code{"ok"}. Token counts repeat across \code{n}.}
\item{totals}{Requested \code{n}, total \code{opportunities}, and
\code{documents} (roster size, including zero-token documents).}
\item{provenance}{Contract identity/version, preparation label, input-column
mapping, input and result content fingerprints, boundary policy and declared
boundary evidence, row ceiling, normalization and network policy.}
}
\code{lexdiv_ngram_reference()} returns a \code{lexdiv_ngram_reference} list
with \code{counts}, \code{totals}, and \code{provenance}. Count columns are
exactly those of the extraction's \code{counts}; keys must be unique and counts
positive whole numbers. Document counts cannot exceed occurrence counts or
the declared document population. Terms are matched exactly by component in
UTF-8, without case folding or Unicode normalization. Extra columns are
discarded. Provenance retains resource metadata, preparation, completeness,
source extraction fingerprint when available, and reference content identity.

\code{lexdiv_ngram_profile()} returns a \code{lexdiv_ngram_profile} list:
\describe{
\item{lookup}{All target occurrence columns plus \code{reference_status},
\code{reference_count}, \code{reference_document_count},
\code{reference_opportunities}, and \code{frequency_per_million}.
Status is \code{"listed"} for an observed reference row,
\code{"not_observed"} for an absent complete-reference key (count zero), or
\code{"not_listed"} for an absent incomplete-reference key (count missing).
Rates equal count divided by reference opportunities for that \code{n}, times
one million. With zero reference opportunities the rate is missing.}
\item{summary}{Document-major, then requested-\code{n}-major, then
\code{"token"}/\code{"type"} weighting rows. Columns are
\code{document_id}, \code{n}, \code{weighting}, \code{eligible_items},
\code{listed_items}, \code{zero_items}, \code{unavailable_items},
\code{lookup_coverage}, \code{value_coverage},
\code{mean_frequency_per_million}, \code{status}, \code{missing_reason}.
Token weighting retains repetitions; type weighting counts each exact sequence
once per document. Coverage denominators are eligible target occurrences or
types. Lookup coverage counts listed keys; value coverage counts available
rates. \code{zero_items} counts \code{"not_observed"} keys, even when a zero
reference denominator leaves their rate undefined; \code{unavailable_items}
counts missing rates. Means use available rates, including defined zeros.
Always report coverage beside means.}
\item{documents}{Unchanged target document diagnostics.}
\item{provenance}{Target and reference provenance, reference totals,
statistic and rate-denominator definitions, contract and content identities.}
}
Summary status is \code{"empty"} with reason \code{"no_target_ngrams"} for
zero eligible items; coverage and mean are missing. It is \code{"no_values"}
with reason \code{"zero_reference_opportunities"} or
\code{"no_available_reference_values"} when no rates are available.
Otherwise it is \code{"ok"}, which permits partial coverage, with missing
reason \code{NA_character_}. Zero-document inputs retain typed zero-row tables.
Identifiers/terms/statuses are character, \code{n} is integer, and positions,
counts, rates and coverages are double. All three print methods display at most
12 rows and return the complete result invisibly.
}
\details{
Segment boundaries must represent the study's chosen adjacency boundaries,
such as sentences or speaker turns. The function checks declared boundaries,
not their linguistic accuracy. Preserve positions before exclusion:
\code{make a decision} at positions 1, 2, 3 must not become the adjacent
bigram \code{make decision} after deleting position 2. Renumbering destroys
that evidence. The generic tokenizer's retained-token index alone does not
provide original gaps or sentence IDs; do not pass it through as if it did.
Decide punctuation, contractions, hyphens and markup handling explicitly.

An external frequency table must supply all required counts and totals. A
published table using word-token normalization, different boundaries or
unknown pruning is not automatically compatible. A reference's zero means
unobserved in the specified sample, not impossible in English. Unlisted keys
in truncated tables retain missing values and are excluded from means.
Even a matching preparation label cannot rule out incorrectly prepared keys.

Save whole results with \code{saveRDS()} and \code{readRDS()}. Content
fingerprints detect accidental modifications before subsequent calls; they
are not signatures or permission checks. To change a reference, reconstruct it
from revised counts, totals and metadata instead of editing its result.
Corpus text and counts remain local unless the user separately shares them;
local processing does not establish permission to redistribute inputs or
outputs. Source text need not be bundled with a reference table or package.

These descriptive frequencies are not association scores, lexical
employability or proficiency estimates. There is no MI, t-score, smoothing,
automatic threshold, skip-gram, semantic matching or document pooling.
Bundled TUBELEX unigram counts cannot recover observed n-gram co-occurrences.
}
\examples{
# Authored, pre-segmented example; no external corpus.
tokens <- data.frame(document_id = c(rep("r1", 3), rep("r2", 3)),
  segment_id = "s1", token_index = rep(1:3, 2),
  term = c("make", "a", "decision", "make", "a", "plan"))
extracted <- lexdiv_ngrams(tokens, "authored-sentences-surface-v1")
extracted$counts
resource <- list(resource_id = "authored_demo", resource_version = "1",
  creator = "Example author", source_reference = "Authored token sequences",
  data_license = "Project-authored example", transformation_id = "none",
  lookup_unit = "adjacent_surface_ngram", resource_key_normalization_id = "identity")
reference <- lexdiv_ngram_reference(extracted, resource)
target <- tokens[1:3, ]
target$term[3] <- "choice"
result <- lexdiv_ngram_profile(
  lexdiv_ngrams(target, "authored-sentences-surface-v1"), reference)
result$lookup
print(result)
# Import a pruned aggregate without converting its missing rows to zero.
partial <- lexdiv_ngram_reference(reference$counts[reference$counts$count > 1, ],
  resource, totals = reference$totals,
  preprocessing_id = "authored-sentences-surface-v1", complete = FALSE)
lexdiv_ngram_profile(lexdiv_ngrams(target,
  "authored-sentences-surface-v1"), partial)$summary
}
\seealso{\code{\link{lexdiv_ngram_compare}}, \code{\link{lexdiv_norm_profile_batch}},
\code{\link{lexdiv_reference_coverage}}, \code{\link{tubelex_profile}}}
\keyword{text}
