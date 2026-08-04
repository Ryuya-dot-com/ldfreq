# Core release-candidate boundary

Version `0.1.0` is a release candidate, not a published release. The candidate
is acceptable for tagging only after one immutable commit on protected `main`
has passed the technical and human gates in `RELEASE-CHECKLIST.md`.

## Automated evidence

The `Release candidate` workflow builds one source tarball and checks that exact
artifact on current R for Linux, macOS, and Windows, on R-devel for Linux, and
on the declared R 4.1 minimum. It also builds the PDF reference manual and
generates:

- a file-level package BOM;
- an SPDX 2.3 dependency SBOM;
- a resource BOM derived from the installed resource inventory;
- release provenance bound to the repository commit, tree, archive, manual,
  environment, and evidence hashes;
- per-platform `R CMD check --as-cran --no-manual` logs and result records; and
- a run index that fails unless every matrix job examined the same tarball.

These outputs are technical evidence. A workflow defined by the candidate
cannot independently approve itself, and expiring Actions artifacts are not the
durable archive required for publication.

CRAN incoming checks report `New submission` until the package has a prior CRAN
version. The check runner accepts only that exact single NOTE as explained; any
additional NOTE, WARNING, ERROR, or unrecognized status remains blocking.

## Go/no-go boundary

The final decision record must name the reviewer, date, candidate commit and
tree, tarball name and SHA-256, known limitations, and rollback action. It must
also preserve the workflow definition, logs, and hashes outside expiring CI
storage.

The current TUBELEX unit remains a non-exported development candidate. Its
inventory reports zero release-approved resources; no TUBELEX public API or
resource admission is implied by a core-package release decision.

Rollback before publication means closing or reverting the candidate change and
creating no tag or release asset. Rollback after publication means documenting
the defect, withdrawing the affected asset where the hosting service permits,
and preparing a reviewed patch release without rewriting an existing tag.
