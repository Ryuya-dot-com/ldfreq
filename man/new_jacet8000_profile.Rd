\name{new_jacet8000_profile}
\alias{new_jacet8000_profile}
\alias{new_jacet8000_profile_batch}
\alias{print.lexical_level_profile}
\alias{print.new_jacet8000_profile_batch}
\alias{plot.lexical_level_profile}
\title{Profile lexical coverage by New JACET 8000 frequency level}
\description{
Creates exact and cumulative token- and type-weighted lexical profiles from a
caller-supplied copy of New JACET 8000. The word list is required at call time
and is never bundled or downloaded by \pkg{ldfreq}.
}
\usage{
new_jacet8000_profile(
  terms,
  wordlist,
  rank_column = NULL,
  word_column = NULL,
  sheet = "\\u65b0J8",
  unit = "lemma",
  flemma_conflict = "antbnc",
  normalization = "nfkc_lower",
  expand_parenthetical = TRUE,
  resource_version = NULL
)

new_jacet8000_profile_batch(
  documents,
  wordlist,
  rank_column = NULL,
  word_column = NULL,
  sheet = "\\u65b0J8",
  unit = "lemma",
  flemma_conflict = "antbnc",
  normalization = "nfkc_lower",
  expand_parenthetical = TRUE,
  resource_version = NULL,
  id_col = "document_id",
  terms_col = "terms",
  max_rows = 1e+06
)

\method{print}{lexical_level_profile}(x, ...)

\method{print}{new_jacet8000_profile_batch}(x, ...)

\method{plot}{lexical_level_profile}(
  x,
  weighting = "token",
  scale = "proportion",
  show_cumulative = TRUE,
  include_off_list = TRUE,
  bar_col = "#4C78A8",
  cumulative_col = "#E45756",
  main = NULL,
  xlab = "New JACET 8000 frequency level",
  ylab = NULL,
  show_legend = TRUE,
  ...
)
}
\arguments{
  \item{terms}{A plain character vector of ordered lexical units, or an object
  returned by \code{lexdiv_tokenize()}.}
  \item{documents}{A plain named list of character vectors or tokenization
  objects, or a data frame containing an explicit ID column and a list-column
  of those inputs.}
  \item{wordlist}{A data frame containing New JACET 8000 ranks and entries, or
  a path to the official local XLSX file or a local CSV file. Direct XLSX input
  requires the suggested \pkg{readxl} package.}
  \item{rank_column, word_column}{Optional names of the rank and entry columns.
  \code{NULL} detects the official XLSX headers
  \code{"\\u65b0J8\\u9806\\u4f4d"} and
  \code{"\\u4ee3\\u8868\\u30ec\\u30de"}, or compatible CSV headers \code{"NJ8"} and
  \code{"Word"}.}
  \item{sheet}{XLSX sheet containing the list. The official workbook uses
  \code{"\\u65b0J8"}. Ignored for data-frame and CSV input.}
  \item{unit}{One of \code{"lemma"} (the default because the official table
  contains representative lemmas), \code{"surface"}, or \code{"flemma"}.
  For a plain character vector, this labels the units already selected by the
  caller.}
  \item{flemma_conflict}{For a flemma-annotated tokenization, how to resolve a
  surface form that is itself a New JACET headword but maps to another flemma:
  retain the \code{"antbnc"} mapping, prefer the \code{"wordlist"} headword,
  or raise an \code{"error"}.}
  \item{normalization}{\code{"nfkc_lower"} applies NFKC, trimming, and
  locale-fixed English lowercasing to both queries and entries.
  \code{"identity"} performs an exact lookup.}
  \item{expand_parenthetical}{Whether a terminal parenthetical list such as
  \code{"mom (mum, mummy)"} contributes comma-separated aliases at the same
  rank.}
  \item{resource_version}{An optional caller-supplied version label. If
  \code{NULL}, the canonical rank-entry SHA-256 supplies the identity.}
  \item{id_col, terms_col}{Names of the explicit document-ID and lexical-input
  list-columns for data-frame batch input.}
  \item{max_rows}{A positive integer bounding the combined number of returned
  batch summary and token-lookup rows. The default is 1,000,000.}
  \item{x}{A result returned by \code{new_jacet8000_profile()}.}
  \item{weighting}{Either token- or type-weighted output. Types are unique
  normalized lookup terms.}
  \item{scale}{Plot proportions or counts.}
  \item{show_cumulative}{Whether to overlay the cumulative profile through
  Level 8.}
  \item{include_off_list}{Whether to include the separate off-list bar.}
  \item{bar_col, cumulative_col}{Colors for the bars and cumulative curve.}
  \item{main, xlab, ylab}{Optional base-graphics labels.}
  \item{show_legend}{Whether to draw the exact/cumulative legend.}
  \item{...}{For \code{plot()}, additional arguments passed to
  \code{graphics::barplot()}; for \code{print()}, additional arguments passed
  to the summary-table print method.}
}
\details{
Ranks 1--8000 are assigned to eight 1,000-rank levels using
\code{ceiling(rank / 1000)}. The official XLSX labels its entries as
representative lemmas, so lemma input is the default. Surface-form matching is
an explicit sensitivity choice and will generally underestimate coverage when
inflected forms have not been lemmatized.

If normalization produces the same entry more than once, the lowest rank wins
and the collision count is reported. Missing ranks are diagnostic rather than
silently invented. For lemma input, tokens without lemmas are excluded before
lookup and their selection coverage is reported separately.

Raw AntBNC and New JACET have non-trivial headword conflicts. For example, a
surface form may be an independent New JACET entry while AntBNC groups it under
another family lemma. With \code{unit = "flemma"}, each such token is marked in
\code{lookup}; the selected conflict policy and the alternative surface-form
rank/level are retained. Explicit form-to-flemma overrides can be supplied to
\code{lexdiv_flemmatize()} before profiling.

The batch function preserves input document order and accepts the same lexical
unit and conflict policies as the single-document function. It reads,
validates, normalizes, and hashes the caller-supplied word list once for the
whole batch. It performs no document-ID inference and no recycling. Its
\code{max_rows} guard is checked before the external resource is processed.
}
\section{Reading the summary}{
The \code{summary} component contains nine rows for each weighting: Levels
1--8 followed by Off-list.

\describe{
  \item{\code{items}}{Occurrences for token weighting or unique normalized
  lookup terms for type weighting.}
  \item{\code{proportion}}{The exact level count divided by all eligible items,
  including off-list items in the denominator.}
  \item{\code{cumulative_items}}{The count at the current level or any more
  frequent level. It is missing for the Off-list row.}
  \item{\code{cumulative_proportion}}{The cumulative count divided by all
  eligible items. Its Level 8 value equals the corresponding token or type
  coverage. It is missing for the Off-list row.}
}
}
\section{Coverage denominators}{
\code{selection_coverage} describes preprocessing completeness: for example,
how many token rows had a usable lemma. \code{token_coverage} and
\code{type_coverage} then describe how many eligible units matched the supplied
list. These rates answer different questions and should be reported separately.
Type-weighted off-list rates are particularly sensitive to whether inflected
forms, spelling variants, and learner errors remain separate surface types or
are collapsed by a lemma/flemma backend. Token and type profiles are not
interchangeable versions of one score.
}
\section{Plot}{
The plot method draws exact level counts or proportions as bars and overlays
the Level 1--8 cumulative series by default. Off-list is a separate grey bar
and is never appended to the cumulative curve. The method invisibly returns
the exact data plotted, allowing the same values to be used with another
graphics system.
}
\section{Resource identity and path privacy}{
The complete list is neither bundled nor copied into the result. For a local
file, provenance retains only its basename, exact file SHA-256, and a canonical
rank-entry SHA-256. The absolute directory is not stored, printed, or repeated
in package-generated error messages. A data-frame input has a canonical hash
but no file hash.

The official workbook permits personal research use with citation and directs
commercial users to consult JACET in advance. Public download availability is
not treated as permission for \pkg{ldfreq} to redistribute the list. Users
remain responsible for obtaining and using their copy under applicable terms.
}
\section{Batch output}{
\code{new_jacet8000_profile_batch()} returns document-major \code{summary} and
\code{lookup} tables with an explicit \code{document_id}. Its \code{coverage}
and \code{document_diagnostics} components contain one row per input document;
\code{exclusion_reasons} retains non-empty preprocessing exclusions;
\code{document_provenance} stores each input's preprocessing reference as a
list-column. Shared resource identity and validation diagnostics are stored
once in \code{provenance} and \code{resource_diagnostics}. An empty container
returns typed zero-row tables and status \code{"empty"}; a named empty document
still contributes its ordinary 18 summary rows.
}
\section{Formal contract}{
The exact denominator, normalization, alias, flemma-conflict, batch, plot, and
resource-boundary rules are installed in
\file{lexical-level-profile-contract.json}. Locate it with
\code{system.file("spec", "lexical-level-profile-contract.json", package =
"ldfreq")}. The contract records that the resource is caller supplied and not
release-approved for redistribution by this package.
}
\value{
\code{new_jacet8000_profile()} returns a list of class
\code{new_jacet8000_profile} and \code{lexical_level_profile}:
\describe{
  \item{\code{status}}{\code{"ok"} or \code{"empty"}.}
  \item{\code{summary}}{Exact and cumulative token/type level rows.}
  \item{\code{lookup}}{One lossless query row per eligible unit, including its
  surface and selected terms, match rule, normalized effective lookup term,
  headword-conflict state and resolution, alternative surface rank/level,
  match state, rank, and level.}
  \item{\code{coverage}}{Selection, matched, and off-list token/type counts and
  rates.}
  \item{\code{provenance}}{Contract, resource hash, lexical-unit,
  normalization, and denominator identity.}
  \item{\code{diagnostics}}{Resolved columns, rank completeness, alias and
  collision counts, and preprocessing exclusions.}
}
The plot method invisibly returns the summary rows and exact values drawn.

\code{new_jacet8000_profile_batch()} returns a list of class
\code{new_jacet8000_profile_batch} and
\code{lexical_level_profile_batch}. The profile information is separated into
document-major tables while the external resource provenance is stored once.
}
\examples{
wordlist <- data.frame(
  NJ8 = c(1L, 1001L, 6001L, 8000L),
  Word = c("the", "develop", "rare", "extreme")
)
profile <- new_jacet8000_profile(
  c("The", "develop", "unknown", "the"),
  wordlist
)
profile$summary
profile$coverage

batch <- new_jacet8000_profile_batch(
  list(doc_a = c("The", "develop"), doc_b = c("rare", "outside")),
  wordlist,
  unit = "surface"
)
batch$coverage

contract_path <- system.file(
  "spec", "lexical-level-profile-contract.json", package = "ldfreq"
)
stopifnot(nzchar(contract_path))
basename(contract_path)

\dontrun{
# A legitimately obtained official workbook can be used directly.
official <- new_jacet8000_profile(
  c("the", "develop", "unknown"),
  "/path/to/j8_2016.xlsx"
)
}

if (interactive()) {
  plot(profile)
  plot(profile, weighting = "type", include_off_list = FALSE)
}
}
\seealso{
\code{\link{lexdiv_preprocessing}},
\code{\link{lexdiv_flemmatize}},
\code{\link{tubelex_frequency_profile}}
}
