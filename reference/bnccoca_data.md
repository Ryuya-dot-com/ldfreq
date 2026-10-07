# Read Nation's BNC/COCA Level 6 Word-Family Lists

Reads an offline snapshot of Nation's BNC/COCA Level 6 lists, Version
1.0.0, with original source membership, spelling and attribution. No
model, download or additional package is needed. These data use CC BY-SA
4.0.

## Usage

``` r
bnccoca_data()
```

## Value

A plain list with five components:

- dictionary:

  75,679 rows representing 25,000 families in frequency/range bands
  1–25. Each row includes character `record_id`, `form`, `family_id`,
  `headword`, `list_type`, `source_file` and `range_flag`; integer
  `frequency_band` and `source_line`; and logical `is_headword`.
  Headwords are included as records.

- supplementary:

  29,798 rows with the same columns from lists 31–34: proper names,
  marginal words, transparent compounds and acronyms. Their
  `frequency_band` is `NA`. They are kept separate from the dictionary.

- catalog:

  Names, SHA-256 hashes, row counts, source family counts, list types
  and inclusion flags for all 34 list files. Slots 26–30 are
  placeholders, excluded from both analysis tables.

- resource:

  Scalar declarations suitable for
  [`lexdiv_family_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_family_profile.md)
  with `dictionary`: citation, version, language, family definition,
  lookup unit, source and CC BY-SA 4.0 license.

- provenance:

  Archive URL and SHA-256, retrieval date, terms and information URLs,
  transformation identifier and description. Save the whole list to
  retain the supplementary-list and conversion information.

## Details

Family membership follows source headwords and indented members. IDs are
scoped to the fixed snapshot and derive from source list/line positions.
Spellings remain uppercase as supplied; choose
`normalization = "nfkc_lower"` explicitly when matching lower-case text.
The final Range field `0` is retained as `range_flag`; it is not a
frequency count. No POS tags, senses or morphological analyses are
inferred.

Bauer–Nation inclusion Level 6 is distinct from frequency/range bands
1–25. No row-level affix inclusion level is supplied. The Level 3
partial lists are a separate inventory, not a subset obtained by
selecting frequency bands. The bands reflect frequency, range and
pedagogical decisions, not a raw corpus frequency ranking. A reference
match does not establish learner knowledge.

For example, this snapshot groups USE/USES and COLOUR/COLOR, but
REUSABILITY is unlisted. Do not silently assign it to USE from an
authored illustration. Supplementary membership does not perform
contextual named-entity recognition. If combining supplementary and core
tables, declare the resulting scope in the resource metadata and examine
conflicting candidates. The default example uses only `dictionary`.

The data and this conversion are CC BY-SA 4.0; independent R code
remains MIT. Retain attribution, changes and ShareAlike conditions when
redistributing the data. The complete license and notice are installed
under `licenses/bnccoca/`. Other bundled resources have separate terms.

## References

Nation, I. S. P. (2017). The BNC/COCA Level 6 word family lists (Version
1.0.0) \[Data file\]. Victoria University of Wellington.
<https://www.wgtn.ac.nz/lals/resources/paul-nations-resources/vocabulary-analysis-programs>

Bauer, L., and Nation, P. (1993). Word families. International Journal
of Lexicography, 6(4), 253–279.
[doi:10.1093/ijl/6.4.253](https://doi.org/10.1093/ijl/6.4.253)

## See also

[`lexdiv_family_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_family_profile.md)
for a complete token-to-family example,
[`morpholex_data`](https://ryuya-dot-com.github.io/ldfreq/reference/morpholex_data.md),
[Word families, roots and affixes
tutorial](https://ryuya-dot-com.github.io/ldfreq/articles/word-families-and-affixes.html)

## Examples

``` r
reference <- bnccoca_data()
# The dictionary maps forms to families; it is not a table of corpus counts.
reference$dictionary[reference$dictionary$form %in%
  c("USE", "USES", "REUSABILITY", "COLOUR", "COLOR"),
  c("form", "headword", "frequency_band")]
#>        form headword frequency_band
#> 998  COLOUR   COLOUR              1
#> 999   COLOR   COLOUR              1
#> 6348    USE      USE              1
#> 6374   USES      USE              1
# USE/USES share a headword; COLOUR/COLOR share another. REUSABILITY has no row.

# A longer installed workflow; the direct API example is in ?lexdiv_family_profile.
env <- new.env(parent = baseenv())
sys.source(system.file("examples", "bnccoca-families.R", package = "ldfreq",
  mustWork = TRUE), env)
profile <- env$bnccoca_example$profile
profile$documents[c("document_id", "selected_tokens", "matched_tokens",
  "unresolved_tokens", "family_types", "family_ttr", "status")]
#>   document_id selected_tokens matched_tokens unresolved_tokens family_types
#> 1      listed               4              4                 0            2
#> 2    unlisted               2              1                 1           NA
#>   family_ttr     status
#> 1        0.5   complete
#> 2         NA incomplete
```
