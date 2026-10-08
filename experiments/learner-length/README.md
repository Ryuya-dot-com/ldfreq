# A reproducible learner-text length example: PELIC

This example asks how TTR, MATTR (window 50) and current MTLD co-vary with
analyzed token count within one observed writing prompt. It illustrates an
analysis researchers can repeat; it does not establish reliability, causal
length effects, or an optimal index.

## Data, selection and rights

Source: Juffs, A., Han, N.-R., & Naismith, B. (2020), *The University of
Pittsburgh English Language Institute Corpus (PELIC)*,
[version 1.0](https://doi.org/10.5281/zenodo.3991977).
We pin upstream commit `853e9e545cc7a78a70839c68e8ed293cc7ed9c2c` and verify all
three original CSVs against their Git LFS SHA-256 identities.

The [upstream README's license](https://github.com/ELI-Data-Mining-Group/PELIC-dataset/tree/853e9e545cc7a78a70839c68e8ed293cc7ed9c2c#10-license)
is CC BY-NC-ND 4.0; Zenodo's v1.0 metadata instead lists CC BY-ND 4.0. This
noncommercial research example follows the upstream noncommercial condition.
Neither original nor transformed corpus texts/token sequences are distributed
in ldfreq. Downloading is explicit, into a caller-selected local cache; it is
never part of package installation, tests, or vignette building. The numeric
aggregates and analysis code here do not replace the corpus's access terms.

Before examining metric values, select original responses (`version = 1`) in
writing courses (`class_id = w`) to essay tasks (`question_type_id = 4`). Choose
the prompt with the most distinct writers, resolving ties by smallest numeric
question ID. Retain the smallest answer ID per writer within that prompt. This
selects prompt 3042, 16 writers, all at recorded course level 3. The task asks for a short how-to essay with an introduction, body and conclusion;
writers choose their content. No length or metric-value threshold determines this selection. Course level is contextual
metadata, not a calibrated proficiency score.

Use the raw `text` field, not the provided NLTK tokens or `text_len`. Tokenize
with ldfreq's English tokenizer, NFC normalization, lowercase surface forms,
and numbers excluded. Retain learners' spelling and grammatical forms. No
lemmatization, correction, attested-word filtering or content-word selection
is applied. The resulting length range is 70–314 tokens; all 16 have finite
scores for all three requested metrics.

## Executed results

| Metric | Pearson with N | Spearman with N | Paired / excluded |
|---|---:|---:|---:|
| TTR | -0.6500 | -0.6814 | 16 / 0 |
| MATTR, window 50 | 0.4173 | 0.4294 | 16 / 0 |
| MTLD, threshold < 0.72, no minimum | 0.3834 | 0.2500 | 16 / 0 |

No MTLD direction is tail-only here. The directional gap has median 8.54% and
maximum 47.08% (absolute directional difference / directional mean). A lack of
tail-only flags does not validate these estimates. The sample is small, from
one prompt and course level. Length can still co-vary with writer and content;
these correlations do not isolate a causal effect of length. No p-values or
population ranking of metrics are inferred.

`prefixes.csv` additionally holds the **same three** texts of at least 200
tokens fixed while using their first 50, 100, 150 and 200 tokens. For example,
median TTR changes from 0.700 to 0.515; median MATTR from 0.700 to 0.761. A
prefix comparison also changes the included content and discourse position.
With only three eligible texts it demonstrates the calculation, not a
population stability result. Prefixes overlap and are not independent samples.

## Reproduce

Install ldfreq's development dependencies (`pkgload`, `jsonlite`, plus package
imports). From a checkout, run:

```sh
Rscript experiments/learner-length/run.R . /path/to/local-pelic-cache /path/to/results
```

The first run downloads about 182 MB; verified original files are reused on
later runs. Keep `analysis-local.rds` in the cache private: it contains texts
and token sequences. Only the four small files under `results/` are published.
The script executes the same diagnostic/correlation helpers as the existing
[comparison guide](https://ryuya-dot-com.github.io/ldfreq/articles/designing-comparisons.html).

The earlier [ICNALE GRA V2.1 migration](../mtld-migration/README.md) already
used 136 actual L2 originals and four ENS texts. That was an empirical
migration check with local, non-redistributable data; it did not supply a
public raw-data reproduction or establish psychometric validity. PELIC
addresses the public reproduction gap without distributing another corpus.
