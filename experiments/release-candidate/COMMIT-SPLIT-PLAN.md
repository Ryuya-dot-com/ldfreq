# Pre-commit audit and split plan

Audit date: 2026-08-05

This document records the intended split of the current uncommitted release
work. It is not final 0.1.0 release evidence.

## Audited starting point

- Branch: `feature/preprocessing-frequency`
- Base and `origin/main`: `24c1ce5c258101ff3407be2a5eaa0e469cc7dd08`
- Staged paths at audit start: none
- Commits created during preparation of this audit: none
- Pushes performed through split execution: none

The working tree is a single cumulative change set above `origin/main`. The
public exports, contract files, resource inventory, admission evaluator, and
tests depend on one another. Splitting those shared surfaces into smaller
feature commits would create misleading intermediate states, so the first
commit keeps them atomic.

## Split execution record

Commit 1 was created as `a35a1c7` (`Add auditable preprocessing and frequency
profile APIs`). A clean detached clone of that exact commit passed the full
test suite with `textstem` 0.1.4 installed. Its source tarball had SHA-256
`c7268a7238751bca6b3acdec606e494bf20cfad0b13ab90c9edbcc4889ba5cb3`,
passed `R CMD check --as-cran` with zero errors, zero warnings, and the expected
new-submission/development-version note, and passed 780 package-resource
inventory assertions across source, platform archive, and installed library.

Commit 2 is the commit that first contains this execution record, so this file
does not attempt to contain its own commit hash. Git history is authoritative.
Neither commit is final 0.1.0 release evidence.

## Commit 1: add auditable preprocessing and reference-profile APIs

Stage these paths together:

```text
DESCRIPTION
NAMESPACE
R/level-profile.R
R/preprocessing.R
R/resource-admission.R
R/tubelex-profile.R
R/variant-metrics.R
experiments/package-resource-inventory/validate-package-resource-inventory.R
experiments/release-candidate/generate-release-evidence.R
experiments/resource-admission/README.md
experiments/resource-admission/OPTIONAL-REVIEW.md
experiments/tubelex-source-build/README.md
inst/spec/ldfreq-preprocessing-contract.json
inst/spec/ldfreq-preprocessing-contract.schema.json
inst/spec/ldfreq-resource-inventory.json
inst/spec/lexical-diversity-variant-contract.json
inst/spec/lexical-diversity-variant-contract.schema.json
inst/spec/lexical-level-profile-contract.json
inst/spec/lexical-level-profile-contract.schema.json
inst/spec/tubelex-frequency-profile-contract.json
inst/spec/tubelex-frequency-profile-contract.schema.json
inst/spec/tubelex-release-admission-candidate.json
inst/spec/tubelex-release-admission-candidate.schema.json
man/lexdiv_flemmatize.Rd
man/lexdiv_preprocessing.Rd
man/lexdiv_variant_metrics.Rd
man/new_jacet8000_profile.Rd
man/tubelex_frequency_profile.Rd
tests/testthat/helper-antbnc.R
tests/testthat/test-level-profile.R
tests/testthat/test-preprocessing.R
tests/testthat/test-resource-admission.R
tests/testthat/test-tubelex-profile.R
tests/testthat/test-variant-metrics.R
tests/tubelex-resource-audit.R
```

Suggested subject:

```text
Add auditable preprocessing and frequency profile APIs
```

Minimum validation from that exact commit:

```sh
Rscript -e 'devtools::test(".", reporter = "summary")'
R CMD build .
env _R_CHECK_FORCE_SUGGESTS_=false \
  R CMD check --as-cran --no-manual /resolved/path/ldfreq_VERSION.tar.gz
Rscript experiments/package-resource-inventory/validate-package-resource-inventory.R \
  . /new/audit/directory /resolved/path/ldfreq_VERSION.tar.gz
```

The placeholder paths above are documentation for a human operator. Resolve
them to one source tarball and a destination that does not yet exist. Release
evidence must record that exact tarball path and its SHA-256. The
`_R_CHECK_FORCE_SUGGESTS_` diagnostic pass demonstrates that the package works
without optional backends; it does not replace the complete candidate check
with all available suggested packages installed.

## Commit 2: document workflows and release gates

Stage these paths together:

```text
DEVELOPMENT.md
LIFECYCLE.md
NEWS.md
README.md
RELEASE-CANDIDATE.md
RELEASE-CHECKLIST.md
experiments/release-candidate/COMMIT-SPLIT-PLAN.md
inst/CITATION
inst/examples/offline-smoke.R
man/ldfreq-package.Rd
vignettes/getting-started.Rmd
vignettes/preprocessing-and-frequency.Rmd
```

Suggested subject:

```text
Document preprocessing workflows and release gates
```

Repeat the Commit 1 validation from this exact commit, then install the exact
built tarball. Load `ldfreq` and source its installed
`system.file("examples", "offline-smoke.R", package = "ldfreq")`, as shown in
the README. Also confirm that the rendered vignettes, help index, citation,
package-resource inventory, and installed example contain neither
private-resource payloads nor machine-specific absolute paths.

## Later commit: freeze the exact 0.1.0 candidate

Do not create the freeze commit until Commits 1 and 2 pass from a clean tree.
The freeze is intentionally separate and should contain only candidate-state
changes such as:

- changing `Version` from the development suffix to `0.1.0`;
- changing `Config/ldfreq/status` from development to release-candidate;
- reconciling release wording and evidence identifiers with the exact commit;
- regenerating evidence from the exact source tarball.

Suggested subject:

```text
Freeze ldfreq 0.1.0 release candidate
```

The byte-pinned TUBELEX admission candidate contains the maintainer's explicit
license and distribution decision, upstream URLs, approved scopes, and risk
controls. Independent review is optional. The final freeze must retain that
decision, reproduce the candidate and resource identities, and pass the exact
source/installed/binary inventory audits.

## Candidate gates after the split

From the exact freeze commit and an unmodified checkout:

1. Build one source tarball and record its SHA-256.
2. Run the package-resource inventory against that exact tarball.
3. Run `R CMD check --as-cran` on the supported R matrix, including Linux,
   macOS, Windows, R-devel, and the minimum supported R release, with all
   available suggested packages installed. Retain a separate no-Suggests job
   for the conditional-backend boundary.
4. Build and inspect the PDF manual and vignettes.
5. Install the exact tarball and run the offline smoke example.
6. Verify that conditional suggested backends remain conditional when absent.
7. Validate the bundled maintainer resource-admission decision and its exact
   candidate bytes.
8. Merge through the protected-branch review workflow; do not bypass required
   CI gates.

Any evidence generated before these commits is useful only as pre-commit
diagnostic evidence. It must not be presented as evidence for the later frozen
candidate.
