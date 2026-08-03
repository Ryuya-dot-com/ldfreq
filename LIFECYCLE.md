# API and measurement lifecycle

The `0.1.x` line freezes the resource-independent, pre-tokenized eleven-method
core. Package version, metric-contract version, and result-schema versions are
independent identities and are recorded separately.

## Method identity

A `method_id` fixes the formula, scale, boundary and tail rules, operation
semantics, aggregation, and canonical defaults. A substantive change receives
a new method ID; an existing method ID is never silently redefined.

A numerical bug fix must name the affected method, add an independent
regression fixture, and state explicitly whether the corrected behavior needs a
new method ID. Compatibility is never inferred from a shared metric label.

## Result and orchestration schemas

A schema version fixes ordered fields, storage types, meanings, status and
missingness vocabulary, and identity behavior. Public columns are not removed,
reordered, or repurposed in a patch release. New diagnostics or fields require
a new schema version.

Default parameters, short-input behavior, token/type identity, normalization,
and tokenization are measurement semantics. They are not changed in a patch
release.

Plan and specification hashes are reproducibility labels rather than security
signatures. Any change to their identity inputs or serialization receives a new
schema version and new pinned fixtures.

## Deprecation

An exported function, argument, method, or schema must be documented as
deprecated in help and `NEWS.md` for at least one minor development cycle before
removal. A replacement and migration path must be named. During the pre-1.0
period, an unavoidable breaking change increments the minor package version and
is called out prominently.

## Separate future surfaces

Raw-text tokenization and resource-backed lookup/results use separate functions
and contracts. They do not overload or silently preprocess
`lexdiv_metrics()`. Experimental or internally installed resource code is not a
public API until its own lifecycle, rights, identity, coverage, and failure
gates pass.
