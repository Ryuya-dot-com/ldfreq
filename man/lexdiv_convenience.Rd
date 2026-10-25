\name{lexdiv_convenience}
\alias{lexdiv_convenience}
\title{Prepare and display lexical-diversity results}
\description{
Choose the operation you need:
\describe{
\item{Prepare token input}{\code{\link{lexdiv_as_documents}} converts token
containers to named documents without tokenizing raw prose.}
\item{Make a wide table}{\code{\link{lexdiv_widen}} retains selected values,
statuses and measurement conditions without recomputing scores.}
\item{Draw results}{\code{\link{plot.lexdiv_results}} selects one metric or
length screen, or draws TUBELEX coverage.}
}
These operations preserve the original result. Save the complete result as
RDS when retaining all diagnostics and provenance matters.
}
\seealso{\code{\link{lexdiv_metrics}}, \code{\link{lexdiv_study_table}}.}
