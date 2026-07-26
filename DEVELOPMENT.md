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
- publish a release checklist and archive reproducibility evidence.

## Resource admission

NGSL, TUBELEX-EN, and Open English WordNet remain separate future work. A
resource-backed feature is not complete until its exact source, version, hash,
license, notice, lookup contract, coverage diagnostics, offline behavior, and
source/installed/binary package membership have all been verified.
