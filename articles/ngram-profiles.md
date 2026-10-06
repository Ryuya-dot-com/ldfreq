# N-gram frequencies without bundling a corpus

## What question does this answer?

Suppose an SLA study compares word combinations in essays, or a
psycholinguistic experiment needs reference frequencies for phrases used
as stimuli. Counting each word separately cannot show how often the
combination occurred.
[`lexdiv_ngrams()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
extracts adjacent bigrams and trigrams with their locations;
[`lexdiv_ngram_reference()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
describes a local reference table;
[`lexdiv_ngram_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
looks up the target phrases and retains coverage.

This guide runs entirely in R using authored token sequences. They are
small examples, not empirical evidence or representative English norms.
No corpus download, corpus redistribution or separate data package is
needed. Researchers can use their own appropriately licensed texts or
aggregate tables. Corpus selection, participant language background and
interpretation remain part of the research design.

## Preserve boundaries before counting

Prepare one token per row with a document ID, segment ID, original token
position and term. A segment is a span within which your design allows
adjacency, such as a sentence. Speaker or turn boundaries may require
additional segments. Each document/segment must form one contiguous
block; positions increase inside it. The function never sorts input or
joins segments.

``` r
reference_tokens <- data.frame(
  document_id = c(rep("r1", 8), rep("r2", 4)),
  segment_id = c(rep("s1", 4), rep("s2", 4), rep("s1", 4)),
  token_index = rep(1:4, 3),
  term = c("we", "make", "a", "decision",
           "we", "make", "a", "decision",
           "they", "make", "a", "plan")
)
preparation <- "authored-sentences-lowercase-surface-original-positions-v1"
extracted <- lexdiv_ngrams(reference_tokens, preparation)
extracted$totals
#>   n opportunities documents
#> 1 2             9         2
#> 2 3             6         2
extracted$counts
#>   n term1    term2    term3 count document_count
#> 1 2    we     make     <NA>     2              1
#> 2 2  make        a     <NA>     3              2
#> 3 2     a decision     <NA>     2              1
#> 4 2  they     make     <NA>     1              1
#> 5 2     a     plan     <NA>     1              1
#> 6 3    we     make        a     2              1
#> 7 3  make        a decision     2              1
#> 8 3  they     make        a     1              1
#> 9 3  make        a     plan     1              1
```

There are nine bigram opportunities and six trigram opportunities. Each
of the three four-word segments contributes three bigrams and two
trigrams. Overlapping windows count: `we make a decision` includes both
`we make a` and `make a decision`. No `decision we` is created across
segments.

If an exclusion removes a token, preserve its position gap. This
prevents `make a decision` from becoming a new adjacent phrase
`make decision`:

``` r
with_gap <- data.frame(document_id = "gap_demo", segment_id = "s1",
  token_index = c(1L, 3L), term = c("make", "decision"))
gap_result <- lexdiv_ngrams(with_gap, preparation)
gap_result$documents
#>   document_id n input_tokens opportunities ngram_types    status
#> 1    gap_demo 2            2             0           0 no_ngrams
#> 2    gap_demo 3            2             0           0 no_ngrams
stopifnot(nrow(gap_result$occurrences) == 0L)
```

Do **not** renumber these positions to `1, 2`. The package cannot
recover deleted information. A retained-token index from
[`lexdiv_tokenize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
alone is not an original-position and sentence-boundary record: that
tokenizer can remove punctuation or numbers and renumber the retained
tokens. The current n-gram interface deliberately expects a prepared
table with explicit boundaries. It does not split raw prose into
sentences. When adapting a corpus annotation or another tokenizer,
retain its original order and document how punctuation, contractions,
hyphens, markup and exclusions affect adjacency. For example, removing a
citation inside a sentence must not fabricate a new phrase across the
removed span. Paragraph boundaries alone cannot prevent that error.

## Build a reusable local reference

Describe the actual resource and preparation. A real source reference
should identify the corpus, version, subset, language/variety, register,
period and sampling restrictions, with its citation and license or
access conditions. The metadata fields below are caller declarations;
they do not grant rights or validate representativeness. Save fuller
sampling documentation alongside the reference if needed.

``` r
resource <- list(
  resource_id = "authored_ngram_demo", resource_version = "1",
  creator = "ldfreq example authors",
  source_reference = "Three authored segments; not a sampled English corpus",
  data_license = "Project-authored example",
  transformation_id = "explicit-segments-no-filtering-v1",
  lookup_unit = "adjacent_surface_ngram",
  resource_key_normalization_id = "identity"
)
reference <- lexdiv_ngram_reference(extracted, resource)
reference$totals
#>   n opportunities documents
#> 1 2             9         2
#> 2 3             6         2
```

This reference includes every observed sequence, so `complete` defaults
to `TRUE`. The count sums equal the eligible opportunities separately
for each `n`. The two declared documents form the document population; a
sequence’s `document_count` counts distinct documents, not sentences or
speakers. An optional document roster can include documents with zero
retained tokens. Keep this choice consistent when interpreting document
counts.

## Accumulate a reference in whole-document chunks

When the reference has many documents, retaining all n-gram occurrences
can be unnecessary.
[`lexdiv_ngram_reference_build()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngram_reference_build.md)
calls your reader once for each source ID and adds its counts and
denominators. Each callback returns an ordinary
[`lexdiv_ngrams()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
result. The corpus itself remains outside the package, and no new
dependency is needed.

Here each source is one document from the same authored example:

``` r
read_document <- function(id) {
  rows <- reference_tokens[reference_tokens$document_id == id, ]
  lexdiv_ngrams(rows, preparation, documents = id)
}
built <- lexdiv_ngram_reference_build(c("r1", "r2"), read_document, resource)
built$reference$totals
#>   n opportunities documents
#> 1 2             9         2
#> 2 3             6         2
built$documents
#>   source_id document_id
#> 1        r1          r1
#> 2        r2          r2
stopifnot(identical(built$reference$totals, reference$totals))
```

Use `built$reference` wherever you would use the reference above. Save
the **whole** `built` list with
[`saveRDS()`](https://rdrr.io/r/base/readRDS.html) to retain the source
manifest and document roster too. It records extraction hashes, not
copies of source files. Preserve file versions, original annotation
provenance and the preparation script separately. A different chunk
order can change count-table row order and hashes while leaving counts
and profile values unchanged.

For local prepared token files, a callback can read one file at a time:

``` r
# manifest has unique source_id, file and document_id columns.
# Each RDS contains one prepared document, including its original positions.
read_local <- function(id) {
  row <- manifest[match(id, manifest$source_id), ]
  lexdiv_ngrams(readRDS(row$file), preparation,
    documents = row$document_id, max_ngrams = 200000)
}
built <- lexdiv_ngram_reference_build(manifest$source_id, read_local, resource,
                                     max_types = 1000000)
saveRDS(built, "local-reference-build.rds")
```

A chunk may contain several whole documents, but **never split one
document between chunks**: the same document ID in two chunks is
rejected so that document frequencies can be added correctly. Assigning
artificial new IDs to parts of a document changes the document
population. Empty documents belong in the extraction’s `documents`
roster. The builder checks identical preprocessing labels and requested
`n` values; labels do not establish that two scripts actually prepared
text the same way.

The type limit stops the build without pruning rare phrases.
`complete = TRUE` means every observed phrase in the **supplied sample**
was kept. It does not mean every intended corpus file was supplied; save
a separate audit of failed or excluded files. Repeated passages under
different IDs are not detected.

This is an in-memory accumulator. Counts for all distinct phrases and
the document roster still grow in memory; callbacks must bound their own
input. Merging cumulative type tables also costs time, so many tiny
chunks can be slower. Choose a chunk size suited to your documents and
available memory. There is no automatic resume after an error. The
package does not download anything here, but a user-written callback can
make network calls or other side effects.

## Profile target texts or experimental items

Use a document ID per text, or an item ID as the document ID when the
unit is a stimulus phrase. Identical phrase text may have distinct item
IDs. Retain participant, condition, corpus and item metadata separately
and join by ID; do not collapse repetitions across participants into
independent observations.

``` r
target_tokens <- data.frame(
  document_id = rep(c("decision_item", "choice_item"), each = 3),
  segment_id = "s1", token_index = rep(1:3, 2),
  term = c("make", "a", "decision", "make", "a", "choice")
)
target <- lexdiv_ngrams(target_tokens, preparation,
  documents = c("decision_item", "choice_item", "empty_item"))
profile <- lexdiv_ngram_profile(target, reference)
profile$lookup
#>     document_id segment_id n start_index end_index term1    term2    term3
#> 1 decision_item         s1 2           1         2  make        a     <NA>
#> 2 decision_item         s1 2           2         3     a decision     <NA>
#> 3   choice_item         s1 2           1         2  make        a     <NA>
#> 4   choice_item         s1 2           2         3     a   choice     <NA>
#> 5 decision_item         s1 3           1         3  make        a decision
#> 6   choice_item         s1 3           1         3  make        a   choice
#>   reference_status reference_count reference_document_count
#> 1           listed               3                        2
#> 2           listed               2                        1
#> 3           listed               3                        2
#> 4     not_observed               0                        0
#> 5           listed               2                        1
#> 6     not_observed               0                        0
#>   reference_opportunities frequency_per_million
#> 1                       9              333333.3
#> 2                       9              222222.2
#> 3                       9              333333.3
#> 4                       9                   0.0
#> 5                       6              333333.3
#> 6                       6                   0.0
profile$summary[profile$summary$weighting == "token", ]
#>      document_id n weighting eligible_items listed_items zero_items
#> 1  decision_item 2     token              2            2          0
#> 3  decision_item 3     token              1            1          0
#> 5    choice_item 2     token              2            1          1
#> 7    choice_item 3     token              1            0          1
#> 9     empty_item 2     token              0            0          0
#> 11    empty_item 3     token              0            0          0
#>    unavailable_items lookup_coverage value_coverage mean_frequency_per_million
#> 1                  0             1.0              1                   277777.8
#> 3                  0             1.0              1                   333333.3
#> 5                  0             0.5              1                   166666.7
#> 7                  0             0.0              1                        0.0
#> 9                  0              NA             NA                         NA
#> 11                 0              NA             NA                         NA
#>    status   missing_reason
#> 1      ok             <NA>
#> 3      ok             <NA>
#> 5      ok             <NA>
#> 7      ok             <NA>
#> 9   empty no_target_ngrams
#> 11  empty no_target_ngrams
```

`make a` occurs three times in nine eligible bigram windows:
`3 / 9 * 1e6 = 333333.33` per million bigram opportunities.
`make a decision` occurs twice in six trigram windows, also `333333.33`
per million, but with a different denominator. These deliberately tiny
reference totals are unsuitable for estimating stable population
frequencies.

Rates do not divide by all word tokens. A published table normalized by
word tokens therefore has a different definition, even if it uses the
same “per million” label. A unigram reference such as bundled TUBELEX
lacks the observed co-occurrence counts needed here.

`lookup` keeps each phrase’s document, segment and start/end positions
beside the reference count and document count. `summary` keeps each
document and `n` separate. Token weighting retains repetitions; type
weighting uses each distinct sequence once within that document. Empty
items remain present with missing means and coverage, rather than
zero-frequency scores.

## A missing row is not always an observed zero

For this complete reference, `a choice` and `make a choice` have status
`not_observed`: their counts are zero **in this reference sample**. This
does not show that those phrases are impossible or inappropriate
English. With a positive denominator, those zeros are included in the
mean.

Now suppose a supplied table lists only sequences occurring at least
twice. Keep the original totals and declare the table incomplete:

``` r
pruned_resource <- resource
pruned_resource$resource_id <- "authored_ngram_demo_pruned"
pruned_resource$transformation_id <- "explicit-segments-retain-count-ge-2-v1"
partial <- lexdiv_ngram_reference(
  reference$counts[reference$counts$count >= 2, ],
  pruned_resource, totals = reference$totals,
  preprocessing_id = preparation, complete = FALSE
)
partial_profile <- lexdiv_ngram_profile(target, partial)
comparison <- rbind(
  transform(profile$summary, reference_kind = "complete"),
  transform(partial_profile$summary, reference_kind = "pruned")
)
comparison[comparison$n == 2 & comparison$weighting == "token",
  c("document_id", "reference_kind", "eligible_items", "lookup_coverage",
    "value_coverage", "mean_frequency_per_million")]
#>      document_id reference_kind eligible_items lookup_coverage value_coverage
#> 1  decision_item       complete              2             1.0            1.0
#> 5    choice_item       complete              2             0.5            1.0
#> 9     empty_item       complete              0              NA             NA
#> 13 decision_item         pruned              2             1.0            1.0
#> 17   choice_item         pruned              2             0.5            0.5
#> 21    empty_item         pruned              0              NA             NA
#>    mean_frequency_per_million
#> 1                    277777.8
#> 5                    166666.7
#> 9                          NA
#> 13                   277777.8
#> 17                   333333.3
#> 21                         NA
```

For `choice_item`, the complete-reference bigram mean is `166666.67`,
including the sample zero for `a choice`. The pruned-reference mean is
`333333.33`, based only on `make a`; value coverage is `1/2`. Its
missing key has status `not_listed` and missing count/rate. Do not
interpret the larger conditional mean as greater phrase familiarity. The
lookup coverage and available-value coverage disclose the different
contributing sets. Report both with the resource definition.

External tables default to incomplete. Declaring them complete requires
their count sums to equal the declared opportunities; structural
consistency alone cannot prove the declarations true. Matching
`preprocessing_id` labels are also necessary but cannot prove equivalent
tokenization. Inspect the actual rules. With zero reference
opportunities, all normalized rates are missing, including known
sample-zero counts. The result retains that reason explicitly.

## Compare references on the same target items

[`lexdiv_ngram_compare()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngram_compare.md)
keeps both the available-value summaries above and an additional
comparison on the **same items with defined rates in every reference**.
This distinction matters when missing rows change the apparent mean. The
first named reference is the default baseline; choose another with
`baseline` when the research question requires it.

``` r
references <- list(complete = reference, pruned = partial)
compared <- lexdiv_ngram_compare(target, references, baseline = "complete")
subset(compared$summary, document_id == "choice_item" & n == 2 & weighting == "token",
  select = c(reference_id, mean_frequency_per_million, value_coverage,
    common_items, common_coverage, common_mean_frequency_per_million,
    difference_from_baseline))
#>    reference_id mean_frequency_per_million value_coverage common_items
#> 5      complete                   166666.7            1.0            1
#> 17       pruned                   333333.3            0.5            1
#>    common_coverage common_mean_frequency_per_million difference_from_baseline
#> 5              0.5                          333333.3                        0
#> 17             0.5                          333333.3                        0
compared$references[c("reference_id", "n", "opportunities", "documents", "complete")]
#>   reference_id n opportunities documents complete
#> 1     complete 2             9         2     TRUE
#> 2     complete 3             6         2     TRUE
#> 3       pruned 2             9         2    FALSE
#> 4       pruned 3             6         2    FALSE
```

For `choice_item`, the available-value mean rose from `166666.67` to
`333333.33` after pruning. The common bigram is only `make a`: its
frequency is unchanged, the difference from baseline is **zero**, and
common coverage is **one half**. The higher conditional mean arose from
excluding the sample zero for `a choice`. It was not an increase in that
item’s measured frequency.

`lookup` retains the phrase components and original occurrence
positions, each reference’s counts/status/rates, `common_available`, and
the per-occurrence common-set difference. Use those rows to investigate
which phrases changed; then connect their positions to source
annotations as in the **Annotated corpora and quanteda** guide. Token
weighting retains repetitions, while type weighting counts each sequence
once per document. Differences always subtract the baseline common-set
mean, not unmatched available-value means.

With two complete references and positive denominators, unobserved
phrases have defined sample-zero rates and common coverage can be one.
This does not mean every phrase was observed or that either sample is
large enough. Inspect `lookup_coverage`, document counts, opportunity
totals, registers and source overlap as well. Adding a reference can
reduce the all-reference common set; pass just two references for a
pairwise question. If no common values exist, the comparison mean and
difference are `NA`, with `no_common_values` status. Empty documents
stay present with `empty` status, not zero-frequency scores.

The function checks matching preparation labels, lexical units and key
normalization declarations. Researchers still need to verify the actual
preparation and choose references appropriate to their question. It does
not select a preferred corpus, pool documents, compute significance or
convert frequency differences into proficiency or employability scores.

``` r
path <- tempfile(fileext = ".rds")
saveRDS(list(target = target, references = references, comparison = compared), path)
saved <- readRDS(path)
stopifnot(identical(lexdiv_ngram_compare(saved$target, saved$references,
  baseline = saved$comparison$provenance$baseline), saved$comparison))
unlink(path)
```

Save the reference inputs too: comparison output contains their metadata
and fingerprints, but not the full count tables. Its `max_rows` bound
covers the combined lookup and summary rows before profiling; it is not
a memory limit.

## Save, import and rerun without the original corpus

RDS preserves the reference counts, denominators, metadata and
fingerprint. The original corpus does not need to be installed alongside
it. Use trusted local files and retain the full object rather than only
its mean table.

``` r
reference_file <- tempfile(fileext = ".rds")
saveRDS(reference, reference_file)
restored <- readRDS(reference_file)
repeated <- lexdiv_ngram_profile(target, restored)
stopifnot(identical(profile, repeated))
unlink(reference_file)
```

CSV/TSV tables are another input path. Supply separate totals and
metadata; the constructor does not guess them from a pruned table.
Column names are `n, term1, term2, term3, count, document_count` and
`n, opportunities, documents`. Bigrams require a character `term3`
column with missing values, even in an all-bigram file. Keep terms as
character strings and document the missing-value convention:

``` r
count_file <- tempfile(fileext = ".csv")
totals_file <- tempfile(fileext = ".csv")
write.csv(reference$counts, count_file, row.names = FALSE, na = "",
  fileEncoding = "UTF-8")
write.csv(reference$totals, totals_file, row.names = FALSE)
counts <- read.csv(count_file, na.strings = "", fileEncoding = "UTF-8",
  colClasses = c(term1 = "character", term2 = "character", term3 = "character"))
totals <- read.csv(totals_file)
imported <- lexdiv_ngram_reference(counts, resource, totals,
  preprocessing_id = preparation, complete = TRUE)
stopifnot(identical(lexdiv_ngram_profile(target, imported)$summary,
                    profile$summary))
unlink(c(count_file, totals_file))
```

An existing table without document counts or the original
eligible-window totals does not meet this initial interface. Do not
substitute a word-token total or the sum of a truncated table. Resolve
its definitions before adapting it. To change an admitted reference,
reconstruct it through the constructor; editing a saved result in place
makes its content fingerprint inconsistent. Fingerprints detect
accidental changes, not false metadata or unauthorized data.

## Interpretation and remaining scope

These functions provide extraction, descriptive frequency, coverage and
reference-choice comparisons on an explicit common set. Association
measures such as MI and t-score need positional marginals from the same
eligible-window population; they are not implemented here. Skip-grams,
dependency collocations, automatic sentence parsing, streaming
large-corpus construction and a standard large reference corpus are also
outside this initial interface. The default extraction limit is one
million occurrence rows; it is not a complete memory bound.

For SLA, a reference frequency is a text characteristic whose relation
to performance needs validation across tasks and registers. For
psycholinguistics, it can be a phrase-level predictor or matching
variable alongside word-level frequency and other covariates. Neither
use makes the output a familiarity, processing-speed, proficiency or
employability score. Choose a reference relevant to the target language
variety and exposure, preserve item and participant identities, and keep
dependent observations in the study model.

Local analysis and redistribution are separate decisions. Check the
conditions for both original text and derived counts before sharing
either. Moving a table into a separate R package or deriving counts from
text does not itself establish redistribution permission. This package
distributes the analysis code and authored examples; it does not bundle
third-party n-gram counts.
