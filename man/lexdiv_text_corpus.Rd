\name{lexdiv_text_corpus}
\alias{lexdiv_text_corpus}
\alias{print.lexdiv_text_corpus}
\title{Create a Validated Raw-Text Corpus from a Data Frame}
\usage{
lexdiv_text_corpus(
  data,
  id_col = "document_id",
  text_col = "text",
  metadata_cols = NULL
)

\method{print}{lexdiv_text_corpus}(x, ...)
}
\arguments{
\item{data}{A data frame with one row per document.}
\item{id_col}{Name of the explicit document-ID column.}
\item{text_col}{Name of the raw-text column. Empty strings represent valid
empty documents; missing values are rejected.}
\item{metadata_cols}{Optional column names to copy into the text-free document
manifest. Select source sheet, source row, grouping, or other audit columns
explicitly rather than retaining every input column.}
\item{x}{An object returned by \code{lexdiv_text_corpus()} or
\code{lexdiv_read_texts()}.}
\item{...}{Arguments passed to \code{print.data.frame()}.}
}
\description{
Converts an in-memory data frame, including a tibble produced by
\code{readxl::read_excel()}, into the same named raw-document corpus used by
\code{lexdiv_read_texts()}. Excel reading and dataset-specific reshaping remain
explicit upstream steps.
}
\details{
Document IDs must be explicit, unique, non-empty valid-UTF-8 strings. The
function does not coerce numeric IDs, factors, missing values, or list-column
text. It performs no tokenization, normalization, row grouping, workbook
reading, or implicit column selection.

For Excel data, use \code{readxl::read_excel()} and dataset-specific
\code{dplyr} or \code{tidyr} operations first. Preserve the original workbook
separately, create one processed row per essay, and include source sheet/row
columns in \code{metadata_cols} when row-level traceability is required.
}
\value{
A \code{lexdiv_text_corpus} list containing \code{texts}, a named character
vector in input-row order; \code{documents}, a text-free manifest; and
\code{provenance}, the versioned conversion choices. The manifest always
records UTF-8 text byte counts and SHA-256 identities. The print method omits
text and returns its input invisibly.
}
\examples{
essays <- data.frame(
  essay_id = c("essay_01", "essay_02"),
  essay_text = c("One short essay.", "Another short essay."),
  source_sheet = "Essays",
  source_row = 2:3,
  stringsAsFactors = FALSE
)

corpus <- lexdiv_text_corpus(
  essays,
  id_col = "essay_id",
  text_col = "essay_text",
  metadata_cols = c("source_sheet", "source_row")
)
corpus$documents

results <- lapply(corpus$texts, lexdiv_metrics_text, metrics = "ttr")
results$essay_01$results
}
\seealso{\code{\link{lexdiv_read_texts}},
\code{\link{lexdiv_metrics_text}}}
\keyword{text}
