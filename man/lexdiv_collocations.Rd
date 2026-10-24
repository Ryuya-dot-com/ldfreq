\name{lexdiv_collocations}
\alias{lexdiv_collocations}
\title{Count collocation opportunities and descriptive association scores}
\description{
Use one saved single-token concordance query as the node and retain all eligible
ordered token-pair opportunities for MI and t-score. No tokenizer, model or
statistical significance decision is supplied.
}
\usage{
lexdiv_collocations(search, query_id, span = c(left = 0L, right = 1L),
                    min_count = 1L, max_pairs = 1e6)
}
\arguments{
\item{search}{Unchanged complete result of \code{\link{lexdiv_concordance}}, or
a legacy plain-list \code{concordance_search()} result. No new search is run.}
\item{query_id}{One saved single-token query. Multi-token phrase nodes are rejected.}
\item{span}{Named numeric vector \code{c(left = ..., right = ...)} of nonnegative
whole widths in original token slots. At least one width must be positive.}
\item{min_count}{Positive whole observed-count threshold, reported only as a
display flag. It does not prune opportunities or change the denominator.}
\item{max_pairs}{Positive whole-number limit on candidate ordered slot pairs,
checked before allocation. Excluded pairs still count toward this limit.}
}
\details{
Pairs are ordered and stay within the supplied segment. Both endpoints must be
searchable; intervening excluded positions do not compress distance or block a
pair. Repeated nodes and overlapping windows contribute distinct position pairs.
The node marginal, context-term marginal and total opportunity count all use the
same eligible pair population, not an unrelated unigram frequency table.

Expected count is \code{node_marginal * context_marginal / opportunities}.
MI is \code{log2(observed / expected)} and t-score is
\code{(observed - expected) / sqrt(observed)}. With positive expectation and
zero observation, MI is \code{-Inf} and t-score is \code{NA}; zero expectation
has reasoned missing scores. No smoothing is applied. Scores are descriptive;
high MI at low counts does not establish idiomaticity or semantic unity.

The computations and layout preserve the previous installed example.
\code{examples/collocation.R} remains a compatibility entry for
\code{collocation_profile()}. See \code{vignette("collocation-association")}.
}
\value{
A plain list with \code{results} (counts, marginals, opportunities, expectation,
MI, t-score, document frequencies, threshold flag and status), \code{documents},
\code{pairs} (eligible positions, source spans and node occurrence IDs), complete
\code{search}, \code{settings}, \code{provenance} and \code{integrity_sha256}.
Save the whole result to retain the count population and original text.
}
\examples{
segments <- data.frame(document_id = "d1", segment_id = "s1", text = "a b a b c")
tokens <- data.frame(document_id = "d1", segment_id = "s1", token_index = 1:5,
  surface = c("a", "b", "a", "b", "c"))
source <- lexdiv_import_annotations(tokens, segments, list(language = "en",
  analyzer = "authored", analyzer_version = "1", dictionary = "none",
  dictionary_version = "none", unit = "supplied tokens", normalization = "none"))
if (requireNamespace("quanteda", quietly = TRUE)) {
  search <- lexdiv_concordance(source, list(node = "a"))
  lexdiv_collocations(search, "node")$results
}
}
