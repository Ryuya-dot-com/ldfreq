\name{ldfreq-package}
\alias{ldfreq}
\alias{ldfreq-package}
\docType{package}
\title{Reproducible Lexical Diversity and Frequency Profiles}
\description{
The \pkg{ldfreq} package computes explicitly versioned lexical-diversity
metrics from ordered tokens and provides separate auditable raw-text,
annotation, lexical-unit, Maas/MTLD sensitivity, and TUBELEX frequency-profile
surfaces. It also provides a caller-supplied New JACET 8000 level-profile
surface without bundling that list. Metric rows retain method, parameter,
schema, and contract provenance.
}
\details{
Start with \code{lexdiv_metrics()} for explicit tokens,
\code{lexdiv_metrics_text()} for one raw or annotated text,
\code{lexdiv_metrics_batch()} for multiple tokenized documents,
\code{lexdiv_profile()} for explicit parameter variants,
\code{lexdiv_variant_metrics()} for separately contracted Maas/MTLD
sensitivity variants, or
\code{new_jacet8000_profile()} for exact and cumulative pedagogical frequency
levels from a caller-supplied list, or
\code{tubelex_frequency_profile()} for coverage-aware corpus-relative
frequency and prevalence.
}
\section{Start here}{
Choose the entry point from the form of data you already have:
\describe{
  \item{One raw character string}{Use \code{lexdiv_metrics_text()}. It calls
  the explicit tokenizer and returns its preprocessing audit beside the metric
  rows.}
  \item{One ordered token vector}{Use \code{lexdiv_metrics()}. The core will
  not change case, remove tokens, or lemmatize.}
  \item{Several tokenized documents}{Use \code{lexdiv_metrics_batch()} with a
  named list or an explicit ID and token-list-column data frame.}
  \item{A corpus-relative reference profile}{Use
  \code{tubelex_frequency_profile()} for bundled TUBELEX frequency/prevalence,
  or \code{new_jacet8000_profile()} with a legitimately obtained caller copy
  of New JACET 8000.}
}

In the help pages, a \emph{token} is one occurrence and a \emph{type} is one
distinct normalized lookup value. A \emph{lemma} is an annotation-provided
base form. An AntBNC \emph{flemma} is a family grouping that does not preserve
part-of-speech distinctions. \emph{Coverage} is the proportion of eligible
tokens or types that received a usable annotation or resource match; it is not
a proficiency score.
}
\section{Input boundary}{
The public core accepts ordered, already-tokenized character vectors. It does
not infer token boundaries, change case, normalize Unicode spelling, remove
tokens, or lemmatize. Batch inputs must carry explicit unique document IDs.
\code{lexdiv_tokenize()}, \code{lexdiv_lemmatize()}, and
\code{lexdiv_flemmatize()} form a separate
preprocessing contract so that these choices cannot silently change core
methods.
}
\section{Results and provenance}{
Metric results are long-form data frames. Read \code{status} and
\code{missing_reason} before \code{value}. Each row records the method, metric
contract, result schema, requested and effective parameters, token/type counts,
the frozen \code{below_quality_floor} field, and method diagnostics. Batch,
profile, and screen layers add separate envelopes without changing the core
record.
}
\section{Formal contracts}{
Human-readable help explains normal use; installed JSON contracts are the
auditable source for exact formulas, domains, schemas, normalization rules,
and resource boundaries. The main files are
\file{lexical-diversity-contract.json},
\file{ldfreq-preprocessing-contract.json},
\file{lexical-diversity-variant-contract.json},
\file{lexical-level-profile-contract.json}, and
\file{tubelex-frequency-profile-contract.json}. Locate them with
\code{system.file("spec", filename, package = "ldfreq")}; schemas and
hand-case fixtures are installed in the same directory. Contract status is
also returned in ordinary result or provenance fields, so users do not need to
rely on an R attribute alone.
}
\section{Preprocessing and lexical units}{
The raw-text adapter records Unicode normalization, case handling, number
retention, offsets, and source/processed text hashes. Lemma analyses record the
annotation backend and version. Caller-supplied AntBNC flemma analyses also
record exact resource identity, matching rules, overrides, and identity
fallback. Surface/lemma/flemma and all/content-word choices are returned with
token-level exclusion reasons and coverage in an envelope that does not alter
the normative metric result schema.
}
\section{Corpus-relative frequency}{
\code{tubelex_frequency_profile()} retains original and normalized lookup
terms, unmatched rows, token/type coverage, and matched-only token/type-weighted
summaries. TUBELEX values are relative to a general YouTube subtitle corpus.
They are not direct measures of proficiency, writing quality, academic
register, or context-independent lexical sophistication.
}
\section{Lexical frequency levels}{
\code{new_jacet8000_profile()} maps caller-supplied ranks to Levels 1--8 and
reports exact and cumulative token/type proportions beside off-list coverage.
The Level 8 cumulative proportion equals matched coverage because off-list
items remain in the denominator. The package does not bundle or download the
New JACET 8000 list. Flemma input exposes conflicts between AntBNC families and
New JACET headwords instead of silently choosing one mapping.
}
\section{Direction and contract scale}{
Direction applies only within the exact method, parameters, preprocessing, and
sampling design. Values from different metric IDs are not interchangeable.

\tabular{lll}{
Metric ID \tab Contract scale \tab Conventional score direction \cr
\code{ttr} \tab 0 to 1 \tab higher \cr
\code{rttr} \tab 0 or greater; no finite upper bound \tab higher \cr
\code{cttr} \tab 0 or greater; no finite upper bound \tab higher \cr
\code{herdan} \tab 0 to 1 \tab higher \cr
\code{maas} \tab 0 or greater; no finite upper bound \tab lower \cr
\code{msttr} \tab 0 to 1 \tab higher \cr
\code{mattr} \tab 0 to 1 \tab higher \cr
\code{mtld} \tab 0 or greater; no finite upper bound \tab higher \cr
\code{hdd} \tab 0 to 1 \tab higher \cr
\code{yule_k} \tab 0 inclusive to 10,000 exclusive \tab lower \cr
\code{yule_i} \tab 0 or greater; no finite upper bound \tab higher
}
}
\section{Interpretation boundary}{
The methods primarily operationalize lexical variety and repetition. They are
indices used within the lexical-diversity research domain, but no single score
represents the full multidimensional lexical-diversity construct. The metrics
describe lexical-distribution properties of the supplied tokens.
They are not direct measures of language proficiency, writing quality, reader
response, or communicative effectiveness. Inferring those constructs requires a
separate validated study design and cannot be justified by one score or by the
frozen \code{below_quality_floor} field.
}
\section{Quality screens}{
\code{below_quality_floor} and \code{lexdiv_screen()} are advisory token-count
evidence screens. Here, quality is a frozen field name; it does not mean writing
quality, measurement validity, or reliability. The screens never change a value,
effective parameter, status, or document membership. Passing a screen does not
establish validity or reliability; failing one does not erase an otherwise
computable value.
}
\section{Candidate and deferred surfaces}{
The raw-text, lexical-level, and TUBELEX functions are separately versioned
public-API candidates and do not redefine the frozen v0.1 core. The new TUBELEX
public API scope remains non-release-approved until independent review and final
package inventory gates pass. The separately named expected-TTR D candidate
remains deferred.
}
\section{Offline smoke test}{
After loading \pkg{ldfreq}, run the installed script returned by
\code{system.file("examples", "offline-smoke.R", package = "ldfreq")}. It
exercises single, batch, profile, profile-batch, lexical-level, and screen
workflows without a network connection or external runtime.
}
\seealso{
\code{\link{lexdiv_metrics}}, \code{\link{lexdiv_preprocessing}},
\code{\link{lexdiv_flemmatize}},
\code{\link{lexdiv_profile}}, \code{\link{lexdiv_variant_metrics}},
\code{\link{new_jacet8000_profile}},
\code{\link{tubelex_frequency_profile}}
}
\examples{
metric_ids <- lexdiv_metric_ids()
head(metric_ids)

smoke_path <- system.file("examples", "offline-smoke.R", package = "ldfreq")
stopifnot(nzchar(smoke_path))
source(smoke_path, local = TRUE)

contract_files <- c(
  "lexical-diversity-contract.json",
  "ldfreq-preprocessing-contract.json",
  "lexical-diversity-variant-contract.json",
  "lexical-level-profile-contract.json",
  "tubelex-frequency-profile-contract.json"
)
contract_paths <- system.file("spec", contract_files, package = "ldfreq")
stopifnot(all(nzchar(contract_paths)))
basename(contract_paths)
}
\keyword{package}
