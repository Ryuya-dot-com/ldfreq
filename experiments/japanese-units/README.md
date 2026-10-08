# Japanese word units: a paired sensitivity example

Two questions require different evidence. How does a published short/long-unit
annotation change counts for the same Japanese sentence? Separately, how much
do scores change across an analyzer's modes on actual learner essays? Neither
question establishes which unit best measures proficiency or score precision.

## Paired public annotations

We use **all 543 test sentences** from UD Japanese GSD and GSDLUW **r2.18**.
The split and release were fixed before inspecting lexical scores. The two
commits, source hashes and settings are in [provenance.json](provenance.json).
The [GSDLUW annotation description](https://github.com/UniversalDependencies/UD_Japanese-GSDLUW/blob/71fd68633ab8c3439a48db3f3718c9ed80be9c6c/README.md)
specifies manual SUW/LUW/bunsetsu layers following BCCWJ; LUW supplies its UD
tokens. These are news/blog sentences, **not learner essays**. See also
[NINJAL's unit descriptions](https://clrd.ninjal.ac.jp/bccwj/morphology.html).

Both inputs have the same sentence IDs, parallel IDs and exact original text.
All surfaces align to that text, with no omitted non-whitespace character.
`lexdiv_align_annotations()` finds 8,485 exact groups and 1,943 SUW-split/LUW-merged
groups, with no unmatched/crossing group. No analyzer was run. Using original
FORM strings avoids adding lemma normalization as another condition.

The primary **all-token** condition isolates boundaries over the same covered
non-whitespace characters; it includes punctuation and is not a recommended
lexical-selection policy. Its sentence medians are:

| Quantity | SUW | LUW |
| --- | ---: | ---: |
| N | 21 | 17 |
| V | 19 | 16 |
| TTR | 0.9130 | 0.9259 |

TTR changes in 370/543 sentences; paired Spearman rho = 0.9047. Unit-dependent
N and V change the index without any change in the writer or original sentence.
This does not show that longer units indicate better vocabulary.

The second condition excludes UPOS `PUNCT` and `SYM` separately in each
annotation. In **54/543 sentences**, the remaining character coverage differs:
a symbol that stands alone in SUW can be part of a retained LUW, and POS labels
can differ across units. Thus identical filter code does not guarantee an
identical lexical target. All 543 are retained in the records. A separate
same-coverage subset contains 489 sentences, with TTR changes in 317 and rho
= 0.8781. It is an explicitly selected subset, not a replacement population.

## Short sentences expose eligibility and factor-support differences

MATTR uses the same **50-token window** in each unit. This holds the parameter
fixed, not the amount of original text inside the window. With all tokens,
MATTR is computable for 29 SUW sentences but only 10 LUW sentences; its paired
comparison therefore has just 10 cases. Do not compare condition medians
computed on different eligible samples as if they were a paired effect.

MTLD uses threshold .72, strict `<`, no minimum factor length, linear tail
credit and the mean of forward/reverse scores. All-token MTLD is finite in
384 SUW and 346 LUW sentences. Of those, **352/384 SUW and 331/346 LUW** have
no complete factor in at least one direction. The remaining 159 SUW and 197
LUW results are missing, not zero. The CSV retains status, missing reason,
length flag, tail-only flag and directional gap. We report these calculations
to expose short-input limitations, not to recommend sentence MTLD. We never
join unrelated sentences to reach a token threshold. The 50-token advisory
floor has not been validated as a Japanese precision threshold.

## Separate learner-essay check: saved Sudachi modes

The optional fourth argument reuses the already saved **28 NINJAL learner
essays** from the [backend pilot](../japanese-backends/README.md). It does not
download or redistribute that corpus. The original spans, including titles,
are unchanged; POS1 whitespace/auxiliary symbols are excluded, while particles,
auxiliaries and numbers are retained. This uses surface forms, not normalized
or dictionary forms. SudachiPy 0.6.11 / SudachiDict-core 20260428 annotations
are reused; morphology is not rerun. Six zero-width symbol rows per mode remain
in the original audit and are not counted as anchored words.

| Quantity (document median) | A | B | C |
| --- | ---: | ---: | ---: |
| N | 333.5 | 323.5 | 323.0 |
| TTR | 0.4316 | 0.4330 | 0.4328 |
| MATTR50 | 0.7082 | 0.7061 | 0.7081 |
| MTLD | 43.9420 | 43.2880 | 43.6272 |

All 28 have finite values in all three modes (N = 147–619 across conditions).
A and C retain identical non-whitespace character coverage for all 28. N/V/TTR
exactly reproduce the previously saved counts. A-to-C paired comparisons:

| Metric | Changed / paired | Spearman rho | Median absolute change |
| --- | ---: | ---: | ---: |
| TTR | 24 / 28 | 0.9907 | 0.00280 |
| MATTR50 | 24 / 28 | 0.9880 | 0.00151 |
| MTLD | 24 / 28 | 0.9496 | 1.25808 |

No essay has a tail-only MTLD flag here. That does not validate precision or
the analysis units. High rank agreement does not make values interchangeable.
This is a small convenience pilot; no proficiency-group effect or universal
direction of change is inferred. **Sudachi C is not relabeled NINJAL LUW.**
The public paired annotations and this practical mode comparison answer
different questions; they are not pooled into one validation sample.

## Reproduce and inspect

From a repository checkout, with ldfreq's development dependencies installed:

```sh
Rscript experiments/japanese-units/run.R . /tmp/ldfreq-japanese-units /tmp/ldfreq-japanese-results
python3 experiments/japanese-units/verify.py /tmp/ldfreq-japanese-units /tmp/ldfreq-japanese-results
```

The R runner explicitly downloads about 5.3 MB once, checks SHA-256, rejects
unsupported CoNLL-U row IDs, imports complete annotations and then filters.
It is a reader for these fixed inputs, not a new general-purpose parser.
The Python check independently matches original codepoints and verifies all
6,516 metric-row N/V counts, 2,172 TTR values and 1,086 coverage decisions.
This validates correspondence and arithmetic, not measurement validity.

The optional fourth R argument is an existing `corpus-local.rds` from the
backend pilot. Private per-document values are saved only in the external
cache. Only aggregate Sudachi results and nontext provenance are published.
Without that argument, the public UD analysis is fully reproducible on its own.

Both UD inputs are **CC BY-SA 4.0**; attribution belongs to their contributors,
listed in the pinned upstream README files. The local cache retains both
README/license files. Corpus text and annotation tables are not bundled in
ldfreq. The derived UD result CSVs in this directory are distributed under
**CC BY-SA 4.0**, with this attribution and explicit transformation description;
the R/Python analysis code follows the package's MIT code license. This
repository experiment is excluded from the R package build.

Files: [sentence results](ud-sentence-metrics.csv), [coverage](coverage.csv),
[summary](ud-summary.csv), [paired results](ud-paired.csv),
[alignment](alignment.csv), [Sudachi summary](sudachi-summary.csv),
[Sudachi pairs](sudachi-paired.csv), [provenance](provenance.json).
