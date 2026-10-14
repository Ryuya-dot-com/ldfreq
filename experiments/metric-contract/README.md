# Metric admission records

This directory preserves design and admission evidence for metrics whose
lifecycle changed while the `0.1.0` contract was being frozen.

These are historical admission decisions, not the current default-method or
stability catalog. Since package 0.3.0, expected-TTR D is experimental and
requires explicit selection; the core contract is 0.2.0. Use
[`lexdiv_methods()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_methods.html)
and the [measurement lifecycle](../../LIFECYCLE.md) for current behavior.
The recorded JSON, predecessor hash and method identity below are unchanged.

`expected-ttr-d-admission.json` records the decision to admit the deterministic
expected-TTR D method to the recomposed `0.1.0` core. It supersedes the
2026-08-03 deferral decision after the public implementation, frozen contract,
independent reference values, spectrum audit, and diagnostics were completed.
The method is not called VOCD and is not claimed compatible with CLAN or the
historical Python Monte Carlo procedure.

The exact predecessor contract remains available in Git history at commit
`d10bcae4ffed6c09506b5e9ddd0771633f4f3703`, where its SHA-256 is
`a3ae6ae2fd3b19ee30f9df93bae5f67c3cae5a285d909d53a7f66d5be880a0c9`.
