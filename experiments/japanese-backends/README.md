# Japanese backend experiment

These experiments connect Sudachi and MeCab output to the
[Japanese annotation workflow](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-annotations.html).
These scripts are available in this repository, but are not installed with the
R package or rendered as website articles. They add no
runtime dependency or exported function. Tested on macOS arm64, Python 3.14 and
R 4.6; this is not a claim of cross-platform support or linguistic accuracy.

The question is whether existing Japanese analyzers can feed ldfreq's source
alignment, KWIC decisions and document counts without losing original writing.
The external analyzers perform analysis; ldfreq imports and checks positions, aligns alternative
annotations, reviews occurrences using quanteda, and calculates N/V/TTR.
No analyzer or lexical-diversity formula is reimplemented here.

## Run

From the repository root, with ldfreq, jsonlite and quanteda already installed:

```sh
python3 -m venv /tmp/ldfreq-sudachi-venv
/tmp/ldfreq-sudachi-venv/bin/python -m pip install \
  'SudachiPy==0.6.11' 'SudachiDict-core==20260428'
Rscript experiments/japanese-backends/validate-import.R \
  /tmp/ldfreq-sudachi-venv/bin/python /tmp/ldfreq-sudachi-results
```

Install the explicitly requested packages only when needed. The R script and
exporter themselves do not install packages or access the network. This
experiment pins an API/dictionary pair from before the 0.7 dictionary-format
transition; it does not test the latest version. Pass the venv executable itself,
not its resolved symlink to the base interpreter.

The runner creates eight authored documents (nine segments), compares A/B/C,
tests empty documents, whitespace, repeated forms, emoji, decomposed kana,
fullwidth Latin letters and ellipses, applies authored fruit decisions, and
checks RDS reload. Invalid positions, normalized replacement surfaces, duplicate
token indices and decisions from a different segmentation are rejected.

An optional third argument accepts a previously saved local analysis RDS with
`$annotations` from `lexdiv_import_annotations()`. It uses exactly those original
segments, including titles, and retains private texts/contexts only in the
specified output directory, which must be outside the repository. It does not
download or redistribute corpus material. The previous annotations are a
comparator, not a gold standard. Only aggregate counts are printed.

## Data and interpretation

`sudachi-export.py INPUT.json OUTPUT.json --mode A` also works separately.
The input is a UTF-8 JSON array of records with string `document_id`, `segment_id`
and `text`. The output retains those segments, token features, dictionary and
configuration hashes, and the analyzer version. Text and surface are unchanged;
Sudachi's internal normalization plugins remain active. `dictionary_form`,
`normalized_form` and `reading_form` are separate features, not automatic human
decisions, UniDic `orthBase`, or a universal lexical identity. OOV is a dictionary
property, not a spelling-error diagnosis. A/B/C are not assumed to be NINJAL
short/long units.

After the run, inspect the saved results entirely in R:

```r
result <- readRDS("/tmp/ldfreq-sudachi-results/authored-local.rds")
subset(result$counts, document_id == "compound")  # N: A = 3, B = 2, C = 1
result$alignment$review_queue                    # Changed spans with context
result$review$occurrences                        # Selected / no-candidate rows
result$exports$A$zero_width_tokens               # Retained analyzer-only rows
```

One original `…` can yield three analyzer dots, two with empty original surface.
Such zero-width auxiliary-symbol rows remain in `zero_width_tokens`, with their
original `analyzer_token_index`. Only source-anchored rows go into the existing
import API; their consecutive `token_index` is distinct from analyzer indexing.
This source projection is explicit and does not weaken the importer's checks.
Other zero-width rows are rejected: the authored `㍿` example produces lexical
components that cannot be assigned disjoint original spans. General many-to-one
normalization alignment remains unsupported. Do not silently drop those rows or
claim support for arbitrary Unicode input.

Document tables distinguish `analyzer_N`, `zero_width_N`, `source_N`, `excluded_N`
and selected `N`. The declared selection excludes POS1 `空白`/`補助記号` and whitespace;
it retains particles and auxiliaries. Type counts for surface, dictionary form
and normalized form use the same selected rows. Empty-input TTR remains missing.
TTR here illustrates the pipeline, not a recommended proficiency measure.
`authored-local.rds` and optional `corpus-local.rds` retain the imported objects,
complete JSON exports including zero-width audit rows, counts and comparisons;
the authored RDS also retains KWIC decisions. Alignment queues retain original
context before any selection, so removing punctuation from document counts does
not create new adjacencies for concordances or n-grams.

## Confirmed scope (2026-10-07)

Authored checks and a local diagnostic run on 28 previously saved Japanese essays
passed. Selected token totals were A = 9,493, B = 9,349 and C = 9,329. Each mode
retained six zero-width symbol rows separately. This confirms source-position,
counting and persistence behavior under the declared versions/settings, not
segmentation accuracy, L2 proficiency validity or representativeness.
An additional R-only session reimported the saved exports and independently
checked N/V/TTR arithmetic for all 24 authored and 84 corpus document-mode rows.

GiNZA, KWJA, UDPipe Japanese models and reticulate integration are not tested by
this experiment. Support for another analyzer requires checking its original-text
alignment, feature meanings and saved-output replay separately. No corpus or
analyzer dictionary is bundled by this prototype.

## Same-dictionary R/Python comparison (2026-10-14)

`compare-mecab.R` runs the gibasa helper directly from the Japanese annotation
guide and compares it with `fugashi-parity.py`. This is a bounded interoperability
experiment, not a supported fugashi adapter or an accuracy benchmark.

From the repository root, with ldfreq, gibasa, jsonlite, digest and stringi
installed in R, and fugashi installed for the supplied Python executable:

```sh
Rscript experiments/japanese-backends/compare-mecab.R \
  /path/to/python /path/to/unidic_lite/dicdir /tmp/ldfreq-mecab-comparison
```

Use **unidic-lite 1.0.8 (based on UniDic 2.1.2)** with its 26-field binary schema.
The dictionary identity is supplied by the caller; the script records hashes
and verifies that both interfaces use the same files, rather than identifying
an arbitrary dictionary. Dictionary/configuration paths must contain no
whitespace for this limited recipe. An existing `~/.mecabrc` is preserved and
used by both paths; otherwise both use empty configuration files. A configuration
activating another dictionary fails the checks. There is no automatic sentence
splitting, user dictionary or requested input normalization.

Confirmed with **gibasa 1.1.3, fugashi 1.5.2, ldfreq 0.3.0.9007, R 4.6.1,
Python 3.14.3, macOS arm64**:

- 16 authored inputs, including compounds, inflections, suffixes, variant
  spellings, unknown forms, whitespace, CRLF, combining marks, fullwidth
  characters, emoji, ellipses, compatibility characters and empty input.
- All 87 analyzer rows have identical surfaces and raw feature strings.
  POS1 and orthBase also agree after explicitly mapping missing fields.
- Both imported outputs preserve the original text and agree on codepoint
  positions, independently calculated in Python from MeCab nodes.
- All 32 surface/orthBase N/V/TTR rows agree with independent Python arithmetic;
  empty TTR remains missing. Complete RDS objects survive save/reload unchanged.

`mecab-parity-summary.json` records versions and dictionary/configuration hashes;
`mecab-parity-counts.csv` contains only authored-input counts. Running the scripts
also saves the inputs, complete fugashi output and imported RDS locally.
This confirms agreement for these inputs/settings, not identical MeCab builds,
all inputs, other operating systems, dictionary versions, or other wrappers.
The older dictionary is a reproducible integration fixture, not a recommendation
that it best represents every contemporary Japanese corpus.

The selection excludes auxiliary symbols and tokens containing whitespace,
retains particles/auxiliaries, and excludes missing orthBase only in the base
condition. Consequently the N values of the two conditions can differ. Compare
the same occurrence population when attributing a score change to lexical unit
alone, and report missingness/coverage separately. Unknown flags are supplied
by fugashi; they are not inferred from gibasa's missing bases.

Different segmentation is a separate comparison: the previously saved
[unit sensitivity experiment](../japanese-units/README.md) found changed scores
for Sudachi A/C on 24 of 28 essays. Agreement between two MeCab wrappers with the
same dictionary does not imply agreement with Sudachi, nor does either establish
linguistic correctness or learner proficiency validity.
