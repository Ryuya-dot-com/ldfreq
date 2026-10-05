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
