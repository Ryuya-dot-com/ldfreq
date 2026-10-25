\name{lexdiv_study_table}
\alias{lexdiv_study_table}
\alias{lexdiv_study_model_data}
\title{Join planned observations to saved measurements and select model rows}
\description{
Preserve planned observations, submitted documents and measurement identities
in an ordinary research table. Select one response specification with a separate
exclusion audit for an existing modelling package. These functions do not fit
or choose models, impute missing observations, or recalculate submitted results.
}
\usage{
lexdiv_study_table(planned, submissions, results, plan, condition_id,
                  reporting = NULL, max_rows = 1e6)
lexdiv_study_model_data(study, condition_id, request_id,
                       required = c("writer_id", "task", "occasion"))
}
\arguments{
\item{planned}{Data frame with unique nonblank character \code{observation_id},
\code{writer_id}, \code{task} and \code{occasion}. Writer/task labels may be
character or factors and may be missing. Extra atomic columns, including dates
and factors, are retained. Supply actual planned rows; no Cartesian design is
inferred. Column names must not collide with result/output fields.}
\item{submissions}{Data frame with exactly \code{observation_id},
\code{document_id} and \code{input_characters}. IDs are unique nonblank character
strings. Each submitted document belongs to one known observation, with at most
one document per observation. Character counts are nonnegative whole numbers or
\code{NA} when unknown.}
\item{results}{Complete, unchanged result of
\code{\link{lexdiv_metrics_batch}(documents, plan = plan)}, including exactly
one row for each submitted document and requested specification.}
\item{plan}{The explicit \code{\link{lexdiv_plan}} used for \code{results}.}
\item{condition_id}{One nonblank character label for the selected analysis
condition. It is a caller declaration, not proof of preprocessing equivalence.}
\item{reporting}{Optional data frame with exactly \code{document_id},
\code{request_id}, \code{reporting_status} and \code{reporting_reason}, covering
every submitted document/request pair. Status is \code{"report"} or
\code{"withhold"}; each decision needs a nonblank reason. \code{NULL} leaves all
rows \code{"not_screened"}, so none enter model data yet.}
\item{max_rows}{Positive whole-number limit on planned observations times
requested specifications, checked before constructing the table.}
\item{study}{The complete study table, optionally with multiple explicitly
labelled conditions. Measurement values must be plain numeric vectors.
Observation, document, condition, request, specification, method and plan IDs,
and status columns, must be character vectors, not factors or matrices.}
\item{request_id}{One request in the saved plan. A model selection must contain
one method, specification and plan identity and one row per observation.}
\item{required}{Unique existing metadata column names required for model rows.
Required columns must contain one atomic value per row; factors and dates are
retained, while matrices and nested tables are rejected. Missing, blank or
non-finite values (including non-finite dates) exclude the row and remain in the audit.}
}
\details{
Unsubmitted observations, empty submitted texts, no selected tokens, unavailable
scores, reporting decisions and missing metadata remain distinct. Missing values
are never converted to zero. The table follows planned-row order, then plan
request order. Empty tokens are passed to the public plan executor only to
validate the plan and obtain request metadata; submitted values are not recomputed.

The model-selection audit reserves \code{not_submitted}, \code{not_computable},
\code{not_reportable}, \code{missing_metadata} and \code{included}. Both functions
reject input metadata with these names so that a column cannot mean an external
decision in the data and a computed decision in the audit. Rename such metadata
explicitly, for example to \code{source_included}; its values are preserved and
do not automatically control model selection.

When selecting model rows, submission status must be \code{"submitted"} or
\code{"not_submitted"}; computation status must be \code{"ok"}, \code{"missing"}
or \code{"not_submitted"}; reporting status must be \code{"report"},
\code{"withhold"} or \code{"not_screened"}. Unknown labels are errors, not
exclusion decisions. Unsubmitted rows have missing document IDs and values;
computed values are finite, and unavailable values are missing. Inconsistent
records are rejected. These checks do not authenticate or recalculate saved scores.

Model rows require submitted, computable, explicitly reportable values and
complete required metadata. The output is not evidence of an ignorable missing
data mechanism, model identifiability or a causal interpretation. Select and
justify a model using the research design. Keep original texts, preprocessing
inputs, plan, reporting decisions and the complete table in the study record.

Introduced as public interfaces in 0.4.0.9006 with the computations and table
layout of the previous installed example. Sourcing \code{examples/study-table.R}
still defines \code{study_long_table()} and \code{study_model_data()} with the
same arguments and return values. See \href{https://ryuya-dot-com.github.io/ldfreq/articles/repeated-observations.html}{repeated observations guide}.

For raw text, start with \code{\link{lexdiv_tokenize_batch}}, retain the
preparation records, and extract the selected token vectors as shown in its
help. Compute them with the explicit plan before constructing this table.
After selection, supply \code{selected$data} to the chosen modelling function
and retain \code{selected$audit} to account for the original observations.
}
\value{
\code{lexdiv_study_table()} returns a plain data frame with planned metadata,
measurement fields and \code{condition_id}, \code{submission_status},
\code{input_status}, \code{input_characters}, \code{computation_status},
\code{reporting_status} and \code{reporting_reason}.

\code{lexdiv_study_model_data()} returns a list with \code{data}, the selected
ordinary data frame whose row names are observation IDs, and \code{audit}, one
row per selected-condition/request observation. Audit columns retain IDs,
\code{not_submitted}, \code{not_computable}, \code{not_reportable},
\code{missing_metadata} and \code{included}; several exclusion reasons may coexist.
}
\examples{
plan <- lexdiv_plan(presets = character(), specs = list(
  lexdiv_spec("ttr_v_over_n_v1", request_id = "ttr")))
planned <- data.frame(observation_id = c("o1", "o2"),
  writer_id = c("001", "002"), task = "essay", occasion = 1)
submissions <- data.frame(observation_id = "o1", document_id = "d1",
  input_characters = 5)
results <- lexdiv_metrics_batch(list(d1 = c("a", "b", "a")), plan = plan)
reporting <- data.frame(document_id = "d1", request_id = "ttr",
  reporting_status = "report", reporting_reason = "Planned specification")
study <- lexdiv_study_table(planned, submissions, results, plan,
  "surface-all", reporting)
selected <- lexdiv_study_model_data(study, "surface-all", "ttr")
selected$audit
}
