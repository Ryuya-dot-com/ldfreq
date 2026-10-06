# Profile lexical coverage by New JACET 8000 frequency level

Creates exact and cumulative token- and type-weighted lexical profiles
from a bundled New JACET 8000 table or an explicit caller-supplied copy.
The bundled table is redistributed with permission from JACET and source
attribution. No resource is downloaded at runtime.

## Usage

``` r
nj8_profile(
  terms,
  wordlist = NULL,
  rank_column = NULL,
  word_column = NULL,
  sheet = "\u65b0J8",
  unit = "lemma",
  flemma_conflict = "antbnc",
  normalization = "nfkc_lower",
  expand_parenthetical = TRUE,
  resource_version = NULL
)

nj8_profile_batch(
  documents,
  wordlist = NULL,
  rank_column = NULL,
  word_column = NULL,
  sheet = "\u65b0J8",
  unit = "lemma",
  flemma_conflict = "antbnc",
  normalization = "nfkc_lower",
  expand_parenthetical = TRUE,
  resource_version = NULL,
  id_col = "document_id",
  terms_col = "terms",
  max_rows = 1e+06
)

# S3 method for class 'lexical_level_profile'
print(x, ...)

# S3 method for class 'nj8_profile_batch'
print(x, ...)

# S3 method for class 'lexical_level_profile'
plot(
  x,
  weighting = "token",
  scale = "proportion",
  show_cumulative = TRUE,
  include_off_list = TRUE,
  bar_col = "#0072B2",
  cumulative_col = "#D55E00",
  main = NULL,
  xlab = "New JACET 8000 frequency level",
  ylab = NULL,
  show_legend = TRUE,
  ...,
  monochrome = FALSE
)
```

## Arguments

- terms:

  A plain character vector of ordered lexical units, or an object
  returned by
  [`lexdiv_tokenize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md).
  Each character-vector element is one complete lexical unit; a single
  value containing whitespace triggers a warning because it may be raw
  prose.

- documents:

  A plain named list of character vectors or tokenization objects, or a
  data frame containing an explicit ID column and a list-column of those
  inputs.

- wordlist:

  `NULL` selects the bundled, versioned table. Alternatively, a data
  frame containing New JACET 8000 ranks and entries, or a path to the
  official local XLSX file or a local CSV file. Direct XLSX input
  requires the suggested readxl package.

- rank_column, word_column:

  Optional names of the rank and entry columns. `NULL` detects the
  official XLSX headers `"\u65b0J8\u9806\u4f4d"` and
  `"\u4ee3\u8868\u30ec\u30de"`, or compatible CSV headers `"NJ8"` and
  `"Word"`.

- sheet:

  XLSX sheet containing the list. The official workbook uses
  `"\u65b0J8"`. Ignored for data-frame and CSV input.

- unit:

  One of `"lemma"` (the default because the official table contains
  representative lemmas), `"surface"`, or `"flemma"`. For a plain
  character vector, this labels the units already selected by the
  caller.

- flemma_conflict:

  For a flemma-annotated tokenization, how to resolve a surface form
  that is itself a New JACET headword but maps to another flemma: retain
  the `"antbnc"` mapping, prefer the `"wordlist"` headword, or raise an
  `"error"`.

- normalization:

  `"nfkc_lower"` applies NFKC, trimming, and locale-fixed English
  lowercasing to both queries and entries. `"identity"` performs an
  exact lookup.

- expand_parenthetical:

  Whether a terminal parenthetical list such as `"mom (mum, mummy)"`
  contributes comma-separated aliases at the same rank.

- resource_version:

  An optional version label for an external table. If `NULL`, its
  canonical rank-entry SHA-256 supplies the identity. The bundled table
  has a fixed version and cannot be relabelled.

- id_col, terms_col:

  Names of the explicit document-ID and lexical-input list-columns for
  data-frame batch input.

- max_rows:

  A positive integer bounding the combined number of returned batch
  summary and token-lookup rows. The default is 1,000,000.

- x:

  A result returned by `nj8_profile()`.

- weighting:

  Either token- or type-weighted output. Types are unique normalized
  lookup terms.

- scale:

  Plot proportions or counts.

- show_cumulative:

  Whether to overlay the cumulative profile through Level 8.

- include_off_list:

  Whether to include the separate off-list bar.

- bar_col, cumulative_col:

  Colors for the bars and cumulative curve.

- main, xlab, ylab:

  Optional base-graphics labels.

- show_legend:

  Whether to draw the exact/cumulative legend.

- monochrome:

  One `TRUE` or `FALSE` value; specify by name. Defaults to color;
  `TRUE` overrides bar and curve colors with gray and black. The
  off-list bar has a separate shade, and bars have black outlines. No
  title is added automatically; place figure titles and notes outside
  the image.

- ...:

  For [`plot()`](https://rdrr.io/r/graphics/plot.default.html),
  additional arguments passed to
  [`graphics::barplot()`](https://rdrr.io/r/graphics/barplot.html); for
  [`print()`](https://rdrr.io/r/base/print.html), additional arguments
  passed to the summary-table print method.

## Details

Plots label every level as 1–8 and keep Off-list separate. The default
proportion axis is fixed at 0–1 across documents, with unlabelled space
above for the legend. Count plots scale to the displayed series. An
undefined proportion (for example, no eligible terms) is not drawn as
zero; inspect `coverage` instead. Use `yaxt` or `axes` to control the
axis. Defaults use a sans serif font, horizontal tick labels, and an
open frame; `family`, `las` and `bty` can be overridden in `...`.

Ranks 1–8000 are assigned to eight 1,000-rank levels using
`ceiling(rank / 1000)`. The official XLSX labels its entries as
representative lemmas, so lemma input is the default. Surface-form
matching is an explicit sensitivity choice and will generally
underestimate coverage when inflected forms have not been lemmatized.

If normalization produces the same entry more than once, the lowest rank
wins and the collision count is reported. Missing ranks are diagnostic
rather than silently invented. For lemma input, tokens without lemmas
are excluded before lookup and their selection coverage is reported
separately.

Raw AntBNC and New JACET have non-trivial headword conflicts. For
example, a surface form may be an independent New JACET entry while
AntBNC groups it under another family lemma. With `unit = "flemma"`,
each such token is marked in `lookup`; the selected conflict policy and
the alternative surface-form rank/level are retained. Explicit
form-to-flemma overrides can be supplied to
[`lexdiv_flemmatize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_flemmatize.md)
before profiling.

The batch function preserves input document order and accepts the same
lexical unit and conflict policies as the single-document function. It
reads, validates, normalizes, and hashes the selected word list once for
the whole batch. It performs no document-ID inference and no recycling.
Its `max_rows` guard is checked before the external resource is
processed.

## Reading the summary

The `summary` component contains nine rows for each weighting: Levels
1–8 followed by Off-list.

- `items`:

  Occurrences for token weighting or unique normalized lookup terms for
  type weighting.

- `proportion`:

  The exact level count divided by all eligible items, including
  off-list items in the denominator.

- `cumulative_items`:

  The count at the current level or any more frequent level. It is
  missing for the Off-list row.

- `cumulative_proportion`:

  The cumulative count divided by all eligible items. Its Level 8 value
  equals the corresponding token or type coverage. It is missing for the
  Off-list row.

## Coverage denominators

`selection_coverage` describes preprocessing completeness: for example,
how many token rows had a usable lemma. `token_coverage` and
`type_coverage` then describe how many eligible units matched the
supplied list. These rates answer different questions and should be
reported separately. Type-weighted off-list rates are particularly
sensitive to whether inflected forms, spelling variants, and learner
errors remain separate surface types or are collapsed by a lemma/flemma
backend. Token and type profiles are not interchangeable versions of one
score.

## Plot

The plot method draws exact level counts or proportions as bars and
overlays the Level 1–8 cumulative series by default. Off-list is a
separate grey bar and is never appended to the cumulative curve. The
method invisibly returns the exact data plotted, allowing the same
values to be used with another graphics system.

## Resource identity and path privacy

The complete list is not copied into the result. For an external local
file, provenance retains only its basename, exact file SHA-256, and a
canonical rank-entry SHA-256. The absolute directory is not stored,
printed, or repeated in package-generated error messages. A data-frame
input has a canonical hash but no file hash.

The bundled table is redistributed with permission from JACET and source
attribution. Cite JACET Basic Word Revision Committee (Ed.). (2016).
*The New JACET List of 8000 Basic Words*. Tokyo: Kirihara Shoten. The
installed `licenses/nj8/NOTICE.md` records the permission and changes.
All 8,000 rank/entry pairs match the official workbook. The bundled
edition restores the missing word `nan` at rank 6926 and lowercase
`true`/`false` at ranks 326/2382 in the supplied snapshot. External
copies retain their applicable terms; supplying a table does not verify
that it is the official edition. Provenance distinguishes bundled from
external input and records the source hash and selected version.

## Batch output

`nj8_profile_batch()` returns document-major `summary` and `lookup`
tables with an explicit `document_id`. Its `coverage` and
`document_diagnostics` components contain one row per input document;
`exclusion_reasons` retains non-empty preprocessing exclusions;
`document_provenance` stores each input's preprocessing reference as a
list-column. Shared resource identity and validation diagnostics are
stored once in `provenance` and `resource_diagnostics`. An empty
container returns typed zero-row tables and status `"empty"`; a named
empty document still contributes its ordinary 18 summary rows.

## Formal contract

The exact denominator, normalization, alias, flemma-conflict, batch,
plot, and resource-boundary rules are installed in
`lexical-level-profile-contract.json`. Locate it with
`system.file("spec", "lexical-level-profile-contract.json", package = "ldfreq")`.
The contract distinguishes the bundled default from external input. The
adapter's measurement contract is normative for version 0.2.0.

## Value

`nj8_profile()` returns a list of class `nj8_profile` and
`lexical_level_profile`:

- `status`:

  `"ok"` or `"empty"`.

- `summary`:

  Exact and cumulative token/type level rows.

- `lookup`:

  One lossless query row per eligible unit, including its surface and
  selected terms, match rule, normalized effective lookup term,
  headword-conflict state and resolution, alternative surface
  rank/level, match state, rank, and level.

- `coverage`:

  Selection, matched, and off-list token/type counts and rates.

- `provenance`:

  Contract, resource hash, lexical-unit, normalization, and denominator
  identity.

- `diagnostics`:

  Resolved columns, rank completeness, alias and collision counts, and
  preprocessing exclusions.

The plot method invisibly returns the summary rows and exact values
drawn.

`nj8_profile_batch()` returns a list of class `nj8_profile_batch` and
`lexical_level_profile_batch`. The profile information is separated into
document-major tables while the external resource provenance is stored
once.

## See also

[`lexdiv_preprocessing`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md),
[`lexdiv_flemmatize`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_flemmatize.md),
[`tubelex_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md)

## Examples

``` r
nj8_profile(c("the", "true", "false", "nan"))
#> <nj8_profile> status=ok | token coverage=100.0% | unit=lemma
#>  weighting level level_label items proportion cumulative_items
#>      token     1     Level 1     2       0.50                2
#>      token     2     Level 2     0       0.00                2
#>      token     3     Level 3     1       0.25                3
#>      token     4     Level 4     0       0.00                3
#>      token     5     Level 5     0       0.00                3
#>      token     6     Level 6     0       0.00                3
#>      token     7     Level 7     1       0.25                4
#>      token     8     Level 8     0       0.00                4
#>      token    NA    Off-list     0       0.00               NA
#>  cumulative_proportion
#>                   0.50
#>                   0.50
#>                   0.75
#>                   0.75
#>                   0.75
#>                   0.75
#>                   1.00
#>                   1.00
#>                     NA

wordlist <- data.frame(
  NJ8 = c(1L, 1001L, 6001L, 8000L),
  Word = c("the", "develop", "rare", "extreme")
)
profile <- nj8_profile(
  c("The", "develop", "unknown", "the"),
  wordlist = NULL,
  unit = "surface"
)
profile$summary
#>    weighting level level_label items proportion cumulative_items
#> 1      token     1     Level 1     3  0.7500000                3
#> 2      token     2     Level 2     0  0.0000000                3
#> 3      token     3     Level 3     1  0.2500000                4
#> 4      token     4     Level 4     0  0.0000000                4
#> 5      token     5     Level 5     0  0.0000000                4
#> 6      token     6     Level 6     0  0.0000000                4
#> 7      token     7     Level 7     0  0.0000000                4
#> 8      token     8     Level 8     0  0.0000000                4
#> 9      token    NA    Off-list     0  0.0000000               NA
#> 10      type     1     Level 1     2  0.6666667                2
#> 11      type     2     Level 2     0  0.0000000                2
#> 12      type     3     Level 3     1  0.3333333                3
#> 13      type     4     Level 4     0  0.0000000                3
#> 14      type     5     Level 5     0  0.0000000                3
#> 15      type     6     Level 6     0  0.0000000                3
#> 16      type     7     Level 7     0  0.0000000                3
#> 17      type     8     Level 8     0  0.0000000                3
#> 18      type    NA    Off-list     0  0.0000000               NA
#>    cumulative_proportion
#> 1              0.7500000
#> 2              0.7500000
#> 3              1.0000000
#> 4              1.0000000
#> 5              1.0000000
#> 6              1.0000000
#> 7              1.0000000
#> 8              1.0000000
#> 9                     NA
#> 10             0.6666667
#> 11             0.6666667
#> 12             1.0000000
#> 13             1.0000000
#> 14             1.0000000
#> 15             1.0000000
#> 16             1.0000000
#> 17             1.0000000
#> 18                    NA
profile$coverage
#> $input_tokens
#> [1] 4
#> 
#> $eligible_tokens
#> [1] 4
#> 
#> $excluded_tokens
#> [1] 0
#> 
#> $selection_coverage
#> [1] 1
#> 
#> $matched_tokens
#> [1] 4
#> 
#> $off_list_tokens
#> [1] 0
#> 
#> $token_coverage
#> [1] 1
#> 
#> $eligible_types
#> [1] 3
#> 
#> $matched_types
#> [1] 3
#> 
#> $off_list_types
#> [1] 0
#> 
#> $type_coverage
#> [1] 1
#> 

batch <- nj8_profile_batch(
  list(doc_a = c("The", "develop"), doc_b = c("rare", "outside")),
  wordlist = NULL,
  unit = "surface"
)
batch$coverage
#>   document_id input_tokens eligible_tokens excluded_tokens selection_coverage
#> 1       doc_a            2               2               0                  1
#> 2       doc_b            2               2               0                  1
#>   matched_tokens off_list_tokens token_coverage eligible_types matched_types
#> 1              2               0              1              2             2
#> 2              2               0              1              2             2
#>   off_list_types type_coverage
#> 1              0             1
#> 2              0             1

contract_path <- system.file(
  "spec", "lexical-level-profile-contract.json", package = "ldfreq"
)
stopifnot(nzchar(contract_path))
basename(contract_path)
#> [1] "lexical-level-profile-contract.json"

if (FALSE) { # \dontrun{
# A legitimately obtained official workbook can be used directly.
official <- nj8_profile(
  c("the", "develop", "unknown"),
  "/path/to/j8_2016.xlsx"
)
} # }

if (interactive()) {
  plot(profile)
  plot(profile, weighting = "type", include_off_list = FALSE)
}
```
