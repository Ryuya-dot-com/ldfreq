# From raw text to tokens to scores

Four authored inputs probe contractions/apostrophes, capitalization, punctuation,
numbers and hyphens, inflected forms and POS, and learner-like spelling and
grammar. Eight explicit pipelines produce 32 executed records. This extends
the [identical-token formula comparison](../external-metrics/README.md); it
is a preprocessing audit, not a test of annotation accuracy on learner language.

`results/tokens-and-scores.json` retains every ordered scoring token, native
scores and scores recomputed with **one common ldfreq definition**. Thus:

- Comparing the **common** score across pipelines isolates differences in the
  supplied token representation, inclusion and order under the same formula.
- Comparing native and common scores on a pipeline's same tokens exposes
  formula differences. TAALED's native MTLD here is `mtldo`, not its distinct
  default `mtld` mean-factor-length index. quanteda.textstats has no MTLD.
- Native TTR equals the common TTR on all 32 records (tolerance 1e-12).
  Same N and V do not imply the same order or the same MTLD.

## Actual settings

| Pipeline | Word forms, inclusion and defaults |
|---|---|
| ldfreq default | `lexdiv_tokenize(text)`: Unicode tokenizer, NFC, case preserved, numbers excluded; surface forms |
| ldfreq English/lower | Explicit `tokenizer="english", case="lower"`; apostrophe normalization; otherwise same options |
| koRpus | `tokenize(text, format="obj", lang="en")` then `lex.div()`; native lowercase scoring, punctuation omitted, numbers retained in this run; no external tagger/lemmatizer |
| quanteda | `tokens(text)` then `textstat_lexdiv(..., measure="TTR")`; scorer removes numbers, punctuation, symbols and URLs; hyphens retained, lowercase via `dfm()` |
| TAALED fallback | Actual `ldwrite()` with Pylats absent: lowercase and literal-space split; punctuation attached to tokens remains |
| TAALED + Pylats surface | Explicit `lats.parameters`: spaCy segmentation, lowercase surface forms; numbers/punctuation and the configured `becuase` removal omitted; no attested-word filter |
| TAALED + Pylats LD | Explicit `lats.ld_params_en`: lemma + UPOS keys, lowercase, attested-word filtering, number/punctuation/removal rules |
| TAALED + Pylats content | **Custom alternative**, derived from `ld_params_en`, retaining NOUN, PROPN, VERB, ADJ, ADV through explicit POS exclusions; not labelled a TAALED default |

TAALED 0.32 does not have one environment-independent default text pipeline.
When Pylats is present but `params` is absent, `ldwrite()` requests parameters
and stops. Pylats 0.40's `contentPOS` annotation alone does not remove function
words; this audit sets `posignore` explicitly. Full effective settings are in
`taaled-pylats.json`. Lemma/POS filtering changes the unit being counted and
may discard non-attested learner forms; it does not correct or validate them.

For the contraction input, actual outputs are:

| Pipeline | N | V | Native MTLD | Common no-minimum MTLD |
|---|---:|---:|---:|---:|
| ldfreq default | 34 | 20 | 25.0893 | 25.0893 |
| ldfreq English/lower | 34 | 14 | 18.0291 | 18.0291 |
| koRpus | 46 | 15 | 13.4370 | 13.4370 |
| quanteda | 34 | 19 | unavailable | 17.4811 |
| TAALED fallback | 34 | 20 | 27.6567 | 19.4836 |
| TAALED + Pylats surface | 46 | 17 | 15.2410 | 15.4773 |
| TAALED + Pylats LD | 41 | 14 | 17.2231 | 14.1714 |
| TAALED + Pylats content | 10 | 5 | 5.6000 | 10.0000 |

Here `don't` stays one token in ldfreq's English configuration, becomes `don`
and `t` in koRpus, and `do` plus `n't` in Pylats surface output. Pylats LD
produces `do_AUX` plus `not_PART`. The input contains straight and curly
apostrophes, so case conversion alone does not reconcile all pipelines.
These small examples reveal differences; their magnitude is not a correction
factor for published learner studies. Obtain a study's actual pipeline and
settings before claiming comparability with its TAALED results.

## Reproduction and identities

The R execution used R 4.6.1, koRpus 0.13.9, koRpus.lang.en 0.1.4,
quanteda 4.5.0, quanteda.textstats 0.97.2, and ldfreq 0.3.0.9002.
The Python execution used Python 3.9.6, spaCy 3.8.7, en_core_web_sm 3.8.0,
Pylats 0.40, and the same pinned TAALED 0.32 source as the earlier audit.
Pylats 0.40 is deliberately a compatible, fixed version, not a claim about
latest Pylats behavior. The wheel SHA-256 is
`e2db629840d70a1121f9fdc7bd79d9df01471891322573e18488905730070c53`.
Original external code/model/data licenses apply; none are redistributed here.

Get the [pinned TAALED source and its data](../external-metrics/README.md#reproduction),
[Pylats 0.40](https://pypi.org/project/pylats/0.40/) and the recorded spaCy/model
versions in a separate environment. Do not overwrite a study's existing tools.
Run the fallback in a Python environment without Pylats, and the other run in
one with Pylats available:

```sh
python3 experiments/raw-text-comparison/run-taaled.py /path/to/ld.py \
  experiments/raw-text-comparison/inputs.json \
  experiments/raw-text-comparison/results/taaled-fallback.json fallback
python3 experiments/raw-text-comparison/run-taaled.py /path/to/ld.py \
  experiments/raw-text-comparison/inputs.json \
  experiments/raw-text-comparison/results/taaled-pylats.json pylats
Rscript experiments/raw-text-comparison/run-r.R . /path/to/external-R-library
```

The Python collector is called by the actual `ldwrite()` pipeline and captures
the tokens it passes to scoring. No external tokenizer/formula is reimplemented.
The R runner records koRpus's retained scoring tokens; for quanteda it repeats
only the scorer's token-selection call and lowercase conversion, then verifies
native TTR against the retained tokens. Inputs and upstream source hashes are
recorded. Package builds/tests require neither these external tools nor network
access. Frozen numerical results are evidence for these pinned configurations.
