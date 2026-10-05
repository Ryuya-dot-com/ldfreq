# NJ8 diagnostics and literature-informed roadmap

This change adds one exported, read-only aggregation API, `nj8_diagnostics()`.
It consumes an existing single or batch profile and reports unmatched-key
frequencies, document frequencies, surface/unit/lookup mappings, and descriptive
transformation flags. Coverage, exclusions, source citations and preprocessing
provenance remain available. No resource bytes, tokenizer rules, annotation
backend or metric formulas change. The guide uses authored inputs; no ICNALE
text, individual rating or Zotero attachment is bundled.

## Local evidence

Evidence directory in the shared workspace:
`reviews/ldfreq-roadmap-20261004/evidence/`.

- `build.log`: source archive, including all seven vignettes, built successfully.
- `check-console.log` and `ldfreq.Rcheck/00check.log`: full
  `R CMD check --no-manual`, Status OK. All five test scripts completed.
- `ldfreq.Rcheck/tests/testthat.Rout`: 4,673 assertions; no failures, warnings
  or skips. The preceding source baseline had 4,410 assertions.
- `public-api.log`: 33 exports, 30 S3 methods and 16 help topics, with the
  namespace, help, examples, API inventory and pkgdown reference in agreement.
- `icnale-diagnostics.log`: the saved corpus profiles reproduce independently
  tabulated occurrence/document counts for 931 surface and 272 lemma unmatched
  keys across 140 original essays; all 57 numeric-introducing mappings detected.
  This reuses completed corpus calculations and is not a new empirical study.
- Source archive SHA-256:
  `ce99531b97cff71de099a0bfc23025de2ac6410e1715fca7dd4f8ff9e90db76e`.
  At the initial NJ8 implementation checkpoint, runtime source, tests, help,
  new vignette, namespace, NEWS and README were compared byte-for-byte with
  that archive. The subsequent documentation-only update below changes the
  vignette and NEWS; the archive is retained as evidence for the runtime.

## Documentation build and recovery

The initial pkgdown run stopped on sandboxed cache/network access. Cache paths
were moved inside the workspace and public metadata access was enabled for the
build. Home and reference generation then completed. Article subprocesses
needed an installed package, so subsequent stages used the library already
installed by the successful R CMD check. Articles and tutorials completed;
NEWS required another public metadata endpoint. The build resumed at NEWS,
then completed sitemap, LLM documents, redirects and search. The final checker
was called via its actual internal pkgdown entry point after correcting an
incorrect exported-function call.

Successful phases were retained; no package tests or corpus calculations were
rerun to resolve these documentation-environment issues. Completion evidence is
spread across `pkgdown-final.log`, `pkgdown-resume.log`, `pkgdown-closeout.log`
and `pkgdown-site-check.log`, not a single successful full-site invocation.
All 86 generated HTML pages have existing local href/src targets. The new
article and function reference contain the documented API and diagnostic
fields. Whole-site visual browser inspection is not claimed.

## Research and release boundaries

`ROADMAP.md` records the updated priorities, literature interpretation,
implementation dependencies, user workflows and empirical completion criteria.
Eight Zotero metadata/abstract records were inspected; no attachments were
retrieved and no library records changed. The targeted search is not a
systematic full-text review. Search records are in `zotero-search.json`.

This is a local, uncommitted development change based on the existing
`prepare/publication-nj8-20261004` branch. Earlier cross-platform CI supports
the preceding source baseline; it is not asserted as evidence for this new
export. No push, merge, repository-visibility change, release or CRAN submission
is included in this work. Resource-build evidence remains applicable because
the resource payloads, source builders and notices are unchanged.

## Follow-up: recently added Zotero records

The three latest relevant records (8MU4UT3N, WU3ZJ43M, 5L5MEMLR) have the same
DOIs as Caltabellotta et al. (2026) and Bestgen (2024, 2025) in the initial
review. They are not counted as additional independent studies. Metadata and
abstracts were checked, with no attachment retrieval or library mutation.
The item-key mapping and access scope are saved in `zotero-added-records.json`.
Publisher information identifies specific Bestgen (2024) appendices to inspect
before fixing a replication protocol; their contents have not been reviewed.

The roadmap now breaks M1 into document-aligned condition comparisons,
annotation-condition recording, length/position designs, and an evaluation of
whether a dedicated wrapper is needed. The existing guide adds executable
surface/lemma-by-window comparisons and a fixed-frequency position example.
No new runtime API or numerical formula is introduced in this follow-up.

`verify-literature-update.R` and `literature-update.log` verify the new guide:

- All 12 condition/document rows and all three IDs remain, including eight
  uncomputable rows with their status/reason.
- Moving a unique token changes MATTR from 2/5 to 8/15 while TTR remains 2/7
  and HD-D remains 10/21; window-exposure counts match independent arithmetic.
- The complete prepared/condition/result bundle survives an RDS round trip.
- The vignette, pkgdown article and roadmap HTML render successfully.

`literature-runtime-identity.txt` confirms that all 119 runtime, test, help,
resource and namespace files are byte-identical to the checked archive.
Build-generated `inst/doc` and DESCRIPTION metadata are excluded from this
source comparison. The prior 4,673-assertion runtime evidence is reused; it
is not presented as a new full-package check of the documentation update.
The prior source archive has not been replaced.

NEWS generation required the same public CRAN metadata access as before;
the network-blocked attempt is in `literature-site.log`, and the resumed
NEWS/search/sitemap/LLM-document generation and final site check are in
`literature-site-complete.log`. Numerical tests and corpus analyses were not
rerun for this documentation-environment issue. Publication remains pending.
