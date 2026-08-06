# ldfreq 0.1.0 release-candidate boundary

The earlier immutable core-only version `0.1.0` candidate was not published,
and its artifacts and go/no-go decision cannot be reused. This replacement
candidate adds raw-text preprocessing, a TUBELEX public-profile candidate, a
caller-supplied New JACET 8000 level-profile surface, and a separately
contracted Maas/MTLD variant surface. The exact replacement commit must pass
the technical, resource, and maintainer decision gates in
`RELEASE-CHECKLIST.md` before tagging or CRAN submission.

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

These outputs are technical evidence. A workflow result is not the maintainer's
final release decision, and expiring Actions artifacts are not the durable
archive required for publication.

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

The TUBELEX unit and exported profile are maintainer-approved in a byte-pinned
admission candidate. That record documents the pinned BSD-3-Clause and README
basis, approved scopes, absence of raw subtitle material, installed notice, and
the fact that no independent legal opinion was obtained. The final exact
source, installed, and binary inventory must reproduce this boundary.

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
