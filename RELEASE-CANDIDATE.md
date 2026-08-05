# Superseded core release-candidate boundary

The immutable core-only version `0.1.0` candidate was not published. Development
version `0.1.0.9000` adds raw-text preprocessing and a TUBELEX public-profile
candidate, a caller-supplied New JACET 8000 level-profile surface, plus a
separately contracted Maas/MTLD variant surface, so the
earlier candidate artifacts and go/no-go decision cannot be reused for tagging
or CRAN submission. A new immutable commit must pass the technical, resource,
and human gates in `RELEASE-CHECKLIST.md`.

## Automated evidence

The `Release candidate` workflow builds one source tarball and checks that exact
artifact on current R for Linux, macOS, and Windows, on R-devel for Linux, and
on the declared R 4.1 minimum. It also builds the PDF reference manual and
generates:

- a file-level package BOM;
- an SPDX 2.3 dependency SBOM for the release-R build-source environment,
  including the declared R constraint (the five check environments remain in
  their separate logs and result records);
- a resource BOM derived from the installed resource inventory;
- release provenance bound to the repository commit, tree, archive, manual,
  environment, and evidence hashes;
- per-platform `R CMD check --as-cran --no-manual` logs and result records; and
- a run index that fails unless every matrix job examined the same tarball and
  all three current-R resource-inventory audits succeeded.

These outputs are technical evidence. A workflow defined by the candidate
cannot independently approve itself, and expiring Actions artifacts are not the
durable archive required for publication.

Multiple independent automated analyses are useful as an additional
quality-control layer, but they do not supply the independent human identity or
decision required by the current resource-admission and publication policy.

CRAN incoming checks report `New submission` until the package has a prior CRAN
version. The check runner accepts only that exact single NOTE as explained; any
additional NOTE, WARNING, ERROR, or unrecognized status remains blocking.

## Go/no-go boundary

The final decision record must name the reviewer, date, candidate commit and
tree, tarball name and SHA-256, known limitations, and rollback action. It must
also preserve the workflow definition, logs, and hashes outside expiring CI
storage.

The TUBELEX unit now has an exported profile candidate but remains explicitly
non-release-approved. The prior internal-only admission candidate does not cover
the new public API scope. A new independent decision must review that exact
scope and bind it to the final repository commit and evidence bytes.

The New JACET 8000 level-profile API is code-only: a final candidate must verify
that no JACET list bytes appear in the repository, source archive, installed
library, platform archive, examples, vignettes, or generated evidence. Its
scientific review must separately confirm the all-eligible denominator,
off-list row, rank-to-level rule, and surface/lemma/flemma provenance.
The caller-supplied AntBNC flemma adapter is also code-only: no AntBNC payload
may enter package artifacts. Review must verify identity fallback, explicit
override precedence, path-private provenance, and the documented distinction
between raw AntBNC approximation and NWLC's manually aligned mapping.

Rollback before publication means closing or reverting the candidate change and
creating no tag or release asset. Rollback after publication means documenting
the defect, withdrawing the affected asset where the hosting service permits,
and preparing a reviewed patch release without rewriting an existing tag.
