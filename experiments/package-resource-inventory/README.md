# Cross-platform package resource-inventory audit

Status: development CI gate; not final release evidence

`validate-package-resource-inventory.R` exercises the package boundary that an
installed-only test cannot observe. Starting from a clean package tree, it:

1. builds the ordinary source package;
2. verifies the declared resource, notice, provenance, copyright, and inventory
   members in that source archive;
3. installs the source archive with `R CMD INSTALL --build` to create the
   platform package format;
4. verifies the same bytes in the platform archive and clean installed library;
5. rejects any undeclared file under installed `extdata`; and
6. emits a JSON record containing the environment and run-specific source and
   platform archive identities.

The validator uses only base R plus the package's existing `digest` and
`jsonlite` dependencies. It refuses to reuse an audit directory and validates
archive member paths before extraction. Repository-only `experiments/` and
`legal/` directories must not enter either package archive.

Run it with a destination that does not exist:

```sh
Rscript --vanilla \
  experiments/package-resource-inventory/validate-package-resource-inventory.R \
  /path/to/ldfreq \
  /private/tmp/ldfreq-package-resource-audit
```

Release-R CI runs the same script on Ubuntu, macOS, and Windows after the normal
package check. The required aggregate therefore fails if any platform package
changes or omits a declared member. The generated archive hashes identify that
individual run; ordinary `R CMD build` and `R CMD INSTALL --build` output is not
claimed to be byte-reproducible. Final release evidence still requires a named
candidate, preserved logs and artifacts, and the recorded maintainer decision.
