# Release-candidate boundary

The frozen lexical-diversity core remains resource-independent and accepts
ordered pre-tokenized vectors. The `0.1.0` release candidate adds separate
raw-text preprocessing and TUBELEX profile APIs under their own versioned
contracts. A third contract exposes selected Maas and sequential-MTLD
sensitivity variants; a fourth defines caller-supplied lexical-level profiles.
All leave the frozen core registry unchanged. The package does
not claim compatibility with TAALES, TAALED, CLAN VOCD, or another package's
same-named variant beyond each row's explicit comparison scope.

The lexical-level profile is resource-decoupled: `new_jacet8000_profile()` and
`new_jacet8000_profile_batch()`
accept only a caller-supplied data frame, local CSV, or official-layout local
XLSX, compute Level 1--8
exact/cumulative token and type rates, and never bundles, downloads, or returns
the full New JACET 8000 list. The batch adapter requires explicit document IDs,
processes the external list once, and bounds its combined summary/lookup rows.
This public measurement contract does not admit
the underlying JACET resource into the package inventory.

`lexdiv_flemmatize()` similarly reads only a caller-supplied local AntBNC text
resource. It keeps that payload outside package artifacts, records only the
source basename and exact hash, and describes raw AntBNC as an NWLC
approximation rather than compatibility. New JACET integration must retain
per-token AntBNC/override/identity rules and selectable headword-conflict
resolution.

## Before publishing version 0.1.0

- exercise the package on R-release and R-devel across Linux, macOS, and Windows;
- preserve the frozen eleven-method public API and lifecycle policy;
- complete an online `R CMD check --as-cran` with release metadata;
- review documentation, examples, spelling, URLs, and package contents;
- preserve the recorded deferral of expected-TTR D from v0.1;
- complete the steps in [`RELEASE-CHECKLIST.md`](RELEASE-CHECKLIST.md) and
  archive the resulting release evidence.

## Repository gate

Before a release is tagged, the GitHub rules for `main` must be verified to:

- require pull requests and an up-to-date branch;
- require the exact status check `R-CMD-check required`, with GitHub Actions as
  its expected source;
- block force pushes and branch deletion;
- require resolution of review conversations; and
- prevent administrators from bypassing the release gate during ordinary work.

These are target settings stored by GitHub, not claims about the current
configuration of the repository. Record the verified ruleset with each release
candidate. The matrix jobs retain platform-specific diagnostics; the stable
`R-CMD-check required` job is the single branch-rule interface and passes only
when every matrix job passes.

A status job defined in the same pull request is not by itself a trust anchor:
the pull request could weaken the workflow and emit the same successful job
name. The final maintainer decision must therefore record and inspect the exact
workflow-definition hash together with the protected ruleset and check logs.
Independent code-owner review or a separately administered workflow is welcome
as additional assurance but is not required for a single-maintainer release.

## Resource admission

NGSL and Open English WordNet remain separate future work. TUBELEX-EN is
included as a maintainer-approved bundled resource: its exact
source, manifest, artifact/content hashes, provenance, BSD notice, and installed
paths are fixed. The exported `tubelex_frequency_profile()` has a normative
0.1.0 measurement contract and
wrapper applies an explicit identity or TUBELEX-oriented query transform,
retains original and lookup terms, reports token/type coverage and
normalization collisions, and leaves unmatched measurements missing rather
than inventing zero counts. Its non-exported exact-match lower layer remains
governed by the internal lookup contract. The exact state and every explicitly
deferred or excluded resource are recorded in
`inst/spec/ldfreq-resource-inventory.json`.
A New JACET 8000 adapter does not change that resource state. The list remains
explicitly excluded from package payloads while durable CRAN and downstream
redistribution scope remains unresolved; only caller-authorized local input is
read at runtime, with no network or fallback path.
The AntBNC adapter also does not admit its payload: official download
availability is not treated as downstream redistribution permission, and only
caller-authorized local input is read without a network path.
A resource-backed feature is not complete until its lookup contract, coverage
diagnostics, offline behavior, public lifecycle, and source/installed/platform-
binary membership have all been verified and the maintainer's admission
decision has been recorded.

The installed release-admission candidate is separately byte-pinned and states
`maintainer-approved`. It records the pinned upstream BSD-3-Clause license and
README, CRAN policy basis, maintainer identity and date, approved distribution
and public-profile scopes, and explicit risk controls. Missing, modified, or
semantically weakened candidate bytes fail closed without search, download, or
fallback. A valid decision closes only the resource-admission gate: the
evaluator always leaves `package_release_ready` false until the final exact
source, installed, and binary inventory audit passes. Independent review is an
optional additional check, not a release prerequisite.

The current non-exported loader establishes only the common integrity and
failure boundary. It consumes exact local paths, hashes the same raw bytes that
it later decodes, enforces per-file and aggregate limits, and has no network,
shell, `latest`, or sibling-file fallback. Its four ordered failure classes are
`resource_unavailable`, `hash_mismatch`, `unsupported_resource_version`, and
`schema_mismatch`. Gzip is registered only through a bounded raw-connection
decoder, and the sole real-resource content adapter accepts only the fixed
TUBELEX four-column schema. Other compression and real-resource adapters remain
unregistered and therefore fail closed.

SHA-256 uses `digest` with serialization disabled so the package can retain its
declared R 4.1 minimum. This hash is a content-identity and corruption check,
not a signature or proof that a manifest is approved. The repository matrix
therefore includes an explicit R 4.1 job in addition to current R, R-devel,
macOS, and Windows.

The TUBELEX runtime never downloads. A separate development-CI builder job on
Ubuntu and Windows downloads only the fixed upstream aggregate source, whose
size and compressed/decompressed hashes are checked before parsing. The R-only
builder then verifies the full 19-column source, reproduces the canonical
four-column content hash, and stress-tests two clean builds, existing-target
and cooperative-lock refusal, forced-failure cleanup, and one-winner concurrent
promotion. Its directory-rename policy protects cooperating builders in a
controlled single-writer workflow; it does not claim atomic no-replace against
a noncooperating process. The pinned upstream source itself is not bundled.

Every ordinary package check loads the installed TUBELEX candidate and verifies
its manifest, compressed and decoded hashes, NOTICE, provenance, inventory,
row/totals invariants, exact lookup and coverage behavior, the byte-pinned
maintainer admission decision, bounded expansion, mutation failure, and absence of
runtime network or fallback. In addition,
every release-R job on Ubuntu, macOS, and Windows builds a fresh source archive
and platform package, installs it in a clean library, and verifies that all
declared resource/legal/inventory, lookup-contract, and admission-candidate
members remain byte-identical across the source tree, source archive, platform
archive, and installation. The audit rejects undeclared `extdata` and emits a
run-specific JSON evidence record. A final release still requires a preserved
rerun and maintainer go/no-go decision against the named release candidate;
development CI output alone is not durable release evidence.

## Independent numerical audit

Every `R CMD check` runs `tests/differential-audit.R` against the installed
public API. The audit compares 500 deterministic random MTLD documents with a
separately written reference implementation, compares 1,000 deterministic
random documents with direct formula, window, and hypergeometric calculations,
and exhaustively checks 73,809 MSTTR, MATTR, and HD-D results over every
three-type sequence through length seven and every local length through
`N + 1`.

This is a cross-platform implementation check, not evidence that one
implementation is a normative oracle or that the measures are valid for every
population and task. The hand fixtures and versioned method contract remain
independent required evidence.
