# Length dependence and sampling stability across three corpora

Specified on 2026-10-24 after inspecting input metadata, lengths and duplicate
token sequences, before inspecting diversity outcomes. Timing probes discarded
their scores. This extends the existing PELIC experiment; its observations and
results are retained under their original sampling design.

## Questions and populations

The primary questions are which measures change least with sampled length,
which reproduce differences between documents across disjoint samples, and
where scores cannot be computed. ICNALE additionally permits agreement across
two fixed writing tasks. These are separate questions, not tests of proficiency
validity or evidence for a universal ranking of measures.

Use ICNALE WE 2.6 (5,600 unmerged original essays), OANC (8,824 documents), and
BAWE UTF-8 XML (2,761 assignments). Source bytes and private prepared inputs
are hash-identified in the run provenance. All use English surface tokens,
NFC, lower case, no numbers, original order and spelling. BAWE uses text/body,
retaining quotations but excluding front/back matter, notes, references to
notes, tables, figures and formula placeholders. Compound assignments remain
one document. Source texts and document-level outputs are not redistributed.

BAWE primary analyses require the header to state exactly one author. Records
with multiple or unknown authors are excluded before duplicate removal.
Remove duplicate complete token sequences within each eligible corpus, retaining
the first sorted document ID. Exclusion does not depend on diversity scores.
ICNALE L1 reference essays and L2 essays are always distinguished. OANC writing
and speech are always distinguished; a conversation is not an individual writer.

## Sampling and measures

Short-text cohort: eligible documents with N >= 200; two disjoint 100-token
blocks, each evaluated at nested lengths 50 and 100. Long-text cohort: OANC
and BAWE documents with N >= 2,000; two disjoint 1,000-token blocks, evaluated
at nested lengths 200, 500 and 1,000. Each length comparison uses the same
documents and starts. Do not connect the short and long curves as though they
used the same cohort. There is no full-text score computation in this extension:
observational associations with original length do not answer the controlled
length question and would add substantial redundant computation.

For maximum block length M, sample two distinct integers from 1:(N-2*M+2),
sort, add M-1 to the second, and randomly label them A and B. This is uniform
over disjoint unordered block pairs. Starts are saved before scoring. Seeds are
202610240 + corpus index (ICNALE=1, OANC=2, BAWE=3), with independent saved draws
for the short, long and task comparisons. Do not shuffle tokens or join documents.

Compute TTR, RTTR, CTTR, Herdan, Maas, MSTTR, MATTR, MTLD, MTLD-MA, HD-D,
Yule K and Yule I with the same settings as PELIC: window/segment 50,
HD-D sample 42, strict MTLD threshold < .72, MTLD-MA minimum complete factor
10 and step 1. The experimental expected-TTR D estimator is excluded.
Record missing reasons and ordinary MTLD cases with no complete factor in
either direction. Do not replace missing scores with zero.

## Estimation and independent units

For each length report all available block scores' mean, SD, median and missing
proportion. Sampling stability is the single-block one-way ICC(1,1), using only
complete A/B pairs: B = 2 var((A+B)/2), W = mean((A-B)^2)/2,
ICC = (B-W)/(B+W). Retain negative estimates. Also report Spearman rank
correlation, without treating ranking as absolute agreement. This ICC describes
between-document differences relative to within-document sampling variation;
it is not a writer-ability or test-retest reliability coefficient.

Length sensitivity is the mean within-document difference between the largest
and smallest length in a cohort, divided by the SD of document means at the
largest length. Both blocks at both lengths must be finite for that comparison.
Report original-scale means at every length alongside the diagnostic difference,
the complete-document count, and the exclusions induced by missing scores.
An apparently stable conditional mean is insufficient when computability is low.

Use 2,000 cluster bootstrap replicates and percentile 95% intervals for ICC,
means and paired length changes. Reuse a group's bootstrap weights across its
metrics and lengths. Each selected cluster carries all its documents and both
blocks. Report cluster count, largest cluster's document share, and finite
bootstrap count. Do not report an interval with fewer than 20 contributing
clusters or fewer than 1,900 finite replicates. Twenty is a predeclared reporting
floor, not a guarantee of reliable asymptotic inference. A dominant cluster
also limits precision and is reported, rather than hidden by document counts.

ICNALE and BAWE clusters link writer IDs; duplicate complete texts additionally
link their recorded writers, even when only one copy is retained. OANC clusters
are connected components of recorded coauthor/speaker IDs and shared source
units: whole OUP books, the 9/11 report, and Berlitz destination guides. Anonymous
Verbatim and ICIC material is grouped by its collection. Other records without
usable people/source identifiers are grouped by source collection; arbitrary
numbered Slate/Switchboard directories are not treated as independent units.
Names are normalized only for case/Unicode/whitespace, without fuzzy matching.
Unrecorded shared authorship cannot be ruled out. Switchboard's linked speaker
network may form very few components: retain its descriptive estimates and
withhold unsupported cluster intervals rather than bootstrap conversations as
independent observations.

Report ICNALE separately for L2/L1 and, within L2, by region, CEFR band and task;
OANC by mode and genre; BAWE overall, by disciplinary group, and by genre family
(compound families grouped as compound). These are descriptive strata, not a
multiple-testing search for significant differences. A pooled high ICC can
reflect genre/topic heterogeneity and cannot replace within-stratum results.

## Agreement across the two ICNALE tasks

Keep writers whose two nonduplicate essays both contain at least 200 tokens.
Independently sample one contiguous 200-token segment uniformly from each essay.
Report task-specific distributions, Spearman correlation and Lin's concordance
correlation coefficient (CCC), using population-moment estimates in its formula.
CCC assesses agreement including mean/scale differences; it is not the within-
essay ICC above. Bootstrap the linked-writer clusters 2,000 times. Report L2,
L1 and the predeclared L2 strata; findings are conditional on these two prompts,
not a population of tasks or longitudinal occasions.

## Validation and interpretation

Verify sampled intervals, saved-input hashes and checkpoint identities. Check
ICC against a separate ANOVA computation and bootstrap sufficient-statistic
calculations against explicit resampling, including unequal clusters and missing
scores. Compare actual koRpus calls on deterministic, length-spread real blocks
from each corpus and scope, preserving exact token identity. Compare TTR,
MATTR, HD-D, MTLD-MA and MTLD; report any method-definition differences.

Recommendations must jointly consider length sensitivity, sampling agreement,
missingness and the intended construct. Retain poor and negative findings.
Plots show original-scale distributions or condition values, not difference
axes. No universal reliability cutoff is used to choose a winner. Data license
conditions and required acknowledgements remain separate from the MIT code.

References: McGraw & Wong (1996), doi:10.1037/1082-989X.1.1.30;
Lin (1989), doi:10.2307/2532051. The sampling protocol and its inference scope,
rather than these citations alone, define the estimands used here.
