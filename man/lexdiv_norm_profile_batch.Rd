\name{lexdiv_norm_profile_batch}
\alias{lexdiv_norm_profile_batch}
\alias{print.lexdiv_norm_profile_batch}
\title{Apply Caller-Supplied Lexical Norms to Multiple Documents}
\usage{
lexdiv_norm_profile_batch(documents, norms, key, measure_specs, resource,
  weightings = c("token", "type"), id_col = "document_id",
  terms_col = "terms", max_rows = 1e6)

\method{print}{lexdiv_norm_profile_batch}(x, ...)
}
\arguments{
\item{documents}{A plain named list of prepared term vectors, or a data frame
with explicit character IDs and a list-column of term vectors. Each vector
must satisfy \code{\link{lexdiv_norm_profile}}. Empty documents and zero-document
batches are accepted; invalid terms stop the whole call and identify the
document. A term is a lookup unit, not an unprocessed sentence.}
\item{norms,key,measure_specs,resource,weightings}{Exactly the arguments of
\code{\link{lexdiv_norm_profile}}. One shared reference table, measure
specification and requested weighting set apply to every document. Shared
inputs are validated once per call. Matching and arithmetic are unchanged.}
\item{id_col,terms_col}{Distinct column names for a data-frame input. IDs
must be unique, non-empty UTF-8 strings without missing values. Input document
order is preserved. Extra columns are ignored; retain and join metadata by ID.}
\item{max_rows}{Positive whole-number bound on the combined rows of
\code{lookup}, \code{summary}, and \code{coverage} for the entire batch,
checked before lookup or result allocation. The default is one million.}
\item{x}{A \code{lexdiv_norm_profile_batch} object.}
\item{...}{Additional arguments passed to \code{print.data.frame()}.}
}
\description{
Applies the single-document lexical-norm calculation with one validated shared
resource. Every document retains its estimates, lookup rows, coverage and
missingness. Documents are not pooled into a corpus score.
}
\value{
A \code{lexdiv_norm_profile_batch} list with six components:
\describe{
\item{status}{\code{"empty"} for zero documents and \code{"ok"} otherwise.
This is a container status; inspect measure-level missingness in the tables.}
\item{summary,lookup,coverage}{The unchanged single-document tables with
\code{document_id} prepended. Rows are document-major, then follow the
single-document ordering. \code{result_order} restarts within each document.
Empty documents retain all requested summary and coverage rows, with
\code{empty_input} reasons. Zero documents give typed zero-row tables.}
\item{provenance}{Complete shared single-document provenance plus
\code{batch_contract_id}, \code{batch_contract_version},
\code{batch_result_schema_id}, \code{batch_result_schema_version},
\code{document_count}, and ordered \code{document_ids}. Caller-supplied resource
metadata describe the source; they do not authenticate its contents or rights.}
\item{diagnostics}{\code{documents} has one row per ID, document \code{status},
\code{input_terms}, \code{input_types} and planned rows for each table and their
total. \code{batch} records resource/measure/weighting/document counts, global
row plans, \code{max_rows}, preserved-order flags and the absence of imputation,
automatic thresholds, pooling, composite scoring, parallelism and networking.}
}
\code{print()} displays at most 12 summary rows and returns \code{x} invisibly.
}
\details{
With \eqn{D} documents, \eqn{M} measures and \eqn{W} weightings, the row budget
is \code{M * sum(document_term_counts) + 2 * D * M * W}. It is global, not
reset per document. Results are equivalent to calling the single-document
function on every valid vector and prepending its ID. Malformed containers,
duplicate IDs, invalid terms, invalid shared inputs and excess rows raise R
errors. Valid documents with no matches or no observed values remain present.

Means remain conditional on observed matched values. Report resource coverage,
value coverage and annotation coverage, which have distinct denominators.
Keep token/type weighting and unlike constructs, units and populations separate.
No automatic normalization, resource download, thresholds or scale conversion
is performed. These data requirements apply equally to native-speaker, learner
and other corpora. A low-frequency or unmatched word is not automatically
difficult, and a mean norm value does not establish proficiency.

For a different reference resource, make a separate call and retain that
resource's identity and coverage. Metadata supplied by the caller are not a
content fingerprint; save the actual table, measure specifications and result
with the original preprocessing and corpus metadata for reproducibility.
}
\examples{
# Project-authored numbers, not published familiarity norms.
norms <- data.frame(term = c("book", "read", "rare"),
  familiarity = c(6, 5, NA_real_))
specs <- data.frame(measure_id = "familiarity", value_column = "familiarity",
  construct_id = "subjective_familiarity", value_unit = "seven_point_rating",
  direction = "higher", language = "English", variety = "unspecified",
  population_id = "authored_demo", collection_year = "not_observed",
  valid_min = 1, valid_max = 7)
resource <- list(resource_id = "authored_norms", resource_version = "1",
  creator = "Example author", source_reference = "Authored demonstration",
  data_license = "Example numbers; no external dataset", transformation_id = "none",
  lookup_unit = "lowercase_surface",
  resource_key_normalization_id = "caller-prepared-v1")
documents <- list(essay = c("book", "book", "rare", "outside"),
  conversation = c("read", "book"), blank = character())
result <- lexdiv_norm_profile_batch(documents, norms, "term", specs, resource)
result$coverage
result$diagnostics$documents
print(result)
}
\seealso{\code{\link{lexdiv_norm_profile}},
\code{\link{lexdiv_as_documents}}, \code{\link{lexdiv_tokenize_batch}}}
\keyword{text}
