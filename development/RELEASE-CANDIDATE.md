# ldfreq 0.2.0 publication boundary

Version `0.2.0` is under development toward an initial CRAN submission. It consolidates the core,
preprocessing, lexical-overlap, many-document reference-coverage, lexical-level,
TUBELEX, formula-variant, correction, test, documentation, and canonical naming
work completed before the first CRAN submission. No earlier package version is
treated as a CRAN compatibility baseline. The exact candidate commit must pass
the technical, resource, and maintainer decision gates in
`RELEASE-CHECKLIST.md` before the release tag is finalized, assets are
published, or the package is submitted to CRAN.

The repository is currently in development state, not an exact release-
candidate state. The GitHub repository and issue URLs in `DESCRIPTION` must be
anonymously reachable before `experiments/release-candidate/state.dcf` is
changed to `Status: release-candidate`. Until then, ordinary pull-request CI is
valid development evidence, but an incoming-check 404 caused by repository
privacy remains a release blocker rather than an accepted exception.

## Automated evidence

The `Release candidate` workflow builds one source tarball and checks that exact
artifact on current R for Linux, macOS, and Windows, on R-devel for Linux, and
on the declared R 4.1 minimum. It also builds the PDF reference manual and
generates:

- a file-level package BOM;
- an SPDX 2.3 dependency SBOM for the release-R build-source environment,
  including the declared R constraint (the five check environments remain in
  their separate logs and result records);
- a resource BOM derived from the installed resource manifest;
- release provenance bound to the repository commit, tree, archive, manual,
  environment, and evidence hashes;
- per-platform `R CMD check --as-cran --no-manual` logs and result records; and
- a run index that fails unless every matrix job examined the same tarball and
  all three current-R resource-inventory audits succeeded.

These outputs are technical evidence. A workflow result is not the maintainer's
final release decision, and expiring Actions artifacts are not the durable
archive required for publication.

The state classifier is fail-closed: only `development` and
`release-candidate` are recognized, and the record scope, package, and version
must agree with `DESCRIPTION`. Ordinary development CI runs the public-API
integration audit even when exact-candidate artifact jobs are correctly
skipped.

Additional automated or third-party analyses are useful quality-control layers,
but they do not replace upstream rights or the maintainer's accountability for
the release decision.

CRAN incoming checks report `New submission` until the package has a prior CRAN
version. The check runner accepts only that exact single NOTE by default. The
declared minimum-R diagnostic intentionally leaves the optional `textstem`
backend unavailable and sets `_R_CHECK_FORCE_SUGGESTS_=false`; only its exact
package-dependency NOTE is additionally accepted, only for the labeled R 4.1
job, and both dispositions are recorded. Any other NOTE, WARNING, ERROR, or
unrecognized status remains blocking.

## Go/no-go boundary

The final decision record must name the maintainer, date, candidate commit and
tree, tarball name and SHA-256, known limitations, and rollback action. It must
also preserve the workflow definition, logs, and hashes outside expiring CI
storage.

The TUBELEX unit and exported profile are maintainer-approved in a
repository-only admission record. That record documents the pinned
BSD-3-Clause and README basis, approved scopes, absence of raw subtitle
material, installed notice, and the fact that no independent legal opinion was
obtained. The final exact source, installed, and binary inventory must reproduce
this boundary.

The New JACET 8000 level-profile API uses an attributed, permitted bundled
rank/entry table by default and still accepts explicit external copies. The
candidate must preserve the installed NJ8 notice, source/correction provenance,
all 8,000 verified ranks, and default/external resource identity.

The caller-supplied AntBNC flemma adapter remains code-only: no AntBNC payload
may enter package artifacts. Review must verify identity fallback, explicit
override precedence, path-private provenance, and the documented distinction
between raw AntBNC approximation and NWLC's manually aligned mapping.

Rollback before publication means closing or reverting the candidate change
without publishing an `ldfreq` CRAN release. After publication, rollback means
documenting the defect, withdrawing an affected asset where the hosting service
permits, and preparing a reviewed follow-up patch release. Published tags
remain immutable.
