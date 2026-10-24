\name{lexdiv_keyness}
\alias{lexdiv_keyness}
\alias{lexdiv_keyness_concordance}
\title{Compare word frequencies in explicit target and reference corpora}
\description{
Retain corpus denominators, document-level counts and source occurrences beside
descriptive G-squared and log-ratio scores. Return an exact term's occurrences
to a source-aligned concordance without redefining the counted vocabulary.
}
\usage{
lexdiv_keyness(x, target, reference, preprocessing_id,
    term_col = "surface", keep = rep(TRUE, nrow(x$tokens)), min_count = 1L,
    max_tokens = 1e6)
lexdiv_keyness_concordance(x, term, window = 5L, max_cells = 1e6)
}
\arguments{
\item{x}{For comparison, an unchanged complete
\code{\link{lexdiv_import_annotations}} result. For concordance, a complete
unchanged keyness result, including a legacy \code{keyness_compare()} record.}
\item{target, reference}{Nonempty vectors of unique known document IDs, with no
ID shared between the two corpora. Other documents remain explicitly excluded.}
\item{preprocessing_id}{Nonblank caller label for the chosen preprocessing and
selection policy. It does not execute preprocessing or prove comparability.}
\item{term_col}{Character token column to count using exact UTF-8 keys.}
\item{keep}{One nonmissing logical value per original token. Missing/blank
selected terms are unavailable and retained in coverage accounting.}
\item{min_count}{Positive whole pooled-count threshold, returned as a flag only.
It does not change the vocabulary, background counts or denominator.}
\item{max_tokens}{Positive whole-number bound on original input token rows.}
\item{term}{One exact term present in the saved comparison.}
\item{window, max_cells}{Context width and allocation bound passed to
\code{\link{lexdiv_concordance}}.}
}
\details{
Vocabulary is the union of counted terms in both corpora. Each denominator is
all counted tokens in that corpus. Two-by-two cells are term and other-token
counts. G-squared is \code{2 * sum(O * log(O/E))}, with zero observed-cell
contributions zero and no continuity correction. Signed G-squared uses the
direction of the rate difference; log-ratio is the base-2 logarithm of the target
rate divided by the reference rate, without smoothing. An observed zero produces
an infinite log-ratio; an empty corpus produces missing scores with reasons.
Document counts and missing terms remain distinct from pooled token counts.

These are descriptive scores, not p-values, significance decisions or measures
of writer proficiency. Corpus representativeness, writer/task dependence and
multiple testing require separate research decisions. Identical source-text
sequences across groups are flagged; near duplicates are not detected.

Counting requires no optional package. Returning to KWIC uses optional
\pkg{quanteda} (>= 4.5.0) and restricts endpoints to the exact counted term before
matching, preserving Unicode key distinctions. Source text is retained in the
complete result. Legacy \code{examples/keyness.R} still defines its old names
and output shapes. See \code{vignette("keyness-comparison")}.
}
\value{
\code{lexdiv_keyness()} returns a plain list with \code{results} (two-by-two
cells, totals, expected cells, per-1000 rates, log-ratio, G-squared, signed
G-squared, direction, document frequencies, threshold flag and status),
\code{totals}, \code{documents}, \code{document_counts}, \code{occurrences},
\code{token_audit}, complete \code{source}, \code{settings}, \code{provenance}
and \code{integrity_sha256}. Absent document-term rows in the sparse
\code{document_counts} table must be interpreted with document coverage.

\code{lexdiv_keyness_concordance()} returns \code{comparison_id}, \code{term}
and \code{search}, a \code{lexdiv_concordance} result usable with \code{plot()}.
}
\examples{
segments <- data.frame(document_id = c("target", "reference"), segment_id = "s1",
  text = c("a a b", "a b b"))
tokens <- data.frame(document_id = rep(segments$document_id, each = 3),
  segment_id = "s1", token_index = rep(1:3, 2), surface = c("a", "a", "b", "a", "b", "b"))
source <- lexdiv_import_annotations(tokens, segments, list(language = "en",
  analyzer = "authored", analyzer_version = "1", dictionary = "none",
  dictionary_version = "none", unit = "supplied tokens", normalization = "none"))
comparison <- lexdiv_keyness(source, "target", "reference", "surface-all")
comparison$results[c("term", "target_count", "reference_count", "log_ratio")]
if (requireNamespace("quanteda", quietly = TRUE)) {
  evidence <- lexdiv_keyness_concordance(comparison, "a")
  evidence$search$occurrences
}
}
