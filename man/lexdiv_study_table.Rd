\name{lexdiv_study_table}
\alias{lexdiv_study_table}
\alias{lexdiv_study_model_data}
\alias{print.lexdiv_study_model_data}
\title{Join Planned Observations to Saved Measurements and Select Model Rows}
\description{
Preserve planned observations, submitted documents and measurement identities
in an ordinary research table, and select one response specification with an
explicit exclusion audit for statistical modelling.
}
\usage{
lexdiv_study_table(
  planned,
  submissions,
  results,
  plan,
  condition_id,
  reporting = NULL,
  max_rows = 1e6
)

lexdiv_study_model_data(
  study,
  condition_id,
  request_id,
  required = c("writer_id", "task", "occasion")
)

\method{print}{lexdiv_study_model_data}(x, ...)
}
\arguments{
\item{planned}{Data frame or tibble with unique nonblank character
\code{observation_id}, plus \code{writer_id}, \code{task} and \code{occasion}.}
\item{submissions}{Data frame or tibble with \code{observation_id} and
\code{document_id}, plus \code{input_characters} (automatically populated from
preprocessing provenance if omitted when \code{results} is a
\code{lexdiv_text_batch_results} object).}
\item{results}{Complete result of \code{lexdiv_metrics_batch(documents, plan = plan)}
or \code{lexdiv_metrics_text_batch(documents, plan = plan)}.}
\item{plan}{The explicit \code{\link{lexdiv_plan}} used for \code{results}.}
\item{condition_id}{Nonblank character label for the selected analysis condition.}
\item{reporting}{Optional data frame/tibble with \code{document_id},
\code{request_id}, \code{reporting_status}, and \code{reporting_reason}.}
\item{max_rows}{Positive whole-number row limit.}
\item{study}{Complete study table returned by \code{lexdiv_study_table()}.}
\item{request_id}{One request ID in the saved plan.}
\item{required}{Metadata column names required to be complete for model rows.}
\item{x}{A \code{lexdiv_study_model_data} object.}
\item{...}{Additional arguments passed to \code{print.data.frame()}.}
}
\value{
\code{lexdiv_study_table()} returns a data frame joining planned metadata,
submission/input/computation/reporting states, and measurement columns.
\code{lexdiv_study_model_data()} returns a \code{lexdiv_study_model_data}
object with \code{data} and \code{audit}. \code{print()} displays up to 12
selected model rows and returns \code{x} invisibly.
}
\examples{
plan <- lexdiv_plan(presets = character(), specs = list(
  lexdiv_spec("ttr", request_id = "ttr")
))
planned <- data.frame(
  observation_id = c("o1", "o2"),
  writer_id = c("001", "002"),
  task = "essay",
  occasion = 1
)
submissions <- data.frame(observation_id = "o1", document_id = "d1")
results <- lexdiv_metrics_text_batch(c(d1 = "Cats chase cats."), plan = plan)
reporting <- data.frame(
  document_id = "d1", request_id = "ttr",
  reporting_status = "report", reporting_reason = "Planned specification"
)
study <- lexdiv_study_table(
  planned, submissions, results, plan, "surface-all", reporting
)
selected <- lexdiv_study_model_data(study, "surface-all", "ttr")
selected
}
\seealso{\code{\link{lexdiv_metrics_text_batch}}, \code{\link{lexdiv_plan}}}
