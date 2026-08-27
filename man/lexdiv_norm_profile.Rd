\name{lexdiv_norm_profile}
\alias{lexdiv_norm_profile}
\alias{print.lexdiv_norm_profile}
\title{Profile Terms with Caller-Supplied Lexical Norms}
\usage{
lexdiv_norm_profile(
  terms,
  norms,
  key,
  measure_specs,
  resource,
  weightings = c("token", "type"),
  max_rows = 1e+06
)

\method{print}{lexdiv_norm_profile}(x, ...)
}
\arguments{
\item{terms}{A plain character vector with one caller-prepared lookup term per
element. Zero length is allowed. Terms are retained in \code{lookup}.}

\item{norms}{An ordinary data frame containing one unique key column and the
numeric norm columns named by \code{measure_specs}. Other columns are ignored
and are not copied into the result.}

\item{key}{One string naming the exact-match key column in \code{norms}.}

\item{measure_specs}{An ordinary data frame with the exact ordered columns
\code{measure_id}, \code{value_column}, \code{construct_id},
\code{value_unit}, \code{direction}, \code{language}, \code{variety},
\code{population_id}, \code{collection_year}, \code{valid_min}, and
\code{valid_max}. IDs must be unique; \code{direction} is \code{"higher"},
\code{"lower"}, or \code{"descriptive"}; numeric bounds may be \code{NA}.}

\item{resource}{A plain named list with the exact ordered fields
\code{resource_id}, \code{resource_version}, \code{creator},
\code{source_reference}, \code{data_license}, \code{transformation_id},
\code{lookup_unit}, and \code{resource_key_normalization_id}. These are caller
assertions recorded for provenance; they do not establish redistribution
rights.}

\item{weightings}{A non-empty subset of \code{c("token", "type")}, without
duplicates. Type identity is the exact lookup term after no package-side
transformation.}

\item{max_rows}{A positive whole-number bound on the combined rows planned for
\code{lookup}, \code{summary}, and \code{coverage}, checked before result
allocation.}

\item{x}{A \code{lexdiv_norm_profile} object.}

\item{...}{Additional arguments passed to \code{print.data.frame()}.}
}
\value{
A \code{lexdiv_norm_profile} list with \code{status}, \code{summary},
\code{lookup}, \code{coverage}, \code{provenance}, and \code{diagnostics}.
\code{summary} contains conditional observed matched-only means and their
denominators. \code{lookup} contains one input-major, measure-minor row per
term and measure. \code{coverage} is the analysis-ready denominator projection
of \code{summary}. No missing value is imputed and no automatic coverage
threshold is applied. \code{print.lexdiv_norm_profile()} returns \code{x}
invisibly.
}
\description{
Computes token- and/or type-weighted arithmetic means for one or more lexical-
norm variables. Matching is exact: the function neither tokenizes nor
normalizes the supplied terms. Means use observed values from matched keys
only. Resource coverage and annotation coverage are therefore returned
separately and should accompany every interpretation of an estimate.
}
\details{
The three coverage rates have different denominators:
\code{resource_coverage = matched_units / input_units},
\code{value_coverage = observed_value_units / input_units}, and
\code{annotation_coverage = observed_value_units / matched_units}. A matched
key with an \code{NA} norm is \code{missing_annotation}; an unmatched key is
\code{not_applicable_oov}. The function does not infer a universal direction,
compare unlike scales, form composite scores, or approve a data license.
}
\examples{
norms <- data.frame(
  term = c("book", "read", "rare"),
  familiarity = c(6, 5, NA_real_),
  stringsAsFactors = FALSE
)
specs <- data.frame(
  measure_id = "familiarity",
  value_column = "familiarity",
  construct_id = "subjective_familiarity",
  value_unit = "seven_point_rating",
  direction = "higher",
  language = "English",
  variety = "unspecified",
  population_id = "example_adults",
  collection_year = "2025",
  valid_min = 1,
  valid_max = 7,
  stringsAsFactors = FALSE
)
resource <- list(
  resource_id = "example_norms",
  resource_version = "2025-01",
  creator = "Example creator",
  source_reference = "Example citation",
  data_license = "Example terms; verify before redistribution",
  transformation_id = "none",
  lookup_unit = "lowercase_lemma",
  resource_key_normalization_id = "caller-prepared-v1"
)

profile <- lexdiv_norm_profile(
  c("book", "book", "rare", "unknown"),
  norms,
  "term",
  specs,
  resource
)
profile$summary
profile$coverage
profile$lookup
print(profile)
}
