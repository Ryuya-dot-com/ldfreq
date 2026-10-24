# Compare annotation versions on identical tokenized documents

Checks one-to-one token alignment and compares lemma, UPOS and flemma
labels without modifying either input. This supports auditing revised
annotations and explicit alternative counting schemes.

## Usage

``` r
lexdiv_compare_annotations(before, after, max_tokens = 1e6)
```

## Arguments

- before,after:

  Two `lexdiv_tokenization` objects, or two plain named lists of these
  objects. Batches must have exactly the same unique document IDs.
  Annotation layers may be absent; original text and tokenization must
  match.

- max_tokens:

  Positive integer limit on the total paired token positions, checked
  before constructing token-level comparison tables.

## Value

A plain list with three components:

- documents:

  One row per document, including empty documents, with `document_id`,
  `tokens`, `before_has_*`/`after_has_*` for each of `lemma`, `upos`,
  and `flemma`, the corresponding `*_changed_tokens` counts, and
  `changed_tokens`, the count of positions changed in at least one
  layer.

- changes:

  Only positions where a label differs. Columns are `document_id`,
  `token_index`, `start`, `end`, `surface`, and `before_*`, `after_*`,
  `*_changed` for each layer. Offsets are those of the processed text,
  as in
  [`lexdiv_tokenize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md).

- provenance:

  Complete `before` and `after` preprocessing lists, each named by
  document ID, including annotation backend labels and versions.

Single inputs use `document_1`. Batch order follows `before`; `after` is
matched by ID, never by its input position. Zero-document batches
produce empty tables and named provenance lists.

## Details

The comparison requires equal original and processed text hashes,
tokenizer identity/version, normalization, case, number policy, token
pattern, character counts and base token rows. It therefore rejects
edited texts and differently tokenized inputs even if their retained
word strings happen to agree. Use separate sensitivity analyses for
those changes. The recorded hashes detect ordinary inconsistency; they
do not authenticate the original texts.

Absent annotation columns are represented as missing labels for
token-level comparison. Two missing labels are unchanged;
missing-to-value and value-to-missing transitions count as changes.
Layer-presence columns distinguish an absent layer from an existing
layer containing only missing values, including on empty documents.
Changes in backend or resource metadata alone do not create token change
rows; inspect both complete provenance records.

A difference is not an annotation error, linguistic improvement or
proficiency gain. A morphologically refined counting key can
legitimately differ from a base lemma. The function does not infer POS,
tense or mood, choose a counting scheme, correct spellings, or calculate
metric differences. It does not assert dictionary identity from a
backend version: retain the actual resource and its version separately
when that identity is not recorded by the annotator. Unchanged flemma
labels with different match-rule metadata are likewise visible in the
original objects/provenance rather than counted as changed labels.

Save both prepared inputs with the comparison to preserve unchanged
annotation rows and resource details. The comparison contains
text-derived surface and annotation labels and is not an anonymization
step.

## See also

[`lexdiv_preprocessing`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md),
[`nj8_diagnostics`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_diagnostics.md)

## Examples

``` r
tokens <- lexdiv_tokenize("Students saw students.", case = "lower")
base <- lexdiv_lemmatize(tokens,
  lemmas = c("student", "see", "student"),
  backend_id = "authored-annotations", backend_version = "base-v1")
refined <- lexdiv_lemmatize(tokens,
  lemmas = c("student", "see_VERB_Ind_Past", "student"),
  backend_id = "authored-annotations", backend_version = "tense-v1")
audit <- lexdiv_compare_annotations(base, refined)
audit$documents
#>   document_id tokens before_has_lemma after_has_lemma lemma_changed_tokens
#> 1  document_1      3             TRUE            TRUE                    1
#>   before_has_upos after_has_upos upos_changed_tokens before_has_flemma
#> 1            TRUE           TRUE                   0             FALSE
#>   after_has_flemma flemma_changed_tokens changed_tokens
#> 1            FALSE                     0              1
audit$changes
#>   document_id token_index start end surface before_lemma       after_lemma
#> 1  document_1           2    10  12     saw          see see_VERB_Ind_Past
#>   lemma_changed before_upos after_upos upos_changed before_flemma after_flemma
#> 1          TRUE        <NA>       <NA>        FALSE          <NA>         <NA>
#>   flemma_changed
#> 1          FALSE

before <- list(essay = base, blank = lexdiv_tokenize(""))
after <- list(blank = lexdiv_tokenize(""), essay = refined)
lexdiv_compare_annotations(before, after)$documents
#>   document_id tokens before_has_lemma after_has_lemma lemma_changed_tokens
#> 1       essay      3             TRUE            TRUE                    1
#> 2       blank      0            FALSE           FALSE                    0
#>   before_has_upos after_has_upos upos_changed_tokens before_has_flemma
#> 1            TRUE           TRUE                   0             FALSE
#> 2           FALSE          FALSE                   0             FALSE
#>   after_has_flemma flemma_changed_tokens changed_tokens
#> 1            FALSE                     0              1
#> 2            FALSE                     0              0
```
