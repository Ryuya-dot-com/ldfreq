\name{lexdiv_text_batch}
\alias{lexdiv_text_batch}
\alias{lexdiv_tokenize_batch}
\alias{lexdiv_metrics_text_batch}
\alias{print.lexdiv_text_batch_results}
\alias{plot.lexdiv_text_batch_results}
\title{Tokenize and Analyze Multiple Texts with Explicit Document IDs}
\description{
Read named texts, data frames, or tibbles into complete tokenizations, then
compute lexical diversity (including multi-parameter \code{plan} profiles)
while retaining document-local audits and preprocessing provenance.
}
\usage{
lexdiv_tokenize_batch(
  documents,
  id_col = "document_id",
  text_col = "text",
  normalization = "NFC",
  case = "lower",
  keep_numbers = FALSE,
  tokenizer = "english"
)

lexdiv_metrics_text_batch(
  documents,
  id_col = "document_id",
  text_col = "text",
  unit = "surface",
  word_inclusion = "all",
  normalization = "NFC",
  case = "lower",
  keep_numbers = FALSE,
  tokenizer = "english",
  ...,
  plan = NULL,
  max_rows = 1e6,
  metadata = NULL
)

\method{print}{lexdiv_text_batch_results}(x, ...)

\method{plot}{lexdiv_text_batch_results}(x, ..., monochrome = FALSE)
}
\arguments{
\item{documents}{A named character vector, a data frame/tibble with ID and text
columns, or (for \code{lexdiv_metrics_text_batch()}) a named list of
\code{lexdiv_tokenization} objects.}
\item{id_col, text_col}{Names of the selected ID and text columns.}
\item{unit, word_inclusion}{Lexical-unit and word-inclusion settings.}
\item{normalization, case, keep_numbers, tokenizer}{Preprocessing settings for
raw text inputs (defaulting to \code{normalization = "NFC"},
\code{case = "lower"}, \code{keep_numbers = FALSE},
\code{tokenizer = "english"}).}
\item{...}{For \code{lexdiv_metrics_text_batch()}, metric arguments forwarded to
\code{\link{lexdiv_metrics_text}} when \code{plan} is \code{NULL}. For
\code{print()} and \code{plot()}, arguments passed to the underlying method.}
\item{plan}{Optional normalized request plan from \code{\link{lexdiv_plan}}.}
\item{max_rows}{Row ceiling when \code{plan} is supplied.}
\item{metadata}{Optional document metadata data frame/tibble matched by
\code{document_id}.}
\item{x}{A \code{lexdiv_text_batch_results} object.}
\item{monochrome}{Logical switch for black/grey plotting.}
}
\value{
\code{lexdiv_tokenize_batch()} returns an input-ordered named list of
\code{lexdiv_tokenization} objects. \code{lexdiv_metrics_text_batch()} returns
a \code{lexdiv_text_batch_results} list with \code{results},
\code{token_audit}, \code{preprocessing}, and optional \code{metadata}, which
pipes directly into \code{\link{lexdiv_widen}}, \code{\link{lexdiv_screen_lengths}},
and \code{\link{lexdiv_study_table}}.
}
\examples{
texts <- data.frame(
  document_id = c("essay_a", "essay_b", "empty"),
  text = c("Cats chase cats and dogs.", "The reader reads a story.", "")
)
result <- lexdiv_metrics_text_batch(texts, metrics = "ttr")
lexdiv_widen(result)
plot(result, metric_id = "ttr")

# Direct plan execution on raw texts:
plan <- lexdiv_plan(presets = character(), specs = list(
  lexdiv_spec("ttr", request_id = "ttr")
))
planned <- lexdiv_metrics_text_batch(texts, plan = plan)
planned$results[, c("document_id", "request_id", "value", "status")]
}
\seealso{\code{\link{lexdiv_metrics_text}}, \code{\link{lexdiv_study_table}},
\code{\link{lexdiv_widen}}}
