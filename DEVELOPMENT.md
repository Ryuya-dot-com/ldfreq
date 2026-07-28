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

NGSL, TUBELEX-EN, and Open English WordNet remain separate future work. A
resource-backed feature is not complete until its exact source, version, hash,
license, notice, lookup contract, coverage diagnostics, offline behavior, and
source/installed/binary package membership have all been verified.
