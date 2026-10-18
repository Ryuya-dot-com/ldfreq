# Compare word use against an explicit reference corpus

Which words occur relatively more often in one corpus than in another?
The answer depends on the reference: its genres, topics, writers and
collection conditions help determine what a difference means. Keyness
describes that comparison; it does not by itself measure language
proficiency or writing quality.

This guide uses ldfreq **0.3.0.9011 or later**. The explicitly sourced
helpers in `examples/keyness.R` retain both corpora, the tokens counted,
the two-by-two tables, and links back to the original text. They are
installed examples, not exported functions. Counting needs no optional
package; returning to KWIC uses **quanteda \>= 4.5.0**. The inputs below
are authored for checking calculations, not learner data or an
evaluation of annotation accuracy.

## Declare the documents and inspect the coverage

``` r
demo <- new.env(parent = globalenv())
sys.source(system.file("examples", "keyness-demo.R",
  package = "ldfreq", mustWork = TRUE), demo)
helper <- demo$helper
comparison <- demo$comparison
knitr::kable(comparison$totals[c("corpus", "documents", "source_tokens",
  "missing_terms", "counted_tokens")], row.names = FALSE)
```

| corpus    | documents | source_tokens | missing_terms | counted_tokens |
|:----------|----------:|--------------:|--------------:|---------------:|
| target    |         3 |            10 |             1 |              8 |
| reference |         3 |             8 |             0 |              8 |

The target is `t1`, `t2`, `t_empty`; the reference is `r1`, `r2`,
`r_empty`. Both have **8 counted tokens**. The target has 10 original
tokens: a period is excluded and one retained token has no lemma. The
document `outside` is not in either corpus. Empty documents remain
declared documents; they do not supply tokens to the denominator.

``` r
knitr::kable(demo$annotations$segments[c("document_id", "text")], row.names = FALSE)
```

| document_id | text                           |
|:------------|:-------------------------------|
| t1          | learn learn learn learn read . |
| t2          | learn learn write unknown      |
| t_empty     |                                |
| r1          | learn read read read           |
| r2          | learn read read speak          |
| r_empty     |                                |
| outside     | unlisted unlisted              |

For your own unchanged
[`lexdiv_import_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md)
result, source both helpers explicitly. The [concordance
guide](https://ryuya-dot-com.github.io/ldfreq/articles/concordance-and-dispersion.md)
explains how to prepare complete, aligned annotations with original
offsets.

``` r
helper <- new.env(parent = globalenv())
for (file in c("concordance.R", "keyness.R"))
  sys.source(system.file("examples", file, package = "ldfreq", mustWork = TRUE), helper)
comparison <- helper$keyness_compare(annotations,
  target = target_document_ids, reference = reference_document_ids,
  preprocessing_id = "lemma-exclude-punctuation-v1",
  term_col = "lemma", keep = keep)
```

`target` and `reference` must each contain unique, known document IDs,
with no ID shared between them. Unlisted documents are explicitly
excluded rather than silently becoming the reference. `keep` has one
non-missing logical value per original token, including tokens in
excluded documents. Define the same unit and selection policy for both
corpora, and name that policy in `preprocessing_id`. This label does not
execute preprocessing: the saved annotation metadata and mask record
what was actually supplied.

Terms use exact UTF-8 values of `term_col`, with no added case folding,
Unicode normalization or lemmatization. Missing and whitespace-only
terms cannot be counted. The vocabulary is the union of counted terms in
the two corpora; a term absent from both has no row. Differences between
annotation tools or selection policies can create apparent keyness.
Inspect those conditions before interpreting a corpus contrast.

`$token_audit` records each token’s corpus, selection, availability and
counting status. `$documents` retains source, retained, missing and
counted token totals for every document. It also flags documents whose
**ordered original segment texts are identical across groups**. This
includes matching empty documents. The flag does not detect near
duplicates or identical text split into different segments, and does not
remove anything. Resolve substantive overlap in your corpus design and
repeat the comparison if its membership changes.

## Read counts before scores

``` r
counts <- comparison$results
knitr::kable(counts[c("term", "target_count", "reference_count",
  "target_documents", "reference_documents")], row.names = FALSE,
  col.names = c("Term", "Target tokens", "Reference tokens", "Target documents", "Reference documents"))
```

| Term  | Target tokens | Reference tokens | Target documents | Reference documents |
|:------|--------------:|-----------------:|-----------------:|--------------------:|
| learn |             6 |                2 |                2 |                   2 |
| read  |             1 |                5 |                1 |                   2 |
| write |             1 |                0 |                1 |                   0 |
| speak |             0 |                1 |                0 |                   1 |

`learn` occurs 6 times in the target and twice in the reference. Its
table includes **all other counted terms**, not just words chosen for
display:

``` r
word <- subset(counts, term == "learn")
table2 <- rbind(target = c(word$target_count, word$target_other),
  reference = c(word$reference_count, word$reference_other))
colnames(table2) <- c("learn", "All other terms")
knitr::kable(table2)
```

|           | learn | All other terms |
|:----------|------:|----------------:|
| target    |     6 |               2 |
| reference |     2 |               6 |

For each cell, expected count E is its row total times its column total,
divided by the grand total. Here all four expectations are 4. The
uncorrected likelihood-ratio statistic is **G² = 2 sum\[O log(O /
E)\]**, using natural logarithms and a contribution of zero when O = 0.
This is the comparison of a shared word probability with separate corpus
probabilities described by [Dunning (1993, Section
5.3)](https://aclanthology.org/J93-1003/). Every observed and expected
cell is retained in `$results`.

``` r
knitr::kable(counts[c("term", "target_per_1000", "reference_per_1000", "log_ratio")],
  digits = 4, row.names = FALSE,
  col.names = c("Term", "Target per 1,000", "Reference per 1,000", "Log2 ratio"))
```

| Term  | Target per 1,000 | Reference per 1,000 | Log2 ratio |
|:------|-----------------:|--------------------:|-----------:|
| learn |              750 |                 250 |     1.5850 |
| read  |              125 |                 625 |    -2.3219 |
| write |              125 |                   0 |        Inf |
| speak |                0 |                 125 |       -Inf |

``` r
knitr::kable(counts[c("term", "G2", "signed_G2", "direction")],
  digits = 4, row.names = FALSE)
```

| term  |     G2 | signed_G2 | direction |
|:------|-------:|----------:|:----------|
| learn | 4.1860 |    4.1860 | target    |
| read  | 4.5567 |   -4.5567 | reference |
| write | 1.4530 |    1.4530 | target    |
| speak | 1.4530 |   -1.4530 | reference |

- `G2` is nonnegative. `signed_G2` adds the direction of the **rate**
  difference: positive for the target, negative for the reference, zero
  for equal rates. The negative value is a ranking convention, not a
  negative chi-squared statistic.
- `log_ratio` is
  `log2(target_count / target_total) - log2(reference_count / reference_total)`.
  A value of 1 means twice the rate; -1 means half. For `learn`, the
  rates are 750 and 250 per 1,000, giving log2(3), approximately 1.585.
- G² changes with the amount of data even when rates stay the same. Read
  it beside raw counts, rates, log-ratio and document frequencies, not
  as an effect-size measure alone.

No continuity correction or smoothing is applied. An observed zero in
just one corpus produces a finite G² and an infinite log-ratio (`Inf` or
`-Inf`). That infinity describes a sample zero, not evidence for an
unlimited population effect. If either corpus has no counted tokens, the
comparison scores are `NA` with `empty_target` or `empty_reference`
status. With both empty, `$results` has no rows and `$totals$status`
explains why. If a term accounts for every counted token in both
nonempty corpora, its rates are equal and its scores are zero
(`constant_feature`). Missing annotations never become known zero
counts.

These helpers produce **descriptive scores, without p-values or
significance decisions**. Tokens within documents, repeated texts from
one writer, and words examined in the same search are not independent
study observations. Ranking many words also selects extreme contrasts.
Do not interpret this table as adjusted multiple testing or as a
substitute for a model that addresses the research design. Preserve
writer, task and occasion IDs using the [repeated-observations
workflow](https://ryuya-dot-com.github.io/ldfreq/articles/repeated-observations.md).

## Select rows while retaining the original comparison

``` r
selected <- helper$keyness_compare(comparison$source,
  target = comparison$settings$target, reference = comparison$settings$reference,
  preprocessing_id = comparison$settings$preprocessing_id,
  term_col = comparison$settings$term_col, keep = comparison$settings$keep,
  min_count = 2L)
shown <- subset(selected$results, meets_min_count)
shown <- shown[order(-shown$signed_G2), ]
knitr::kable(shown[c("term", "target_count", "reference_count", "signed_G2")],
  digits = 4, row.names = FALSE)
```

| term  | target_count | reference_count | signed_G2 |
|:------|-------------:|----------------:|----------:|
| learn |            6 |               2 |    4.1860 |
| read  |            1 |               5 |   -4.5567 |

`min_count` is a positive whole number applied to pooled frequency. It
only changes a display flag: the vocabulary, counts, background terms
and denominators remain complete. Its default of 1 allows singletons to
be inspected; it is not a recommendation to rank rare terms without
scrutiny. Changing `keep`, in contrast, changes which tokens contribute
to both the counts and denominators.

`$document_counts` stores positive counts by document, corpus and term
without allocating a dense document-by-vocabulary table. To inspect a
selected word, join these counts to `$documents`, retaining declared
empty documents. A missing row there means no counted occurrence;
consult the token coverage before treating that as complete observation
of the word’s absence.

## Return to exactly the counted occurrences

``` r
context <- helper$keyness_concordance(comparison, "learn", window = 2L)
hits <- context$search$occurrences
hits$corpus <- comparison$documents$corpus[
  match(hits$document_id, comparison$documents$document_id)]
knitr::kable(hits[c("document_id", "corpus", "pre", "keyword", "post")], row.names = FALSE)
```

| document_id | corpus    | pre         | keyword | post          |
|:------------|:----------|:------------|:--------|:--------------|
| t1          | target    |             | learn   | learn learn   |
| t1          | target    | learn       | learn   | learn learn   |
| t1          | target    | learn learn | learn   | learn read    |
| t1          | target    | learn learn | learn   | read .        |
| t2          | target    |             | learn   | learn write   |
| t2          | target    | learn       | learn   | write unknown |
| r1          | reference |             | learn   | read read     |
| r2          | reference |             | learn   | read read     |

``` r
stopifnot(sum(hits$corpus == "target") == word$target_count,
  sum(hits$corpus == "reference") == word$reference_count)
```

This search uses the saved counting mask and one exact term, including
its case and Unicode form. It returns 6 target and 2 reference
occurrences of `learn`. The KWIC shows original surface text even when
counting lemmas; excluded or missing nearby tokens still appear in the
context. Original document/segment IDs, token indices and inclusive
character offsets connect each match to the source. The returned
`comparison_id` identifies its comparison. Use a UTF-8 `LC_CTYPE` locale
for non-ASCII KWIC terms, as required by the adapter.

By default, `max_tokens = 1e6` bounds the complete source passed to
`keyness_compare()`, before exclusions. KWIC’s separate
`max_cells = 1e6` bounds stored matches and context cells as in the
concordance guide. Exceeding either bound raises an error instead of
truncating the analysis. These limits are not a guarantee of total
memory use or a streaming large-corpus implementation.

## Save the reasons, source and complete result

``` r
record <- list(comparison = comparison,
  target_reason = "Authored target documents for checking the calculation",
  reference_reason = "Disjoint authored reference with known counts",
  session = sessionInfo())
file <- tempfile(fileext = ".rds") # use a durable project path for your analysis
saveRDS(record, file, version = 2)
reopened <- readRDS(file)
helper$keyness_validate(reopened$comparison)
s <- reopened$comparison$settings
replayed <- helper$keyness_compare(reopened$comparison$source,
  target = s$target, reference = s$reference, preprocessing_id = s$preprocessing_id,
  term_col = s$term_col, keep = s$keep, min_count = s$min_count, max_tokens = s$max_tokens)
stopifnot(identical(replayed, reopened$comparison))
unlink(file)
```

Record why the target and reference answer your question, including
their collection and overlap checks. A different reference is a
different comparison: repeat the calculation, keep both records, and
explain the change. A selected CSV alone cannot reconstruct the
background denominator. Validation detects accidental edits, not the
authenticity or quality of supplied annotations. Exact whole-object
replay requires the same package/helper version; after an upgrade,
compare counts and settings explicitly.

## Numerical checks and their scope

Hand counts and separate binomial log-likelihood calculations check the
formula. Across 544 small two-by-two tables, including zero cells,
unequal corpus sizes and equal rates, signed G² agrees within `1e-7`
with
[quanteda.textstats](https://search.r-project.org/CRAN/refmans/quanteda.textstats/html/textstat_keyness.html)
0.97.2 using `measure = "lr", correction = "none"`. Specify that
correction explicitly when comparing implementations. Its logarithms use
a small numerical offset, so exact ties can differ slightly from zero.
The independent likelihood calculation agrees within `1e-12`.
quanteda.textstats is not required to run this example, and its p-values
are not imported.

These are counting and numerical checks on constructed inputs, not
evidence that a reference corpus represents a population or that a word
contrast measures proficiency. This example compares single annotated
terms. For nearby-word association, use the separate [collocation
guide](https://ryuya-dot-com.github.io/ldfreq/articles/collocation-association.md),
whose population consists of token pairs rather than corpus word totals.
