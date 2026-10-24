# Length sensitivity and sampling reliability in learner essays

The [metric-selection guide](https://ryuya-dot-com.github.io/ldfreq/articles/choosing-metrics.html)
explains the results and their practical implications. `PROTOCOL.md` specifies
the corpus selection, estimands, sampling and uncertainty calculations.
`results/` contains aggregate statistics and source identities. It contains no
learner text, token streams, author IDs or individual essay scores.

## Obtain the corpus separately

Use PELIC v1.0, [DOI 10.5281/zenodo.3991977](https://doi.org/10.5281/zenodo.3991977),
Git revision `853e9e545cc7a78a70839c68e8ed293cc7ed9c2c` of
[ELI-Data-Mining-Group/PELIC-dataset](https://github.com/ELI-Data-Mining-Group/PELIC-dataset/tree/853e9e545cc7a78a70839c68e8ed293cc7ed9c2c).
The repository labels the corpus CC BY-NC-ND 4.0; the Zenodo record displays
CC BY-ND 4.0. This analysis follows the more restrictive repository conditions
for academic research and does not redistribute the corpus or tokenized text.
Review the source terms before obtaining or reusing the data, including for
commercial research. The package's MIT license does not license this corpus.

Download `corpus_files/answer.csv`, `corpus_files/course.csv` and `corpus_files/question.csv` from that
revision into a private directory outside this repository. Git LFS files must
be downloaded as actual data, not small pointer files. `prepare.R` checks
all three SHA-256 hashes before reading. The complete files are about 182 MB;
this is a separate research reproduction, not a package installation step.

## Reproduce

From the package repository root, set `PRIVATE_CACHE` to that directory and
`RESULTS` to a new output directory. Scripts make no network requests. Install
the package's dependencies plus `pkgload`, `jsonlite`, `koRpus` 0.13-9 and
`koRpus.lang.en` 0.1-4 for the external comparison. The recorded run used R 4.6.1.

```sh
Rscript experiments/corpus-stability/prepare.R . "$PRIVATE_CACHE"
Rscript experiments/corpus-stability/compute.R . "$PRIVATE_CACHE"
Rscript experiments/corpus-stability/summarize.R "$PRIVATE_CACHE" "$RESULTS"
Rscript experiments/corpus-stability/external.R . "$PRIVATE_CACHE" "$RESULTS"
Rscript experiments/corpus-stability/check-and-distributions.R . "$PRIVATE_CACHE" "$RESULTS"
```

`compute.R` saves completed document results every 100 documents and resumes
only when input, preparation, protocol and metric-source hashes match. Keep
`prepared-private.rds`, `metrics-private.rds` and `external-private.rds` private.
The independent check verifies block sampling, recomputes all 48 ICC point
estimates through ANOVA, and compares a spread of saved scores with current
code. It derives distribution summaries without repeating the metric runs or
2,000 writer-cluster bootstrap replicates.

## Read the outputs

- `block-summaries.csv`, `block-densities.csv`, `block-quantiles.csv`: original
  scores at 50, 100, 150 and 200 tokens, including computable/missing counts.
  Density estimates share bandwidth and range within each measure.
- `paired-length-change.csv`: paired 200-minus-50 changes with intervals;
  this diagnostic table is distinct from the original-scale distributions.
- `sampling-reliability.csv`: single-block ICC(1,1), rank correlations, complete
  pairs and writer-cluster bootstrap intervals. These are within-essay sampling
  estimates, not test–retest reliability or proficiency validity.
- `full-length-associations.csv`: descriptive full-essay length correlations;
  writer, prompt and instructional differences may contribute.
- `external-comparison.csv`: actual koRpus comparisons with verified identical
  ordered tokens. Two essays lack MTLD-MA values in both implementations.
- `provenance.json` and `external-provenance.json`: data/code identities,
  versions, settings and sample counts for the recorded computations.

The original run recorded hashes for API dispatch, MTLD and expected-TTR D.
Those original identities are retained. Final-code comparison hashes cover all
R sources and the prepared token cache separately; new runs bind checkpoints
to this complete source set. The core basic/HD-D/Yule implementations did not
change from the preceding release. Reproduction
from a different version creates a new run; it does not rewrite the identity of
these saved results. Agreement of implementations and score stability answer
different questions, both discussed in the selection guide.
