\name{lexdiv_preprocessing}
\alias{lexdiv_preprocessing}
\alias{lexdiv_tokenize}
\alias{lexdiv_lemmatize}
\alias{lexdiv_metrics_text}
\title{Versioned raw-text preprocessing for lexical-diversity metrics}
\description{
Tokenize one raw text under an explicit Unicode contract, attach lemmas and
optional Universal POS tags with backend provenance, and select surface,
lemma, or separately annotated flemma units before calling the frozen
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
  backend_version = NULL
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
  sample_size = 42L
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
or one raw character string.}
\item{method}{Lemma source: caller-\code{"supplied"} values or the optional
\code{"textstem"} backend.}
\item{lemmas}{An aligned character vector of lemmas for the supplied method.
Missing values are allowed and are later reported as exclusions.}
\item{upos}{Optional aligned Universal POS tags. Missing values are allowed.}
\item{backend_id, backend_version}{Required non-empty provenance strings for
caller-supplied annotations. The textstem identity is recorded automatically.}
\item{unit}{One of \code{"surface"}, \code{"lemma"}, or \code{"flemma"}.}
\item{word_inclusion}{Either \code{"all"} word tokens or \code{"content"},
defined as UPOS \code{ADJ}, \code{ADV}, \code{NOUN}, \code{PROPN}, and
\code{VERB}.}
\item{metrics}{A duplicate-free vector from \code{lexdiv_metric_ids()}.}
\item{segment_length}{Requested complete segment length for MSTTR.}
\item{window_length}{Requested step-one window length for MATTR.}
\item{mtld_threshold}{Requested MTLD threshold strictly between zero and one.}
\item{sample_size}{Requested without-replacement sample size for HD-D.}
}
\details{
The tokenizer extracts Unicode letter, mark, and number sequences, retaining
internal apostrophes and hyphens while excluding punctuation tokens. Start and
end offsets refer to the processed text after the requested normalization and
case transformation.

The package does not silently choose or download a lemmatization model.
\code{lexdiv_lemmatize(method = "supplied")} accepts annotations created by
any documented external workflow and requires its identity and version.
\code{method = "textstem"} is an optional convenience backend.
\code{lexdiv_flemmatize()} is a separate caller-supplied AntBNC adapter because
flemma counting does not preserve POS distinctions and is not synonymous with
ordinary lemmatization.

\code{lexdiv_metrics_text()} does not add preprocessing columns to the frozen
metric result schema. It returns the unchanged core results beside a token-level
audit and a separately versioned preprocessing record. This allows
surface/lemma/flemma
and all/content-word analyses to be compared without treating one choice as a
universal default.
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
  backend_version = "1"
)
lemma_content <- lexdiv_metrics_text(
  annotated,
  unit = "lemma",
  word_inclusion = "content",
  metrics = "ttr"
)
lemma_content$results
lemma_content$token_audit
}
\seealso{\code{\link{lexdiv_flemmatize}}, \code{\link{lexdiv_metrics}},
\code{\link{tubelex_frequency_profile}}}
\keyword{text}
