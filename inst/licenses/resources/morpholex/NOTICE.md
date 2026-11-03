# MorphoLex-en data and documentation

Creators: Claudia H. Sánchez-Gutiérrez, Hugo Mailhot, S. Hélène Deacon,
and Maximiliano A. Wilson.

Source: <https://github.com/hugomailhot/MorphoLex-en>

Citation: Sánchez-Gutiérrez, C. H., Mailhot, H., Deacon, S. H., & Wilson,
M. A. (2018). MorphoLex: A derivational morphological database for 70,000
English words. *Behavior Research Methods, 50*, 1568–1580.
<https://doi.org/10.3758/s13428-017-0981-8>

## License

The MorphoLex-en material is licensed under **Creative Commons
Attribution-NonCommercial-ShareAlike 4.0 International (CC BY-NC-SA 4.0)**.
The upstream license is reproduced unchanged in `CC-BY-NC-SA-4.0.md` next to
this notice; see also <https://creativecommons.org/licenses/by-nc-sa/4.0/>.
It includes a disclaimer of warranties and limitation of liability.

This license permits noncommercial reproduction and sharing, and
noncommercial adaptations, subject to attribution, change notices and the
applicable ShareAlike conditions. It does not grant commercial-use permission.
The full license governs, including its exceptions and limitations. Cite the
resource and retain its terms when redistributing the data. The ldfreq MIT
license does not apply to these third-party data or their data dictionary.
The original authors do not endorse this conversion or package.

## Included material and conversion

Installed paths (prefixed with `inst/` in the source package):

- `extdata/morpholex/5bc425fb/morpholex_en.rds`: all 34 worksheet tables from
  `MorphoLEX_en.xlsx`, including 68,624 word records, the Presentation sheet,
  and the All prefixes, All suffixes and All roots sheets.
- `extdata/morpholex/5bc425fb/MorphoLEX_en-Data_Dictionary.pdf`: the unchanged
  original variable definitions.

The workbook was converted to named R data frames with character columns.
Empty cells are represented by NA; case and cell whitespace are retained.
The Presentation sheet has generated column names. Other sheets use their
original header row. Blank exterior margins are omitted: the Presentation
region starts at C2, the 0-1-0 region at D1, and all other regions at A1.
The sheet catalog retains these origins. Numeric and logical cells use R's
text representation. In particular, Word cells for ELP IDs 42162 and 65908
are logical values in the workbook and remain `TRUE` and `FALSE` in the R table.
Spreadsheet formatting and formulas are not preserved;
the stored cell values are used. No words, columns, or sheets were filtered,
and no morphological analyses were corrected or inferred. Source sheet/row
order is retained. An R provenance list records the source identity and
conversion. Any copyright in this data conversion is also offered under
CC BY-NC-SA 4.0. The independent conversion/reading code is MIT licensed.

Snapshot source checksums (SHA-256), obtained 2026-10-06:

- Workbook: `5bc425fbb710f3d63cab69e77ee731fa466653ed0ace94937cac6c1fd6de52c6`
- Data dictionary: `af01e0db5e953ad3b7bbc06ea06b3c8a1af6dac60e7600d826a5e079e4068575`
- Upstream license: `051131b5ef3596dad9bf0cffee19c248ff9751596a86b25c70f0cd82d6f6d713`

The package repository's `experiments/build-morpholex.R` reproduces the
conversion from these inputs and rejects different source checksums.
