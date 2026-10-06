# Designing comparable lexical-diversity analyses

## Start with a question and a comparison unit

Suppose the question is whether writers use a greater variety of word
forms locally in responses to the same writing task. The observations
are documents; repeated responses by the same writer are not independent
participants. Fix the task, population, lexical unit, preprocessing, and
common window size before comparing groups. A result about local
surface-form variety is not automatically a result about vocabulary
knowledge, proficiency, or writing quality.

The examples below are synthetic. They isolate effects of length, order,
and window size so that we can explain what the calculations answer.
They cannot establish a population effect or the validity of a chosen
window for a task.

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

## A stable definition can still have an awkward boundary

The canonical MTLD definition requires at least ten tokens for a
complete factor and uses an unclamped linear residual factor. A short
residual can therefore create a discontinuity even when only one token
is added.

``` r
mtld_boundary <- data.frame(N = c(50L, 51L, 52L, 59L, 60L))
mtld_boundary$MTLD <- vapply(mtld_boundary$N, function(n) {
  lexdiv_metrics(rep("a", n), metrics = "mtld")$value
}, numeric(1))
mtld_boundary
#>    N      MTLD
#> 1 50 10.000000
#> 2 51 10.200000
#> 3 52  7.663158
#> 4 59  7.217476
#> 5 60 10.000000
```

For this intentionally extreme sequence, the 59-token result is about
7.22 and the 60-token result is 10. This follows the stated factor and
tail rules; changing or clamping those rules would define a different
method. Inspect directional/factor diagnostics and length sensitivity
when MTLD is central to the question. The variant APIs compare their
explicitly stated definitions; agreement on a label is not proof of
agreement with another implementation.

Expected-TTR D has a different limitation: near-all-unique texts yield
very large estimates because the target curve approaches one. Package
0.2.0 fixes numerical cancellation here, but numerical accuracy does not
make that boundary substantively informative. Report `near_saturation`,
fit diagnostics, sample sizes, and package version; all-unique input has
an unbounded fit.

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
