# Contributing to ldfreq

Proposed public functions should use a consistent, discoverable vocabulary
and include help, examples, and tests for the behavior they introduce.

`ldfreq` treats a lexical metric as a measurement contract, not just a formula.
Changes to metric definitions, defaults, missingness, parameter handling, or
output identity therefore require matching tests and specification updates.

## Local verification

From the repository root, build and check the source package:

```sh
R CMD build .
R CMD check --no-manual ldfreq_*.tar.gz
```

This installs the package before running its tests. Some example recipes source
other installed example files, so an uninstalled `testthat::test_local()` run
does not exercise the same file lookup and can fail to locate those files.
Use the installed-package check for the complete suite. When only documentation
or build records change, retain earlier test evidence for unchanged code and
verify the affected documents or artifacts instead of repeating the full suite.

Do not add production lexical resources without a separate review of source
identity, redistribution rights, installed notices, package size, and failure
behavior. Tests and examples must run without network access.
