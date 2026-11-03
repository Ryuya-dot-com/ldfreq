# API and measurement lifecycle

## Current distribution

The current stable release is **1.0.0**. Pin the package version used in
an analysis and run `citation("ldfreq")` to cite that exact release
alongside the measurement methods and reference datasets used in your
study.

The public development snapshot 1.0.0.9001 contains incompatible changes
relative to 1.0.0, including changed raw-text defaults and retired entry
points. It is not a stable 1.x release. See the migration instructions
in the README and NEWS before using it. A future stable release
containing incompatible changes requires a major version increment and
migration notes.

## Stability and reproducibility commitments

`ldfreq` treats lexical measures as auditable measurement specifications
rather than opaque numbers:

- **Explicit method and parameter identities**: Every metric row records
  its versioned `method_id`, requested and effective parameters, token
  and type counts (`N`, `V`), calculation `status`, and
  `missing_reason`.
- **Recorded preprocessing choices**: Raw-text analyses
  (`lexdiv_tokenize*()`, `lexdiv_metrics_text*()`) default to
  `case = "lower"`, `tokenizer = "english"`, `normalization = "NFC"`,
  and `keep_numbers = FALSE`, and record every setting and SHA-256 text
  fingerprint in `$preprocessing`.
- **Saved-result integrity**: Exported corpus, annotation, and profile
  objects carry explicit S3 classes and integrity checks so accidental
  post-hoc edits cannot silently alter downstream tables or plots.
- **Deprecation policy**: In the stable 1.x release series, public
  functions, argument names, and documented result columns are
  maintained compatibly; any future breaking change requires a major
  version increment and migration notes in `NEWS.md`.

## Optional reference data

Third-party reference datasets are **not** bundled in the MIT-licensed
package archive. Use
[`lexdiv_resource_info()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_resources.md)
to inspect each dataset’s source, pinned version, SHA-256 digest, and
license terms, then download selected resources explicitly with
`lexdiv_download_resources(..., accept_license = TRUE)`. Package
installation and ordinary calculations never perform network requests.
