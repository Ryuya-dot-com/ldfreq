# Development boundary

The initial public baseline is intentionally a resource-independent lexical-
diversity core. Its public functions accept ordered pre-tokenized vectors and do
not claim compatibility with TAALES, TAALED, CLAN VOCD, or another package's
same-named variant without an explicit crosswalk.

## Before version 0.1.0

- exercise the package on R-release and R-devel across Linux, macOS, and Windows;
- freeze the public API and lifecycle policy;
- complete an online `R CMD check --as-cran` with release metadata;
- review documentation, examples, spelling, URLs, and package contents;
- decide whether the design-review expected-TTR D candidate is deferred;
- complete the steps in [`RELEASE-CHECKLIST.md`](RELEASE-CHECKLIST.md) and
  archive the resulting release evidence.

## Repository gate

Before a release is tagged, the GitHub rules for `main` must be independently
verified to:

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

A status job defined in the same pull request is not a trust anchor: the pull
request could weaken the workflow and emit the same successful job name. Before
a release, changes under `.github/workflows/` must therefore require an
independent code-owner approval, or the required result must come from a
separately administered workflow or application whose definition the candidate
cannot change. A zero-review rule may avoid deadlock during single-maintainer
development, but it leaves this exception unresolved and does not satisfy the
release gate. Once an independent maintainer is available, require at least one
code-owner approval for workflow changes.

## Resource admission

NGSL and Open English WordNet remain separate future work. TUBELEX-EN is now
included only as an internal development candidate: its exact source, manifest,
artifact/content hashes, provenance, BSD notice, and installed paths are fixed,
but it has no public lookup/profile API and is not release-approved. The exact
state and every explicitly deferred or excluded resource are recorded in
`inst/spec/ldfreq-resource-inventory.json`. A resource-backed feature is not
complete until its lookup contract, coverage diagnostics, offline behavior,
public lifecycle, and source/installed/platform-binary membership have all been
verified and independently approved.

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
row/totals invariants, bounded expansion, mutation failure, and absence of
runtime network or fallback. A final release still requires independent review
and explicit platform-binary inventory evidence.

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
