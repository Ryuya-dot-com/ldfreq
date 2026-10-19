# Release-candidate evidence tools

These repository-only tools generate and verify evidence for the immutable
`ldfreq` source tarball used by the `Release candidate` GitHub Actions workflow.
They are excluded from the R source package by `.Rbuildignore`.

The current [state.dcf](state.dcf) identifies a development version; published
development snapshots do not use this formal-candidate artifact workflow.
Ordinary pull-request checks still exercise the development matrix. A formal
candidate requires a separately selected three-component version, an exact
commit and anonymously reachable metadata URLs. Public URLs alone do not
justify changing the classification. CRAN submission is outside the current
project scope; the `--as-cran` command below performs checks, not submission.
A private-repository 404 is not an allowed incoming NOTE and must not be hidden
by weakening the strict result policy.
The classifier accepts only `development` and `release-candidate`; a mismatched
record scope, package, version, or any other status fails the workflow rather
than falling back to a non-candidate result.

`generate-release-evidence.R` requires a clean checkout and writes a package
BOM, SPDX dependency SBOM, resource BOM, and release-provenance record. The
archive and PDF manual must already exist.

The SPDX root uses a LicenseRef with the source LICENSE text, preserving the
component-specific terms instead of labeling the complete collection MIT.
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
named tarball. By default, it accepts `Status: OK` or the exact single CRAN
incoming NOTE whose complete nonblank detail is the maintainer line followed by
`New submission`. The optional `minimum-r-optional-backends` policy is restricted
to the `ubuntu-latest-r-4.1` job on R 4.1.x. It additionally requires the exact
package-dependency NOTE naming exactly `gibasa` and `textstem`; every
other result fails. Their current versions need R >= 4.2 and R >= 4.4,
respectively. The workflow leaves both uninstalled in that one job,
sets `_R_CHECK_FORCE_SUGGESTS_=false`, and verifies that the package remains
checkable without these optional backends.

```sh
Rscript experiments/release-candidate/run-as-cran-check.R \
  /path/to/ldfreq_VERSION.tar.gz /new/check-directory job-label \
  new-submission-only
```

`assemble-run-index.R` verifies the five platform/R result records, the three
current-R source/platform/installed resource-inventory records, and their exact
source-artifact identity before writing a single run index. It also binds job
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
