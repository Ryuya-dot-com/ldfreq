# Publication preparation: attributed NJ8 and user workflows

The 0.2.0 preparation adds a permitted default NJ8 table and explains how
comparison settings and reference coverage support interpretable text profiles.
It does not change any core diversity formula or publish a release.

## NJ8 source and permission

The project owner confirmed JACET permission with attribution and supplied
`NJ8.csv` for this work on 2026-10-04. This confirmation is the permission
record; original correspondence is not required. The permission is not
presented as a standard open license. The installed notice distinguishes
JACET's material from the original MIT-licensed package code.

The input CSV SHA-256 is
`1433dcd94135f86cfdbcbf5bafc209661678f1104f5062041b737834e99d3cf8`.
It has 7,999 rows. Against the official 2016 workbook, the differences are:

| Rank | Supplied snapshot | Bundled entry |
|---:|---|---|
| 326 | `TRUE` | `true` |
| 2382 | `FALSE` | `false` |
| 6926 | absent | `nan` |

The official workbook SHA-256 is
`6ff9e8e7f6893079c6a6ae4287f1fe69083374d2d9919fb4dc297aae086af1a7`.
Every bundled rank/entry pair matches its `新J8` sheet. Only those two columns
are bundled, with parenthetical alternatives preserved. The original input
CSV is unchanged. `experiments/nj8-source-build/build-nj8.R` verifies both
inputs and reproduces the installed table. The table's SHA-256 is
`6797238778c4b67bdce9657f16bfbdcc65982c72e4fd29eca93f7fef2d010f59`.

`nj8_profile()` and `nj8_profile_batch()` now default to this table, verify its
checksum, and retain its fixed version and citation. Explicit external tables
keep the previous matching and denominator rules. The level-profile and batch
contracts advance to 0.2.0; the core measurement contract remains 0.1.0.

## Public explanation and examples

- The README starts with the user problem, gives a comparison with
  quanteda.textstats, koRpus, tidytext, and zipfR, and explains the package's
  contribution as integration of comparison conditions and resource coverage.
  It makes no first-implementation, speed, or empirical-validity claim.
- The complete worked example connects a question, common settings, diversity
  and NJ8 coverage, a joined table, plots, interpretation, RDS round trip, and
  methods/resource citations. Both authored texts have 12 tokens; MATTR is
  0.800 versus 0.933 while NJ8 surface token coverage is 83.3% versus 75.0%.
- The optional TUBELEX recipe uses pinned upstream apostrophe/number/filter
  rules with NLTK sentence-aware tokenization. It records software/model/input
  identity, runs locally after explicit environment setup, and does not add a
  Python or network dependency to R calculations. It does not reproduce corpus
  collection, subtitle cleanup, or deduplication.
- Public NEWS/specification wording no longer exposes internal approval gates.
  Developer decisions remain in excluded development/experiment directories.
  User-facing compatibility semantics and limitations are preserved.

## Local validation and reuse of evidence

Evidence is stored in the workspace under
`reviews/ldfreq-publication-20261004/evidence/`.

The broad installed-package run passed 4,317 testthat assertions and identified
one smoke-script return-value failure. The added NJ8 assertions followed the
script's former final `invisible(TRUE)`; moving that return to the actual end
fixed it. The same run also identified an invalid DCF license stub, corrected
by retaining the attribution note as a valid continuation field. Neither issue
was a metric calculation failure.

After those fixes, the installed smoke test passed both assertions, completing
the 4,318-assertion suite by evidence reuse. The unexecuted TUBELEX installed
resource audit then passed 71 assertions. The earlier differential audit,
85-assertion loader audit, and 6,000-assertion randomized loader audit passed.
R source, tests, resource bytes, and specifications are identical between the
broad run and the final archive; archive-member comparisons are recorded in
`test-evidence-reuse.json`.

The final source archive passed `R CMD check --no-manual --no-tests` with
`Status: OK`, including examples and all five vignette rebuilds. This is a
combined local verification, not a claim that this invocation reran tests.
The resource inventory audit passed 1,342 assertions across source, macOS
archive, and installed forms. All 35 audited members were compared again with
the final source archive and its installed library after the last documentation
edit; they are byte-identical. The public API audit passed, and 13 local JSON
records validated against their schemas.

The optional Python/R input recipe passed its source-rule doctests, expected
contraction/curly-apostrophe/number tokens, empty input, provenance hashes,
R integration, save/read, and overwrite/duplicate-ID rejection with NLTK 3.9.3
and Python 3.14.3. The pkgdown site and revised worked article built successfully;
78 HTML pages had no missing local link/image targets. A browser was unavailable
in this session, so complete visual inspection of the rendered site is not
claimed.

Cross-platform full-check evidence belongs to the PR's existing CI runs.
The first Windows build exposed Git's automatic LF-to-CRLF conversion of the
new byte-pinned files. A `core.autocrlf=true` checkout reproduced five resource
member hash mismatches. Explicit `-text` attributes for the NJ8 directory,
notice, and optional Python example preserve their exact bytes. The same
checkout verification then matched all ten declared resource members. This
change affects checkout behavior, not R calculations or the resource content.

Repository visibility and `experiments/release-candidate/state.dcf` remain
unchanged: this is development work, not a publication or CRAN submission.
The ordinary private-repository checks do not replace final anonymously
accessible URL checks for publication.

## English tokenizer and raw-text batch follow-up

The owner selected usability for English analysis entirely within R as the
priority. The opt-in `tokenizer = "english"` therefore adds fixed lexical rules
to the existing tokenizer API without new dependencies, Python calls, or model
downloads. Contractions and hyphenated words stay whole; dotted initialisms,
number-like spans, URLs and email addresses have documented rules. Apostrophe
and hyphen typography is canonicalized. Excluded recognized spans have reasons,
processed-text offsets, and an integrity fingerprint. This is neither Treebank
segmentation nor automatic lemmatization or validated multilingual segmentation.

`lexdiv_tokenize_batch()` validates named texts or character ID/text columns and
returns complete document tokenizations. `lexdiv_metrics_text_batch()` accepts
raw or prepared documents and returns full metric rows, token audits with IDs,
and document-local preprocessing. Empty documents survive, missing texts name
the failing document, and explicit tokenizer settings are rejected for prepared
objects. Existing annotation, NJ8, overlap-comparability, wide-table, and plot
interfaces are exercised. The Unicode default and metric formulas are unchanged;
preprocessing contract 0.3.0 also accepts saved 0.2.0 Unicode objects without
rewriting their recorded provenance.

Current local evidence is in
`reviews/ldfreq-english-tokenizer-20261004/evidence/`:

- `R CMD check --no-manual`: Status OK; all five test scripts and six vignettes
  passed, including 4,410 testthat assertions (zero failures, warnings or skips).
- The public API audit covers 32 exports, 30 registered S3 methods, and 15
  shared help topics. Eleven installed JSON documents passed schema validation.
- All six articles and the pkgdown reference built successfully. All 84 HTML
  pages have existing local href/src targets. Whole-site visual browser review
  is not claimed.
- The source archive SHA-256 is
  `d4241994463d61d75bdc6cc227907cfa35268f2debd8e8e5b36f509a287104ed`.

The initial vignette build caught a syntax error in the newly extended smoke
example; it was fixed and the installed example and complete final build/check
passed. This was an example-edit error, not a numerical-method failure.
Resource bytes, source builders, the optional external Python tokenizer, and
license notices are unchanged, so their prior source-reproduction evidence is
still applicable. The new preprocessing and batch paths require fresh full
cross-platform package checks; the PR records those results separately from this
local check. No release-state or repository-visibility change is included.

## General-purpose corpus package review

This follow-up treats native-speaker, learner and other English corpora as
analysis targets. Its contribution remains reproducible comparison conditions,
resource coverage and reusable result tables; it does not claim a new diversity
formula or a universally validated proficiency/quality scale.

| Perspective | Finding and action | Remaining boundary |
|---|---|---|
| Audience and construct | README and package help distinguish general corpus description, matched population comparisons and individual vocabulary evidence. | L1 status, reference frequency and corpus occurrence do not establish individual ability. |
| Input and interoperability | Existing named vectors, ID/text tables, prepared tokens and tidy/quanteda adapters are reusable. The new guide joins separate metadata by unique document ID. | English tokenization is not multilingual validation or a corpus-XML/transcription parser. Spoken boundaries require explicit preparation. |
| Custom resources | Promoted the existing B0/B1 norm-batch design into `lexdiv_norm_profile_batch()`, reusing current single-document arithmetic and shared validators. | One resource/specification per call; caller labels are not resource fingerprints. Save actual tables for replay. |
| Missingness and denominators | Empty documents, OOV terms and matched-but-unannotated values remain visible. The three coverage rates and token/type weighting remain separate. | No automatic coverage cutoff, imputation, corpus pooling or combined sophistication score. |
| API and maintenance | One canonical paired batch name, one bounded print method, a 0.1.0 batch contract, installed help and runnable guide. No new dependency or bundled dataset. | Do not extend the first release with speculative XML importers, inference engines or incompatible resource variants. |
| Scale and portability | Shared resource validation runs once, and a global row budget is checked before lookup/allocation. Default/C-locale tests cover UTF-8 identity. | This is not a memory benchmark or a performance advantage claim; new cross-platform CI is still needed. |
| Attribution and distribution | Added a DESCRIPTION reference to existing third-party COPYRIGHTS. JACET permission/attribution and TUBELEX BSD notices remain intact. | This metadata clarification does not convert JACET data to MIT or amount to CRAN acceptance. |
| Public availability | Anonymous TLS-verified requests returned 404 for the repository and issue tracker, and 200 for the documentation home. The new batch reference URL returned 404. | The site being reachable does not mean the latest local functions are published or installable anonymously. No visibility or publishing change was made. |
| Scientific evidence | Software tests and authored demonstrations exercise stated calculations and data boundaries. | Cross-register/native-speaker empirical analyses and independent usability/validity studies remain separate work. |

The CRAN source-package policy was checked at
<https://cran.r-project.org/web/packages/policies.html>. Its requirements on
copyright identification, portability, package size and economical checks
inform this review. The owner's existing JACET authorization is retained;
no additional corpus was downloaded or redistributed as part of the change.

The batch follows the existing workspace design in
`r-package/NORM-PROFILE-BATCH-CONTRACT.md` and its prototype, with existing
package document-ID adapters reused instead of duplicating them. The
single-document implementation and existing numerical contracts are unchanged.
Local code, documentation and distribution checks are recorded under
`reviews/ldfreq-general-package-20261004/evidence/`. Historical checks above
remain evidence for their own source revisions, not this later source archive.

The repository-only lifecycle record remains in development state. Anonymous
repository/issue access, the candidate's full platform CI and actual public
artifact/site synchronization are release work, not established by a local
`R CMD check` result. The repository's inaccessible URL may reflect visibility
or existence; the HTTP response alone does not establish which.

### Validation of this follow-up

The exact source archive passed `R CMD check --no-manual` with Status OK:
5,006 testthat assertions, zero failures/warnings/skips, all five test scripts,
and nine vignette builds/rebuilds. The 89 new focused assertions also passed
under the C character locale. They include single-call equivalence and
independent count/mean calculations, shared validation count, early global
budget rejection, empty inputs, Unicode identities and save/read behavior.
The public API audit covers 37 exports, 31 S3 methods and 20 public help topics.
`R CMD Rd2pdf` produced the 57-page reference manual. This verifies compilation;
it is not a claim of human usability testing or visual review of every page.

The source archive is 3,156,774 bytes; bundled resource files occupy 2,678,587
uncompressed bytes and installed vignette material 780,404 bytes. All 146
compared source/help/test/example/specification members match the archive byte
for byte, and DESCRIPTION's source fields match after R's formatting and added
build metadata. All six bundled resource members match the previous checked
archive. No excluded development, experiment, legal or local-site directories
appear in the archive. The scan of public documentation/specifications found no
local user paths or review-gate phrases among the checked patterns.

Archive SHA-256:
`6c2ae17fc517e860dbc2522f1d3ba8c3795d154eafcb4b803383d0de9c097d5e`.
The authored guide runs through custom reference matching, metadata alignment,
missingness and replay. No real native-speaker corpus validation was performed.
Cross-platform CI, public repository access and deployment remain unverified
for this revision; no release, visibility change or CRAN submission was made.

The full pkgdown build also completed. All 93 HTML pages have existing local
href/src targets, and the new reference, guide, index and NEWS show the current
API. This is local site verification; the anonymous public URL results above
remain a separate publication finding.

## Open-access paper workflow and publication state (2026-10-05)

The owner clarified that the distributable example need not come from an
established corpus. ICNALE GRA text remains outside all package/public example
payloads. LOCNESS's official distribution page requires an application and
restricts third-party redistribution; it was not downloaded or substituted as
a redistributable fixture. Free-to-read access alone is not treated as a license.

The new `open-access-papers` guide and installed R recipe use the CC BY 4.0 JOSS
papers for tidytext, tokenizers and quanteda. Each article landing page and the
pinned publisher JATS file identify that license. The recipe records full
attribution, exact source commits and SHA-256 values, DOI, selected paragraphs,
exclusion rules and transformed-text hashes. It saves attribution and
modifications with the outputs. No paper XML or extracted text is bundled in
the package. `xml2` is added only to Suggests for the explicit XML recipe.
Loading the package or building its documentation performs no paper download.

This is an academic-English workflow example, not native-speaker evidence:
author L1 is unknown, selection is purposive, and authors overlap. The guide
explains why the texts cannot establish a register effect, a writing-quality
ranking, independent writer effects or lexical employability. It also explains
within-paper paragraph boundaries and the different TUBELEX token denominator.

Verification evidence is in `reviews/ldfreq-open-papers-20261005/evidence/`:

- The new source archive is 3,171,253 bytes, SHA-256
  `f852b68b2853f0c44b87eff81dec63b09a70aecff50e5324346dcf785a6849d0`.
- All 129 compared R/test/help/spec/resource/license members are byte-identical
  to the prior `6c2ae17f...` archive. Its successful 5,006 assertions and PDF
  compilation remain applicable to those unchanged files. The current archive
  was checked with `R CMD check --no-tests --no-manual`: Status OK, examples and
  ten vignettes checked/rebuilt. Tests were deliberately skipped in that run;
  it is not reported as another complete test run.
- The installed new recipe passed its separate executable check
  `experiments/open-access-papers/verify-example.R`: pinned input identities,
  extraction counts, independent TTR/MATTR/HD-D calculations, NJ8 numerators and
  denominators, published table values, metadata, offline replay and save/read.
  Missing and changed source files were rejected. An explicit fresh download
  through the installed R recipe reproduced the offline inputs and results.
- R English token totals are 256/495/935, with NJ8 matches 178/322/584. The
  optional existing NLTK 3.9.3 recipe produced 260/498/941 TUBELEX input tokens,
  of which 251/486/893 matched. Both token/type matched means and denominators
  were independently checked; the complete frequency result survived save/read.
  The separate tokenization and coverage conditions are retained, not merged.
- The API inventory still has 37 exports, 31 S3 registrations and 20 help topics.
  No numerical implementation, resource content or public function was changed.

Authenticated `gh` reads resolved the earlier anonymous 404 ambiguity:
`Ryuya-dot-com/ldfreq` is PRIVATE. Pages is public, with legacy source `main:/`.
PR #21 points to `prepare/publication-nj8-20261004` at
`13d580fa4b1fd1cecb9a5479169c59a86acdb813`; the successful ordinary CI run
37198599794 and development-state candidate workflow 37198599898 concern that
commit, not the subsequent local functions or this guide. The GitHub connector
could not see the repository; the existing local CLI authentication could.
No running CI was cancelled and no new remote run was triggered.

The source archive now identifies the local reviewable artifact. A clean
candidate commit, its cross-platform evidence, anonymous source/issue access
and synchronized public deployment remain outstanding. `state.dcf` remains
`development`; no push, merge, visibility change, release or CRAN submission
was performed. The existing release checklist remains the governing record;
this follow-up adds no separate release-management system.

The final full pkgdown build completed with 94 HTML pages and no missing local
href/src targets. The new guide's attribution, code, language-background field
and checked results table were verified in the rendered HTML. All 148 compared
checkout/archive source members agree byte for byte (DESCRIPTION is excluded
from that byte comparison because R rewrites build metadata). No public site
was deployed; the new guide is currently available in the local `docs/` output.


## Adjacent n-grams without corpus redistribution (2026-10-05)

Added `lexdiv_ngrams()`, `lexdiv_ngram_reference()` and
`lexdiv_ngram_profile()` under adjacent-ngram contract 0.1.0. The implementation
accepts caller-prepared document/segment IDs and original token positions,
retains overlapping bigram/trigram occurrences and document counts, and
constructs or imports local reference aggregates with explicit opportunity
and document totals. Profiles keep document/n/token-type summaries, locations,
reference counts and two coverage denominators. Complete-reference sample
zeros and unlisted incomplete-reference keys have distinct states. External
CSV tables default to incomplete; RDS preserves the complete reference object.

The guide uses authored sequences and checks the `make a decision` exclusion
counterexample, complete versus pruned references, CSV import and RDS replay.
Neither corpus text nor third-party n-gram counts are added. Existing bundled
data, provenance and rights notices are byte-identical to the previous
open-paper archive. There are no new dependencies or automatic downloads.
Preparation labels and resource metadata are caller assertions; consistency
checks and hashes do not establish linguistic boundaries or redistribution
rights. The retained-token index of the general tokenizer is explicitly
insufficient to infer original gaps or sentence IDs.

Evidence is in `reviews/ldfreq-ngrams-20261005/evidence/`:

- Final source archive: 3,201,967 bytes, SHA-256
  `1876614c7bc2d42812197a2d4275140349e70dd6c912f50e39f9a6ca3112f16a`.
  All 152 compared checkout/archive members agree. DESCRIPTION's generated
  build metadata are excluded from that source-byte comparison.
- The initial full installed-package check passed 5,817 testthat assertions
  and failed one new schema-order assertion. It also reported an unqualified
  `setNames` NOTE. The fixes qualify `stats::setNames` and create `status`
  before `missing_reason`; they change only `R/ngrams.R` among runtime,
  test, help, contract and resource members. The initial artifact/logs remain
  under `initial/`, including the actual failure, rather than being overwritten.
- On the corrected installed archive, all 812 n-gram assertions pass with
  FAIL/WARN/SKIP zero. They cover hand-calculated frequencies and means,
  overlapping/gapped/bounded extraction, empty inputs, malformed references,
  exact Unicode/component identity, changed-result rejection, CSV/RDS reuse,
  and 25 generated examples checked by a separate nested-loop oracle.
  The unchanged 5,006 existing assertions and three independent audit scripts
  retain their successful initial-run evidence. This gives 5,818 assertions
  covered by combined evidence, not a claim of a second all-suite execution.
- The final `R CMD check --no-tests --no-manual` reports Status OK. It checks
  installation, namespace, code, help, examples and eleven vignettes; tests are
  intentionally skipped in this command and covered as described above.
  Installed offline workflows and a separate C-locale Unicode/RDS check pass,
  including n-gram operation with the stats package detached.
- The API audit covers 40 exports, 34 S3 registrations and 21 public help topics.
  Full pkgdown completes: 101 HTML pages have no missing local href/src target.
  Key input, missingness, numeric example and saving instructions are present
  in the rendered guide. The first site attempt stopped at a network-restricted
  CRAN metadata lookup; the successful retry had network permission. This was
  a documentation environment issue, not a failed numerical test.
- The standard Rd PDF manual compiles to 63 pages using installed `mendex` as
  the indexer. Its new n-gram pages 23–26 were rendered and visually inspected.
  Help sources are identical between initial and corrected archives, so the
  manual was not rebuilt for a runtime-only fix. Existing TeX overfull-box/font
  warnings remain in the log; this is not an all-page visual-quality audit.
  Browser inspection was unavailable (CUA: no browser available); the HTML
  claims above refer to rendered-content and local-link checks.

The implemented scope is extraction, reference frequency and coverage.
Automatic sentence segmentation, validated adapters retaining excluded spans,
MI/t-score and positional-marginal outputs, streaming construction and a
standard large n-gram reference remain outstanding. Do not describe this as a
validated phraseological-sophistication or employability score. The next
research-facing integration should establish reliable real-text boundaries and
appropriate reference definitions before adding association measures.

These are local, reviewable development artifacts. This turn performs no push,
CI dispatch, visibility change, site deployment, release or CRAN submission.
Earlier remote checks do not cover these functions; the release checklist's
cross-platform and public-availability gates remain open.

## MASC Penn input and position-preserving quanteda integration (2026-10-05)

Added experimental `lexdiv_read_masc()` and `lexdiv_as_quanteda()`. The reader
uses optional xml2 to import local GrAF 1.0 `seg`, `s` and `penn` layers,
retaining source token/segment IDs, supplied lemma/POS/features, exact primary
text, original anchors, Unicode-codepoint positions and source-file SHA-256s.
It supports explicitly selected codepoint or UTF-16 anchors and rejects
unresolved, discontinuous, overlapping or out-of-segment token spans. The
verified dataset is Mini-MASC 1.0's Penn layer; this does not establish support
for all MASC releases, PTB layers or OANC.

The adapter accepts explicit token/segment tables independently of that reader.
It uses quanteda's public APIs, retaining exclusion gaps, trailing positions,
empty segments and source mappings. Each segment becomes a quanteda document;
the guide aggregates back to original documents before reporting document
frequency. It also connects KWIC locations to source annotations and saves the
corpus, adapter and lexical results together. The guide uses four-grams through
quanteda; ldfreq's own reference-profile contract still accepts only n = 2, 3.

quanteda >= 4.5.0 is a new optional dependency. The six bundled example files
are original MIT-licensed fixtures, not a MASC extract. Downloaded MASC/OANC
texts and annotations are not included in the archive. No automatic download,
installation, retokenization, inferred lemma or POS mapping was introduced.

Evidence is in `reviews/ldfreq-masc-20261005/evidence/`:

- Final archive: 3,226,226 bytes, SHA-256
  `0d33986c1121791ed9ffbf9d132ed4f284e9188c8914e186c6172e3e880df763`.
  All 163 compared checkout/archive files agree, excluding DESCRIPTION's
  generated build metadata. `artifact-audit.log` identifies the changed members.
- The initial full `R CMD check --no-manual` reports Status OK, with 5,885
  testthat assertions passing and FAIL/WARN/SKIP zero, plus the existing
  independent audit scripts. That archive and complete check remain in
  `initial/`. The subsequent runtime change only adds the non-UTF-8 import
  guard in `R/masc.R`; its tests and documentation were updated too.
- On the final installed archive all 70 MASC/adapter assertions pass with
  FAIL/WARN/SKIP zero. They cover source identity, malformed links/spans,
  both Unicode coordinate conventions, missing annotations, empty documents,
  exclusion gaps, KWIC mappings, serialization, Unicode identity and locale
  handling. The other 5,818 assertions retain their successful initial-run
  evidence: all other runtime/test/resource files are byte-identical.
  Together this covers 5,888 assertions; it is not a second all-suite run.
- Final `R CMD check --no-tests --no-manual` reports Status OK, including
  installation, code, help, examples and twelve vignettes. Installed API audit
  confirms 42 exports, 34 S3 registrations and 22 function help topics plus
  the package overview. The PDF manual was not rebuilt in this follow-up.
- The final installed Mini-MASC workflow retains 8 documents, 579 supplied
  segments and 7,263 Penn tokens. With an explicit letter/number filter,
  6,718 tokens remain. Case-preserving bigram/trigram occurrence and original
  document counts agree with quanteda. Four-grams, 279 KWIC source mappings
  and full RDS replay also pass. Independent Python standard-library XML
  parsing agrees on all 7,263 source IDs, surfaces, lemmas, POS, positions and
  segment indices, including explicit missingness flags. There are 851 absent
  `base` features and no absent `msd` features; missing lemmas remain `NA`.
- Full pkgdown succeeds; 104 HTML pages have no missing local href/src file
  targets. Rendered guide checks confirm supported input scope, missingness,
  locale, case policy, original segment counts and saving instructions.
  The new guide/help contain no local workspace paths or task markers.
  This is rendered-content/link verification, not a browser visual audit.

Integration findings and their resolutions are preserved rather than hidden:

- `quanteda::as.tokens()` drops empty input strings. The adapter imports a
  collision-free placeholder, removes it with padding through the public API,
  and verifies the resulting token sequence against the supplied positions.
- `quanteda::dfm()` defaults to lowercasing. The first real-corpus comparison
  therefore disagreed with case-preserving ldfreq counts. The corrected
  validation and guide explicitly set `tolower = FALSE`. This was a settings
  mismatch, not evidence of erroneous n-gram arithmetic.
- Non-ASCII import under a C locale changed strings in quanteda 4.5.0; the
  existing roundtrip guard caught it. The final adapter gives an actionable
  UTF-8-locale error before that import and does not change the user's locale.
  A whole-file C-locale probe also produced one upstream quanteda KWIC encoding
  warning; it is retained in `final-source-c-locale.log`. The final normal-locale
  test includes explicit C-locale rejection and ASCII-import checks and is clean.
- The first independent validator assumed every token had `base`; it was
  corrected to verify missingness as well. An auxiliary help inventory counted
  the package overview among function help and initially expected 22 instead
  of 23 total Rd entries. The standalone corrected inventory passes; numerical
  integration had already completed before that auxiliary assertion and was
  not rerun for it. HTML text checks normalize rendered whitespace.
- The first pkgdown attempt could not resolve CRAN in the restricted network
  environment. The permitted retry succeeded. This was a documentation
  environment failure; successful numerical tests were not repeated for it.

The next research-facing step is a controlled comparison of reference choices,
reporting shared items, coverage, missingness and denominators together. Full
MASC/OANC format validation, corpus overlap, register composition and large-data
memory behavior remain separate work. This integration does not validate a
phraseological-sophistication score or individual lexical employability.

All artifacts remain local development candidates. No push, CI dispatch,
visibility change, site deployment, release or CRAN submission was performed.
The release checklist's cross-platform and public-availability gates remain
open; earlier remote checks do not cover these new functions.

## Reference-choice comparisons and Mac UTF-8 clarification (2026-10-05)

Added `lexdiv_ngram_compare()` for one unchanged target extraction and a named
list of at least two n-gram references. It reuses `lexdiv_ngram_profile()`
without changing that function's arithmetic. Each reference's coverage,
available-value mean and missingness remain visible alongside common-item
means, common coverage and differences from an explicit baseline. Target
document/n/token-or-type strata remain separate. Original occurrence positions,
reference denominators, complete flags, metadata and input hashes are retained.

The common set consists of defined rates in all supplied references. Defined
sample zeros belong to it; unlisted incomplete-table keys and rates with zero
opportunities do not. With no common items, means and even the baseline's
difference are missing. Adding a reference may change the set. Matching
preparation/unit/normalization declarations are checked, but remain assertions,
not certification of equivalent preparation or corpus suitability. A row ceiling
is enforced before profiling. There are no new dependencies, significance tests,
automatic rankings, imputation, pooling or changes to existing n-gram semantics.

The expanded offline n-gram guide demonstrates a concrete interpretation error:
pruning raises `choice_item`'s available-value mean from 166,666.67 to 333,333.33,
but the frequency of the shared bigram is unchanged. Common coverage is 1/2 and
the common-set difference is zero. Inputs and output are saved together for RDS
replay. Complete reference count tables are not copied into comparison output.

The Mac question was checked in the actual terminal R session: `LC_CTYPE` is
`C.UTF-8`, `l10n_info()[["UTF-8"]]` is TRUE, and accented Latin, Japanese and
emoji tokens survive the installed quanteda adapter unchanged. No system or
session locale setting was changed for that check. The previous failure was an
intentional plain-C-locale stress test, not a macOS incompatibility. Guide/help
now distinguish `C.UTF-8` from `C` and explain that a different R frontend can
start a separate session; that frontend's settings were not inferred or changed.

Evidence is in `reviews/ldfreq-reference-comparison-20261005/evidence/`:

- Final archive: 3,237,906 bytes, SHA-256
  `f85a28578b352c7b591b70dcbca8b9cda5aa1e1ca0a5f81cb6f27a34a13d4bc9`.
  All 167 compared checkout/archive members agree, excluding DESCRIPTION's
  generated build metadata. Compared with the previous MASC candidate, all
  existing runtime, test and resource files are unchanged. Only the new
  comparison implementation, tests and contract join those categories.
- All 93 comparison assertions pass on the installed archive with no failures
  or warnings. They include hand calculations, opposite directions for unmatched
  versus common-set means, token/type weights, a third-reference intersection,
  defined zeros, zero denominators, empty targets, baseline/order changes,
  incompatible declarations, input mutation, pre-allocation limits, distinct
  bigram/trigram denominators, RDS replay and ten generated examples checked
  against a component-wise oracle. An earlier 89-assertion version of the suite
  also passed under the C locale, including exact Unicode-component comparisons;
  the final four added assertions concern n-specific denominators and order.
- The existing 5,888 assertions retain the previous candidate's combined
  successful evidence, because their runtime and test sources are identical.
  With the 93 additions, evidence covers 5,981 assertions. This is deliberately
  combined evidence, not a claim of another full-suite execution.
- `R CMD check --no-tests --no-manual` reports Status OK, including installation,
  code, help, examples and twelve vignettes. Both repository and installed API
  audits confirm 43 exports, 34 S3 methods and 23 function help topics plus
  the package overview. No PDF manual or cross-platform CI was rebuilt here.
- The installed Mini-MASC workflow holds out document `lw1`, using four SP
  documents and the remaining three WR documents as separate references.
  Source document IDs are disjoint. This is not an audit of overlapping
  excerpts, author identities or population independence. All eight means
  (two references, n = 2/3, token/type weighting) agree with independently
  merged type counts and weighted arithmetic. Full RDS replay is identical.
  The saved aggregates carry corpus attribution, CC BY 3.0 US terms, subset IDs,
  source hashes and the explicit preprocessing label. They are review evidence
  outside the package; no additional corpus text/counts are bundled.
- Full pkgdown succeeds. All 105 HTML pages have valid local href/src file
  targets. The changed guides and new help contain the common-set example,
  limitations and UTF-8 explanation without workspace paths or task markers.
  This is rendered-content and link verification, not browser visual QA.

Mini-MASC demonstrates why availability and empirical support must be separate:
the held-out target has 646 bigram and 559 trigram occurrences. Both complete
references give common coverage one, including sample zeros. Yet only 10.84%
and 8.98% of target bigram occurrences, and 0.18% and 0.72% of trigrams, were
observed in the spoken/written references respectively. The samples contain
3,396/1,831 bigram and 2,993/1,614 trigram opportunities. They are too small
to present as general register norms or evidence of proficiency/employability.

The roadmap now records reference comparison as implemented, with larger
MASC/OANC format, composition, overlap and memory validation still pending,
alongside the existing need for real psycholinguistic-norm item workflows.
These remain local development artifacts. No push, CI dispatch, public-site
deployment, visibility change, release or CRAN submission was performed.


## Whole-document reference construction and full-corpus input audit — 2026-10-05

Added experimental `lexdiv_ngram_reference_build()` 0.1.0. The callback returns
ordinary sealed `lexdiv_ngrams` chunks; the builder reuses their exact counts,
opportunities and document counts. Whole-document IDs must be disjoint across
chunks, including empty documents. The returned standard complete reference
works with existing profiles/comparisons, while source fingerprints, chunk
order and document roster remain separately inspectable. No new dependency,
corpus download, pruning, persistent cache, on-disk index or custom result
class was added. Counts/types and the roster remain in memory; the type limit
is not a guarantee on callback or total memory. Callback side effects remain
the caller's responsibility.

Reader interface 0.2.0 adds modern MASC `documentHeader`/`.hdr` references
without changing token/segment output schemas or relaxing span validation.
The prior Mini-MASC `cesHeader` layout remains covered. All corpus files stay
outside the source/package artifact. The reader and builder remain experimental.

### Corpus identity and observed scope

Evidence directory: `reviews/ldfreq-corpus-scaling-20261005/evidence/`.
`corpus-archives.json` records URLs, sizes, SHA-256 values and agreement with
GitHub's published asset digests. Release asset dates are not corpus versions.
MASC's own README identifies 3.0.0 / 2012-12-15. MASC attribution remains to
the American National Corpus project under CC BY 3.0 US; dataset rights are
separate from the package's MIT license.

- MASC archive: 36,358,521 bytes, SHA-256
  `0b300d96016233c7c79b43559b477a6bb0ed16bb416d5c517eccb108a6228493`.
  All 392 document headers were passed through the reader, using its default
  codepoint offset interpretation. 122 documents passed and 270 were rejected:
  130 first failed token containment within one sentence/utterance, 126 segment
  overlap, nine region-anchor validity, four token overlap, one flat-feature
  validation. First failures are not a complete defect inventory. The nine
  anchor cases contain non-positive seg regions and have equal codepoint and
  UTF-16 text lengths; these are not fixed by changing the R session locale.
  Accepted/rejected IDs and reasons are in `masc-document-audit.csv`; consumed
  source hashes for accepted inputs are in `masc-source-hashes.csv`.
- OANC GrAF archive: 655,230,430 bytes, SHA-256
  `5a26559a1becba41a527cb674fff4fb9c4fb70b276f60422c4f07a0ef23fd867`.
  Its uncompressed contents total 7,412,134,932 bytes. Headers were inspected
  directly in the ZIP without extracting the full corpus. There are 8,824
  data `.txt` files and 9,074 `.anc` files; 9,073 headers parse as XML.
  The prevailing layer is `hepple`, with token regions in the annotation graph
  itself, and there are layout exceptions. Counts of files are not counts of
  validated documents. `oanc-format-inventory.json` records layer patterns and
  the unparsable header. There is no validated OANC importer or whole-OANC
  n-gram run yet. Existing zero-byte workspace files were not altered.

These results deliberately limit the claim: modern-header support is not
whole-MASC support. Excluding failures could change register composition.
Neither accepted subset nor either corpus is certified representative,
independent of the other, or suitable as a standard proficiency norm.
Boundary/annotation reconciliation and overlap/sampling audits remain open.
No corrections, alternate layers or reannotation were silently substituted.

### Independent arithmetic and measured tradeoff

`verify-independent.py` uses Python's XML parser and explicit source anchors,
without calling package code, to reconstruct every retained token of the 122
accepted documents. All 79,059 prepared tokens, document/segment IDs and
original positions agree. Its separate sliding-window counter agrees with all
94,674 type frequencies, document frequencies and denominators: 67,220 bigram
and 57,909 trigram opportunities. Filters retain surfaces containing a Unicode
letter/number and no Unicode White_Space, keep case, and preserve excluded
positions. The actual source texts/counts remain outside the package.

`benchmark.R` reads the same prepared RDS documents in separate processes on
this Mac/R 4.6.1. XML parse time is excluded. One exploratory measurement per
configuration, with no inference of general speed superiority:

| Configuration | Read/extract/build elapsed | Process maximum RSS, decimal MB |
|---|---:|---:|
| Bulk, 122 documents | 1.420 s | 378.4 |
| 122 single-document chunks | 9.678 s | 297.1 |
| 13 chunks, at most 10 documents each | 2.415 s | 292.8 |

The accumulator avoids retaining all occurrence tables, at the cost of
repeated cumulative table merges. Chunk size matters; total memory is not
constant and OANC-scale performance has not been established. All three saved
references have identical keyed counts, document counts and denominators, and
produce identical target lookup/summary/document tables in the final installed
package. Row order and reference hashes may differ with chunk boundaries.

### Final local artifact and checks

Candidate `ldfreq_0.2.0.tar.gz`: 3,248,697 bytes, SHA-256
`063a374215481feb10c9c4ef37e2d564de22e37b9646c6a47c9114080c02185d`.

- Source and installed focused tests: 79 reader/adapter assertions and 49
  builder assertions pass, 128 total, without warnings in the normal UTF-8
  session. They cover authored old/modern header parity, source-coordinate
  preservation, hand-counted bulk/chunk equivalence, document frequencies,
  empty documents/chunks, Unicode component keys, bounds, invalid/mutated
  inputs, duplicate document IDs, callback failures and RDS replay.
- Archive comparison proves only `R/masc.R` and new `R/ngram-build.R` changed
  at runtime from the previous reference-comparison candidate. Only their
  tests changed. All existing corpus resources and specification files are
  byte-identical. The previous 5,911 unaffected passing assertions are reused;
  together with 128 current assertions, coverage is 6,039. This is combined
  evidence across runs, not a fresh all-tests invocation. Checkout/archive
  contents agree for 170 members, excluding DESCRIPTION build metadata.
- `R CMD check --no-tests --no-manual` completes with Status OK: installation,
  code, Rd, examples and all twelve vignettes. Tests are supplied by the
  installed focused run and source-identical prior evidence above. No PDF
  manual, cross-platform CI or CRAN submission was run here.
- Repository and installed API checks agree: 44 exports, 34 S3 methods,
  24 function help topics plus the overview. Full pkgdown build succeeds;
  all 106 HTML pages have valid local href/src file targets. Changed guides
  and builder help have examples/limits without workspace paths or task
  markers. This is rendered-content/link checking, not browser visual QA.
- The optional fresh-process `LC_ALL=C` stress run produced one warning while
  lazily loading quanteda internals during `tokens_remove()`; strict
  stop-on-warning therefore exited nonzero. A standalone public-quanteda-only
  reproduction gives the same warning with ASCII input and retains the
  expected token/padding output. This is not counted as a clean test pass.
  The new builder's 49 tests independently pass with no warning in plain C.
  Normal C.UTF-8 operation is already clean; no user locale or quanteda
  installation was modified and no warnings were suppressed in package code.

The n-gram guide now explains whole-document callbacks, portable source IDs,
empty-document denominators, memory/time tradeoffs and separate exclusion
records. The annotated-corpus guide states the 122/392 scope and OANC boundary.
The roadmap prioritizes boundary reconciliation, a separately validated OANC
Hepple reader, composition/overlap audits and real psycholinguistic norms.
No push, CI dispatch, remote-site deployment, visibility change, release or
CRAN submission was performed.


## Japanese scope assessment and roadmap — 2026-10-05

Reviewed the existing tokenization, annotation-comparison, generic norm and
English TUBELEX interfaces against official UniDic/BCCWJ/TUBELEX and R package
documentation. Added M6 to the roadmap: one optional Japanese annotation
adapter, dictionary/resource identity, exact frequency-key alignment, and a
separate source-span comparison for splitting/merging tokens. This is planned
work, not an implemented Japanese morphological analyzer or an assertion of
cross-language measurement equivalence. Existing English defaults and resource
contracts are unchanged.

`reviews/ldfreq-japanese-20261005/evidence/probe.R` exercises the final installed
candidate from the preceding section using an authored Japanese sentence.
The current Unicode tokenizer returns one punctuation-free span; manually
prepared fine and compound units produce N/V of 7/6 and 5/5, TTR 6/7 and 1,
and bigram/trigram opportunities 6/5 versus 4/3. Source spans and hand arithmetic
agree. These are authored counterexamples, not UniDic/Sudachi output or an
accuracy/validity benchmark. The first probe assertion incorrectly required
integer storage for the existing numeric N/V fields; the probe was corrected
to compare numeric values. No package calculation was changed.

Zotero was searched read-only for Japanese, 日本語 and TUBELEX; the latter two
literal queries returned no records in that helper search. Selected metadata
and Chikamatsu (1996)'s abstract were read. Amano et al. (2007) had metadata
but no abstract in the response. No attachments/full text were read and no
library records were added/modified. The investigation is targeted, not a
systematic novelty review. BCCWJ 1.1's current landing page was verified, but
its linked manual could not be retrieved; older 1.0 redistribution restrictions
are not silently applied as proof of the newer version's terms.

No new analyzer, dictionary, Japanese frequency table or language model was
installed, downloaded or bundled. No package runtime, export, dependency,
public help or vignette changed. The previous source archive and its valid
checks remain the current candidate; full tests/check/pkgdown were therefore
not repeated for this research/roadmap-only change. Local roadmap and
publication HTML were updated. No remote publication occurred.

## Japanese annotation input and R-only analyzer recipe (2026-10-05)

The research-only assessment above is superseded for implementation status by
this entry. Added experimental `lexdiv_import_annotations()` interface 0.1.0:
complete surfaces align exactly to original segment text with whitespace-only
gaps, original positions survive exclusions, and additional feature columns,
missing values, empty documents and caller-declared analyzer/dictionary metadata
are retained. Coordinates are segment-local inclusive Unicode codepoints.
No normalization, POS translation, missing-lemma fallback or segmentation
comparison is inferred. Existing sealed preprocessing and metric contracts are
unchanged. Help, overview, README, NEWS, lifecycle and the public API inventory
describe the boundary.

The new Japanese vignette includes authored offline examples and a separately
executed R-only gibasa 1.1.3 / unidic-lite 1.0.8 (UniDic 2.1.2) recipe.
gibasa was compiled into `tmp/japanese-r/library`; its dictionary archive was
downloaded into the workspace and checked against the release SHA-256.
Dictionary binaries/configuration hashes accompany the actual analysis. Neither
the analyzer nor dictionary is bundled. gibasa is a Suggests dependency only;
the importer uses the existing mandatory dependencies. No Python runtime,
home MeCab configuration change, model download or system installation was
needed for this path. The configuration helper records the actual configuration
hash and verifies that only the explicitly requested system dictionary is active.

Evidence: `reviews/ldfreq-japanese-import-20261005/evidence/`.

- Final installed-archive focused tests: **55 assertions**, no failures or
  warnings under C.UTF-8. Fresh plain-C process: **53 assertions**, no failures
  or warnings, with the one quanteda/Japanese test skipped by its documented
  UTF-8 precondition. These final tests run without gibasa available in the
  active library paths; separate English-text/import smoke checks also pass.
- Actual analyzer output: 16 rows across two source segments plus an empty
  document. Exact hand-checked source spans, `学び` -> `学ぶ` and `まし` -> `ます`,
  retained missing bases/lemmas, and explicit exclusions agree. The selected
  base-form sequence has N=12, V=9, TTR=0.75, 10 bigram and 8 trigram windows.
  quanteda padding, RDS round-trip and restoration of MECABRC pass. This verifies
  software integration on authored examples, not segmentation accuracy or
  validity on learner corpora. See `installed-verification.log` and
  `japanese-actual-gibasa.html`.
- `R CMD check --no-tests --no-manual`: **Status: OK**, including examples
  and all 13 vignettes. The final archive differs from that checked archive
  only in DESCRIPTION build metadata and a corrected test fixture. All runtime,
  help, vignette sources and compiled vignettes are byte-identical. Previously
  built vignettes were reused with `R CMD build --no-build-vignettes`; the final
  artifact was installed and its corrected test file executed in both locales.
- The initial C-locale failure was a test-construction issue: mixing literal
  Japanese with `\u`/`\U` escapes in one R string produced different codepoints
  when parsed under C. Codepoint dumps identified it. Fully escaped construction
  of the affected strings fixes it; no runtime source change was made. The
  initial UTF-8 test run also exposed an incorrect test expectation about the
  existing per-document/per-n n-gram roster; that expectation was corrected.
- Existing runtime files, tests and specification files are byte-identical to
  the previous checked corpus-scaling candidate. Its 6,039 assertions retain
  their documented scope; this turn adds 55 focused assertions, not a fresh
  one-process run of 6,094 assertions. The actual gibasa integration checks
  are additional recorded checks, not counted in that testthat total.
- Public API audit: **45 exports, 34 S3 methods, 25 function topics plus the
  overview**. Full local pkgdown build passed; **108 HTML files** have no broken
  relative local file links. No remote-link availability claim is made.
- `artifact-audit.json` confirms 174 common checkout/archive files are
  byte-identical, excluding DESCRIPTION build metadata, and confirms that
  dictionaries and analyzers are absent from the archive.

Final local artifact: `ldfreq_0.2.0.tar.gz`, **3,275,353 bytes**,
SHA-256 `413f879a2974fdd68c92233d2bdd13c092c330ec82b1c3e8e6ae8b9727f74dbd`.
The preceding checked artifact and logs are retained to identify the exact
scope of reused evidence. PDF-manual compilation and Windows/Linux integration
were not added to this verification. No CRAN submission, push or remote site
publication occurred.

Remaining M6 work: source-span comparisons that permit token splits/merges;
a fixed Japanese TUBELEX variant with tested dictionary/form/normalization
compatibility and collision handling; and human annotation/error analysis on
the intended Japanese research populations. Bundled frequency resources remain
English. The Japanese workflow is experimental and does not establish a common
English/Japanese measurement scale or a novel segmentation algorithm.

## Japanese stimulus norms guide (2026-10-05)

Added `japanese-norms.Rmd` and the explicitly sourced
`inst/examples/japanese-norms.R`. The example accepts a user-supplied item table
and either pinned AoA or BOI CSV independently. It retains IDs, row order,
experimental columns, original source IDs, means, rating counts, SDs and missing
match reasons. It reuses `lexdiv_norm_profile()`; there is no new export or
dependency. Sourcing the file does not download data or write output. Existing
repository-runner code now reuses this example instead of duplicating it.

The guide distinguishes resource terms, constructs and native-speaker norms
from individual L2 knowledge. Its offline illustration uses invented ratings
to show different value coverage across experimental conditions. It explains
separate data acquisition, leading-zero IDs, joins by study item ID, RDS/CSV
output, and explicit WLSP record matching. It records unresolved AWD-J scale
descriptions and BOI publication/file scope. No outside norms are bundled.
README, NEWS, the article index and norm-profile help link to the guide.

Evidence: `reviews/ldfreq-japanese-norm-guide-20261005/evidence/`.

- Installed example verified with both actual, pinned aggregate tables:
  independent token/type arithmetic, preserved groups/IDs/order/n/SD, repeated
  terms, reordered input, empty input and unmatched items. Duplicate IDs,
  missing terms, output-column collisions, wrong resource files and directory
  inputs are rejected. RDS and UTF-8 CSV round trips retain Japanese and IDs.
- The two changed Japanese vignettes were rendered successfully. The other
  compiled vignettes were reused from the preceding archive. Package build
  used `--no-build-vignettes` and contains 14 vignettes.
- Pre-index-fix archive `R CMD check --no-tests --no-manual --no-vignettes`:
  **Status: OK**, including installation, help, examples and vignette structure.
  This is a scoped check, not a fresh full numerical-test/vignette run.
- Final installed discovery found a stale 13-entry `build/vignette.rds` inherited
  from the reused archive, despite all 14 guide files being present. Rebuilt the
  index with R's vignette tooling using existing source/output pairs. The final
  archive differs from the checked one only in that index and DESCRIPTION build
  metadata. It was separately installed; all 14 guides are discoverable and
  `vignette("japanese-norms")` resolves to an existing HTML file. The installed
  example matches the checkout and a BOI lookup succeeds. Numerical tests and
  already rendered guides were not rerun for this index-only repair.
- Archive comparison confirms byte-identical R runtime, existing tests,
  specifications, existing data and NAMESPACE versus the prior Japanese-input
  candidate. Its successful evidence retains its previous scope. All 176
  common checkout/archive members match, apart from DESCRIPTION build metadata.
- Local pkgdown build succeeded using its lazy rebuild path. All 109 HTML
  pages have no broken relative file links. The initial site's CRAN metadata
  lookup was blocked by network restrictions; only the site stage was resumed
  with network access, without rerunning completed vignette rendering.

Final local artifact: `ldfreq_0.2.0.tar.gz`, **3,290,610 bytes**,
SHA-256 `783c2c4be49607c21c01bfa204b17a95d08bf17544148e495b54b58498321c58`.
No remote site deployment, push or CRAN submission occurred. No new
Windows/Linux or PDF-manual validation is claimed.

## Explicit WLSP record review (2026-10-05)

Added `inst/examples/wlsp-items.R`, sourced explicitly through the Japanese
norms guide. `review_wlsp_items()` reads the pinned WLSP-familiarity v4.0 CSV,
lists every exact-spelling candidate, and applies explicit item/record/reason
decisions. It retains headings, readings, classification and record type, plus
the five published KNOW/WRITE/READ/SPEAK/LISTEN estimates. Even a single candidate
requires review. Original item IDs, order and experimental columns stay intact;
unmatched, unreviewed and selected rows remain distinct. Selected source NA
values remain NA. No resource data, new export or dependency is bundled.

The guide adds acquisition, candidate inspection, explicit choices, coverage by
condition, decision CSVs and RDS restoration. It states that ID/spelling checks
do not establish contextual validity or resolve the upstream methodological
question about repeated heading/reading records with different estimates.
README and NEWS point to the added workflow.

Evidence: `reviews/ldfreq-wlsp-review-20261005/evidence/`.

- Verified actual source IDs and all five estimates, repeated spellings,
  preserved groups/order, empty and unmatched input, missing source estimates,
  no implicit Unicode normalization, and a bounded candidate expansion.
  Invalid/foreign IDs, duplicate choices, blank reasons, numeric record IDs,
  output collisions and wrong snapshots fail. CSV leading zeros and complete
  RDS/decision reapplication round trips pass.
- The exact final archive was installed by `R CMD check --no-tests --no-manual
  --no-vignettes --no-examples`: **Status: OK**. Existing tests/help examples
  and unchanged vignette computations were not repeated. The changed guide was
  rendered separately. All three published WLSP code blocks then ran unchanged
  using the installed example and actual local CSV: 5 items, 12 candidate pairs,
  3 selected, 1 unreviewed and 1 unmatched; save/restore passed.
- The vignette index was regenerated before the build; all 14 guides are
  discoverable in the installed artifact. The local site's 109 HTML pages have
  no broken relative file links. No remote-link uptime claim is made.
- Archive audit confirms unchanged R runtime, tests, specifications, existing
  data and exports against the previous Japanese-norm-guide candidate. All 177
  common checkout/archive members match, excluding DESCRIPTION build metadata.
  External norm CSVs, decision tables and analysis RDS files are absent.

Final local artifact: `ldfreq_0.2.0.tar.gz`, **3,297,993 bytes**,
SHA-256 `197c52105b58ca991043062f8592cd8c8cbb5619c8e7aa1fe42a99b914240dd6`.
No remote deployment, push or CRAN submission occurred; no new cross-platform
or PDF-manual validation is claimed.


## Japanese frequency and combined stimulus review (2026-10-05)

Added `inst/examples/japanese-tubelex.R` and the `japanese-stimuli` guide.
The explicitly sourced helper reads only the pinned Japanese base table at
TUBELEX commit `7cb5fb36add76b83a266d1967536e1a1d3faa513`, verifies SHA-256
`be1a66ac600d5e7efe6a301f63fba5321352742ae5dbaaa231529cdf2ab11710`, and reuses
`lexdiv_norm_profile()` for per-million frequency and video/channel proportions.
It retains supplied bases, original spellings, NFKC/lowercase keys, transformation
flags, unresolved/unmatched rows and the published denominators. It does not
claim full tokenizer replication, reading-specific counts or new validity evidence.
No Japanese frequency/norm tables, new exports or mandatory dependencies are bundled.

The guide joins separately obtained TUBELEX, WLSP, AoA and BOI by study item ID,
retains source-specific missingness, and inspects within-condition distributions
and complete subsets. It saves both a review CSV and an RDS with source hashes,
profiles and explicit WLSP decisions. The annotation connection retains original
positions and dictionary declarations from the existing gibasa input workflow.
README, NEWS, related guides and the article index are synchronized.

Evidence: `reviews/ldfreq-japanese-stimuli-20261005/evidence/`.

- Exact archive installation and structural/document checks: `R CMD check
  --no-tests --no-manual --no-vignettes --no-examples`, **Status: OK**.
  The first invocation stopped before installation because the existing local
  gibasa library was not on its library path; the completed invocation specifies
  that library. This was an environment lookup issue, not a numerical failure.
- All real-data processing/save chunks from the installed guide ran unchanged
  with local files: 9 items; frequency 7 matched, 1 unmatched and 1 unresolved;
  only 3 items had all four selected values. AoA/BOI means were independently
  compared with original source cells. Repeated 人気 items retained separate
  WLSP records and the same aggregate base frequency, as intended.
- The already verified actual gibasa/UniDic annotation object was reused:
  12 retained tokens, original positions preserved, all frequency lookups matched.
  This is a small input-path check, not a segmentation accuracy benchmark.
- `experiments/validate-japanese-tubelex.R` verifies the installed helper against
  the fixed aggregate: denominator arithmetic, duplicate query forms, NFKC/case,
  no trimming, unmatched/unresolved/empty inputs, invalid IDs/reasons/snapshots,
  reserved total metadata, column collisions and full RDS restoration.
  CI now runs this small check after the existing installed-inventory audit on
  Linux, macOS and Windows release R, reusing that installation.
- Core R, Rd help, tests, specifications and bundled resources are byte-identical
  to the previous WLSP candidate. Their numerical evidence is reused locally;
  the pending consolidated remote revision will receive the full CI matrix.
  Changed guides were rendered and the installed vignette index regenerated.

Local archive: `ldfreq_0.2.0.tar.gz`, **3,317,556 bytes**, SHA-256
`dd11c8afb1a753d6aa46ff08ee6392b543bfc34176d3b5b3613a97a103b82593`.
This local hash does not identify independently rebuilt CI archives.
Repository visibility is still private and Pages serves main at the repository
root (read-only confirmation on 2026-10-05). No visibility change, main merge,
remote site deployment or CRAN submission is included in this preparation step.

### Cross-platform preparation corrections

The first consolidated PR run (`37260822842`, commit `f95f89e`) completed without
cancellation. It exposed three distinct issues: R 4.1 dependency resolution tried
to install gibasa >= 1.1.3 although that optional backend needs R >= 4.2; the old
convenience test fabricated a `tokens` class instead of a real quanteda object;
and Windows checkout converted the offset-based MASC example's LF to CRLF.
These are corrected by declaring the optional-backend CI exclusion, constructing
real quanteda tokens in the test, and retaining exact MASC example bytes in
`.gitattributes`. The core computations were not changed. The future candidate
NOTE policy now permits exactly the two declared unavailable optional backends
on R 4.1; its narrow acceptance/rejection check is runnable and included in CI.

A separate C-locale probe exposed native-encoding conversion in the new frequency
reader. It now marks UTF-8 fields without conversion to the native locale.
The installed helper's complete check passes in both C.UTF-8 and C locales;
the test script uses Unicode escapes to keep source parsing independent of the
process locale. The Japanese guide states gibasa's R >= 4.2 requirement.
The corrected convenience test passes locally (25 expectations), and a checkout
with `core.autocrlf=true` preserves the MASC source bytes.

The revised archive again passes the same bounded install/document check with
Status: OK. The installed real-resource workflow and token connection also pass.
The 110-page site has no broken relative file links; 179 common source/archive
files agree, excluding generated DESCRIPTION metadata. No external Japanese tables
are present. The superseding local archive is **3,318,227 bytes**, SHA-256
`5651682fcaf825de01e44479033f5129fff217005d0352bcb587501b709a0d03`.
The final remote revision will verify the supported matrix; record its outcome
against its commit rather than treating this local archive as the CI artifact.

### Complete the existing publication gates without changing package calculations

Run `37261636301` at `edc3540` passed the current-R package checks (the macOS
log reports 6,094 passing expectations), R-devel, the PDF manual and both
English TUBELEX builders. Release-R jobs subsequently stopped at the separate
resource-inventory gate because the authored MASC example files were not in its
explicit extdata set; this was not a failed numerical test. R 4.1 stopped before
checking: quanteda needs Matrix >= 1.5-0, while available current Matrix releases
need newer R than 4.1.

The inventory gate now explicitly enumerates all six authored example files and
compares them across source/platform/installed artifacts. Unlisted extdata still
fails. The installed lexical-resource manifest still correctly declares two
reference tables; the examples are not a third reference corpus. The existing
local source archive was reused for the corrected audit: **1,757 assertions,
45 members**, source/platform/installed byte equality. The package archive and
all numerical code, tests, documentation and example source bytes are unchanged
by this CI-only correction, so no local numerical suite or document build was
repeated.

The R 4.1 jobs now pin `Matrix@1.6-5`. The official CRAN archive DESCRIPTION was
checked (R >= 3.5.0; SHA-256
`726c8d46626e73d1d6e76a74679813c6df96ffdee1aee45d94e7014cb4ceb97d`).
A source-dependency resolution preflight for R 4.1.3 passed for the package's
check dependencies, omitting only the already declared optional gibasa/textstem
backends; it is a solver check, not execution under R 4.1. The actual R 4.1 CI
remains the runtime check. CI-only changes are consolidated for one final push;
existing workflow gates rerun on that revision. Neither prior run was cancelled.

R 4.1's actual setup still differed from the first dependency preflight: the
setup action defaults to `dependencies = "all"`, which pulled Matrix's optional
Bioconductor `graph` enhancement. The R 4.1 setup now explicitly keeps Depends,
Imports, LinkingTo and Suggests, excluding only Enhances; ldfreq declares no
Enhances. It pins MASS 7.3-60 as well (official DESCRIPTION: R >= 4.0), satisfying
Matrix's optional dependency without selecting a current R-incompatible MASS.
The full Suggests-inclusive dependency preflight under exactly those dependency
types passes for R 4.1.3; the earlier hard-dependency-only result is not claimed
to cover this setup. Current-R setup remains unchanged. No package source,
archive, numerical tests or rendered documents were changed for this correction.

## Contextual ambiguity review (2026-10-05)

Added experimental `lexdiv_ambiguity_review()` with optional quanteda KWIC,
complete verified imports, original segment text and positions, caller-supplied
candidate inventories, stable occurrence IDs and snapshot-bound reviewer
decisions. Selection, unresolved review, unreviewed occurrences and absent
candidates remain distinct. No automatic sense choice, external semantic data,
new dependency or change to existing numerical estimators is included.

An added counterexample showed that quanteda 4.5.0 fixed search matches both
composed and decomposed Unicode spellings. The review now checks original
surface/query equality before accepting a hit, preserving the declared exact
matching contract. The initial archive and initial check did not include this
correction; the final archive and final test result below supersede them.

Evidence: `reviews/ldfreq-ambiguity-review-20261005/evidence/`.

- New tests: **73 PASS, 0 FAIL/WARN/SKIP** in `targeted-results.csv`, covering
  English/Japanese contexts, original spans, candidate and source changes,
  duplicate/foreign decisions, missing candidates, padding, exact case/Unicode
  matching, reordered decisions, and RDS/CSV round trips. Existing annotation
  input and MASC/quanteda tests also passed; unchanged numerical code retains
  its earlier evidence. No full numerical suite was repeated.
- The final source archive is **3,342,098 bytes**, SHA-256
  `7d8a0ca6990c374f4a255b4c55fb338d3d1f346e63700b981e628a47fc36169c`.
  All 179 R/man/tests/vignettes/inst source files agree with the current
  checkout; generated documentation is recorded separately. All 12 extdata
  files are byte-identical to the preceding Japanese-stimuli archive.
- Exact final archive: `R CMD check --no-tests --no-manual --no-vignettes`,
  **Status: OK**. Installation, code/Rd checks and examples completed.
  The new/changed guides were executed and rendered separately; unchanged
  compiled guides were reused. There are **16 discoverable installed guides**.
- The final installed function accepted the previously saved real gibasa /
  unidic-lite annotations and preserved all source data and the three selected
  occurrence locations. This is integration evidence, not semantic validation.
- Public API audit: **46 exports, 34 S3 methods, 26 function help topics**.
  A 72-page PDF manual was built. Local pkgdown produced **112 HTML files**
  with no missing relative file links. Its first attempt failed only on a
  sandboxed CRAN hostname lookup; document construction resumed with permitted
  network access, without repeating the package check or PDF build.

This is local macOS/R 4.6.1/quanteda 4.5.0 evidence. The previously successful
cross-platform CI at `2717dcba` predates this feature. This change has not been
pushed, tested in the remote OS matrix, merged, deployed or submitted to CRAN.
Resource-backed automatic candidates, multi-token decisions, inter-rater
adjudication, sense-frequency estimates and semantic-model validity remain
outside the implemented scope.

## Paired contextual reviews and WLSP candidates (2026-10-05)

`lexdiv_compare_ambiguity()` pairs two complete reviews by occurrence ID and
retains both original reviews, their contexts, reviewer IDs and reasons. It
reports conditional selection agreement together with the fraction of all
target occurrences selected in both reviews, and keeps non-agreements in a
review queue. Unresolved, unreviewed and absent-candidate cases remain distinct;
two unresolved decisions are not treated as a semantic agreement. Source,
inventory and resource identities must agree; context windows may differ.
Review results now include a full-content fingerprint. Older saved reviews can
be regenerated from their retained inputs and decisions before comparison.

The separately sourced `wlsp_ambiguity_candidates()` recipe reuses the pinned
WLSP-familiarity v4 reader. It returns exact record IDs, readings and
classification metadata, plus coverage and source/license declarations. It
does not download or bundle the external CSV or return its rating columns as
sense estimates. Resource records are not a validated inventory of discrete
psychological meanings. Agreement is descriptive: no automatic adjudication,
chance-corrected coefficient, accuracy or independent-rater claim is made.

Evidence: `reviews/ldfreq-ambiguity-comparison-20261005/evidence/`.

- **126 PASS, 0 FAIL/WARN/SKIP**: 53 new comparison expectations plus the 73
  review expectations. Hand-counted outcomes, denominators, no selections,
  absent targets, review/order/window differences, stale or altered results,
  term-local candidate IDs, status pairs and save/read are covered.
- The separately acquired real CSV produced 2 / 7 / 1 / 0 records for the
  authored Japanese query set. The installed recipe's IDs, readings and
  classifications matched independently read source columns. Input rejection,
  KWIC integration, disagreement counts and RDS replay passed. This is software
  integration evidence, not a contextual semantic validation study. A missing
  closing brace in the repository-only validation script initially prevented
  that script from parsing; only the corrected script was rerun.
- Archive: **3,354,100 bytes**, SHA-256
  `3c072a7e822fc9a95667450f82498a2a9fe01651f99ae08c35231eb33dcca880`.
  Package-source equality is recorded in `source-equality.tsv`; all 12 extdata
  files are identical to the previous archive. Excluded development and
  experiment files, including the real-resource validation script, are absent.
- Exact archive: `R CMD check --no-tests --no-manual --no-vignettes`, **Status:
  OK**, including installation, code/Rd checks and runnable examples. The two
  changed guides were executed and rendered separately; other compiled guides
  were reused. All **16 installed guides** are retained. No unrelated local
  numerical suite was rerun.
- API: **47 exports, 34 S3 registrations, 27 function help topics**. A **74-page
  PDF manual** and **113 HTML files** built; relative file-link target failures:
  **0**. Compilation and link checks are not a complete visual/usability review.

These are local macOS/R 4.6.1/quanteda 4.5.0 results. The previous successful
remote CI at `2717dcba` does not verify these two ambiguity APIs. The changes
are consolidated for PR #21 and its existing OS-matrix workflow; remote results
must be identified by the actual new commit/run. No repository visibility,
main-branch merge, deployment, release-state or CRAN-submission change is made.


## Reviewed WLSP polysemy resource connection (2026-10-05)

Added two explicitly sourced helpers in `inst/examples/wlsp-polysemy.R` and the
`japanese-polysemy` guide. They read only the pinned v1.0 polysemous.txt file,
retain exact WID/WORD/LABEL keys, and require explicit item-to-display-key and
candidate decisions. They reuse existing norm-profile and contextual review
APIs. Full-item selection/value coverage is distinct from the selected-WID
profile; unresolved keys, unmatched keys and unreviewed candidates are retained.
No new export, dependency, formula or external rating table is introduced.

The actual source has 100,827 WIDs and 84,152 distinct display words. The
released signed estimates are preserved without rescaling or interpreting them
as sense counts. Exact normalization details are not established by the inspected
README/preprint. Resource IDs are not equated with familiarity IDs, readings or
lexemes; a KWIC choice does not validate a context-specific rating.

Evidence: `reviews/ldfreq-wlsp-polysemy-20261005/evidence/`.

- The installed helper passed independent all-character source-column and
  numeric-cell comparisons, hand-checked selection denominators and weighted
  means, unmatched/unresolved/empty inputs, reordered decisions, wrong resource
  IDs and types, altered-file rejection, KWIC integration and RDS replay.
- All four published guide chunks were executed against the already acquired
  file, with full-item coverage 3/6 and original contextual IDs retained. The
  original purl attempt left eval=FALSE chunks commented; execution was then
  checked explicitly by enabling evaluation in a local copy of the guide text.
- The reader and selected-item lookup also passed under the C character locale;
  this does not remove the separate UTF-8 requirement for Japanese KWIC.
- Archive: 3,370,304 bytes, SHA-256
  `9fac0b2af971d84f3d93eda9c6e4d2ad8cec0d81aa44acf8b5dfbafcc515a20d`.
  Exact-archive `R CMD check --no-tests --no-manual --no-vignettes`: Status OK,
  including examples. Its installed helper passed the real-resource validator.
- All 186 compared source/help/test/example/vignette files match the archive;
  127 core/test/help/resource members are byte-identical to the previous archive.
  The earlier successful numerical suite and 74-page manual remain applicable
  to those unchanged files. Neither was rerun locally. A missing closing brace
  in the local build runner was corrected before the build could start.
- All 17 guides are installed. The three new/changed guides were rendered and
  the local site built with 114 HTML files and zero missing relative file
  targets. No source norm table or excluded experiment/development directories
  are in the archive. The API audit remains 47 exports, 34 S3 methods, 27 topics.

The new installed-helper validator is an explicit release-R CI step on Linux,
macOS and Windows. It obtains the pinned file in runner temporary storage;
ordinary package loading, tests and document builds do not download it. It
retains the source credit/license in the helper and does not upload a data
fixture. The previous successful CI at 1d7497db does not cover the new helper;
PR #21 must record the actual new run. This is a software integration check,
not a new semantic or behavioral validation study. Publication state is unchanged.

## External contextual model outputs (2026-10-05)

Added experimental `lexdiv_import_contextual()` and a separately invoked,
offline Hugging Face example. Embeddings and candidate scores are paired to
intact reviews using occurrence/review IDs, original text and codepoint spans.
Human selections remain separate; skipped/error/absent model output remains in
all-occurrence coverage. Full-segment input is the initial supported context
policy. No model, external corpus or new R dependency is bundled.

Evidence: `reviews/ldfreq-contextual-models-20261005/evidence/`.

- New importer: 66 expectations passed. The 126 ambiguity review/comparison
  expectations also passed after sharing the existing review validator. The
  installed API naming/smoke checks add 17 passes: 209 focused expectations in
  total. The first new-test attempt failed because a fixture was file-local;
  moving it unchanged into a test helper resolved the test setup.
- The Python span validator passes three tests with crossing/gapped/overlapping
  offsets, unknown/special tokens, repeated words and Unicode codepoints. Actual
  cached English BERT processes two English examples and skips two Japanese
  targets; a multilingual MiniLM base model processes all four. Independent
  char-to-token mapping and explicit vector addition agree with both outputs.
  A six-case actual-model stress input processes repeated words, a target after
  an emoji and a four-subword target; it skips boundary-crossing and overlong
  cases. These are transport/alignment tests, not semantic accuracy estimates.
- The installed guide's four chunks, including its optional R-to-Python call,
  complete with four 384-dimensional vectors and an RDS round trip. The first
  installed call exposed a Transformers 5.3 tokenizer compatibility check that
  attempted network access despite `local_files_only`; the script now sets
  offline/telemetry environment variables before importing model libraries.
  This is confined to its explicitly invoked child process. The final script
  matches the installed copy and executes without caller-set offline variables.
- Final archive: 3,393,013 bytes, SHA-256
  `deae74348ce09ce107a7a8124a6437f8a74cd90053953fff53455be3baea07ba`.
  `R CMD check --no-tests --no-manual --no-vignettes` is Status OK, including
  examples. All 193 source members agree (DESCRIPTION is compared as DCF values
  because R build reformats it and adds packaging fields); 123 core/test/help/
  resource members and all 12 resource files match the preceding archive.
  The unchanged numerical suite is reused locally; the PR OS matrix runs the
  current complete package checks. No external model files are in the archive.
- API audit: 48 exports, 34 S3 registrations, 28 function help topics. The two
  new/changed guides were rendered, other compiled guides reused, and the final
  package installs 18 guides. A 76-page PDF manual and a 116-HTML pkgdown site
  build successfully, with no missing relative file targets. This is not a
  complete visual or human usability evaluation.

The final check initially lacked the existing gibasa library path when invoked
outside the build runner; the dependency-stage failure was resumed with the
established library paths, without rebuilding unchanged guides or rerunning
successful numerical tests. pkgdown's CRAN metadata lookup required network
access; its build resumed after the checked library was available. The actual
commit-specific remote CI is recorded in PR #21, separately from these local
macOS/R 4.6.1 results. Release metadata, visibility, main merge, deployment and
CRAN submission remain unchanged. Independent sense labels, behavioral data,
model-assistance time savings and research validity remain to be evaluated.

## Comparing contextual scores with a reference review (2026-10-05)

Added experimental `lexdiv_evaluate_contextual()`. It ranks supplied candidate
scores with an explicit direction and absolute tie tolerance, requiring the
complete supplied inventory and a unique best score. Ties and incomplete scores
abstain. Overall/per-term counts retain reference/prediction/pair coverage,
singleton predictions and unscored reference candidates. Term-specific confusion
counts and the non-agreement KWIC queue preserve original occurrences and both
inputs. Reference protocol, model exposure and evaluation role are declarations,
not evidence that a reference is valid, blinded or held out. No classifier,
inference, model weights, external data or new dependency was added.

Evidence: `reviews/ldfreq-contextual-evaluation-20261005/evidence/`.

- The final archive's installed tests pass 94 expectations: 77 new evaluation,
  15 API-naming and two smoke checks. Cases cover absent/tied/partial scores,
  lower/higher direction, tolerance, stale/modified inputs, row order, Japanese
  candidate scopes, absent targets, empty inputs and RDS replay. Final review
  stabilized the empty prediction-status column as character and added a check.
- Four actual installed guide chunks run. The authored example distinguishes
  conditional agreement 1/1 from prediction coverage 1/4 and matching predictions
  among selected references 1/3. These are not empirical accuracy results.
- The previously saved real-model output (four 384-dimensional vectors) passes
  the new evaluator without inventing predictions or judgments; all occurrences
  and the complete input survive an RDS round trip. Model inference and the
  unchanged Python alignment tests were not rerun locally.
- Final archive: 3,403,076 bytes, SHA-256
  `0860fe05f0c4744af36544985379581dfebaa45a02ce16b75d264ed7a07f1672`.
  Exact-archive `R CMD check --no-tests --no-manual --no-vignettes` is Status OK,
  including examples. All 196 compared source members agree (DESCRIPTION uses
  normalized DCF values); 129 core/test/help/resource members and all 12 resource
  files match the preceding archive. No external models or excluded development/
  experiment directories are bundled.
- API audit: 49 exports, 34 S3 registrations, 29 function help topics. The
  changed guide was rendered and unchanged compiled guides reused. There are
  18 installed guides, a 78-page PDF manual and 117 local site HTML files with
  zero missing relative file targets. The empty-result code correction does not
  change help or rendered examples, so those document checks were retained.

An initial evidence CSV write failed on a test-result list column after all 93
then-current expectations passed. The unexecuted guide checks resumed separately;
final test results are saved as RDS. This was a result-recording failure, not a
package test failure. The final code correction was checked in the rebuilt
archive. Full commit-specific remote checks are recorded in PR #21; existing
local numerical evidence is reused for unchanged code. These software checks do
not establish gold-label validity, semantic accuracy or human-review time savings.
Publication state remains development.

## Supervised contextual scoring baselines (2026-10-05)

Added experimental `lexdiv_score_contextual()` to connect imported target
embeddings, separate training labels, contextual evaluation and KWIC review.
It returns raw-mean centroid cosine and unsmoothed training-label counts as
separate contextual outputs. Query labels and prior scores are never used to
fit or score either baseline. Candidate inventories/resources, model declarations
and dimensions must match; shared document IDs and exact target-context copies
are rejected. These checks do not establish independent annotations or detect
all forms of leakage. Missing/zero vectors, canceling centroids, unobserved
candidates and all original model statuses/reasons remain auditable.

Evidence: `reviews/ldfreq-contextual-scoring-20261005/evidence/`.

- Installed tests pass 227 expectations: 67 new scoring checks, 66 importer,
  77 evaluation, 15 API naming and two smoke checks. Hand-computed centroids,
  negative cosines, training counts, extreme scaling, input separation,
  query-label invariance, empty/missing inputs, Japanese candidate scopes and
  complete-result RDS replay pass. The input validator was shared unchanged
  between scoring and evaluation.
- Five installed guide chunks execute, including the complete authored
  English/Japanese scoring and baseline-comparison example. The guide explains
  training-population differences, coverage, retained reasons and why these
  constructed outcomes are not empirical accuracy results.
- The cached, pinned multilingual model processed four of five new training
  occurrences. The `popularity` candidate's example, `人気の店だ。`, was skipped
  by the unchanged exact-span rule.
  No replacement example was selected to hide this exclusion. Four previously
  saved query vectors were reused; cosine has six scores and frequency eight.
  Both Japanese queries retain incomplete cosine inventories and abstain.
  Independent direct vector sums/cosine calculations agree within 1e-12;
  the complete result passes RDS replay. No query gold labels were supplied,
  so reference agreement remains NA. This checks integration, not WSD accuracy.
- Final archive: 3,417,814 bytes, SHA-256
  `07b501dea1a2428140b47934183c6521fc5e86801379deb49e68bae55104252a`.
  Exact-archive `R CMD check --no-tests --no-manual --no-vignettes` is Status OK,
  including examples. All 199 compared source members agree (DESCRIPTION uses
  normalized DCF values); 129 core/test/help/resource members and all 12 resource
  files match the preceding archive. No external models or restricted corpora
  are added. Unchanged numerical calculations were not rerun locally.
- API audit: 50 exports, 34 S3 registrations, 30 function help topics. The
  changed guide was rendered, with other compiled guides reused: 18 installed
  guides, an 81-page PDF manual and 118 local site HTML files, with no missing
  relative file targets. This is not a complete visual/usability evaluation.

Initial test expectations were corrected for retained no-candidate status and
changed reference fingerprints; an empty-input fixture was changed to the
annotation importer's required segment roster. The actual-model validator's
initial all-five-vectors assumption was corrected after inspecting the recorded
skip; inference was not repeated. An HTML assertion used a source chunk name
instead of the rendered section ID and was corrected without rebuilding docs.
The commit-specific remote matrix is recorded in PR #21. Publication state
remains development; semantic validity and human annotation evidence remain
separate research requirements.

## Reusable contextual study folder (2026-10-05)

Added three installed R scripts for authored English/Japanese study preparation,
development/frozen evaluation, and read-only replay. Document/group separation,
exact target-context copies across all three partitions, individual judgments,
unresolved references, coverage and common-evaluable cases remain explicit.
Settings and complete training inputs are saved before test scoring; test scores
are saved before the reference labels are opened. This workflow neither enforces
blinding nor turns authored labels into independent judgments. A real study must
replace the source, sampling, annotation protocol and model outputs.

Evidence: `reviews/ldfreq-contextual-study-20261005/evidence/`.

- The final archive's installed tests pass 50 expectations: 33 template checks,
  15 API-naming and two smoke checks. Cases include shared groups, mismatched
  document metadata, blank/duplicate IDs, development contexts renamed into
  test documents, overwrite rejection, no common evaluable occurrences and
  unchanged saved files after repeated reporting.
- Each script passes in a separate fresh R session. Reporting succeeds after
  the live input directory is moved away. The authored comparison has centroid
  prediction coverage 3/4 and conditional agreement 2/2, versus frequency 4/4
  and 2/3. Both match 2/3 of all selected references; on their common two cases,
  agreement is 2/2 versus 1/2. No empirical accuracy claim follows.
- Exact archive: 3,432,925 bytes, SHA-256
  `7c3425c40d7e8076317ccac01e8d0913b8c3398be621a60a4bf2ed518866b569`.
  `R CMD check --no-tests --no-manual --no-vignettes` is Status OK, including
  examples. All 203 staged source members match the checkout before build;
  archive source identity is also checked, with DESCRIPTION normalized by R.
  All 166 compared prior core/test/help/resource members and 12 resource files
  match the preceding archive. No exported function or numerical implementation
  changed; the 227 earlier focused expectations and actual-model evidence at
  `980372ff` remain applicable to those unchanged files.
- The changed contextual guide was executed and rendered; the 17 unchanged
  compiled guides were reused. The archive retains 18 installed guides. Local
  home, NEWS and contextual-article pages were rebuilt. Help is unchanged, so
  the existing 81-page PDF manual was retained rather than regenerated.

The site build initially stopped while fetching CRAN metadata under restricted
network access; only that document build was retried with network access.
The template's initial source-object accessor was corrected to the existing
review `source` field. The no-vector test was corrected to retain a zero-row
matrix with the declared dimensions; this did not require changing the scorer.
Commit-specific OS checks are recorded in PR #21. Publication remains development.


## Source-aligned phrase-list example (2026-10-05)

Added an explicitly sourced helper and an authored English/Japanese demo. The
helper validates a complete external annotation import, searches supplied token
sequences with quanteda, verifies original unnormalized surfaces, and returns
source-text KWIC with segment-local codepoint spans. Excluded token slots and
segment/document boundaries remain barriers. All nested/overlapping and
per-ID matches remain available, while token coverage uses their union.
Document-by-ID counts retain zeros; coverage is NA for zero retained tokens.
No phrase list, corpus, parser, new dependency or exported function was added.
The guide describes preparation, denominators, RDS replay, scope and separate
human interpretation. Exact surface matches are not sense/function judgments.

Evidence: `reviews/ldfreq-phrase-list-20261005/evidence/`.

- Final installed checks: 64 expectations pass, without failures or warnings:
  47 phrase-example checks, 15 API naming checks and two smoke checks. Cases
  include 4+ token expressions, nesting, repeated overlaps, duplicate sequences
  with different IDs, punctuation and exclusion gaps, segment/document edges,
  empty documents, absent lists, original Unicode including decomposed forms
  and an emoji prefix, underscores, source tampering and malformed inputs.
- Separate fresh R sessions prepare/save and replay the result identically.
  UTF-8 occurrence CSV roundtrip also preserves the table. The authored English
  example has four per-ID occurrences and nine union-covered tokens out of
  12 retained tokens; the Japanese example preserves its original unspaced text.
- Archive: 3,450,717 bytes, SHA-256
  `601029b820af7d6959ef3a2a893687943d835fd19d792037f9f1dbb3b6ca1652`.
  Exact-archive `R CMD check --no-tests --no-manual --no-vignettes` is Status OK,
  including examples. All 206 staged source members match the checkout;
  archive source identity and normalized DESCRIPTION fields also agree.
  All 137 prior R/test/help/extdata members and all 12 extdata files match the
  preceding archive. Prior successful numerical/model checks remain applicable
  to unchanged files; those computations were not repeated locally.
- The changed annotated-corpora guide executes and renders; 17 unchanged
  compiled guides are reused. Home, NEWS and that article were rebuilt locally.
  There are 18 installed guides and 118 local HTML files with zero missing
  relative file targets. Help is unchanged; the prior 81-page manual is retained.
  API audit remains 50 exports, 34 S3 registrations and 30 public help topics.

The first test run exposed that the demo sourced its helper into the global
rather than the supplied environment; local sourcing fixes execution in tests
and user environments. This helper is deliberately for modest lists and retains
all source data and zero-count cells; no large-corpus performance or empirical
validity claim is made. The exact commit's OS checks are recorded in PR #21.
Publication state remains development.


## Annotation sensitivity example (2026-10-05)

The two installed scripts connect before/after supplied lemma and UPOS labels
with original-text context, all-word surface/lemma and content-lemma TTR/MATTR,
and bundled NJ8 coverage. They preserve every selection position, missing
labels, reference denominators, non-computable paired differences and complete
inputs for replay. Source and processed hashes must both match the supplied
original text; changed segmentation or transformed-text offsets are rejected.
No export, numerical method, dependency, model or external corpus was added.
The six documents and their annotation changes are authored illustrations, not
independent human judgments or evidence of annotation accuracy.

The priority follows the page-by-page reading of Kyle & Eguchi (2024), recorded
in `KYLE-EGUCHI-2024-READING.md`. The next research/implementation step is the
separate input and scoring contract for predictions and independent references.
The current difference helper does not assign TP/FP/FN or infer which label is
correct, and it does not accept external-import objects or score flemma units.

Evidence: `reviews/ldfreq-annotation-sensitivity-20261005/evidence/`.

- Installed archive checks pass 69 expectations (52 new example, 15 API naming,
  two smoke), with no failures/warnings/skips. Hand checks cover lemma effects,
  content-word exclusions, lost MATTR computability, different coverage
  denominators, missing-to-present transitions, empty/all-excluded documents,
  ID reordering, source tampering, original Unicode/emoji/decomposed characters,
  unchanged surface phrase matches, and save/replay.
- Preparation and replay in separate R sessions produce identical full RDS
  results. A subsequent CSV check exposed automatic conversion of all-missing
  character columns to logical; specifying the saved column classes restores
  exact equality. The guide uses RDS for complete reproducibility and CSV for
  inspection. This was a CSV type-inference issue, not a failed RDS replay or
  numerical change; only the failed CSV step needed an additional check.
- Archive: 3,467,664 bytes, SHA-256
  `5d90cec7b24d9ae6033a9d10e5be45b12d81e92e480dc2f62d10f7b8db134ee0`.
  Exact-archive `R CMD check --no-tests --no-manual --no-vignettes` is Status OK,
  including examples. Repository-index lookups were unavailable in the sandbox;
  installed dependencies were used. This does not verify current repository
  availability. All 209 staged source members match the checkout, and archive
  identity matches with DESCRIPTION formatting normalized.
- All 138 prior R/test/help/extdata files and all 12 resource files match the
  preceding phrase-list archive. Existing successful numerical/model checks
  remain applicable; those computations were not repeated locally. API audit
  remains 50 exports, 34 S3 registrations and 30 public help topics.
- The changed vocabulary-audit guide executes and renders. Seventeen unchanged
  compiled guides are reused, for 18 installed guides in total. Home, NEWS and
  that article build locally; 118 HTML files have no missing relative file
  targets. Help is unchanged and the prior 81-page manual remains applicable.

Local focused evidence is distinct from OS CI. Publication state remains
`development`; no main merge, public-site deployment or CRAN submission is part
of this change.

## Reference-based annotation evaluation (2026-10-05–06)

Added experimental `lexdiv_evaluate_annotations()` for complete external
annotation imports on the same original segments and token boundaries. It
evaluates one explicitly named categorical column with a complete allowed
label inventory. Source context covers all tokens, including non-candidates.
Per-label TP/FP/FN, precision/recall/F1, document coverage and sparse confusion
counts distinguish unavailable references from unavailable predictions.
Missing predictions on available references count as FN; unavailable references
do not enter the error denominators. Complete inputs retain separate review and
prediction-failure metadata. Reference independence and evaluation role remain
caller declarations. No dependency, analyzer, corpus or model was added.

The new installed example and guide connect noun selection to document TTR.
English and Japanese authored examples have two selected nouns in each
condition, but different occurrences: reference TTR is 0.5 and predicted TTR
is 1.0. Partial reference/prediction annotations leave the corresponding full
document count and score unavailable. Empty documents remain explicit. This
illustrates a mechanism; it is not independent human validation, a language
comparison, dependency-head accuracy, or word-sense disambiguation.

This implements the software part of roadmap stage 2, following the separate
input contract proposed after the sensitivity example. The existing
`lexdiv_compare_annotations()` contract remains unchanged. Real reference
sampling, independent judgments and adjudication remain research work; they
are not silently counted as complete or made prerequisites for distributing
this limited descriptive evaluator.

Evidence: `reviews/ldfreq-annotation-evaluation-20261005/evidence/`.

- On macOS with R 4.6.1, the installed archive passes **189 expectations**:
  117 evaluator/example checks, 55 external-import checks, 15 API naming checks,
  and two installed smoke checks. Failures, errors, warnings and skips are zero.
  Independent hand counts cover class errors, empty/unobserved classes, missing
  references/predictions, equal counts with different TTR, exact source matching,
  reordered compound IDs, Unicode/decomposed characters and saved-input replay.
- A separate R session reconstructs both the evaluation and complete example
  object identically, including document-score outputs and settings.
- The first archive's `R CMD check --no-tests --no-manual --no-vignettes` is
  **Status OK**, including execution of help examples. PDF inspection exposed
  clipped long field lists in the new help topic; those lists and example line
  breaks were reformatted. The final archive's R/test/example implementations
  are byte-identical to the tested archive; only help prose/formatting and the
  DESCRIPTION build timestamp differ. Parsed help-example R expressions are
  unchanged. Numerical tests were not repeated for those documentation edits.
- Final archive: **3,492,724 bytes**, SHA-256
  `77cc8c84dbf8e5ff45ffc96b15d68590087f36700ddfe6190c0dd9f2748f3b41`.
  Its focused `R CMD check --no-tests --no-examples --no-manual --no-vignettes`
  is **Status OK**. All 213 checked non-DESCRIPTION source members match the
  checkout; DESCRIPTION fields match after build metadata/format normalization.
  All 127 prior R/test/help members and 12 resource files are unchanged from
  the sensitivity archive. Prior numerical/model evidence is reused for them.
- API audit: **51 exports, 34 S3 registrations, 31 public help topics**.
  The new vignette executes and renders, giving 19 installed guides; 18
  unchanged compiled guides are reused. A newly compiled **84-page manual**
  includes the new topic on pages 19–22, inspected visually. Existing manual
  layout warnings outside the changed topic are not a new whole-manual audit.
- Home, NEWS, the new article/help and their indexes build locally. The
  original attempt stopped on sandbox DNS access to public package metadata;
  rerunning only document construction with network access succeeds. All
  120 local HTML pages have valid relative file targets. A newly created root
  AGENTS.md was found to be picked up automatically by pkgdown, so its roadmap
  pointers were moved to the workspace AGENTS.md outside the package and the
  generated internal page was removed. Neither archive nor site contains it.

These are local source/archive checks, not new Windows/Linux/macOS CI runs.
At completion of those checks, push and PR updates were pending after a
remote-write approval rejection. On 2026-10-06 the user explicitly approved
pushing the verified changes to `Ryuya-dot-com/ldfreq`, branch
`prepare/publication-nj8-20261004`, and updating existing PR #21. That approval
resolves the earlier remote-write blocker. Current remote head and CI results
are recorded in PR #21 rather than triggering another heavy CI run solely to
add their URLs here. Main merge, repository visibility changes, site deployment
and CRAN submission remain separate actions; package status stays development.

## Source alignment across token segmentations (2026-10-06)

Added experimental `lexdiv_align_annotations()` for roadmap stage 3. Both inputs
are complete, revalidated external imports with identical source segments.
An interval sweep groups overlapping source spans without a Cartesian product
or matching token row numbers. Split, merge, complex, changed-span and one-sided
relations retain original context and both sides' token IDs. Exact-span coverage
and internal-junction agreement use separate, explicit denominators. A junction
is the pair of left-token end and right-token start; compulsory segment edges
are excluded, and explicit whitespace/punctuation tokens remain in the counts.

Optional label evaluation shares the existing evaluator's scoring code but uses
only exact span pairs. Non-exact spans retain exclusion reasons and are not
silently treated as missing predicted labels or counted in conditional label
FN. The four exact pairs in the authored example all agree, while only 4/9
reference tokens and 4/15 predicted tokens are covered. This is descriptive
correspondence to a supplied baseline, not independent analyzer validation.
The same-segmentation evaluator retains its strict contract and saved results.

The installed English/Japanese example uses both complete sequences for N/V,
TTR and MATTR, with a declared all-surface-token policy including punctuation
and the same four-token window. Japanese TTR changes from 0.75 to 2/3; English
TTR stays 0.75 while MATTR changes from 0.75 to 0.85. Empty and short documents
retain undefined metrics and their reasons. No new required dependency,
corpus or model is included. Independent reference validation, word-sense
analysis and dependency-head evaluation are not claimed. The next implementation
stage remains the narrowly scoped basic-UD amod–noun occurrence extraction;
dependency MI requires a separately suitable reference and denominator.

Evidence: `reviews/ldfreq-annotation-alignment-20261006/evidence/`.

- Installed-package focused evidence covers **296 expectations**: 107 alignment
  checks after the Unicode fixture correction, 117 existing evaluator checks, 55 import checks, 15 API checks and
  two smoke checks; no failures, errors, warnings or skips. Cases cover manual
  boundary/count calculations, split/merge/many-to-many correspondence, shifted
  token indices, Unicode/decomposed text, whitespace ownership, missing labels,
  empty rosters, source tampering and reordered collision-safe compound IDs.
  An independent all-pairs overlap graph agrees with the interval sweep on
  every pair of partitions of a four-codepoint string (64 combinations).
- The old evaluator reproduces its preceding saved full result identically
  after extraction of shared validation/scoring helpers. New inputs, alignment,
  whole-document scores and settings replay identically in separate R sessions,
  including from the final archive's installation.
- The first source archive passes `R CMD check --no-tests --no-manual
  --no-vignettes` with **Status OK**, including help examples. Subsequent PDF
  layout corrections change only help prose/formatting; all R, test, example
  and guide bytes are identical. The pre-fixture-correction archive's documentation check with
  `--no-tests --no-examples --no-manual --no-vignettes` is **Status OK**. Those
  checks plus the retained focused tests are combined evidence, not one full
  local check invocation.
- Final archive after fixture correction: **3,508,998 bytes**, SHA-256
  `9c86797543888180ddb41885fd77c34c287bba39ecb9f6678c46e1fbd42796c7`.
  All 218 audited non-DESCRIPTION source members match the checkout; only the
  new help file, corrected alignment test fixture and build metadata differ
  from the first tested archive. All runtime, installed example, guide and
  resource bytes are unchanged. The corrected 107-expectation alignment test
  uses the already checked installation; 189 unaffected focused expectations
  retain their earlier evidence rather than being repeated locally. The 128
  unchanged prior R/test/help files and all 12 resource files retain their
  existing evidence. The existing evaluator implementation and its help are
  the only changed prior R/test/help members; their affected checks are included.
- Public API inventory, help, exports, examples and pkgdown agree: **52 exports,
  34 S3 registrations, 32 help topics**. The new guide executes and renders;
  19 unchanged compiled guides are reused for **20 installed guides**. Home,
  NEWS, affected help and article/index pages build; all **122 local HTML files**
  have valid relative file targets. Package/site contain no workspace AGENTS.md.
- The rebuilt manual has **87 pages**; the new topic on pages 8–10 was visually
  inspected after repairing long-code wrapping. This is focused changed-topic
  inspection, not a new visual audit of every pre-existing manual page.

The first pushed head, `49dacb7`, passed the four non-Windows R jobs, both
resource builders and PDF manual. R 4.1 passed 6,709 expectations with eight
optional-textstem skips and two NOTEs (optional dependencies and installed
size). Windows reported one error while importing the new Unicode test fixture,
before calling the alignment function; its guide rebuild succeeded. The test
mixed a literal supplementary-plane character with Unicode escapes. The exact
parser-level cause is not independently established on this Mac. The fixture
now constructs its six intended codepoints with `intToUtf8()` and verifies the
source before testing the same decomposed-character and emoji positions. No
runtime or tolerance was changed, and the Unicode case was not skipped.

This test correction requires a new head and Windows CI confirmation. The
repository's normal PR workflow starts its full matrix on that push; no extra
manual workflow or cancellation is introduced. Existing user approval covers
this branch and draft PR #21 update. Final CI results are recorded in the PR
rather than causing another push solely to record their URLs here.
No main merge, visibility change, site deployment or CRAN submission occurs.

## Color defaults and monochrome plots (2026-10-06)

All eleven existing plot methods now accept the named argument
`monochrome = FALSE`; `TRUE` selects black/gray series. Metric and screening
defaults retain advisory distinctions with triangles/circles. MATTR retains
its dashed mean line, and NJ8 retains its separate off-list bar. Automatic
titles were removed; metric IDs label the y-axis. Explicit base-graphics
labels/symbols remain available. No export, dependency, metric, denominator,
selection rule or return schema was added or changed.

Local working-tree evidence is in workspace
`reviews/ldfreq-plot-style-20261006/evidence/`:

- Installation and 1,519 focused assertions passed without failures, warnings
  or skips, including 165 plot-style assertions. Tests exercise all eleven
  methods, both modes, unchanged invisible returns, invalid flags, actual
  graphics colors and overlays, default symbols and explicit overrides.
- Visual inspection found the existing NJ8 legend overlapping the off-list
  bar. It now uses reserved space at the top right. The affected 324 NJ8/style
  assertions passed again after that correction; 1,195 unaffected assertions
  are retained. These are combined focused results, not a new full check.
- Code/help signatures agree, all five affected help topics validate/render,
  and the three guides containing package plots execute/render with the final
  code. Six plot families were rendered in both modes; focused visual review
  checked labels, grayscale distinctions and the corrected NJ8 legend.
- The public API audit remains 52 exports, 34 registered S3 methods and 32
  documented topics. README, help, NEWS and the introductory guide describe
  the same switch and external figure-title/note convention.

The earlier alignment/network illustrations also have color defaults and
explicit monochrome variants in their local example script. Their saved
numerical data are unchanged; they remain prototypes outside the package API.
This entry records local source installation/tests and documentation, not a
new release archive, remote CI run or published site.

## Literature-informed figure refinement (2026-10-06)

The user requested Web and Zotero evidence for further refinement. Zotero
searches for visualization, visualisation, graphics and Cumming identified
Cumming (2014), item `NP46KF6G`, DOI 10.1177/0956797613504966, and Gabry et al.
(2019), item `LAA54HWF`, DOI 10.1111/rssa.12378. Their metadata and abstracts
were read; this was not a full-text/page-by-page review. No library entries
were written. The helper's localhost probe was sandbox-blocked; the connected
Zotero tools successfully supplied the records.

Primary Web sources consulted were Wilke's *Fundamentals of Data Visualization*
(chapters 4, 20 and 24, at https://clauswilke.com/dataviz/), Weissgerber et al.
(2015), DOI 10.1371/journal.pbio.1002128, official APA figure/font guidance, and
R's Cairo-device documentation. The report guide links the sources beside the
corresponding design choices. Estimation/model-checking principles inform the
interpretation boundary; the package does not infer intervals or fit a model
merely because a descriptive graph is requested.

Changes: redundant point shapes in both color modes; a common Okabe--Ito
blue/orange palette; sans serif text, horizontal tick labels and open frames;
restoration of cosmetic device settings even after errors. NJ8 uses common
0--1 proportion ticks, explicit category labels with a wrapped Off-list label
at narrow widths, and count ranges determined by the visible series. Undefined
proportions raise an error rather than becoming zero-height bars. The audit
guide now plots signed TTR changes for the same documents: four of six authored
documents are paired, two remain unavailable in the full status table. This is
an illustration of annotation sensitivity, not an independent accuracy study.

Workspace evidence: `reviews/ldfreq-visual-refinement-20261006/evidence/`.
The first installed run passed 1,555 focused assertions. Final narrow-label
corrections and four additional checks passed 364 NJ8/style assertions;
1,195 unaffected assertions are retained, for 1,559 combined passes without
failures/warnings/skips. All eleven computable plot-data returns match the
previous installed version exactly. Five help topics validate/render and agree
with code signatures; four affected guides execute/render, including PDF/PNG
round trips with identical plotted rows. No new export/dependency was added.

Six plot families were rendered in both modes, with additional 3.25-inch NJ8
figures and paired-change figures. Visual checks exposed the automatic loss
of the narrow Off-list label; explicit category-axis placement fixed it without
reducing the 11-point text. The local network prototype also offsets count
labels from edges; its saved numeric tables are unchanged. These are local
source/document/figure checks, not a new archive-wide or cross-platform CI run.

## Basic UD adjective–noun pairs (2026-10-06)

Added experimental `lexdiv_amod_pairs()` over an unmodified external-annotation
import. One sentence per segment supplies basic UD head/deprel/UPOS. Selection
is ADJ–amod–NOUN, including relation subtypes but excluding PROPN/PRON; this is
not the exact Penn-tag feature used by Kyle & Eguchi (2024). The official UD
amod, CoNLL-U and Japanese amod pages were checked for this implementation.
No parser, required dependency, model, corpus or MI resource was added.

The function validates head ranges, self-links, root consistency and cycles,
including known contradictions within incomplete annotations. Whole sentences
with missing heads/relations/UPOS are excluded; observed counts survive but
complete document totals are unavailable. Missing lemmas affect type coverage,
not syntactic occurrence detection. Both source endpoints, direction, distance,
original KWIC, surface/lemma units and complete annotation provenance survive.
The offline seven-document example includes English/Japanese, a true zero,
missing and partially analyzed documents, and empty input. Equal counts can
still have one FP and one FN by endpoint comparison. These are authored
implementation examples, not independently collected accuracy data.

Evidence is in workspace `reviews/ldfreq-amod-pairs-20261006/evidence/`:

- The new feature passed **116 installed expectations**, including an independent
  adjacency-matrix reachability oracle over all 27 possible three-node head
  assignments without self-links. Cases include non-adjacency, postposed
  dependents, subtypes, missing annotations/lemmas, enhanced-edge rejection,
  malformed heads, Unicode codepoints, compound IDs and RDS replay.
  The test run succeeded; its first CSV summary write failed because a testthat
  result column was a list. The log retains the passing test evidence. This was
  an evidence-output error, not a feature-test failure. Subsequent integration
  results save RDS first and serialize only scalar columns to CSV.
- **17 installed API/smoke expectations** passed with no failures/warnings/skips.
  The existing plot evidence (1,559 combined focused passes) and unchanged core
  numerical evidence are reused; no new full local numerical run is claimed.
- Exact source archive passes `R CMD check --no-tests --no-manual --no-vignettes`
  with **Status: OK**, including installation and all help examples. The runtime
  and plot tests above are separate evidence, not tests run by that command.
  All **225 audited source members** match the checkout; build metadata and
  compiled guides are checked separately. Private development files and
  workspace instructions are absent. Resource bytes and builders are unchanged.
- Archive SHA-256: `f67ab008aab5852ced7b170dcaf153dfaf12fd4266218e20df159d35cf79053a`.
  Twenty existing guides retain their earlier source/render evidence (the four
  plot-related outputs use the final figure-refinement artifacts); the new
  dependency guide executes/renders for **21 installed guides**. A fresh R
  process using the archive installation reproduces both saved pair results.
- API audit agrees at **53 exports, 34 S3 registrations and 33 public topics**.
  New help and guide describe the same arguments, return tables and limitations.
  Color and monochrome paired-change figures render; the color plot was visually
  checked. Figure titles remain outside the image. No plot S3 method was added.
- The PDF manual builds to **89 pages**. The new help on pages 13–15 was visually
  checked for wrapping and legibility; this is not an audit of all older topics.
  Home, NEWS, affected help/articles and indexes build locally. The initial
  pkgdown home build could not resolve CRAN within the sandbox; only the failed
  document build was retried with network access and succeeded. No deployment
  occurred.

This completes the initial source-linked extraction API. Real-parser/corpus
adapters, independent reference evaluation and compatible dependency MI remain
separate work. Existing approval covers updating the development branch and
PR #21 once these changes are combined. Commit-specific CI is recorded in the
PR to avoid another source push solely to copy workflow URLs. Main merge,
visibility changes, site deployment and CRAN submission are not part of this
update.

## Optional UDPipe workflow and overlaid distributions (2026-10-06)

Added the explicitly sourced `inst/examples/udpipe-amod.R` recipe and extended
the dependency guide from original sentence inputs through a real parser,
source-endpoint comparison, original count distributions and saved-output
replay. UDPipe and ggplot2 are optional suggestions; public exports and S3
methods are unchanged. No model or corpus is distributed. The official UDPipe
R documentation and UD 2.5 model repository were consulted; model terms are
recorded separately from the R code license.

The helper consumes the complete UDPipe output (`x`, `conllu`, `errors`) and
one original sentence per segment. It uses UDPipe's own CoNLL-U reader and
the existing exact-surface annotation importer, preserving the original roster,
empty inputs and missing labels. It refuses reported failures, source/ID
mismatches, multiple sentences per input, multiword-token rows, empty nodes
and enhanced dependencies. It does not reconstruct source text, invent global
document offsets, silently filter unsupported rows or rerun inference on replay.

The user's subsequent visualization instruction supersedes the earlier
signed-change figure recommendations in this record. The audit guide now
overlays original TTR observations; the dependency guide overlays document
frequencies at each original integer pair count. Difference tables remain
available for auditing. The optional continuous TTR density recipe uses a
common numeric bandwidth, reflection at the 0--1 bounds, and solid/dashed
lines in both color modes. The ggplot2 3.4.0 release documentation confirms
the required `bounds` and linewidth support. These are marginal descriptive
distributions, not an uncertainty or paired-effect estimator. Constant series
are rejected; tiny/discrete examples use observations/frequencies. No in-figure
title, subtitle or caption is introduced. The Japanese stimulus guide's
all-missing branch now reports its message outside the figure.

Workspace evidence: `reviews/ldfreq-udpipe-workflow-20261006/evidence/`.

- **31 new recipe expectations and 17 existing API/smoke expectations passed**,
  with no failures, warnings or skips, using the installed helper. Authored
  CoNLL-U covers Unicode, literal `NA`/underscore surfaces, empty inputs,
  source/ID changes, unsupported structures, missing labels and saved replay.
  Core `R/`, NAMESPACE, resource bytes and help files are unchanged; the prior
  numerical and public-plot evidence remains applicable to those files.
- Real parsing used UDPipe **0.8.16**, English EWT UD 2.5 model SHA-256
  `784bd0fa85e3d831fd02a55290d0acfd05c953159dc38cc33d52e1b28add9957`.
  Four authored inputs, including an empty document, produced pair totals
  **2, 2, 0, 0**, equal to the reference totals. In the first sentence, one
  endpoint mismatch yields one FP and one FN despite an unchanged count.
  This is workflow evidence, not independent parser-accuracy validation.
  A Unicode original is retained exactly; a multiple-sentence input is refused.
  The model remains only in the local evidence directory. An older model path
  proved to be a zero-byte file; a separate valid download was used.
- **Four affected guides execute and render**, including the optional model
  path separately. The latter reproduces the saved raw output and extracted
  pairs. Eight current figures cover original TTR, authored/parser count
  distributions and continuous density rendering, each in color/monochrome.
  Plotted numbers are identical between modes. Bounds, finite density values,
  line types, title absence, invalid bandwidths and constant-series refusal
  were checked. The density figure uses deterministic beta-quantile rendering
  inputs, not observations from a research corpus. Color density, monochrome
  density, original TTR and parser count figures were visually inspected.
  Earlier `parser-differences-*.png` artifacts are superseded and are not shipped.
- Two evidence-generation issues were localized and corrected. The first
  validation driver tried to retrieve a globally sourced helper from the
  knitting environment; `source(..., local = TRUE)` fixed that scope mismatch.
  The tests and preceding model execution had succeeded. Later, standalone
  `purl()` lacked the optional-chunk flag; an explicit offline environment
  restored those chunks as commented code. The parsed executable expressions
  were identical before/after that extraction correction. Neither issue was
  a numerical or parser failure; successful runtime tests were not repeated.
- The checked archive candidate passed
  `R CMD check --no-tests --no-manual --no-vignettes`, **Status: OK**, including
  all help examples. After the comment-only extraction correction, the archive
  was rebuilt and installed; a fresh R process reproduced both saved-output
  import and pair extraction without a model and executed the installed
  offline guide script. The full check was not repeated for restored comments.
  These are separate evidence stages, not a claim that the final archive ran
  all tests or a full check in a single process.
- Final archive SHA-256:
  `22f8bc92898282f9c67ddd2ab92a5708358c1e68443b9aebdc75a84d909b11c4`.
  **227 audited source members** match the checkout. There are **21 installed
  guides**: four newly rendered and seventeen whose source is byte-identical
  to the previously validated compiled guides. Model files, raw parser records,
  workspace instructions and private development files are absent. API audit
  still reports **53 exports, 34 S3 registrations and 33 public topics**.

This update is locally validated. It does not change main, publish a website,
submit to CRAN or establish independent accuracy in a target population.

## External-reference check and sentence-boundary correction (2026-10-06)

Following the request to consider priorities, paused further visualization
work and took the existing Stage 5 candidate into a bounded real-data check.
The question was whether the current source-aligned amod workflow processes
all supplied sentences, and whether equal pair counts conceal occurrence errors.
The result determines input guidance and the scope of claims; it does not
create a new requirement for universal accuracy before distributing the API.

Used the complete public UD English ESLSpok test split at commit
`3feb27b9759454c4cf02263b371963137bee0d2b`, source SHA-256
`7d3b37af353205dc3b2964937e7c511e7763cdca25ec9c830638a2540ffe04be`.
It contains **232 sentences, 2,266 tokens and 200 source-file ID groups**.
These are sampled sentences, not complete interviews or verified independent
participant records. The distributed `# text` is the coordinate reference;
its whitespace and segmentation are not assumed to reproduce original audio
or an untouched full transcript.

Sources: the [pinned treebank README](https://github.com/UniversalDependencies/UD_English-ESLSpok/blob/3feb27b9759454c4cf02263b371963137bee0d2b/README.md),
its LICENSE.txt, and the sampling/annotation/split sections of
[Kyle, Eguchi, Miller, and Sither (2022)](https://aclanthology.org/2022.bea-1.7/).
The pinned distribution declares CC BY-SA 4.0. Dependencies/XPOS were manually
annotated; UPOS was converted then manually checked; lemmas are absent.
This is an external reference, not new blind human annotation commissioned
for ldfreq. No lemma accuracy or language-wide generalization is assessed.

Kept the existing English EWT UD 2.5 model (SHA recorded above), feature
ADJ--amod--NOUN including subtypes, and surface unit. The model README says
UD 2.5 training with original splits; ESLSpok entered UD in 2.12. This supports
the absence of this annotated treebank from the declared training release,
not an exhaustive raw-text contamination audit. No model was trained or
selected using these test results. All 232 references pass source/tree checks.

Initial fixed-setting results with `tokenizer = "tokenizer"`:

- **229/232 sentences processed**; three were refused because UDPipe split a
  supplied sentence into multiple sentences. Their prediction counts remain
  missing, not zero. All three have zero reference amod pairs in this sample.
- On the paired set, **55 TP, 6 FP and 5 FN**, against 60 reference pairs:
  precision **0.9016393**, recall **0.9166667**, F1 **0.9090909**. The operational
  recall including all reference-complete inputs equals the conditional recall
  here because the three failed predictions contain no reference pairs.

Corrected the guide to use the existing UDPipe
[presegmented tokenizer](https://ufal.mff.cuni.cz/udpipe/1/api-reference).
It respects the caller's sentence line while predicting token boundaries;
tagging/parsing operate on that sentence. An explicit guard prevents silently
removing embedded CR/LF. A paragraph on one line is not automatically a sentence.
The importer still refuses saved multi-sentence output and unsupported UD
structures; no guessed head remapping or concatenation was introduced.

The corrected setting processes **232/232 sentences** with the same 55/6/5
occurrence counts. It fixes processing coverage, not the remaining annotation
errors. Pair counts agree in **223/232 sentences**, including **one sentence
with one FP and one FN**. Fifty sentences contain reference pairs, so most
count agreements are zeros. The eleven discrepancies occur in ten sentences;
`review-queue.csv` retains original contexts, both annotations at the dependent
span, head surfaces, and an explicit unreviewed status. These mismatches include
POS, relation and attachment differences; the reference was not rewritten to
match predictions. No new graph was needed to identify this priority.

The second setting was checked after seeing the initial failures on this same
test split. It is a development check, **not an untouched final test**. The
numbers describe this finite sample; no population confidence intervals are
claimed from independent-token assumptions. Whole-document diversity, rankings,
other registers, L1 performance and Japanese require separate evidence.

Evidence is in `reviews/ldfreq-eslspok-evaluation-20261006/evidence/`:

- `experiments/evaluate-eslspok-amod.R` pins source/model bytes, retains every
  sentence and status, caches complete raw output, and saves source-linked
  comparisons. `experiments/check-eslspok-counts.py` independently reads integer
  CoNLL-U rows, aligns Unicode source spans, selects the feature and checks
  occurrence sets and counts. Both settings pass this separate check.
- An initial driver error used R's partial `$error` lookup against UDPipe's
  `$errors`; exact `[["error"]]` indexing fixed the driver. Raw inference output
  was already saved and reused. Each corpus setting was inferred once; the
  review-table addition reused its saved predictions. Downloading initially
  encountered sandbox DNS and Python CA configuration failures; macOS curl
  retrieved the same public URLs with certificate validation enabled.
- The changed guide executes offline and with the actual model. Its authored
  example's plotted rows match the previous version exactly, so unchanged
  figure checks are reused. Twenty other guides, runtime R code, helpers,
  tests, resources and help retain their previous byte-checked evidence.
- The updated source archive builds and installs. A fresh R process reimports
  and re-extracts all **229 initial and 232 corrected accepted sentences**
  identically from saved output, without loading the model. The installed
  guide script executes offline; all 21 guides remain indexed. No full
  numerical suite, unchanged manual or remote CI was rerun for this change.
- Final archive SHA-256:
  `18ff8e9c4bee053dfe285bd269c0267c02bd911f99c3c8600fe25e686936064b`.
  All **227 audited source members** match the checkout. The source archive
  contains the updated guide and NEWS, and excludes experiment scripts,
  corpus/model files and development notes. No public API or mandatory
  dependency was added. No commit, push or deployment occurred in this step.

## Learner-text errors and explicit reviewed versions (2026-10-06)

The user's follow-up asks how learner spelling and grammatical errors enter
the analysis. This belongs to current roadmap priority 2 (input/interpretation
boundaries), without replacing the package's annotation-to-document evaluation
purpose with a general correction engine. Existing annotation comparison and
alignment correctly require the same original source; changing the text needs
separate versions and fresh tokenization/annotation.

Research consulted:

- [Nagata, Sato, and Takamura (2018)](https://aclanthology.org/C18-1202/),
  *Exploring the Influence of Spelling Errors on Lexical Variation Measures*.
  Read the primary PDF's methods/results passages on original versus manually
  corrected Japanese EFL essays. TTR and Yule's K had different sensitivities
  under their preprocessing. Unidentifiable and concatenation/split corrections
  were excluded. Do not generalize this to universal robustness or import the
  paper's correction categories as mandatory rules for spelling varieties,
  names or code-switching. This was targeted reading, not a page-by-page
  replication or an independent experiment.
- [Berzak et al. (2016)](https://aclanthology.org/P16-1070/), *Universal
  Dependencies for Learner English*. Read the parallel original/corrected
  annotation design and literal-reading scheme, including its exceptions for
  misspellings and malformed forms. This supports distinguishing source errors
  from annotation errors; it does not license silently normalizing all syntax.
- [Bryant, Felice, and Briscoe (2017)](https://aclanthology.org/P17-1074/),
  ERRANT. Checked the stated role of extracting/categorizing edits from paired
  original/corrected sentences. Its categories do not establish intended
  meaning or correction validity. No ERRANT/Python dependency was introduced.
- Read-only Zotero searches found Kojima and Yamashita (2014), *Reliability of
  lexical richness measures based on word lists in short second language
  productions* (`GEVLP3RD`, DOI 10.1016/j.system.2013.10.019). Its metadata and
  abstract concern short-text measure reliability, not enough to establish a
  spelling-correction policy. Exact Nagata/title and Berzak searches did not
  retrieve these target papers; fallback fulltext hits were not treated as
  matches. The local API helper probe was sandbox-blocked, so the connected
  Zotero tools were used. No library/settings changes or attachment retrieval.

Added `inst/examples/reviewed-text.R` and `reviewed-text-demo.R`, explicitly
sourced examples rather than public exports. The ledger uses original Unicode
code-point spans, exact original/replacement strings, category, decision,
reviewer and reason. Only approved selected categories apply. Source tables and
writer/task metadata, rejected/unresolved proposals, original context, revised
edit spans and document hashes are retained. Insertions/deletions are explicit
empty intervals; conflicting active edits stop. No automatic proposals, fuzzy
replacement, lemma substitution or guessed cross-version token alignment.

Six authored documents compare unchanged, spelling-reviewed and expanded-review
versions through existing surface TTR/MATTR and NJ8 batch APIs. The spelling
example changes TTR from 4/5 to 3/5; article insertion changes N from 4 to 5 with
TTR still 1. Word-boundary repair changes N from 3 to 4 and the requested
four-token MATTR becomes computable. Real-word substitution demonstrates why
dictionary membership alone cannot identify errors. The unknown intended form,
rejected name change and empty document remain visible. These observations are
constructed accounting checks, not learner data or correction-accuracy evidence.

Expanded the existing audit guide and linked it from the tokenizer guide and
README; NEWS describes the scope. The guide separates primary-version choice
from mandatory source retention, spelling from grammar/lexical rewriting,
source errors from parser/OCR errors and OOV status, and raw code-point edits
from processed-token offsets. Model proposals, if supplied externally, require
their own provenance and review. No new plot, corpus, model or dependency.

Evidence: `reviews/ldfreq-reviewed-text-20261006/evidence/`.

- Focused test file: **57 passing expectations**, no failures/warnings/skips.
  Tests cover source preservation, metadata, policy selection, rejected and
  unresolved proposals, empty input, insertion/deletion, non-BMP and combining
  characters, revised spans, conflicts, stale source, malformed inputs,
  denominator changes and existing same-source rejection. RDS replay matches.
- Both modified guides render and extracted scripts execute. Their HTML
  includes the new section/link and no absolute workspace paths. No figure
  logic changed; previous figure evidence remains applicable.
- Nineteen other compiled guides were reused after source-byte checks.
  Runtime `R/`, `man/`, `inst/extdata/` and `NAMESPACE` match the preceding
  verified source package. No unchanged numerical suite/model inference was
  repeated and no new full `R CMD check` or remote CI is claimed.
- The source archive builds and installs; **230 source members** match the
  checkout (DESCRIPTION gains build metadata). All 21 guides and both new
  examples are included; development notes, corpus/model files and incidental
  plot outputs are excluded. The public surface remains 53 exports.
- A fresh process from the installed archive reproduces all three versions,
  tokenization, metrics and NJ8 objects identically from saved inputs. Both
  installed guide scripts run. An initial inventory assertion incorrectly
  counted R's generated `doc/index.html` as a guide; the evidence script now
  excludes it. Analysis replay had already passed; no package fix was needed.
- Archive SHA-256:
  `7e41b86087e60cfe9daebc115835eda14d3a146bba57aaa3c553e1992679cb1a`.
  Full saved results and flat previews are local evidence, not bundled data.
  No commit, push, merge, public deployment or CRAN submission in this step.

Remaining research boundary: on real paired documents, independent decisions
and a declared correction scope are needed to study score/ranking effects.
The ledger does not detect all errors or validate intended meaning; its proposal
counts cannot estimate corpus error prevalence. This is a candidate within
stage 5, not a new universal prerequisite for distributing the bounded tools.

## Spelling varieties, names, numerals and symbols (2026-10-06)

The user's next questions concern legitimate spelling variants and counting
policies, rather than correcting learner errors. The canonical roadmap keeps
this under priority 2. Inspected the actual English/Unicode tokenizers, UPOS
selection, NJ8 aliases, complete annotation import and original-position n-gram
contracts before choosing the implementation scope.

Observed on the bundled resource: surface `colour`, `centre`, `theatre` queries
are off-list while `color`, `center`, `theater` match. This is not evidence of
errors or advanced vocabulary. Current content-word selection includes PROPN.
English `keep_numbers = FALSE` excludes recognized digit-based expressions but
retains `Two`, `2nd`, `COVID-19`; its pattern flag is not a NUM annotation.
The raw lexical tokenizer also reduces `C++` to `C` and `R&D` to `R`, `D`.
Complete external token rows can preserve these forms and exclusion boundaries.

Primary definitions checked on the Web:

- Cambridge Dictionary's [color](https://dictionary.cambridge.org/dictionary/english/color),
  [practice](https://dictionary.cambridge.org/dictionary/english/practice),
  [practise](https://dictionary.cambridge.org/dictionary/english/practise) and
  [spelling comparison](https://dictionary.cambridge.org/plus/quiz/grammar/spelling-5)
  entries support the example equivalences and the need to consider grammatical
  role. Direct fetches of some pages returned 403; their indexed dictionary
  entries were available. No dictionary database was downloaded or redistributed.
- UD v2 [PROPN](https://universaldependencies.org/u/pos/PROPN.html),
  [NUM](https://universaldependencies.org/u/pos/NUM.html),
  [SYM](https://universaldependencies.org/u/pos/SYM.html) and
  [PUNCT](https://universaldependencies.org/u/pos/PUNCT.html) definitions:
  name spans and proper-noun tags are not identical; digit patterns and semantic
  numeral labels are not identical; symbols can convey lexical/discourse meaning.
  These are annotation definitions, not evidence of automatic tagger accuracy.

Added `inst/examples/lexical-counting-policy.R`, an explicitly sourced offline
example using existing APIs, with eight authored documents and five policies.
It retains full source annotations, supplied tags, missing POS and empty input;
separates source forms, counting keys and reference query keys; records three
reviewed noun aliases with metadata and a hash; and protects PROPN occurrences
from those noun aliases. Alias lookup and type merging are separate choices.
Full token positions survive filtering, so n-grams do not bridge excluded
symbols, names, numbers or unknown-tag positions. This is not automatic NER,
a general variety converter, a punctuation scorer or numeric-value parsing.

For `The colour is color.`, surface TTR is 1 and declared-equivalence TTR is
0.75; NJ8 token coverage is 2/4 versus 3/4 with aliases. Coverage can be compared
without changing diversity keys. Removing the supplied PROPN from `Rose saw a
rose.` increases lowercased TTR from 0.75 to 1, demonstrating that the direction
of exclusion effects is not fixed. Unknown POS retains conditional values but
makes the full-policy reportable value unavailable. Complete annotations keep
`C++` and prevent a `cats dogs` adjacent pair across `+`. These are authored
accounting checks, not empirical validity or model performance results.

Expanded the English guide, linked the vocabulary-audit guide and README, and
updated NEWS and the number-argument help/source comments. The guide also
distinguishes POS exclusion from complete named-entity exclusion, pattern-based
number recognition from NUM and ordinal annotation, selected-token MATTR windows
from original-position n-grams, and lexical analysis from anonymization. It
explains why TUBELEX variant-frequency pooling needs original counts/denominators,
why document ranges cannot be added blindly, and why form-specific norms should
not be merged automatically. No such pooling is implemented or implied by aliases.

Evidence: `reviews/ldfreq-counting-policy-20261006/evidence/`.

- **39 new example/policy expectations and 92 existing English-text expectations
  pass (131 total)**, with no failures, errors, warnings or skips. No unchanged
  full numerical suite or model inference was repeated.
- All runtime `R/` parsed expressions match the preceding verified archive;
  the preprocessing source change is comment-only. NAMESPACE and bundled
  reference bytes are identical. No new export or dependency was introduced.
- Both changed guides render and their extracted scripts execute. Nineteen
  other compiled guides were reused after byte-checking their source. The
  modified HTML contains the section/link and no local absolute workspace paths.
- The source archive builds and installs; **232 audited source members** match
  the checkout (DESCRIPTION acquires build metadata), with all 21 compiled
  guides. Development records, corpus/model files and generated plot outputs
  are excluded. Public exports remain 53. No new full R CMD check or remote CI
  is claimed for this example/help change.
- Fresh-process replay from the installed archive reproduces the full example,
  all policies, metrics, reference lookups and n-grams identically to the saved
  object. Saved source/tag rows also reimport identically, and both shipped
  guide scripts execute. Complete RDS evidence and flat previews are retained.
- Archive SHA-256:
  `0d1e6ebc9fd928a9bc2cca6b186fe97c1ecd30cd170ee751bedf8a36e5f4b1ed`.
  No commit, push, merge, public deployment or CRAN submission in this step.

The work clarifies current options without changing tokenization defaults or
promising a comprehensive orthographic lexicon. Real-corpus evaluation and
reviewed study-specific annotations remain separate stage-5 work.

## Resource-defined word-family profiles (2026-10-06)

Implemented the next bounded feature in the canonical roadmap:
`lexdiv_family_profile()` maps complete imported source annotations to a
caller-supplied `record_id`/`form`/`family_id` table with optional exact UD POS.
Resource ID, version, language, citation, license, lookup unit and family
definition are required. Original surface/lemma/flemma keys and occurrences
remain distinct from assigned families; no suffix stripping or identity
fallback is used. Extra inventory metadata is retained in the full dictionary.

The result exposes all source occurrences, candidate records, original KWIC,
matched member counts, document and pooled summaries, complete inputs and
resource/result hashes. Multiple records for one family do not inflate counts;
different candidate families remain unresolved. POS exclusion, unknown
selection, missing unit/POS, unlisted forms and ambiguous families have separate
statuses. Complete family totals/TTR are NA with unresolved non-excluded tokens;
observed types and conditional coverage remain explicitly conditional. Empty
and fully excluded documents have zero family types and undefined TTR/coverage.
Expanded candidates are bounded before their allocation.

The authored installed example compares identical selected occurrences in
`use uses reusability use.`: N = 4 throughout; V = 3/2/2/1 for surface,
lemma, flemma and family respectively. TTR = .75/.50/.50/.25. Existing core
MATTR is used with a deliberately illustrative window of 3; unresolved tokens
are never removed to close gaps. The example's USE and BANK memberships are
authored decisions, not verified entries from Nation or learner observations.

Help, README, NEWS, DESCRIPTION, NAMESPACE, pkgdown navigation, API inventory,
the existing preprocessing guide and offline smoke example now agree on the
new operation. The API-name decision distinguishes it from AntBNC flemma
behavior. No class, plotting method, dependency, corpus, model or inventory is
added. There are now 54 exports, 34 S3 registrations, 35 Rd files (34 public
topics) and the same 21 guides. Public docs contain no development workspace
paths. The roadmap front records this implementation without changing the
research priority of source-linked whole-document evaluation.

Evidence: `reviews/ldfreq-word-family-20261006/evidence/`.

- **98 new family expectations and 72 existing annotation-input/API-name/smoke
  expectations pass (170 total)**, with zero failures, warnings or skips in
  the completed focused run. Tests include exact hand counts, repeated forms,
  normalization collisions, POS/missingness, empty resources/documents, distinct
  composite source IDs, row limits, CSV identifier preservation, RDS replay,
  resource-order invariance and a separate record-by-record lookup oracle.
  One initial expected error message was corrected: edited source surfaces are
  rejected by alignment before the generic changed-object check. Runtime code
  did not need modification to pass this test.
- The changed guide rendered and its extracted script executed; 20 unchanged
  compiled guides were reused after Rmd byte comparisons. All pre-existing
  runtime R files, bundled extdata and specifications match the prior verified
  counting-policy archive, so unchanged numerical/model work was not repeated.
- The exact archive passes **R CMD check --no-tests --no-manual --no-vignettes:
  Status OK**, including installation, static code/help checks and all help
  examples. Tests and changed-guide execution are separate evidence, not a
  full one-process test/check/vignette rebuild. Initial dependency checking
  stopped because the existing optional gibasa library was absent from R_LIBS;
  the completed command includes `tmp/japanese-r/library`, with no new install.
- **236 audited source members** match the checkout byte-for-byte; DESCRIPTION
  agrees after build whitespace folding, and all 21 compiled guides are present.
  Private development records, external corpora/models and generated Rplots
  are absent. Archive SHA-256:
  `588eb8628daa863df24b6765ba8d5e2160f1703652c5adf5a6888d7b6d9aad5c`.
- A fresh process loading the archive's checked installation reproduced the
  complete saved profile, annotation reimport and installed example identically,
  and executed the installed guide script. The subsequent metadata assertion
  initially compared DESCRIPTION wrapping literally; only Imports/Suggests
  wrapping differed. A focused normalized-field check passed, recorded in
  `description-validation.log`; completed replay/render operations were reused.

This is software/accounting validation with authored data. Actual family
inventory coverage and inclusion-level choices, contextual human-decision
application, affix decomposition and empirical validity remain uncompleted.
KWIC/candidates support inspection but do not yet apply occurrence-specific
review decisions. No commit, push, merge, remote CI, site deployment or CRAN
submission occurred in this step.

## Occurrence-specific review of family assignments (2026-10-06)

Refined the family workflow to close its documented gap between KWIC inspection
and downstream counts. `lexdiv_family_profile(review = ...)` now accepts the
existing `lexdiv_ambiguity_review()` result; `$review_input` prepares that API's
targets, record candidates and resource metadata. No second judgment interface,
new export, class, dependency or plot was introduced. Creating a review uses
the existing optional quanteda route; applying a saved review calls no quanteda
functions. Method version is now 0.2.0, with a versioned family-review snapshot.

Explicit record selection assigns a family only to that occurrence. Explicit
`unresolved` withholds a previous automatic match, while unreviewed occurrences
keep their lookup result. Original lookup status/family, final assignment,
reviewer/reason, full review and source inputs remain available. Document counts
include selected/unresolved judgment totals and withheld automatic matches.
The generic surface display can contain a union across POS/lemma contexts;
application additionally checks exact per-occurrence record eligibility.
Excluded and unknown-selection tokens cannot be reintroduced by review.

The prepared snapshot binds the complete source, dictionary (including record
order/extra fields), resource definition, lexical unit, normalization and POS
exclusions. Changed policy or data rejects a previous review; display-width
changes alone are allowed. These checks detect inconsistent reuse, not incorrect
linguistic judgment or a falsified reviewer identity. Neither new inventory
entries nor automatic sense inference are supplied by this refinement.

The new authored example uses `The bank lends money.` and `The river bank floods.`
under an explicitly illustrative two-BANK-family definition. The two ambiguous
occurrences become FINANCE/RIVER choices without changing the shared dictionary.
N remains 8 after excluding punctuation; V becomes 7 and TTR 7/8. An empty
document remains zero types with undefined TTR. This is not a claim that all
family inventories separate these meanings or that sense equals derivational
family. Help, README, NEWS, the API record, offline smoke and the existing
preprocessing guide cover this boundary and character-ID CSV/RDS use.

Evidence: `reviews/ldfreq-family-review-20261006/evidence/`.

- The completed initial focused run passed **270 expectations**: 144 family,
  73 existing ambiguity-review and 53 existing reviewer-comparison expectations.
  After adding a version marker to the family snapshot and tests for lemma
  eligibility/unknown selection, the final family run passed **149 expectations**.
  These give **275 distinct focused expectations** with zero failures, warnings
  or skips in the completed runs; the unchanged 126 review expectations are
  reused evidence, not claimed as one final combined invocation.
- Tests cover occurrence-specific selections, explicit withholding, partial
  review, stale source/resource/policy, edited or incomplete review inputs,
  wrong POS/lemma candidates, excluded/unknown-selection tokens, unchanged
  display policies, normalized keys with original surfaces, literal `NA` and
  leading-zero record IDs, empty candidate displays and reviewed RDS replay.
  Existing family accounting tests still pass; the offline smoke also runs the
  optional contextual family example.
- Only `R/family-profile.R` differs among runtime R files from the preceding
  family archive. Bundled extdata/specifications are byte-identical. The changed
  guide renders and its extracted script executes; 20 unchanged compiled guides
  were reused after source-byte comparison. No model inference or full unchanged
  numerical suite was repeated.
- Exact archive `R CMD check --no-tests --no-manual --no-vignettes`:
  **Status OK**, including installation and all help examples. Existing optional
  gibasa library was supplied through R_LIBS from the start. Focused tests and
  guide execution above remain separate from this scoped package check.
- **237 audited source files** match the checkout; all DESCRIPTION fields agree
  after build whitespace folding. All 21 compiled guides are present, with no
  private development/corpus/model files or absolute local workspace paths in
  compiled guides. Archive SHA-256:
  `dee9a7d66fdce112ef0af40f3b1d920c2f70907e861a33cebe9a0c112adedca0`.
- A fresh process reproduced the complete reviewed RDS profile **without loading
  quanteda**, and reimported original annotations identically. CSV initially
  failed an overstrict whole-review equality assertion: inspection isolated
  differences to display row names and their content hash. The follow-up checks
  compare character decision values without display row names, unchanged source
  occurrences/candidates/review identity, and all downstream occurrence/member/
  document/summary tables; all agree. This is semantic CSV restoration, distinct
  from complete RDS identity. Completed RDS/reimport checks were not repeated.
- The installed contextual example reproduces its complete saved result; the
  installed offline smoke and changed guide script execute successfully.

The canonical roadmap now marks occurrence-review application as implemented.
Actual inventory coverage/inclusion criteria, independent human-reference
validation and affix decomposition remain open. No external resources were
acquired, no Zotero records changed, and no commit/push/remote CI/publication
operation was performed.


## Source-linked word parts and local MorphoLex recipe (2026-10-06)

Added explicitly sourced example helpers, not public exports:
`word-parts.R`, `word-parts-demo.R`, and `morpholex-word-parts.R`.
The profile joins caller-provided analysis/part tables to complete imported
annotations by exact surface and optional UD POS. Root/prefix/suffix roles,
inflection/derivation, boundness and explicit part IDs stay separate. Multiple
roots and repeated parts count separately; different eligible analyses remain
ambiguous rather than contributing multiple copies to observed counts.
Source KWIC, candidates, partial/unanalysed/unlisted entries, unknown selection,
empty documents and original inputs survive aggregation. Complete totals and
proportions require a fully resolved selection; observed counts are separate.

The optional reader uses the already suggested readxl with explicit sheets
and words. It retains selected original rows (including unused norm/POS
columns), canonical segmentation, requested/missing forms, source sheets and a
workbook SHA-256. Extracted parts must agree with reported PRS/Nmorph fields;
unsupported entries remain unanalysed. Completeness is declared relative to
MorphoLex derivational segmentation, excluding inflection. No root boundness,
meaning, actual substring spans or derivation tree is guessed. No dataset,
model, new dependency, class, export or S3 method was added.

The existing preprocessing guide, README, NEWS and offline smoke document and
exercise this route. Formation-stage validation, nonaffixal-process analysis,
occurrence-specific reviewer application and a generic exported morphology API
remain unimplemented. Extra metadata preservation is not structure validation.
Neither authored examples nor five external records validate morphology
accuracy, corpus coverage or learner knowledge.

Evidence: `reviews/ldfreq-word-parts-20261006/evidence/`.

- Final focused test: **88 expectations**, zero failures/warnings/skips. Checks
  arithmetic, affix/token vs affixed-token denominators, repeated/compound roots,
  UTF-8 positions, same-spelling affix IDs, partial and unknown states, POS
  eligibility, empty references/documents, malformed inputs, bounded candidate
  and part expansion, RDS and character-ID CSV, and optional reader failures.
  The initial run exposed a zero-row key bug that created a phantom frequency
  row. The shared local key helper now returns character(0) for zero rows;
  focused retests cover both empty reference and wholly empty source.
- Local MorphoLex workbook read and joined to a source-authored five-word text:
  transmit, transport, transmission, teacher, teachers. Five root occurrences,
  four affix occurrences, three root types and three affix types agree with the
  actual selected records. Teachers receives no invented plural -s. Workbook
  SHA256: `5bc425fbb710f3d63cab69e77ee731fa466653ed0ace94937cac6c1fd6de52c6`.
  Complete local output is saved in `morpholex-local.rds`; source data stay
  outside the package. Only these rows and parsing/accounting were checked.
- All runtime R files, help files, NAMESPACE, extdata and specs match the prior
  family-review archive byte for byte. Its core/family/help-example evidence is
  reused. The changed guide rendered and its extracted script executed;
  20 other compiled guides were reused after source-byte comparison.
- Exact archive check:
  `R CMD check --no-tests --no-manual --no-vignettes --no-examples`:
  **Status OK**. Optional gibasa library was provided via R_LIBS. The targeted
  tests, installed smoke and guide execution are separate completed checks;
  this does not claim one full package test/example/vignette run.
- **241 audited source files** match the checkout; all DESCRIPTION fields match
  after build whitespace folding; all 21 compiled guides are included. No
  external workbook, private development folder or local workspace path is
  included in the package/compiled guides. Archive SHA256:
  `72939f0e6ac11d2ad52847a7cf5ddb11d4bc19e84cb4808fc11b978f25499497`.
- A fresh process using the checked archive installation reproduced the entire
  authored result in both conditions and the actual MorphoLex profile from saved
  inputs, without loading quanteda or readxl. Installed offline smoke and the
  installed changed guide script also succeeded. Public API audit remains
  54 exports, 34 S3 methods and 34 public help topics.

No commit, push, remote CI, site deployment, library write to Zotero, or CRAN
submission occurred. The canonical roadmap records these recipes as implemented
and distinguishes them from the remaining morphology API/validation work.


## Bundled MorphoLex reference and component licenses (2026-10-06)

The user challenged treating noncommercial conditions as a major disadvantage
and instructed continuation after the correction. Commercial availability is
not a mandatory project requirement. The roadmap now explicitly withdraws
noncommercial licensing as the reason to require local-only data access.
CRAN does not categorically exclude NC licenses; CC BY-NC-SA 4.0 is in R's
license database. Acceptance of this particular distribution remains untested.

Added public `morpholex_data(sheets = NULL)`, a plain-list data reader, separate
from the explicitly sourced morphology recipes. It exposes all 34 original
worksheet tables (68,624 word records, 142 prefix rows, 240 suffix rows, 15,471
root rows, Presentation), or a caller-ordered subset, with source/checksum,
license, conversion and sheet-origin metadata. All values are character;
missing cells remain NA. Numeric/logical cells use R text representation,
exterior blank margins are omitted, and formatting/formulas are not retained.
The original dictionary PDF and unchanged upstream license accompany the data.
No linguistic repairs, inferred parts, morphology model or new dependency
were introduced. The parts recipe defaults to bundled data without readxl;
explicit local paths still use readxl and the same source identity.

MorphoLex data/dictionary are CC BY-NC-SA 4.0. The original R code remains MIT;
TUBELEX and NJ8 terms remain unchanged. DESCRIPTION now uses `file LICENSE`
with `License_is_FOSS: no` and `License_restricts_use: yes`; it also names the
MorphoLex restriction in its Description. LICENSE, LICENSE.md, COPYRIGHTS,
resource notice, README, NEWS, public help, navigation and the existing guide
state the respective terms. An R rebuild script pins all upstream checksums.
Source Word cells for ELP IDs 42162 and 65908 are boolean cells: their R values
TRUE/FALSE are preserved and their exact-case lookup consequence is documented.

Evidence: `reviews/ldfreq-morpholex-bundle-20261006/evidence/`.

- Independent Python standard-library XLSX XML comparison against the R
  conversion covers all 34 sheets and **953,978 cells**: 291,116 text, 662,749
  numeric, 2 boolean, 111 blank. Text/boolean/missingness are exact; numeric
  cells are compared at relative tolerance 1e-14, absolute tolerance 1e-15 to
  allow different decimal spellings of the same double. All agree. Initial
  verifier assumptions about A1 origins and exclusively text/numeric cells
  were corrected against actual XML (Presentation C2; 0-1-0 D1; two booleans).
  No source values were changed to satisfy the verifier. Final snapshot and
  exact archive tables match the verified values.
- **133 targeted expectations** passed: 45 new data/adapter checks and 88
  existing word-parts checks, zero failures, warnings or skips. Public API
  audit passes: 55 exports, 34 S3 registrations, 35 public help topics.
- A public help example initially failed because `%in%` needed escaping in Rd.
  The Rd source was corrected; source-extracted and installed help examples
  subsequently execute. Targeted tests had already passed; this was a help
  syntax failure, not a failed numerical test.
- Changed guide rendered and its extracted script executed. All 20 unchanged
  guide Rmd sources were compared byte-for-byte before their compiled versions
  were reused. Existing runtime R files, NJ8/TUBELEX and specs are byte-identical
  to the preceding word-parts archive; no unchanged full numerical suite rerun.
- Exact archive scoped check, using the existing optional gibasa library:
  `R CMD check --no-tests --no-manual --no-vignettes --no-examples`:
  **Status OK**. External repository-index requests failed under network
  restrictions; checks used installed dependencies. Tests, help/guide execution
  and offline smoke are separate evidence, not one complete --as-cran run.
- **248 audited source files** match the checkout. DESCRIPTION matches after
  build whitespace folding; the R-generated build/partial.rdb is treated as
  generated output. All 21 compiled guides, license/dictionary and data are
  present, with no private directories, XLSX or local paths in compiled guides.
  RDS is **1,185,716 bytes**; combined extdata **4,010,789 bytes**; archive
  **5,012,796 bytes**. Archive SHA256:
  `e5864a717907978da4ee049c4d0ed357363ce09b82272b8a0f6069a1405a5e8b`.
- Fresh checked-archive installation reproduces the entire previously saved
  local-workbook reference and five-word profile, including the same unlisted
  query, without readxl/quanteda loaded. The first comparison used five queries
  against an old six-query reference; aligning the query vector to the saved
  input resolves that mismatch without changing the reader. Full RDS replay,
  installed help example, offline smoke and changed guide script all succeed.
- Changed local pkgdown home/license, reference/index, news and article pages
  built successfully after allowing public URL reads and normal cache writes.
  The sandbox-blocked initial site stage was resumed, not the successful tests.
  Pages contain license disclosure, no absolute workspace paths, and no stale
  non-bundling statement. No site was deployed.

Source fidelity and arithmetic checks do not establish morphological accuracy,
complete inflection coverage, corpus representativeness or learner knowledge.
No commit, push, remote CI, Zotero write, CRAN submission, or external message
occurred. The final archive and local site are reviewable development outputs.


## Nation BNC/COCA bundle and distinct morphology resources (2026-10-06)

The current task asked about Nation, MorphyNet and Japanese resources. The
completed package path is Nation's actual Level 6 family inventory, reused by
the existing family profiler. MorphyNet and J-UniMorph were inspected as
separate relation/feature resources; they are not bundled or exposed as new
analyzers. The active roadmap records their scope, candidate ambiguity and
next implementation conditions without changing the main research purpose.

`bnccoca_data()` returns the complete basic table (75,679 rows, 25,000
families), a separate supplementary table (29,798 rows), source catalog,
scalar family-resource declarations and conversion provenance. All 25 frequency
bands have 1,000 families. Slots 26--30 contain placeholders and are excluded;
Range executables/configuration are neither executed nor bundled. The official
umbrella resource page supplies CC BY-SA 4.0 or GPL as appropriate; the data
and conversion use CC BY-SA 4.0, with notice, attribution and full license.
No new dependency, analyzer, class or alternative family API is added.

The actual list assigns USE/USES and COLOUR/COLOR to their respective shared
families; REUSABILITY is absent. The installed example preserves six source
occurrences over two documents: 4/4 matched with two families in the first,
1/2 matched and complete family counts/TTR unavailable in the second. This
supersedes no authored fixture and supplies no guessed missing membership.
Level 6 inclusion, frequency bands and the separate Level 3 partial inventory
are explained in help, README and the existing preprocessing guide.

Evidence: `reviews/ldfreq-bnccoca-20261006/evidence/`.

- Official archive SHA256:
  `ac81c7a60e5c76cd2bbf0c59b0501808f0d4fa026b2936919dd54329a9bb6a69`.
  Independent Python stdlib parsing compares every value in **105,477 data
  rows and 34 catalog rows** to CSV exported from the exact installed archive.
  Source order, spellings, family membership, IDs, source lines and hashes agree.
- Independent parsing found UTF-8 BOMs in source lists 5, 18 and 19, despite
  the general instructions recommending no BOM. R consumes these markers;
  the independent decoder was corrected to UTF-8-sig and the conversion notice
  records the encoding transformation. No word spelling was altered.
- A catalog row-name inspection found temporary file paths inherited from
  named hash vectors. The builder now removes those names; a regression check
  confirms plain numeric row names. The final resource contains no local path
  metadata. Earlier provisional output is not the final resource.
- New targeted suite: **29 expectations**, no failures/warnings/skips. The
  existing family-profile suite also passed before metadata-only cleanup;
  its runtime and analysis data are unchanged. This is not a full numerical
  suite rerun. API audit passes: **56 exports**, 34 S3 registrations,
  36 public help topics (37 Rd files).
- The first guide render under pkgload reached an older installed helper via
  base `system.file()` and failed to find its nested example. A separate
  installed package library resolved the lookup. The guide then rendered;
  this was an installation-path issue, not a failing numerical test.
- The final archive scoped check used the existing optional gibasa library:
  `R CMD check --no-tests --no-manual --no-vignettes --no-examples`:
  **Status OK**. Network-restricted repository-index access used installed
  dependencies. Do not describe this as one full --as-cran check.
- Fresh installation of the **exact archive** reproduces the complete reference
  and example, then replays saved RDS inputs without readxl/quanteda loaded.
  Installed help, the offline smoke script and the changed guide's extracted
  R script pass separately. These results supplement the scoped check.
- **255 source files** byte-match the checkout; DESCRIPTION fields also agree.
  All 21 compiled guides are included. Twenty unchanged Rmd sources were
  byte-compared before reusing their compiled output. All **84** prior runtime,
  data and spec files are unchanged against the MorphoLex archive.
- New RDS: **509,712 bytes**; all extdata: **4,520,501 bytes**; source archive:
  **5,535,445 bytes**. Final archive SHA256:
  `888021b7bcac0f04bd72295e2f747c3c30dc5a9ca22b71a0bc95e27bd3d92997`.
  No private directories, original ZIP/XLSX/executable, or absolute workspace
  paths in compiled guides. Local home/license, relevant reference pages,
  NEWS and article rebuilt and checked for attribution and stale claims.

`experiments/check-morphology-references.py` also pins and checks the separate
MorphyNet English derivational file (225,131 six-column rows) and J-UniMorph
filtered jpn file (12,687 records, 107 lemmas, 10,848 forms). J-UniMorph retains
1,439 forms with multiple records, including potential/passive/honorific
candidates for 食べられる and alternative lemmas for 開ける. Their verified
licenses are respectively CC BY-SA 3.0 and CC BY 4.0. These source observations
are not contextual tagging accuracy, inventory-wide linguistic validation or
proof of suitability for a learner population. MorphyNet graph components are
not Nation families; J-UniMorph forms are not necessarily UniDic short units.

No commit, push, remote CI, deployment, CRAN submission, Zotero write or
external message occurred. This artifact is a reviewable local development
build, not a verified public release.


## MorphyNet local reader and occurrence review (2026-10-06)

Added `morphynet_read_derivations(path, language, resource_version, max_rows)`
for the six-field source/target/POS/morpheme/position format. It preserves
literal fields, alternatives and duplicates, assigns hash-scoped relation IDs
and line numbers, and records the full input SHA-256, supplied language/version,
source citation and CC BY-SA 3.0 terms without exposing the local path. It is
not an analyzer, affix counter, family generator, POS mapper or authenticator
of arbitrary user-provided files. No new dependency or S3 class is introduced.

The example uses existing `lexdiv_ambiguity_review()` with optional quanteda.
All three incoming reusability relations remain candidates for two occurrences;
one illustrative judgment selects reusable + ity, and another is withheld.
Single-candidate retransmit/transmitter remain unreviewed until a decision is
made. An unlisted teachers occurrence remains no_candidates. The original
17-token/five-segment roster, including an empty document, is retained.
Selecting one edge is an explicit study choice, not rejection of the other
potentially coexisting relations or a complete morphological decomposition.

Only nine unchanged source rows and their original line mapping are bundled,
with full license and attribution. The complete English v1 file remains local
input. Full-table trials measured 2,349,940 bytes as RDS or 1,628,932 bytes as
compressed original TSV, which would exceed the CRAN policy's general 5 MB
data guideline when added to the current 4,520,501 bytes. This is a measured
packaging tradeoff, not a licensing prohibition or a CRAN rejection. Separate
full-data distribution remains a future packaging decision; no extra data
package, download service or startup network request was introduced.

Evidence: `reviews/ldfreq-morphynet-20261006/evidence/`.

- The complete pinned English file has 225,131 rows and SHA-256
  `5920edacc1888b14464fc5cd96beea0a721221d56d1dc0e49de22f4c7c537c50`.
  Python stdlib independently compared all six fields, line numbers and
  generated IDs to the final installed reader's CSV. All match. All nine
  excerpt rows match the original lines, including every incoming relation
  for the six declared example targets. Source words/POS are never corrected.
- New suite: **52 expectations**, zero failures/warnings/skips. Existing
  ambiguity-review: **73 expectations** passed in the earlier targeted run;
  its code and fixtures are byte-unchanged. No full numerical suite rerun.
- Boundary tests caught NUL truncation when readLines used warn=FALSE. The
  reader now checks raw bytes and parses a raw connection, retaining exact
  input identity and rejecting NUL. Invalid UTF-8, malformed/trailing columns,
  empty/blank fields, invalid position, row limits, Unicode-blank metadata,
  BOM, missing final newline, duplicates and literal NA are covered.
- Under pkgload, the new test's isolated base-parent environment bypassed the
  package system.file resolver. The test now uses the namespace as its parent;
  the normal installed-package example had already worked. This was test
  resource lookup, not an error in the supplied relation data. The final source
  test and exact-archive installed example both pass.
- API audit: **57 exports**, 34 S3 registrations, 37 public help topics
  (38 Rd files). Help, examples, NEWS, README, package overview, license,
  COPYRIGHTS and navigation agree on complete local input vs the small excerpt.
- `R CMD check --no-tests --no-manual --no-vignettes --no-examples` using the
  existing optional gibasa library: **Status OK**. Repository-index requests
  are network-restricted; installed dependencies were used. This is a scoped
  check supplemented by separately executed tests/help/examples, not a full
  --as-cran or all-OS validation.
- The exact archive's fresh installation reproduces the entire external input
  table and saved example. Saved reference/review objects can be read with
  quanteda/readxl unloaded; regenerating KWIC correctly uses quanteda.
  Review replay, installed help, offline smoke and the changed guide's
  extracted script pass. DESCRIPTION fields match after whitespace folding.
- **263 source files** byte-match checkout. All 21 compiled guides are present;
  20 unchanged Rmds were compared before reusing compiled results. All **86**
  pre-existing runtime/data/spec files match the Nation archive. The new
  runtime is R/morphynet.R; prior algorithms and bundled inventories are unchanged.
- Archive **5,552,330 bytes**, total extdata **4,521,543 bytes**, SHA-256
  `2aaca4fc8ab68c7eebb62379f9dfe4e27f3241a01f85975cf8e4fd65d497f1e2`.
  Private development directories, full MorphyNet table and executables are
  absent. Local home/license, reference, NEWS and guide pages build and retain
  CC BY-SA 3.0 attribution, no absolute workspace paths, and the documented anchor.

Source fidelity, authored decisions and replay do not establish morphological
accuracy, semantic uniqueness, coverage outside the tested reference, learner
knowledge or productivity. Multiple edges are not summed as observed affixes.
The current KWIC route requires whitespace-free single-token target surfaces;
complete derivation trees, lemma/multiword alignment and Japanese form-span
alignment remain separate tasks. No commit, push, deployment, remote CI,
CRAN submission, Zotero mutation or external message occurred.

## 2026-10-06 roadmap evidence review after MorphyNet

This is a planning/documentation update, not another package build or release.
The current roadmap now prioritizes a concrete release-inventory gap before
additional feature work:

- `inst/spec/ldfreq-installed-resource-manifest.json` and
  `experiments/resource-admission/ldfreq-release-resource-inventory.json`
  still list only TUBELEX and NJ8. MorphoLex, Nation BNC/COCA and the MorphyNet
  excerpt are present in the source tree but absent from these inventories.
- Both inventories record `COPYRIGHTS` as 1,401 bytes with SHA-256
  `467853be2cc1944f88b434a9ce802b0b5d9b358d483e24f849b6d97c7f647beb`.
  The current `inst/COPYRIGHTS` is 3,066 bytes with SHA-256
  `27056951661decd9211a8f7e4558717d6144d64b480dbdac60f0ee207909be2c`.
- The resource-admission and package-resource-inventory validators retain
  two-resource assertions. The latter also checks every declared member's
  size/hash and rejects undeclared extdata. These static discrepancies must
  be corrected; no remote CI failure was observed or newly induced here.
- Release-candidate state is still `development`; its workflow's state check
  does not establish that the conditional candidate-build jobs ran.

Existing scoped checks, full-table conversion comparisons, installed examples
and round trips remain evidence for their recorded scope. They do not prove
that the current resource inventories are complete. The next implementation
should update the existing inventories/validators and validate the changed
distribution path, reusing unchanged numerical and conversion evidence.

The research plan also reuses the existing 140-document ICNALE results.
`analysis/icnale-gra/results/dictionary-review/summary.csv` in the workspace
reports unchanged MATTR50/HD-D42 and NJ8 mean coverage from 0.9629180903 to
0.9646497995 after 55 occurrence changes across 43 documents. The script labels
this as assistant context review without independent human validation.
New family/morphology conditions, Japanese form-span handling and broader
annotation accuracy remain distinct future work. No analysis was rerun and
no private corpus content was copied into the package.

## 2026-10-06 five-resource inventory and distribution checks

Closed the inventory mismatch identified in the preceding roadmap review.
The installed schema is now 1.2.0 and the repository inventory schema 0.2.0.
Both records cover TUBELEX, NJ8, MorphoLex, Nation BNC/COCA and the nine-row
MorphyNet excerpt. The last is explicitly example-only; the full external
MorphyNet database is not declared bundled. Each shipped data/notice/license
member has a byte count and SHA-256. Null separate-manifest/decoded-content
hashes denote inapplicable representations, not unverified member bytes.
The shared COPYRIGHTS file is registered once with its current identity.

The admission validator compares all component records, not just TUBELEX.
The package audit rejects undeclared license files as well as extdata.
Tracing its consumers also found a one-resource assumption in the release
index and an obsolete whole-package MIT assumption in SPDX generation.
The index now compares IDs/counts to the exact resource BOM; the SPDX record
uses a LicenseRef containing the source component-specific LICENSE text.
The resource BOM includes the full admission inventory while labeling the
older approval decision as TUBELEX-specific. No license permissions changed.

Evidence: workspace `reviews/ldfreq-resource-inventory-20261006/evidence/`.

- `regressions.log`: 16 actual CLI cases pass, including valid/reordered
  inventories and rejection of missing/duplicate resources, mismatched terms,
  unapproved entries, excerpt-scope drift, member drift, missing data/license,
  equal-size tampering, stale COPYRIGHTS, undeclared data/license files,
  duplicate paths and invalid relative paths. Three additional checks execute
  production record-generation/aggregation expressions with local fixture
  inputs: component terms, complete admission BOM with archive mismatch
  rejection, and resource count/ID comparison. These fixtures are not CI runs.
- Both JSON records validate against their Draft 2020-12 schemas with Python
  jsonschema. Independent Python size/SHA-256 comparison verifies all 21
  declared resource members. Workflow YAML parses; the regression command is
  registered once in the Ubuntu release-R job. Remote CI was not triggered.
- `package-audit/package-resource-inventory-evidence.json`: **2,317 assertions**,
  **5 resources**, **56 audited members**, source archive / Mac platform
  archive / fresh installed library byte-identical. Environment: Darwin,
  aarch64-apple-darwin23, R 4.6.1 (2026-06-24). No undeclared extdata observed.
- `installed-resource-test.log`: the installed TUBELEX audit passes **101
  assertions**, including its existing bounded loader/tamper checks and the
  updated all-resource member check. It uses the exact new archive install.
- `archive-audit.json`: **263 source files** match the checkout. All **21
  compiled guides** were reused after byte-comparing every Rmd source.
  **156 runtime/help/data/license/example/guide input files** are unchanged.
  Existing numerical, complete conversion and example-replay evidence remains
  applicable to those inputs; no broad numerical rerun or new full check.
- Source archive `ldfreq_0.2.0.tar.gz`: **5,554,356 bytes**, SHA-256
  `6d293b51d7f20706902d0a55aca39330e9d70b503aa73d6100007d821928de9f`.
  Extdata remains **4,521,543 bytes**.
- Mac platform archive `ldfreq_0.2.0.tgz`: **6,186,774 bytes**, SHA-256
  `cd287fcdef05ef4b6b3e954f01e991da01077d43ce1c14f916b435fd0d7849ae`.
  These identify this run, not reproducible archive generation across builds.
- NEWS and the local news page describe the completed change. The first page
  build failed resolving the public crandb host under network restrictions;
  rerunning only `build_news()` with network access succeeded. No package
  tests or build were repeated because of that documentation failure.

The resource-inventory gap is closed locally. A clean-candidate full release
workflow, other OS checks, same-version public artifacts/site and CRAN
submission/acceptance remain distinct unfinished stages. `state.dcf` remains
`development`. No commit, push, remote publication or corpus/model analysis
was performed. The next research task remains the roadmap's ICNALE
family/morphology extension, using the existing saved analysis.

## 2026-10-06 common-token family comparison

Completed the family-counting part of the planned ICNALE extension. The new
explicitly sourced `inst/examples/family-count-comparison.R` recipe reuses the
existing family API; public exports remain 57. It reports whole-selection
coverage and missing totals separately from surface/lemma/family types and TTR
on the same resolved occurrence IDs. It retains complete profiles, source IDs
and explicit selection. No identity fallback or moving-window measure on a
gap-closed subset is introduced. The Nation example supplies authored lemmas;
the existing guide and NEWS explain the comparison.

Local corpus evidence: workspace `analysis/icnale-gra/results/family-comparison/`.
The script reuses 140 original essays and 31,902 saved English lexical tokens
and baseline textstem lemmas. All source/processed hashes and token spans agree.
The imported representation retains all non-whitespace text; 3,654 context-only
gap chunks remain outside the lexical denominator. Original coordinates are
verified under the one-codepoint transformations that hold for this input,
with failure on unsupported normalization changes.

Core Nation lookup matches 30,892 tokens, leaves 1,010 unlisted and encounters
no multiple-family candidates. Supplementary string matches (103 tokens) stay
separate, without POS inference or inclusion in the core count. Whole-selection
family V/TTR is unavailable for 135 of 140 documents. On each document's common
resolved set, mean types are surface 108.9857, lemma 100.6857 and family 97.45.
These are conditional descriptive results, not annotation accuracy or learner
knowledge. Later contextual lemma revisions are not mixed into this condition.

- A separate direct lookup agrees with all lexical assignments. Saved token
  IDs/coordinates, denominators and all 840 comparison rows agree with direct
  counts (`independent-checks.csv`).
- `replay.log` records a fresh R process replay of complete profiles and
  comparisons, including IDs/settings, without retokenizing, lemmatizing or
  repeating rating associations/bootstraps. The complete RDS retains sources,
  reference, selection, candidates and provenance locally.
- Targeted `test-bnccoca-data.R` tests pass: hand-counted complete/partial cases,
  missing lemmas, ambiguous families, exclusions, empty documents/common sets,
  invalid selections, modified profiles and RDS replay. An initial test expected
  integer indices although the fixture supplied doubles; it now correctly
  asserts preservation of supplied indices.
- The local report was rendered from saved outputs. Its two existing plots
  no longer embed titles; axes identify the outcome/counting unit. Rendered
  images were inspected. No new difference plot was added.

Distribution evidence: workspace
`reviews/ldfreq-family-comparison-20261006/evidence/`.

- The changed guide rendered using current installed examples. Twenty unchanged
  compiled guides were reused after byte comparison of Rmd inputs.
- The exact source archive installs into a fresh library. The authored example,
  saving/recounting and extracted guide R script execute (`installed-replay.log`).
- `archive-audit.json`: 264 source files match the checkout; all 149 installed
  inst members match archive bytes. Runtime R, Rd help, data and licenses are
  unchanged from the inventory archive. Prior numerical/resource validation
  remains applicable and was not repeated.
- Archive scans found no local-user paths or selected private-corpus file/record
  markers. Corpus text and individual derived records remain in the separate
  local analysis folder. Public documentation gives only a brief dataset/version,
  sample size and implementation-check description.
- Source archive `ldfreq_0.2.0.tar.gz`: **5,560,690 bytes**, SHA-256
  `620bb962116f22425fb3628536db555b96325a165c4d005a8a0e55d699a87436`.
- Local article and NEWS pages are updated. Article generation succeeded;
  NEWS initially failed resolving public CRAN metadata under network isolation.
  Only NEWS generation was retried with network access and succeeded.

No full R CMD check, new platform binary, remote CI, commit/push, remote site
publication or CRAN submission was performed. Candidate state remains
`development`; installation checks do not establish all-OS release completion.
Morphological-candidate linkage remains the next part of the local analysis,
independently of the remaining release checks.

## 2026-10-06 Japanese kana/kanji occurrence review

Added `inst/examples/japanese-orthography.R`, a self-contained optional quanteda
example using the existing annotation importer and ambiguity-review API. The
Japanese annotation guide and NEWS describe original spelling, reviewed lexical
identity and the separate evidence needed to infer kanji production knowledge.
No public API, required dependency, automatic converter or corpus data was added.

The authored example retains complete source annotations and compares declared
target occurrences only. Three apple spellings have three surface types and one
selected lexical ID. Three HASHI occurrences yield two contextual selections
and one unresolved occurrence; whole-target lexical types remain NA. On the
same two selected occurrences, surface types = 1 and lexical types = 2. A target
with no candidates, a document without targets and an empty document remain
distinct. These are demonstration decisions, not independently judged corpus
annotations or an accuracy/knowledge evaluation.

Evidence: workspace `reviews/ldfreq-japanese-orthography-20261006/evidence/`.

- Current checkout installs into a separate library (`install.log`). The new
  installed example is byte-identical to its source, SHA256
  `029387a8b85cce349b148add21cf8c863eaf4026e000cbf4e539f51be202ba0f`.
- Focused tests pass **24 assertions** under C.UTF-8, both in development and
  against that installation. Hand-counted populations/types, original kana and
  character spans, unresolved alternatives, RDS saving/replay and rejection of
  a candidate belonging to another surface are covered (`verification.log`).
- The changed guide renders with the new optional example. Rendered text
  contains the Japanese strings, count output and stated limitations, with no
  local user path (`content-check.log`). This is content verification, not a
  browser layout audit. The separately optional gibasa branch was not run here.
- Initial standalone `purl()` extraction printed three missing-`run_gibasa`
  option-evaluation diagnostics: that extraction does not execute the setup
  chunk before evaluating later options. Guide rendering itself succeeded.
  Only extraction/replay was repeated with the optional flag explicitly FALSE;
  it executes the new example and checks its counts (`extracted-replay.log`).
- All **81 R/help files** are byte-identical to the previously verified family
  comparison archive. Existing core evidence is retained; no whole-package
  numerical test run was repeated for this example/guide-only change.

The guide also corrects an outdated statement: source-span segmentation
comparison already exists in `lexdiv_align_annotations()`, while label comparison
requires identical token rows. Neither determines the correct segmentation by
itself. Multi-token candidate review and J-UniMorph linkage remain future work.

No new source archive, platform binary, full R CMD check, remote CI, site
publication or CRAN submission was performed. The previous source archive does
not contain this example or the changed guide; its evidence remains scoped to
that earlier artifact. Real learner-corpus validation is still pending.

## 2026-10-06 Japanese boundary review and actual analyzer probe

Extended the same spelling example with separate boundary and lexical decisions.
Both complete annotation alternatives keep `はしではしをつかいます。` unchanged.
Source positions 4--5 connect `は / し` to the reviewed `はし`. The reviewed input
is imported afresh and its KWIC decisions have a new review identity. No fragment
lemma/POS is propagated to the joined token. The author's intended bridge and
chopsticks readings are explicitly declared, not inferred as a gold standard.

Whole-sequence surface counts excluding only the full stop are N/V = 7/7 for
the split alternative and 6/5 for the reviewed alternative. Empty documents are
retained. Exact-span-only scoring would remove the changed occurrence; the guide
now explains why these full-sequence counts and contextual target counts have
different populations. No automatic editor, multi-token candidate API or new
export was introduced.

Evidence: workspace `reviews/ldfreq-japanese-boundaries-20261006/evidence/`.

- A fresh gibasa 1.1.3 run with local unidic-lite 1.0.8 (UniDic 2.1.2) processed
  eight authored diagnostic sentences using the existing guide's analyzer
  function. `probe.rds` retains all raw expanded features and session metadata.
  The selected sentence actually produced `はし / で / は / し / を / つかい /
  ます / 。`. Other recorded outputs include `すん -> 済む`. These observations
  do not estimate population error rates or establish independent accuracy.
- `verify-actual.R` reuses that saved probe, imports all eight complete source
  annotations, records dictionary/configuration hashes, and checks original
  positions. The selected sentence passes actual-input alignment, new lexical
  review and RDS replay (`actual-verification.log`, `actual-boundary-review.rds`,
  `actual-token-audit.csv`, `changed-source-spans.csv`, `surface-counts.csv`).
  No second analyzer pass was needed for these downstream checks.
- Focused development and installed tests pass **46 assertions** in C.UTF-8
  (the earlier 24 plus 22 boundary-workflow expectations). Tests cover exact
  source spans, hand-counted complete populations, empty documents, restored
  targets, saved alignment and rejection of old review IDs after resegmentation.
- The changed guide renders; its extracted script executes both examples.
  Rendered content includes the boundary table, counts and scope, without a
  local user path. This is content verification, not browser visual inspection.
  Twenty unchanged compiled guides are reused after matching their Rmd sources.
- Source archive `ldfreq_0.2.0.tar.gz`: **5,575,560 bytes**, SHA256
  `9b5fe544f095c43e78f67fb9803289aaeb369caa1b8f66e9e565e79b63f6e87b`.
  All **266 source files** compared to the checkout and all **150 inst members**
  compared to the fresh archive installation are byte-identical
  (`archive-audit.json`). The source includes the new tests and both Japanese
  examples. R/help/data/license and public API are unchanged.
- Exact archive installation, the examples, RDS round-trip and installed guide
  script pass (`archive-replay-final.log`). The first smoke assertion expected
  integer storage for metric N, whose API output uses doubles. Only that
  verification assertion was corrected to check numeric count values; no
  runtime edit, reinstall or full test rerun was needed.

The latest archive now includes the spelling and boundary changes that were
absent from the earlier family-comparison archive. No full R CMD check, new
platform binary, remote CI, site publication or CRAN submission was performed.
Actual learner-corpus validation, automatic disambiguation and J-UniMorph
multi-token candidate linkage remain outside this completed example change.

## 2026-10-06 NINJAL learner-essay input and partial-whitespace import fix

The next Japanese workflow step uses actual locally acquired essays. Official
download and filename guidance were checked at
<https://mmsrv.ninjal.ac.jp/essay/essay_05.html> and
<https://mmsrv.ninjal.ac.jp/essay/essay_04.html>. The TXT ZIP and essay/writer
workbooks are supplied under CC BY-NC-ND 4.0. Corpus text, source metadata,
individual annotations and review queues remain in the workspace's local
`analysis/ninjal-essay/`, outside the package and site. No correction XML was
downloaded or used in this step.

The distribution downloaded on 2026-10-06 has **1,777** TXT members matching
1,777 unique essay metadata records; the overview page's historical 1,754 is
not used as the archive count. The writer workbook has 1,589 unique writer IDs.
There are 1,764 UTF-8 and 13 explicitly inspected CP932 texts; 179 UTF-8 members
have a leading BOM. One essay has no writer-table match, and one filename is
irregular. Metadata mappings are used rather than filename parsing. Unmatched
L1 stays missing; source nonresponse labels remain verbatim. Country is not L1.

`inst/examples/ninjal-essays.R` is an explicitly sourced local reader, not a
new export. It accepts already-read character metadata tables and a local ZIP,
with explicit per-file encoding where needed. Failed decoding, failed byte
round-trip, conflicting BOM, duplicate join keys and missing requested files
are rejected. Only a leading UTF-8 BOM is removed and recorded; all other
characters and line endings are preserved. It retains raw/text/ZIP hashes,
source filenames, document/writer/task IDs and missing metadata status.
Optional readxl reads XLSX files in the guide; no dependency was added.
The new test ZIP contains three wholly authored UTF-8/CP932/empty records.

Raw file identity is recorded in `analysis/ninjal-essay/raw/source-manifest.json`:

- `sakubun_txt.zip`, 1,602,811 bytes, SHA256
  `686607d589ef2250440fb904b6f213c62b3aa6d0b41abcfa827888dae055801c`.
- `sakubun.xlsx`, 149,797 bytes, SHA256
  `89433a79573cac7881999a971c07c359db711dd34038f693823f7d30bc152079`.
- `shipitsusha.xlsx`, 57,015 bytes, SHA256
  `1fc17b0486909e338173b8657ad78c7c440335e0f1207d3d533671a96c3bb62d`.

All 1,777 R-decoded strings and raw-byte hashes agreed with an independent
Python decoder/hash comparison, including all CP932 members. The explicit
encoding manifest, imported RDS and per-file import audit are retained locally.

### Real input exposed a whitespace-alignment defect

The diagnostic subset consists of four task-01 essays per reported L1 label
(Chinese, Korean, English, Finnish, Sinhala, German and Japanese), selected in
radix essay-ID order: 28 distinct writers. This is not a random or representative
sample and does not estimate L1 differences. The existing guide's gibasa 1.1.3
function and unidic-lite 1.0.8 (UniDic 2.1.2) were used without rewriting text.
Dictionary/configuration hashes, raw features and selection rules are saved.

The first annotation import stopped at an actual CR/LF sequence: the analyzer
emitted CR tokens while omitting LF, but the importer required a whitespace-
prefixed token to start immediately at the cursor. `R/annotation-input.R` now
finds its earliest exact match across **whitespace-only** gaps. Non-whitespace
omissions, normalized replacements and inconsistent supplied positions still
fail. Original text and positions are retained; valid earlier imports and the
public API remain unchanged. Help and the guide describe the rule. Regression
cases cover partial CRLF, whitespace-only text, omitted letters/punctuation,
supplied positions and identical reimport.

After this fix, all **10,932 annotation rows** aligned with the 28 original
texts. An independent substring and non-whitespace coverage check passed.
Excluding auxiliary symbols and whitespace, while retaining particles and
auxiliary verbs, gives 9,554 tokens. Of these, 139 lack lemma annotations; the
common surface/base/lemma population is 9,415. Full-population lemma type counts
remain NA when features are missing. Lemma labels are not assumed to be unique
lexeme identities. The local review table includes 1,830 kana-surface/Han-lemma
occurrences plus missing-lemma candidates, all initially unreviewed. These are
not verified errors, unknown words or measures of kanji knowledge.

The input is the complete distributed TXT, including titles and transcription
notation. No cleaned-body claim, human accuracy reference, automatic correction,
or corrected-XML comparison is made. This establishes local input, alignment
and counting behavior; segmentation and lexical-identification accuracy remain
unevaluated. Authored review examples remain the distributable demonstration.

### Validation and distributable artifact

Evidence: workspace `reviews/ldfreq-ninjal-input-20261006/evidence/`.

- Related development tests pass **745 assertions**, with no failures, errors,
  warnings or skips (`focused-tests.rds`, `focused-tests-summary.log`). Scope:
  annotation input/alignment/evaluation, ambiguity review/comparison, family
  profiles, amod pairs, Japanese orthography and the new reader example.
- Installed importer/reader tests pass **84 assertions** (64 importer, 20 reader).
  The changed Japanese guide renders and its extracted script executes.
  Saved actual annotations reimport identically in a fresh R process
  (`verify-installed.R`, `installed-verification.log`).
- Twenty unchanged compiled guides are reused after byte-matching their Rmd
  sources. The changed guide's content and script were checked, without a
  browser layout audit. No successful numerical experiment or full guide set
  was rerun merely for this input fix.
- New source archive `ldfreq_0.2.0.tar.gz`: **5,586,141 bytes**, SHA256
  `49fb056fdbfacada735064c75458ec7ec83bd93dc069166f3d941fe95ab3d0d9`.
  All **269 source files** compared with the checkout are byte-identical;
  DESCRIPTION is separately checked by field values because R CMD build
  rewraps it and adds generated fields. All **151 inst members** match a fresh
  installation of the exact archive (`archive-audit.json`). Relative to the
  preceding archive, the only changed runtime R file is `annotation-input.R`.
  No local user paths, local analysis directory or diagnostic private corpus
  filenames occur in the archive; authored ZIP members were verified explicitly.
- With the exact archive installed, all **1,777** imported documents and the
  **28-document** annotation object replay identically. The installed guide
  script also passes (`verify-archive.R`, `archive-replay.log`). This reuses the
  saved analyzer output; it does not rerun the analyzer or call this a second
  independent accuracy assessment.
- `R CMD check --no-tests --no-manual --ignore-vignettes` reports **Status: OK**
  on macOS / R 4.6.1 / UTF-8 (`ldfreq.Rcheck/00check.log`). The check library
  lacks optional gibasa (INFO); actual analyzer validation used the separate
  existing local gibasa library. Tests and the changed guide were verified in
  the separate steps above, not by this scoped check. This is not one full
  check with every optional dependency and vignette enabled.

There are still 57 exports; no new required dependency, platform binary,
remote CI run, site publication or CRAN submission was introduced. The roadmap
now distinguishes real-corpus input validation from independent linguistic
accuracy evaluation; J-UniMorph multi-token linkage remains a later task.

## 2026-10-06 J-UniMorph records and multi-token span review

Implemented the roadmap's bounded Japanese morphology path as explicitly
sourced example helpers, retaining the existing single-token ambiguity API.
`inst/examples/junimorph-spans.R` supplies `read_junimorph()` and
`review_morphology_spans()`; `junimorph-spans-demo.R` provides authored text,
complete authored annotations, six authored format-demonstration rows, choices
and an unresolved occurrence. These are not exported functions or a bundled
J-UniMorph excerpt. No required dependency or corpus data was added.

The official <https://github.com/cl-tohoku/J-UniMorph> README was checked again:
`jpn` is the filtered three-column input, distinct from the hit-count source,
and the dataset is CC BY 4.0. The already-acquired local `jpn` has 12,687 rows,
107 lemma labels and 10,848 forms; its Git blob is
`6b001fa9d33139bd9b85ffe70f74c1143ae9df24`, SHA256
`6ba4589cd43846c8afab5bdf5f4c498e03e32849f95c3e5c9840be2975d4b888`.
The reader preserves all original fields, row order, duplicate records and
source-row candidate IDs, alongside resource metadata and file identity. A
separate `read.delim()` comparison confirmed all three fields of every row.
The table itself remains outside the package.

Exact source-form searches retain overlapping hits. Every hit has its original
segment-local Unicode start/end; endpoints that agree with complete imported
token boundaries also receive token-from/to and token-count fields. A substring
ending or starting inside an analyzer token remains a `boundary_mismatch`,
requiring boundary review before a lexical candidate decision. Nothing is
silently resegmented, normalized or counted as a new word. The span KWIC uses
original codepoint windows, explicitly distinguished from the existing
quanteda token-window API. It preserves spaces and newlines within each segment.

Selected, unresolved, unreviewed, no-candidate and boundary-mismatch cases are
separate. Decisions require source/reference/target identity, an existing
occurrence, a candidate belonging to that exact form, and a reviewer/reason.
Changes to segmentation or the candidate table invalidate old decisions.
Overlapping selected spans remain flagged and cannot be added as word counts.
Document summaries count diagnostic spans; absent requested forms and empty
documents remain visible. The implementation scans each form per segment and
is an explicit local workflow, not a corpus-scale matching engine.

The authored demonstration has five target spans, of which two are selected,
one unresolved, one unreviewed and one without candidates. Two selected forms
map to one lemma label on exactly the same selected population; the complete
target lemma count is unavailable. All 26 original annotation tokens remain
unchanged before and after review. These declared teaching decisions do not
establish independent linguistic accuracy.

Evidence: workspace `reviews/ldfreq-junimorph-spans-20261006/evidence/`.

- **50 development assertions**, and the same **50 installed assertions**, pass
  without failures, errors, warnings or skips. They exercise source positions,
  repeated and multi-token occurrences, exact combining-character/emoji
  handling, overlapping hits/selections, boundary mismatches, candidate
  membership, stale segmentation/reference/target decisions, missing and empty
  cases, explicit metadata, malformed files and RDS replay (`tests.rds`,
  `tests.log`, `installed-verification.log`). During implementation, the
  isolated-environment check required namespacing `stats::setNames`; restored
  UTF-8 targets are explicitly marked before radix sorting. Both paths pass.
- The existing **28-essay** source/annotation object was reused without another
  learner-corpus analyzer run. Full-table matching produced **1,309 exact
  spans**, of which **587** agree with token boundaries and **722** do not.
  Of the aligned spans, **409** cover multiple tokens and **98** have multiple
  candidate records. **619** of all exact spans overlap another span. R checked
  all substrings and reconstructed all aligned spans from the original token
  surfaces. These are matching diagnostics, not error/accuracy estimates.
- An independent Python overlapping substring search reproduced **all 1,309
  source ranges**, and independently mapped all **587** aligned ranges and
  **409** multi-token ranges (`verify-independent.py`, `independent.log`). It
  reads the downloaded ZIP and explicit encodings; real text/individual
  records are not written to publication evidence. Real outputs and an empty
  decision template stay in `analysis/ninjal-essay/morphology-spans/`. All
  actual-corpus candidate decisions remain unreviewed, with zero selections.
- A new gibasa 1.1.3 / unidic-lite 1.0.8 run on **five authored sentences plus
  an empty document** checks actual token spans against the full resource.
  All five target occurrences align; candidate counts are 3, 3, 1, 2 and 0.
  Author-declared selections/withholding survive saving and fresh-process
  replay (`actual-authored.rds`, `verify-actual.R`, `actual-verification.log`).
  Dictionary and configuration hashes match the earlier validated setup.
- The changed guide renders and its extracted script executes. Twenty
  unchanged compiled guides are reused after source equality checks. This is
  content/execution verification, not a browser layout audit.
- Source archive `ldfreq_0.2.0.tar.gz`: **5,600,278 bytes**, SHA256
  `42ce455b83829d7df16cedda383a02dc721a507ac2729e7949655a6b818495d4`.
  All **272 compared source files** equal the checkout; build-normalized
  DESCRIPTION values are checked separately. All **153 inst members** equal
  the exact archive's fresh installation (`archive-audit.json`). No local
  paths or analysis/development/experiments directories are included.
- The exact archive replays both the 28-essay review and actual-authored
  decisions identically, runs its installed guide script, and retains **57
  exports** (`verify-archive.R`, `archive-replay.log`). Runtime R, Rd, bundled
  resources/licenses and NAMESPACE/LICENSE comprise **108 unchanged members**
  relative to the previous archive; earlier runtime tests and scoped check
  evidence remain applicable to that unchanged code, not a new full check.

No full test-suite rerun, new R CMD check, platform binary, remote CI, site
publication or CRAN submission was performed. This closes the explicit
local-reader → multi-token source-span → KWIC decision/withholding → replay
example path. Independent contextual accuracy, automatic normalization,
general lexical/sense span review and changes to the counted word unit remain
separate work. The current release is not gated on those research extensions.

## 2026-10-06 English morphology at shared corpus occurrences

The explicit `morphology-link.R` recipe connects an existing family profile to
MorphoLex segmentations and MorphyNet incoming derivational relations. It keeps
one row per selected original token, separate resource candidates and separate
KWIC decisions. Only a selected complete segmentation contributes reviewed
root/prefix/suffix instances; selected one-step relations are counted separately.
Full segmentation totals remain unavailable until every eligible occurrence has
a selected complete analysis. A zero reviewed total is not absence of morphology.
The authored demonstration, guide and tests exercise repeated surfaces, distinct
choices, ambiguity, withholding, no candidates, empty documents and saving/replay.
This is an explicitly sourced example, not a new export or mandatory dependency.

The saved ICNALE GRA V2.1 family profile was reused, preserving all **31,902**
selected occurrences in **140** essays, source coordinates, original KWIC and
family assignments. Exact cached surface matching finds **30,690** MorphoLex
occurrences (30,680 unique complete entries; ten matched unanalysed entries) and
**4,592** MorphyNet occurrences, including **401** with multiple relation
candidates. **4,348** occurrences match all three resources. These counts
describe different resource units and scopes, not comparative accuracy.
No corpus candidate decisions were made; no learner knowledge, productivity or
independent contextual accuracy is inferred. Original text and individual
corpus outputs remain under the local `analysis/icnale-gra/` directory.

Evidence: workspace `reviews/ldfreq-morphology-link-20261006/evidence/`.

- All candidate counts agree with direct lookups against preserved MorphoLex
  worksheet Word cells and the full 225,131-relation MorphyNet English v1 table.
  Every document denominator and original selected ID/coordinate/family matches
  the saved prior analysis. This does not rerun tokenization or family analysis.
- **40 installed assertions** pass, including an authored alternative MorphoLex
  segmentation that must not be summed with the selected candidate. The changed
  guide renders, and its extracted script runs from the exact archive installation.
- The exact archive reproduces the complete saved 140-essay linkage in a fresh
  R process and passes the same 40 assertions. DESCRIPTION field values and all
  **155 installed inst members** match. API audit remains **57 exports / 34 S3
  registrations**. The five-resource admission validator passes 36 assertions.
- Source archive: **5,611,720 bytes**, SHA256
  `e891bf10e54ab08cf25988b29ed18705690a6217d95e7e42e2cb57029adfe6d0`.
  All **275 compared source files** match the checkout. Twenty unchanged compiled
  guides and **108 unchanged runtime/help/resource/license members** retain prior
  evidence. Generated build indexes and normalized DESCRIPTION are distinguished
  from literal source files. Restricted corpus files and local paths are absent.
- Added Git byte-preservation attributes for the three new resource directories
  and their license directories. A `core.autocrlf=true` checkout reproduces all
  **21 resource-manifest members** exactly. This addresses the known Windows
  checkout risk before running the accumulated revision through CI.
- Initial development-mode tests could not resolve nested installed example
  paths through pkgload's shim. Fresh installation passes without a code workaround.
  An initial local analysis identity assertion compared inherited data-frame row
  names; comparing each explicit ID column fixed that verification script.
  Neither issue changed resource matching or the package's measurement formulas.

The remote was rechecked: `Ryuya-dot-com/ldfreq` is PRIVATE and draft PR #21 is
open. Its existing successful CI covers `d6eabd14`, not this accumulated revision.
Anonymous TLS-verified repository and documentation-root requests returned 404
and 200 respectively; a reachable site alone does not demonstrate publication of
the new functions. Keep `state.dcf` at `development` while integrating the changes
into that private PR. No visibility change, main merge, Pages deployment or CRAN
submission is included. Record the selected new CI result separately from older
successful checks and from the intentionally skipped release-candidate jobs.


### First integration CI and Unicode fixture correction

Commit `8183addbe4247d06a7d64606bb1e2a60fbca72a3` ran at
<https://github.com/Ryuya-dot-com/ldfreq/actions/runs/37444349754>.
Mac, Linux release and Linux devel each passed **7,785** assertions with zero
failures/warnings/skips and `Status: OK`. R 4.1 passed **7,710** assertions with
zero failures/warnings, eight optional-textstem skips and two NOTEs (optional
gibasa/textstem unavailable; installed size). Both TUBELEX builders and the PDF
manual passed. Mac and Linux release each passed the **2,017-assertion** inventory
check and byte-matched 56 members across source/platform/installed forms.
Linux also passed all 16 rejection fixtures and three release-record tests.

Windows failed one test before the span-review helper ran: the mixed literal
emoji / escaped combining-character fixture did not align with its token
surfaces during annotation import. Its existing separate all-escaped Unicode
import test passed. Construct the non-BMP and decomposed strings with explicit
Unicode scalar values instead; retain all original boundary and occurrence
expectations. This is a fixture construction change, not a runtime normalization
or position-calculation change. The corrected **50 assertions** pass locally;
Windows confirmation is pending the updated PR revision. The precise upstream
parser mechanism has not been independently reproduced outside that CI test.

The first workflow and its required aggregate correctly remain failed; do not
call the overall run successful. The development-state release classifier at
<https://github.com/Ryuya-dot-com/ldfreq/actions/runs/37444349755> passed with
candidate artifact jobs skipped, as intended. No jobs were cancelled.

The corrected archive is `reviews/ldfreq-morphology-link-20261006/evidence/final/ldfreq_0.2.0.tar.gz`,
**5,611,817 bytes**, SHA256
`c4b11c1b15a81cfd303dcf97deb07b4604e87fd1a74d9ab5acb51d7f93d69e9f`.
Its only changed archive members are the test fixture and DESCRIPTION build
metadata. All **275 compared source files** match the checkout and all **155 inst
members** match the existing exact-archive installation. Runtime, help, data and
all compiled guides are unchanged, so no repeated numerical analysis, resource
conversion, guide render or full local test run is needed for this fixture fix.
The existing PR workflow verifies every head revision; bundle this fix and its
evidence into one update, without a separate manual duplicate run.

The two changed local articles and NEWS build successfully; 128 local HTML pages
have no missing local file targets. NEWS needed a permitted external CRAN-history
lookup after the restricted-network attempt failed; only that document stage was
repeated. The public family-reference URL still returns 404. These are local
site checks, not publication or a full visual layout audit.


### Final integration result: c788d909

<https://github.com/Ryuya-dot-com/ldfreq/actions/runs/37446251926> completed
successfully for `c788d909dcd113492261b4fd99b9787f6d61eb1e`: **all nine jobs pass**,
including the required aggregate, five R/OS environments, two TUBELEX builders
and the PDF reference manual. Saved `final/ci.json` identifies the exact revision
and each job; `final/ci-*.log` preserves each package-check log.

Windows, macOS, Linux release and Linux devel each report **7,785 passes**, zero
failures/warnings/skips and `Status: OK`. The corrected Unicode span fixture
passes on Windows without changes to runtime code, Unicode positions or its
assertions. R 4.1 reports **7,710 passes**, zero failures/warnings, eight optional
textstem skips and two NOTEs (gibasa/textstem unavailable; installed size).
These permitted NOTEs are not a zero-NOTE CRAN submission.

The source/platform/installed resource audit matches all **56 members** on
Windows, macOS and Linux release; **2,018 assertions** on Windows and **2,017**
on each Unix platform. Linux also passes all inventory rejection and generated
release-record checks. The initial failed Windows run is preserved above;
no job was cancelled and no duplicate manual workflow was started.

<https://github.com/Ryuya-dot-com/ldfreq/actions/runs/37446251899> passes the
release-state classifier/aggregate with candidate artifact jobs skipped for
`development`, not a formal candidate-artifact pass. PR #21's title and body
now describe the final resources, workflows, tests, limitations and this exact
CI revision. Repository visibility, main, site deployment and CRAN remain
unchanged. The final status updates in this document and the roadmap are local
development records; they do not change package/archive contents or require a
third CI push solely to record completed checks.


## 2026-10-06 Prepare the public installation and site path

The GitHub API confirms that `Ryuya-dot-com/ldfreq` remains PRIVATE, with
`main` at `5466bb88bdb7146ec947e4c5ccd8de2b2d4ac263`. Its public Pages site uses
legacy publishing from `main` at `/`; its latest successful build is from
2026-09-22. That source has 30 exports despite the same 0.2.0 development version.
PR #21 remains draft, MERGEABLE/CLEAN, at tested revision `c788d909`.
There is no existing `gh-pages` branch. Changing Pages to an explicit generated
site branch is the proposed deployment route; it has not been performed.

README now pins the tested GitHub revision, states R >= 4.1.0 and required vs
optional dependencies, supplies local built-archive installation instructions,
and distinguishes rendered archive guides from GitHub installations that omit
them. Its first-result table uses a plain data frame to avoid a misleading
schema-unknown header after column subsetting. CONTRIBUTING now recommends
installed-package R CMD check for its complete suite: nested explicitly sourced
example files do not reliably resolve through pkgload's development shim.
No package runtime code, resource, help or measurement formula changed.

Evidence: `reviews/ldfreq-publication-path-20261006/evidence/`.

- Authenticated GitHub tarball retrieval at `c788d909` matches **all 345 tracked
  source files** byte-for-byte. Building without vignettes and installing to a
  new local library reproduces 57 exports, the README analysis (12 tokens in
  each text; TTR 0.75/0.9167, MATTR10 0.8/0.9333), NJ8 coverage, the Nation and
  MorphoLex loaders, and plotting. The source installation contains no rendered
  HTML guides. This verifies the downloaded pinned source path, not anonymous
  availability or a new complete platform test suite.
- A clean pkgdown 2.2.1 build using the previously verified installed runtime
  succeeds for the complete site. **128 HTML pages / 247 files** have no missing
  local file or fragment targets (including absolute links back into this site),
  local user paths or generated development/experiment/AGENTS pages. The public
  lifecycle/compatibility explanation remains intentional site content.
- `site/index.html` is the reviewable preview. Its upper desktop layout was
  inspected from a headless Chrome render; no clipping/overlap was observed in
  that viewport. This is not a full visual audit of all pages or breakpoints.
  CUA had no browser surface, so the installed Chrome CLI used a task-specific
  profile, which was terminated after capturing the image.
- `.nojekyll` is present in `ldfreq-site-0.2.0.zip`: **2,439,553 bytes**, SHA256
  `eaab466e8f979231ea0c686c36cc8e8d9c7f5bf4e344e562624e5c80685899d0`.
  This is a generated static-site payload, with the package source directories,
  restricted corpus files and local browser profile outside its root.
- `package/ldfreq_0.2.0.tar.gz`: **5,612,172 bytes**, SHA256
  `ebc9ced7e017f1d59b76a042e34e7a45e9c9ca6d184d115a62822dea447b4071`.
  The only changes from the prior final archive are README and DESCRIPTION
  build metadata. All **275 source files** match the checkout; **155 inst
  members**, all compiled guides, runtime R, help and resources remain identical.
  Retain the prior installed/replay and five-environment CI evidence for those
  unchanged contents; no new full numerical or resource-conversion run is needed.
- An initial site call supplied `preview` twice through pkgdown's wrapper and
  stopped before building; removing the duplicate argument resolved it. A later
  home-only update needed CRAN-link metadata network access; only that document
  stage was repeated. These are document execution issues, not package test
  failures. An audit assertion initially mistook the public LIFECYCLE page for
  the previously removed internal AGENTS page; inspecting the content and prior
  record corrected the assertion without deleting valid compatibility guidance.

The existing approval record at the annotation-evaluation entry authorizes
private branch pushes and PR updates. Making the existing repository Public
would additionally expose its development records and Git history (not just the
R archive); ask for that concrete audience change after providing these artifacts.
Main merge, Pages branch/source changes and public availability checks are the
remaining publication operations. Formal release-candidate checks and CRAN
submission remain separate. No visibility change, main merge, site deployment,
release tag or new CI push was performed during this preparation.


## 2026-10-06 Authorized public development publication

The user explicitly approved the pending request to make the existing repository
Public (including development records/history), integrate the tested development
implementation and documentation into main, and publish the prepared pkgdown site:
「素晴らしい。明示的に許可します。CRAN投稿はしないでください」.
CRAN submission is explicitly excluded. Keep repository release state at
`development`; public availability does not claim a formal CRAN-ready candidate.

The repository is now Public. Prepared static content was pushed to the new
`gh-pages` branch (commit `2094951`), and the Pages source was changed from
main/root to gh-pages/root. Live anonymous verification is recorded below once
complete. No restricted local corpus or browser-profile directory is in that
static payload. This is publication of the already-reviewed documentation.

The README now removes the private-access condition. Only the home-document
stage was rerendered. All 128 HTML pages retain valid local links and fragments;
the 247-file ZIP is 2,439,531 bytes, SHA256
`b78bc7e8911ad9309c0e6fc992782c77642ec6f30edaf8bc373411eefe35932e`.
The refreshed source archive is 5,612,146 bytes, SHA256
`22a09bf5885182f890d517dc9b831fcbb7cf6f61007b3cda7d303f450995e170`.
All 275 compared source files match the checkout. The only changes from the
c788d909 final archive are README and DESCRIPTION build metadata; all 155 inst
members and runtime/help/test contents remain unchanged. Earlier artifact hashes
above refer to the preparation snapshots before removal of the access condition.

Main protection is implemented by ruleset 19778066, not classic branch protection
(the latter API returns 404). It requires a PR and both aggregate checks. Preserve
that rule; send the accumulated documentation and publication record in one PR
update. The final-head required CI is required by that existing merge contract.
Once it passes, merge without bypass and omit only the duplicate push-triggered
CI for the identical merged tree. Do not cancel checks or relabel prior runs.
No repeated local full suite, numerical analyses, or resource transformations are
needed for this documentation-only change.


### Public publication completed

PR #21 was merged on 2026-10-06 at 11:39:34 UTC (20:39:34 JST).
Main is `bbab3ee37ded00e247b90ffaab27f1f87195ed87`; its tree
`bf8c874a49ad748ffc59b3da36df7803f0dff60d` exactly matches final PR head
`600debee01eb7931e5e874471018720f0d5aa4af`. The final head passes all nine jobs at
<https://github.com/Ryuya-dot-com/ldfreq/actions/runs/37456525303>. Windows, Mac,
Linux release/devel each pass 7,785 assertions (FAIL/WARN/SKIP 0), Status OK.
R 4.1 passes 7,710 with the same eight optional skips and two declared NOTEs.
The development classifier also passes at run 37456525339; formal candidate
artifact jobs remain intentionally skipped. Full check logs are preserved.

The existing main ruleset remains active (PR, required checks, deletion and
non-fast-forward protection). The merge uses no administrator bypass. The
merge message's skip directive prevents only a redundant push CI for the
identical tested tree; no check was cancelled or marked successful artificially.

Anonymous TLS-verified checks confirm:

- Repository and Issues return HTTP 200. The pinned c788d909 download matches all
  345 files of the previously fresh-installed source. The default-main download
  also matches all 345 tracked files of merged main.
- Pages deployment run 37456523838 succeeds for
  `2094951948b18000212f8e67f41d7a937e4ace9a`, with source gh-pages/root. All 128
  HTML pages and related served assets, 246 files total, byte-match the reviewed
  payload. `.nojekyll` is the 247th source file and is a hosting directive.
- Internal AGENTS/development/experiments site URLs return 404. This separates
  user-facing pkgdown contents from the intentionally Public repository history
  and development records; it is not a comprehensive security audit.

An initial Python 3.14 HTTPS probe lacked local CA trust. System curl succeeded
with TLS verification enabled, curlrc disabled, and no authentication/netrc; no
certificate verification was disabled. An explicit Pages build request was
needed after changing the source because the prior build still referenced main.
Only the new gh-pages deployment was requested; the package checks were not
restarted.

Evidence remains in `reviews/ldfreq-publication-path-20261006/evidence/`: final CI
and PR/Pages JSON, check logs, publication manifest, anonymous source/main
comparisons, live-site byte audit and internal-site-path responses. The final
PR description publishes the outcome and evidence links. These two local
development-record updates record completion without another documentation-only
CI push. The four prepared documentation changes are already merged.

**Repository and site publication is complete as a 0.2.0 development version.
No CRAN submission, formal release-candidate promotion or release tag was made.**


## 2026-10-06 Publish the reproducible trajectory example

The user requested adding the shared plot code to the public documentation.
Add the complete authored passage, English tokenization, 25/50/100-token plan,
base-R overlay, monochrome option and PNG/PDF export to the existing report
guide; link its plot preview directly from the homepage. Explicitly distinguish
local TTR from its mean MATTR and describe dependent overlapping windows,
complete-window endpoints and the limits of a constructed illustration.

No runtime, test, help, API, dependency or bundled-resource change is made.
Use distinct trajectory variable names so the guide's earlier two-document
analysis and saved record remain intact. Rendering the changed article and
executing the entire extracted guide succeed. Running only the three new chunks
in a fresh R process, including explicit exports and monochrome, also succeeds:
431 tokens and the full profile exactly match the prior shared illustration.
The colored site figure has been visually inspected. All 128 local HTML pages
have valid file/fragment links. Only the changed guide, home and search index
were built; other articles and prior runtime/numerical evidence were reused.

Evidence: `reviews/ldfreq-trajectory-guide-20261006/evidence/`. Submit these source
and existing publication-completion records together through the protected
main workflow, then deploy the generated changes to gh-pages and confirm
anonymous bytes and the section anchor. No CRAN submission is included.


### Trajectory guide publication completed

[PR #22](https://github.com/Ryuya-dot-com/ldfreq/pull/22) is merged at
`c9e977d9f5bbe1c5045023d4f893f5167de4a4d0`. Its complete tree equals final head
`233f895d7454468f118132126eec0510b739c338`, which passes all nine jobs in
[run 37467395411](https://github.com/Ryuya-dot-com/ldfreq/actions/runs/37467395411).
The development classifier also passes at run 37467395234, with formal candidate
artifact jobs intentionally skipped. The two public source documents match
anonymous raw-main downloads.

The initial fa9acc2 head passed all nine jobs at run 37463936813. A final one-line
link repair uses an absolute installation URL so that opening the installed
vignette does not depend on the website directory layout. The first CI run was
allowed to finish before pushing that repair; only the local automatic-merge
monitor was stopped, not a GitHub job. Required checks were not bypassed, and
only the redundant identical-tree main push CI was omitted. No local numerical
rerun or full local package check was needed for the URL-only correction.

The public site serves gh-pages `c096d1cad3de7d424b70563cb57200f485d84323`. All
eight changed files match the prepared payload anonymously: home/article HTML,
the trajectory PNG, home/article/contribution Markdown, search index and llms
index. Markdown generation also synchronizes previously stale contribution and
installation text with the already-updated HTML. A text-presence assertion first
failed on ordinary Markdown line wrapping; normalizing whitespace resolved the
check without changing content. The site has 128 HTML pages and 248 files.

The public desktop homepage was rendered and visually inspected: the plot and
its direct guide link are visible without overlap or clipping. The section
anchor is `#plot-local-vocabulary-diversity`. The full-guide execution, independent
copy/paste execution with exports and monochrome, exact original-profile match,
local link audit, live byte audit, screenshot and final CI/PR/Pages records are in
`reviews/ldfreq-trajectory-guide-20261006/evidence/`. `publication-result.json`
identifies the final source and site commits.

## 2026-10-07 Executable local-file input tutorial

Implemented roadmap A: one TXT, an explicitly mapped folder, and ID/text CSV
input converge on the existing batch analysis. The tutorial retains empty
documents, joins deliberately reordered writer/task metadata by document ID,
shows the original MATTR values as points, and saves the complete record beside
an inspection CSV. The new section is linked from the report and getting-started
guides. Authored teaching files, including Japanese UTF-8 text, are under
`inst/examples/text-input/`; no real corpus or reference resource is added.

`inst/examples/text-file-input.R` is a sourced helper, not a new export. Its
explicit UTF-8/CP932 decoding preserves line endings and final newlines, records
a removed leading UTF-8 BOM, hashes source bytes separately from decoded text,
and rejects failed/lossy decoding, NUL and files over the declared byte limit.
The corpus remains an ordinary ID/text data frame; existing batch validation
handles identities and missing text. No R/ runtime file, namespace, metric,
required dependency or bundled reference data changed.

The old open PR #16 was read before implementation. Its two public APIs and new
corpus class target 0.1.0.9000 and are not merged into this narrower teaching
change. Its explicit-byte approach and the current NINJAL input example informed
the small reader. PR #16 remains untouched; this is not a blanket rejection of
that independent API proposal.

Mac installed-package evidence: all 55 targeted assertions pass, covering exact
UTF-8 and CP932 strings, CRLF/LF/final-newline/empty/BOM handling, a Japanese
filename, lossy/invalid input rejection, special CSV strings and quoted multiline
fields, metadata IDs, empty-document results and saving. All seven new tutorial
chunks execute independently in a fresh R process. Full extracted execution of
english-tokenization, from-text-to-report and getting-started also succeeds.
Fresh-session reaggregation exactly matches the saved result; color/monochrome
plots return identical selected rows, and all 57 public exports remain present.

The three changed articles render successfully. NEWS generation initially
fails because the sandbox cannot resolve the public CRAN metadata endpoint;
resuming NEWS/search/Markdown with network access completes without rebuilding
the successful articles or rerunning numerical analyses. Local site links and
private-path checks pass. Full prior runtime/resource evidence is reused;
cross-platform CI and final publication are pending at this record point.

Evidence: `reviews/ldfreq-file-input-20261007/evidence/`, including installation,
targeted tests, standalone/extracted guide scripts, fresh-session RDS,
generated site and audit. Update the documentation's installation pin to the
new implementation commit so installed sample files match the online guide;
the older c788d909 snapshot does not contain these teaching files. Submit the
complete change once through the protected main workflow, then verify the live
article and source bytes. No CRAN submission is authorized or performed.

These local completion-record updates do not trigger another documentation-only
CI cycle; the public PR description contains the result and evidence links.
No runtime/API/dependency/resource change, new release tag or CRAN submission.

## 2026-10-07 Thirty-document plot follow-up

The user's requested expansion replaces the two computable examples with 30
constructed English documents (107–149 tokens) and retains one empty document.
All plotted values use the same 50-token MATTR window. Six authored topic
passages and five endings, with varied repetition, are explicitly teaching
material rather than independent learner observations. The 8-by-4-inch point
plot uses vertical document labels, color by default, optional monochrome, and
no embedded title. Metadata, CSV input, saved output and empty-document examples
use the same 31 IDs.

All 58 focused assertions pass. The seven standalone tutorial chunks and full
English guide execute with the updated installed samples; unchanged report and
getting-started execution evidence is retained from the preceding check. In a
fresh R session, reaggregation exactly matches the saved result. Independently
computed Python token counts and all 30 MATTR values agree (maximum absolute
error 1.11e-16); color and monochrome return the same 30 rows. The empty document
retains two missing/empty_input rows, not zero scores. There are still 57 exports.

Initial PR CI at f88c0a5 reports a Windows vignette failure in the TXT/CSV equality
assertion, before package tests. Git checkout newline conversion and read.csv's
CRLF-to-LF parsing inside quoted fields make cross-format source strings differ.
The exact-byte teaching files are now marked -text in .gitattributes, preserving
their committed LF bytes on Windows. The tutorial explains CSV parsing separately
from decoding; a focused check confirms its CRLF behavior. The text reader keeps
original TXT line endings. This is an input-fixture/document-build correction,
not a change to metric arithmetic. Final-head CI and live publication remain
pending at this record point.

## 2026-10-07 File-input tutorial publication completed

Final source head `da26692ba169d4122fd50babf180c9eb7964e9e4` passes all nine
R-CMD-check jobs in run 37549222144 and both required status checks. Windows,
macOS, Linux release and Linux devel each report 7,843 passing assertions, no
failures/warnings/skips, and Status: OK. R 4.1 reports 7,768 passing assertions,
eight optional-dependency skips and two NOTEs (unavailable suggested gibasa/
textstem and installed size); it is not a zero-NOTE check. The development-state
classifier passes; formal release-candidate artifact jobs are intentionally
skipped. Initial run 37546762328 completed without cancellation; only its
Windows vignette failure and dependent required gate failed. The final run
confirms the newline fixture correction on Windows.

PR #23 merged through the existing protections to main
`9dda4de4ebe42c18cfc2e1a9f3f6ecfd4c08e8ab`. Main and the tested PR have identical
tree `00dee4ea84a85f7b45f0b6c5771697c049075d20`. The merge subject skips only the
redundant same-tree push CI. The documented installation snapshot
`d2568c9d8d0bfa3955bba31cd53bbff8d0f751b3` differs from the tested head only in
README's pin. A fresh pak installation from GitHub succeeds; all 36 teaching
files match source bytes and the seven tutorial chunks execute with 30 finite
MATTR results and the retained empty document. No existing user library was
replaced.

GitHub Pages commit `5207ae1909034e4e01c55c27250f94434f66ce42` deploys successfully
in run 37550485845. All 13 changed public files, including the 30-point PNG,
English guide, installation pin, companion Markdown and search index, match
the reviewed files byte-for-byte through anonymous requests. The 128-page local
link audit passes; the prepared site contains 249 files. A live browser rendering
confirms all 30 IDs are readable, with no embedded title. Python's local TLS
trust-store configuration initially prevented HTTP verification; using the macOS
standard curl with certificate verification completes the same audit. No site
change or certificate-verification bypass was needed.

Evidence remains in `reviews/ldfreq-file-input-20261007/evidence/`: final CI and
R 4.1 logs, merge identity, GitHub installation/file comparison, independent
MATTR check, Pages records, live-file hashes and screenshot. Completion-only
roadmap/evidence edits remain local to avoid another unchanged CI cycle; the
merged public PR description records these final results. No CRAN submission,
release tag or change to runtime APIs, dependencies or reference data.

## 2026-10-07 Decision worksheet workflow and local corpus pilot

The ambiguity guide now supplies six independently executable chunks covering
reference context/candidate CSVs, a worksheet with four editable decision fields,
strict UTF-8 reading through the already installed file-input example, complete
row/fixed-field checks, explicit submission, document status counts and full RDS
saving. The recipe is defined in the guide, not a new export or installed helper.
It permits sorting but rejects missing/duplicate/changed identities and partly
filled unsubmitted rows; existing API validation checks candidate membership and
the source snapshot. It explains full-set replacement, resuming prior decisions,
clearing a decision, and the distinction from lemma/POS or source-text correction.
The report guide links to this workflow; NEWS is updated.

On the existing documented d2568c9 installation, all 29 focused worksheet checks
pass. These exercise independent expected state counts, sorting and column
reordering, malformed IDs/columns/rows, partial rows, invalid or missing choices,
missing/blank decision fields, leading-zero candidates, literal NA/TRUE, Unicode
reasons, resuming/clearing decisions and a header-only zero-occurrence worksheet.
Both changed guides render; the six-chunk standalone and fresh-session complete
RDS replay pass. No R/, NAMESPACE, help, dependencies or reference data changed;
prior runtime/resource evidence is retained.

The same reader is applied locally to saved ICNALE GRA V2.1 MorphyNet reviews.
Four purposively inspected occurrences receive two selected and two unresolved
Codex-assisted decisions. A declared spelling-consistency criterion selects two
recorded suffix relations; competing N/V -ing labels remain unresolved rather
than repairing the learner text or inventing a definitive annotation convention.
All 140 documents and 31,902 occurrences, family identities, candidate counts and
unchanged MorphoLex review are retained. The final state counts are 2 selected,
2 unresolved, 4,588 unreviewed and 27,310 without candidates. Two selected suffix
relations are counted; this is not a corpus-wide productivity or accuracy claim.
Source text, context and individual judgments remain in the local
analysis/icnale-gra/results/review-worksheet-pilot/ directory. Fresh-session
replay reproduces the complete reviewed object. This is a pilot of operation and
accounting, not an independent human reference, inter-rater reliability or a
representative validation sample.

Evidence: reviews/ldfreq-review-worksheet-20261007/evidence/. The public guide
contains only authored sentences and candidates. Local checks and page rendering
are complete; protected main integration and live publication are pending at
this record point. CRAN submission remains outside scope.

## 2026-10-07 Decision worksheet publication completed

Final source head `1c4e81e59a3a715005c19b8024e82daf53517d0b` passes all nine
R-CMD-check jobs in run 37556206419 and both protected required checks. Windows,
macOS, Linux release and Linux devel each report 7,843 passing assertions, no
failures/warnings/skips, and Status: OK. R 4.1 reports 7,768 passing assertions,
eight optional-dependency skips and two NOTEs (unavailable suggested gibasa/
textstem and installed size). The development-state classifier passes in run
37556206329; formal release-candidate artifact jobs are intentionally skipped.
These results do not represent a formal release-candidate artifact check.

PR #24 merged through the existing protections to main
`741e74acc82437fb025da133b96c77fec160b89d`. Main and the tested PR have identical
tree `4ecef135eb38c1b41505892eb95f81e5338e60e5`. The merge subject skips only the
redundant same-tree push CI. No CI cancellation, protection bypass, release tag
or CRAN submission occurred. The documented d2568c9 installation pin remains
applicable: runtime, installed examples, dependencies and reference data are
unchanged, and the new inline recipe was verified with that installed snapshot.
Three public source documents retrieved anonymously match the tested head.

GitHub Pages commit `17a8ebbd8bba28e033df4d5a736312cddbe6bae8` deploys successfully
in run 37558099317. All seven changed public files match the verified local
artifacts byte-for-byte through anonymous requests with certificate verification.
The local link audit covers 128 HTML pages in the 249-file site. Live browser
inspection confirms the new section, object-role table and four-state document
summary are readable. The zero-target and empty documents remain in the table
with an undefined reviewed proportion rather than a zero proportion.

Evidence is in `reviews/ldfreq-review-worksheet-20261007/evidence/`: final CI,
classification and R 4.1 records, merge identity, anonymous source hashes, Pages
records, live-file hashes and live browser screenshots. The 29 focused checks,
fresh-session replay and limited local ICNALE pilot are described above; no
independent linguistic accuracy claim follows from these operation checks.
Completion-only roadmap/evidence edits remain local to avoid another unchanged
CI cycle. The merged PR description records the final publication results.

## 2026-10-07 Standalone word-family and affix tutorial

The new word-families-and-affixes guide follows research questions through
shared-occurrence type counts, coverage, root/prefix/suffix and process labels,
reference scope, occurrence-specific CSV decisions and complete saving. It
reuses installed recipes and public APIs without changing runtime, dependencies
or reference data. New sentences and judgments are explicitly authored;
MorphyNet relation selection is a reporting convention, not a uniquely proven
derivation. The empty source document and unlisted occurrences are retained.
Home, article navigation and the detailed preprocessing guide link to it.

On the existing documented d2568c9 installation, extracted runnable chunks
execute and 24 independent expected-accounting/replay checks pass. The supplied
CSV-input recipe retains the empty document and rejects a fractional token
index rather than truncating it. A separate
R session regenerates family comparisons, authored part counts and the complete
linked review identically. There are still 57 exports. Initial purl extraction
could not evaluate a chunk option defined in a preceding chunk; supplying its
extraction environment included all review chunks, which then executed and
were verified. This was an extraction setup issue, not a successful review
check to count before the correction.

The new navigation required one site-wide render. All 129 HTML pages pass the
local link audit; the new article's counts and affix tables have been inspected
in the browser. Shorter table headings improve readability without changing
the arithmetic. Evidence is under reviews/ldfreq-families-tutorial-20261007/evidence/.
Final-head protected checks, main merge and actual public-site verification
remain pending at this record point. CRAN submission is excluded.
