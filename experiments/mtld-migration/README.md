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

The tutorial's values and ranks therefore remain unchanged. The complete-factor
screen below explains why this agreement is guaranteed for these inputs. It
does **not** establish interchangeability in learner corpora. The subsequent
local ICNALE check measures sensitivity in a retained learner sample; neither
sample establishes a general population effect.

`results/documents.csv` gives each ID, token count, both scores, statuses, ranks,
absolute-scale signed change, percentage change and original-file SHA-256.
`results/summary.csv` gives the paired descriptive summary; no missing value
is replaced with zero. `results/provenance.json` records versions and settings.
The operator table holds an additional comparison described below. Differences
are tabulated for auditing; no difference plot is used.

## Why the authored essays agree

For the same ordered tokens, threshold, strict `<` comparison, final-token
check, tail rule and directional averaging, an input of at least ten tokens is
unaffected by min10 if neither direction of the no-minimum scan contains a
complete factor shorter than ten. Before the first closure, min10 cannot block
any qualifying token; after that common closure, the same reasoning applies
to the next factor. Induction gives identical boundaries and the same residual
tail. A missing `no_factor` result is also preserved.

The shortest complete factor across the 30 essays is **14 tokens**. Of the 30,
22 have at least one complete factor; their document-wise minima have median
**39**. Eight have only residual factors in both directions. Giving these eight
an artificial minimum of `Inf` yields median **45** across all 30, but the
recorded minima use `NA` for absence and report the 22-document denominator.
Both summaries imply zero factors shorter than ten; the convention does not
change the migration conclusion.

`results/factors.csv` contains the forward/reverse minima, short-factor counts
and classification for every authored document. The executable helper is
printed in the [migration tutorial](https://ryuya-dot-com.github.io/ldfreq/articles/designing-comparisons.html#identify-where-the-min10-restriction-can-matter).
The comparison script reads that exact code chunk, avoiding a second helper
implementation. This is analysis code, not a new exported API or result schema.

- `no_min10_effect`: both directions have zero short complete factors and
  N >= 10. Scores or `no_factor` results are guaranteed unchanged.
- `possible_min10_effect`: at least one short complete factor. Run the explicit
  legacy method to learn whether the final score actually changes.
- `legacy_ineligible`: N < 10, including empty input. The legacy formula is
  unavailable; report the actual statuses separately.

The condition is sufficient, not necessary. For example,
`c(letters[1:6], "a", "b", "c", "g")` has a nine-token forward factor, but
both methods return 10. Do not interpret the screen's flagged percentage as
the changed-score percentage, or include unfinished tails as complete factors.

The runner verifies seven explicit boundary examples and 1,500 independently
generated inputs (seed 20261008; uniform length 10–300, uniform vocabulary size
1–100, IID uniform token sampling with replacement). This is a deterministic
implementation check, not a reproduction of another random sample or a
corpus prevalence estimate. Actual exported current and legacy methods give:

| Screen | Equal finite scores | Different finite scores | Both missing |
|---|---:|---:|---:|
| No short complete factors | 611 | 0 | 10 |
| At least one short complete factor | 27 | 852 | 0 |

For every unflagged input, values, status and missing reason match exactly.
The finite-score comparison uses an absolute tolerance of 1e-12. The ten
missing inputs have no factors; they are not counted as equal numerical scores.
`results/screen-checks.csv` and `results/provenance.json` preserve the counts
and random-generation settings.

## Local learner check: ICNALE GRA V2.1

We reused the saved original-essay token streams from the existing local
ICNALE GRA V2.1 analysis: 136 L2 essays and four ENS essays, 31,902 tokens in
total, from one writing task. Tokenization was ldfreq English 0.1.0, NFC,
lowercase surface forms, numbers excluded. Texts were not corrected,
re-tokenized or replaced with lemmas for this comparison. Both methods used
strict `< 0.72`. Every essay had a finite pair of scores.

| Corpus proficiency label | Essays | Flagged by the factor screen | Actually changed (> 1e-12) |
|---|---:|---:|---:|
| L2 A2_0 | 31 | 2 (6.45%) | 2 |
| L2 B1_1 | 32 | 6 (18.75%) | 6 |
| L2 B1_2 | 33 | 3 (9.09%) | 3 |
| L2 B2_0 | 40 | 4 (10.00%) | 4 |
| **All L2** | **136** | **15 (11.03%)** | **15** |
| ENS | 4 | 1 (25.00%) | 1 |

All 121 unflagged L2 essays agreed exactly. The 15 changed L2 scores comprise
14 decreases and one increase. Across all 136, the mean signed change (new
minus old) is -0.576369; the maximum absolute change is 11.553956, and the
largest decrease is 19.61% relative to the old value. Spearman correlation is
0.989314. The one increase, about 0.626190, arises in the reverse direction:
both versions have five complete factors, but their residual credits differ.
Thus even a high rank correlation can accompany material changes to some
scores, and a short factor alone guarantees neither change nor its direction.

These observations answer whether the retained essays are affected. They do
not establish a population rate, a monotonic relation with proficiency, or
compression throughout a low-score population. The L2 current-score range is
34.517383–109.240600; essays below this range are not represented. Four ENS
essays cannot characterize native-speaker writing.

Only aggregate `results/icnale-summary.csv` and `results/icnale-provenance.json`
are public. The latter records the source-audit hashes and settings. Corpus
texts, document IDs, ratings, token streams and individual results remain
local. To repeat the procedure on authorized saved tokens, use the tutorial
helper and the current/legacy calls shown there, join the classifications to
the corpus metadata locally, and count flagged and actually changed documents
separately by group. Exact reproduction of this ICNALE result requires the
same authorized saved input; this repository does not distribute it.

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
`<=`: moving from strict to inclusive lowers the value by 25.383291% relative
to strict (equivalently, strict is 34.018240% larger relative to inclusive).
The other 29 agree. This operator comparison
is separate from the new/legacy comparison above, where both use `<`.
Always report the boundary rule. The
[reporting guide](https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report.html#save-enough-to-reproduce-and-report-the-analysis)
includes the operator, threshold, minimum length, final-token check, tail rule
and directional averaging in its MTLD methods-statement example.
