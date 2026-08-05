\name{tubelex_frequency_profile}
\alias{tubelex_frequency_profile}
\title{Coverage-aware TUBELEX frequency and prevalence profile}
\description{
Look up surface-form frequency, video prevalence, and channel prevalence in the
byte-pinned TUBELEX-EN Treebank aggregate bundled with \pkg{ldfreq}.
}
\usage{
tubelex_frequency_profile(terms, normalization = "tubelex")
}
\arguments{
\item{terms}{A plain ordered character vector, or an object returned by
\code{lexdiv_tokenize()}. Order and duplicate tokens are retained. Each vector
element is one complete lookup term; a single string containing whitespace
triggers a warning because it may be raw prose. Pass raw prose through
\code{lexdiv_tokenize()}.}
\item{normalization}{\code{"tubelex"} applies the recorded NFKC, trim, and
locale-fixed English lowercase query transform. \code{"identity"} performs an
exact case- and normalization-sensitive lookup.}
}
\details{
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

The four normalization constants used to form these three denominators are
stored in the \code{formula_parameters} component of \code{provenance}. Video
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
The public profile contract is normative for version 0.1.0. The resource's
license, provenance, and runtime integrity records are installed separately
from the measurement contract.
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
\value{
A \code{tubelex_frequency_profile} list containing \code{status},
\code{failure_reason}, token- and type-weighted \code{summary}, lossless
\code{lookup} rows, \code{coverage}, versioned \code{provenance}, and
\code{diagnostics}.
}
\examples{
tokens <- lexdiv_tokenize("The apple and the missingword.")
profile <- tubelex_frequency_profile(tokens)
profile$summary
profile$coverage
profile$lookup
profile$provenance$formula_parameters

contract_files <- c(
  "tubelex-frequency-profile-contract.json",
  "lexical-resource-lookup-contract.json"
)
contract_paths <- system.file("spec", contract_files, package = "ldfreq")
stopifnot(all(nzchar(contract_paths)))
basename(contract_paths)
}
\seealso{\code{\link{lexdiv_tokenize}}, \code{\link{lexdiv_metrics_text}}}
\keyword{text}
