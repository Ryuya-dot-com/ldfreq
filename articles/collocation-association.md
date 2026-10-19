# Count nearby words and explain their association

A word can occur near a node often simply because it is common. To
describe association, compare the observed number of pairs with an
expected number computed from an explicit population of possible pairs.
Keep both counts: a high association score from one occurrence deserves
different interpretation from a frequently repeated combination.

This guide uses ldfreq 0.3.0.9010 or later and optional **quanteda \>=
4.5.0**. It starts with adjacent words, then expands to a left/right
span. The two helpers in `examples/collocation.R` use the saved searches
from `examples/concordance.R`. These are explicitly sourced, installed
examples, not exported functions. The examples below are authored for
hand checking; they are not learner data or an assessment of annotation
accuracy.

## Start with a complete, source-linked search

``` r
library(ldfreq)

demo <- new.env(parent = globalenv())
sys.source(system.file("examples", "collocation-demo.R",
  package = "ldfreq", mustWork = TRUE), demo)
helper <- demo$helper
search <- demo$search
print(demo$annotations$segments, row.names = FALSE)
#>  document_id segment_id      text token_count
#>           d1         s1 a b a b c           5
#>           d2         s1   a c b a           4
#>           d2         s2       b a           2
#>          gap         s1     a , b           3
#>      missing         s1   a gap b           3
#>        empty         s1                     0
#>                                                       text_sha256
#>  d110393ed7da5c855423fe9e64e7bac0559ce7da85188465544cfb28fe23e0cb
#>  61312e7448895df2363ff3c60711105fdb4b61bb92389627331e76c067160a3a
#>  beedb4a7ba34c4ea09727022655dd743d5dda2940f1c8e4ec56ff2904324026c
#>  d33dc101d06f8d7fee912c714d098f98f64aed510d78774d6fa632967ce5a892
#>  8e964a33b68f627c79b0409ec2adfa9ec2af20baae5d7a0815fc9a3f61e53bc0
#>  e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
```

The imported tokens retain original positions and character offsets. The
chosen `lemma` column is missing for `gap`; the comma is explicitly
excluded. `d2` has two separate segments. Every segment is a hard
boundary. A segment means a sentence only when your input defines it as
one; the helper does not split sentences automatically.

For your own unchanged
[`lexdiv_import_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md)
result, source both helpers and make a search. See the [concordance
guide](https://ryuya-dot-com.github.io/ldfreq/articles/concordance-and-dispersion.md)
for preparing aligned annotations from your text or parser output.

``` r
helper <- new.env(parent = globalenv())
for (file in c("concordance.R", "collocation.R"))
  sys.source(system.file("examples", file, package = "ldfreq", mustWork = TRUE), helper)
search <- helper$concordance_search(annotations, list(node = "learn"),
  term_col = "lemma", keep = keep, window = 5L)
nearby <- helper$collocation_profile(search, "node", span = c(left = 3L, right = 3L))
```

A node query must have one token pattern. Fixed, wildcard and
regular-expression queries retain their saved search settings. A pattern
matching several forms pools those node positions into one class.
Context terms use exact UTF-8 values of the selected column: the node’s
case-insensitive matching does **not** merge context forms such as
`Word` and `word`. No new case or Unicode normalization is performed.
Specify and preserve any normalization in the annotations.

## Adjacent words: inspect the denominator first

``` r
adjacent <- helper$collocation_profile(search, "a") # L0/R1
print(adjacent$results, digits = 4, row.names = FALSE)
#>  context observed node_marginal context_marginal opportunities expected     MI
#>        b        2             3                3             8    1.125 0.8301
#>        a        0             3                3             8    1.125   -Inf
#>        c        1             3                2             8    0.750 0.4150
#>  t_score documents context_documents meets_min_count        status
#>   0.6187         1                 2            TRUE            ok
#>       NA         0                 2           FALSE zero_observed
#>   0.2500         1                 2            TRUE            ok
print(adjacent$documents, row.names = FALSE)
#>  document_id source_tokens kept_tokens searchable_tokens missing_terms
#>           d1             5           5                 5             0
#>           d2             6           6                 6             0
#>          gap             3           2                 2             0
#>      missing             3           3                 2             1
#>        empty             0           0                 0             0
#>  node_occurrences candidate_slot_pairs eligible_pairs excluded_pairs node_pairs
#>                 2                    4              4              0          2
#>                 3                    4              4              0          1
#>                 1                    2              0              2          0
#>                 1                    2              0              2          0
#>                 0                    0              0              0          0
#>  nodes_with_context            status
#>                   2                ok
#>                   1                ok
#>                   0 no_eligible_pairs
#>                   0 no_eligible_pairs
#>                   0 no_eligible_pairs
```

There are **8 eligible adjacent pairs**, of which **3** start at the
node `a`. The context `b` appears at the right endpoint of **3**
eligible pairs, and the pair `a b` occurs **2** times. Thus its expected
count is `3 * 3 / 8 = 1.125`. These marginals count positions in
eligible pairs, not unrestricted unigram frequencies. Final tokens,
excluded endpoints and segment boundaries affect the denominator.

For each context type, the result includes:

| Column | Meaning in the saved pair population |
|----|----|
| `observed` | Pairs with both a matching node and this context term, O |
| `node_marginal` | All pairs whose node endpoint matches the query, R |
| `context_marginal` | All pairs whose context endpoint has this term, C |
| `opportunities` | All eligible ordered pairs, N |
| `expected` | R × C / N, E |
| `MI` | Pointwise mutual information, log2(O / E) |
| `t_score` | (O − E) / sqrt(O) |
| `documents` | Distinct documents contributing to O |
| `context_documents` | Distinct documents contributing to C |
| `meets_min_count` | Display-selection flag; counts remain complete |
| `status` | `ok`, `zero_observed`, or `no_node_opportunities` |

The MI and t-score definitions follow Evert’s [association-measure
discussion](https://www.stephanie-evert.de/PUB/Evert2007HSK_extended_manuscript.pdf),
Sections 4.1–4.3. MI is sensitive to rare combinations; report O and
choose a frequency threshold explicitly. Here t-score is a descriptive
association measure, not a Student t statistic or a significance test.
Overlapping windows share tokens, and documents may share writers; these
rows are not independent observations for a study-level model.

The helper applies **no smoothing**. When O = 0 and E \> 0, MI is `-Inf`
and t-score is `NA` (`zero_observed`). When no eligible pair starts at a
matching node, E = 0 and both scores are `NA` (`no_node_opportunities`).
With no eligible pairs at all, the results table is empty and document
status explains why. Only context types present in eligible pairs
receive rows. An absent row is not a claim of zero frequency in an
external corpus, and a missing lemma is not a known zero.

## Expand the span without changing the meaning of a position

``` r
span <- helper$collocation_profile(search, "a", span = c(left = 2L, right = 2L))
print(span$results, digits = 4, row.names = FALSE)
#>  context observed node_marginal context_marginal opportunities expected      MI
#>        b        8            13               12            30    5.200  0.6215
#>        a        2            13               13            30    5.633 -1.4940
#>        c        3            13                5            30    2.167  0.4695
#>  t_score documents context_documents meets_min_count status
#>   0.9899         4                 4            TRUE     ok
#>  -2.5692         1                 4            TRUE     ok
#>   0.4811         2                 2            TRUE     ok
print(span$documents[c("document_id", "candidate_slot_pairs",
  "eligible_pairs", "excluded_pairs", "node_occurrences", "nodes_with_context", "node_pairs")],
  row.names = FALSE)
#>  document_id candidate_slot_pairs eligible_pairs excluded_pairs
#>           d1                   14             14              0
#>           d2                   12             12              0
#>          gap                    6              2              4
#>      missing                    6              2              4
#>        empty                    0              0              0
#>  node_occurrences nodes_with_context node_pairs
#>                 2                  2          6
#>                 3                  3          5
#>                 1                  1          1
#>                 1                  1          1
#>                 0                  0          0
```

The span example has **30 eligible ordered pairs**. Each ordered pair of
original positions within the requested distance is one opportunity.
Both endpoints must be searchable, and they must belong to the same
segment. The span includes all distances from 1 to the chosen width on
each side; `left = 0` or `right = 0` selects only the other direction.

These rules determine the counts:

- A node token cannot pair with itself. Two occurrences of the same word
  can pair with each other. With both directions enabled, `(i, j)` and
  `(j, i)` are separate ordered opportunities.
- Repeated context tokens each count. Two node tokens may pair with the
  same context token: their original position pairs are different.
- Excluded or missing endpoints cannot form a pair. Intervening excluded
  or missing slots still consume distance and do not block a wider-span
  pair. Thus `a , b` can contribute at distance +2, but never at +1.
  Splitting the input into sentence segments is the way to prohibit
  sentence crossing.
- Node and context marginals and N are recounted over this whole pair
  population. Do not substitute corpus unigram totals, or multiply the
  node frequency by twice the span: boundaries and endpoint availability
  matter.
- Left and right distances are pooled within a call. To describe one
  side, run a separate call with the other width zero; filtering the
  saved pairs afterward would invalidate the original scores and
  denominators.

This is an independence model for the two roles in a population of
**ordered token pairs**. It is not the conventional surface-window
approximation using unigram frequencies times span width. Scores from
tools using different populations or exclusion rules need not agree.

The complete `$pairs` table contains background opportunities as well as
matching node pairs. `$documents` retains empty and zero-match
documents, original/searchable/missing token counts, candidate and
eligible pair counts, node occurrences, and nodes with at least one
eligible context. By default, `max_pairs = 1e6` bounds **all candidate
slot pairs before endpoint exclusions**. Exceeding the bound raises an
error rather than truncating the sample. This is not a full memory bound
or a streaming large-corpus engine.

## Select frequent combinations and return to their source

``` r
selected <- helper$collocation_profile(search, "a", min_count = 2L)
shown <- subset(selected$results, meets_min_count)
shown <- shown[order(-shown$MI, -shown$observed), ]
print(shown, digits = 4, row.names = FALSE)
#>  context observed node_marginal context_marginal opportunities expected     MI
#>        b        2             3                3             8    1.125 0.8301
#>  t_score documents context_documents meets_min_count status
#>   0.6187         1                 2            TRUE     ok
```

`min_count` is a positive whole number. It sets a flag; it never removes
pairs, changes marginals, or overwrites below-threshold counts. The
default of 1 includes singletons for inspection and is not a
recommendation for ranking rare combinations. Choose a threshold
appropriate to your corpus and report it.

``` r
pairs <- subset(span$pairs, is_node & context_term == "b")
kwic <- span$search$occurrences[
  match(pairs$occurrence_id, span$search$occurrences$occurrence_id), ]
inspection <- data.frame(document_id = pairs$document_id,
  segment_id = pairs$segment_id, node_position = pairs$node_position,
  context_position = pairs$context_position, distance = pairs$distance,
  pre = kwic$pre, node = kwic$keyword, post = kwic$post,
  context = span$search$source$tokens$surface[pairs$context_row])
print(inspection, row.names = FALSE)
#>  document_id segment_id node_position context_position distance  pre node
#>           d1         s1             1                2        1         a
#>           d1         s1             3                2       -1 a b     a
#>           d1         s1             3                4        1 a b     a
#>           d2         s1             1                3        2         a
#>           d2         s1             4                3       -1 c b     a
#>           d2         s2             2                1       -1   b     a
#>          gap         s1             1                3        2         a
#>      missing         s1             1                3        2         a
#>    post context
#>     b a       b
#>     b c       b
#>     b c       b
#>     c b       b
#>               b
#>               b
#>     , b       b
#>   gap b       b
```

Each matching pair links to a saved node occurrence ID, original token
rows and segment-local, 1-based inclusive character offsets. A node KWIC
may appear more than once because it contributed several pairs. Its
display window comes from the original search; choose a search window at
least as wide as the collocation span to see all the context in this
display. The full original segment remains available even with a
narrower KWIC window.

## Save the complete record and replay it

``` r
record <- list(adjacent = adjacent, span = span, session = sessionInfo())
file <- tempfile(fileext = ".rds") # use a durable project path for your analysis
saveRDS(record, file, version = 2)
reopened <- readRDS(file)
helper$collocation_validate(reopened$span)
replayed <- helper$collocation_profile(reopened$span$search, "a",
  span = reopened$span$settings$span)
stopifnot(identical(replayed, reopened$span))
unlink(file)
```

Retain the full object, source annotations, helper/package versions and
session information; a CSV of selected scores cannot reconstruct the
denominator. `collocation_validate()` detects accidental changes to the
saved record, including its search. It is not an authenticity check for
supplied annotations. Exact whole-object replay requires the same
package version; after an upgrade, compare counts and settings
explicitly instead of assuming object identity.

## What was checked, and what the scores do not establish

The authored example’s adjacent pairs agree with
[`lexdiv_ngrams()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md).
A separate Cartesian enumeration verifies the pair sets and 2×2 tables
for left-only, right-only and two-sided spans, including segment
boundaries, repeated nodes, excluded endpoints and missing terms.
Positive-count scores were checked against `corpora` 0.7’s
[am.score()](https://cran.r-project.org/web/packages/corpora/corpora.pdf)
with the same positional marginals and `span.size = 1`: the span is
already represented by the pair population. The deliberate `NA` t-score
convention at O = 0 is checked separately. `corpora` is not needed to
run these helpers.

These checks concern counting and numerical reproduction on constructed
data. They do not validate idiomaticity, semantic cohesion, language
proficiency, or performance on a natural corpus. Phrase nodes,
dependency relations and automatic sentence detection are outside this
example. The existing [n-gram reference
profiles](https://ryuya-dot-com.github.io/ldfreq/articles/ngram-profiles.md)
retain their own frequency and coverage contracts; a pruned reference
table cannot supply missing marginals. Preserve writer, task and
occasion identifiers when relating text measures to research outcomes,
as in the [repeated-observations
guide](https://ryuya-dot-com.github.io/ldfreq/articles/repeated-observations.md).
