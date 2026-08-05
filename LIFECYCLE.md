# API and measurement lifecycle

The `0.1.x` line freezes the resource-independent, pre-tokenized eleven-method
core. Raw-text preprocessing and resource-backed profiles are separate public
surfaces with their own contract versions and review gates. The Maas/MTLD
sensitivity surface also has a separate variant contract and does not add
methods to the frozen core registry. Caller-supplied lexical-level profiles
have a separate contract for resource input, rank bands, denominator, off-list
handling, and plot data. Package version,
metric-contract version, result-schema version, preprocessing-contract version,
and resource-profile contract version are independent identities and are
recorded separately.

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

## Separate preprocessing and resource surfaces

Raw-text tokenization and resource-backed lookup/results use separate functions
and contracts. They do not overload or silently preprocess
`lexdiv_metrics()`. `lexdiv_metrics_text()` calls that unchanged core and keeps
its token audit outside the metric schema. Adding or changing a tokenizer,
normalization, content-word set, lemma backend contract, query transform,
coverage denominator, or matched-only summary requires a new corresponding
contract version.

Flemma is a distinct lexical unit. Changing the AntBNC parser, unknown-form
fallback, override precedence, form-family identity, path-provenance boundary,
or cache-visible result semantics requires a new preprocessing contract
version. Performance caching must remain result-invariant and path-free.

For lexical-level profiles, changing rank-to-level mapping, entry
normalization, alias collision policy, default lexical unit, type identity,
cumulative denominator, or off-list handling requires a new level-profile
contract version. Public availability of a caller-supplied list does not admit
its bytes to the package resource inventory.
Changing AntBNC-versus-wordlist conflict detection, its default policy, or the
reported alternative rank/level also requires a new level-profile contract
version.

Likewise, adding a variant formula, threshold boundary, minimum factor length,
tail rule, directional aggregation, or compatibility claim requires a new
variant method or contract identity. Shared labels never imply equivalence with
a third-party implementation.

An exported resource profile is not release-approved merely because its code is
public. Its lifecycle, rights, artifact identity, coverage/failure behavior,
independent public-scope review, and final package inventory must all pass.
