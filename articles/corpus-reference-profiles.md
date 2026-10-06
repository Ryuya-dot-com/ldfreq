# Using your own lexical reference data across a corpus

## Choose a question and a reference unit

Suppose you want to describe familiarity and age-of-acquisition values
for words in a collection of texts. The authors may be native speakers
or language learners; the same computation applies. Its interpretation
depends on the reference population, text sampling and word unit, not
the author’s L1 label.

[`lexdiv_norm_profile_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile_batch.md)
applies one caller-supplied reference table to multiple documents. It
retains each document and each variable, rather than pooling all texts
or combining different scales. This guide uses authored texts and
numbers, not observed norms or a finding about register differences. No
external dataset or network connection is needed to run it.

## Preserve documents and their metadata

Use a unique document ID independently of writer/speaker ID, since the
same person may contribute several texts. Real metadata should record
corpus/version, register, task/topic, author/speaker, documented
language background and sampling conditions. Keep unknown information
missing; do not infer L1 from a genre label.

``` r
texts <- data.frame(
  document_id = c("demo_essay", "demo_turn", "demo_blank"),
  corpus_id = "authored_demo_v1",
  register = c("essay_example", "conversation_example", "essay_example"),
  participant_id = NA_character_,
  text = c("We read the book and discuss the policy.",
           "I read the book. I read it again.", "")
)
stopifnot(!anyNA(texts$document_id), !anyDuplicated(texts$document_id))
prepared <- lexdiv_tokenize_batch(texts, tokenizer = "english",
  normalization = "NFC", case = "lower")
terms <- lapply(prepared, function(x) x$tokens$surface)
```

These are plain text examples, not raw XML or unprocessed conversation
transcripts. Select speaker/turn boundaries and handle transcription
markup before tokenization. Do not join unrelated documents to make them
long enough for a metric. For other languages, supply an appropriate
external segmentation and prepared lookup terms; this English tokenizer
and the bundled English resources are not evidence of multilingual
validation.

## Describe the reference table, variables and population

The toy table uses lowercase surface forms. A real lemma-based resource
instead needs compatible lemmas, including its POS convention if
relevant. Exact matching does not silently correct case, accents,
spelling or inflection.

``` r
norms <- data.frame(term = c("read", "book", "discuss", "policy"),
  familiarity = c(6, 7, 5, NA_real_),
  aoa_years = c(6, 4, 9, 12))
specs <- data.frame(
  measure_id = c("familiarity", "aoa"),
  value_column = c("familiarity", "aoa_years"),
  construct_id = c("subjective_familiarity", "age_of_acquisition"),
  value_unit = c("seven_point_rating", "years"),
  direction = c("higher", "descriptive"),
  language = "English", variety = "unspecified",
  population_id = "authored_not_participant_data",
  collection_year = "not_observed",
  valid_min = c(1, 0), valid_max = c(7, NA_real_))
resource <- list(resource_id = "authored_norms", resource_version = "1",
  creator = "Example author", source_reference = "Authored demonstration",
  data_license = "Example numbers; no external dataset",
  transformation_id = "none", lookup_unit = "lowercase_surface",
  resource_key_normalization_id = "caller-prepared-v1")

profiles <- lexdiv_norm_profile_batch(terms, norms, "term", specs, resource)
profiles$summary[, c("document_id", "measure_id", "weighting", "estimate",
  "value_unit", "status", "missing_reason")]
#>    document_id  measure_id weighting estimate         value_unit  status
#> 1   demo_essay familiarity     token 6.000000 seven_point_rating      ok
#> 2   demo_essay familiarity      type 6.000000 seven_point_rating      ok
#> 3   demo_essay         aoa     token 7.750000              years      ok
#> 4   demo_essay         aoa      type 7.750000              years      ok
#> 5    demo_turn familiarity     token 6.333333 seven_point_rating      ok
#> 6    demo_turn familiarity      type 6.500000 seven_point_rating      ok
#> 7    demo_turn         aoa     token 5.333333              years      ok
#> 8    demo_turn         aoa      type 5.000000              years      ok
#> 9   demo_blank familiarity     token       NA seven_point_rating missing
#> 10  demo_blank familiarity      type       NA seven_point_rating missing
#> 11  demo_blank         aoa     token       NA              years missing
#> 12  demo_blank         aoa      type       NA              years missing
#>    missing_reason
#> 1            <NA>
#> 2            <NA>
#> 3            <NA>
#> 4            <NA>
#> 5            <NA>
#> 6            <NA>
#> 7            <NA>
#> 8            <NA>
#> 9     empty_input
#> 10    empty_input
#> 11    empty_input
#> 12    empty_input
```

`direction` describes the variable; it does not turn a high score into
good writing. Years and rating points remain separate scales. The same
interface can use documented frequency measures, but record their units,
reference corpus, denominator and transformations. A per-million
frequency, a log frequency and a Zipf value are not interchangeable. For
another source, make a separate call with its own resource record. The
bundled TUBELEX adapter additionally verifies its fixed resource; this
generic function records caller assertions and does not fingerprint or
authenticate the supplied table.

## Keep coverage alongside each estimate

Three rates answer different questions:

| Rate | Numerator / denominator | Question |
|----|----|----|
| Resource coverage | Matched units / all input units | How much of the document occurs in the reference? |
| Value coverage | Units with observed values / all input units | How much contributes to this variable’s mean? |
| Annotation coverage | Units with observed values / matched units | How complete is this variable among matched entries? |

In the essay, `policy` matches the reference but lacks familiarity.
Other words are absent from the reference entirely. Both stay visible,
with different reasons. Neither receives zero. The blank document
retains rows with `empty_input`; it does not disappear from the study.

``` r
profiles$coverage
#>    document_id result_order    resource_id resource_version  measure_id
#> 1   demo_essay            1 authored_norms                1 familiarity
#> 2   demo_essay            2 authored_norms                1 familiarity
#> 3   demo_essay            3 authored_norms                1         aoa
#> 4   demo_essay            4 authored_norms                1         aoa
#> 5    demo_turn            1 authored_norms                1 familiarity
#> 6    demo_turn            2 authored_norms                1 familiarity
#> 7    demo_turn            3 authored_norms                1         aoa
#> 8    demo_turn            4 authored_norms                1         aoa
#> 9   demo_blank            1 authored_norms                1 familiarity
#> 10  demo_blank            2 authored_norms                1 familiarity
#> 11  demo_blank            3 authored_norms                1         aoa
#> 12  demo_blank            4 authored_norms                1         aoa
#>    weighting input_units matched_units unmatched_units observed_value_units
#> 1      token           8             4               4                    3
#> 2       type           7             4               3                    3
#> 3      token           8             4               4                    4
#> 4       type           7             4               3                    4
#> 5      token           8             3               5                    3
#> 6       type           6             2               4                    2
#> 7      token           8             3               5                    3
#> 8       type           6             2               4                    2
#> 9      token           0             0               0                    0
#> 10      type           0             0               0                    0
#> 11     token           0             0               0                    0
#> 12      type           0             0               0                    0
#>    matched_missing_value_units resource_coverage value_coverage
#> 1                            1         0.5000000      0.3750000
#> 2                            1         0.5714286      0.4285714
#> 3                            0         0.5000000      0.5000000
#> 4                            0         0.5714286      0.5714286
#> 5                            0         0.3750000      0.3750000
#> 6                            0         0.3333333      0.3333333
#> 7                            0         0.3750000      0.3750000
#> 8                            0         0.3333333      0.3333333
#> 9                            0                NA             NA
#> 10                           0                NA             NA
#> 11                           0                NA             NA
#> 12                           0                NA             NA
#>    annotation_coverage
#> 1                 0.75
#> 2                 0.75
#> 3                 1.00
#> 4                 1.00
#> 5                 1.00
#> 6                 1.00
#> 7                 1.00
#> 8                 1.00
#> 9                   NA
#> 10                  NA
#> 11                  NA
#> 12                  NA
profiles$lookup[profiles$lookup$term == "policy",
  c("document_id", "term", "measure_id", "lookup_status", "value_status")]
#>    document_id   term  measure_id    lookup_status       value_status
#> 15  demo_essay policy familiarity matched_resource missing_annotation
#> 16  demo_essay policy         aoa matched_resource           observed
profiles$diagnostics$documents
#>   document_id status input_terms input_types planned_lookup_rows
#> 1  demo_essay     ok           8           7                  16
#> 2   demo_turn     ok           8           6                  16
#> 3  demo_blank  empty           0           0                   0
#>   planned_summary_rows planned_coverage_rows planned_result_rows
#> 1                    4                     4                  24
#> 2                    4                     4                  24
#> 3                    4                     4                   8
```

Token weighting gives repeated words repeated weight within a document.
Type weighting counts distinct exact lookup terms once. Neither weights
writers or documents for a group comparison. Group averages would
require another explicit decision about equal-document versus token
weighting, missing results and sampling dependencies. The batch function
deliberately returns document rows.

## Join metadata by ID and save the complete analysis

Metric/profile tables are long: each document contributes multiple rows.
Join metadata by unique document ID, preserving every result row and its
order. Additional columns in an input data frame are not automatically
copied into the batch output.

``` r
metadata <- texts[, c("document_id", "corpus_id", "register", "participant_id")]
row_index <- match(profiles$summary$document_id, metadata$document_id)
stopifnot(!anyNA(row_index), !anyDuplicated(metadata$document_id),
  !any(setdiff(names(metadata), "document_id") %in% names(profiles$summary)))
analysis <- cbind(profiles$summary,
  metadata[row_index, setdiff(names(metadata), "document_id"), drop = FALSE])
rownames(analysis) <- NULL
stopifnot(nrow(analysis) == nrow(profiles$summary))

# One variable and weighting, with all documents and missing rows retained.
report <- analysis[analysis$measure_id == "familiarity" &
  analysis$weighting == "token", c("document_id", "register", "estimate",
    "input_units", "observed_value_units", "resource_coverage",
    "value_coverage", "annotation_coverage", "status", "missing_reason")]
report
#>   document_id             register estimate input_units observed_value_units
#> 1  demo_essay        essay_example 6.000000           8                    3
#> 5   demo_turn conversation_example 6.333333           8                    3
#> 9  demo_blank        essay_example       NA           0                    0
#>   resource_coverage value_coverage annotation_coverage  status missing_reason
#> 1             0.500          0.375                0.75      ok           <NA>
#> 5             0.375          0.375                1.00      ok           <NA>
#> 9                NA             NA                  NA missing    empty_input

saved <- tempfile(fileext = ".rds")
saveRDS(list(texts = texts, prepared = prepared, terms = terms,
  norms = norms, specs = specs, resource = resource, profiles = profiles,
  analysis = analysis, session = sessionInfo()), saved)
restored <- readRDS(saved)
replayed <- lexdiv_norm_profile_batch(restored$terms, restored$norms, "term",
  restored$specs, restored$resource)
stopifnot(identical(replayed, restored$profiles),
  identical(restored$analysis, analysis))
unlink(saved)
```

Use a persistent path for an actual study. Save the resource table as
well as its citation/version and preprocessing; a version label alone
does not preserve its contents. Obtain the source table under its
applicable terms before use. Research data saved in your project do not
become package data automatically.

For this authored example, the useful answer is which words and
denominators contribute to each mean. It does not establish a register
difference or a participant’s knowledge. In a real study, examine
coverage differences before comparing estimates, use appropriate
independent documents or speaker/author clusters, and justify the
reference population. See [designing
comparisons](https://ryuya-dot-com.github.io/ldfreq/articles/designing-comparisons.md)
for the broader study design.

## Know when an input stops the calculation

Duplicate IDs, malformed term vectors and invalid reference
specifications stop the whole call. This follows the single-document
norm API. Valid empty, unmatched and unannotated documents remain in the
output. The global `max_rows` limit covers lookup, summary and coverage
rows; reduce the requested output or choose an explicit larger limit
after considering its memory needs. Splitting documents does not evade
this bound within one call.
