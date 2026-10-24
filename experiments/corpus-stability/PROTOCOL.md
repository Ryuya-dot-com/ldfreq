# PELIC length and sampling stability protocol

Specified on 2026-10-24 after inspecting corpus metadata and token lengths,
before computing metric outcomes. This addresses which implemented measures
are comparatively insensitive to text length and reproducible across sampled
parts of the same essay. It does not estimate proficiency validity or the
reliability of differences between people across prompts or occasions.

## Population and preprocessing

PELIC v1.0, commit `853e9e545cc7a78a70839c68e8ed293cc7ed9c2c`;
original version 1, writing class `w`, essay question type `4`. Keep the first
numeric answer ID per writer and prompt. Use the package English tokenizer,
NFC, lower case, exclude numbers, surface forms, preserve order and spelling.
No filtering on lexical scores, proficiency, missing scores or lexical content.
The resulting corpus has 2,786 essays, 696 writers, 297 prompts and 1,196,348
tokens. The controlled-length cohort has 1,330 essays of at least 400 tokens,
421 writers and 237 prompts. Long-text selection limits generalization.

## Estimands

1. Full-essay length associations describe the selected corpus; differences in
   topic, writer, instructional level and task can cause these associations.
   They are not interpreted as causal effects of adding tokens.
2. Within-essay length sensitivity uses the same 1,330 essays at 50, 100, 150
   and 200 tokens. Sample one pair of disjoint 200-token blocks uniformly over
   all possible unordered pairs, then randomly label the blocks A and B.
   Within each block take nested prefixes. No token reshuffling or document
   concatenation. Report each length's mean, SD, median, missing proportion
   and its original-scale distribution, with paired length changes in a
   numerical diagnostic table only. Standardize the mean 50-to-200 change by
   the SD of document means at 200, to compare sensitivity across units.
3. Sampling reliability is the single-block one-way random-effects ICC(1,1)
   across A and B, separately at each length. This estimates the proportion
   of score variation attributable to differences between essays rather than
   the sampled position within essays, in this selected corpus. It is not the
   reliability of an average of two blocks. Negative estimates are retained.
   Report rank correlation as a secondary, distinct ranking measure.
   Missing block pairs are excluded per metric, and counts are explicit.
   High ICC can reflect topic differences; it is not evidence of ability validity.

The uniform-pair construction samples two distinct integers from
`1:(N-398)`, sorts them, and adds 199 to the second. This is a bijection to all
pairs of starts of non-overlapping 200-token blocks. Use seed 20261024.

## Measures, uncertainty and checks

Compute all eleven default metrics plus opt-in MTLD-MA. MATTR and MSTTR use
50 tokens, HD-D uses 42, and MTLD/MTLD-MA use strict TTR < .72. MTLD-MA keeps
complete factors of at least 10 tokens and has no fractional tail. These
settings are held fixed across lengths. Expected-TTR D is excluded because
it is an experimental curve estimator, not one of the default methods.

Use 2,000 percentile bootstrap replicates resampling writers (all their essays
retained together), seed 20261025. Inference is document-weighted, conditional
on this corpus's prompts; no claim of independent essays or population-wide
prompt sampling. Bootstrap the paired length change and the ICC/rank estimates;
report 95% intervals and the number of finite bootstrap estimates. Do not
truncate negative ICCs or omit poor results. The full-essay descriptive
associations do not determine the primary recommendation.

Compare actual koRpus calls on a deterministic subset spread through each
recorded course level and length quartile, at most 20 essays per stratum.
Compare TTR, MATTR (window 50), HD-D (sample 42) and MTLD-MA against the same
ordered tokens. Inspect names and scale definitions first. The ordinary MTLD
comparison records known terminal-factor differences rather than treating
identical names as identical formulas. Frozen aggregate external results and
source hashes are public; texts, token sequences, author IDs and per-document
scores stay in the private cache. No network calls occur in analysis scripts.

## Interpretation

Recommendations must combine sampling consistency, length sensitivity,
computability and the construct of interest. A convenient high correlation
with another index is insufficient. Findings apply to these English learner
essays and these settings; short speech, edited native prose, languages and
other window sizes require appropriate evidence. Resource license conditions
are recorded in the README; only aggregate results and reproduction code are
redistributed.
