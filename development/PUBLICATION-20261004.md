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
