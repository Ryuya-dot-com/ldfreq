\name{lexdiv_evaluate_contextual}
\alias{lexdiv_evaluate_contextual}
\title{Compare contextual candidate scores with an explicit reference review}
\description{
Derives a unique best-scoring candidate only for complete score inventories and
compares it to selected reference judgments. Ties, incomplete scores and missing
judgments remain explicit. This experimental descriptive evaluator does not
change human decisions, run inference or establish reference validity.
}
\usage{
lexdiv_evaluate_contextual(x, reference, direction, reference_info,
  tie_tolerance = 0)
}
\arguments{
\item{x}{An unmodified \code{\link{lexdiv_import_contextual}} result with
its complete content fingerprint. Embedding-only results are allowed but produce
no predictions: this function does not convert embeddings to candidate scores.}
\item{reference}{An unmodified \code{\link{lexdiv_ambiguity_review}} result
using the same source, targets, candidate inventory and resource snapshot as
\code{x}. Only \code{selected} judgments supply a reference label. Unresolved,
unreviewed and no-candidate occurrences are retained. Decisions and display
windows may differ from the review used to import model output.}
\item{direction}{Required scalar string: \code{"higher"} for larger-is-better
scores or \code{"lower"} for smaller-is-better scores. Match this to the model's
declared score definition; the function does not interpret that prose.}
\item{reference_info}{Plain named list of non-blank scalar strings including
\code{reference_id}, \code{annotation_protocol}, \code{model_exposure}
(\code{not_shown}, \code{shown} or \code{unknown}), and \code{evaluation_role}
(\code{held_out}, \code{development} or \code{unknown}). Additional declarations
are retained. These statements do not prove independent annotation, valid
labels or absence of training/model-selection leakage.}
\item{tie_tolerance}{One finite non-negative number, in the supplied score's
absolute units. All candidates whose scores differ from the best by at most
this value are tied. Default zero treats exactly equal scores as ties. Set the
policy before final evaluation; this is not a calibrated confidence threshold.}
}
\details{
Predictions require a score for every candidate in that surface's supplied
inventory and exactly one best candidate within the tolerance. No candidates,
no scores, partial inventories and tied best scores yield \code{NA} predictions
with statuses \code{no_candidates}, \code{no_scores},
\code{incomplete_scores} and \code{tied_best}. A complete unique best is
\code{unique_best}. The reported best score/count for a partial inventory is
descriptive only; even when the reference candidate is scored, missing rivals
prevent a prediction. Original model error/skipped/not-returned reasons remain
available. Candidate completeness is relative to the supplied table, not proof
that all possible meanings were included.

Predictions are separate from human selections. A fully scored singleton
inventory produces a trivial unique best; these predictions are counted
separately. Candidate IDs remain scoped to their surface in confusion tables.
Comparisons use occurrence IDs rather than row positions. Modified inputs or
changed source/candidate snapshots are rejected. Reordering score rows or
reference decisions does not change the comparison.

Agreement is conditional on both a prediction and a selected reference.
\code{matches_among_reference_selected} instead divides matching pairs by
all selected-reference occurrences, including those without a prediction.
It measures the fraction receiving a matching prediction, not agreement on
unknown labels. All proportions include their underlying counts and are
\code{NA} when the denominator is zero. Pooled summaries weight occurrences,
not word types. No significance tests, confidence intervals, macro average,
chance correction, threshold optimization or benchmark-specific F1 is computed.

Model-assisted reference judgments are not independent validation. Even a
declared blinded held-out reference requires external checks of the annotation
protocol, candidate inventory, sampling and split. These outputs describe
agreement, not automatically gold-standard accuracy or learner knowledge.
See \code{vignette("contextual-models", package = "ldfreq")}.
}
\value{
A plain list with overall \code{summary}, per-target \code{terms} (including
absent targets), source/KWIC \code{pairs}, a term-specific \code{confusion} count
table for paired cases, and a \code{review_queue} containing every non-agreement,
including unavailable comparisons. Pair fields include reference judgment,
reviewer/reason, prediction status/ID, best score/count, whether the reference
candidate was scored, and nullable \code{matches_reference}. Summary counts
distinguish all outcomes and prediction statuses. \code{prediction_coverage},
\code{reference_coverage} and \code{paired_coverage} use all occurrences;
\code{agreement_among_paired} uses paired cases;
\code{matches_among_reference_selected} uses selected reference cases.
The complete \code{model_output}, \code{reference} and declared policy are retained.
Use \code{saveRDS()} to keep source text, scores, judgments and provenance together.
}
\examples{
if (requireNamespace("quanteda", quietly = TRUE)) {
  annotation <- lexdiv_import_annotations(
    data.frame(document_id = "d", segment_id = "s", token_index = 1L, surface = "bank"),
    data.frame(document_id = "d", segment_id = "s", text = "bank"),
    list(language = "en", analyzer = "authored", analyzer_version = "1",
      dictionary = "none", dictionary_version = "none", unit = "test", normalization = "none"))
  candidates <- data.frame(term = c("bank", "bank"), candidate_id = c("a", "b"),
    label = c("financial", "river"))
  resource <- list(resource_id = "authored", resource_version = "1",
    source_reference = "Authored illustration", data_license = "MIT")
  review <- lexdiv_ambiguity_review(annotation, "bank", candidates, resource)
  data <- review$occurrences[c("review_id", "occurrence_id", "segment_text", "surface", "start", "end")]
  data$status <- "processed"; data$reason <- "Authored scores, not model inference"
  scores <- data.frame(occurrence_id = rep(data$occurrence_id, 2),
    candidate_id = c("a", "b"), score = c(2, 0))
  model <- list(model_id = "authored", model_revision = "1", tokenizer_id = "authored",
    tokenizer_revision = "1", software = "example", software_version = "1",
    context_policy = "full segment; no truncation", score_definition = "larger is preferred")
  imported <- lexdiv_import_contextual(review, data, model, suggestions = scores)
  decisions <- data[c("review_id", "occurrence_id")]
  decisions$status <- "selected"; decisions$candidate_id <- "a"
  decisions$reviewer <- "example"; decisions$reason <- "Authored reference, not human evidence"
  reference <- lexdiv_ambiguity_review(annotation, "bank", candidates, resource, decisions)
  evaluated <- lexdiv_evaluate_contextual(imported, reference, "higher", list(
    reference_id = "authored", annotation_protocol = "Authored demonstration",
    model_exposure = "unknown", evaluation_role = "development"))
  evaluated$summary[c("agreement", "paired", "agreement_among_paired", "prediction_coverage")]
}
}
\seealso{\code{\link{lexdiv_import_contextual}},
\code{\link{lexdiv_compare_ambiguity}}}
