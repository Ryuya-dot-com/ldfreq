# Release checklist

This checklist defines the minimum evidence for an `ldfreq` release candidate.
It does not imply that the candidate version is approved for publication.

The repository-only `Release candidate` workflow and the tools under
`experiments/release-candidate/` build and check one exact source archive and
generate the technical BOM/SBOM/provenance inputs. Their output does not replace
the maintainer's final release decision, durable archival,
signature/attestation, or publication steps below.

## 1. Identify the candidate

- [ ] Start from a fresh clone with no modified, staged, or untracked files.
- [ ] Record the repository URL, candidate commit SHA, candidate tree SHA, and
      intended version.
- [ ] Confirm that the candidate commit already contains the same non-`.9000`
      version in `DESCRIPTION`, NEWS, and CITATION, and that the intended tag
      and archive name match it. Commit and check any version change before
      selecting the candidate SHA and tree.
- [ ] Confirm that NEWS has one coherent heading for the intended public
      version and does not describe an unpublished earlier build as a prior
      public release.
- [ ] Confirm that every exported surface intended to be stable in this release
      reports a non-draft normative contract version. If a public surface is
      experimental, label that status consistently in its help, lifecycle
      policy, and returned provenance.
- [ ] Confirm that the commit is on protected `main` and arrived through a pull
      request.
- [ ] Record the active `main` ruleset and verify the repository gate described
      in [`DEVELOPMENT.md`](DEVELOPMENT.md).
- [ ] Record the exact workflow definition hash and the protected required-check
      configuration. A same-branch job name alone is insufficient.
- [ ] Confirm that `R-CMD-check required` succeeded for the exact candidate
      commit. Record the workflow and job IDs, conclusions, definition hash,
      downloaded logs, and log hashes; links alone are not durable evidence.

## 2. Audit public scope

- [ ] Inspect the candidate tree and all reachable refs for accidental corpus,
      credential, generated-result, cache, or local-environment files.
- [ ] Confirm that no COCA or ELLIPSE payload, no redistributability-restricted
      lexical resource distributed with or used by TAALES, and no result
      derived from an unapproved resource is in the repository, package,
      release assets, examples, or vignettes.
- [ ] Confirm that no New JACET 8000 list bytes or reconstructable full-list
      output is bundled. Exercise `new_jacet8000_profile()` only with
      project-authored synthetic fixtures or a legitimately obtained
      caller-authorized local copy.
- [ ] Confirm that no AntBNC payload, full mapping, or derived reconstructable
      list is bundled. Exercise `lexdiv_flemmatize()` in installed examples and
      checks only with project-authored synthetic fixtures; local research runs
      may use a legitimately obtained analyst-supplied copy.
- [ ] For every admitted lexical resource, record its canonical source,
      version, cryptographic hash, redistribution terms, required notice,
      lookup contract, coverage diagnostics, and offline failure behavior.
- [ ] For TUBELEX, run
      `experiments/resource-admission/validate-tubelex-admission.R` against the
      installed package. Confirm the byte-pinned maintainer decision, upstream
      BSD-3-Clause and README URLs, approved scopes, risk controls, and one
      release-approved resource. Treat this as resource and public-profile
      admission evidence only, not final package release readiness.
- [ ] Include each admitted resource's required license, copyright, notice, and
      manifest files under the appropriate `inst/` path, then verify their
      contents and hashes in the source, installed, and binary packages.
- [ ] Verify source-tarball, installed-package, and platform-binary membership
      for every admitted or excluded resource.
- [ ] Generate a machine-readable package file bill of materials and dependency
      SBOM; record their formats, generating tools, tool versions, and hashes.

If no lexical resource is admitted, record that the candidate remains the
resource-independent core rather than leaving the resource inventory blank. If
a public resource API is present but not admitted, block release; do not relabel
it as internal-only evidence.

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
      or record its technical justification and maintainer disposition.
- [ ] If CRAN incoming reports the exact single NOTE `New submission`, retain it
      in every raw log and record its explicit disposition.
- [ ] In the labeled R 4.1 minimum-version diagnostic only, retain and explain
      the exact additional dependency NOTE caused by deliberately unavailable
      optional package `textstem` with `_R_CHECK_FORCE_SUGGESTS_=false`. Require
      all other jobs to install their suggested packages, and block every other
      NOTE rather than generalizing either disposition.
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
- [ ] Confirm that each Maas/MTLD sensitivity row matches its separate variant
      contract, that reference labels identify only their declared comparison
      scope, and that no official TAALED compatibility or code-translation
      claim has entered documentation or metadata.
- [ ] Confirm that New JACET 8000 level rows use `ceiling(rank / 1000)`, exact
      and cumulative rates retain all eligible terms as the denominator,
      off-list terms remain visible, and surface/lemma/flemma, normalization,
      flemma match rules, and headword-conflict policy remain in provenance.
- [ ] Confirm that raw AntBNC use is described as an NWLC approximation, not
      compatibility; verify AntBNC/wordlist/error conflict modes, explicit
      overrides, identity fallback, and token-level alternative ranks.
- [ ] Separate compatibility claims from validation evidence: no comparison
      with TAALES, TAALED, CLAN VOCD, COCA, or another implementation is claimed
      unless the exact method crosswalk and legally publishable evidence are
      archived.
- [ ] Review lifecycle labels, README scope, vignette wording, NEWS, and the
      deferred `expected_ttr_d` decision for consistency with the candidate.

## 5. Publish and archive

- [ ] Record the maintainer's final go/no-go decision for the exact candidate,
      including known limitations and rollback action. Optional third-party
      review may be retained as supporting evidence but is not a release gate.
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
      digests; maintainer decision; storage location; and retention policy.
- [ ] Make the manifest and artifact identities tamper-evident with a signature
      or verifiable attestation, and preserve the evidence outside expiring
      Actions logs.
- [ ] Download the published named asset, verify its size and SHA-256 against
      the manifest, reinstall from that file, and repeat the smoke test before
      declaring the release complete.
