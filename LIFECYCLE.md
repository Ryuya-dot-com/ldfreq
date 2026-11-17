# API and measurement lifecycle

## Current distribution

The current stable release is **1.0.0** (`remotes::install_github("Ryuya-dot-com/ldfreq@v1.0.0")`), documented at <https://ryuya-dot-com.github.io/ldfreq/>. Pin the package version used in an
analysis and run `citation("ldfreq")` to cite that exact release alongside the
measurement methods and reference datasets used in your study.

The `main` branch hosts the **2.0.0 development series (`1.99.0.9000`)**, documented separately under <https://ryuya-dot-com.github.io/ldfreq/dev/>.
It consolidates single-document and multi-document APIs into unified polymorphic
entry points, standardizes parameter names (`term_col`, `id_col`, `cache_dir`),
and contains incompatible changes relative to stable 1.0.0. Review the migration
notes in `README.md` and `NEWS.md` before upgrading an existing 1.x workflow.

## Stability and reproducibility commitments

`ldfreq` treats lexical measures as auditable measurement specifications rather
than opaque numbers:

- **Explicit method and parameter identities**: Every metric row records its
  versioned `method_id`, requested and effective parameters, token and type
  counts (`N`, `V`), calculation `status`, and `missing_reason`.
- **Recorded preprocessing choices**: Raw-text analyses (`lexdiv_tokenize()`,
  `lexdiv_metrics_text()`) default to `case = "lower"`,
  `tokenizer = "english"`, `normalization = "NFC"`, and `keep_numbers = FALSE`,
  and record every setting and SHA-256 text fingerprint in `$preprocessing`.
- **Saved-result integrity**: Exported corpus, annotation, and profile objects
  carry explicit S3 classes and integrity checks so accidental post-hoc edits
  cannot silently alter downstream tables or plots.
- **Deprecation policy**: In the stable 1.x release series, public functions, argument
  names, and documented result columns are maintained compatibly; any future
  breaking change requires a major version increment and migration notes in
  `NEWS.md`.

## Optional reference data

Third-party reference datasets are **not** bundled in the MIT-licensed package
archive. Use `lexdiv_resource_info()` to inspect each dataset's source, pinned
version, SHA-256 digest, and license terms, then download selected resources
explicitly with `lexdiv_download_resources(..., accept_license = TRUE)`.
Package installation and ordinary calculations never perform network requests.
