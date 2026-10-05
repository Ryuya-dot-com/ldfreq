\name{lexdiv_compare_responses}
\alias{lexdiv_compare_responses}
\title{Compare paired binary vocabulary responses with an explicit criterion}
\usage{
lexdiv_compare_responses(data, test, criterion,
  keys = c("learner_id", "item_id"), by = character())
}
\arguments{
\item{data}{A data frame, one row per paired observation. All original columns
are retained, including sense/context IDs, rubric versions, raters, task order,
missingness reasons and corpus features when supplied.}
\item{test,criterion}{Names of two distinct columns containing numeric or
logical 0 (incorrect), 1 (correct), or \code{NA} (missing). Factors, character
scores, partial credit, infinities and \code{NaN} are rejected. The caller must
score and pair responses under explicit criteria before calling this function.}
\item{keys}{Non-empty character vector naming columns that jointly identify
each pair. Values must be non-blank UTF-8 character strings or factors, without
missing values. Add occasion, task or format IDs for repeated observations.
Keys establish row identity, not statistical independence.}
\item{by}{Distinct categorical column names to tabulate separately, or
\code{character()} for one pooled table. Values must be non-blank UTF-8
character strings or factors. Missing group labels are retained as an
\code{NA} stratum. Grouping is explicit: include relevant formats, occasions,
groups or rubric versions; these are not detected automatically.}
}
\description{
Checks pair identity and binary scores, preserves missing responses, and
tabulates agreement and directional disagreement with visible denominators.
This is a descriptive response comparison, not an employability scale,
automatic response scorer, or validation of the chosen criterion.
}
\value{
A plain list with four components:
\describe{
\item{responses}{Original rows and columns in input order, plus character
\code{comparison_outcome}. The input is not modified.}
\item{counts}{Grouping columns followed by \code{outcome} and integer
\code{n}. Every observed group has all seven outcomes, including zero counts:
\code{both_correct}, \code{test_only}, \code{criterion_only},
\code{both_incorrect}, \code{missing_test}, \code{missing_criterion}, and
\code{missing_both}. The first two missing categories mean exactly one score
is missing. Unused factor levels do not create groups.}
\item{summary}{Grouping columns followed by \code{quantity}, \code{numerator},
\code{denominator}, and \code{proportion}. Five rows per observed group:
agreement, test-only and criterion-only proportions among complete pairs;
criterion failure among test-correct complete pairs; and the complete-pair
fraction among all supplied pairs. Zero denominators give \code{NA}.}
\item{provenance}{\code{comparison_version}, selected \code{test},
\code{criterion}, \code{keys}, \code{by}, and \code{missing_policy}.
This records the comparison specification, not an independent scoring audit.}
}
Groups follow first occurrence. Empty ungrouped input returns seven zero counts
and five undefined proportions; empty grouped input returns zero-row tables.
Duplicate column names and output-name collisions are rejected.
}
\details{
Use unique item IDs for different target senses or contexts even when the
surface form is identical. Joining on the surface form can duplicate response
rows. Repeated observations need additional key columns; grouping alone does
not resolve duplicate keys. A missing administration must be represented by
an explicit row with \code{NA} score(s) if it belongs in the supplied-pair
denominator. The function cannot detect unrecorded scheduled observations.

The criterion is a caller-selected measurement and need not be error-free.
Each supplied pair contributes once; pooled proportions are not averages of
learner-level proportions when learners contribute different numbers of pairs.
Meaning recall can address a prerequisite of reading; it does not establish
fluent contextual comprehension or productive use. TUBELEX values describe
forms in a reference corpus and are not response scores or learner abilities.
Save the item dictionary, complete resource profiles, scoring rubric/version
and response records alongside this result.

Missing scores are never converted to incorrect responses. An unanswered item
may count as incorrect only if a prespecified scoring policy justifies it;
preserve the original response and missingness reason separately. Partial
credit is not silently dichotomized. Observed complete-pair proportions can
be biased by informative missingness. An absent essay word is not an incorrect
elicited response. No confidence intervals or tests are calculated because
repeated learners/items and sampling require an explicit inferential design.
}
\examples{
# Authored demonstration, not learner observations.
responses <- data.frame(learner_id = rep("example", 5),
  item_id = paste0("i", 1:5), recognition = c(1, 1, 0, 0, NA),
  recall = c(1, 0, 1, 0, 0))
comparison <- lexdiv_compare_responses(responses,
  test = "recognition", criterion = "recall")
comparison$counts
comparison$summary

repeated <- rbind(transform(responses, occasion_id = "pre"),
  transform(responses, occasion_id = "post"))
lexdiv_compare_responses(repeated, "recognition", "recall",
  keys = c("learner_id", "item_id", "occasion_id"),
  by = "occasion_id")$summary
}
\references{
Kremmel, B. and Schmitt, N. (2016). Interpreting vocabulary test scores: What
do various item formats tell us about learners' ability to employ words?
Language Assessment Quarterly, 13(4), 377--392.
\doi{10.1080/15434303.2016.1237516}.
}
\seealso{\code{\link{tubelex_profile}}, \code{\link{tubelex_diagnostics}}}
\keyword{utilities}
