# Release-candidate evidence tools

These repository-only tools generate and verify evidence for the immutable
`ldfreq` source tarball used by the `Release candidate` GitHub Actions workflow.
They are excluded from the R source package by `.Rbuildignore`.

`generate-release-evidence.R` requires a clean checkout and writes a package
BOM, SPDX dependency SBOM, resource BOM, and release-provenance record. The
archive and PDF manual must already exist.

```sh
Rscript experiments/release-candidate/generate-release-evidence.R \
  /path/to/ldfreq /path/to/ldfreq_0.1.0.tar.gz \
  /path/to/ldfreq_0.1.0.pdf /new/evidence-directory
```

`run-as-cran-check.R` runs `R CMD check --as-cran --no-manual` against one
named tarball. By default, it accepts `Status: OK` or the exact single CRAN
incoming NOTE whose complete nonblank detail is the maintainer line followed by
`New submission`. The optional `minimum-r-optional-textstem` policy is restricted
to the `ubuntu-latest-r-4.1` job on R 4.1.x. It additionally requires the exact
package-dependency NOTE naming unavailable Suggests package `textstem`; every
other result fails. The workflow leaves `textstem` uninstalled in that one job,
sets `_R_CHECK_FORCE_SUGGESTS_=false`, and verifies that the package remains
checkable without this optional backend.

```sh
Rscript experiments/release-candidate/run-as-cran-check.R \
  /path/to/ldfreq_0.1.0.tar.gz /new/check-directory job-label \
  new-submission-only
```

`assemble-run-index.R` verifies the five platform/R result records, the three
current-R source/platform/installed resource-inventory records, and their exact
source-artifact identity before writing a single run index. It also binds job
labels to their recorded OS/R environments and rechecks every source, manual,
BOM, SBOM, and resource-BOM identity named by provenance. It deliberately leaves
the final maintainer go/no-go decision pending after recording resource
admission.
