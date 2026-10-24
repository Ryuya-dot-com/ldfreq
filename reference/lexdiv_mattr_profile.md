# Inspect the local MATTR trajectory and positional exposure

Decomposes canonical step-one MATTR specifications into their complete
moving windows. It returns each local TTR and the number and nominal
weight of windows containing each token position. The function does not
choose a window length, resample tokens, infer a minimum valid text
length, or turn the local profile into an inferential stability test.

## Usage

``` r
lexdiv_mattr_profile(tokens, plan, max_rows = 1e+06)

# S3 method for class 'lexdiv_mattr_profile'
print(x, ...)
```

## Arguments

- tokens:

  Input accepted by
  [`lexdiv_metrics()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md).
  Token strings are used for calculation but are not retained in the
  result.

- plan:

  A normalized
  [`lexdiv_plan()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
  containing only MATTR specifications. Use
  [`lexdiv_grid()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
  to request several window lengths.

- max_rows:

  Maximum combined rows across `summary`, `windows`, `exposure`, and
  `diagnostics`, checked before detail allocation.

- x:

  A `lexdiv_mattr_profile` object.

- ...:

  Additional arguments passed to
  [`print.data.frame()`](https://rdrr.io/r/base/print.dataframe.html).

## Value

A `lexdiv_mattr_profile` list. `summary` contains the unchanged
canonical
[`lexdiv_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
rows; `windows` contains local TTR values; `exposure` contains
position-only inclusion counts and weights; `diagnostics` reconciles the
local mean with the canonical result; and `provenance` records the
profile contract, schema, and plan identity. The print method returns
`x` invisibly.

## Details

For a document of \\N\\ tokens and requested window length \\w\\, the
`windows` table contains \\N-w+1\\ complete step-one windows when \\N
\ge w\\. Each local value is the number of distinct types in that window
divided by \\w\\. Their arithmetic mean reconciles with the unchanged
`mattr_sliding_step1_v1` core value.

The `exposure` table makes MATTR's positional weighting observable. A
token position belongs to fewer windows near the endpoints than in the
interior. `nominal_observation_weight` divides each position's exposure
count by \\(N-w+1)w\\ and sums to one for each available request. It is
an accounting weight, not a causal contribution assigned to the token at
that position.

Bestgen (2024,
[doi:10.1111/lang.12630](https://doi.org/10.1111/lang.12630) )
distinguishes dependence on text length from sensitivity to the
reduction parameter. Bestgen (2025,
[doi:10.1016/j.rmal.2024.100168](https://doi.org/10.1016/j.rmal.2024.100168)
) treats MATTR as especially useful for local fluctuation while
criticizing unqualified whole-text interpretation because positional
exposure is unequal. The function exposes those quantities but does not
declare any window or text length universally valid.

## Formal contract

The installed `mattr-profile-contract.json` file fixes the method reuse,
result topology, exposure formulas, missingness, privacy boundary, and
interpretation limits. Locate it with
`system.file("spec", "mattr-profile-contract.json", package = "ldfreq")`.

## Examples

``` r
methods <- lexdiv_methods()
mattr_method <- methods$method_id[methods$metric_id == "mattr"]
plan <- lexdiv_plan(
  presets = character(),
  grids = lexdiv_grid(
    mattr_method,
    "window_length",
    c(3, 5),
    request_id_prefix = "mattr"
  )
)
profile <- lexdiv_mattr_profile(
  c("a", "b", "a", "c", "d", "a", "e"),
  plan
)
profile$summary
profile$windows
profile$exposure
plot(profile, request_id = "mattr_1")
```
