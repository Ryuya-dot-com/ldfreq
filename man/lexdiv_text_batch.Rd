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
  tokenizer = "unicode", ..., metadata = NULL
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
are ignored unless explicitly supplied through \code{metadata}; these arguments
cannot be supplied for a prepared-tokenization list.}
\item{metadata}{Optional data frame with one row for every input document,
including empty documents. Specify by name. It must contain a unique plain
character \code{document_id} column, even when the raw text uses a different
\code{id_col}. Other columns must be atomic vectors, including factors or dates;
list, matrix and nested data-frame columns are rejected. Missing study values
such as an unknown writer are allowed. The default \code{NULL} retains the
existing three-component return value.}
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
For a first analysis, create a table with one row per document and columns
\code{document_id} and \code{text}, then call
\code{lexdiv_metrics_text_batch()} directly. Replace the example texts with
your own; retain a unique ID even for an empty document. Use \code{id_col}
and \code{text_col} if your columns have different names. TXT-folder and CSV
input are shown in the linked file-input tutorial.

Read \code{result$results} for one row per document and metric. In the first
example, \emph{essay_a} has five tokens and four types (TTR 0.8),
\emph{essay_b} has five tokens and five types (TTR 1), and \emph{empty}
has zero tokens with \code{missing_reason = "empty_input"}. These short
authored texts explain the output, not a comparison of writing ability.
\code{lexdiv_widen(result$results)} puts metrics into columns without
recalculating them. Keep the complete \code{result} when saving: the wide
table alone does not retain the token audit and preprocessing records.

Use \code{lexdiv_tokenize_batch()} separately when you want to inspect or
annotate the tokens before scoring or reuse them with a reference vocabulary.
Its output is a named list: \code{prepared$essay_a$tokens} shows one document.
Do not supply tokenization settings again when scoring that prepared list.

To retain writer, task, group or occasion information with an analysis, supply
\code{metadata} to \code{lexdiv_metrics_text_batch()}. It accepts the same
metadata table for named raw texts, raw ID/text tables and prepared tokenization
lists. Rows are matched by document ID and reordered to the input order;
\code{document_id} becomes the first column and row names are reset.
Missing, extra or duplicate document IDs are errors. Select the intended roster
explicitly when a study table covers a larger corpus. Writer IDs may repeat
across documents; document IDs must not. Column names must be unique and nonempty.
UTF-8 ID markers are canonicalized as in the batch input, without Unicode
normalization. Study-column values and types are preserved.

Metadata are returned separately, not inserted into metric or token rows.
Thus a study column named \code{value} cannot overwrite a metric value.
Join selected fields by \code{document_id} for analysis, checking for column-name
collisions; save the whole object as RDS to retain the typed table and audits.
This roster check does not verify the truth of study labels, establish independent
observations or fit a repeated-measures model. No labels are inferred from text.
The separate tables returned by \code{lexdiv_import_annotations()} are not
\code{lexdiv_tokenization} objects; use the existing ID-based reporting workflow
for that input path rather than passing the imported object to this function.

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
list with three default components and optional study metadata:
\describe{
  \item{results}{A long \code{lexdiv_batch_results} data frame with
  \code{document_id} and every core metric result column.}
  \item{token_audit}{The single-text token audits joined with a leading
  \code{document_id} column. Zero-token documents have no token rows.}
  \item{preprocessing}{An input-ordered named list containing every document's
  complete preprocessing record, including zero-token documents.}
  \item{metadata}{Present only when \code{metadata} is non-\code{NULL}. A data
  frame ordered by input document ID, with one row per document.}
}
\code{print()} returns the input invisibly. \code{plot()} returns the plotted
metric rows invisibly, with the same selection rules as
\code{plot.lexdiv_batch_results()}. Use \code{lexdiv_widen(x$results)} to
create a metric table; save the complete object to retain its audits.
}
\examples{
library(ldfreq)

# 1. One row per text; keep the empty document in the input.
texts <- data.frame(
  document_id = c("essay_a", "essay_b", "empty"),
  text = c("Cats chase cats and dogs.", "The reader reads a story.", "")
)
result <- lexdiv_metrics_text_batch(
  texts, tokenizer = "english", case = "lower", metrics = "ttr"
)
result$results  # TTR: essay_a = 0.8, essay_b = 1; empty = NA
result$token_audit
lexdiv_widen(result$results)

# 2. The plot displays the two computed scores; the empty row stays in
# results.
plot(result, metric_id = "ttr")
plot(result, metric_id = "ttr", monochrome = TRUE)

# 3. Save the whole analysis. Use your own output path for a research
# project.
path <- tempfile(fileext = ".rds")
saveRDS(result, path)
restored <- readRDS(path)
restored$results
unlink(path)  # Clean up only this temporary demonstration file.

# 4. Optional workflow: prepare tokens once, then reuse them.
prepared <- lexdiv_tokenize_batch(texts, tokenizer = "english", case = "lower")
prepared$essay_a$tokens
# A 4-token window illustrates MATTR here; it is not a research
# recommendation.
lexdiv_metrics_text_batch(prepared, metrics = "mattr", window_length = 4)$results
nj8_profile_batch(prepared, unit = "surface")$coverage

# 5. Keep study information with the same analysis, matched by ID.
# Labels are fictional; the empty response has an unknown writer.
study <- data.frame(document_id = c("empty", "essay_b", "essay_a"),
  writer_id = c(NA_character_, "writer_1", "writer_1"),
  occasion = c(1L, 2L, 1L))
with_study <- lexdiv_metrics_text_batch(prepared, metrics = "ttr", metadata = study)
with_study$metadata
stopifnot(identical(with_study$results,
  lexdiv_metrics_text_batch(prepared, metrics = "ttr")$results))
}
\seealso{\code{\link{lexdiv_metrics_text}}, \code{\link{lexdiv_convenience}},
\href{https://ryuya-dot-com.github.io/ldfreq/articles/english-tokenization.html#import-text-files}{Read your own TXT or CSV files},
\href{https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report.html}{From text to a research report}}
