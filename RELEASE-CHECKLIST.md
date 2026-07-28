# Release checklist

This checklist defines the minimum evidence for an `ldfreq` release candidate.
It does not imply that the current development version is release-ready.

## 1. Identify the candidate

- [ ] Start from a fresh clone with no modified, staged, or untracked files.
- [ ] Record the repository URL, candidate commit SHA, candidate tree SHA, and
      intended version.
- [ ] Confirm that the candidate commit already contains the same non-`.9000`
      version in `DESCRIPTION`, NEWS, and CITATION, and that the intended tag
      and archive name match it. Commit and check any version change before
      selecting the candidate SHA and tree.
- [ ] Confirm that the commit is on protected `main` and arrived through a pull
      request.
- [ ] Record the active `main` ruleset and verify the repository gate described
      in [`DEVELOPMENT.md`](DEVELOPMENT.md).
- [ ] Record an independent approval of the exact workflow definition, or the
      identity of the separately administered workflow/application that anchors
      the required result. A same-branch job name alone is insufficient.
- [ ] Confirm that `R-CMD-check required` succeeded for the exact candidate
      commit. Record the workflow and job IDs, conclusions, definition hash,
      downloaded logs, and log hashes; links alone are not durable evidence.

## 2. Audit public scope

- [ ] Inspect the candidate tree and all reachable refs for accidental corpus,
      credential, generated-result, cache, or local-environment files.
- [ ] Confirm that no COCA or ELLIPSE payload, no redistributability-restricted
      TAALES resource, and no result derived from an unapproved resource is in
      the repository, package, release assets, examples, or vignettes.
- [ ] For every admitted lexical resource, record its canonical source,
      version, cryptographic hash, redistribution terms, required notice,
      lookup contract, coverage diagnostics, and offline failure behavior.
- [ ] For TUBELEX, verify the installed byte-pinned admission candidate first,
      then evaluate the independent review DCF and preserved evidence bytes
      against the exact reviewed repository commit with
      `experiments/resource-admission/validate-tubelex-admission.R`. Reject
      self-approval, commit/candidate drift, incomplete distribution scope,
      reviewer rejection, or evidence-hash mismatch. Treat a structurally valid
      record as admission evidence only, not reviewer authentication, signature
      verification, public-API approval, or package release readiness.
- [ ] Include each admitted resource's required license, copyright, notice, and
      manifest files under the appropriate `inst/` path, then verify their
      contents and hashes in the source, installed, and binary packages.
- [ ] Verify source-tarball, installed-package, and platform-binary membership
      for every admitted or excluded resource.
- [ ] Generate a machine-readable package file bill of materials and dependency
      SBOM; record their formats, generating tools, tool versions, and hashes.

If no lexical resource is admitted, record that the candidate remains the
resource-independent core rather than leaving the resource inventory blank.

## 3. Check the package artifact

- [ ] In the fresh clone, run the test suite and build one named source package
      with the release R version. Verify afterward that no tracked source file
      changed and that only declared build outputs appeared.
- [ ] Run online `R CMD check --as-cran` against that source package on current
      and devel R, and complete current-R checks on Linux, macOS, and Windows
      (including win-builder or its documented successor).
- [ ] Build and inspect the PDF reference manual; do not treat routine
      `--no-manual` CI as release evidence.
- [ ] Treat every package-check error or warning as blocking. Resolve each note,
      or record its technical justification and independent disposition.
- [ ] Treat an external service, runner, or infrastructure failure as an invalid
      run that must be repeated, not as an exception to a package-check result.
- [ ] Check the built archive's file list, sizes, license files, vignettes,
      examples, URLs, spelling, and package metadata.
- [ ] Install from the built archive in a clean library and run the documented
      smoke examples against the installed package.
- [ ] Record every exact command and exit code, operating system, R version,
      dependency snapshot, logs, archive filename, byte size, and SHA-256
      digest.

An ordinary `R CMD build` embeds packaging metadata such as time and user.
Therefore, archive digests identify the tested artifact but are not by
themselves evidence of byte-for-byte reproducible builds. Any reproducibility
claim must name and verify a separate controlled build procedure.

## 4. Review scientific claims

- [ ] Confirm that each exported metric still matches its versioned
      specification and test fixtures.
- [ ] Confirm that parameter variants remain explicit and that short-input and
      non-computable cases retain structured status and reason fields.
- [ ] Separate compatibility claims from validation evidence: no comparison
      with TAALES, TAALED, CLAN VOCD, COCA, or another implementation is claimed
      unless the exact method crosswalk and legally publishable evidence are
      archived.
- [ ] Review lifecycle labels, README scope, vignette wording, NEWS, and the
      deferred `expected_ttr_d` decision for consistency with the candidate.

## 5. Publish and archive

- [ ] Obtain an independent review of the candidate evidence. A
      single-maintainer exception may be recorded for development snapshots,
      but it does not close the release gate.
- [ ] Create the release tag only after all blocking items above pass, and
      verify that the tag resolves to the recorded candidate commit.
- [ ] Publish release notes that distinguish implemented features, deferred
      work, known limitations, and resource/licensing boundaries.
- [ ] Upload the exact tested `R CMD build` archive as a named release asset.
      Do not substitute GitHub's automatically generated source-code archive.
- [ ] Publish a machine-readable evidence manifest containing its schema
      version; repository, commit, tree, tag, and package version; workflow and
      ruleset evidence; commands and exit codes; environments and dependencies;
      resource inventory; BOM/SBOM; artifact and log paths, sizes, and SHA-256
      digests; reviewer decision; storage location; and retention policy.
- [ ] Make the manifest and artifact identities tamper-evident with a signature
      or verifiable attestation, and preserve the evidence outside expiring
      Actions logs.
- [ ] Download the published named asset, verify its size and SHA-256 against
      the manifest, reinstall from that file, and repeat the smoke test before
      declaring the release complete.
