\name{lexdiv_preprocessing}
\alias{lexdiv_preprocessing}
\alias{lexdiv_tokenize}
\alias{lexdiv_lemmatize}
\alias{lexdiv_lemmatize_batch}
\alias{lexdiv_metrics_text}
\alias{print.lexdiv_tokenization}
\alias{print.lexdiv_text_results}
\title{Versioned Raw-Text Preprocessing for Lexical-Diversity Metrics}
\description{
Compute lexical diversity directly from raw text with
\code{lexdiv_metrics_text()}, or prepare reusable \code{lexdiv_tokenization}
objects with \code{lexdiv_tokenize()}, \code{lexdiv_lemmatize()}, and
\code{lexdiv_lemmatize_batch()}. By default, raw English text uses
\code{case = "lower"} and \code{tokenizer = "english"} while recording every
setting in provenance.
}
\usage{
lexdiv_tokenize(
  text,
  normalization = "NFC",
  case = "lower",
  keep_numbers = FALSE,
  tokenizer = "english"
)

lexdiv_lemmatize(
  x,
  method = "supplied",
  lemmas = NULL,
  upos = NULL,
  backend_id = NULL,
  backend_version = NULL,
  upos_backend_id = NULL,
  upos_backend_version = NULL,
  dictionary = NULL,
  dictionary_id = NULL,
  dictionary_version = NULL
)

lexdiv_lemmatize_batch(
  documents,
  method = "supplied",
  lemmas = NULL,
  upos = NULL,
  backend_id = NULL,
  backend_version = NULL,
  upos_backend_id = NULL,
  upos_backend_version = NULL,
  dictionary = NULL,
  dictionary_id = NULL,
  dictionary_version = NULL
)

lexdiv_metrics_text(
  x,
  unit = "surface",
  word_inclusion = "all",
  normalization = "NFC",
  case = "lower",
  keep_numbers = FALSE,
  metrics = setdiff(lexdiv_metric_ids(), c("expected_ttr_d", "mtld_ma")),
  segment_length = 50L,
  window_length = 50L,
  mtld_threshold = 0.72,
  sample_size = 42L,
  expected_ttr_sample_sizes = 35:50,
  tokenizer = "english",
  plan = NULL
)

\method{print}{lexdiv_tokenization}(x, ...)

\method{print}{lexdiv_text_results}(x, ...)
}
\arguments{
\item{text}{One plain valid-UTF-8 character string.}
\item{normalization}{Unicode normalization: \code{"NFC"}, \code{"NFKC"}, or \code{"none"}.}
\item{case}{Either locale-fixed English \code{"lower"} (default) or \code{"preserve"}.}
\item{keep_numbers}{Whether recognized numeric tokens are retained.}
\item{tokenizer}{\code{"english"} (default) or \code{"unicode"}.}
\item{x}{A \code{lexdiv_tokenization} object, one raw string (for
\code{lexdiv_metrics_text()}), or the printed result object.}
\item{documents}{Named list of \code{lexdiv_tokenization} objects (such as from
\code{\link{lexdiv_tokenize_batch}}).}
\item{method}{Lemma source: \code{"supplied"} or \code{"textstem"}.}
\item{lemmas, upos}{Aligned character vector(s) for \code{lexdiv_lemmatize()},
or named list(s) matching \code{documents} for \code{lexdiv_lemmatize_batch()}.}
\item{backend_id, backend_version, upos_backend_id, upos_backend_version}{Path-free
backend identifiers for caller-supplied annotations.}
\item{dictionary, dictionary_id, dictionary_version}{Optional two-column
dictionary and identifiers for \code{method = "textstem"}.}
\item{unit}{\code{"surface"}, \code{"lemma"}, or \code{"flemma"}.}
\item{word_inclusion}{\code{"all"} or \code{"content"} (UPOS ADJ/ADV/NOUN/PROPN/VERB).}
\item{metrics, segment_length, window_length, mtld_threshold, sample_size,
expected_ttr_sample_sizes}{Metric arguments forwarded to \code{\link{lexdiv_metrics}}
when \code{plan} is \code{NULL}.}
\item{plan}{Optional normalized request plan from \code{\link{lexdiv_plan}}.}
\item{...}{Additional arguments passed to \code{print.data.frame()}.}
}
\value{
\code{lexdiv_tokenize()} and \code{lexdiv_lemmatize()} return a
\code{lexdiv_tokenization} object. \code{lexdiv_lemmatize_batch()} returns an
input-ordered named list of \code{lexdiv_tokenization} objects.
\code{lexdiv_metrics_text()} returns a \code{lexdiv_text_results} list with
\code{results}, \code{token_audit}, and \code{preprocessing}.
}
\examples{
# 1. Default English lowercase preprocessing:
result <- lexdiv_metrics_text("Cats chase cats and dogs.", metrics = "ttr")
result$results  # N = 5, V = 4, TTR = 0.8

# 2. Plan-based execution directly from raw text:
plan <- lexdiv_plan(presets = character(), specs = list(
  lexdiv_spec("ttr", request_id = "ttr")
))
lexdiv_metrics_text("Cats chase cats and dogs.", plan = plan)$results

# 3. Supplied lemmas and batch lemmatization:
toks <- lexdiv_tokenize_batch(c(d1 = "Cats ran.", d2 = "Dogs barked."))
annotated_batch <- lexdiv_lemmatize_batch(
  toks,
  lemmas = list(d1 = c("cat", "run"), d2 = c("dog", "bark")),
  backend_id = "example-lemmas",
  backend_version = "1"
)
lexdiv_metrics_text_batch(annotated_batch, unit = "lemma", metrics = "ttr")
}
\seealso{\code{\link{lexdiv_flemmatize}}, \code{\link{lexdiv_text_batch}},
\code{\link{lexdiv_as_annotations}}}
\keyword{text}
