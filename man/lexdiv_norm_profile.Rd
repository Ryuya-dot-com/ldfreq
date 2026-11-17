\name{lexdiv_norm_profile}
\alias{lexdiv_norm_profile}
\alias{lexdiv_norm_spec}
\alias{lexdiv_resource_meta}
\alias{print.lexdiv_norm_profile}
\alias{print.lexdiv_norm_profile_batch}
\title{Profile One or More Documents with Caller-Supplied Lexical Norms}
\usage{
lexdiv_norm_profile(
  x,
  norms,
  key,
  measure_specs = NULL,
  resource = lexdiv_resource_meta("caller_norms"),
  weightings = c("token", "type"),
  id_col = "document_id",
  term_col = "terms",
  max_rows = 1e+06
)

lexdiv_norm_spec(
  value_column,
  measure_id = NULL,
  construct_id = measure_id,
  value_unit = "unspecified",
  direction = "descriptive",
  language = "unspecified",
  variety = "unspecified",
  population_id = "unspecified",
  collection_year = "unspecified",
  valid_min = NA_real_,
  valid_max = NA_real_
)

lexdiv_resource_meta(
  resource_id = "caller_resource",
  resource_version = "unspecified",
  creator = "unspecified",
  source_reference = "unspecified",
  data_license = "unspecified",
  transformation_id = "none",
  lookup_unit = "exact_term",
  resource_key_normalization_id = "caller-prepared-v1"
)

\method{print}{lexdiv_norm_profile}(x, ...)

\method{print}{lexdiv_norm_profile_batch}(x, ...)
}
\arguments{
\item{x}{For a single document, a character vector of caller-prepared lookup
terms or a \code{lexdiv_tokenization} object. For multiple documents, a named
list of term vectors, a \code{lexdiv_tokenization_batch} object, or a data
frame/tibble with \code{id_col} and \code{term_col}. For \code{print()}, a
\code{lexdiv_norm_profile} or \code{lexdiv_norm_profile_batch} object.}
\item{norms}{A data frame or tibble containing one unique key column and numeric
norm columns. Non-numeric metadata columns are ignored automatically when
\code{measure_specs = NULL}.}
\item{key}{One string naming the exact-match key column in \code{norms}.}
\item{measure_specs}{Optional data frame or tibble of 11 measure-specification
columns (from \code{lexdiv_norm_spec()}). When \code{NULL}, defaults to all
plain numeric columns in \code{norms} other than \code{key}, sanitizing
non-identifier column names (such as \code{"\%_known"} to \code{"pct_known"}).}
\item{resource}{Named list of 8 resource-metadata fields from
\code{lexdiv_resource_meta()}.}
\item{weightings}{A non-empty subset of \code{c("token", "type")}.}
\item{id_col}{Document-ID column name for multi-document data-frame input.}
\item{term_col}{Term list-column name for multi-document data-frame input
(default \code{"terms"}), or token column name for tokenization input
(defaults to \code{"surface"} when omitted).}
\item{max_rows}{Positive whole-number row bound checked before allocation.}
\item{value_column, measure_id, construct_id, value_unit, direction, language,
variety, population_id, collection_year, valid_min, valid_max}{Vectorized or
scalar fields recycled across \code{value_column} by \code{lexdiv_norm_spec()}.}
\item{resource_id, resource_version, creator, source_reference, data_license,
transformation_id, lookup_unit, resource_key_normalization_id}{Scalar provenance
fields assembled by \code{lexdiv_resource_meta()}.}
\item{...}{Additional arguments passed to \code{print.data.frame()}.}
}
\value{
For a single document, \code{lexdiv_norm_profile()} returns a
\code{lexdiv_norm_profile} list with \code{status}, \code{summary},
\code{lookup}, \code{coverage}, \code{provenance}, and \code{diagnostics}. For
multiple documents, it returns a \code{lexdiv_norm_profile_batch} list with
document-major \code{summary}, \code{lookup}, and \code{coverage} tables.
\code{lexdiv_norm_spec()} returns an 11-column specification data frame.
\code{lexdiv_resource_meta()} returns an 8-element metadata list. \code{print()}
returns \code{x} invisibly.
}
\description{
Computes token- and/or type-weighted arithmetic means for one or more
lexical-norm variables on one document or a multi-document corpus from matched
observed keys while reporting resource and annotation coverage separately.
}
\examples{
norms <- data.frame(
  term = c("book", "read", "rare"),
  familiarity = c(6, 5, NA_real_),
  aoa = c(4.2, 5.0, 11.5),
  note = c("noun", "verb", "adj")
)

# Single document (non-numeric 'note' column is ignored automatically):
quick <- lexdiv_norm_profile(c("book", "book", "rare", "unknown"), norms, "term")
quick

# Multiple documents with explicit metadata:
specs <- lexdiv_norm_spec(
  c("familiarity", "aoa"),
  direction = c("higher", "lower"),
  valid_min = c(1, 0),
  valid_max = c(7, 25)
)
meta <- lexdiv_resource_meta("example_norms", resource_version = "2025-01")
batch <- lexdiv_norm_profile(
  list(d1 = c("book", "read"), d2 = c("rare", "unknown")),
  norms, "term", specs, meta
)
batch$summary[, c("document_id", "measure_id", "weighting", "estimate")]
}
\seealso{\code{\link{nj8_profile}}, \code{\link{tubelex_profile}}}
\keyword{text}
