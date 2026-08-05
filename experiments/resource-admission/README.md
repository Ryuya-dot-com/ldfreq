# TUBELEX release-admission gate

Status: maintainer-approved resource and public API; final package inventory
and release-candidate checks remain open.

The installed admission evaluator verifies one byte-pinned candidate containing
the package maintainer's explicit license and distribution decision. The
decision records:

- the pinned upstream repository, commit, source file, and hashes;
- the upstream BSD-3-Clause license and the official README distinction between
  distributable frequency lists and non-distributable full corpus text;
- the installed NOTICE, attribution, disclaimer, and transformation statement;
- the absence of raw subtitles and source identifiers;
- the no-network and no-fallback runtime boundary; and
- the approved bundled-resource and public-profile scopes.

CRAN makes the package maintainer accountable for ensuring that third-party
material is used under the license granted by its author. It does not require an
independent reviewer. Independent legal or provenance review remains welcome,
but is not a release prerequisite and does not replace upstream clarification
where clarification is needed.

After installing the package built from the candidate checkout, verify the
decision and its byte-pinned candidate with:

```sh
Rscript experiments/resource-admission/validate-tubelex-admission.R
```

The command must report `maintainer_decision_valid`,
`admission_gate_passed: true`, and `package_release_ready: false`. The last value
remains false until the exact release-candidate source, installed, and binary
resource inventories pass.

See [`OPTIONAL-REVIEW.md`](OPTIONAL-REVIEW.md) for a compact advisory review
checklist.
