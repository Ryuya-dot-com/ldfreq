# Add flemmas from a caller-supplied AntBNC lemma list

Maps token surface forms to family lemmas (flemmas) using a local AntBNC
lemma-list file. No resource is bundled or downloaded. Unknown forms
retain their normalized surface form so that downstream analyses keep
them visible.

## Usage

``` r
lexdiv_flemmatize(
  x,
  resource,
  overrides = NULL,
  normalization = "nfkc_lower",
  resource_version = NULL,
  override_version = NULL
)
```

## Arguments

- x:

  An object created by
  [`lexdiv_tokenize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md).

- resource:

  Path to a caller-supplied AntBNC lemma-list text file in
  `headword<TAB>-><TAB>form...` format.

- overrides:

  Optional data frame with unique `form` and `flemma` columns. Overrides
  are applied after resource lookup and before identity fallback.

- override_version:

  Optional caller-declared version label for a non-empty override table.
  Supplying it without overrides is an error. Strict flemma overlap
  treats overrides without a version as unverifiable.

- normalization:

  `"nfkc_lower"` applies NFKC, trimming, and locale-fixed English
  lowercasing to resource entries, overrides, and queries. `"identity"`
  performs exact matching.

- resource_version:

  Optional caller-declared resource version label. Strict flemma overlap
  treats a missing version as unverifiable; the package does not infer
  content identity from file bytes.

## Details

Flemma counting groups inflected forms without distinguishing part of
speech. It is therefore not interchangeable with a POS-sensitive lemma
analysis.

The parser requires unique normalized headwords and a deterministic
one-to-one form-to-headword mapping. The output records whether each
token used `"antbnc"`, an explicit `"override"`, or normalized-surface
`"identity"` fallback. Identity fallback prevents an unknown resource
form from disappearing before an off-list or diversity analysis.

The flemma adapter, parser, and AntBNC resource IDs are fixed by ldfreq.
`resource_version` and `override_version` are caller labels, not
byte-identity proofs. They are included in public provenance and may
appear in overlap comparability output. Labels must be path-free and
non-sensitive; callers must not put paths, credentials, private hashes,
or machine-specific details in them. When strict flemma overlap is
requested, resource versions must be present and equal. If neither side
used overrides, their override setting is comparable; otherwise both
sides need the same non-missing override version.

The raw AntBNC list is only an approximation to New Word Level Checker
(NWLC) processing. NWLC uses a manually modified AntBNC mapping aligned
to its selected word lists. Use
[`nj8_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md)
conflict diagnostics and explicit overrides rather than claiming
unverified NWLC equivalence.

## Resource and path boundary

The AntBNC payload is read only from the path supplied by the caller. It
is never bundled, downloaded, or copied into the result. Its local file
name, absolute directory, and content hash are not retained in public
provenance. A source-byte digest is used only for caching, is never
copied to public provenance or results, and is not used to decide
overlap comparability. Package-generated file-access errors do not echo
the supplied path.

## Value

The input `lexdiv_tokenization` object with three token columns:
`flemma`, `flemma_matched`, and `flemma_match_rule`. A
`flemma_annotation` record is added to preprocessing provenance with
fixed adapter/parser/resource IDs, caller-declared versions,
match/override/fallback counts, and coverage.

## See also

[`lexdiv_preprocessing`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md),
[`nj8_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md)

## Examples

``` r
fixture <- tempfile(fileext = ".txt")
writeLines(
  c(
    "cat\t->\tcat\tcats",
    "see\t->\tsaw\tsee",
    "the\t->\tthe"
  ),
  fixture,
  useBytes = TRUE
)

tokens <- lexdiv_tokenize("The cats saw an unknownword.", case = "lower")
flemmas <- lexdiv_flemmatize(
  tokens,
  fixture,
  resource_version = "synthetic-help-fixture"
)
unlink(fixture)

flemmas$tokens[, c(
  "surface", "flemma", "flemma_matched", "flemma_match_rule"
)]
flemmas$provenance$flemma_annotation[c(
  "backend_id", "backend_version", "resource_id", "resource_version",
  "matched_coverage"
)]
lexdiv_metrics_text(flemmas, unit = "flemma", metrics = "ttr")

if (FALSE) { # \dontrun{
# Replace the synthetic fixture with a legitimately obtained AntBNC list.
real_flemmas <- lexdiv_flemmatize(
  lexdiv_tokenize("Interesting studies went outside."),
  "/path/to/antbnc_lemmas_ver_004.txt",
  overrides = data.frame(
    form = "interesting",
    flemma = "interesting"
  ),
  resource_version = "004",
  override_version = "analysis-overrides-v1"
)

lexdiv_metrics_text(real_flemmas, unit = "flemma", metrics = "ttr")
} # }
```
