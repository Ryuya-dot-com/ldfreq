# MTLD migration on the authored essay examples

This execution uses the 30 project-authored English teaching texts distributed
with ldfreq and retains the additional empty document. These are not observed
learner essays or a representative population sample. The comparison answers:
would switching the default change the existing tutorial's scores or ordering?

All texts use the English tokenizer, NFC, lowercase surface forms and exclusion
of number tokens. Both definitions receive exactly the same ordered tokens and
threshold 0.72. The legacy method is selected explicitly. No correction, POS
filter, sampling or length matching is introduced.

| Quantity | Observed result |
|---|---:|
| Finite paired documents | 30 |
| Token count range | 107–149 |
| Spearman rank correlation (average ties) | 1.000 |
| Documents with a score change > 1e-12 | 0 |
| Mean / median signed change (new minus old) | 0 / 0 |
| Mean / maximum absolute change | 0 / 0 |
| Median relative change | 0% |
| Score range, both definitions | 48.758612–165.211667 |
| Excluded from paired summaries | 1 empty document; retained as missing |

The tutorial's values and ranks therefore remain unchanged. This does **not**
establish interchangeability in learner corpora: the sample has no low-scoring
texts, and the adversarial cases in `../external-metrics` already show large
differences. A claim that long learner texts generally have compressed low
scores remains untested here. Check the original tokens and explicit legacy
method for one's own corpus before combining old and new results.

`results/documents.csv` gives each ID, token count, both scores, statuses, ranks,
absolute-scale signed change, percentage change and original-file SHA-256.
`results/summary.csv` gives the paired descriptive summary; no missing value
is replaced with zero. `results/provenance.json` records versions and settings.
The operator table holds an additional comparison described below. Differences
are tabulated for auditing; no difference plot is used.

## Reproduce

Install the corrected package, then run from its source checkout:

```sh
Rscript experiments/mtld-migration/compare-essays.R . /path/to/new-output
```

The output also includes a complete `analysis.rds` with prepared tokens,
preprocessing, both result objects, identities and summaries. Reproduction
requires no external corpus, analyzer, network call or paid API.

## Isolating the inequality

A separate transparent reference changes only `<` to `<=`; it keeps the
no-minimum definition, threshold 0.72, final-token closure, linear residual
credit and directional mean fixed. Before the comparison, its strict output
is checked against the actual package on all nine adversarial inputs and all
31 tutorial documents. This reference is an illustration, not another exported
method or a replacement for actual external-tool comparisons.

On the existing 27-token `threshold_equal` input, strict `<` gives
16.7235188509874 and inclusive `<=` gives 9.97351885098743: the strict value is
67.6792224% larger relative to the inclusive value. The boundary effect depends
on the sequence; this is not a general percentage adjustment. One of the 30
essays also changes: document `024` gives 86.195614 with `<` and 64.316331 with
`<=` (strict is 34.018240% larger). The other 29 agree. This operator comparison
is separate from the new/legacy comparison above, where both use `<`.
Always report the boundary rule.
