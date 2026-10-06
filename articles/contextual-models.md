# Connect contextual model outputs to research occurrences

## The research problem

For a word such as *bank*, a model can provide a representation of each
occurrence in context. The research question might be whether those
representations distinguish financial from river-edge uses. Computing
vectors does not establish that distinction: the target, context,
candidate inventory and an independent evaluation must also be
specified.

[`lexdiv_import_contextual()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_contextual.md)
connects external model output to source occurrences used for KWIC
review. It checks joins, preserves missing output and keeps model
suggestions separate from human decisions. It does not run BERT, install
Python, download weights, select a meaning, or validate a semantic
measure. The importer needs no model software. Creating the review uses
optional quanteda; the English/Japanese example below requires a UTF-8 R
session.

## An offline example with authored values

These sentences, candidates, vectors and scores are **authored
illustrations**, not model predictions, corpus observations or
psycholinguistic norms. Japanese `人気` illustrates different readings
of the same spelling, not a demonstrated related-sense manipulation. Use
real annotations for a real study.

``` r
words <- list(c("The", "bank", "lent", "money", "."),
              c("The", "river", "bank", "flooded", "."),
              c("その", "店", "は", "人気", "が", "ある", "。"),
              c("ここ", "は", "人気", "が", "ない", "。"))
tokens <- data.frame(document_id = "example",
  segment_id = rep(paste0("s", 1:4), lengths(words)),
  token_index = sequence(lengths(words)), surface = unlist(words, use.names = FALSE))
segments <- data.frame(document_id = "example", segment_id = paste0("s", 1:4),
  text = c("The bank lent money.", "The river bank flooded.",
           "その店は人気がある。", "ここは人気がない。"))
annotations <- lexdiv_import_annotations(tokens, segments, list(
  language = "en/ja", analyzer = "authored", analyzer_version = "1",
  dictionary = "none", dictionary_version = "none", unit = "authored",
  normalization = "none"))
candidates <- data.frame(term = c("bank", "bank", "人気", "人気"),
  candidate_id = c("financial", "river", "popularity", "human-presence"),
  label = c("financial institution", "river edge", "にんき", "ひとけ"))
review <- lexdiv_ambiguity_review(annotations, c("bank", "人気"), candidates,
  list(resource_id = "authored", resource_version = "1",
    source_reference = "Authored candidates, not a dictionary", data_license = "MIT"))

# Export anchors BEFORE computation. Never reconstruct them after a model run.
input <- review$occurrences[c("review_id", "occurrence_id", "segment_text",
                              "surface", "start", "end")]
data <- input[1:3, ]
data$status <- c("processed", "processed", "skipped")
data$reason <- c("Authored transport example", "Authored transport example",
                 "Illustrated failure, not an actual model limitation")
vectors <- matrix(c(1, 0, 0, 1), nrow = 2,
                  dimnames = list(data$occurrence_id[1:2], NULL))
scores <- data.frame(occurrence_id = rep(data$occurrence_id[1:2], each = 2),
  candidate_id = rep(c("financial", "river"), 2), score = c(2, -1, 0.5, 0.5))
model <- list(model_id = "authored-example", model_revision = "1",
  tokenizer_id = "authored", tokenizer_revision = "1",
  software = "illustration", software_version = "1",
  context_policy = "full segment; no truncation",
  representation = "authored two-dimensional vectors, not model output",
  score_definition = "authored scores; larger is preferred; not probabilities")
imported <- lexdiv_import_contextual(review, data, model, vectors, scores)
imported$summary
#>   occurrences returned processed skipped error not_returned with_embeddings
#> 1           4        3         2       1     0            1               2
#>   with_suggestions processed_proportion
#> 1                2                  0.5
imported$occurrences[c("surface", "status", "model_status", "has_embedding")]
#>   surface     status model_status has_embedding
#> 1    bank unreviewed    processed          TRUE
#> 2    bank unreviewed    processed          TRUE
#> 3    人気 unreviewed      skipped         FALSE
#> 4    人気 unreviewed not_returned         FALSE
imported$suggestions[c("pre", "keyword", "post", "label", "score", "human_status")]
#>         pre keyword         post                 label score human_status
#> 1       The    bank lent money . financial institution   2.0   unreviewed
#> 2       The    bank lent money .            river edge  -1.0   unreviewed
#> 3 The river    bank    flooded . financial institution   0.5   unreviewed
#> 4 The river    bank    flooded .            river edge   0.5   unreviewed
stopifnot(identical(imported$review, review),
          imported$summary$processed_proportion == 0.5,
          all(imported$occurrences$status == "unreviewed"))
```

Two of four occurrences have output. Skipped and omitted
(`not_returned`) occurrences remain in the denominator. Tied and
negative scores are retained; importing them does not create
probabilities or human decisions. The suggestions table contains KWIC
and candidate labels; `segment_text` retains the full original segment.
Scores may cover only part of an inventory: an absent score is missing,
not zero. Use the ordinary review decision table to record later human
selections and keep the earlier review as well. Model-assisted judgments
are not independent human judgments; conduct a blinded human pass before
showing suggestions when independent accuracy or agreement is the
research question.

## Compare scores with a declared reference

[`lexdiv_evaluate_contextual()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_evaluate_contextual.md)
predicts a candidate only when **every candidate in the supplied
inventory is scored** and one is best. Partial lists and tied best
scores abstain. This conservative policy is not a WSD benchmark
convention or proof that the inventory contains every meaning. Specify
whether larger or smaller scores are preferred. The optional absolute
`tie_tolerance` treats nearby scores as ties; choose it before final
evaluation, not by tuning on test labels.

These reference labels are also authored illustrations, not independent
human gold labels. Agreement here is not evidence about BERT accuracy.
Keep the reference separate from the imported model output and its
original human review.

``` r
decisions <- input[c("review_id", "occurrence_id")]
decisions$status <- c("selected", "selected", "selected", "unresolved")
decisions$candidate_id <- c("financial", "river", "popularity", NA_character_)
decisions$reviewer <- "authored-example"
decisions$reason <- c(rep("Authored criterion for this example", 3),
                      "Illustration of an unresolved reference")
reference_review <- lexdiv_ambiguity_review(annotations, c("bank", "人気"),
  candidates, review$provenance$resource, decisions)
evaluation <- lexdiv_evaluate_contextual(imported, reference_review,
  direction = "higher", reference_info = list(
    reference_id = "authored-demonstration", annotation_protocol = "Authored examples, not human ratings",
    model_exposure = "unknown", evaluation_role = "development"))
evaluation$summary[c("agreement", "paired", "agreement_among_paired",
  "predictions", "occurrences", "prediction_coverage",
  "reference_selected", "matches_among_reference_selected")]
#>   agreement paired agreement_among_paired predictions occurrences
#> 1         1      1                      1           1           4
#>   prediction_coverage reference_selected matches_among_reference_selected
#> 1                0.25                  3                        0.3333333
evaluation$review_queue[c("surface", "prediction_status", "model_status",
  "reference_status", "reference_reason", "outcome")]
#>   surface prediction_status model_status reference_status
#> 2    bank         tied_best    processed         selected
#> 3    人気         no_scores      skipped         selected
#> 4    人気         no_scores not_returned       unresolved
#>                          reference_reason           outcome
#> 2     Authored criterion for this example    reference_only
#> 3     Authored criterion for this example    reference_only
#> 4 Illustration of an unresolved reference neither_available
stopifnot(evaluation$summary$agreement_among_paired == 1,
          evaluation$summary$prediction_coverage == 1/4,
          evaluation$summary$matches_among_reference_selected == 1/3,
          identical(evaluation$reference, reference_review),
          identical(evaluation$model_output, imported))
saved_evaluation <- tempfile(fileext = ".rds")
saveRDS(evaluation, saved_evaluation)
stopifnot(identical(readRDS(saved_evaluation), evaluation))
unlink(saved_evaluation)
```

The one comparable case agrees (1/1), but only one of four occurrences
receives a prediction. Among the three occurrences with selected
reference labels, one receives a matching prediction (1/3). “100%
agreement” alone would hide most cases. The KWIC `review_queue` retains
the tied English example, the skipped Japanese example and the
unresolved reference. `terms` repeats counts by surface, including
absent targets; `confusion` keeps candidate IDs scoped to each surface.
Overall proportions weight occurrences rather than word types. A
singleton inventory produces a trivial prediction, counted in
`single_candidate_predictions`; inspect these separately when evaluating
ambiguity.

All inputs remain unchanged. An unresolved or unreviewed reference is
not a wrong label and is not counted as agreement. Embedding-only output
yields no predictions: a separately specified classifier or scoring
procedure is still needed. `reference_scored` identifies whether a
selected reference candidate appeared in the scores, distinguishing a
missing reference candidate from missing rivals.

Use `model_exposure = "not_shown"` only when annotators did not see
model output, and `evaluation_role = "held_out"` only when examples were
not used to fit or choose the scoring procedure or evaluation settings.
These declarations are not verified by the package. Model-assisted
judgments (`shown`) and development examples are valid descriptive
inputs, but are not independent held-out accuracy.

WSD evaluation depends on consistent annotation guidelines and sense
inventories ([Raganato et al.,
2017](https://aclanthology.org/E17-1010/)). Performance on answered
cases and coverage are also distinguished in selective classification
([Geifman & El-Yaniv,
2017](https://papers.neurips.cc/paper_files/paper/2017/hash/4a8423d5e91fda00bb7e46540e2b0cf1-Abstract.html)).
This evaluator implements neither their training algorithms nor their
statistical guarantees; it reports counts and descriptive proportions.

For a candidate-frequency baseline, estimate its scores on separate
training data, import them against the same unchanged review, and
evaluate with the same reference and predeclared policy. Keep each
method’s coverage and compare their overlapping evaluable occurrence IDs
as well. A higher conditional agreement based on fewer, easier cases is
not evidence of improvement. Do not derive baseline frequencies from
held-out labels or equate different candidate inventories.

## Score separate training and query examples in R

[`lexdiv_score_contextual()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_score_contextual.md)
bridges imported vectors and the evaluator. Its centroid baseline
averages the raw target vectors for each selected training candidate,
then computes cosine similarity to a query vector. Averaging labeled
contextual embeddings is a starting point in [Loureiro & Jorge (2019),
section 4.1](https://aclanthology.org/P19-1569/). This small baseline
does not implement their full LMMS method, WordNet propagation, gloss
representations or reported benchmark results.

The comparison baseline uses selected training-label counts for the same
surface. Unlike centroid fitting, it can use selected examples without
embeddings. Always inspect both `n_selected` and `n_vectors`. Neither
score is a probability. The two methods remain separate: there is no
automatic frequency fallback.

Create training and query sources separately **before** model
computation. Stable document IDs must not overlap; renamed copies of
identical target-bearing segments are also rejected. Candidate
tables/resources and embedding declarations (including model/tokenizer
revisions, layer/aggregation and software) must match. Matching
declarations are not proof that external software followed them.

The following sentences, labels and vectors are authored for
illustration. They are not an independent annotation study or a trained
BERT benchmark.

``` r
train_words <- list(c("Her", "bank", "approved", "a", "loan", "."),
                    c("A", "bank", "holds", "deposits", "."),
                    c("We", "rested", "by", "the", "bank", "."),
                    c("人気", "の", "店", "だ", "。"),
                    c("周囲", "に", "人気", "が", "ない", "。"))
train_tokens <- data.frame(document_id = "training-example",
  segment_id = rep(paste0("t", 1:5), lengths(train_words)),
  token_index = sequence(lengths(train_words)), surface = unlist(train_words, use.names = FALSE))
train_segments <- data.frame(document_id = "training-example", segment_id = paste0("t", 1:5),
  text = c("Her bank approved a loan.", "A bank holds deposits.", "We rested by the bank.",
           "人気の店だ。", "周囲に人気がない。"))
train_annotations <- lexdiv_import_annotations(train_tokens, train_segments,
  annotations$provenance$annotation)
train_review <- lexdiv_ambiguity_review(train_annotations, c("bank", "人気"), candidates,
  review$provenance$resource)
train_input <- train_review$occurrences[c("review_id", "occurrence_id", "segment_text", "surface", "start", "end")]
train_data <- train_input
train_data$status <- "processed"; train_data$reason <- "Authored training vectors"
train_vectors <- rbind(c(2,0), c(2,1), c(0,2), c(2,0), c(0,2))
rownames(train_vectors) <- train_input$occurrence_id
train_imported <- lexdiv_import_contextual(train_review, train_data, model, train_vectors)
train_decisions <- train_input[c("review_id", "occurrence_id")]
train_decisions$status <- "selected"
train_decisions$candidate_id <- c("financial", "financial", "river", "popularity", "human-presence")
train_decisions$reviewer <- "authored-example"
train_decisions$reason <- "Intended labels of authored sentences; not independent human judgments"
train_reference <- lexdiv_ambiguity_review(train_annotations, c("bank", "人気"), candidates,
  review$provenance$resource, train_decisions)
scored <- lexdiv_score_contextual(imported, train_imported, train_reference,
  training_info = list(training_id = "authored-training",
    annotation_protocol = "Author-specified intended labels",
    partition_protocol = "Separate authored documents and target contexts",
    model_exposure = "unknown"))
scored$candidates[c("term", "candidate_id", "n_selected", "n_vectors", "prototype_status")]
#>   term   candidate_id n_selected n_vectors prototype_status
#> 1 bank      financial          2         2        available
#> 2 bank          river          1         1        available
#> 3 人気 human-presence          1         1        available
#> 4 人気     popularity          1         1        available
scored$query_occurrences[c("surface", "model_status", "centroid_status", "frequency_status")]
#>   surface model_status   centroid_status frequency_status
#> 1    bank    processed   complete_scores  complete_scores
#> 2    bank    processed   complete_scores  complete_scores
#> 3    人気      skipped missing_embedding  complete_scores
#> 4    人気 not_returned missing_embedding  complete_scores
baseline_evaluations <- lapply(scored[c("centroid", "frequency")], function(output)
  lexdiv_evaluate_contextual(output, reference_review, "higher",
    evaluation$provenance$reference_info))
comparison <- do.call(rbind, lapply(baseline_evaluations, function(result)
  result$summary[c("agreement", "paired", "prediction_coverage", "agreement_among_paired")]))
comparison
#>           agreement paired prediction_coverage agreement_among_paired
#> centroid          2      2                 0.5                    1.0
#> frequency         1      2                 0.5                    0.5
baseline_evaluations$centroid$review_queue[c("keyword", "pre", "post", "prediction_status", "model_reason")]
#>   keyword        pre       post prediction_status
#> 3    人気 その 店 は が ある 。         no_scores
#> 4    人気    ここ は が ない 。         no_scores
#>                                                                                       model_reason
#> 3 centroid: missing_embedding; input: skipped; Illustrated failure, not an actual model limitation
#> 4                                   centroid: missing_embedding; input: not_returned; not returned
stopifnot(comparison$agreement_among_paired == c(1, 0.5),
          all(comparison$prediction_coverage == 0.5),
          identical(scored$query, imported), identical(scored$reference, train_reference))
saved_scores <- tempfile(fileext = ".rds")
saveRDS(scored, saved_scores)
stopifnot(identical(readRDS(saved_scores), scored))
unlink(saved_scores)
```

The centroid method matches both English reference choices in this
constructed example; the frequency baseline picks the financial
candidate for both. This is a demonstration of different rules, not
empirical evidence of improvement. The Japanese queries have no imported
vectors, so no centroid scores are made. Frequency scores exist for
those queries, but tied training counts mean that the evaluator
abstains. Scoring-stage `processed` therefore does not mean a unique
prediction, an available embedding or a correct interpretation.

A missing candidate prototype stays missing and causes evaluator
abstention when the score list is incomplete. Frequency zero means no
selected training example of that candidate; an entirely unobserved
surface receives no scores. Zero vectors and canceling means are
recorded separately. Training counts can be small or uneven; inspect
them before interpreting a candidate comparison.

For a real run, use the optional embedding script below separately on
the two source rosters with identical settings, import both outputs, and
supply the training review and independent query reference. Do not
relabel query outputs as training data or manufacture new IDs to bypass
the split check. Participant overlap, near duplicates, pretraining
contamination and earlier model-selection leakage are not detected
automatically. This baseline cannot generalize to a new surface with no
training labels; a word-held-out study needs another method. Save the
entire `scored` object: each score output contains training fingerprints
and required declarations, while the full object retains all training
examples, prototype vectors and exclusion reasons.

## A study folder that survives a new R session

The installed `examples/contextual-study/` template connects
preparation, development, a frozen analysis, final scoring and replay.
It follows the useful file handoffs in [Masaki Eguchi’s LDA II project
template](https://github.com/egumasa/lda2-proj-template), using existing
ldfreq functions and local R files. No code or data from that project is
included. No cloud account, Python, model or new dependency is needed to
run this illustration; optional quanteda and a UTF-8 R session are
required.

**Every sentence, label, group and vector is authored.** The 14
documents are six training, four development and four test
illustrations. Group IDs demonstrate split checks; they do not identify
independent participants. The word *bank* and the readings of Japanese
`人気` illustrate different candidate inventories, not validated
equivalent ambiguity manipulations. The example’s test evaluation uses
`evaluation_role = "unknown"`, not a claim of independent held-out
accuracy.

| Script | What it does | Saved handoff |
|----|----|----|
| `01-prepare.R` | Creates source-checked occurrences, a document/group partition table, two authored judgments and a separate reference, plus vectors and a missing-vector case | `inputs/`: design, metadata, request CSVs, model and reference RDS files, readable decision CSV snapshots |
| `02-evaluate.R` | Checks document/group separation and exact target-context copies across partitions, evaluates development examples, freezes the settings and training inputs, then writes test scores before opening test reference labels | `analysis/`: development results, frozen inputs/settings/session, test scores and evaluations |
| `03-report.R` | Recomputes evaluation from saved scores and references, checks agreement with the saved result, and creates coverage and common-occurrence comparison tables | An R object `report`; this stage reads files without changing them |

Copy the scripts to a **new study directory**. Preparation and
evaluation refuse existing output directories, so a later run cannot
silently replace an earlier one. The report can be replayed repeatedly.
If a stage fails after writing a partial result, retain it for
diagnosis; fix the input and use a new run directory. Directories and
RDS files are not access controls, tamper-proof registration or proof
that a researcher did not inspect test examples.

``` r
template <- system.file("examples", "contextual-study", package = "ldfreq", mustWork = TRUE)
study_dir <- tempfile("ldfreq-study-") # Choose a permanent new folder for your study.
dir.create(study_dir)
stopifnot(all(file.copy(list.files(template, pattern = "[.]R$", full.names = TRUE), study_dir)))
run_stage <- function(script) {
  previous <- setwd(study_dir)
  on.exit(setwd(previous))
  env <- new.env(parent = globalenv())
  sys.source(script, envir = env)
  env
}
invisible(run_stage("01-prepare.R"))
#> Authored inputs saved. CSVs document these snapshots; editing a CSV does not update an RDS.
invisible(run_stage("02-evaluate.R"))
#> Development, frozen settings, test scores and evaluations saved separately.
study_report <- run_stage("03-report.R")$report
#>      method occurrences predictions paired agreement prediction_coverage
#> 1  centroid           4           3      2         2                0.75
#> 2 frequency           4           4      3         2                1.00
#>   agreement_among_paired matches_among_reference_selected
#> 1              1.0000000                        0.6666667
#> 2              0.6666667                        0.6666667
#>      method paired agreement agreement_among_paired coverage_of_all_occurrences
#> 1  centroid      2         2                    1.0                         0.5
#> 2 frequency      2         1                    0.5                         0.5
#> Replayed saved judgments and scores. Values are authored, not empirical accuracy.
study_report$comparison[c("method", "occurrences", "predictions", "paired",
  "agreement_among_paired", "matches_among_reference_selected")]
#>      method occurrences predictions paired agreement_among_paired
#> 1  centroid           4           3      2              1.0000000
#> 2 frequency           4           4      3              0.6666667
#>   matches_among_reference_selected
#> 1                        0.6666667
#> 2                        0.6666667
study_report$common_comparison
#>      method paired agreement agreement_among_paired coverage_of_all_occurrences
#> 1  centroid      2         2                    1.0                         0.5
#> 2 frequency      2         1                    0.5                         0.5
study_report$judgments$summary
#>   occurrences no_candidates a_reviewed b_reviewed both_reviewed both_selected
#> 1           4             0          4          4             4             3
#>   agreement disagreement selected_a_only selected_b_only neither_selected
#> 1         2            1               0               1                0
#>   both_selected_proportion agreement_among_both_selected
#> 1                     0.75                     0.6666667
```

The centroid method predicts 3/4 examples and matches 2/2 selected
references among those predictions. The frequency baseline predicts 4/4
and matches 2/3 selected references. Both match **2/3 of all selected
references**. On the two examples where both methods and the reference
are available, the match counts are 2/2 and 1/2. These are different
denominators and populations, not competing estimates of the same
quantity. Common-case coverage is only 2/4. The unresolved fourth
reference is not counted as correct or incorrect for either method.

The two authored judges jointly select a candidate in 3/4 cases and
agree in 2/3 of those cases. Their individual judgments survive
adjudication. An unresolved case remains unresolved in the reference.
`report$pairs` retains group/language metadata, predictions, reference
status and KWIC; `report$terms` and `report$review_queue` keep
word-level results and cases needing inspection. The counts are too
small, and the values too constructed, to support a claim about
English/Japanese accuracy, proficiency or psychological validity.

After changing to the copied study directory, these commands also run in
three separate R sessions. Replaying the report does not need the live
`inputs/` files or another model inference:

``` sh
Rscript --vanilla 01-prepare.R
Rscript --vanilla 02-evaluate.R
Rscript --vanilla 03-report.R
```

### Replace the authored inputs for a real study

Keep the three file handoffs, and adapt the preparation script to your
source annotations, candidate inventory and independently collected
decisions. In particular:

1.  Define the target population, sense/reading criteria, sampling and
    grouping before final evaluation. Use real author/speaker IDs for a
    study of new participants. For a study of new documents from known
    participants, define the grouping accordingly and describe that
    narrower claim. A supplied group ID is checked for overlap, not for
    its truth. Near-duplicate contexts and pretraining contamination
    still require separate assessment.
2.  Create unreviewed occurrence rosters and collect each annotator’s
    decisions without model suggestions. Retain their initial tables,
    disagreement review and reasons for adjudication separately. Rebuild
    each reference with
    `lexdiv_ambiguity_review(..., decisions = decisions)`, using its
    unchanged source and candidate resource. The CSV files here are
    readable snapshots; **editing them does not update the saved RDS
    inputs**. Read your finalized table explicitly (for these CSVs, use
    `na.strings = ""` and UTF-8), pass it to the review API, then save
    that rebuilt object in the reference bundle.
3.  Replace the authored vectors with actual source-aligned outputs
    imported by
    [`lexdiv_import_contextual()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_contextual.md).
    Keep the same declared model/layer/aggregation across partitions.
    Use development data to choose those settings, leaving final
    evaluation untouched. The scorer uses training labels only; this
    example keeps the original training data after development rather
    than refitting on development labels. Candidate inventories must
    agree, but a candidate need not occur in every partition. Report
    rare/missing candidates. If a partition yields no vectors, preserve
    a zero-row matrix with the known model dimension and column names;
    `NULL` does not declare those dimensions.
4.  Replace the authored protocol and `unknown` declarations only with
    accurate descriptions of your study. Freeze the selected settings
    and save test scores before examining test labels. Do not choose a
    model or tolerance by repeatedly trying the final evaluation set.
    Keep skipped examples, abstentions and unresolved references in
    their respective denominators.

For statistical comparisons, define the estimand and account for
repeated documents/participants, word inventories and unequal
missingness. The template supplies descriptive tables, not confidence
intervals or a test of superiority. Candidate-frequency counts describe
the labeled training sample, which may be balanced or purposefully
sampled; they are not population sense frequencies or TUBELEX
sense-specific frequencies. Source text in saved reviews retains the
original corpus’s sharing restrictions. No test-set secrecy is enforced
by RDS.

## Compute actual target embeddings with a cached model

The installed `examples/contextual-embeddings.py` is an optional,
explicitly invoked Python example using Hugging Face Transformers and
PyTorch. Obtain those dependencies and the chosen model separately under
their applicable terms. The script uses only the local Hugging Face
cache, a specified full commit, CPU inference and safetensors; it never
downloads files or loads custom remote code. A missing model or
incompatible tokenizer stops with an error.

It extracts the last hidden layer and averages only subwords that
exactly cover the target span. This is **not** the complete
sentence-transformers embedding pipeline, even when its base model is
used. It is not a trained WSD model and does not produce candidate
scores.

``` r
# Explicit optional step: jsonlite is a suggested package.
# 'review' and 'input' are the unchanged objects created above.
request_path <- tempfile(fileext = ".json")
output_path <- tempfile(fileext = ".json")
jsonlite::write_json(list(schema_version = "0.1.0", occurrences = input),
  request_path, dataframe = "rows", auto_unbox = TRUE, pretty = TRUE)
script <- system.file("examples", "contextual-embeddings.py", package = "ldfreq")
python <- Sys.which("python3") # Must contain torch and transformers.
stopifnot(nzchar(python))
# Illustration, not a validated Japanese WSD model. Cache this revision first.
model_id <- "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2"
revision <- "e8f8c211226b894fcb81acc59f3b34ba3efd5f42"
status <- system2(python, c(shQuote(script), "--input", shQuote(request_path),
  "--output", shQuote(output_path), "--model", shQuote(model_id),
  "--revision", shQuote(revision)))
stopifnot(status == 0L)
payload <- jsonlite::fromJSON(output_path)
stopifnot(identical(payload$schema_version, "0.1.0"))
embeddings <- NULL
if (length(payload$embeddings$occurrence_ids)) {
  embeddings <- as.matrix(payload$embeddings$values)
  rownames(embeddings) <- payload$embeddings$occurrence_ids
}
# A zero-row JSON array needs the typed, empty input roster in R.
returned <- payload$data
if (!length(returned)) {
  returned <- input[FALSE, ]
  returned$status <- returned$reason <- character()
}
actual <- lexdiv_import_contextual(review, returned, payload$model, embeddings)
actual$summary
actual$occurrences[c("surface", "model_status", "model_reason")]
saveRDS(actual, "contextual-model-result.rds")
```

The script processes one occurrence at a time; it is not a
high-throughput corpus engine. A fast tokenizer must expose original
character offsets. Python uses zero-based/end-exclusive offsets; R’s
request uses one-based/inclusive Unicode codepoints, so the script
subtracts one from `start` only. It rejects subwords crossing the target
boundary, gaps, overlaps and unknown target tokens. Overlong segments
are skipped without truncation. These strict checks can exclude valid
linguistic items that cannot be represented with exact spans: report
that coverage. See the [Hugging Face tokenizer
documentation](https://huggingface.co/docs/transformers/main_classes/tokenizer).

The full original segment is used regardless of the visible KWIC window.
Sentence/turn boundaries are supplied by the researcher. This initial
importer does not accept cropped, truncated or multi-segment contexts.
Record tokenizer normalization, model revision, layer and aggregation.
Do not mix models or dimensions in a matrix. The importer checks
declared anchors, not whether external software actually followed them.
Source text in JSON/RDS retains its original sharing restrictions; no
input corpus or model weights are bundled in ldfreq.

## Use existing R tools where they fit

[text](https://www.r-text.org/) already calls Transformer models from R
through Python. `text::textEmbed()` supports token/layer aggregation. An
adapter must additionally demonstrate exact per-occurrence target
alignment: do not label sentence or word-type vectors as target-token
vectors. For Japanese, review preprocessing explicitly: the documented
`remove_non_ascii` default is `TRUE`. See
[textEmbed](https://www.r-text.org/reference/textEmbed.html).

ldfreq adds checked source joins, missing-output coverage and
connections to human KWIC reviews and lexical resources. It does not
claim a new embedding algorithm or better accuracy. Either R or Python
can supply values satisfying the contract. The core R analyses require
neither model environment.

## Evaluate a research claim separately

A useful study asks whether contextual representations distinguish
meanings of the **target word** beyond a simple candidate-frequency
baseline. Define the inventory and obtain independent human judgments
first; WLSP row counts are not a gold-standard sense inventory.
GlossBERT illustrates an additional context/definition model for WSD,
not a capability obtained by averaging vectors ([Huang et al.,
2019](https://aclanthology.org/D19-1355/)).

Separate examples used to choose a model, layer, threshold or sense
prototype from final evaluation examples. For generalization to unseen
words or documents, split by those units rather than mixing their
occurrences across sets. Report candidate coverage,
processed/all-occurrence coverage, conditional accuracy on independently
resolved cases and unresolved cases separately. Inspect errors by
language, reading, frequency, genre and segmentation. Abstentions must
remain visible. For usability, compare existing tools and this joined
workflow on the same task: erroneous joins, missed cases, correction
time and reproducibility. Human review time, semantic accuracy, norm
validity and learner knowledge require evidence beyond a software round
trip; the authored examples supply none of it.

``` r
saved <- tempfile(fileext = ".rds")
saveRDS(imported, saved)
stopifnot(identical(readRDS(saved), imported))
unlink(saved)
```
