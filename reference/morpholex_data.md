# Read the Bundled MorphoLex English Database

Reads the bundled MorphoLex-en worksheet values without downloading data
or requiring Excel, readxl, Python, or a model. This is a reference-data
reader, not a morphological analyzer.

## Usage

``` r
morpholex_data(sheets = NULL)
```

## Arguments

- sheets:

  `NULL` for all 34 worksheets, or a nonempty character vector of unique
  worksheet names in the desired order. Unknown names are errors.

## Value

A plain list with two components:

- `sheets`:

  Named data frames, one per selected worksheet. All columns are
  character; empty cells are `NA`. Numeric measures require explicit
  conversion with [`as.numeric()`](https://rdrr.io/r/base/numeric.html).
  IDs, case, spelling, sheet/row order, and cell whitespace are
  retained. The Presentation sheet uses generated column names; other
  sheets use the original header row.

- `provenance`:

  Resource ID/version, source URL/file and SHA-256, reference, data
  license and license URL, data-dictionary SHA-256, transformation
  ID/description, build-time readxl version, complete sheet catalog
  (`sheet`, `rows`, `columns`, `start_row`, `start_column`), and
  selected sheet names. Start positions are one-based Excel coordinates
  of the occupied region, including the header where present. The
  resource version is the original workbook SHA-256.

## Details

The snapshot contains 68,624 word records across 30 prefix-root-suffix
(PRS) sheets, 142 prefix rows, 240 suffix rows, 15,471 root rows, and
the Presentation sheet. These counts describe this snapshot, not
distinct spellings or a validated vocabulary-size scale. Differently
shaped sheets are kept separate. Word sheets retain `ELP_ItemID`,
`Word`, `POS`, `Nmorph`, `PRS_signature`, `MorphoLexSegm`, and all
available root/affix columns. The three aggregate sheets are named
`All prefixes`, `All suffixes`, and `All roots`.

Segmentation uses canonical morphemes and excludes inflection. For
example, `teachers` is represented with teach and -er, without plural
-s. Unlisted words do not have a known zero morpheme count. The six
entries on `0-0-0` retain the source's classification and are not
silently discarded. MorphoLex root/affix family sizes, cumulative HAL
frequencies, whole-word frequency, and counts in a user's corpus are
different quantities. The data do not establish learner knowledge,
synchronic transparency, or educational word-family membership.

All worksheet values are retained as text; workbook formatting and
formulas are not retained. Blank exterior margins are omitted. Numeric
and logical cells use R text representation; the source `Word` cells for
ELP IDs 42162 and 65908 are logical values and read as `TRUE` and
`FALSE`. Exact lowercase queries do not match these uppercase values. No
linguistic corrections or inferred parts are added. The bundled original
data dictionary describes the variables, including PFMF, family size,
HAL frequency, P, and P\*. Its path is shown in the examples. The
explicitly sourced `examples/morpholex-word-parts.R` recipe selects word
records and extracts supported canonical parts for the accompanying
word-parts recipe. That recipe is not an exported morphology API.

## License and attribution

MorphoLex-en data and the original data dictionary are distributed under
CC BY-NC-SA 4.0, not the MIT license of the independent ldfreq code. The
license permits noncommercial sharing and adaptation subject to
attribution, change notices, and the applicable ShareAlike conditions.
It does not grant commercial-use permission. See
<https://creativecommons.org/licenses/by-nc-sa/4.0/> and the installed
`licenses/morpholex/NOTICE.md` and `CC-BY-NC-SA-4.0.md`. Cite the
resource paper when using these data; package citation alone is not
resource attribution. Original authors do not endorse this R conversion.

## References

Sánchez-Gutiérrez, C. H., Mailhot, H., Deacon, S. H., and Wilson, M. A.
(2018). MorphoLex: A derivational morphological database for 70,000
English words. *Behavior Research Methods*, 50, 1568–1580.
[doi:10.3758/s13428-017-0981-8](https://doi.org/10.3758/s13428-017-0981-8)
.

## Source

<https://github.com/hugomailhot/MorphoLex-en>

## See also

[`bnccoca_data`](https://ryuya-dot-com.github.io/ldfreq/reference/bnccoca_data.md),
[Word families, roots and affixes
tutorial](https://ryuya-dot-com.github.io/ldfreq/articles/word-families-and-affixes.html).
The tutorial explains how to source the word-parts recipes; those
helpers are not exported package functions.

## Examples

``` r
# "0-1-1" is a source worksheet: zero prefixes, one root, one suffix.
reference <- morpholex_data(c("0-1-1", "All roots"))
words <- reference$sheets[["0-1-1"]]
words[words$Word %in% c("teacher", "teachers"),
      c("Word", "MorphoLexSegm", "ROOT1_FamSize", "ROOT1_Freq_HAL")]
#>          Word MorphoLexSegm ROOT1_FamSize ROOT1_Freq_HAL
#> 6247  teacher {(teach)}>er>             4          84480
#> 6248 teachers {(teach)}>er>             4          84480
# Both records contain teach and -er. Plural -s is outside this resource's scope.
roots <- reference$sheets[["All roots"]]
roots$HAL_freq <- as.numeric(roots$HAL_freq)
reference$provenance$data_license
#> [1] "CC BY-NC-SA 4.0"
dictionary_path <- system.file("extdata", "morpholex", "5bc425fb",
                               "MorphoLEX_en-Data_Dictionary.pdf", package = "ldfreq")
```
