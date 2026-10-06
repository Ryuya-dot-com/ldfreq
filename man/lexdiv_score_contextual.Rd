\name{lexdiv_score_contextual}
\alias{lexdiv_score_contextual}
\title{Score contextual candidates using separate labeled training examples}
\description{
Experimental supervised baselines using imported target embeddings: cosine to
each candidate's training centroid and selected-label training frequency.
Scores connect directly to contextual evaluation and KWIC review. No model
download, embedding inference, tuning or query-label fitting is performed.
}
\usage{
lexdiv_score_contextual(x, training, reference, training_info)
}
\arguments{
\item{x}{An unmodified \code{\link{lexdiv_import_contextual}} result for query
occurrences, containing an embedding matrix (possibly with zero rows). Query
judgments and existing candidate scores are retained but never used for fitting
or scoring. Missing/zero query vectors remain in the occurrence roster.}
\item{training}{An unmodified contextual import with training embeddings.
Targets, complete candidate table, resource metadata, embedding dimensions,
column names and model declarations must match \code{x}. Model list order and
the prior \code{score_definition} may differ; all other declarations must agree.}
\item{reference}{An unmodified \code{\link{lexdiv_ambiguity_review}} result for
the training snapshot. Only selected labels contribute. It may differ from the
human review originally stored in \code{training}.}
\item{training_info}{Plain named list of non-blank scalar strings requiring
\code{training_id}, \code{annotation_protocol}, \code{partition_protocol}, and
\code{model_exposure} (\code{not_shown}, \code{shown}, or \code{unknown}). These
are researcher declarations, not verified independence or absence of leakage.
Additional string declarations are retained in the full result.}
}
\details{
Partition sources before importing annotations and model output. All training
and query document IDs must be disjoint. Identical target-bearing segment text
across the two inputs is rejected even when document IDs have changed. These
checks cannot detect near duplicates, renamed fragments, participant overlap,
pretraining contamination or earlier use of query labels for model selection.
Use stable document IDs and a scientifically appropriate external split.

Within each exact surface/candidate pair, the centroid is the arithmetic mean
of nonzero training vectors with selected reference labels, followed by L2
normalization. Individual training vectors are not normalized before averaging.
A common positive scale is used before averaging to avoid overflow. The score
is cosine similarity to a nonzero query vector, bounded to [-1, 1] for floating
point roundoff; higher is closer. This is not a probability or a calibrated
semantic-distance measure. Zero vectors, missing vectors, unselected labels and
zero (canceling) centroids do not produce usable prototypes. An unavailable
candidate score is missing, not zero; the evaluator abstains on partial lists.

The frequency baseline uses all selected training labels, including examples
without usable embeddings. Every candidate for an observed surface receives
its unsmoothed training count, including zero for an unobserved candidate. A
surface with no selected training labels receives no scores. Query embeddings
are not used by this baseline. Thus its coverage and training sample can differ
from the centroid method; both counts and all original input statuses are retained.
Neither method automatically breaks ties or substitutes for the other.

This is a within-surface baseline, not a full implementation of LMMS, WordNet
propagation, gloss scoring or unseen-word generalization. See Loureiro and Jorge
(2019), \doi{10.18653/v1/P19-1569}, for annotated sense embeddings and a broader
WSD method. The supplied candidate inventory, annotation quality and external
evaluation determine what research claims these scores can support.

Audit column names such as \code{n_selected}, \code{prototype_status}, and
\code{centroid_status} are reserved. Conflicting input columns are rejected.
See \code{vignette("contextual-models", package = "ldfreq")} for a complete
English/Japanese scoring, baseline comparison and KWIC example.
}
\value{
A plain list. \code{centroid} and \code{frequency} are complete contextual-import
results ready for \code{lexdiv_evaluate_contextual(..., direction = "higher")}.
Their processed/skipped status refers to the scoring stage; reasons also retain
the original embedding-output status/reason. No new human selections are made.
\code{candidates} preserves the supplied inventory with \code{n_selected},
\code{n_vectors} and \code{prototype_status} (\code{available},
\code{no_selected_reference}, \code{no_valid_vectors}, \code{zero_centroid}).
\code{prototypes} contains normalized centroids in candidate-table row order;
unavailable rows are \code{NA}. \code{training_occurrences} records reference
choices, count/centroid inclusion and exclusion status.
\code{query_occurrences} retains original model statuses and reasons beside
\code{embedding_status}, score counts and each scorer's status. Full
\code{query}, \code{training}, \code{reference} and declared \code{provenance}
are retained. Save the whole result with \code{saveRDS()} to preserve this audit;
the two score outputs alone retain training fingerprints and required
declarations but not the complete training inputs.
}
\examples{
if (requireNamespace("quanteda", quietly = TRUE)) {
  candidates <- data.frame(term = c("bank", "bank"), candidate_id = c("a", "b"),
    label = c("financial", "river"))
  resource <- list(resource_id = "authored", resource_version = "1",
    source_reference = "Authored demonstration", data_license = "MIT")
  model <- list(model_id = "authored", model_revision = "1", tokenizer_id = "authored",
    tokenizer_revision = "1", software = "example", software_version = "1",
    context_policy = "full segment; no truncation", representation = "authored vectors")
  make <- function(id, words, vectors, labels = NULL) {
    source <- lexdiv_import_annotations(
      data.frame(document_id = id, segment_id = rep(as.character(seq_along(words)), each = 2),
        token_index = rep(1:2, length(words)), surface = as.vector(rbind(words, "bank"))),
      data.frame(document_id = id, segment_id = as.character(seq_along(words)),
        text = paste(words, "bank")),
      list(language = "en", analyzer = "authored", analyzer_version = "1",
        dictionary = "none", dictionary_version = "none", unit = "test", normalization = "none"))
    review <- lexdiv_ambiguity_review(source, "bank", candidates, resource)
    data <- review$occurrences[c("review_id", "occurrence_id", "segment_text", "surface", "start", "end")]
    data$status <- "processed"; data$reason <- "Authored illustration"
    rownames(vectors) <- data$occurrence_id
    output <- lexdiv_import_contextual(review, data, model, vectors)
    if (!is.null(labels)) {
      d <- data[c("review_id", "occurrence_id")]
      d$status <- "selected"; d$candidate_id <- labels
      d$reviewer <- "author"; d$reason <- "Authored training label"
      review <- lexdiv_ambiguity_review(source, "bank", candidates, resource, d)
    }
    list(output = output, reference = review)
  }
  train <- make("train", c("money", "river"), diag(2), c("a", "b"))
  query <- make("query", "another", matrix(c(1, 0), nrow = 1))
  scored <- lexdiv_score_contextual(query$output, train$output, train$reference,
    list(training_id = "authored", annotation_protocol = "Authored labels, not human evidence",
      partition_protocol = "Separate authored documents", model_exposure = "unknown"))
  scored$centroid$suggestions[c("surface", "candidate_id", "score")]
  scored$candidates[c("term", "candidate_id", "n_selected", "n_vectors")]
}
}
\seealso{\code{\link{lexdiv_import_contextual}}, \code{\link{lexdiv_evaluate_contextual}}}
