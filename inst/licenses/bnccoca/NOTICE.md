# Nation's BNC/COCA word-family lists

Creator: I. S. P. (Paul) Nation.

Citation: Nation, I. S. P. (2017). *The BNC/COCA Level 6 word family lists*
(Version 1.0.0) [Data file]. Victoria University of Wellington.

Source and explanation:
<https://www.wgtn.ac.nz/lals/resources/paul-nations-resources/vocabulary-analysis-programs>

## License and attribution

These data are redistributed under **CC BY-SA 4.0**. The official resource
page provides CC BY-SA 4.0 or GPL version 2 or 3, as appropriate to the
resource: <https://www.wgtn.ac.nz/lals/resources/paul-nations-resources>.
This conversion uses CC BY-SA 4.0 for the word-list data; it does not include
the Range software. The license permits sharing and adaptation, including
commercial use, subject to attribution, change notices and ShareAlike.
Retain the citation, source and license when sharing these data or adaptations.
The full terms, warranty disclaimer and limitations are in the adjacent
`CC-BY-SA-4.0.txt` and <https://creativecommons.org/licenses/by-sa/4.0/>.
The original author does not endorse this conversion or package.

Any copyright in this conversion is also offered under CC BY-SA 4.0.
The independent R code remains MIT licensed. Other bundled resources retain
their separate conditions, including MorphoLex's noncommercial condition.

## Snapshot and conversion

Retrieved 2026-10-06 from the official `BNC_COCA_25000.zip` download:
<https://www.wgtn.ac.nz/lals/resources/paul-nations-resources/vocabulary-analysis-programs/range/BNC_COCA_25000.zip>

Archive SHA-256:
`ac81c7a60e5c76cd2bbf0c59b0501808f0d4fa026b2936919dd54329a9bb6a69`.

Installed `extdata/bnccoca/ac81c7a6/bnccoca.rds` contains:

- All 75,679 headword/member rows in `basewrd1.txt` through `basewrd25.txt`,
  comprising 25,000 families; each list contains 1,000 families.
- A separate table of all 29,798 rows in `basewrd31.txt` through
  `basewrd34.txt`: proper names, marginal words, transparent compounds and
  acronyms. These lists are not extra frequency bands.
- A catalog of all 34 source list files with their hashes and row/headword
  counts. The five placeholder rows in slots 26--30 are excluded from the
  analysis tables. Executables and Range configuration are not included.

UTF-8 spellings, capitalization and source order are unchanged. Indentation
defines source family membership. Initial UTF-8 byte-order marks, where
present, are consumed as encoding markers, not included in the first word.
IDs derive from the list number and original
line number; headwords are included as records. The terminal Range field `0`
is preserved separately and is not a corpus frequency. No POS, senses, affix
analyses, missing members or spelling corrections are inferred. The R data
format and added ID/metadata columns are the changes to the original material.
Rebuild with `experiments/build-bnccoca.R` in the package repository.

The official explanation identifies these as Bauer--Nation Level 6 families.
This inclusion level differs from frequency bands 1--25. The Level 3 partial
lists are a different inventory and cannot be recovered by filtering this
snapshot by frequency band. Resource membership does not establish learner
knowledge, and unlisted forms are not assigned a new family.
