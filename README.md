# ldfreq

`ldfreq` provides explicitly versioned lexical-diversity measurements for R.
The current development release computes eleven independently specified metrics
from ordered, pre-tokenized character vectors and returns method, parameter,
schema, and contract provenance with every result.

## Current status

The public API is experimental and remains a resource-independent lexical-
diversity core. One separately licensed, byte-pinned TUBELEX aggregate is now
installed as an internal development candidate so its packaging and failure
behavior can be verified end to end. It is not exposed as a user feature;
lexical-resource profiles and raw-text tokenization remain deferred until their
lookup and licensing contracts are complete.

The implemented metric set is:

- TTR, RTTR/Guiraud, and CTTR
- Herdan C and Maas a-squared
- MSTTR and MATTR
- MTLD
- HD-D
- Yule K and Yule I

The design-review `expected_ttr_d` candidate is not part of the public metric
set.

## Installation

Install the development version from GitHub with `pak`:

```r
pak::pak("Ryuya-dot-com/ldfreq")
```

## Basic use

The core accepts tokens, not raw prose. It performs no hidden case conversion,
Unicode normalization, token deletion, or lemmatization.

```r
library(ldfreq)

tokens <- c("the", "cat", "saw", "the", "other", "cat")

lexdiv_metrics(tokens, metrics = c("ttr", "rttr", "yule_k"))
```

For multiple documents, use an explicitly named list:

```r
documents <- list(
  document_a = c("one", "two", "one"),
  document_b = c("alpha", "beta", "gamma", "delta")
)

lexdiv_metrics_batch(documents, metrics = c("ttr", "hdd"))
```

Parameter variants are represented as explicit specifications rather than
silently changing defaults:

```r
plan <- lexdiv_plan(presets = "length_50_100")
profile <- lexdiv_profile(tokens, plan)
lexdiv_screen(profile)
```

See `vignette("getting-started", package = "ldfreq")` for the result contract,
batch inputs, profiles, and token-length screens.

## Reproducibility boundary

Every metric row carries ordinary columns identifying the metric contract and
result schema. List-columns preserve requested and effective parameters and
method-specific diagnostics. Attributes are conveniences, not the sole source
of provenance.

Short documents never cause requested window, segment, or sample sizes to be
silently reduced. Non-computable requests return structured status and reason
fields.

## Scope

This repository contains no learner corpus, raw subtitle text, source document
identifier, Python or Java runtime, or runtime network-dependent calculation.
It contains one third-party resource development candidate: the slim TUBELEX-EN
Treebank aggregate at commit `7cb5fb36`. Its exact manifest, 2.55 MB gzip
artifact, canonical-content hash, build provenance, BSD 3-Clause notice, and
COPYRIGHTS entry are installed together. The machine-readable inventory still
records zero release-approved resources and no public resource API. NGSL and
Open English WordNet remain excluded until their complete artifact and notice
units pass the same gates.

A non-exported local-resource loader provides the integrity boundary. It reads
an exact manifest and each declared artifact once, hashes those same bytes
before decoding, rejects unavailable, mismatched, unsupported-version, and
schema-invalid inputs in a fixed order, and never downloads or searches for a
fallback. In addition to project-authored synthetic fixtures, the internal
TUBELEX path performs bounded streaming gzip expansion and validates the fixed
515,292-row four-column schema. A second non-exported layer now provides a
versioned exact-match result contract for development testing: it applies no
query normalization, preserves order and duplicates, returns token/type
coverage diagnostics, and keeps unmatched measurements missing rather than
coercing them to zero. This remains an internal development path, not a
resource-backed user feature or release approval.

A byte-pinned admission candidate and non-exported evidence evaluator now make
the remaining independent-review boundary executable. The current installed
state deliberately returns `pending_independent_review`; no approval record is
bundled. Any later record must bind an independent reviewer, the exact candidate
and repository commit, explicit distribution-scope decisions, and preserved
review-evidence bytes. Passing that structural gate would still leave the public
API and final release audits open.

## License

The R source code is licensed under the MIT License. The installed TUBELEX
candidate remains BSD-3-Clause material under its component-level NOTICE and
COPYRIGHTS entry; placement in this repository does not relicense it as MIT.
Any later lexical resource must retain the same separation of license, notice,
and provenance.
