# Designing comparable lexical-diversity analyses

## Start with a question and a comparison unit

Suppose the question is whether writers use a greater variety of word
forms locally in responses to the same writing task. The observations
are documents; repeated responses by the same writer are not independent
participants. Fix the task, population, lexical unit, preprocessing, and
common window size before comparing groups. A result about local
surface-form variety is not automatically a result about vocabulary
knowledge, proficiency, or writing quality.

The runnable examples below use synthetic sequences and authored
teaching essays to isolate effects of length, order and window size. A
separate executed PELIC example uses actual learner writing. Neither the
teaching examples nor that small observational sample establish a
population effect or validate a window for every task.

## Native-speaker corpora are also analysis targets

The package does not restrict input to English learners. Native-speaker
conversation, student essays, professional writing and other registers
can be studied in their own right. L1/L2 comparison is another
application, not a requirement for a corpus study. A corpus can play
three different roles:

| Role | Example question | What the observations support |
|----|----|----|
| Analysis sample | How do local lexical variety and repetition vary across spoken and written registers? | Description of the sampled texts under the selected unit and parameters |
| Reference resource | Does a text’s frequency profile change with the reference register? | Dependence on the reference vocabulary, corpus composition and coverage |
| Comparison sample | How do comparable L1 and L2 responses to a task differ? | A conditional group comparison, with task and sampling differences still considered |

For student writing,
[LOCNESS](https://corpora.uclouvain.be/catalog/en/corpus/locness)
contains essays by British and American native English students. For
natural conversation, [Spoken
BNC2014](https://www.lancaster.ac.uk/news/articles/2017/researchers-release-largest-ever-public-collection-of-british-conversations/)
contains spontaneous British English conversations recorded among
friends and family.
[COCA](https://www.english-corpora.org/coca/help/tour.asp) supplies a
broader register contrast, including spoken, fiction, news and academic
texts. These are candidate sources, not bundled datasets or
automatically matched control groups. General-English coverage alone
does not verify every contributor’s L1 background; use documented
participant metadata if that is an inclusion criterion.

An initial corpus study can test whether conclusions about lexical
variety survive changes in window length, word unit and reference
resource within each register. Then compare populations where age,
education, task, topic, mode, time constraints and editing conditions
are sufficiently aligned. Do not interpret a difference between edited
professional articles and timed learner essays as a pure effect of
language background. Native speakers also vary; neither higher diversity
nor lower reference frequency is a universal target.

Retain a document metadata table with `document_id`, `corpus_id`, corpus
version, author/speaker ID, documented language background, register,
task/topic and collection period. Join it to result rows by unique
document ID; the metric functions do not discover or automatically carry
arbitrary metadata columns. Keep unknown background as unknown. Do not
concatenate a whole corpus into one document: local windows must not
cross unrelated text boundaries, and pooled tokens answer a different
question from typical-document scores.

For conversations, specify whether a unit is a conversation, a speaker’s
turn, or a defined sequence of turns. Record treatment of transcription
tags, fillers, false starts and repairs before tokenization. Removing
other speakers’ turns can create artificial adjacency in a speaker-only
stream; do not treat that stream as uninterrupted speech. Repeated turns
from one speaker are not independent participants. The English tokenizer
is not a corpus-XML parser.

The existing batch and profile APIs can perform these calculations.
Compare document distributions and missing-result/coverage patterns by
the chosen strata, preserving author/speaker dependencies in any later
inference. Corpus frequencies and attested uses describe a sample;
individual vocabulary ability requires additional evidence. The
[vocabulary-use
guide](https://ryuya-dot-com.github.io/ldfreq/articles/vocabulary-knowledge-and-use.md)
addresses that separate question using paired response data.

## Why use a common MATTR window?

MATTR averages the proportion of distinct types over all complete
windows of a specified size. A common window makes its local denominator
explicit. Global TTR supplies a useful contrast: it depends on the full
document length.

``` r
vocabulary <- c("river", "stone", "tree", "cloud")
documents <- list(
  blocked = rep(vocabulary, each = 30),
  interleaved = rep(vocabulary, 30),
  interleaved_long = rep(vocabulary, 60)
)
primary <- lexdiv_metrics_batch(documents,
  metrics = c("ttr", "mattr"), window_length = 20)
primary[, c("document_id", "metric_id", "N", "V", "value", "status")]
#> <lexdiv_batch_results: 3 documents; 6 metric records; schema unknown>
#>        document_id metric_id      value status   N V
#> 1          blocked       ttr 0.03333333     ok 120 4
#> 2          blocked     mattr 0.07821782     ok 120 4
#> 3      interleaved       ttr 0.03333333     ok 120 4
#> 4      interleaved     mattr 0.20000000     ok 120 4
#> 5 interleaved_long       ttr 0.01666667     ok 240 4
#> 6 interleaved_long     mattr 0.20000000     ok 240 4
```

The first two sequences have identical length and type frequencies.
Their TTRs are equal, but MATTR differs because one clusters repetition
and the other spreads the same four words across every window. Doubling
the interleaved sequence halves TTR while leaving its MATTR unchanged at
4/20. This controlled example answers why local and whole-document
variety need not agree; it does not show that MATTR is
length-independent for arbitrary texts.

In a real raw-text analysis, tokenize every document with the same
explicit choices, such as NFC and lowercase, and retain the resulting
provenance. Lowercasing merges case distinctions; selecting lemmas
changes type identity; restricting to content words changes both order
spacing and the denominator. Use annotation coverage to check whether
exclusions differ between groups. Do not choose a different lexical unit
only for documents with poor coverage.

## Separate the main comparison from parameter sensitivity

Window 20 is an illustrative choice, not a recommended universal value.
A second common window asks whether the conclusion is sensitive to the
local scale. Do not pool the scores as interchangeable measurements.

``` r
mattr_method <- lexdiv_methods()$method_id[
  lexdiv_methods()$metric_id == "mattr"]
plan <- lexdiv_plan(presets = character(), grids = lexdiv_grid(
  mattr_method, "window_length", c(20, 40), request_id_prefix = "window"))
sensitivity <- lexdiv_profile_batch(documents, plan)
sensitivity[, c("document_id", "request_id", "value", "requested_parameters")]
#> <lexdiv_profile_batch_results: 3 documents; 6 specification results; schema unknown>
#>        document_id request_id      value
#> 1          blocked   window_1 0.07821782
#> 2          blocked   window_2 0.05555556
#> 3      interleaved   window_1 0.20000000
#> 4      interleaved   window_2 0.10000000
#> 5 interleaved_long   window_1 0.20000000
#> 6 interleaved_long   window_2 0.10000000
wide <- lexdiv_widen(sensitivity)
```

Interleaved MATTR changes from 4/20 to 4/40 solely because its window
changes. A plot must therefore select one request, for example
`plot(sensitivity, request_id = "window_1")`. The default wide table
retains the contract, method, parameters, and counts. Request labels are
local to a plan: when combining independently constructed plans,
separate differing conditions or use `names_from = "specification_id"`.

Documents shorter than the requested window receive a missing result;
the package does not silently shrink their window. Report these
exclusions by group. A computable score or a passed token-floor screen
does not establish acceptable precision or eliminate length effects.
Estimate uncertainty with a design that respects writers, tasks, and
other sampling dependencies; these descriptive metric functions do not
perform that inferential analysis.

## Distinguish current MTLD from the legacy min10 calculation

From package 0.3.0, core MTLD closes a factor whenever running TTR is
strictly below the threshold, without a minimum factor length. It checks
every token, including the last. The earlier min10 method is preserved
for reproduction.

``` r
mtld_boundary <- data.frame(N = c(50L, 51L, 52L, 59L, 60L))
mtld_boundary$MTLD <- vapply(mtld_boundary$N, function(n) {
  lexdiv_metrics(rep("a", n), metrics = "mtld")$value
}, numeric(1))
mtld_boundary$legacy_min10 <- vapply(mtld_boundary$N, function(n) {
  lexdiv_variant_metrics(rep("a", n),
    variants = "mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1")$value
}, numeric(1))
mtld_boundary
#>    N     MTLD legacy_min10
#> 1 50 2.000000    10.000000
#> 2 51 2.040000    10.200000
#> 3 52 2.000000     7.663158
#> 4 59 2.034483     7.217476
#> 5 60 2.000000    10.000000
```

For 50 or 60 identical tokens, current MTLD is 2. With odd token counts,
the last singleton adds zero residual credit, so a small length effect
remains. The legacy 59-token result is about 7.22 and the 60-token
result is 10. Its short repetitive tail can contribute more than one
factor because closure is blocked until ten tokens. Keep these methods
separate in reports and saved analyses; a shared metric name does not
make values interchangeable.

Core contract 0.2.0 gives the no-minimum method a new method ID. Saved
result RDS files retain their original values and identities. Recreate
old plans explicitly for new computation; see
[`?lexdiv_metrics`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
for migration details. The [external
comparisons](https://github.com/Ryuya-dot-com/ldfreq/tree/main/experiments/external-metrics)
show the actual koRpus and TAALED outputs and account for remaining
differences.

### Check the effect on your documents

Use the same ordered tokens for both definitions. This example reads the
30 authored teaching essays and the empty file distributed with the
package; replace `folder` with your own input directory to check a
study’s documents.

``` r
folder <- system.file("examples", "text-input", "texts", package = "ldfreq")
files <- sort(list.files(folder, pattern = "[.]txt$", full.names = TRUE))
texts <- vapply(files, function(path) {
  paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
}, character(1))
names(texts) <- tools::file_path_sans_ext(basename(files))
prepared <- lexdiv_tokenize_batch(texts, tokenizer = "english",
  normalization = "NFC", case = "lower")
tokens <- lapply(prepared, function(x) x$tokens$surface)
current <- lexdiv_metrics_batch(tokens, metrics = "mtld")
legacy <- lapply(tokens, lexdiv_variant_metrics,
  variants = "mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1")
migration <- data.frame(document_id = names(tokens), N = lengths(tokens),
  current = current$value,
  legacy = vapply(legacy, function(x) x$value, numeric(1)))
paired <- is.finite(migration$current) & is.finite(migration$legacy)
data.frame(paired = sum(paired), excluded = sum(!paired),
  spearman = cor(migration$current[paired], migration$legacy[paired],
    method = "spearman"),
  mean_absolute_change = mean(abs(migration$current[paired] -
    migration$legacy[paired])))
#>   paired excluded spearman mean_absolute_change
#> 1     30        1        1                    0
```

All 30 paired scores agree (Spearman = 1; mean absolute change = 0); the
empty document remains missing. These texts have 107–149 tokens and MTLD
values 48.76–165.21. The agreement has a structural explanation, which
the factor screen below makes visible. These authored texts do not
estimate the effect on low-scoring learner essays. Report the paired
count, missing cases, ranks and numerical changes for your own sample
before combining old and new results. Correlation alone can conceal a
systematic shift in values. With fewer than two finite pairs or constant
scores, rank correlation is not defined.

### Inspect MTLD factor support

`status = "ok"` means that the formula is computable. The 50-token
advisory screen does not mean that the text contains a complete MTLD
factor. In a direction with no complete factors, the value is
`N / tail_credit`: an extrapolation from the fractional tail alone. It
can exceed the observed text length. There is no requirement that MTLD
be bounded by `N`.

Use this ordinary R helper with current MTLD or its sequential legacy
min10 results. It reads the existing diagnostics, so it also works with
saved results from earlier versions. Other MTLD variants have different
diagnostics.

``` r
mtld_support_table <- function(x) {
  fields <- c("forward_score", "reverse_score", "forward_complete_factors",
    "reverse_complete_factors", "forward_tail_credit", "reverse_tail_credit")
  stopifnot(nrow(x) > 0L, all(vapply(x$diagnostics,
    function(d) all(fields %in% names(d)), logical(1))))
  d <- do.call(rbind, lapply(x$diagnostics, function(z) as.data.frame(z[fields])))
  out <- cbind(as.data.frame(x)[intersect(
    c("document_id", "method_id", "value", "status", "N"), names(x))], d)
  out$tail_only <- ifelse(x$status == "ok",
    pmin(d$forward_complete_factors, d$reverse_complete_factors) == 0, NA)
  out$direction_gap_percent <- ifelse(x$status == "ok",
    100 * abs(d$forward_score - d$reverse_score) /
      ((d$forward_score + d$reverse_score) / 2), NA_real_)
  out$score_exceeds_N <- ifelse(x$status == "ok", x$value > x$N, NA)
  out
}
support <- mtld_support_table(current)
support[c("document_id", "N", "value", "forward_complete_factors",
  "reverse_complete_factors", "tail_only", "direction_gap_percent")]
#>    document_id   N     value forward_complete_factors reverse_complete_factors
#> 1          001 107 133.57167                        0                        0
#> 2          002 129 103.88318                        1                        1
#> 3          003 147  54.66044                        2                        2
#> 4          004 117 123.64258                        0                        0
#> 5          005 138  89.97273                        1                        1
#> 6          006 108 120.96000                        0                        0
#> 7          007 127  75.46677                        1                        1
#> 8          008 149  48.75861                        2                        3
#> 9          009 117 117.00000                        1                        1
#> 10         010 137  59.40803                        2                        2
#> 11         011 108 163.29600                        0                        0
#> 12         012 128  72.79462                        1                        1
#> 13         013 147  56.02444                        2                        2
#> 14         014 119 141.61000                        0                        0
#> 15         015 137  78.68859                        1                        1
#> 16         016 107 107.00000                        1                        1
#> 17         017 128 114.25397                        0                        1
#> 18         018 148  53.68868                        2                        2
#> 19         019 118 118.07152                        1                        0
#> 20         020 140  69.04465                        1                        2
#> 21         021 108 125.61231                        0                        0
#> 22         022 128  80.02695                        1                        1
#> 23         023 149  58.90084                        2                        2
#> 24         024 119  86.19561                        1                        1
#> 25         025 138  65.67068                        1                        2
#> 26         026 110 130.30769                        0                        0
#> 27         027 128  76.37374                        1                        1
#> 28         028 148  54.13347                        2                        2
#> 29         029 119 165.21167                        0                        0
#> 30         030 139  51.65766                        2                        2
#> 31         031   0        NA                       NA                       NA
#>    tail_only direction_gap_percent
#> 1       TRUE             0.0000000
#> 2      FALSE            48.3558994
#> 3      FALSE             5.9018653
#> 4       TRUE             0.0000000
#> 5      FALSE             9.9900100
#> 6       TRUE             0.0000000
#> 7      FALSE             5.5081245
#> 8      FALSE            30.6882591
#> 9      FALSE             0.0000000
#> 10     FALSE            30.6085704
#> 11      TRUE             0.0000000
#> 12     FALSE            13.2198628
#> 13     FALSE             7.8127839
#> 14      TRUE             0.0000000
#> 15     FALSE            12.1892871
#> 16     FALSE             0.0000000
#> 17      TRUE            43.3451725
#> 18     FALSE             8.7547406
#> 19      TRUE             0.1211387
#> 20     FALSE            44.6082118
#> 21      TRUE             0.0000000
#> 22     FALSE            14.3172409
#> 23     FALSE             1.5513497
#> 24     FALSE            25.7299798
#> 25     FALSE            42.5711165
#> 26      TRUE             0.0000000
#> 27     FALSE            10.1214575
#> 28     FALSE             1.4513788
#> 29      TRUE             0.0000000
#> 30     FALSE             7.3637703
#> 31        NA                    NA
```

Among the 30 nonempty authored texts, ten have no complete factor in at
least one direction, including eight with none in either direction; 22
have at most one in at least one direction. Nine scores exceed `N`. The
median directional gap is 6.63%, with a maximum of 48.36%, using the
mean of directional scores as the denominator. The four highest scores
depend entirely on the tail in both directions. These counts describe
the examples, not a learner population.

From development version 0.3.0.9002, printing results shows
`mtld_tail_only` and `mtld_gap_pct` automatically where these
diagnostics are available. These are derived display columns; the saved
result schema and values are unchanged. The table above retains the
numeric components for analysis or export.

**The gap measures order sensitivity, not uncertainty.** When both
directions have zero complete factors, both tails have the same
full-text TTR, hence the same score and a gap of zero. That is not
evidence of precision. A complete factor count is useful diagnostic
information, but there is no validated universal count cutoff here for
reliable measurement. Retain flags, report their prevalence and justify
any exclusions through the study design.

Why retain 50 tokens?
[`lexdiv_length_evidence()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_length_evidence.md)
records a 50-token result for MTLD Original in Zenker and Kyle’s (2021)
ICNALE study and 50-token guidance in TAALED 0.32. It also records
Koizumi’s (2012) context-specific 100-token recommendation for spoken L2
English. The implementations, tasks and samples differ; the registry
does **not** establish equivalence with this package’s current
no-minimum definition. Thus 50 is retained as advisory length guidance,
not adopted as an empirically validated precision threshold for this
implementation. Length, factor support, task and sampling design all
need attention; one cannot replace them with a single pass/fail
criterion.

### Check association with text length in your sample

This recipe reports Pearson and Spearman correlations with the
**analyzed** token count, with one common setting per metric. Replace
`tokens` with your own prepared documents. Keep non-computable values
missing and report their count rather than treating them as zero.

``` r
length_associations <- function(results) {
  do.call(rbind, lapply(split(as.data.frame(results), results$metric_id), function(x) {
    stopifnot(!anyDuplicated(x$document_id)) # one setting per document/metric
    ok <- x$status == "ok" & is.finite(x$N) & is.finite(x$value)
    n <- x$N[ok]
    value <- x$value[ok]
    estimable <- length(n) >= 3L && length(unique(n)) > 1L &&
      length(unique(value)) > 1L
    data.frame(metric_id = x$metric_id[[1]], paired = sum(ok),
      excluded = sum(!ok), N_min = if (length(n)) min(n) else NA,
      N_max = if (length(n)) max(n) else NA,
      pearson = if (estimable) cor(n, value) else NA_real_,
      spearman = if (estimable) cor(n, value, method = "spearman") else NA_real_)
  }))
}
length_results <- lexdiv_metrics_batch(tokens,
  metrics = c("ttr", "mattr", "mtld"), window_length = 50)
length_associations(length_results)
#>       metric_id paired excluded N_min N_max    pearson   spearman
#> mattr     mattr     30        1   107   149 -0.9195612 -0.9113254
#> mtld       mtld     30        1   107   149 -0.8552701 -0.8689381
#> ttr         ttr     30        1   107   149 -0.8835006 -0.8470752
```

These are descriptive associations, not a test of length independence.
Across documents, length can co-vary with proficiency, topic and task.
Inspect the actual `N` range and repeat the table within relevant
strata; do not conclude length invariance from a small correlation or
automatically regress length out of every metric. Repeated writers
require an appropriate sampling model for inference, so this recipe does
not attach independent-observation p-values. A complementary
within-document check uses fixed contiguous segment lengths under the
same tokenization and metric settings. It asks a different question and
overlapping segments are not independent texts. Bestgen’s
[methodological review](https://arxiv.org/abs/2307.04626) distinguishes
the text length problem from sensitivity to the metric’s own length
parameter.

### A public learner-corpus example

An [executed PELIC v1.0
example](https://github.com/Ryuya-dot-com/ldfreq/tree/main/experiments/learner-length)
applies these checks to 16 original essays by 16 writers answering the
same prompt, all in recorded course level 3. The prompt was selected for
the largest number of distinct writers among original writing-class
essay responses, with numeric-ID tie breaking, before examining scores.
English tokenization uses lowercase surface forms, NFC, and excludes
numbers; spelling and grammatical forms remain unchanged. Analyzed
lengths range from 70 to 314.

| Metric | Pearson with N | Spearman with N | Paired / excluded |
|----|---:|---:|---:|
| TTR | -0.6500 | -0.6814 | 16 / 0 |
| MATTR, common window 50 | 0.4173 | 0.4294 | 16 / 0 |
| MTLD, strict \< 0.72, no minimum | 0.3834 | 0.2500 | 16 / 0 |

Every direction has at least one complete MTLD factor in this sample.
The directional gap has median 8.54% and maximum 47.08%. These
observations do not validate reliability or identify the best metric.
Even within a prompt, writers and content can differ with length. A
fixed-document prefix example is also provided; only three texts reach
200 tokens, so it is a computational demonstration, not evidence of
population stability.

The [corpus](https://doi.org/10.5281/zenodo.3991977) is credited to
Juffs, Han and Naismith (2020). The pinned upstream README states CC
BY-NC-ND 4.0, while Zenodo v1.0 metadata states CC BY-ND 4.0; the
example follows the upstream noncommercial condition. Corpus texts and
transformed token sequences are not bundled. Reproduction explicitly
downloads the hash-verified source into a local cache (about 182 MB);
package installation and vignette builds do not download it. The public
repository contains the code, settings and aggregate tables. Existing
ICNALE GRA V2.1 results below remain a separate local-data migration
comparison.

### Identify where the min10 restriction can matter

For an input of at least ten tokens, if **neither direction has a
complete factor shorter than ten tokens** under the current definition,
the old min10 restriction never blocks a closure. Both scans therefore
start each next factor at the same token, leave the same residual tail,
and return the same score (or the same `no_factor` missing result). This
is a sufficient condition for agreement, not a necessary one: a short
factor can change the segmentation without changing the final
directional mean.

This small analysis helper inspects the same ordered token vector used
for MTLD. Use the same threshold as in the metric calculation. It is
tutorial code; it does not add fields to package results or change the
MTLD definition.

``` r
mtld_factor_screen <- function(x, threshold = 0.72) {
  stopifnot(is.character(x), !anyNA(x), all(nzchar(x)),
    is.numeric(threshold), length(threshold) == 1L,
    is.finite(threshold), threshold > 0, threshold < 1)
  scan <- function(x) {
    start <- 1L
    complete <- integer()
    for (i in seq_along(x)) {
      n <- i - start + 1L
      if (length(unique(x[start:i])) / n < threshold) {
        complete <- c(complete, n)
        start <- i + 1L
      }
    }
    c(minimum = if (length(complete)) min(complete) else NA_integer_,
      short = sum(complete < 10L))
  }
  forward <- scan(x)
  reverse <- scan(rev(x))
  data.frame(N = length(x), forward_min = unname(forward["minimum"]),
    reverse_min = unname(reverse["minimum"]),
    forward_short = unname(forward["short"]),
    reverse_short = unname(reverse["short"]),
    screen = if (length(x) < 10L) "legacy_ineligible" else if
      (forward["short"] + reverse["short"] == 0L) "no_min10_effect" else
      "possible_min10_effect")
}
```

The minima count **complete factors only**; an unfinished tail is not a
short complete factor. `NA` means that direction has no complete factor.
Fewer than ten tokens are classified separately because the legacy
method cannot return a score. A screen classification does not replace
the metric’s status or establish that a text is long enough for a
study’s purposes.

``` r
factor_screen <- do.call(rbind, lapply(tokens, mtld_factor_screen))
factor_screen$document_id <- names(tokens)
table(factor_screen$screen)
#> 
#> legacy_ineligible   no_min10_effect 
#>                 1                30
shortest <- pmin(factor_screen$forward_min, factor_screen$reverse_min,
  na.rm = TRUE)
data.frame(shortest_complete_factor = min(shortest, na.rm = TRUE),
  documents_with_complete_factors = sum(!is.na(shortest)),
  median_document_minimum = median(shortest, na.rm = TRUE))
#>   shortest_complete_factor documents_with_complete_factors
#> 1                       14                              22
#>   median_document_minimum
#> 1                      39
```

All 30 essays are `no_min10_effect`: the shortest complete factor in
either direction is 14 tokens. Among the 22 essays with at least one
complete factor, the median document minimum is 39 tokens. The other
eight have only residual factors in both directions. Assigning `Inf` to
those eight and taking the median over all 30 would give 45; this
example leaves their absent minima as `NA` and states the 22-document
denominator. Thus the observed agreement is guaranteed by their factor
lengths, not evidence that the two definitions are interchangeable. The
empty document is `legacy_ineligible`.

For your own corpus, retain this table alongside the scores. Only rows
marked `possible_min10_effect` need the legacy calculation to determine
a numerical change, provided the token stream and all other settings are
unchanged. Report the potentially affected count separately from the
actually changed count; also report ineligible and missing cases. For
example, `subset(factor_screen, screen == "possible_min10_effect")`
selects the documents to inspect. With no complete factors, the document
minimum remains `NA`; do not substitute zero or infer a low MTLD score
from it.

In a local check of the saved original ICNALE GRA V2.1 token streams,
the same screen and actual old/new scores were compared separately for
learners and English native speakers. Aggregate results and the
reproduction procedure are in the [migration
record](https://github.com/Ryuya-dot-com/ldfreq/tree/main/experiments/mtld-migration).
The corpus texts and individual results are not distributed. Of the 136
learner essays, 15 (11.03%) had a short factor and all 15 changed; the
remaining 121 were guaranteed unchanged. The A2 subset had 2 changes in
31 essays (6.45%). One of the four ENS essays also changed. These are
descriptive results for the retained sample and preparation, not
population rates or evidence that the restriction affects only
beginners.

Both methods above use strict `<`. Changing only the comparison to `<=`
is a different sensitivity analysis: for teaching essay `024`, a
transparent no-minimum reference gives 86.1956 with `<` and 64.3163 with
`<=`: a 25.38% decrease relative to the strict value (equivalently,
strict is 34.02% higher relative to the inclusive value). The [executed
migration
record](https://github.com/Ryuya-dot-com/ldfreq/tree/main/experiments/mtld-migration)
preserves the document-level outputs, operator-only reference and exact
input hashes. The boundary effect depends on the token sequence, so
there is no universal percentage adjustment. Include the operator in
your methods statement; see the [reporting
guide](https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report.html#save-enough-to-reproduce-and-report-the-analysis).

Expected-TTR D is experimental and excluded from defaults.
Near-all-unique texts yield large estimates because the target curve
approaches one. The numerical correction in package 0.2.0 does not
establish equivalence to CLAN vocd-D. If explicitly selected, report
`near_saturation`, fit diagnostics, sample sizes, and package version;
all-unique input has an unbounded fit.

## Reference frequency answers a separate question

If the question also concerns how frequent the forms are in general
YouTube subtitles, use TUBELEX as a separate corpus-relative measure.
Its Treebank segmentation is not supplied by the general Unicode
tokenizer in this package. Prepare and record a compatible external
pipeline; these hand-prepared terms illustrate only one sentence.

``` r
terms <- c("I", "do", "n't", "think", "it", "'s", "a", "book")
frequency <- tubelex_profile(terms)
frequency$summary[, c("weighting", "coverage", "mean_zipf")]
#>   weighting coverage mean_zipf
#> 1     token        1  6.810781
#> 2      type        1  6.810781
frequency$provenance$tokenization_alignment
#> [1] "caller_supplied_terms_unverified"
```

The mean describes matched terms, not all terms with unknown words
assigned zero frequency. A change in mean can accompany a change in
coverage, so inspect both and the unmatched terms. Character-vector
alignment remains unverified: even 100% coverage cannot confirm the
intended segmentation. The explicit apostrophe normalization option
harmonizes typography, not token boundaries.

This measure does not answer whether an essay is better or whether its
writer knows more vocabulary. Those claims need an appropriate external
criterion, reference-corpus justification, and study design.

## What to preserve and report

Preserve document IDs, task and writer identifiers, the prepared tokens
and preprocessing provenance, exclusions and coverage, the complete long
result, method and contract IDs, parameters, and the R/package session
information. Keep exact text and tokens under the study’s data-access
rules rather than placing them automatically in a public report.

The synthetic results support a precise conclusion: equal whole-document
vocabularies can have different local variety, and a changed window
changes the question. They provide implementation and interpretation
checks. An empirical group conclusion still requires its actual effect
size, uncertainty, sampling design, exclusions, and sensitivity results.
