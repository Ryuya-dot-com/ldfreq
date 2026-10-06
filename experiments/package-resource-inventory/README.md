# Cross-platform package resource-inventory audit

Status: technical inventory gate; not a final maintainer release decision

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

The five resource records cover TUBELEX, NJ8, MorphoLex, Nation BNC/COCA and
the nine-row MorphyNet excerpt. The excerpt is `example-only`, not the full
database. They are distinct from the six authored MASC-format
example files. The latter are explicitly enumerated in the validator and undergo
the same source/platform/installed byte comparison. They are MIT examples, not
redistributed corpus data. Unexpected files under `extdata` or `licenses` fail
the audit. The shared COPYRIGHTS index is declared once, under TUBELEX.

Manifest schema 1.2.0 permits null `manifest_sha256` and `content_sha256` when
there is no separate manifest or decoded-content checksum. Every shipped file
still has a byte count and SHA-256 in `package_members`. For MorphoLex and
Nation, `provenance_path` names the RDS containing the provenance; for the
MorphyNet excerpt it names the original-row mapping.

Run it with a destination that does not exist:

```sh
Rscript --vanilla \
  experiments/package-resource-inventory/validate-package-resource-inventory.R \
  /path/to/ldfreq \
  /private/tmp/ldfreq-package-resource-audit
```

An optional third argument names an already-built exact source archive. This
reuses compiled guides when their source inputs are unchanged; the inventory
must match the checkout. To exercise rejection cases without rebuilding:

```sh
Rscript experiments/package-resource-inventory/check-resource-inventory.R .
```

Release-R CI runs the same script on Ubuntu, macOS, and Windows after the normal
package check. The required aggregate therefore fails if any platform package
changes or omits a declared member. The generated archive hashes identify that
individual run; ordinary `R CMD build` and `R CMD INSTALL --build` output is not
claimed to be byte-reproducible. Final release evidence still requires a named
candidate, preserved logs and artifacts, and the recorded maintainer decision.
