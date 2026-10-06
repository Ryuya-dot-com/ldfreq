# Count resource-defined word families while retaining source occurrences

Matches complete imported annotations against a caller-supplied
word-family table. This experimental function retains original tokens,
candidate records, context, resource definitions, document counts and
unresolved occurrences. It runs no morphological analyzer. Use
[`bnccoca_data`](https://ryuya-dot-com.github.io/ldfreq/reference/bnccoca_data.md)
for the bundled Nation inventory or supply a differently defined table
explicitly.

## Usage

``` r
lexdiv_family_profile(annotations, dictionary, resource,
  unit = c("surface", "lemma", "flemma"),
  normalization = c("identity", "nfkc_lower"),
  exclude_pos = character(), context_chars = 30L,
  max_tokens = 1e6, max_candidates = 1e6, review = NULL)
```

## Arguments

- annotations:

  Unmodified
  [`lexdiv_import_annotations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md)
  result, including all source tokens and original segments before
  exclusions. Supplied `lemma`/`flemma` columns are required when
  selected. A `upos` column using UD tags is required for POS matching
  or exclusion. Missing annotations use character `NA`, never blank
  strings or underscores.

- dictionary:

  Plain data frame with character `record_id`, `form` and `family_id`.
  Record IDs must be unique and keys nonblank; family IDs may repeat. An
  optional `upos` column requires exact UD POS matching, without
  wildcards or missing values. Other columns (e.g., inclusion level,
  frequency band) are retained without determining assignment. Empty
  tables are allowed. Read CSV identifiers as character to preserve
  leading zeros.

- resource:

  Named list of nonblank character scalars. Required fields:
  `resource_id`, `resource_version`, `language`, `source_reference`,
  `data_license`, `family_definition`, `lookup_unit`. The last must
  equal `unit`. Specify the inclusion criteria and inventory version;
  license declarations do not grant rights.

- unit:

  Column used to match `dictionary$form`. No lemma or flemma is
  inferred. This chooses the lookup key, not the output counting unit.

- normalization:

  `identity` is exact and case-sensitive. `nfkc_lower` applies Unicode
  NFKC, trims whitespace and lowercases with English locale to both
  lookup keys. Original surfaces and IDs are unchanged. Normalized-key
  collisions retain all candidate families.

- exclude_pos:

  Unique UD tags to exclude explicitly, e.g., `c("PUNCT", "SYM")`.
  Default excludes nothing, including numerals and proper nouns. Missing
  POS makes selection unknown when exclusions are requested.

- context_chars:

  Non-negative whole number of Unicode codepoints on each side of a
  token, limited to its original segment.

- max_tokens:

  Positive whole-number input token row ceiling.

- max_candidates:

  Positive whole-number ceiling on dictionary rows and on expanded
  occurrence-by-record rows, checked before expanding candidates.
  Neither ceiling is a total memory or source-text size limit.

- review:

  Optional unmodified
  [`lexdiv_ambiguity_review`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ambiguity_review.md)
  result created using this profile's `annotations` and `review_input`.
  Decisions select dictionary `record_id` values, not family IDs.
  Source, complete table, resource declarations and counting policy must
  agree. Creating the single-token, whitespace-free surface review uses
  optional quanteda; applying an already saved review requires no
  quanteda calls. Default `NULL` uses lookup alone.

## Details

Only one distinct candidate family permits assignment. Multiple records
for that same family retain their record IDs but count as one family
candidate. Different families are `ambiguous`; absent keys are
`unlisted`. There is no first-record choice, identity fallback or
automatic sense selection. `review_input` prepares the existing
ambiguity-review interface. If its `targets` is empty, there are no
candidate-bearing forms to review. Its display lists the union of
candidate records for each original surface; `candidates` retains exact
eligibility by occurrence, selected unit and POS. A record eligible only
for another occurrence cannot be selected here.

Explicit `selected` judgments assign the chosen record's family to that
occurrence only. Explicit `unresolved` judgments withhold any automatic
assignment: a previously matched occurrence becomes `review_unresolved`.
Unreviewed occurrences retain their lookup result. Occurrences without
eligible candidates, POS-excluded or unknown-selection occurrences
cannot be assigned a candidate by override. Changing annotations,
dictionary contents or order, resource declarations, lookup unit,
normalization or exclusions requires a new review snapshot. Changing
context display widths does not. Snapshots detect inconsistent reuse,
not whether the reviewer's linguistic judgment is correct.

Selection is evaluated first: known excluded POS is `excluded`; missing
POS with exclusions is `unknown_selection`. Remaining occurrences may be
`missing_unit`, `missing_pos` (known unit but POS needed for lookup),
`unlisted`, `ambiguous` or `matched`. A manual veto can add
`review_unresolved`. No source row is removed.

`token_coverage` is matched tokens divided by selected tokens. It is
undefined when selection is unknown or the denominator is zero.
`conditional_token_coverage` uses only known-selected tokens; report
`unknown_selection_tokens` beside it. `observed_family_types` counts
families assigned among matched tokens. `family_types` and `family_ttr`
are `NA` if any non-excluded occurrence is unresolved; otherwise TTR is
family types divided by selected tokens. Empty or fully excluded
documents have zero family types and undefined TTR and coverage. The
pooled `summary` is not the mean of document-level metrics. Counts and
coverage describe final assignments, including explicit selections;
`lookup_status`/`lookup_family_id` preserve the automatic result.

If an inventory places *use* and *reusability* together, these remain
two tokens with one family type. This is not evidence that a learner
knows both words, that any particular inventory includes them together,
or that derivational morphology has been analyzed. Flemma, lemma and
family definitions are distinct. Inclusion levels and frequency bands
are not interchangeable. For other diversity measures, pass the ordered
family IDs from complete documents to
[`lexdiv_metrics`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md).
Never drop unresolved tokens to close gaps for MATTR; declare any
POS-selected sequence explicitly.

## Value

A plain list containing:

- `occurrences`: all source IDs, selected unit, surface, Unicode
  positions, query, selection, status, candidate counts, assigned family
  and `pre`/`keyword`/`post` context. Also retains `lookup_status`,
  `lookup_family_id`, `review_status`, `review_record_id`, `reviewer`
  and `reason`.

- `candidates`: occurrence IDs and matching record IDs, forms, family
  IDs and optional POS. Join extra metadata by `record_id`.

- `members`: matched counts `n` by document, family, original surface
  and normalized query. Repeated tokens are not collapsed in
  occurrences.

- `documents` and `summary`: total, excluded, known-selected,
  unknown-selection, selected, matched and unresolved token counts;
  separate unlisted, ambiguous, missing-unit, missing-POS and
  `withheld_tokens` (previous matches withheld by explicit unresolved
  judgments); both coverage measures; observed and complete family
  types; family TTR and status. Status is `empty`, `no_selected_tokens`,
  `incomplete` or `complete`. `review_selected_tokens` and
  `review_unresolved_tokens` count explicit judgments; the latter may
  also include already ambiguous occurrences.

- `review_input`: `targets`, `candidates` and `resource` arguments for
  [`lexdiv_ambiguity_review()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ambiguity_review.md).
  Candidate IDs are record IDs; labels/family IDs and optional POS
  remain in the display. The generated `family_profile_sha256` binds
  review to the analysis snapshot.

- `review`: the complete supplied review, or `NULL`.

- Complete `annotations`, `dictionary`, and `provenance` with resource
  declarations, unit, normalization, selection, coordinates, method
  version, dictionary hash and complete-result hash.

Use composite document/segment/token IDs to join occurrences, not row
numbers. Save the complete result as RDS to retain inputs and policies
for replay.

## References

Bauer, L., and Nation, P. (1993). Word families. *International Journal
of Lexicography*, 6(4), 253–279.
[doi:10.1093/ijl/6.4.253](https://doi.org/10.1093/ijl/6.4.253) .

## See also

[`lexdiv_import_annotations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md),
[`lexdiv_flemmatize`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_flemmatize.md),
[`lexdiv_metrics`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md),
[`lexdiv_compare_ambiguity`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_compare_ambiguity.md)

## Examples

``` r
env <- new.env(parent = baseenv())
sys.source(system.file("examples", "word-families.R", package = "ldfreq",
  mustWork = TRUE), env)
x <- env$word_families_example
x$profile$documents
#>   document_id tokens excluded_tokens known_selected_tokens
#> 1    complete      5               1                     4
#> 2  unresolved      3               1                     2
#> 3       empty      0               0                     0
#>   unknown_selection_tokens selected_tokens matched_tokens unlisted_tokens
#> 1                        0               4              4               0
#> 2                        0               2              0               1
#> 3                        0               0              0               0
#>   ambiguous_tokens missing_unit_tokens missing_pos_tokens withheld_tokens
#> 1                0                   0                  0               0
#> 2                1                   0                  0               0
#> 3                0                   0                  0               0
#>   unresolved_tokens review_selected_tokens review_unresolved_tokens
#> 1                 0                      0                        0
#> 2                 2                      0                        0
#> 3                 0                      0                        0
#>   conditional_token_coverage token_coverage observed_family_types family_types
#> 1                          1              1                     1            1
#> 2                          0              0                     0           NA
#> 3                         NA             NA                     0            0
#>   family_ttr     status
#> 1       0.25   complete
#> 2         NA incomplete
#> 3         NA      empty
x$profile$members
#>   document_id family_id     surface       query n
#> 1    complete       USE         use         use 2
#> 2    complete       USE        uses        uses 1
#> 3    complete       USE reusability reusability 1
x$profile$occurrences[c("document_id", "keyword", "status", "family_id")]
#>   document_id     keyword    status family_id
#> 1    complete         use   matched       USE
#> 2    complete        uses   matched       USE
#> 3    complete reusability   matched       USE
#> 4    complete         use   matched       USE
#> 5    complete           .  excluded      <NA>
#> 6  unresolved        bank ambiguous      <NA>
#> 7  unresolved        quux  unlisted      <NA>
#> 8  unresolved           .  excluded      <NA>
x$comparison
#>      unit metric_id     value N V
#> 1 surface       ttr 0.7500000 4 3
#> 2 surface     mattr 1.0000000 4 3
#> 3   lemma       ttr 0.5000000 4 2
#> 4   lemma     mattr 0.6666667 4 2
#> 5  flemma       ttr 0.5000000 4 2
#> 6  flemma     mattr 0.6666667 4 2
#> 7  family       ttr 0.2500000 4 1
#> 8  family     mattr 0.3333333 4 1
if (requireNamespace("quanteda", quietly = TRUE)) {
  sys.source(system.file("examples", "word-family-review.R", package = "ldfreq",
    mustWork = TRUE), env)
  env$word_family_review_example$reviewed$documents
}
#>   document_id tokens excluded_tokens known_selected_tokens
#> 1     example     10               2                     8
#> 2       empty      0               0                     0
#>   unknown_selection_tokens selected_tokens matched_tokens unlisted_tokens
#> 1                        0               8              8               0
#> 2                        0               0              0               0
#>   ambiguous_tokens missing_unit_tokens missing_pos_tokens withheld_tokens
#> 1                0                   0                  0               0
#> 2                0                   0                  0               0
#>   unresolved_tokens review_selected_tokens review_unresolved_tokens
#> 1                 0                      2                        0
#> 2                 0                      0                        0
#>   conditional_token_coverage token_coverage observed_family_types family_types
#> 1                          1              1                     7            7
#> 2                         NA             NA                     0            0
#>   family_ttr   status
#> 1      0.875 complete
#> 2         NA    empty
```
