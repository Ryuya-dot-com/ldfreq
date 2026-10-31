\name{lexdiv_norm_profile}
\alias{lexdiv_norm_profile}
\alias{lexdiv_norm_spec}
\alias{lexdiv_resource_meta}
\alias{print.lexdiv_norm_profile}
\title{Profile Terms with Caller-Supplied Lexical Norms}
\usage{
lexdiv_norm_profile(
  terms,
  norms,
  key,
  measure_specs = lexdiv_norm_spec(setdiff(names(norms), key)),
  resource = lexdiv_resource_meta("caller_norms"),
  weightings = c("token", "type"),
  max_rows = 1e+06
)

lexdiv_norm_spec(
  value_column,
  measure_id = value_column,
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
}
\arguments{
\item{terms}{A character vector with one caller-prepared lookup term per
element. Zero length and named vectors are allowed.}
\item{norms}{A data frame or tibble containing one unique key column and the
numeric norm columns named by \code{measure_specs}.}
\item{key}{One string naming the exact-match key column in \code{norms}.}
\item{measure_specs}{Data frame or tibble of 11 measure-specification columns
(in any column order), defaulting to \code{lexdiv_norm_spec(setdiff(names(norms), key))}.}
\item{resource}{Named list of 8 resource-metadata fields (in any field order),
defaulting to \code{lexdiv_resource_meta("caller_norms")}.}
\item{weightings}{A non-empty subset of \code{c("token", "type")}.}
\item{max_rows}{Positive whole-number row bound checked before allocation.}
\item{value_column, measure_id, construct_id, value_unit, direction, language,
variety, population_id, collection_year, valid_min, valid_max}{Vectorized or
scalar fields recycled across \code{value_column} by \code{lexdiv_norm_spec()}.}
\item{resource_id, resource_version, creator, source_reference, data_license,
transformation_id, lookup_unit, resource_key_normalization_id}{Scalar provenance
fields assembled by \code{lexdiv_resource_meta()}.}
\item{x}{A \code{lexdiv_norm_profile} object.}
\item{...}{Additional arguments passed to \code{print.data.frame()}.}
}
\value{
\code{lexdiv_norm_profile()} returns a \code{lexdiv_norm_profile} list with
\code{status}, \code{summary}, \code{lookup}, \code{coverage},
\code{provenance}, and \code{diagnostics}. \code{lexdiv_norm_spec()} returns an
11-column specification data frame. \code{lexdiv_resource_meta()} returns an
8-element metadata list. \code{print()} returns \code{x} invisibly.
}
\description{
Computes token- and/or type-weighted arithmetic means for one or more
lexical-norm variables from matched observed keys while reporting resource and
annotation coverage separately.
}
\examples{
norms <- data.frame(
  term = c("book", "read", "rare"),
  familiarity = c(6, 5, NA_real_),
  aoa = c(4.2, 5.0, 11.5)
)

# Concise call with automatic measure_specs and resource defaults:
quick <- lexdiv_norm_profile(c("book", "book", "rare", "unknown"), norms, "term")
quick

# Explicit publication-ready metadata via helpers:
specs <- lexdiv_norm_spec(
  c("familiarity", "aoa"),
  direction = c("higher", "lower"),
  valid_min = c(1, 0),
  valid_max = c(7, 25)
)
meta <- lexdiv_resource_meta("example_norms", resource_version = "2025-01")
profile <- lexdiv_norm_profile(c("book", "read"), norms, "term", specs, meta)
profile$summary[, c("measure_id", "weighting", "estimate", "value_coverage")]
}
\seealso{\code{\link{lexdiv_norm_profile_batch}}}
