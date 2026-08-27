\name{lexdiv_preprocessing}
\alias{lexdiv_preprocessing}
\alias{lexdiv_tokenize}
\alias{lexdiv_lemmatize}
\alias{lexdiv_metrics_text}
\title{Versioned raw-text preprocessing for lexical-diversity metrics}
\description{
Tokenize one raw text under an explicit Unicode contract, attach lemmas and
optional Universal POS tags with backend provenance, and select surface,
lemma, or separately annotated flemma units before calling the versioned
lexical-diversity core.
}
\usage{
lexdiv_tokenize(
  text,
  normalization = "NFC",
  case = "preserve",
  keep_numbers = FALSE
)

lexdiv_lemmatize(
  x,
  method = "supplied",
  lemmas = NULL,
  upos = NULL,
  backend_id = NULL,
  backend_version = NULL,
  upos_backend_id = NULL,
  upos_backend_version = NULL
)

lexdiv_metrics_text(
  x,
  unit = "surface",
  word_inclusion = "all",
  normalization = "NFC",
  case = "preserve",
  keep_numbers = FALSE,
  metrics = lexdiv_metric_ids(),
  segment_length = 50L,
  window_length = 50L,
  mtld_threshold = 0.72,
  sample_size = 42L,
  expected_ttr_sample_sizes = 35:50
)
}
\arguments{
\item{text}{One plain valid-UTF-8 character string. An empty string is valid.}
\item{normalization}{Unicode normalization: \code{"NFC"}, \code{"NFKC"},
or \code{"none"}.}
\item{case}{Either \code{"preserve"} or locale-fixed English
\code{"lower"}.}
\item{keep_numbers}{Whether tokens consisting only of Unicode numbers are
retained. Alphanumeric tokens remain eligible under either setting.}
\item{x}{For \code{lexdiv_lemmatize()}, an object created by
\code{lexdiv_tokenize()}. For \code{lexdiv_metrics_text()}, either that object
or one raw character string. When an existing tokenization is supplied, its
recorded normalization, case, and number-retention choices are authoritative;
supplying \code{normalization}, \code{case}, or \code{keep_numbers} again is
an error. Call \code{lexdiv_tokenize()} again to change those choices.}
\item{method}{Lemma source: caller-\code{"supplied"} values or the optional
\code{"textstem"} backend.}
\item{lemmas}{An aligned character vector of lemmas for the supplied method.
Missing values are allowed and are later reported as exclusions.}
\item{upos}{Optional aligned Universal POS tags. Missing values are allowed.
Non-missing tags are uppercased and must belong to the Universal POS inventory;
unsupported labels are errors rather than ordinary non-content words.
The \pkg{textstem} backend supplies lemmas only and does not infer UPOS. Supply
tags explicitly when a later \code{word_inclusion = "content"} analysis is
required.}
\item{backend_id, backend_version}{Required non-empty, path-free lemma-backend
identifiers for caller-supplied annotations. For textstem, package identity is
recorded automatically and these arguments must be \code{NULL}. Caller labels
are public provenance and must not contain paths, secrets, or private hashes.}
\item{upos_backend_id, upos_backend_version}{Required path-free UPOS-backend
identifiers whenever any non-missing UPOS tag is present. They are never
defaulted from the lemma backend, even when one pipeline created both layers.
They must be \code{NULL} when no UPOS tags are present. These values are
public provenance; callers must not put paths, secrets, or private hashes in
them.}
\item{unit}{One of \code{"surface"}, \code{"lemma"}, or \code{"flemma"}.
Lemma and flemma analyses require the corresponding annotations on a
\code{lexdiv_tokenization} object; raw character input supports surface
analysis only.}
\item{word_inclusion}{Either \code{"all"} word tokens or \code{"content"},
defined as UPOS \code{ADJ}, \code{ADV}, \code{NOUN}, \code{PROPN}, and
\code{VERB}.}
\item{metrics}{A duplicate-free vector from \code{lexdiv_metric_ids()}.}
\item{segment_length}{Requested complete segment length for MSTTR.}
\item{window_length}{Requested step-one window length for MATTR.}
\item{mtld_threshold}{Requested MTLD threshold strictly between zero and one.}
\item{sample_size}{Requested without-replacement sample size for HD-D.}
\item{expected_ttr_sample_sizes}{A non-empty, strictly increasing vector of
sample sizes used to fit deterministic expected-TTR D.}
}
\details{
The tokenizer extracts Unicode letter, mark, and number sequences, retaining
internal apostrophes and hyphens while excluding punctuation tokens. Start and
end offsets refer to the processed text after the requested normalization and
case transformation.

The package does not silently choose or download a lemmatization model.
\code{lexdiv_lemmatize(method = "supplied")} accepts annotations created by
any documented external workflow and requires its identity and version.
\code{method = "textstem"} is an optional English lemma convenience backend.
It records the installed \pkg{textstem} version but does not create UPOS tags.
Consequently, it can be used directly for \code{unit = "lemma"} with
\code{word_inclusion = "all"}; content-word selection additionally requires
caller-supplied UPOS annotations. Missing lemmas or UPOS tags are excluded and
reported in the token audit rather than imputed.

Lemma and UPOS backend identities are separate. Supplying UPOS tags always
requires explicit \code{upos_backend_id} and \code{upos_backend_version};
the package does not derive them from \code{backend_id} or
\code{backend_version}.
\code{lexdiv_flemmatize()} is a separate caller-supplied AntBNC adapter because
flemma counting does not preserve POS distinctions and is not synonymous with
ordinary lemmatization.

\code{lexdiv_metrics_text()} does not add preprocessing columns to the versioned
metric result schema. It returns the unchanged core results beside a token-level
audit and a separately versioned preprocessing record. This allows
surface/lemma/flemma
and all/content-word analyses to be compared without treating one choice as a
universal default.

The tokenizer arguments \code{normalization}, \code{case}, and
\code{keep_numbers} apply only when \code{x} is raw text. They are never
silently reapplied to, or ignored for, an existing tokenization object.
}
\section{Saved-object compatibility}{
Preprocessing contract \code{0.1.1} validates annotation and provenance more
strictly than \code{0.1.0}, including explicit UPOS-backend identity. A
\code{lexdiv_tokenization} object saved under \code{0.1.0}, for example with
\code{saveRDS()}, is not migrated automatically. Recreate it from the
original text with \code{lexdiv_tokenize()} and then reapply annotations with
the current functions and explicit identities.
}
\section{Formal contract}{
The installed \file{ldfreq-preprocessing-contract.json} file fixes tokenizer,
normalization, annotation, lexical-unit, and result-boundary behavior. Use
\code{system.file()} with directory \code{"spec"}, that filename, and
\code{package = "ldfreq"} to locate it. The contract is ordinary JSON and can
be inspected without running a preprocessing backend.
}
\value{
\code{lexdiv_tokenize()}, \code{lexdiv_lemmatize()}, and
\code{lexdiv_flemmatize()} return a
\code{lexdiv_tokenization} object containing \code{tokens} and
\code{provenance}. \code{lexdiv_metrics_text()} returns a
\code{lexdiv_text_results} list containing \code{results},
\code{token_audit}, and \code{preprocessing}.
}
\examples{
tokenization <- lexdiv_tokenize("Cats and cat ran run.")
surface <- lexdiv_metrics_text(tokenization, metrics = "ttr")
surface$results

annotated <- lexdiv_lemmatize(
  tokenization,
  lemmas = c("cat", "and", "cat", "run", "run"),
  upos = c("NOUN", "CCONJ", "NOUN", "VERB", "VERB"),
  backend_id = "documented-example-annotations",
  backend_version = "1",
  upos_backend_id = "documented-example-upos",
  upos_backend_version = "1"
)
lemma_content <- lexdiv_metrics_text(
  annotated,
  unit = "lemma",
  word_inclusion = "content",
  metrics = "ttr"
)
lemma_content$results
lemma_content$token_audit

if (requireNamespace("textstem", quietly = TRUE)) {
  textstem_tokens <- lexdiv_tokenize(
    "The cats were running and studies.",
    case = "lower"
  )
  textstem_lemmas <- lexdiv_lemmatize(
    textstem_tokens,
    method = "textstem"
  )
  textstem_lemmas$tokens[, c("surface", "lemma")]
  textstem_lemmas$provenance$annotation
  lexdiv_metrics_text(textstem_lemmas, unit = "lemma", metrics = "ttr")
}
}
\seealso{\code{\link{lexdiv_flemmatize}}, \code{\link{lexdiv_metrics}},
\code{\link{tubelex_profile}}}
\keyword{text}
