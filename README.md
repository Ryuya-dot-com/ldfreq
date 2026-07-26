# ldfreq

`ldfreq` provides explicitly versioned lexical-diversity measurements for R.
The current development release computes eleven independently specified metrics
from ordered, pre-tokenized character vectors and returns method, parameter,
schema, and contract provenance with every result.

## Current status

The public API is experimental. The resource-independent lexical-diversity core
is implemented and heavily tested; lexical-resource profiles and raw-text
tokenization are deliberately deferred until their lookup and licensing
contracts are complete.

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

This repository currently contains no production lexical resource, learner
corpus, Python or Java runtime, or network-dependent calculation. NGSL,
TUBELEX-EN, and Open English WordNet support will be admitted only after
resource identity, redistribution rights, failure behavior, and cross-platform
packaging are verified end to end.

## License

The R source code is licensed under the MIT License. Any lexical resources added
in future releases will retain their own component-level licenses, notices, and
provenance; placement in this repository will not relicense those resources as
MIT.
