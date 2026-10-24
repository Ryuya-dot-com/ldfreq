# Release-candidate evidence tools

These repository-only tools generate and verify evidence for the immutable
`ldfreq` source tarball used by the `Release candidate` GitHub Actions workflow.
They are excluded from the R source package by `.Rbuildignore`.

The current [state.dcf](state.dcf) identifies the development snapshot.
Published development snapshots do not use this artifact workflow.
Ordinary pull-request checks still exercise the development matrix. A formal
candidate requires a separately selected three-component version, an exact
commit and anonymously reachable metadata URLs. Public URLs alone do not
justify changing the classification. CRAN submission is outside the current
project scope; the `--as-cran` command below performs checks, not submission.
A private-repository 404 is not an allowed incoming NOTE and must not be hidden
by weakening the strict result policy.
The [release-scope guide](../../vignettes/release-scope.Rmd) defines the current
compatibility boundary. The exact PR-head artifact is checked once; merging
the same tree does not start another artifact build. A deliberate environment
recheck can use workflow dispatch. The build signs the source, manual and
machine-readable evidence with GitHub build-provenance attestations and retains
the Sigstore bundle beside the archive, including when a later check fails.

A completed archive can be retained after an evidence or manual failure. The
optional `Source-Archive-*` fields in `state.dcf` bind its original Actions run,
commit and SHA-256. `verify-reuse.py` rejects package-source changes and records
the excluded changes in `source-reuse.json`, which is signed with the assets.
`Validation-Run` and `Validation-Commit` separately identify completed ordinary
numerical CI. Reuse requires unchanged numerical job definitions, runtime code,
resources and tests. The verifier permits only named release-control and
documentation repairs. Changed controls, API documentation and the PDF manual
are checked afresh, and all five exact-archive checks remain required. Remove
`Source-Archive-*` whenever package content changes: numerical-evidence reuse
does not permit reuse of an archive containing superseded documentation.

`build-manual.R` uses R's documented `texi2dvi` emulation, retains TeX diagnostics,
and requires a nonempty function index. A PDF returned by the no-index fallback
is rejected. Both manual jobs explicitly install TeX Live's `makeindex`, refresh
its executable links and check that it is on `PATH` before compiling the manual.
The public-content scanner permits only the exact existing
API descriptions in README, NEWS and the contextual-model guide (source and
installed copy); unknown workflow text and local paths fail
with a file/line diagnostic.

The classifier accepts only `development` and `release-candidate`; a mismatched
record scope, package, version, or any other status fails the workflow rather
than falling back to a non-candidate result.

`generate-release-evidence.R` requires a clean checkout and writes a package
BOM, SPDX dependency SBOM, resource BOM, and release-provenance record. The
archive and PDF manual must already exist.
The evidence environment explicitly includes cpp11, progress and RcppEigen:
binary dependency installation can omit these transitive LinkingTo packages,
but the SBOM records the complete installed hard/build dependency closure.

The SPDX root records MIT code and the BSD-3-Clause tokenizer example.
Optional reference datasets are distributed separately with their own terms.
The resource BOM embeds both the installed manifest and repository admission
inventory. The run index compares resource IDs and counts against this exact
BOM, not a historical hard-coded count.

```sh
Rscript experiments/release-candidate/generate-release-evidence.R \
  /path/to/ldfreq /path/to/ldfreq_VERSION.tar.gz \
  /path/to/ldfreq_VERSION.pdf /new/evidence-directory
```

Replace `VERSION` with the selected candidate's actual DESCRIPTION version;
the example does not select a future release version.

`run-as-cran-check.R` runs `R CMD check --as-cran --no-manual` against one
named tarball. The default `new-submission-only` policy remains strict. The
workflow selects `release-resource-notes`: `Status: OK`, or individually
recognized NOTES for CRAN's `New submission` (with only the exact optional
`Non-FOSS package license (file LICENSE)` line) and installed package size.
The non-FOSS disposition preserves the declared component terms, including
MorphoLex's CC BY-NC-SA restriction; it does not grant any extra rights.
The latter must list only R/doc/extdata, include doc and extdata, and total
at most 15 MiB (the 9019 Linux baseline was 10.9 MiB). The attributed resources
and rendered guides explain that size; the exact file BOM and independent
resource inventories still have to pass. Unexpected payload areas, duplicate
notes, size growth beyond that bound, warnings and errors remain blocking.

The `minimum-r-optional-backends` policy is restricted to the
`ubuntu-latest-r-4.1` job on R 4.1.x. It also requires the exact dependency NOTE
naming `gibasa` and `textstem`; no other unavailable package is accepted.
Their current versions need R >= 4.2 and R >= 4.4,
respectively. The workflow leaves both uninstalled in that one job,
sets `_R_CHECK_FORCE_SUGGESTS_=false`, and verifies that the package remains
checkable without these optional backends.

R 4.1's older URL checker receives publisher bot-blocking responses on
references successfully checked with current/devel R. Only that minimum-R
diagnostic sets `_R_CHECK_CRAN_INCOMING_SKIP_URL_CHECKS_IF_REMOTE_=true`:
it still performs incoming metadata, installation, examples, tests and
vignettes checks. Current R on all three platforms and R-devel retain online
URL checks on the same archive. DESCRIPTION DOI checking is controlled
separately by R and remains enabled. Check-result schema 1.2.0 records this
scope, and both the runner and aggregator reject an altered or missing scope.
The earlier HTTP failures remain in the superseded candidate's raw logs;
they are not reclassified as successful URL checks.

```sh
Rscript experiments/release-candidate/run-as-cran-check.R \
  /path/to/ldfreq_VERSION.tar.gz /new/check-directory job-label \
  release-resource-notes
```

`assemble-run-index.R` verifies the five platform/R result records, the three
current-R source/platform/installed resource-inventory records, and their exact
source-artifact identity before writing a single run index. It reclassifies
each raw check log and requires exact agreement with the saved result and
dispositions, using the same fail-closed policy as the runner. It also binds job
labels to their recorded OS/R environments and rechecks every source, manual,
BOM, SBOM, and resource-BOM identity named by provenance. It deliberately leaves
the final maintainer go/no-go decision pending after recording resource
admission.

For the R 4.1 diagnostic, CI pins compatible `Matrix@1.6-5`, `MASS@7.3-60`
and `readxl@1.4.5`. The current readxl requires R >= 4.2; its 1.4.5 release
declares R >= 3.6 and retains the workbook reader on the minimum supported R.
Matrix is needed by
quanteda (>= 1.5-0 Matrix). Current Matrix releases require newer R; the archived
1.6-5 DESCRIPTION declares R >= 3.5.0. Current-R jobs use their normal dependency
resolution. This is a CI compatibility pin, not a package runtime dependency.

The R 4.1 dependency setup includes Depends, Imports, LinkingTo and Suggests,
but excludes third-party Enhances (notably the archived Matrix graph extension).
ldfreq declares no Enhances. Its full check dependencies remain included except
for the two documented R-incompatible optional backends.

### Recorded external responses for the 0.4.0 archive

All five checks of archive SHA-256
`c720ad309683a321ee11b61910a63b914a71c444ca67d8a7cd1288504176f921`
completed examples, tests and vignette rebuilding successfully. Three incoming
responses need a narrow disposition, not another numerical run:

- R 4.1: HTTP 403 for DESCRIPTION DOI `10.1080/09296171003643098`.
  The [publisher's record](https://www.tandfonline.com/doi/full/10.1080/09296171003643098)
  identifies Covington and McFall's *Cutting the Gordian Knot* (2010),
  Journal of Quantitative Linguistics 17(2), 94–100. Other current-R jobs
  accepted the reference; this does not claim R 4.1 accessed the article.
- R-devel: the [author's L2SCA page](https://sites.psu.edu/xxl13/l2sca/) timed
  out. It passed the same-archive Linux/macOS checks and an independent R URL
  probe during candidate review.
- Windows: the [provider's LOCNESS page](https://uclouvain.be/en/research-institutes/ilc/cecl/locness)
  could not be connected to. The provider page was inspected and the same
  reference passed the Linux/macOS checks of this archive.

`check-note-policy.R` recognizes only these exact job/URL/source/status/detail
combinations, including the recorded archive size for the DOI case. Altered
URLs, other HTTP responses and additional lines fail. The raw failed responses
remain unchanged; they are not reported as successful access by those runners.

`Check-Evidence-Run` reuses the completed raw check records from the declared
source-archive run. Its source commit and completed workflow identity are
verified first. Each platform checks archive bytes, OS, R version, command,
recorded scope and completed example/test/vignette stages before reclassifying
the raw log. Original result JSON, its hash and original dates are retained.
The run index verifies them again. Existing resource inventories are reused;
a missing platform inventory is still run. `Reuse-Manual: true` requires the
original manual hash and a nonempty index. This combines recorded stages and
does not claim that all numerical checks were rerun in the final workflow.
An R-devel snapshot used only to classify the stored log may differ from the
snapshot that executed the original check. The original execution version is
retained in `environment`; `reused_check.classification_environment` records
the classification host separately. This does not establish runtime behavior
on the classification host's snapshot.
