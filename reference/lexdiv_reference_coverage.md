# Compute Coverage of Multiple Documents by One Reference Term Set

Compute token- and type-weighted directional coverage for multiple
explicit term vectors against one reference term set. Exact matching,
denominators, empty-input behavior, and optional term disclosure are
explicit.

## Usage

``` r
lexdiv_reference_coverage(
  documents,
  reference,
  reference_id = "reference",
  id_col = "document_id",
  terms_col = "terms",
  details = "counts",
  max_rows = 1e6
)

# S3 method for class 'lexdiv_reference_coverage'
print(x, ...)

# S3 method for class 'lexdiv_reference_coverage'
plot(
  x,
  weighting = "token",
  col = "#0072B2",
  pch = 19,
  main = NULL,
  xlab = "document",
  ylab = "coverage",
  ylim = c(0, 1),
  ...,
  monochrome = FALSE
)
```

## Arguments

- documents:

  Either a plain named list whose elements are term vectors, or a data
  frame containing the columns selected by `id_col` and `terms_col`. The
  selected ID column must contain unique character IDs; the selected
  terms column must be a list-column with one element per row.

- reference:

  A plain character vector containing one complete reference term per
  element.

- reference_id:

  One path-free, non-empty valid-UTF-8 reference identifier. It must
  differ from every document ID.

- id_col:

  Name of the document-ID column for data-frame input.

- terms_col:

  Name of the term list-column for data-frame input.

- details:

  Either `"counts"`, which does not retain lexical strings, or
  `"terms"`, which retains document types, document and reference
  counts, and exact-match indicators in `$terms`.

- max_rows:

  One finite positive integer limiting the combined number of rows in
  all returned data frames. The bound is checked before term-detail
  allocation.

- x:

  A `lexdiv_reference_coverage` object.

- weighting:

  Exactly one of `"token"` or `"type"`. Plotting never combines the two
  weighting definitions silently.

- col, pch, main, xlab, ylab, ylim:

  Base-graphics settings.

- monochrome:

  One `TRUE` or `FALSE` value; specify by name. Defaults to color;
  `TRUE` overrides `col` with black. No title is added automatically;
  place figure titles and notes outside the image.

- ...:

  Additional arguments passed to the data-frame print method or
  [`graphics::plot()`](https://rdrr.io/r/graphics/plot.default.html), as
  appropriate.

## Details

Plot defaults use a sans serif font, horizontal tick labels and an open
frame. Override these with `family`, `las` or `bty` in the plot method's
`...`. Cosmetic graphics parameters are restored after drawing.

Each element of each vector is treated as one complete lexical unit. The
function performs no tokenization, Unicode normalization, case
conversion, stemming, lemmatization, synonym expansion, or fuzzy
matching. A single string containing whitespace triggers a warning
because it may be un-tokenized prose.

For document tokens \\D\\, distinct document types \\T\\, and the
distinct reference type set \\R\\, the two rows for each document are:

|  |  |  |
|----|----|----|
| Weighting | Numerator | Denominator |
| `token` | tokens in \\D\\ whose term belongs to \\R\\ | number of tokens in \\D\\ |
| `type` | types in \\T\\ that belong to \\R\\ | number of types in \\T\\ |

Document repetition therefore affects token coverage but not type
coverage. Reference repetition does not affect either value because the
reference defines membership, although reference token and type counts
remain visible in the result. This directional many-to-one estimand
differs from
[`lexdiv_term_overlap()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_overlap.md),
whose Jaccard, Dice, and related measures compare two distinct-type sets
and use different denominators.

## Empty and invalid input

An empty document has a zero denominator, so both rows are `missing`
with `missing_reason = "empty_document"`. An empty reference yields zero
coverage for every non-empty valid document. An invalid document
produces two local `invalid_input` rows without preventing valid
documents from being computed. An invalid reference makes every document
row invalid. Invalid term elements are never removed silently.
Structural errors in the document container, selected columns, IDs,
choices, or row bound stop the call.

## Result object

The returned list contains:

- `summary`:

  A document-major long table with one token row and one type row per
  document. Each row includes the measure and method IDs, contract and
  schema identity, value, status, missing reason, numerator,
  denominator, document/reference counts, and matched counts.

- `documents`:

  One diagnostic row per document with validation state and input
  token/type counts.

- `reference`:

  One diagnostic row for the reference.

- `terms`:

  A typed empty table by default. With `details = "terms"`, one row per
  distinct valid document term, including document and reference counts
  and the membership indicator. Reference-only terms are intentionally
  omitted because they do not enter either document denominator.

- `preprocessing`, `provenance`:

  Exact matching settings, contract/schema identity, row bound, detail
  mode, and an explicit flag saying whether lexical strings are
  retained. Raw text, hashes, and absolute paths are not copied into the
  result.

The print method shows the analysis rows and discloses retained term
details. The plot method selects one weighting, draws only finite `ok`
rows, and returns the plotted rows plus their positions invisibly for
reuse.

## Interpretation boundary

Coverage states how much of each supplied document belongs to the
supplied reference set under exact matching. It does not validate the
reference, infer semantic similarity, or measure plagiarism,
proficiency, writing quality, or reference quality. Those claims require
an independently justified reference, preprocessing pipeline, and
research design.

## Formal contract

The installed `reference-coverage-contract.json` file fixes formulas,
empty/invalid-input behavior, output shape, and the privacy boundary.
Locate it with
`system.file("spec", "reference-coverage-contract.json", package = "ldfreq")`.

## Value

`lexdiv_reference_coverage()` returns a `lexdiv_reference_coverage`
list. Its tables remain directly reusable; no implicit flattening
selects one component. The print method returns `x` invisibly. The plot
method invisibly returns the exact plotted rows plus `position`.

## See also

[`lexdiv_overlap`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_overlap.md),
[`lexdiv_metrics_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)

## Examples

``` r
documents <- list(
  essay_a = c("cat", "cat", "run", "rare"),
  essay_b = c("bird", "run", "unknown")
)
coverage <- lexdiv_reference_coverage(
  documents,
  reference = c("cat", "bird", "run"),
  reference_id = "course_list",
  details = "terms"
)
coverage$summary[, c(
  "document_id", "weighting", "value", "numerator", "denominator", "status"
)]
coverage$documents
coverage$terms
plot_data <- plot(coverage, weighting = "type")
plot_data

document_frame <- data.frame(
  document_id = c("a", "b"),
  stringsAsFactors = FALSE
)
document_frame$terms <- list(c("a", "a", "b"), c("b", "c"))
lexdiv_reference_coverage(document_frame, c("a", "b"))$summary
```
