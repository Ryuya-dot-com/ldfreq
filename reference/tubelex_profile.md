# Coverage-aware TUBELEX frequency and prevalence profile

Look up surface-form frequency, video prevalence, and channel prevalence
in the byte-pinned TUBELEX-EN Treebank aggregate bundled with ldfreq.

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
tokenizer retains contractions such as `don't`, whereas the bundled
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
validation; and `"resource_error"` means the bundled resource failed an
availability or integrity check. `failure_reason` is missing for `"ok"`
and `"empty"`, and otherwise gives the specific failure reason. Coverage
is missing when its denominator is zero or the lookup could not be
completed.

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
[`vignette("tubelex-input", package = "ldfreq")`](https://ryuya-dot-com.github.io/ldfreq/articles/tubelex-input.md)
for the optional external tokenization recipe and its reproducibility
boundaries.

## Examples

``` r
# Explicit illustrative Treebank units; no automatic tokenization is implied.
tokens <- c("I", "do", "n't", "think", "it", "'s", "John", "'s", "book")
profile <- tubelex_profile(tokens)
profile$summary
#>   weighting eligible_items matched_items coverage mean_zipf   sd_zipf
#> 1     token              9             9        1  6.601118 0.7946027
#> 2      type              8             8        1  6.533295 0.8211448
#>   mean_video_prevalence mean_channel_prevalence
#> 1            -0.3360080               -0.345417
#> 2            -0.3712797               -0.376663
profile$coverage
#> $input_tokens
#> [1] 9
#> 
#> $input_types
#> [1] 8
#> 
#> $eligible_tokens
#> [1] 9
#> 
#> $eligible_types
#> [1] 8
#> 
#> $matched_tokens
#> [1] 9
#> 
#> $unmatched_tokens
#> [1] 0
#> 
#> $matched_types
#> [1] 8
#> 
#> $unmatched_types
#> [1] 0
#> 
#> $token_coverage
#> [1] 1
#> 
#> $type_coverage
#> [1] 1
#> 
profile$lookup
#>   query_index  term lookup_term matched resource_word   count videos channels
#> 1           1     I           i    TRUE             i 3794340  83952    50926
#> 2           2    do          do    TRUE            do 1105372  78492    48095
#> 3           3   n't         n't    TRUE           n't  909491  72651    44756
#> 4           4 think       think    TRUE         think  438105  51625    32474
#> 5           5    it          it    TRUE            it 2917104  95070    56204
#> 6           6    's          's    TRUE            's 2400420  93407    54909
#> 7           7  John        john    TRUE          john   21926   6320     4743
#> 8           8    's          's    TRUE            's 2400420  93407    54909
#> 9           9  book        book    TRUE          book   56208  12058     8921
#>       zipf video_prevalence channel_prevalence
#> 1 7.342551      -0.10018255        -0.12815245
#> 2 6.806923      -0.12938784        -0.15299159
#> 3 6.722213      -0.16297120        -0.18423958
#> 4 6.404994      -0.31135029        -0.32355139
#> 5 7.228367      -0.04617071        -0.08532559
#> 6 7.143702      -0.05383470        -0.09544910
#> 7 5.104394      -1.22343298        -1.15895586
#> 8 7.143702      -0.05383470        -0.09544910
#> 9 5.513220      -0.94290747        -0.88463833
profile$provenance$formula_parameters
#> $token_total
#> [1] 171805865
#> 
#> $source_vocabulary_size
#> [1] 613309
#> 
#> $video_total
#> [1] 105733
#> 
#> $channel_total
#> [1] 68405
#> 

profiles <- tubelex_profile_batch(list(essay_a = tokens, essay_b = c("the", "book")))
profiles$essay_a$summary
#>   weighting eligible_items matched_items coverage mean_zipf   sd_zipf
#> 1     token              9             9        1  6.601118 0.7946027
#> 2      type              8             8        1  6.533295 0.8211448
#>   mean_video_prevalence mean_channel_prevalence
#> 1            -0.3360080               -0.345417
#> 2            -0.3712797               -0.376663

# Typography alone can be normalized explicitly after token preparation.
tubelex_profile(c("it", "\u2019s"), normalization = "tubelex_apostrophe")$lookup
#>   query_index term lookup_term matched resource_word   count videos channels
#> 1           1   it          it    TRUE            it 2917104  95070    56204
#> 2           2   ’s          's    TRUE            's 2400420  93407    54909
#>       zipf video_prevalence channel_prevalence
#> 1 7.228367      -0.04617071        -0.08532559
#> 2 7.143702      -0.05383470        -0.09544910

contract_files <- c(
  "tubelex-frequency-profile-contract.json",
  "lexical-resource-lookup-contract.json"
)
contract_paths <- system.file("spec", contract_files, package = "ldfreq")
stopifnot(all(nzchar(contract_paths)))
basename(contract_paths)
#> [1] "tubelex-frequency-profile-contract.json"
#> [2] "lexical-resource-lookup-contract.json"  
```
