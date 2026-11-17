\name{lexdiv_preprocessing}
\alias{lexdiv_preprocessing}
\alias{lexdiv_tokenize}
\alias{lexdiv_lemmatize}
\alias{lexdiv_metrics_text}
\alias{print.lexdiv_tokenization}
\alias{print.lexdiv_text_results}
\alias{print.lexdiv_text_batch_results}
\title{Versioned Raw-Text Preprocessing for Lexical-Diversity Metrics}
\description{
Compute lexical diversity directly from one raw text or a multi-document table
with \code{lexdiv_metrics_text()}, or prepare reusable
\code{lexdiv_tokenization} and \code{lexdiv_tokenization_batch} objects with
\code{lexdiv_tokenize()} and \code{lexdiv_lemmatize()}. By default, raw English
text uses \code{case = "lower"} and \code{tokenizer = "english"} while
recording every setting in provenance.
}
\usage{
lexdiv_tokenize(
  x,
  normalization = "NFC",
  case = "lower",
  keep_numbers = FALSE,
  tokenizer = "english",
  id_col = "document_id",
  text_col = "text"
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
  plan = NULL,
  id_col = "document_id",
  text_col = "text",
  max_rows = 1e+06,
  metadata = NULL,
  retain_token_audit = TRUE
)

\method{print}{lexdiv_tokenization}(x, ...)

\method{print}{lexdiv_text_results}(x, ...)

\method{print}{lexdiv_text_batch_results}(x, ...)
}
\arguments{
\item{x}{For \code{lexdiv_tokenize()} and \code{lexdiv_metrics_text()}, one
unnamed raw UTF-8 string, a named character vector of raw texts, an ID/text
data frame or tibble, a single \code{lexdiv_tokenization} object, or a named
list / \code{lexdiv_tokenization_batch} of tokenizations. For
\code{lexdiv_lemmatize()}, a single \code{lexdiv_tokenization} or named batch
of tokenizations. For \code{print()}, the result object.}
\item{normalization}{Unicode normalization: \code{"NFC"}, \code{"NFKC"}, or
\code{"none"}.}
\item{case}{Either locale-fixed English \code{"lower"} (default) or
\code{"preserve"}.}
\item{keep_numbers}{Whether recognized numeric tokens are retained.}
\item{tokenizer}{\code{"english"} (default) or \code{"unicode"}.}
\item{id_col, text_col}{Column names selecting unique document IDs and raw text
strings in multi-document data-frame inputs.}
\item{method}{Lemma source: \code{"supplied"} or \code{"textstem"}.}
\item{lemmas, upos}{Aligned character vector(s) for a single tokenization, or
named list(s) matching document IDs for a batch of tokenizations.}
\item{backend_id, backend_version, upos_backend_id, upos_backend_version}{Path-free
backend identifiers for caller-supplied annotations.}
\item{dictionary, dictionary_id, dictionary_version}{Optional two-column
dictionary and identifiers for \code{method = "textstem"}.}
\item{unit}{\code{"surface"}, \code{"lemma"}, or \code{"flemma"}.}
\item{word_inclusion}{\code{"all"} or \code{"content"} (UPOS
ADJ/ADV/NOUN/PROPN/VERB).}
\item{metrics, segment_length, window_length, mtld_threshold, sample_size,
expected_ttr_sample_sizes}{Metric arguments forwarded to
\code{\link{lexdiv_metrics}} when \code{plan} is \code{NULL}.}
\item{plan}{Optional normalized request plan from \code{\link{lexdiv_plan}}.}
\item{max_rows}{Positive whole-number row ceiling for multi-document execution.}
\item{metadata}{Optional document-metadata data frame keyed by \code{id_col} for
multi-document runs.}
\item{retain_token_audit}{Logical; set \code{FALSE} on very large multi-document
corpora to omit per-token audit rows while keeping metric rows and provenance.}
\item{...}{Additional arguments passed to \code{print.data.frame()}.}
}
\value{
\code{lexdiv_tokenize()} and \code{lexdiv_lemmatize()} return a
\code{lexdiv_tokenization} object for single-document input or an input-ordered
\code{lexdiv_tokenization_batch} named list for multi-document input.
\code{lexdiv_metrics_text()} returns a \code{lexdiv_text_results} list (single
document) or \code{lexdiv_text_batch_results} list (multiple documents) with
\code{results}, \code{token_audit}, and \code{preprocessing}.
}
\examples{
# 1. Default English lowercase preprocessing on one or several texts:
single <- lexdiv_metrics_text("Cats chase cats and dogs.", metrics = "ttr")
single$results  # N = 5, V = 4, TTR = 0.8

texts <- c(
  essay_a = "Cats chase cats and dogs.",
  essay_b = "The reader reads a story.",
  empty = ""
)
result <- lexdiv_metrics_text(texts, metrics = "ttr")
result$results  # TTR = 0.8, 1, NA

# 2. Plan-based execution directly from raw texts:
plan <- lexdiv_plan(presets = character(), specs = list(
  lexdiv_spec("ttr", request_id = "ttr")
))
planned <- lexdiv_metrics_text(texts, plan = plan)
planned$results

# 3. Multi-document tokenization and lemmatization through the same functions:
toks <- lexdiv_tokenize(c(d1 = "Cats ran.", d2 = "Dogs barked."))
annotated_batch <- lexdiv_lemmatize(
  toks,
  lemmas = list(d1 = c("cat", "run"), d2 = c("dog", "bark")),
  backend_id = "example-lemmas",
  backend_version = "1"
)
lexdiv_metrics_text(annotated_batch, unit = "lemma", metrics = "ttr")
}
\seealso{\code{\link{lexdiv_flemmatize}}, \code{\link{lexdiv_metrics}},
\code{\link{lexdiv_as_annotations}}}
\keyword{text}
