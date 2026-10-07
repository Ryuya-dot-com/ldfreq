# Executed external metric comparisons

Nine authored token sequences, actual external implementations, no reimplementation
of their formulas. The inputs and frozen outputs are in
`tests/fixtures/external-metrics/`. The runs used R 4.6.1, koRpus 0.13.9,
koRpus.lang.en 0.1.4, quanteda 4.5.0, quanteda.textstats 0.97.2 and Python 3.9.6.
The ldfreq baseline is merged main `1c719ec` (package 0.2.0). These are
implementation comparisons on adversarial examples, not validation with learners.

| Input | N | ldfreq 0.2.0 (legacy min10) | koRpus `MTLD` | TAALED `mtldo` |
|---|---:|---:|---:|---:|
| One repeated type | 9 | missing | 2.250000 | 2.835000 |
| One repeated type | 10 | 10.000000 | 2.500000 | 3.111111 |
| One repeated type | 19 | 4.551331 | 2.111111 | 4.551331 |
| One repeated type | 50 | 10.000000 | 2.083333 | 6.930693 |
| Exact threshold example | 27 | 27.000000 | 16.723519 | 26.257500 |
| Ordinary tail | 10 | 14.000000 | 14.000000 | 14.000000 |
| Repetitive short tail | 12 | 4.307692 | 2.400000 | 4.307692 |
| Asymmetric sequence | 14 | 8.902913 | 3.150000 | 8.902913 |
| Repeated mixed pattern | 120 | 10.000000 | 4.900000 | 9.655172 |

All three pinned baseline implementations compare TTR with strict `<`. ldfreq and TAALED
require ten tokens for a complete factor; koRpus does not. TAALED evaluates the
last sequence as a fractional tail even when a full factor could close there;
ldfreq checks closure first. koRpus 0.13.9's `mtld.sub.nodata()` loop does not
evaluate a final sequence of at most two tokens: for 50 repeated tokens it counts
24 factors rather than 25. Consequently, koRpus is not an unquestioned oracle.
The ten-token rule has a precedent in TAALED; a min10 variant is not inherently
an implementation error. It needs an explicit name and boundary/tail rules,
since the shared minimum does not make the implementations identical.
The CSV records a reason for each case. A ten-token lower bound for ldfreq is
false (the 12-token example is below five); effects on an actual L2 distribution
have not been estimated here.

quanteda.textstats does not implement MTLD in this version. Its TTR matches
ldfreq, koRpus and TAALED on every input. With `log.base = exp(1)`, its `Maas`
column is **a**, whereas ldfreq uses **a-squared**. Squaring it agrees with ldfreq.
TAALED's natural comparison is its base-10 a-squared; dividing that value by
`log(10)` agrees with ldfreq. The offline test checks these relations and all
three existing TAALED-labelled MTLD variants on the eight inputs of at least
ten tokens. It does not require other tools or the network during package tests.

## No-minimum migration in package 0.3.0

`current-mtld.csv` records core-contract 0.2.0 output. The original external
outputs above remain frozen. With the same nine inputs, current MTLD is
2.25, 2, 19/9, 2, 9315/557, 14, 2, 3.15 and 4.9 in table order. Six match
koRpus to tolerance 1e-12. The three exceptions (10 and 50 repeated tokens,
and the 12-token short-tail case) are explained by koRpus omitting the last
complete two-token factor. Current ldfreq evaluates every token.

The no-minimum definition retains strict `<` and averages directional scores.
For the exact-threshold case, the forward factor closes at token 27 (not 25).
The reverse pass has four length-two factors and a 19-token tail of 18 types:
credit 25/133 and score 3591/557, giving mean 9315/557. This also matches the
frozen koRpus result. Tests separately cover tail bounds and reversal at four
thresholds; tail credit is at most one without clamping.

`legacy-core-0.1.0.rds` was produced before migration using the isolated installed
0.2.0 package. It contains the nine MTLD results and original canonical plan.
Tests reproduce its values/statuses through the explicit min10 variant, retain
old IDs through saving/loading, and reject silent reuse of the old plan or
mixing old/new values in a single wide metric column. The cross-language
fixture's R min10 row is likewise retained as a legacy-variant test.

## Reproduction

Obtain `taaled/ld.py` and `taaled/real_words5.pickle` from the separately licensed
[TAALED revision](https://github.com/LCR-ADS-Lab/TAALED/tree/27b19e1cda26e6f4d869d36afea6874f08825618).
The source SHA-256 is checked by `run-taaled.py`. Run it from a directory where
the upstream import can find its data file; `pkg_resources` from setuptools is
required by that upstream version. Optional plotnine is unnecessary. Neither
upstream code nor that data file is redistributed here.

```sh
python3 /path/to/package/experiments/external-metrics/run-taaled.py \
  /path/to/ld.py /path/to/package/tests/fixtures/external-metrics/inputs.json \
  /path/to/new-taaled-results.json
Rscript experiments/external-metrics/run-r.R . /path/to/external-R-library \
  tests/fixtures/external-metrics/inputs.json /path/to/new-r-results.json
```

The R runner uses the actual public entry points and checks that koRpus and
quanteda retained exactly the ordered input tokens. In a fresh library install
the versions recorded above, plus pkgload/jsonlite; no dependency is added to
ldfreq. Review new outputs against the frozen files before accepting a version
update. A changed upstream output is evidence to investigate, not a reason to
overwrite the baseline automatically.

Sources: [koRpus](https://reaktanz.de/?c=hacking&s=koRpus),
[quanteda.textstats source](https://github.com/quanteda/quanteda.textstats/blob/master/R/textstat_lexdiv.R),
[pinned TAALED source](https://github.com/LCR-ADS-Lab/TAALED/blob/27b19e1cda26e6f4d869d36afea6874f08825618/taaled/ld.py).
Expected-TTR D has not been compared with CLAN in this work; it is experimental.


## Migration and boundary sensitivity

The [executed 30-essay comparison](../mtld-migration/README.md) reports paired
scores, rank correlation, changes and missingness on the bundled authored
teaching sample. All 30 pairs match (rho = 1); this does not establish equality
in learner populations or in the low-score range absent from that sample.

`<` and `<=` are different definitions when a factor reaches exactly 0.72.
Holding the no-minimum algorithm's other choices fixed, the 27-token
`threshold_equal` input gives 16.723519 with `<` and 9.973519 with `<=`
(67.68% larger relative to the latter). The reproducible operator comparison
is part of that migration script. This is a sequence-specific illustration,
not a universal adjustment and not a change to the package's strict rule.
