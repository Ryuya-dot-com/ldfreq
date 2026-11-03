# New JACET 8000: source, permission, and changes

Copyright belongs to the Japan Association of College English Teachers
(JACET). The rank/representative-lemma table is redistributed in `ldfreq`
with permission from JACET and with source attribution. It is not relicensed
under the MIT license used for the package's R code. Retain this attribution
and permission notice with the data; this statement does not assign a standard
open license or extend the permission to other JACET works.

## Required source attribution

大学英語教育学会基本語改訂特別委員会（編著）（2016）
『大学英語教育学会基本語リスト新JACET8000』東京：桐原書店。

JACET Basic Word Revision Committee (Ed.). (2016).
*The New JACET List of 8000 Basic Words*. Tokyo: Kirihara Shoten.

Official resource description: <https://language.sakura.ne.jp/s/voc.html>

## Bundled edition

Resource version: `jacet2016-8000-v1`. The file contains 8,000 rank/entry
pairs, checked against the official `新J8` sheet in `j8_2016.xlsx`.
It contains no translations, examples, or other companion lists.

The supplied 2023 CSV snapshot had 7,999 entries. Comparison with the official
workbook identified three corrections: restore `nan` at rank 6926, and restore
lowercase `true` at rank 326 and `false` at rank 2382. All other rank/entry
pairs were unchanged. CSV quoting and line endings were standardized to UTF-8
with LF line endings. The original supplied file was not modified.

All 8,000 bundled pairs agree with the official workbook. Parenthetical aliases
are expanded only during lookup when requested; they do not add ranked entries.
The source identities and transformation are recorded in
`extdata/nj8/2016/provenance.json`. Calculated levels use `ceiling(rank / 1000)`.
