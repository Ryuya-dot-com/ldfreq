# Contributing to ldfreq

`ldfreq` treats a lexical metric as a measurement contract, not just a formula.
Changes to metric definitions, defaults, missingness, parameter handling, or
output identity therefore require matching tests and specification updates.

## Local verification

From the repository root, run:

```r
testthat::test_local()
```

Then build and check the source package:

```sh
R CMD build .
R CMD check --no-manual ldfreq_*.tar.gz
```

Do not add production lexical resources without a separate review of source
identity, redistribution rights, installed notices, package size, and failure
behavior. Tests and examples must run without network access.
