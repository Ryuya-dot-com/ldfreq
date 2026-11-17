# Search Source-Aligned Words and Phrases and Inspect Their Distribution

Search complete annotations (from
[`lexdiv_import_annotations`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_import_annotations.md)
or
[`lexdiv_as_annotations`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_import_annotations.md)),
preserving original text, token positions, selection masks and
zero-match documents. Sort saved contexts, draw Base-R positional
barcode plots, or compute single-token within-document dispersion.

## Usage

``` r
lexdiv_concordance(
  x,
  queries,
  term_col = NULL,
  valuetype = c("fixed", "glob", "regex"),
  case_insensitive = FALSE,
  keep = NULL,
  window = 5L,
  max_cells = 1e6
)

lexdiv_sort_concordance(
  x,
  side = c("right", "left"),
  depth = 1L,
  case_insensitive = FALSE
)

lexdiv_concordance_dispersion(
  x,
  query_id = NULL,
  parts = 10L,
  max_cells = 1e6,
  include_normalized = FALSE
)

# S3 method for class 'lexdiv_concordance'
print(x, ...)

# S3 method for class 'lexdiv_dispersion'
print(x, ...)

# S3 method for class 'lexdiv_concordance'
plot(
  x,
  query_id = NULL,
  relative = TRUE,
  monochrome = FALSE,
  col = NULL,
  main = NULL,
  xlab = NULL,
  ylab = "",
  ...
)
```

## Arguments

- x:

  For `lexdiv_concordance()`, an unmodified `lexdiv_annotations` object.
  For sorting, dispersion, and plotting, an unmodified
  `lexdiv_concordance` object. For `print.lexdiv_dispersion`, a
  `lexdiv_dispersion` object.

- queries:

  Named list with unique nonblank query IDs.

- term_col:

  Character token column to search. When `NULL`, defaults to `"term"` on
  bridged raw-text annotations and `"surface"` otherwise.

- valuetype:

  Fixed, glob or regex matching (uses quanteda when installed, with a
  pure-R stringi fallback).

- case_insensitive:

  Logical switch for case-insensitive matching or sorting.

- keep:

  One nonmissing logical value per original token. When `NULL`, defaults
  to `x$tokens$is_word` when present and all tokens otherwise.

- window:

  Nonnegative number of context surface-token slots on each side.

- max_cells:

  Positive whole-number allocation bound.

- side:

  Context side to sort, nearest token first.

- depth:

  Positive number of context tokens used as successive sort keys.

- query_id:

  Saved query ID to inspect. Defaults to the sole query when `x`
  contains exactly one query.

- parts:

  Number of within-document parts (integer \>= 2).

- include_normalized:

  Logical; if `TRUE`, appends Gries's normalized `DP_norm`
  (`DP / (1 - min_expected_share)`) to `documents`.

- relative:

  Plot relative positions in `[0, 1]` (`TRUE`) or raw token positions
  (`FALSE`).

- monochrome:

  Use black rather than default color.

- col, main, xlab, ylab:

  Base-R graphics styling parameters.

- ...:

  Additional Base-R graphics or
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html)
  arguments.

## Value

`lexdiv_concordance()` returns a sealed `lexdiv_concordance` object.
`lexdiv_sort_concordance()` returns an ordered occurrence data frame.
`lexdiv_concordance_dispersion()` returns a `lexdiv_dispersion` object
with `documents` and `parts`.
[`plot()`](https://rdrr.io/r/graphics/plot.default.html) draws a Base-R
positional plot and invisibly returns
`list(occurrences, documents, counts)`.

## See also

[`lexdiv_as_annotations`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_import_annotations.md),
[`lexdiv_collocations`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_collocations.md),
[`lexdiv_keyness`](https://ryuya-dot-com.github.io/ldfreq/dev/reference/lexdiv_keyness.md)

## Examples

``` r
ann <- lexdiv_as_annotations(c(d1 = "Cats chase cats and dogs.", empty = ""))
search <- lexdiv_concordance(ann, list(cat = "cats"))
print(search)
#> <lexdiv_concordance: 2 documents; 1 query; 2 occurrences>
#>  query_id document_id segment_id from to         pre keyword
#>       cat          d1         s1    1  1                Cats
#>       cat          d1         s1    3  3 Cats chase     cats
#>                   post
#>   chase cats and dogs.
#>              and dogs.
lexdiv_sort_concordance(search, case_insensitive = TRUE)
#>   query_id document_id segment_id from to document_from document_to start end
#> 1      cat          d1         s1    3  3             3           3    12  15
#> 2      cat          d1         s1    1  1             1           1     1   4
#>           pre keyword                  post matched_terms left_tokens
#> 1 Cats chase     cats             and dogs.          cats chase, Cats
#> 2                Cats  chase cats and dogs.          cats            
#>                right_tokens
#> 1              and, dogs, .
#> 2 chase, cats, and, dogs, .
#>                                                      occurrence_id
#> 1 84bf00f56dbfd33b273996cefe3fbb5e30b6bce3ea5fb51354968f82b67b5da7
#> 2 9b18aef686c66395484cf4b1680cc5defd3f6b1d8e951b985113f3ed0bd12bda
lexdiv_concordance_dispersion(search, parts = 3, include_normalized = TRUE)
#> <lexdiv_dispersion: 2 documents; 3 parts; measure=DP>
#>  document_id query_id source_tokens searchable_tokens occurrences parts
#>           d1      cat             6                 5           2     3
#>        empty      cat             0                 0           0     3
#>  nonempty_parts  DP  status       missing_reason DP_norm
#>               3 0.2      ok                 <NA>    0.25
#>               0  NA missing no_searchable_tokens      NA
plot(search)
```
