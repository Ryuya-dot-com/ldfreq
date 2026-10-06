# Read local MASC Penn annotations and retain positions in quanteda

Imports supplied Penn tokens from the MASC GrAF 1.0 layout, or transfers
an explicit token/segment table to quanteda without retokenizing it.
These experimental functions retain source positions and explicit
segment boundaries. They do not download a corpus or infer missing
annotations.

## Usage

``` r
lexdiv_read_masc(files, resource_version, document_ids = NULL,
  offset_unit = c("codepoint", "utf16"), max_tokens = 1e6)

lexdiv_as_quanteda(data, segments, term_col = "surface", max_tokens = 1e6)
```

## Arguments

- files:

  Non-empty character vector of local document headers. Each must use
  GrAF 1.0 `cesHeader` (Mini-MASC `.anc`) or `documentHeader` (MASC
  3.0.0 `.hdr`), with one primary text and references for `seg`, `s`,
  and `penn`. Modern headers use `f.id="f.seg"` etc. and `loc`; older
  headers use `type` and `ann.loc`. References must resolve to files in
  the same directory as the header.

- resource_version:

  A non-empty caller-supplied label for the actual data release. This
  declaration is recorded, not independently authenticated.

- document_ids:

  Unique document IDs, in file order. Defaults to header basenames
  without their extensions; supply IDs when basenames repeat.

- offset_unit:

  Unit of the source's zero-based, end-exclusive anchors: Unicode
  codepoints or UTF-16 code units. Choose from source documentation; the
  reader does not infer the unit. Primary text must be UTF-8 in either
  case.

- max_tokens:

  Positive integer bound. For the reader, maximum total Penn token rows;
  for the adapter, maximum sum of segment `token_count`, including
  excluded positions. This is an output allocation bound, not a total
  memory limit.

- data:

  Plain data frame with `document_id`, `segment_id`, `token_index`, and
  the selected term column. Indices are positive integers within each
  original segment. Keep them unchanged when excluding rows. Additional
  columns, including annotation IDs and character positions, survive.

- segments:

  Plain data frame with unique `document_id`/`segment_id` pairs and the
  original non-negative `token_count` for each segment. Its row order
  determines quanteda document order. Include empty segments. At least
  one segment is required. Do not replace the counts by retained counts.

- term_col:

  Column of non-missing, non-empty, whitespace-free token strings. For
  example, `surface` or `lemma`. No case conversion or normalization is
  requested. Missing lemmas require an explicit exclusion or other
  decision.

## Details

`lexdiv_read_masc()` requires the optional xml2 package. It is verified
against Mini-MASC 1.0's Penn layer and accepts MASC 3.0.0's modern
header layout. This does not establish whole-corpus support: a local
audit of the official 392-document MASC 3.0.0 archive accepted 122
documents under the reader's strict span/feature conditions and rejected
270. Do not silently omit failures and describe the remaining subset as
full MASC. PTB layers, arbitrary GrAF graphs and OANC are not validated
inputs. It sorts tokens and segments by source anchors, resolves
adjacent multi-region tokens, and rejects missing links, duplicate IDs,
overlapping tokens/segments, discontinuous token regions and tokens
outside the supplied sentence/utterance regions. XML with DTD/entity
declarations is not accepted. The `s` layer may describe utterances; it
is not replaced by automatic sentence splitting. Unannotated text
outside these regions stays in the original document text but does not
become a token.

The source `base`, `msd`, and `affix` features are exposed as `lemma`,
`pos`, and `affix`. Missing features stay `NA`. All flat feature values
are also retained in a list column. Penn tags are not converted to UPOS.
An imported annotation is not a guarantee of accuracy. The file format
does not establish ownership or permission to redistribute the input;
retain the actual dataset's attribution and terms separately.

`lexdiv_as_quanteda()` requires the optional quanteda package. It makes
each segment a quanteda document, preserving position gaps as padding
and retaining source document IDs in `docvars`. It verifies that the
public quanteda import/removal operations preserve all supplied terms
and positions. `quanteda_docname` is a reserved output column. Non-ASCII
terms require a UTF-8 `LC_CTYPE` locale for the quanteda import; the
adapter errors in other locales and never changes the session locale.
Check `l10n_info()[["UTF-8"]]` in the session running the analysis;
`TRUE` needs no locale change. This is not a restriction on macOS.
`C.UTF-8` is different from the non-UTF-8 `C` locale. The reader itself
accepts UTF-8 primary text independently of this restriction. Aggregate
segment counts back to original documents before computing document
frequency. Use `quanteda::ntoken(x, remove_padding = TRUE)` to count
retained tokens. The position mapping applies to the returned token
object; compounding, collapsing gaps, and n-gram construction can change
positions. For phrase locations, search the original token object with
`kwic()`.

## Value

The reader returns a plain list:

- `tokens`: document/segment IDs, within-segment `token_index`,
  `document_token_index`, source `annotation_id`,
  surface/lemma/POS/affix, `start`/`end` in 1-based inclusive Unicode
  codepoints, original `start_anchor`/`end_anchor`, and supplied
  `features`.

- `segments`: IDs, both coordinate forms, and original `token_count`.

- `documents`: IDs, unchanged primary text, title/medium/genre from the
  header (missing values remain missing), and token/segment counts.
  Empty source documents remain here even if they have no segments.

- `provenance`: reader/version, declared resource version, layer and
  offset choices, format documentation, and SHA-256 of every consumed
  file.

The adapter returns `tokens` (a quanteda tokens object), `positions`
(all supplied token rows plus `quanteda_docname`), `segments` (the
segment table plus that mapping), and `provenance` (adapter and quanteda
versions, selected term column, counts and input fingerprint). It
accepts tables independently of the MASC reader. Save the reader's
provenance alongside the adapter result; the adapter cannot recover
source metadata absent from its input tables.

## See also

[`lexdiv_ngrams`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md),
[`lexdiv_as_documents`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md)

## Examples

``` r
if (requireNamespace("xml2", quietly = TRUE)) {
  header <- system.file("extdata", "masc-example", "example.anc",
                        package = "ldfreq")
  corpus <- lexdiv_read_masc(header, resource_version = "authored-example-1")
  corpus$tokens[c("surface", "lemma", "pos", "start", "end")]
  if (requireNamespace("quanteda", quietly = TRUE)) {
    words <- corpus$tokens[corpus$tokens$pos != ".", ]
    q <- lexdiv_as_quanteda(words, corpus$segments)
    quanteda::kwic(q$tokens, "re-use", valuetype = "fixed")
    quanteda::tokens_ngrams(q$tokens, n = 2:4)
  }
}
#> Tokens consisting of 2 documents and 8 docvars.
#> segment_1 :
#> [1] "We_re-use"       "re-use_words"    "We_re-use_words"
#> 
#> segment_2 :
#> [1] "We_go"
#> 
```
