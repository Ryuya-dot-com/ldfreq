\name{nj8_diagnostics}
\alias{nj8_diagnostics}
\title{Diagnose NJ8 non-matches and lexical-unit transformations}
\description{
Counts unmatched lookup terms and surface-to-unit mappings across an existing
NJ8 profile. Preserves coverage, exclusions and resource/preprocessing
provenance without running tokenization, annotation or lookup again.
}
\usage{nj8_diagnostics(x)}
\arguments{
  \item{x}{An unmodified result of \code{nj8_profile()} or
  \code{nj8_profile_batch()}. A single profile receives the local document ID
  \code{"document_1"}; batch document IDs are preserved.}
}
\value{
A plain list with the following components:
\describe{
  \item{unmatched_terms}{A data frame with \code{lookup_term},
  \code{token_count}, and \code{document_count}. Counts use eligible unmatched
  occurrences and distinct documents containing each exact lookup term.}
  \item{unit_mappings}{A data frame with grouping keys \code{surface_term},
  \code{term}, \code{lookup_term}, \code{matched}; counts \code{token_count},
  \code{document_count}; and logical flags \code{unit_changed},
  \code{lookup_changed}, \code{numeric_introduced}, \code{whitespace_introduced}.}
  \item{coverage}{The original per-document coverage data frame. Single-profile
  coverage is converted to a one-row data frame with \code{document_id} first.
  Empty and wholly excluded documents remain visible here.}
  \item{exclusion_reasons}{The original exclusion counts with \code{document_id}.
  Tokens excluded because of missing annotations do not become unmatched terms.}
  \item{provenance}{The unchanged source profile provenance, including resource
  identity, selected unit, normalization and the resource citation.}
  \item{document_provenance}{Document IDs, input sources, selected units and
  preprocessing references. The batch table is preserved; a corresponding
  one-row table is constructed for a single profile.}
}
The two count tables are sorted by decreasing token count, with ties in first
occurrence order. Counts have type double. Empty tables retain the same columns
and types. Counts are pooled over documents, not averages of document rates.
}
\details{
\code{unit_changed} compares the recorded surface and selected unit exactly.
\code{lookup_changed} compares the selected unit and final lookup key; this
can reflect normalization or a flemma headword-conflict decision.
\code{numeric_introduced} indicates a selected unit consisting entirely of
Unicode Number characters when its surface does not. It does not detect all
numeric expressions such as decimals. \code{whitespace_introduced} indicates
Unicode whitespace in the selected unit when its surface has none. Neither
flag changes, splits, drops or corrects the unit.

These flags describe string transformations, not annotation errors. Unmatched
terms may include inflected forms, contractions, proper names, compounds,
spelling variants, errors, or words absent from the reference; the function
does not classify them as difficult or infer proficiency. With preselected
character-vector inputs, the original surface-to-lemma mapping is unavailable:
the supplied units occupy both fields, so unchanged flags do not validate an
upstream annotation process. Retain \code{x$lookup} for token positions and
document IDs, and original tokenization objects for excluded-token details.

No resource or model is loaded, downloaded or modified. Basic input structure
and token-count consistency are checked; this is not a cryptographic integrity
check of a saved profile. The result is an audit summary, not a replacement
for the full profile or a standalone analysis of all annotation failures.
}
\examples{
prepared <- lexdiv_tokenize_batch(c(
  essay_a = "Students have part-time jobs.",
  essay_b = "Students learn from jobs."
), tokenizer = "english", case = "lower")
profile <- nj8_profile_batch(prepared, unit = "surface")
audit <- nj8_diagnostics(profile)
audit$unmatched_terms
audit$coverage

# Authored annotation example: flags record a change, not its correctness.
text <- lexdiv_tokenize("Students second", case = "lower")
annotated <- lexdiv_lemmatize(text, lemmas = c("student", "2"),
  backend_id = "authored-example", backend_version = "1")
audit <- nj8_diagnostics(nj8_profile(annotated, unit = "lemma"))
audit$unit_mappings[audit$unit_mappings$numeric_introduced, ]
}
\seealso{\code{\link{nj8_profile}}, \code{\link{lexdiv_preprocessing}}}
