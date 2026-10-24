# Tokenize and analyze multiple texts with explicit document IDs

Read named texts or explicit ID/text columns into complete
tokenizations, then compute lexical diversity while retaining
document-local audits and preprocessing. These functions do not guess
IDs or merge documents.

## Usage

``` r
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

# S3 method for class 'lexdiv_text_batch_results'
print(x, ...)
# S3 method for class 'lexdiv_text_batch_results'
plot(x, ..., monochrome = FALSE)
```

## Arguments

- documents:

  A named character vector, or a data frame with plain character ID and
  text columns. IDs must be non-empty, unique, valid UTF-8 strings. The
  metric function also accepts a plain named list of
  `lexdiv_tokenization` objects, including annotated objects.
  Raw/prepared mixed lists are not accepted. Empty texts are valid;
  missing texts are errors identifying the document. An empty named
  vector/list or zero-row table is valid.

- id_col,text_col:

  Names of the selected ID and text columns. Other columns are ignored
  unless explicitly supplied through `metadata`; these arguments cannot
  be supplied for a prepared-tokenization list.

- metadata:

  Optional data frame with one row for every input document, including
  empty documents. Specify by name. It must contain a unique plain
  character `document_id` column, even when the raw text uses a
  different `id_col`. Other columns must be atomic vectors, including
  factors or dates; list, matrix and nested data-frame columns are
  rejected. Missing study values such as an unknown writer are allowed.
  The default `NULL` retains the existing three-component return value.

- normalization,case,keep_numbers,tokenizer:

  Settings passed to
  [`lexdiv_tokenize`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
  for raw input. All raw texts share these settings. The default
  `"unicode"` rules preserve existing behavior; explicitly use
  `tokenizer = "english"` for the English lexical rules. Supplying any
  of these arguments for a prepared-tokenization list is an error.

- unit,word_inclusion:

  Lexical-unit and word-inclusion choices as in
  [`lexdiv_metrics_text`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md).
  Lemma/flemma/content-word analyses require the corresponding
  annotations on every input tokenization; raw texts do not acquire
  annotations automatically.

- x:

  A `lexdiv_text_batch_results` object.

- monochrome:

  One `TRUE` or `FALSE` value passed to the metric plot method; specify
  by name. Defaults to color; `TRUE` uses black and distinguishes points
  below the advisory floor by shape unless `pch` is supplied. No title
  is added automatically. See
  [`lexdiv_convenience`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md).

- ...:

  For the metric function, named metric requests passed to
  `lexdiv_metrics_text`, such as `metrics` and `window_length`. For
  print and plot methods, arguments passed to the corresponding method
  for `x$results`. Plotting requires one explicit metric/specification
  if the table contains several.

## Details

For a first analysis, create a table with one row per document and
columns `document_id` and `text`, then call
`lexdiv_metrics_text_batch()` directly. Replace the example texts with
your own; retain a unique ID even for an empty document. Use `id_col`
and `text_col` if your columns have different names. TXT-folder and CSV
input are shown in the linked file-input tutorial.

Read `result$results` for one row per document and metric. In the first
example, *essay_a* has five tokens and four types (TTR 0.8), *essay_b*
has five tokens and five types (TTR 1), and *empty* has zero tokens with
`missing_reason = "empty_input"`. These short authored texts explain the
output, not a comparison of writing ability.
`lexdiv_widen(result$results)` puts metrics into columns without
recalculating them. Keep the complete `result` when saving: the wide
table alone does not retain the token audit and preprocessing records.

Use `lexdiv_tokenize_batch()` separately when you want to inspect or
annotate the tokens before scoring or reuse them with a reference
vocabulary. Its output is a named list: `prepared$essay_a$tokens` shows
one document. Do not supply tokenization settings again when scoring
that prepared list.

To retain writer, task, group or occasion information with an analysis,
supply `metadata` to `lexdiv_metrics_text_batch()`. It accepts the same
metadata table for named raw texts, raw ID/text tables and prepared
tokenization lists. Rows are matched by document ID and reordered to the
input order; `document_id` becomes the first column and row names are
reset. Missing, extra or duplicate document IDs are errors. Select the
intended roster explicitly when a study table covers a larger corpus.
Writer IDs may repeat across documents; document IDs must not. Column
names must be unique and nonempty. UTF-8 ID markers are canonicalized as
in the batch input, without Unicode normalization. Study-column values
and types are preserved.

Metadata are returned separately, not inserted into metric or token
rows. Thus a study column named `value` cannot overwrite a metric value.
Join selected fields by `document_id` for analysis, checking for
column-name collisions; save the whole object as RDS to retain the typed
table and audits. This roster check does not verify the truth of study
labels, establish independent observations or fit a repeated-measures
model. No labels are inferred from text. The separate tables returned by
[`lexdiv_import_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md)
are not `lexdiv_tokenization` objects; use the existing ID-based
reporting workflow for that input path rather than passing the imported
object to this function.

Plot defaults use a sans serif font, horizontal tick labels and an open
frame. Override these with `family`, `las` or `bty` in the plot method's
`...`. Cosmetic graphics parameters are restored after drawing.

Input order is retained. Short and zero-token documents remain in the
metric table with their computability status, requested parameters, and
counts. A document does not change another document's requested window
or sample size. Settings and metric requests are validated even with
zero documents. Only metric arguments supported by
[`lexdiv_metrics_text()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
can be forwarded through `...`; `plan` and `max_rows` are not supported.

Prepared objects retain their recorded settings. A batch call does not
assert that differently prepared documents are comparable: inspect
preprocessing and use common choices for comparisons. Tokenizer
exclusions (such as English URLs and numbers) are recorded in each
tokenization provenance; lexical-unit exclusions (such as missing
lemmas) are recorded in the token audit. These denominators describe
different stages.

The complete tokenization list can also be passed to
[`nj8_profile_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md).
Neither tokenizer provides TUBELEX's Treebank segmentation; its explicit
mismatch policy still applies. See [english tokenization
guide](https://ryuya-dot-com.github.io/ldfreq/articles/english-tokenization.html)
for CSV and text file input and segmentation examples.

## Value

`lexdiv_tokenize_batch()` returns an input-ordered named list of
complete `lexdiv_tokenization` objects, with their token tables and
provenance.

`lexdiv_metrics_text_batch()` returns a `lexdiv_text_batch_results` list
with three default components and optional study metadata:

- results:

  A long `lexdiv_batch_results` data frame with `document_id` and every
  core metric result column.

- token_audit:

  The single-text token audits joined with a leading `document_id`
  column. Zero-token documents have no token rows.

- preprocessing:

  An input-ordered named list containing every document's complete
  preprocessing record, including zero-token documents.

- metadata:

  Present only when `metadata` is non-`NULL`. A data frame ordered by
  input document ID, with one row per document.

[`print()`](https://rdrr.io/r/base/print.html) returns the input
invisibly. [`plot()`](https://rdrr.io/r/graphics/plot.default.html)
returns the plotted metric rows invisibly, with the same selection rules
as
[`plot.lexdiv_batch_results()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md).
Use `lexdiv_widen(x$results)` to create a metric table; save the
complete object to retain its audits.

## See also

[Getting started: read, plot and save document
results](https://ryuya-dot-com.github.io/ldfreq/articles/getting-started.html),
[`lexdiv_metrics_text`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md),
[`lexdiv_convenience`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md),
[Read your own TXT or CSV
files](https://ryuya-dot-com.github.io/ldfreq/articles/english-tokenization.html#import-text-files),
[From text to a research
report](https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report.html)

## Examples

``` r
# Optional data: review and explicitly download these resources first.
if (all(lexdiv_resource_info(c("nj8"))$available)) {
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

```
