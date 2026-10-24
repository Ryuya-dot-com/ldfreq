# ICNALE, OANC and BAWE evaluation

This experiment evaluates controlled-length sensitivity and agreement across
disjoint text samples for twelve implemented lexical-diversity measures. ICNALE
also supplies agreement across two fixed essay prompts. Read `PROTOCOL.md` for
the populations, exclusions, estimands, cluster units and uncertainty rules.
The PELIC experiment in `../corpus-stability/` remains a separate evaluation.

## Data and conditions

Obtain each corpus directly under its provider's conditions. Corpus texts,
tokens, person IDs and document-level scores are not included here.

- [ICNALE WE 2.6](https://language.sakura.ne.jp/icnale/download.html): the
  unclassified, unmerged originals, 5,600 essays from 2,800 writers. Use the
  provider's registration and citation requirements; do not redistribute the
  data. The evaluated snapshot's sorted source-inventory SHA-256 is
  `f37815e55d1ab88dfa300573d12aed7ac402aefe7dad70dde254b7e6cdad374a`.
  Do not assume every archive carrying the same version label has identical bytes.
- [OANC](https://anc.org/data/oanc/): official `OANC_GrAF.zip`, distributed in
  `nancyide/anc-website` release `datasets-2026-09-25`, SHA-256
  `5a26559a1becba41a527cb674fff4fb9c4fb70b276f60422c4f07a0ef23fd867`.
  Usage and redistribution, including commercial use, are unrestricted.
- [BAWE](https://www.coventry.ac.uk/research/research-directories/current-projects/2015/british-academic-written-english-corpus-bawe/):
  Oxford Text Archive resource 2539, `2539.zip`, SHA-256
  `3612b5e24e3ebf106e7d580b9132d90b6a63bdee035b48ecefbd655c9cacab32`.
  Use `CORPUS_UTF-8` only; the other XML directories duplicate these assignments.
  The repository lists CC BY-NC-SA 3.0; the corpus headers and project conditions
  additionally specify research use, no redistribution of original/modified
  corpus files, prescribed acknowledgement and notification of projects/outputs
  to the developers. Keep texts and derived token sequences private.

The data in this study come from the British Academic Written English (BAWE)
corpus, which was developed at the Universities of Warwick, Reading and Oxford
Brookes under the directorship of Hilary Nesi and Sheena Gardner (formerly of
the Centre for Applied Linguistics [previously called CELTE], Warwick), Paul
Thompson (Department of Applied Linguistics, Reading) and Paul Wickens
(Westminster Institute of Education, Oxford Brookes), with funding from the
ESRC (RES-000-23-0800).

## Reproduce

Requirements: Python with lxml; R with ldfreq's development dependencies,
digest, jsonlite and ggplot2. The external comparison additionally uses koRpus
and koRpus.lang.en. Analysis scripts make no network calls.

Choose a private directory outside the package and place the licensed sources at:

```text
PRIVATE/icnale/source/WE_*.txt
PRIVATE/oanc/source/OANC-GrAF/data/.../*.txt and corresponding *.anc
PRIVATE/bawe/source/download/CORPUS_UTF-8/*.xml
```

Run from the package root, replacing `PRIVATE` with that private directory:

```sh
python3 experiments/corpus-extension/prepare-sources.py PRIVATE icnale
python3 experiments/corpus-extension/prepare-sources.py PRIVATE oanc
python3 experiments/corpus-extension/prepare-sources.py PRIVATE bawe
Rscript experiments/corpus-extension/tokenize.R . PRIVATE icnale
Rscript experiments/corpus-extension/tokenize.R . PRIVATE oanc
Rscript experiments/corpus-extension/tokenize.R . PRIVATE bawe
Rscript experiments/corpus-extension/fingerprint.R PRIVATE
python3 experiments/corpus-extension/oanc-links.py PRIVATE/oanc
Rscript experiments/corpus-extension/prepare-plan.R . PRIVATE
Rscript experiments/corpus-extension/check-statistics.R .
Rscript experiments/corpus-extension/compute.R . PRIVATE icnale
Rscript experiments/corpus-extension/compute.R . PRIVATE oanc
Rscript experiments/corpus-extension/compute.R . PRIVATE bawe
Rscript experiments/corpus-extension/summarize.R . PRIVATE icnale OUTPUT
Rscript experiments/corpus-extension/summarize.R . PRIVATE oanc OUTPUT
Rscript experiments/corpus-extension/summarize.R . PRIVATE bawe OUTPUT
Rscript experiments/corpus-extension/check-results.R . PRIVATE OUTPUT
Rscript experiments/corpus-extension/external.R . PRIVATE OUTPUT
Rscript experiments/corpus-extension/plot-distributions.R PRIVATE OUTPUT
```

Computation checkpoints preserve completed documents; summary checkpoints
preserve completed strata. Resuming checks the input, plan and code identities.
Use a new private run directory for a changed protocol or input.

## Results

`results/` contains aggregate distributions, means, missing counts, ICCs,
paired-length changes, task CCCs and external comparisons. Empty interval
fields mean the predeclared cluster/finite-replicate rule was not satisfied;
they do not mean zero uncertainty. Read `clusters` and `largest_cluster_share`:
the shared-speaker network makes Switchboard conversations unsuitable for an
independent-conversation bootstrap. Even an available interval is fragile if
one component contains most observations. Negative ICCs are retained.

External comparisons cover 182 real blocks. All jointly computable values for
the five compared measures agree within 1e-10. Forty 50-token MATTR blocks have
a documented boundary difference: koRpus 0.13-9 requires N > window and returns
NA at N = window; ldfreq permits the single valid window. Dedicated 49/50/51/52
token checks verified this rule. The result tables retain these disagreements.

The accompanying choosing-metrics vignette interprets these results together
with the PELIC evidence and the original methods literature. None of these
analyses establishes proficiency validity or a universal minimum text length.
