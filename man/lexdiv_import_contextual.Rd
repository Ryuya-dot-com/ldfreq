\name{lexdiv_import_contextual}
\alias{lexdiv_import_contextual}
\title{Attach external model outputs to verified contextual occurrences}
\description{
Imports caller-computed embeddings or lexical-candidate scores into a complete
ambiguity review. Original text, positions and snapshot IDs must match. Human
decisions remain separate. This experimental function performs no model inference
and requires no Python or model installation.
}
\usage{
lexdiv_import_contextual(review, data, model, embeddings = NULL,
  suggestions = NULL)
}
\arguments{
\item{review}{An unmodified \code{\link{lexdiv_ambiguity_review}} result with
a whole-result fingerprint.}
\item{data}{Plain data frame containing character \code{review_id},
\code{occurrence_id}, \code{segment_text}, \code{surface}, \code{status},
\code{reason}, and numeric whole-number \code{start}/\code{end} positions.
Copy the first four and positions from the review before computation and return
them unchanged. Positions are 1-based inclusive Unicode codepoints in the
original segment. Each returned occurrence appears at most once, in any order.
Status is \code{processed}, \code{skipped} or \code{error}; each row requires
a non-blank reason. Omitted occurrences are reported as \code{not_returned}.
Zero rows are allowed. Extra columns are retained in the returned \code{data}.}
\item{model}{Plain named list of non-blank scalar strings, including
\code{model_id}, \code{model_revision}, \code{tokenizer_id},
\code{tokenizer_revision}, \code{software}, \code{software_version}, and
\code{context_policy}. This initial interface requires the context policy
\code{"full segment; no truncation"}. Non-null embeddings also require
\code{representation} describing layer, target extraction and aggregation;
non-null suggestions require \code{score_definition}, including scale and
direction. Extra declarations such as device, precision, file hashes and model
terms are retained. These declarations do not authenticate the computation.}
\item{embeddings}{\code{NULL}, or a finite numeric matrix with at least one
column. Row names must be unique processed occurrence IDs. Rows may arrive in
any order and are returned in review order. Missing occurrences have no vector;
they are not replaced with zero vectors.}
\item{suggestions}{\code{NULL}, or a plain data frame with exactly
\code{occurrence_id}, \code{candidate_id} and \code{score} columns. IDs are
character, scores are finite numeric values. Each occurrence/candidate pair
must be unique, refer to a processed occurrence and belong to that surface's
candidate inventory. Ties, negative scores and partial candidate lists are
allowed; there is no automatic ranking, probability conversion or selection.}
}
\details{
Every processed occurrence must have at least one embedding or suggestion;
skipped, error and omitted occurrences must not have either. Source changes,
stale review IDs, unknown or duplicated occurrences, shifted spans, non-finite
values and candidates belonging to other words are rejected. Changing human
decisions or KWIC display width alone does not invalidate source-linked output.

The source checks detect inconsistent joins, not fabricated outputs, inaccurate
model declarations or semantic errors. Never paste new IDs or original text
onto results computed from different inputs. External code must verify target
subword alignment, preserve the full segment and record failures. Model
tokenization can differ from the research tokenization. A whole-sentence vector
is not a target-word vector. No similarity, sense count, proficiency estimate,
normative rating or word-sense accuracy is inferred by importing a matrix.

The installed \file{examples/contextual-embeddings.py} script illustrates an
explicit, offline CPU call to a separately cached, commit-pinned Hugging Face
model with a fast tokenizer. It requires exact target subword coverage, skips
unknown targets and overlong segments, and computes last-layer target means.
It does not implement the complete sentence-transformers pipeline or WSD.
See \code{vignette("contextual-models", package = "ldfreq")} for the JSON
exchange and validation boundaries. R never invokes it implicitly. No model
weights, text corpora or new dependencies are bundled.
}
\value{
A plain list: \code{occurrences} retains every review occurrence and human
decision, adding \code{model_status}, \code{model_reason}, \code{has_embedding}
and \code{n_suggestions}; \code{embeddings} contains the ID-keyed matrix;
\code{suggestions} contains each supplied score, candidate label, original
context, \code{human_status} and \code{human_candidate_id}. \code{summary}
reports all-occurrence denominators and processing coverage. \code{data},
\code{review} and \code{provenance} preserve complete inputs and declarations.
Use \code{saveRDS()} to retain the whole object, which includes source text and
inherits the input sharing restrictions.
}
\examples{
if (requireNamespace("quanteda", quietly = TRUE)) {
  x <- lexdiv_import_annotations(
    data.frame(document_id = "d", segment_id = "s", token_index = 1:3,
      surface = c("The", "bank", ".")),
    data.frame(document_id = "d", segment_id = "s", text = "The bank."),
    list(language = "en", analyzer = "authored", analyzer_version = "1",
      dictionary = "none", dictionary_version = "none", unit = "authored",
      normalization = "none"))
  review <- lexdiv_ambiguity_review(x, "bank",
    data.frame(term = "bank", candidate_id = "financial", label = "financial institution"),
    list(resource_id = "authored", resource_version = "1",
      source_reference = "Authored illustration", data_license = "MIT"))
  data <- review$occurrences[c("review_id", "occurrence_id", "segment_text",
    "surface", "start", "end")]
  data$status <- "processed"
  data$reason <- "Authored transport example, not model inference"
  model <- list(model_id = "authored", model_revision = "1",
    tokenizer_id = "authored", tokenizer_revision = "1",
    software = "example", software_version = "1",
    context_policy = "full segment; no truncation",
    representation = "authored two-dimensional values")
  vectors <- matrix(c(1, 0), nrow = 1,
    dimnames = list(data$occurrence_id, NULL))
  imported <- lexdiv_import_contextual(review, data, model, vectors)
  imported$summary
  imported$occurrences[c("status", "model_status", "has_embedding")]
}
}
\seealso{\code{\link{lexdiv_ambiguity_review}},
\code{\link{lexdiv_evaluate_contextual}},
\code{\link{lexdiv_compare_ambiguity}}}
