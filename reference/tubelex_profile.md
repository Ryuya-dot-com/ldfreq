# Coverage-aware TUBELEX frequency and prevalence profile

Reference snapshots require a prior explicit download; see
[`lexdiv_download_resources`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_resources.md)
for terms and cache setup.

Look up surface-form frequency, video prevalence, and channel prevalence
in the byte-pinned TUBELEX-EN Treebank aggregate downloaded separately
for ldfreq.

## Usage

``` r
tubelex_profile(
  terms, normalization = "tubelex", tokenization_mismatch = "error"
)

tubelex_profile_batch(
  documents, normalization = "tubelex", tokenization_mismatch = "error",
  id_col = "document_id", terms_col = "terms", max_rows = 1e6
)

# S3 method for class 'tubelex_profile'
print(x, ...)
```

## Arguments

- terms:

  A plain ordered character vector, or an object returned by
  [`lexdiv_tokenize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
  only with explicit mismatch opt-in. Order and duplicate tokens are
  retained. Each vector element is one complete lookup term; a single
  string containing whitespace triggers a warning because it may be raw
  prose. For text-frequency analysis, prepare tokens using the
  resource's Penn Treebank segmentation and record the external
  tokenizer and version. Character vectors are caller assertions; their
  segmentation is not verified by the package.

- normalization:

  `"tubelex"` applies the recorded NFKC, trim, and locale-fixed English
  lowercase query transform. `"identity"` performs an exact case- and
  normalization-sensitive lookup. The explicit `"tubelex_apostrophe"`
  option additionally maps right single quotation marks and primes to
  ASCII apostrophes internally or at clitic starts. This term-level
  typography transform does not split contractions or establish Treebank
  compatibility. The default transform is unchanged.

- tokenization_mismatch:

  `"error"` rejects objects from
  [`lexdiv_tokenize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md),
  whose word segmentation differs from Treebank. `"allow"` explicitly
  permits them for sensitivity analysis and records the mismatch. This
  option does not verify character-vector input.

- documents:

  An explicitly named list of document term vectors or tokenization
  objects, or a data frame with distinct IDs and a terms list-column.
  Invalid term vectors receive document-local invalid profiles;
  structural errors and known tokenizer mismatches stop the batch.

- id_col, terms_col:

  ID and term list-column names for data-frame input.

- max_rows:

  Positive whole-number bound on combined lookup and summary rows,
  checked before resource loading.

- x:

  A `tubelex_profile` object.

- ...:

  Additional arguments passed to the summary-table print method.

## Details

The general-purpose
[`lexdiv_tokenize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
tokenizer retains contractions such as `don't`, whereas the cached
resource uses Treebank units such as `do` and `n't`. A spelling can
match a resource entry even when segmentation is inappropriate: 100
percent coverage does not verify alignment. Do not extract the surface
column merely to bypass the object mismatch check. An explicitly allowed
mismatch measures sensitivity to a different segmentation; it is not a
recommended automatic frequency-analysis pipeline.

Unmatched terms remain missing. They are not converted to zero counts or
to a maximum-sophistication category. Summary means are therefore
conditional on matched terms and must be interpreted beside token and
type coverage.

The token-weighted row retains repetition in the input. The
type-weighted row uses each distinct normalized lookup term once. The
output records both the original and normalized type counts so that
normalization-induced collisions remain visible.

TUBELEX is a general YouTube subtitle frequency space. Its values are
relative to that corpus and are not direct measures of proficiency,
writing quality, academic register, or context-independent lexical
sophistication. In particular, lexical employability (using words in
communication) requires learner-level criteria; neither frequency nor
video/channel prevalence demonstrates an individual's meaning recall,
processing speed or appropriate contextual use.

## Locales and resource failures

The cached CSV is decoded as UTF-8 independently of `LC_CTYPE`. C/POSIX
sessions can use ASCII or explicitly UTF-8-encoded query terms. An
accented character may be displayed with a Unicode escape in a C console
even though its bytes and lookup result are correct.

For `status = "resource_error"`, printing reports the failure reason.
For `schema_mismatch`, it also shows the failed schema checks and
current `LC_CTYPE`, and suggests checking resource integrity and UTF-8
decoding. Older loaders could fail in non-UTF-8 locales; this hint does
not establish the cause of every schema failure. The machine-readable
reason and diagnostics remain available without printing.

## Reading lookup and summary values

The lossless `lookup` table contains:

- `term`, `lookup_term`:

  The caller's original term and its effective normalized query.

- `matched`, `resource_word`:

  Whether the query matched and the exact resource key used.

- `count`:

  Raw token occurrences in the pinned TUBELEX aggregate.

- `videos`, `channels`:

  Numbers of source videos and channels containing the matched resource
  entry.

- `zipf`:

  Smoothed per-billion token frequency. It is the base-10 logarithm of
  `1e9 * (count + 1) / D`, where `D` equals
  `token_total + source_vocabulary_size`.

- `video_prevalence`:

  Smoothed log video proportion. It is `log10((videos + 1) / Dv)`, where
  `Dv` equals `video_total + 2`.

- `channel_prevalence`:

  Smoothed log channel proportion. It is `log10((channels + 1) / Dc)`,
  where `Dc` equals `channel_total + 2`.

The `formula_parameters` component of `provenance` stores the four
normalization constants used to form these three denominators. Video and
channel prevalence values are normally non-positive because they are
base-10 logarithms of smoothed proportions no greater than one; a value
closer to zero denotes wider prevalence. The `summary` means and Zipf
standard deviation use matched rows only. Read them beside
`eligible_items`, `matched_items`, and `coverage`; token weighting
retains repetition, whereas type weighting keeps the first occurrence of
each distinct normalized lookup term.

## Formal contracts

The public profile contract is installed as
`tubelex-frequency-profile-contract.json`; exact lookup formulas and
field roles are installed as `lexical-resource-lookup-contract.json`.
Locate either with `system.file("spec", filename, package = "ldfreq")`.
The public profile contract is normative for version 0.2.0. The lookup
file is the versioned, non-exported implementation contract at contract
version `0.1.0`; its installation does not make the lookup helper a
supported exported API. The resource's license, provenance, and runtime
integrity records are installed separately from the measurement
contract.

## Reading status

`status = "ok"` means a non-empty valid input was looked up
successfully; `"empty"` means a valid zero-term input produced typed
empty output; `"invalid_input"` means the supplied terms failed
validation; and `"resource_error"` means the cached resource failed an
availability or integrity check. `failure_reason` is missing for `"ok"`
and `"empty"`, and otherwise gives the specific failure reason. Coverage
is missing when its denominator is zero or the lookup could not be
completed. Missing cache files return
`failure_reason = "resource_unavailable"`; changed manifest or data
bytes return `"hash_mismatch"`. This applies to both single-document and
batch calls. Inspect `lexdiv_resource_info("tubelex")` and its license
before explicitly calling
`lexdiv_download_resources("tubelex", accept_license = TRUE)`. An
incomplete or modified version directory must be removed explicitly
before downloading it again. Profile calls never download or repair
files implicitly.

## References

Nohejl et al. (2025). Beyond Film Subtitles: Is YouTube the Best
Approximation of Spoken Vocabulary? *Proceedings of COLING 2025*.
<https://aclanthology.org/2025.coling-main.641/>.

## Value

A `tubelex_profile` list containing `status`, `failure_reason`, token-
and type-weighted `summary`, lossless `lookup` rows, `coverage`,
versioned `provenance`, and `diagnostics`. The print method returns `x`
invisibly.

`tubelex_profile_batch()` returns an input-ordered named list of
complete `tubelex_profile` objects, including every document's coverage
and provenance. It loads one immutable resource snapshot per batch, has
no global cache, and gives the same per-document values as separate
calls. Access, for example, `profiles[["essay_a"]]$summary`; do not
concatenate documents to avoid repeated resource loading. An empty batch
returns a named empty list.

## See also

[`lexdiv_tokenize`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md),
[`lexdiv_metrics_text`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md),
[`tubelex_diagnostics`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_diagnostics.md);
[getting started
guide](https://ryuya-dot-com.github.io/ldfreq/articles/getting-started.html)
for batch profiles; [tubelex input
guide](https://ryuya-dot-com.github.io/ldfreq/articles/tubelex-input.html)
for the optional external tokenization recipe and its reproducibility
boundaries.

## Examples

``` r
# Optional data: review and explicitly download these resources first.
if (all(lexdiv_resource_info(c("tubelex"))$available)) {
# Explicit illustrative Treebank units; no automatic tokenization is implied.
tokens <- c("I", "do", "n't", "think", "it", "'s", "John", "'s", "book")
profile <- tubelex_profile(tokens)
profile$summary
profile$coverage
profile$lookup
profile$provenance$formula_parameters

contract_files <- c(
  "tubelex-frequency-profile-contract.json",
  "lexical-resource-lookup-contract.json"
)
contract_paths <- system.file("spec", contract_files, package = "ldfreq")
stopifnot(all(nzchar(contract_paths)))
basename(contract_paths)
}
#> [1] "tubelex-frequency-profile-contract.json"
#> [2] "lexical-resource-lookup-contract.json"  
```
