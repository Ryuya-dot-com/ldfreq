# Independent review guide for the TUBELEX candidate

This guide is the handoff contract for the human reviewer of
`tubelex-en-treebank-slim-7cb5fb36-admission-v1`. The review covers resource
admission only. It does not approve a public API or declare the package ready
for release.

## Reviewer eligibility

The reviewer must be an identifiable person who:

- did not author or build the candidate and was not materially involved in
  choosing its release-admission evidence;
- is not `Ryuya-dot-com` (case-insensitive), the login excluded by the pinned
  candidate policy;
- can identify themselves by name, affiliation or `Independent`, and GitHub
  login;
- can assess data provenance, redistribution terms, attribution, artifact
  identity, and the stated package-distribution scope; and
- is willing to preserve their findings and explicitly attest to independence.

CI, automated checks, and AI-assisted analysis may be cited as evidence, but
they are not the independent approver. A human reviewer remains responsible for
the decision and attestations recorded in the approval DCF.

## Frozen review target

Before review begins, record one lowercase 40-hex repository commit and do not
review a moving branch. At that commit, confirm the following pinned identity:

| Property | Required value |
|---|---|
| Candidate ID | `tubelex-en-treebank-slim-7cb5fb36-admission-v1` |
| Candidate SHA-256 | `8c8eca27e3f2810f6f1c8ed158f93acb22d8ad885d3832448cf3b6d194309de6` |
| Upstream commit | `7cb5fb36add76b83a266d1967536e1a1d3faa513` |
| Upstream source SHA-256 | `4096022259d5eaa7261c3bf22c3b0af9fd58ae8eebe17894c0b34a163954f936` |
| Installed artifact SHA-256 | `ded083e5b9f59ddfb719ebd88063778500cb347e1eab0f2d79ff55085d92fb4d` |
| Canonical content SHA-256 | `423dd4631c9da2f7442705d2930126da4cba980e46b6a5c0dda98336dce74916` |
| NOTICE SHA-256 | `e65a1f5d0d6e7806e31e92d78bf3b903115e610c36bd9f2406269700441ecdd3` |

The machine-readable source of truth is
`inst/spec/tubelex-release-admission-candidate.json`. If it disagrees with this
guide, stop and reject the review target rather than repairing the discrepancy
informally.

## Required review

Use `review-evidence-template.md` to record commands, environments, results,
and findings. The reviewer must reach an explicit conclusion for each of these
items:

1. The upstream source, manifest, installed artifact, canonical content, and
   NOTICE resolve to the pinned identities.
2. The BSD-3-Clause redistribution terms cover the aggregate included in the
   package under the stated conditions.
3. `inst/licenses/tubelex/NOTICE.md` and `inst/COPYRIGHTS` preserve the required
   attribution and modification notice without implying upstream endorsement.
4. The candidate contains aggregate word statistics, not raw subtitle text or
   source identifiers, and its actual package membership matches the declared
   internal-development distribution scope.
5. Runtime lookup is non-exported and performs no network access, implicit
   download, or fallback.
6. The reproducibility and package-inventory evidence supports the identity
   claims. Passing CI alone is not sufficient for approval.

If specialist legal judgment is needed to decide redistribution rights, the
reviewer should obtain it or return `rejected`; uncertainty must not be converted
into approval.

## Minimum validation procedure

Start with a clean checkout of the exact reviewed commit. Install that checkout
and run the fail-closed candidate check:

```sh
git status --porcelain
git rev-parse HEAD
R CMD INSTALL .
Rscript experiments/resource-admission/validate-tubelex-admission.R candidate
```

The final command must report `pending_independent_review`,
`admission_gate_passed: false`, and `package_release_ready: false`. Review the
successful cross-platform workflow for the same commit and independently
inspect the source-build and package-inventory evidence described in:

- `experiments/tubelex-source-build/README.md`
- `experiments/package-resource-inventory/README.md`
- `inst/extdata/tubelex/7cb5fb36/build-provenance.json`
- `inst/licenses/tubelex/NOTICE.md`
- `inst/COPYRIGHTS`

Record any additional commands and outputs in the evidence file. Do not paste
credentials, local private paths, or unrelated personal data into evidence.

## Decision and preservation

1. Complete `review-evidence-template.md` and publish or archive its exact bytes
   at a stable GitHub URL.
2. Compute SHA-256 over those exact bytes. Do not edit the evidence afterward.
3. Copy `approval-record.template.dcf`, retain the exact field order, and replace
   every placeholder. Use `approved` only when all four reviewed scopes pass;
   otherwise use `rejected` and `not-approved` where applicable.
4. Preserve the evidence and approval record outside the installed package,
   preferably with a signed commit or another verifiable attestation. The
   evaluator checks byte identity, not authorship or signatures.
5. Install the package built from the reviewed commit and run:

```sh
Rscript experiments/resource-admission/validate-tubelex-admission.R \
  approval path/to/approval.dcf path/to/review-evidence.md REVIEWED_COMMIT
```

An `approval_record_valid` result closes only the resource-admission record
gate. `package_release_ready` must remain `false`; public-API review and the
final named-release inventory audit remain separate gates.
