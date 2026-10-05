\name{tubelex_diagnostics}
\alias{tubelex_diagnostics}
\title{Tabulate TUBELEX profiles while retaining coverage and input conditions}
\description{
Combine existing profiles into document and summary tables, count confirmed
unmatched terms, and inspect term normalization. No resource lookup,
tokenization, annotation, model download, or learner scoring is performed.
}
\usage{
tubelex_diagnostics(x, max_rows = 1e6)
}
\arguments{
\item{x}{One unmodified \code{tubelex_profile()} result, or a plain named list
as returned by \code{tubelex_profile_batch()}. IDs must be unique, non-empty
valid-UTF-8 strings. A single profile uses \code{document_1}. An empty named
list is allowed. Profiles must use profile contract 0.2.0 and the currently
bundled resource; unsupported records must be recreated from their inputs.}
\item{max_rows}{Positive whole-number limit on total input lookup rows plus
two summary rows per document, checked before constructing aggregate tables.}
}
\details{
Input order and empty or failed documents are retained. Summary values are
copied after checking their consistency with lookup and coverage. Missing
results are not replaced by zero. A resource failure leaves match status
unresolved (\code{NA}); these terms are not counted as confirmed unmatched.
Validation checks structure and consistency, not authenticity of saved profiles.

\code{condition_id} labels groups of identical recorded resource, query
normalization, input source, alignment declaration, and (where available)
tokenizer and text-preparation settings, in first-seen order. Unmatched and
mapping counts are computed separately within these groups. IDs are local to
each diagnostic call, not persistent analysis identifiers. Matching settings
for character vectors remain unverified; a group is not evidence that the
vectors used the same tokenizer or that their segmentation matches TUBELEX.
Keep externally recorded tokenization metadata with the full profiles.

\code{token_count} is the number of occurrences; \code{document_count} is the
number of distinct input IDs containing the row's key. Counts are ordered by
decreasing occurrence count, with ties in input encounter order. The tables
retain text-derived strings; they are not anonymized corpus summaries.

TUBELEX describes reference-corpus frequency and distribution across videos
and channels. These are properties of word forms, not observations that a
particular learner recognizes, recalls, or can use a word. Reading-related
lexical employability needs learner evidence and an appropriate criterion;
it is not inferred from high coverage, mean Zipf frequency or channel prevalence.
}
\value{
A plain list containing:
\describe{
\item{\code{summary}}{Two rows per document, preserving token/type weighting,
matched-only frequency and prevalence statistics, denominators and coverage.
Adds \code{document_id}, \code{condition_id}, \code{status}, and
\code{failure_reason}.}
\item{\code{documents}}{One row per document with status, all original coverage
fields, resource version, query normalization and input alignment settings.
Tokenizer fields are missing for character-vector inputs. Settings columns,
including \code{keep_numbers}, are character labels.}
\item{\code{unmatched_terms}}{Counts by \code{condition_id} and
\code{lookup_term}, including only confirmed non-matches.}
\item{\code{normalization_mappings}}{Counts by \code{condition_id}, original
\code{term}, \code{lookup_term}, and logical \code{matched} (possibly missing).
\code{lookup_changed} flags unequal original/query strings;
\code{number_marker} identifies the exact query \code{<num>}.
Neither flag is an annotation error or a difficulty classification.}
\item{\code{provenance}, \code{diagnostics}}{Named lists retaining each
profile's complete records, including failure details and preprocessing.}
}
Empty batches return typed zero-row tables and empty named metadata lists.
Keep the original profiles for occurrence positions and complete lookup values.
}
\examples{
profiles <- tubelex_profile_batch(list(
  first = c("Apple", "apple", "zzunmatchedxyz"),
  second = c("the", "zzunmatchedxyz"), blank = character(),
  invalid = c("the", NA_character_)
))
audit <- tubelex_diagnostics(profiles)
audit$summary[, c("document_id", "status", "weighting", "coverage", "mean_zipf")]
audit$unmatched_terms
audit$normalization_mappings
}
\seealso{
\code{\link{tubelex_profile}}, \code{\link{nj8_diagnostics}};
\code{vignette("vocabulary-knowledge-and-use", package = "ldfreq")} for a
worked separation of learner responses and corpus features.
}
\keyword{text}
