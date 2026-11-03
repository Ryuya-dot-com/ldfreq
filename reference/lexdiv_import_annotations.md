# Import External Annotations or Bridge Raw Texts to Corpus Annotations

`lexdiv_import_annotations()` aligns complete external token surfaces
(including Japanese morphological analyses) with original segment text.
`lexdiv_as_annotations()` bridges raw texts or `lexdiv_tokenization`
objects directly into sealed `lexdiv_annotations` objects ready for
[`lexdiv_concordance`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_concordance.md),
[`lexdiv_collocations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_collocations.md),
[`lexdiv_keyness`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_keyness.md),
[`lexdiv_ambiguity_review`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ambiguity_review.md),
and
[`lexdiv_family_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_family_profile.md).

## Usage

``` r
lexdiv_import_annotations(data, segments, provenance, max_tokens = 1e6)

lexdiv_as_annotations(
  documents,
  texts = NULL,
  id_col = "document_id",
  text_col = "text",
  normalization = "NFC",
  case = "lower",
  keep_numbers = FALSE,
  tokenizer = "english",
  language = "en",
  max_tokens = 1e6
)

# S3 method for class 'lexdiv_annotations'
print(x, ...)
```

## Arguments

- data:

  Data frame or tibble with character `document_id`, `segment_id`,
  `surface`, and consecutive positive `token_index` covering all
  non-whitespace text in each segment.

- segments:

  Data frame or tibble with unique `document_id`/`segment_id` pairs and
  UTF-8 `text`.

- provenance:

  Named list of scalar strings including `language`, `analyzer`,
  `analyzer_version`, `dictionary`, `dictionary_version`, `unit`, and
  `normalization`.

- documents:

  For `lexdiv_as_annotations()`, a named character vector, a data
  frame/tibble with `id_col` and `text_col`, a single
  `lexdiv_tokenization`, or a named list of `lexdiv_tokenization`
  objects.

- texts:

  Original raw texts required only when `documents` supplies
  `lexdiv_tokenization` objects (verified via `source_text_sha256`).

- id_col, text_col:

  Column selectors for data-frame inputs.

- normalization, case, keep_numbers, tokenizer:

  Preprocessing parameters used when `documents` supplies raw texts
  directly.

- language:

  Language code recorded in provenance.

- max_tokens:

  Positive whole-number ceiling on total token rows.

- x:

  A `lexdiv_annotations` object.

- ...:

  Additional arguments passed to
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html).

## Value

A sealed `lexdiv_annotations` object containing `tokens`, `segments`,
`documents`, `provenance`, and `integrity_sha256` (used to verify that
aligned source records remain unmodified). When created by
`lexdiv_as_annotations()`, `tokens` includes `is_word` (`TRUE` for
lexical words, `FALSE` for punctuation/excluded spans) and `term`
(normalized/cased word form or `NA_character_`).
[`print()`](https://rdrr.io/r/base/print.html) displays up to 12 token
rows and returns `x` invisibly.

## See also

[`lexdiv_concordance`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_concordance.md),
[`lexdiv_keyness`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_keyness.md),
[`lexdiv_tokenize`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)

## Examples

``` r
# Direct 1-line bridge from raw English texts:
ann <- lexdiv_as_annotations(c(
  d1 = "Hello, world! Cats chase dogs.",
  d2 = "Dogs bark loudly."
))
ann
#> <lexdiv_annotations: 2 documents; 2 segments; 12 tokens; analyzer ldfreq-english-word-tokenizer>
#>  document_id segment_id token_index surface   term is_word is_number start end
#>           d1         s1           1   Hello  hello    TRUE     FALSE     1   5
#>           d1         s1           2       ,   <NA>   FALSE     FALSE     6   6
#>           d1         s1           3   world  world    TRUE     FALSE     8  12
#>           d1         s1           4       !   <NA>   FALSE     FALSE    13  13
#>           d1         s1           5    Cats   cats    TRUE     FALSE    15  18
#>           d1         s1           6   chase  chase    TRUE     FALSE    20  24
#>           d1         s1           7    dogs   dogs    TRUE     FALSE    26  29
#>           d1         s1           8       .   <NA>   FALSE     FALSE    30  30
#>           d2         s1           1    Dogs   dogs    TRUE     FALSE     1   4
#>           d2         s1           2    bark   bark    TRUE     FALSE     6   9
#>           d2         s1           3  loudly loudly    TRUE     FALSE    11  16
#>           d2         s1           4       .   <NA>   FALSE     FALSE    17  17

# External morphological annotation import:
segments <- data.frame(document_id = "ja", segment_id = "s1",
  text = "\u732b\u304c\u6765\u305f\u3002")
tokens <- data.frame(document_id = "ja", segment_id = "s1", token_index = 1:5,
  surface = c("\u732b", "\u304c", "\u6765", "\u305f", "\u3002"))
x <- lexdiv_import_annotations(tokens, segments, list(
  language = "ja", analyzer = "authored", analyzer_version = "1",
  dictionary = "none", dictionary_version = "not-applicable",
  unit = "authored-example", normalization = "none"))
x
#> <lexdiv_annotations: 1 document; 1 segment; 5 tokens; analyzer authored>
#>  document_id segment_id token_index surface start end
#>           ja         s1           1      猫     1   1
#>           ja         s1           2      が     2   2
#>           ja         s1           3      来     3   3
#>           ja         s1           4      た     4   4
#>           ja         s1           5      。     5   5
```
