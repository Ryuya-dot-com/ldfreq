# API and measurement lifecycle

The resource-independent, pre-tokenized twelve-method core introduced in
`0.1.0` remains frozen throughout the pre-1.0 package line. Raw-text
preprocessing, exact lexical overlap, many-document reference coverage,
caller-supplied generic lexical-norm profiles, and resource-backed profiles are
separate public surfaces with their own contract
versions and review gates. The Maas/MTLD
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

Package 0.2.0 corrects cancellation in `expected_ttr_d_hypergeom_fit_v1`.
Its finite-population expectation, D model, unweighted least-squares objective,
parameter domain, and 100-step log-D fit are unchanged. Direct duplicate-draw
probabilities and stable residuals replace cancellation-prone arithmetic.
This is an explicit numerical-correction exception to frozen evaluation order,
not a new estimator: the method and core contract IDs remain unchanged, and
the specification records the corrected evaluation. An independently generated
80-digit fixture covers the failure. Record the package version as well as the
method ID when reproducing results. See `development/REVIEW-20260922.md`.

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

The canonical function and result-class names are established by the initial
version 0.1.0 release. Compatibility aliases and a public deprecation cycle are
unnecessary because no earlier CRAN version exposed alternative names. This
initial-release exception does not waive the deprecation policy after
publication.

## Separate preprocessing and resource surfaces

Raw-text tokenization and resource-backed lookup/results use separate functions
and contracts. They do not overload or silently preprocess
`lexdiv_metrics()`. `lexdiv_metrics_text()` calls that unchanged core and keeps
its token audit outside the metric schema. Adding or changing a tokenizer,
normalization, content-word set, lemma backend contract, query transform,
coverage denominator, or matched-only summary requires a new corresponding
contract version.

Flemma is a distinct lexical unit. Changing the fixed AntBNC adapter/parser,
unknown-form fallback, override precedence, declared resource/override version
semantics, label-disclosure boundary, path-provenance boundary, or public
result semantics requires a new preprocessing contract version. Declared
versions are caller labels, not inferred content identities. Performance
caching must remain result-invariant; its source-byte digest must remain
limited to caching and must not become public provenance or an
overlap-comparability key.

Preprocessing objects are validated against their recorded contract version.
Objects serialized under the current `0.2.0` contract are revalidated whenever
they are consumed. If provenance is incomplete, unsupported, or manually
altered, recreate the object from the original text and reapply current
annotations and explicit backend labels; do not edit provenance in place.
Objects from preprocessing contract 0.1.0 must be recreated; there is no
automatic migration. Tokenizer rules remain at tokenizer version 0.1.0.
The new contract requires text hashes, the token pattern, character counts,
and a fingerprint of the token rows before annotation. It detects accidental
inconsistency, not intentional forgery or the correctness of supplied lemmas.

TUBELEX profile contract 0.2.0 rejects known generic-tokenizer inputs unless
the caller explicitly allows a mismatch, records alignment status, adds an
opt-in apostrophe transform, and specifies batch snapshot reuse. The resource
bytes and default character-term normalization have not changed. Convenience
wide output retains specification metadata by default; reshaping and plotting
reject comparison groups with unlike method, contract, or parameter identities.

For lexical-level profiles, changing rank-to-level mapping, entry
normalization, alias collision policy, default lexical unit, type identity,
cumulative denominator, or off-list handling requires a new level-profile
contract version. Public availability of a caller-supplied list does not admit
its bytes to the package resource inventory.
Changing AntBNC-versus-wordlist conflict detection, its default policy, or the
reported alternative rank/level also requires a new level-profile contract
version.

For exact lexical overlap, changing set identity, normalization, formulas,
denominators, empty-set behavior, content-word membership, the default
comparability policy, or term-detail disclosure requires a new overlap contract
version. Exact term details remain opt-in and must be visibly disclosed in the
returned provenance and print output.

For many-document reference coverage, changing exact reference membership,
token/type formulas, document or reference empty-input rules, document-local
invalidity, ID disclosure, summary shape, term-detail disclosure, or the scope
of the whole-result row bound requires a new reference-coverage contract
version. Adding normalization, annotation, or multiple-reference inference to
the existing method IDs is not a compatible extension.

For caller-supplied lexical-norm profiles, changing exact-key matching,
measure/resource metadata fields, token/type identity, observed matched-only
arithmetic means, any of the three coverage denominators, OOV versus missing-
annotation states, fixed table columns or ordering, structural-error boundary,
or whole-result row budget requires a new norm-profile contract or result
schema version. Adding implicit normalization, fuzzy matching, imputation,
automatic thresholds, composite scores, or a default cross-measure plot is not
a compatible extension.

Likewise, adding a variant formula, threshold boundary, minimum factor length,
tail rule, directional aggregation, or compatibility claim requires a new
variant method or contract identity. Shared labels never imply equivalence with
a third-party implementation.

A normative measurement contract does not by itself establish redistribution
rights for its reference data. Resource rights, artifact identity,
coverage/failure behavior, installed notices, and package inventory are reviewed
and recorded separately from the public API contract.
