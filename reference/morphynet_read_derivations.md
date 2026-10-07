# Read MorphyNet Derivational Relations from a Local File

Reads supplied source word, target word, source POS, target POS,
morpheme and prefix/suffix fields. Preserves alternative relations and
source identity for inspection and optional keyword-in-context review.
The complete English v1 file has been checked; the bundled nine-row
excerpt is only a teaching example.

## Usage

``` r
morphynet_read_derivations(path, language, resource_version, max_rows = 1e6)
```

## Arguments

- path:

  Local UTF-8 TSV file in the six-column MorphyNet derivational format,
  without a header. No download or external runtime is invoked.

- language:

  Nonblank character scalar declaring the language, e.g., `"en"`. This
  is supplied metadata, not automatic language detection.

- resource_version:

  Nonblank character scalar identifying the source version and any
  subset or modification, e.g., `"English v1"`.

- max_rows:

  Positive whole-number row ceiling, below the integer limit. The reader
  stops if more rows are present. This is not a byte or total-memory
  limit.

## Value

A plain list:

- relations:

  A data frame with character `relation_id`, integer `source_line`, and
  six unchanged character fields: `source_word`, `target_word`,
  `source_pos`, `target_pos`, `morpheme`, `affix_position`. Original
  ordering, duplicates and literal `NA` strings are retained. IDs
  include a shortened file hash and line number; their interpretation
  requires the complete source hash in the metadata.

- resource:

  Scalar declarations including language/version, full source SHA-256,
  citation, URLs, CC BY-SA 3.0 terms and derivational scope. Suitable
  for the `resource` argument of
  [`lexdiv_ambiguity_review`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ambiguity_review.md).

- provenance:

  Reader identity, row ceiling, observed rows, source hash,
  transformation and interpretation limits. No local path is recorded.

## Details

Use files obtained from the official MorphyNet repository under its CC
BY-SA 3.0 conditions. This reader validates the format, not the
linguistic accuracy, language/version declarations or authenticity of
arbitrary files. Missing, empty, invalid UTF-8, over-limit and malformed
files produce errors. The final column must be `prefix` or `suffix`; the
inflectional format is a different input and is rejected. An initial
UTF-8 BOM is consumed as an encoding marker. Field whitespace,
punctuation and POS symbols are not normalized.

The source uses symbols such as N, V, J, R and U; these are not silently
converted to Universal Dependencies tags. For example, its
teach-to-teacher row carries N/N, which should be inspected rather than
silently corrected. Full English v1 includes multiword fields; they are
retained. The existing ambiguity-review API supports single-token,
whitespace-free target surfaces, so a multiword target needs a
separately defined alignment method.

A relation is one formation step, not a complete root/affix
segmentation. Reusability has three incoming relations in this snapshot:
reuse with ability, reusable with ity, and usability with re. These need
not be mutually exclusive claims. Do not add them as three observed
affixes or treat graph connectivity as educational word-family
membership. Selecting one relation in a review records an explicitly
declared study analysis, not that other edges are false. An absent
target does not prove absence of morphology. This reader does not
lemmatize, infer inflections, predict learner knowledge or compute
productivity.

The full English file is obtained separately. Only nine attributed
example rows and their original line mapping are bundled, under
`extdata/morphynet-example/`. Resource and conversion terms are recorded
under `licenses/morphynet/`; the independent R code remains MIT.

## References

Batsuren, K., Bella, G., and Giunchiglia, F. (2021). MorphyNet: a Large
Multilingual Database of Derivational and Inflectional Morphology.
Proceedings of the 18th SIGMORPHON Workshop, 39–48.
[doi:10.18653/v1/2021.sigmorphon-1.5](https://doi.org/10.18653/v1/2021.sigmorphon-1.5)
<https://github.com/kbatsuren/MorphyNet>

## See also

[`lexdiv_ambiguity_review`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ambiguity_review.md),
[`morpholex_data`](https://ryuya-dot-com.github.io/ldfreq/reference/morpholex_data.md),
[`bnccoca_data`](https://ryuya-dot-com.github.io/ldfreq/reference/bnccoca_data.md),
[Word families, roots and affixes
tutorial](https://ryuya-dot-com.github.io/ldfreq/articles/word-families-and-affixes.html)

## Examples

``` r
path <- system.file("extdata", "morphynet-example", "eng.derivational.example.tsv",
  package = "ldfreq", mustWork = TRUE)
reference <- morphynet_read_derivations(path, language = "en",
  resource_version = "English v1; nine-row teaching excerpt")
reference$relations[reference$relations$target_word == "reusability", ]
#>                      relation_id source_line source_word target_word source_pos
#> 4 morphynet:d6aae849b1a0:0000004           4       reuse reusability          N
#> 6 morphynet:d6aae849b1a0:0000006           6    reusable reusability          J
#> 7 morphynet:d6aae849b1a0:0000007           7   usability reusability          N
#>   target_pos morpheme affix_position
#> 4          N  ability         suffix
#> 6          N      ity         suffix
#> 7          N       re         prefix
# Three incoming relations, not three counted affixes in one segmentation.
# For a complete, separately obtained English v1 file:
# reference <- morphynet_read_derivations("eng.derivational.v1.tsv", "en", "English v1")
```
