# Contributing

Run focused tests for a change, then `R CMD build` and `R CMD check` for package
integration. Reference-dependent checks require an explicitly prepared resource
cache; the core package works without it. See `experiments/prepare-resources.R`.
Tests never download reference data implicitly.

The public API audit is `Rscript development/audit-public-api.R .`.
The resource inventory audit is documented in `experiments/package-resource-inventory`.
Method definitions, missing-value rules and resource identities are in `inst/spec`.
Research reproduction code and aggregate outputs are under `experiments`;
restricted source corpora and per-person data must remain outside this repository.

API conventions are in [API-NAMING.md](API-NAMING.md), and the export inventory
is in [API-SURFACE.md](API-SURFACE.md). Update user-facing help and examples with
behavioral changes. Preserve reproducible identities and compatibility for
previously saved results.
