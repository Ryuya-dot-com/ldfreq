# TUBELEX release-admission gate

Status: pending independent review; no bundled approval record and no release
approval.

This directory provides the repository-side command wrapper for the installed,
non-exported admission evaluator. The evaluator binds a strict approval record
to:

- the byte-pinned admission candidate;
- one exact repository commit;
- a reviewer who is not listed as a candidate author or builder;
- explicit independence attestations and review scope; and
- one exact preserved review-evidence file by SHA-256.

It does not authenticate the reviewer or verify a cryptographic signature. The
record and evidence must still be independently checked and preserved under the
release checklist.

The approver is an independent human reviewer; CI and AI-assisted analysis may
support that person but cannot supply the identity, independence attestation,
or accountable judgment required by this gate. Give the reviewer the
[`REVIEWER-GUIDE.md`](REVIEWER-GUIDE.md) handoff. It uses
[`review-evidence-template.md`](review-evidence-template.md) for durable findings
and [`approval-record.template.dcf`](approval-record.template.dcf) for the
strict, externally supplied decision record.

After installing the package built from the candidate checkout, verify the
current fail-closed state with:

```sh
Rscript experiments/resource-admission/validate-tubelex-admission.R candidate
```

The command succeeds only when the installed candidate is intact and no
approval is claimed. Once an independent reviewer supplies the strict DCF
record and preserved evidence, evaluate them against the exact reviewed commit:

```sh
Rscript experiments/resource-admission/validate-tubelex-admission.R \
  approval path/to/approval.dcf path/to/review-evidence.txt COMMIT_SHA
```

An `approval_record_valid` result closes only the resource-admission record
gate. It does not approve a public API or the final package release.
