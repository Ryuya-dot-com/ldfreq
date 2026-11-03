# MorphyNet example relations

Creators: Khuyagbaatar Batsuren, Gábor Bella, and Fausto Giunchiglia.

Citation: Batsuren, K., Bella, G., & Giunchiglia, F. (2021). MorphyNet: A Large
Multilingual Database of Derivational and Inflectional Morphology. In
*Proceedings of the 18th SIGMORPHON Workshop*, pp. 39–48.
<https://doi.org/10.18653/v1/2021.sigmorphon-1.5>

Source: <https://github.com/kbatsuren/MorphyNet>, including its README license
declaration. MorphyNet is derived from Wiktionary; see the paper and README
for the extraction methods and contributing language editions.

The selected data and any copyright in this selection/mapping retain
**CC BY-SA 3.0 Unported**. The adjacent `CC-BY-SA-3.0.txt` is the full legal
code, including warranty disclaimers and limitations:
<https://creativecommons.org/licenses/by-sa/3.0/>.
Retain attribution, license and change notices when sharing the material;
adaptations remain subject to the applicable ShareAlike terms. The authors
do not endorse this selection or package. The independent reader and authored
example code are MIT licensed; the data are not relicensed under MIT.

## Included excerpt and changes

The installed `extdata/morphynet-example/eng.derivational.example.tsv` contains
all nine English v1 incoming relations for teacher, transmitter, unhappiness,
reusability, retransmit and transmission. Its six data fields and source order
are unchanged. Selection is the change: the remaining source rows are omitted.
`source-rows.csv` maps each excerpt row to its original line number and full
file SHA-256. This is a teaching excerpt, not a vocabulary coverage inventory.
It must not be described as the complete MorphyNet database.

Original file: `eng/eng.derivational.v1.tsv`, retrieved 2026-10-06.
<https://github.com/kbatsuren/MorphyNet/blob/main/eng/eng.derivational.v1.tsv>
Original SHA-256:
`5920edacc1888b14464fc5cd96beea0a721221d56d1dc0e49de22f4c7c537c50`.

The reader adds source line numbers and relation IDs scoped to the supplied
file hash. Original POS symbols, including `U`, remain unchanged. In particular,
the source's `teach -> teacher` relation has N/N tags; the reader does not
silently replace these with an expected V/N analysis. The data contain
one-step relations, not complete segmentations, ordered derivation trees,
inflectional paradigms or Nation-style families. Multiple incoming relations
may coexist and must not simply be added as affix counts.
