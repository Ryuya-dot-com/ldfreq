# Compute Exact Type Overlap Between Two Texts

Compute Jaccard, Dice, directional coverage, and overlap-coefficient
values from two exact term sets. A separate adapter selects explicitly
annotated Universal POS content words before applying the same term
core.

## Usage

``` r
lexdiv_overlap_ids()

lexdiv_term_overlap(
  terms_a,
  terms_b,
  measures = lexdiv_overlap_ids(),
  document_ids = c("text_a", "text_b"),
  details = "counts"
)

lexdiv_content_overlap(
  x,
  y,
  unit = "lemma",
  measures = lexdiv_overlap_ids(),
  document_ids = c("text_a", "text_b"),
  details = "counts",
  mismatch = "error"
)

# S3 method for class 'lexdiv_overlap'
print(x, ...)
```

## Arguments

- terms_a, terms_b:

  Plain character vectors with one complete lexical unit per element.
  Missing or empty terms, invalid UTF-8, and `bytes`- or `latin1`-marked
  strings invalidate the pair instead of being silently removed.

- measures:

  A non-empty, duplicate-free vector from `lexdiv_overlap_ids()`.

- document_ids:

  Two distinct, path-free, plain, non-empty valid-UTF-8 identifiers for
  documents A and B. Control characters are not accepted.

- details:

  Either `"counts"`, which does not retain lexical items, or `"terms"`,
  which returns shared and side-unique exact terms with token counts.

- x, y:

  For `lexdiv_content_overlap()`, objects created by
  [`lexdiv_tokenize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
  and annotated with
  [`lexdiv_lemmatize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md),
  including explicit `upos_backend_id` and `upos_backend_version`
  whenever UPOS tags are present. Raw character strings are not accepted
  because ldfreq does not infer UPOS tags. Flemma comparison
  additionally requires
  [`lexdiv_flemmatize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_flemmatize.md).
  For the print method, `x` is a `lexdiv_term_overlap` or
  `lexdiv_content_overlap` object and `y` is not used.

- unit:

  One of `"lemma"`, `"surface"`, or `"flemma"`. The default is explicit
  lemma comparison. The selected units are not normalized again.

- mismatch:

  Action when A and B record different or unverifiable unit-relevant
  settings. The default `"error"` fails closed; `"warn"` and `"allow"`
  must be selected explicitly. This controls only the diagnostic action;
  it never transforms either input.

- ...:

  Additional arguments passed to the summary-table print method.

## Details

`lexdiv_term_overlap()` converts each valid input to a set of distinct
exact strings. Token order and repetition do not affect overlap values.
It does not perform tokenization, Unicode normalization, case
conversion, stemming, lemmatization, synonym expansion, or fuzzy
matching.

For type sets \\A\\ and \\B\\, intersection \\I\\, and union \\U\\, the
measures are:

|                             |                                |           |
|-----------------------------|--------------------------------|-----------|
| Measure ID                  | Numerator and denominator      | Symmetric |
| `jaccard_types`             | \\\|I\| / \|U\|\\              | yes       |
| `dice_types`                | \\2\|I\| / (\|A\| + \|B\|)\\   | yes       |
| `a_covered_by_b_types`      | \\\|I\| / \|A\|\\              | no        |
| `b_covered_by_a_types`      | \\\|I\| / \|B\|\\              | no        |
| `overlap_coefficient_types` | \\\|I\| / \min(\|A\|, \|B\|)\\ | yes       |

The summary always carries the numeric numerator and denominator.
Directional rows also identify the source (denominator) document and
reference document, so A-in-B cannot be confused with B-in-A.

`lexdiv_content_overlap()` uses the same content set as
`lexdiv_metrics_text(..., word_inclusion = "content")`: `ADJ`, `ADV`,
`NOUN`, `PROPN`, and `VERB`. Missing UPOS, non-content UPOS, and missing
selected units are excluded for different reasons and counted
separately. The `coverage` table should be interpreted beside the
overlap values. The `comparability` table records whether A and B use
the same relevant preprocessing and annotation settings. It has exactly
four columns: `component`, `value_a`, `value_b`, and `matches`. The
values are disclosed; there is no `values_disclosed` column.

The compared components depend on `unit`. Surface comparison uses
tokenizer settings and UPOS backend identity. Lemma comparison
additionally uses the lemma method and backend. If either lemma backend
is textstem, both dictionary IDs, versions, content hashes, hash
methods, query casefold rules and locales must be present and equal.
Older saved annotations lacking this record fail strict comparison even
if both lack it; reannotate with a known dictionary or explicitly use
the existing mismatch policy to retain the uncertainty. These checks
establish recorded processing agreement, not linguistic validity. Flemma
comparison instead adds the fixed flemma adapter/parser and its
resource/override settings; it intentionally ignores lemma
method/backend because
[`lexdiv_flemmatize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_flemmatize.md)
consumes surface forms rather than lemmas.

For flemma input, adapter/parser/resource IDs are fixed by ldfreq.
Strict comparison requires both caller-declared resource versions to be
present and equal. When neither side used overrides, the override
setting is comparable without an override version. If either side used
overrides, both sides must use overrides and declare the same
non-missing version. Missing labels are unverifiable, different labels
are mismatches, and no flemma resource or override content hash is
compared. Because declared labels appear in the table, callers must not
put paths, secrets, private hashes, or machine-specific details in them.

## Empty sets and invalid input

When both type sets are empty, every measure is `missing`; empty sets
are not treated as perfect overlap. When only one set is empty, Jaccard
and Dice are zero. A directional measure is missing only when its own
denominator set is empty; the other direction is zero. The overlap
coefficient is missing when either set is empty.

Invalid term input makes all requested rows `invalid_input`. The
`missing_reason` identifies whether A, B, or both inputs were invalid.
Structural request errors such as unknown measure IDs stop the call.

## Result object

Both functions return a list inheriting from `lexdiv_overlap`. Its
components are:

- `summary`:

  One row per requested measure, including method and schema identity,
  value, status, numerator, denominator, document direction, set counts,
  lexical unit, and analysis scope.

- `counts`:

  One pair-level row with token and type denominators.

- `coverage`:

  One row per document. Content overlap reports UPOS, content-word,
  selected-unit, and flemma identity-fallback coverage.

- `shared_terms`, `unique_to_a`, `unique_to_b`:

  Typed empty tables under `details = "counts"`; exact lexical details
  under `details = "terms"`.

- `exclusions`:

  Aggregated content-word exclusion counts.

- `comparability`:

  A/B preprocessing and annotation comparisons in the four columns
  `component`, `value_a`, `value_b`, and `matches`.

- `preprocessing`, `provenance`:

  Measurement settings and contract identity.
  `provenance$contains_lexical_terms` states whether the three
  term-detail tables retain exact lexical strings. The print method
  displays a notice when they do. Raw text, text hashes, flemma resource
  or override hashes, local resource file names, and absolute paths are
  not copied into the overlap result.

## Interpretation boundary

These functions describe exact lexical sharing under the selected unit
and content-word annotations. They are not plagiarism detectors or
direct measures of semantic similarity, coherence, language proficiency,
or writing quality. Such claims require a separate validated design.
Jaccard, Dice, directional coverage, and the overlap coefficient have
different denominators and are not interchangeable labels for one
generic overlap percentage.

## Formal contract

The installed `lexical-overlap-contract.json` file fixes measure
formulas, empty-set behavior, content-word eligibility, comparability
diagnostics, and the privacy boundary. Locate it with
`system.file("spec", "lexical-overlap-contract.json", package = "ldfreq")`.

## Value

`lexdiv_overlap_ids()` returns a character vector.
`lexdiv_term_overlap()` returns a `lexdiv_term_overlap` object;
`lexdiv_content_overlap()` returns a `lexdiv_content_overlap` object.
Both also inherit from `lexdiv_overlap`. The shared print method returns
`x` invisibly.

## See also

[`lexdiv_preprocessing`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md),
[`lexdiv_metrics`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)

## Examples

``` r
term_overlap <- lexdiv_term_overlap(
  c("cat", "dog", "run"),
  c("cat", "bird", "run"),
  details = "terms"
)
term_overlap$summary
#>                  measure_id                                         method_id
#> 1             jaccard_types           jaccard_type_intersection_over_union_v1
#> 2                dice_types          dice_type_twice_intersection_over_sum_v1
#> 3      a_covered_by_b_types        a_covered_by_b_type_intersection_over_a_v1
#> 4      b_covered_by_a_types        b_covered_by_a_type_intersection_over_b_v1
#> 5 overlap_coefficient_types overlap_coefficient_type_intersection_over_min_v1
#>      overlap_contract_id overlap_contract_version           result_schema_id
#> 1 ldfreq-lexical-overlap                    0.2.0 lexdiv-type-overlap-result
#> 2 ldfreq-lexical-overlap                    0.2.0 lexdiv-type-overlap-result
#> 3 ldfreq-lexical-overlap                    0.2.0 lexdiv-type-overlap-result
#> 4 ldfreq-lexical-overlap                    0.2.0 lexdiv-type-overlap-result
#> 5 ldfreq-lexical-overlap                    0.2.0 lexdiv-type-overlap-result
#>   result_schema_version     value status missing_reason numerator denominator
#> 1                 0.1.0 0.5000000     ok           <NA>         2           4
#> 2                 0.1.0 0.6666667     ok           <NA>         4           6
#> 3                 0.1.0 0.6666667     ok           <NA>         2           3
#> 4                 0.1.0 0.6666667     ok           <NA>         2           3
#> 5                 0.1.0 0.6666667     ok           <NA>         2           3
#>   document_id_a document_id_b source_document_id reference_document_id
#> 1        text_a        text_b               <NA>                  <NA>
#> 2        text_a        text_b               <NA>                  <NA>
#> 3        text_a        text_b             text_a                text_b
#> 4        text_a        text_b             text_b                text_a
#> 5        text_a        text_b               <NA>                  <NA>
#>   type_count_a type_count_b shared_type_count union_type_count
#> 1            3            3                 2                4
#> 2            3            3                 2                4
#> 3            3            3                 2                4
#> 4            3            3                 2                4
#> 5            3            3                 2                4
#>       analysis_scope unit content_set_id content_set_version
#> 1 all_supplied_terms term           <NA>                <NA>
#> 2 all_supplied_terms term           <NA>                <NA>
#> 3 all_supplied_terms term           <NA>                <NA>
#> 4 all_supplied_terms term           <NA>                <NA>
#> 5 all_supplied_terms term           <NA>                <NA>
term_overlap$shared_terms
#>   term token_count_a token_count_b
#> 1  cat             1             1
#> 2  run             1             1

x <- lexdiv_lemmatize(
  lexdiv_tokenize("Cats and dogs ran.", case = "lower"),
  lemmas = c("cat", "and", "dog", "run"),
  upos = c("NOUN", "CCONJ", "NOUN", "VERB"),
  backend_id = "documented-example-annotations",
  backend_version = "1",
  upos_backend_id = "documented-example-upos",
  upos_backend_version = "1"
)
y <- lexdiv_lemmatize(
  lexdiv_tokenize("Cats and birds ran.", case = "lower"),
  lemmas = c("cat", "and", "bird", "run"),
  upos = c("NOUN", "CCONJ", "NOUN", "VERB"),
  backend_id = "documented-example-annotations",
  backend_version = "1",
  upos_backend_id = "documented-example-upos",
  upos_backend_version = "1"
)
content_overlap <- lexdiv_content_overlap(
  x,
  y,
  details = "terms",
  document_ids = c("essay", "reference")
)
content_overlap$summary
#>                  measure_id                                         method_id
#> 1             jaccard_types           jaccard_type_intersection_over_union_v1
#> 2                dice_types          dice_type_twice_intersection_over_sum_v1
#> 3      a_covered_by_b_types        a_covered_by_b_type_intersection_over_a_v1
#> 4      b_covered_by_a_types        b_covered_by_a_type_intersection_over_b_v1
#> 5 overlap_coefficient_types overlap_coefficient_type_intersection_over_min_v1
#>      overlap_contract_id overlap_contract_version           result_schema_id
#> 1 ldfreq-lexical-overlap                    0.2.0 lexdiv-type-overlap-result
#> 2 ldfreq-lexical-overlap                    0.2.0 lexdiv-type-overlap-result
#> 3 ldfreq-lexical-overlap                    0.2.0 lexdiv-type-overlap-result
#> 4 ldfreq-lexical-overlap                    0.2.0 lexdiv-type-overlap-result
#> 5 ldfreq-lexical-overlap                    0.2.0 lexdiv-type-overlap-result
#>   result_schema_version     value status missing_reason numerator denominator
#> 1                 0.1.0 0.5000000     ok           <NA>         2           4
#> 2                 0.1.0 0.6666667     ok           <NA>         4           6
#> 3                 0.1.0 0.6666667     ok           <NA>         2           3
#> 4                 0.1.0 0.6666667     ok           <NA>         2           3
#> 5                 0.1.0 0.6666667     ok           <NA>         2           3
#>   document_id_a document_id_b source_document_id reference_document_id
#> 1         essay     reference               <NA>                  <NA>
#> 2         essay     reference               <NA>                  <NA>
#> 3         essay     reference              essay             reference
#> 4         essay     reference          reference                 essay
#> 5         essay     reference               <NA>                  <NA>
#>   type_count_a type_count_b shared_type_count union_type_count
#> 1            3            3                 2                4
#> 2            3            3                 2                4
#> 3            3            3                 2                4
#> 4            3            3                 2                4
#> 5            3            3                 2                4
#>       analysis_scope  unit              content_set_id content_set_version
#> 1 upos_content_words lemma universal-pos-content-words               0.1.0
#> 2 upos_content_words lemma universal-pos-content-words               0.1.0
#> 3 upos_content_words lemma universal-pos-content-words               0.1.0
#> 4 upos_content_words lemma universal-pos-content-words               0.1.0
#> 5 upos_content_words lemma universal-pos-content-words               0.1.0
content_overlap$coverage
#>   document_id input_tokens content_tokens eligible_tokens excluded_tokens
#> 1       essay            4              3               3               1
#> 2   reference            4              3               3               1
#>   missing_upos_tokens non_content_upos_tokens missing_unit_tokens
#> 1                   0                       1                   0
#> 2                   0                       1                   0
#>   identity_fallback_tokens eligible_types upos_coverage unit_coverage
#> 1                        0              3             1             1
#> 2                        0              3             1             1
#>   content_unit_coverage selection_coverage
#> 1                     1               0.75
#> 2                     1               0.75
content_overlap$shared_terms
#>   term token_count_a token_count_b
#> 1  cat             1             1
#> 2  run             1             1
```
