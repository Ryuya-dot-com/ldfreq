\name{tubelex_profile}
\alias{tubelex_profile}
\alias{tubelex_profile_batch}
\alias{print.tubelex_profile}
\title{Coverage-aware TUBELEX frequency and prevalence profile}
\description{
Look up surface-form frequency, video prevalence, and channel prevalence in the
byte-pinned TUBELEX-EN Treebank aggregate bundled with \pkg{ldfreq}.
}
\usage{
tubelex_profile(
  terms, normalization = "tubelex", tokenization_mismatch = "error"
)

tubelex_profile_batch(
  documents, normalization = "tubelex", tokenization_mismatch = "error",
  id_col = "document_id", terms_col = "terms", max_rows = 1e6
)

\method{print}{tubelex_profile}(x, ...)
}
\arguments{
\item{terms}{A plain ordered character vector, or an object returned by
\code{lexdiv_tokenize()} only with explicit mismatch opt-in. Order and duplicate tokens are retained. Each vector
element is one complete lookup term; a single string containing whitespace
triggers a warning because it may be raw prose. For text-frequency analysis,
prepare tokens using the resource's Penn Treebank segmentation and record the
external tokenizer and version. Character vectors are caller assertions;
their segmentation is not verified by the package.}
\item{normalization}{\code{"tubelex"} applies the recorded NFKC, trim, and
locale-fixed English lowercase query transform. \code{"identity"} performs an
exact case- and normalization-sensitive lookup. The explicit
\code{"tubelex_apostrophe"} option additionally maps right single quotation
marks and primes to ASCII apostrophes internally or at clitic starts. This
term-level typography transform does not split contractions or establish
Treebank compatibility. The default transform is unchanged.}
\item{tokenization_mismatch}{\code{"error"} rejects objects from
\code{lexdiv_tokenize()}, whose word segmentation differs from Treebank.
\code{"allow"} explicitly permits them for sensitivity analysis and records
the mismatch. This option does not verify character-vector input.}
\item{documents}{An explicitly named list of document term vectors or
tokenization objects, or a data frame with distinct IDs and a terms list-column.
Invalid term vectors receive document-local invalid profiles; structural
errors and known tokenizer mismatches stop the batch.}
\item{id_col, terms_col}{ID and term list-column names for data-frame input.}
\item{max_rows}{Positive whole-number bound on combined lookup and summary
rows, checked before resource loading.}
\item{x}{A \code{tubelex_profile} object.}
\item{...}{Additional arguments passed to the summary-table print method.}
}
\details{
The general-purpose \code{lexdiv_tokenize()} tokenizer retains contractions
such as \samp{don't}, whereas the bundled resource uses Treebank units such
as \samp{do} and \samp{n't}. A spelling can match a resource entry even when
segmentation is inappropriate: 100 percent coverage does not verify alignment.
Do not extract the surface column merely to bypass the object mismatch check.
An explicitly allowed mismatch measures sensitivity to a different segmentation;
it is not a recommended automatic frequency-analysis pipeline.

Unmatched terms remain missing. They are not converted to zero counts or to a
maximum-sophistication category. Summary means are therefore conditional on
matched terms and must be interpreted beside token and type coverage.

The token-weighted row retains repetition in the input. The type-weighted row
uses each distinct normalized lookup term once. The output records both the
original and normalized type counts so that normalization-induced collisions
remain visible.

TUBELEX is a general YouTube subtitle frequency space. Its values are relative
to that corpus and are not direct measures of proficiency, writing quality,
academic register, or context-independent lexical sophistication.
}
\section{Reading lookup and summary values}{
The lossless \code{lookup} table contains:
\describe{
  \item{\code{term}, \code{lookup_term}}{The caller's original term and its
  effective normalized query.}
  \item{\code{matched}, \code{resource_word}}{Whether the query matched and
  the exact resource key used.}
  \item{\code{count}}{Raw token occurrences in the pinned TUBELEX aggregate.}
  \item{\code{videos}, \code{channels}}{Numbers of source videos and channels
  containing the matched resource entry.}
  \item{\code{zipf}}{Smoothed per-billion token frequency. It is the base-10
  logarithm of \code{1e9 * (count + 1) / D}, where \code{D} equals
  \code{token_total + source_vocabulary_size}.}
  \item{\code{video_prevalence}}{Smoothed log video proportion. It is
  \code{log10((videos + 1) / Dv)}, where \code{Dv} equals
  \code{video_total + 2}.}
  \item{\code{channel_prevalence}}{Smoothed log channel proportion. It is
  \code{log10((channels + 1) / Dc)}, where \code{Dc} equals
  \code{channel_total + 2}.}
}

The \code{formula_parameters} component of \code{provenance} stores the four
normalization constants used to form these three denominators. Video
and channel prevalence values are normally non-positive because they are
base-10 logarithms of smoothed proportions no greater than one; a value closer
to zero denotes wider prevalence. The \code{summary} means and Zipf standard
deviation use matched rows only. Read them beside \code{eligible_items},
\code{matched_items}, and \code{coverage}; token weighting retains repetition,
whereas type weighting keeps the first occurrence of each distinct normalized
lookup term.
}
\section{Formal contracts}{
The public profile contract is installed as
\file{tubelex-frequency-profile-contract.json}; exact lookup formulas and
field roles are installed as \file{lexical-resource-lookup-contract.json}.
Locate either with \code{system.file("spec", filename, package = "ldfreq")}.
The public profile contract is normative for version 0.2.0. The lookup file
is the versioned, non-exported implementation contract at contract version
\code{0.1.0}; its installation does not make the lookup helper a supported exported
API. The
resource's license, provenance, and runtime integrity records are installed
separately from the measurement contract.
}
\section{Reading status}{
\code{status = "ok"} means a non-empty valid input was looked up successfully;
\code{"empty"} means a valid zero-term input produced typed empty output;
\code{"invalid_input"} means the supplied terms failed validation; and
\code{"resource_error"} means the bundled resource failed an availability or
integrity check. \code{failure_reason} is missing for \code{"ok"} and
\code{"empty"}, and otherwise gives the specific failure reason. Coverage is
missing when its denominator is zero or the lookup could not be completed.
}
\references{
Nohejl et al. (2025). Beyond Film Subtitles: Is YouTube the Best Approximation
of Spoken Vocabulary? \emph{Proceedings of COLING 2025}.
\url{https://aclanthology.org/2025.coling-main.641/}.
}
\value{
A \code{tubelex_profile} list containing \code{status},
\code{failure_reason}, token- and type-weighted \code{summary}, lossless
\code{lookup} rows, \code{coverage}, versioned \code{provenance}, and
\code{diagnostics}.
The print method returns \code{x} invisibly.

\code{tubelex_profile_batch()} returns an input-ordered named list of complete
\code{tubelex_profile} objects, including every document's coverage and
provenance. It loads one immutable resource snapshot per batch, has no global
cache, and gives the same per-document values as separate calls. Access, for
example, \code{profiles[["essay_a"]]$summary}; do not concatenate documents to
avoid repeated resource loading. An empty batch returns a named empty list.
}
\examples{
# Explicit illustrative Treebank units; no automatic tokenization is implied.
tokens <- c("I", "do", "n't", "think", "it", "'s", "John", "'s", "book")
profile <- tubelex_profile(tokens)
profile$summary
profile$coverage
profile$lookup
profile$provenance$formula_parameters

profiles <- tubelex_profile_batch(list(essay_a = tokens, essay_b = c("the", "book")))
profiles$essay_a$summary

# Typography alone can be normalized explicitly after token preparation.
tubelex_profile(c("it", "\u2019s"), normalization = "tubelex_apostrophe")$lookup

contract_files <- c(
  "tubelex-frequency-profile-contract.json",
  "lexical-resource-lookup-contract.json"
)
contract_paths <- system.file("spec", contract_files, package = "ldfreq")
stopifnot(all(nzchar(contract_paths)))
basename(contract_paths)
}
\seealso{
\code{\link{lexdiv_tokenize}}, \code{\link{lexdiv_metrics_text}};
\code{vignette("tubelex-input", package = "ldfreq")} for the optional
external tokenization recipe and its reproducibility boundaries.
}
\keyword{text}
