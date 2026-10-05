\name{lexdiv_text_batch}
\alias{lexdiv_text_batch}
\alias{lexdiv_tokenize_batch}
\alias{lexdiv_metrics_text_batch}
\alias{print.lexdiv_text_batch_results}
\alias{plot.lexdiv_text_batch_results}
\title{Tokenize and analyze multiple texts with explicit document IDs}
\description{
Read named texts or explicit ID/text columns into complete tokenizations,
then compute lexical diversity while retaining document-local audits and
preprocessing. These functions do not guess IDs or merge documents.
}
\usage{
lexdiv_tokenize_batch(
  documents, id_col = "document_id", text_col = "text",
  normalization = "NFC", case = "preserve", keep_numbers = FALSE,
  tokenizer = "unicode"
)

lexdiv_metrics_text_batch(
  documents, id_col = "document_id", text_col = "text",
  unit = "surface", word_inclusion = "all",
  normalization = "NFC", case = "preserve", keep_numbers = FALSE,
  tokenizer = "unicode", ...
)

\method{print}{lexdiv_text_batch_results}(x, ...)
\method{plot}{lexdiv_text_batch_results}(x, ..., monochrome = FALSE)
}
\arguments{
\item{documents}{A named character vector, or a data frame with plain character
ID and text columns. IDs must be non-empty, unique, valid UTF-8 strings.
The metric function also accepts a plain named list of
\code{lexdiv_tokenization} objects, including annotated objects. Raw/prepared
mixed lists are not accepted. Empty texts are valid; missing texts are errors
identifying the document. An empty named vector/list or zero-row table is valid.}
\item{id_col,text_col}{Names of the selected ID and text columns. Other columns
are ignored; join study metadata by document ID afterwards. These arguments
cannot be supplied for a prepared-tokenization list.}
\item{normalization,case,keep_numbers,tokenizer}{Settings passed to
\code{\link{lexdiv_tokenize}} for raw input. All raw texts share these settings.
The default \code{"unicode"} rules preserve existing behavior; explicitly use
\code{tokenizer = "english"} for the English lexical rules. Supplying any of
these arguments for a prepared-tokenization list is an error.}
\item{unit,word_inclusion}{Lexical-unit and word-inclusion choices as in
\code{\link{lexdiv_metrics_text}}. Lemma/flemma/content-word analyses require
the corresponding annotations on every input tokenization; raw texts do not
acquire annotations automatically.}
\item{x}{A \code{lexdiv_text_batch_results} object.}
\item{monochrome}{One \code{TRUE} or \code{FALSE} value passed to the metric plot method; specify by name. Defaults to color; \code{TRUE} uses black and distinguishes points below the advisory floor by shape unless \code{pch} is supplied. No title is added automatically. See \code{\link{lexdiv_convenience}}.}
\item{...}{For the metric function, named metric requests passed to
\code{lexdiv_metrics_text}, such as \code{metrics} and \code{window_length}.
For print and plot methods, arguments passed to the corresponding method for
\code{x$results}. Plotting requires one explicit metric/specification if the
table contains several.}
}
\details{
Plot defaults use a sans serif font, horizontal tick labels and an open frame.
Override these with \code{family}, \code{las} or \code{bty} in the plot
method's \code{...}. Cosmetic graphics parameters are restored after drawing.

Input order is retained. Short and zero-token documents remain in the metric
table with their computability status, requested parameters, and counts.
A document does not change another document's requested window or sample size.
Settings and metric requests are validated even with zero documents.

Prepared objects retain their recorded settings. A batch call does not assert
that differently prepared documents are comparable: inspect preprocessing and
use common choices for comparisons. Tokenizer exclusions (such as English URLs
and numbers) are recorded in each tokenization provenance; lexical-unit
exclusions (such as missing lemmas) are recorded in the token audit. These
denominators describe different stages.

The complete tokenization list can also be passed to
\code{\link{nj8_profile_batch}}. Neither tokenizer provides TUBELEX's Treebank
segmentation; its explicit mismatch policy still applies. See
\code{vignette("english-tokenization", package = "ldfreq")} for CSV and text
file input and segmentation examples.
}
\value{
\code{lexdiv_tokenize_batch()} returns an input-ordered named list of complete
\code{lexdiv_tokenization} objects, with their token tables and provenance.

\code{lexdiv_metrics_text_batch()} returns a \code{lexdiv_text_batch_results}
list with three components:
\describe{
  \item{results}{A long \code{lexdiv_batch_results} data frame with
  \code{document_id} and every core metric result column.}
  \item{token_audit}{The single-text token audits joined with a leading
  \code{document_id} column. Zero-token documents have no token rows.}
  \item{preprocessing}{An input-ordered named list containing every document's
  complete preprocessing record, including zero-token documents.}
}
\code{print()} returns the input invisibly. \code{plot()} returns the plotted
metric rows invisibly, with the same selection rules as
\code{plot.lexdiv_batch_results()}. Use \code{lexdiv_widen(x$results)} to
create a metric table; save the complete object to retain its audits.
}
\examples{
texts <- data.frame(
  document_id = c("essay_a", "essay_b", "empty"),
  text = c("The cat can't read the book.", "A reader reads a story.", "")
)
prepared <- lexdiv_tokenize_batch(texts, tokenizer = "english", case = "lower")
prepared$essay_a$tokens
result <- lexdiv_metrics_text_batch(
  prepared, metrics = c("ttr", "mattr"), window_length = 4
)
result
result$token_audit
lexdiv_widen(result$results)
nj8_profile_batch(prepared, unit = "surface")$coverage
plot(result, metric_id = "ttr")
}
