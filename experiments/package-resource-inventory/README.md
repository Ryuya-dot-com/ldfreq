# Package resource inventory checks

The source archive contains MIT code/documentation and an attributed BSD-3-Clause
tokenizer example. Third-party reference data are optional, separate downloads.
Schema 2.0.0 records their pinned identities and archive members; only actual
code/license files appear in `package_members`.

`validate-package-resource-inventory.R` builds a source package without compiled
vignettes, creates a platform package, installs it into a clean library and
compares audited files byte for byte. The six authored MASC-format files and
aggregate corpus-stability results are explicitly enumerated. It rejects
undeclared data, notices, missing or modified members and unsafe archive paths.
The normal runtime must not fetch data implicitly. The source release omits
compiled walkthroughs containing reference-data output; rendered guides are
published separately on the documentation site under the stated resource terms.

```sh
Rscript experiments/package-resource-inventory/check-resource-inventory.R .
Rscript experiments/package-resource-inventory/validate-package-resource-inventory.R . /tmp/new-inventory-audit
```

An optional third argument supplies the exact release source archive to audit,
instead of building another archive. The output records source, platform and
installed identities, environment and completed checks. Run-specific archive
hashes do not imply byte-reproducible builds across toolchains.
