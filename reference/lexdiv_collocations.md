# Count collocation opportunities and descriptive association scores

Use one saved single-token concordance query as the node and retain all
eligible ordered token-pair opportunities for MI and t-score. No
tokenizer, model or statistical significance decision is supplied.

## Usage

``` r
lexdiv_collocations(search, query_id, span = c(left = 0L, right = 1L),
                    min_count = 1L, max_pairs = 1e6)
```

## Arguments

- search:

  Unchanged complete result of
  [`lexdiv_concordance`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_concordance.md),
  or a legacy plain-list `concordance_search()` result. No new search is
  run.

- query_id:

  One saved single-token query. Multi-token phrase nodes are rejected.

- span:

  Named numeric vector `c(left = ..., right = ...)` of nonnegative whole
  widths in original token slots. At least one width must be positive.

- min_count:

  Positive whole observed-count threshold, reported only as a display
  flag. It does not prune opportunities or change the denominator.

- max_pairs:

  Positive whole-number limit on candidate ordered slot pairs, checked
  before allocation. Excluded pairs still count toward this limit.

## Details

Pairs are ordered and stay within the supplied segment. Both endpoints
must be searchable; intervening excluded positions do not compress
distance or block a pair. Repeated nodes and overlapping windows
contribute distinct position pairs. The node marginal, context-term
marginal and total opportunity count all use the same eligible pair
population, not an unrelated unigram frequency table.

Expected count is `node_marginal * context_marginal / opportunities`. MI
is `log2(observed / expected)` and t-score is
`(observed - expected) / sqrt(observed)`. With positive expectation and
zero observation, MI is `-Inf` and t-score is `NA`; zero expectation has
reasoned missing scores. No smoothing is applied. Scores are
descriptive; high MI at low counts does not establish idiomaticity or
semantic unity.

The computations and layout preserve the previous installed example.
`examples/collocation.R` remains a compatibility entry for
`collocation_profile()`. See
[`vignette("collocation-association")`](https://ryuya-dot-com.github.io/ldfreq/articles/collocation-association.md).

## Value

A plain list with `results` (counts, marginals, opportunities,
expectation, MI, t-score, document frequencies, threshold flag and
status), `documents`, `pairs` (eligible positions, source spans and node
occurrence IDs), complete `search`, `settings`, `provenance` and
`integrity_sha256`. Save the whole result to retain the count population
and original text.

## Examples

``` r
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
```
