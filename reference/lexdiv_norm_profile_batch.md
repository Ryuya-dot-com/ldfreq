# Apply Caller-Supplied Lexical Norms to Multiple Documents

Applies the single-document lexical-norm calculation with one validated
shared resource. Every document retains its estimates, lookup rows,
coverage and missingness. Documents are not pooled into a corpus score.

## Usage

``` r
lexdiv_norm_profile_batch(documents, norms, key, measure_specs, resource,
  weightings = c("token", "type"), id_col = "document_id",
  terms_col = "terms", max_rows = 1e6)

# S3 method for class 'lexdiv_norm_profile_batch'
print(x, ...)
```

## Arguments

- documents:

  A plain named list of prepared term vectors, or a data frame with
  explicit character IDs and a list-column of term vectors. Each vector
  must satisfy
  [`lexdiv_norm_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile.md).
  Empty documents and zero-document batches are accepted; invalid terms
  stop the whole call and identify the document. A term is a lookup
  unit, not an unprocessed sentence.

- norms,key,measure_specs,resource,weightings:

  Exactly the arguments of
  [`lexdiv_norm_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile.md).
  One shared reference table, measure specification and requested
  weighting set apply to every document. Shared inputs are validated
  once per call. Matching and arithmetic are unchanged.

- id_col,terms_col:

  Distinct column names for a data-frame input. IDs must be unique,
  non-empty UTF-8 strings without missing values. Input document order
  is preserved. Extra columns are ignored; retain and join metadata by
  ID.

- max_rows:

  Positive whole-number bound on the combined rows of `lookup`,
  `summary`, and `coverage` for the entire batch, checked before lookup
  or result allocation. The default is one million.

- x:

  A `lexdiv_norm_profile_batch` object.

- ...:

  Additional arguments passed to
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html).

## Value

A `lexdiv_norm_profile_batch` list with six components:

- status:

  `"empty"` for zero documents and `"ok"` otherwise. This is a container
  status; inspect measure-level missingness in the tables.

- summary,lookup,coverage:

  The unchanged single-document tables with `document_id` prepended.
  Rows are document-major, then follow the single-document ordering.
  `result_order` restarts within each document. Empty documents retain
  all requested summary and coverage rows, with `empty_input` reasons.
  Zero documents give typed zero-row tables.

- provenance:

  Complete shared single-document provenance plus `batch_contract_id`,
  `batch_contract_version`, `batch_result_schema_id`,
  `batch_result_schema_version`, `document_count`, and ordered
  `document_ids`. Caller-supplied resource metadata describe the source;
  they do not authenticate its contents or rights.

- diagnostics:

  `documents` has one row per ID, document `status`, `input_terms`,
  `input_types` and planned rows for each table and their total. `batch`
  records resource/measure/weighting/document counts, global row plans,
  `max_rows`, preserved-order flags and the absence of imputation,
  automatic thresholds, pooling, composite scoring, parallelism and
  networking.

[`print()`](https://rdrr.io/r/base/print.html) displays at most 12
summary rows and returns `x` invisibly.

## Details

With \\D\\ documents, \\M\\ measures and \\W\\ weightings, the row
budget is `M * sum(document_term_counts) + 2 * D * M * W`. It is global,
not reset per document. Results are equivalent to calling the
single-document function on every valid vector and prepending its ID.
Malformed containers, duplicate IDs, invalid terms, invalid shared
inputs and excess rows raise R errors. Valid documents with no matches
or no observed values remain present.

Means remain conditional on observed matched values. Report resource
coverage, value coverage and annotation coverage, which have distinct
denominators. Keep token/type weighting and unlike constructs, units and
populations separate. No automatic normalization, resource download,
thresholds or scale conversion is performed. These data requirements
apply equally to native-speaker, learner and other corpora. A
low-frequency or unmatched word is not automatically difficult, and a
mean norm value does not establish proficiency.

For a different reference resource, make a separate call and retain that
resource's identity and coverage. Metadata supplied by the caller are
not a content fingerprint; save the actual table, measure specifications
and result with the original preprocessing and corpus metadata for
reproducibility.

## See also

[`lexdiv_norm_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile.md),
[`lexdiv_as_documents`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md),
[`lexdiv_tokenize_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md)

## Examples

``` r
# Project-authored numbers, not published familiarity norms.
norms <- data.frame(term = c("book", "read", "rare"),
  familiarity = c(6, 5, NA_real_))
specs <- data.frame(measure_id = "familiarity", value_column = "familiarity",
  construct_id = "subjective_familiarity", value_unit = "seven_point_rating",
  direction = "higher", language = "English", variety = "unspecified",
  population_id = "authored_demo", collection_year = "not_observed",
  valid_min = 1, valid_max = 7)
resource <- list(resource_id = "authored_norms", resource_version = "1",
  creator = "Example author", source_reference = "Authored demonstration",
  data_license = "Example numbers; no external dataset", transformation_id = "none",
  lookup_unit = "lowercase_surface",
  resource_key_normalization_id = "caller-prepared-v1")
documents <- list(essay = c("book", "book", "rare", "outside"),
  conversation = c("read", "book"), blank = character())
result <- lexdiv_norm_profile_batch(documents, norms, "term", specs, resource)
result$coverage
result$diagnostics$documents
print(result)
```
