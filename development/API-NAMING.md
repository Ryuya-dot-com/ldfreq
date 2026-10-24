# API naming conventions

General analysis functions use `lexdiv_`. Resource-specific operations use the
resource name (`nj8_`, `tubelex_`, `morpholex_`, `bnccoca_`, `morphynet_`).
This distinction identifies a resource dependency, not a different code license.

- Operations use action before object: `compare_annotations`, `compare_ngrams`,
  `build_ngram_reference`, `sort_concordance`, `screen_lengths`.
- Result constructors and summaries use nouns: `metrics`, `study_table`,
  `concordance`, `keyness`, `ngram_profile`, `concordance_dispersion`.
- `_text` means raw text; `_batch` means separately identified documents.
  Never infer these distinctions from string length or whitespace.
- `_ids` returns character identifiers. Catalog tables use `methods`,
  `presets` or `resource_info`.
- An argument selects a variation of one operation. Use S3 methods when an
  input/result class identifies an implementation; keep separate functions
  when combining them would hide distinct inputs, meanings or missingness.
- Retain documented compatibility aliases when changing a public name. Do not
  change an old name's return type to make it fit a new convention.

## Compatibility in 0.5.0.9001

| Canonical usage | Compatible earlier usage |
|---|---|
| `lexdiv_compare_ngrams()` | `lexdiv_ngram_compare()` |
| `lexdiv_build_ngram_reference()` | `lexdiv_ngram_reference_build()` |
| `lexdiv_sort_concordance()` | `lexdiv_concordance_sort()` |
| `lexdiv_screen_lengths()` | `lexdiv_screen()` |
| `lexdiv_methods(scope = "variants")` | `lexdiv_variant_ids()` |
| `lexdiv_metrics(tokens, plan = plan)` | `lexdiv_profile(tokens, plan)` |

The four renamed functions are exact aliases, including defaults and returned
objects. The other two routes already share the same implementation. Examples
use canonical names; prior scripts and saved results remain supported. The
resource-profile and general `profile` names retain their established meaning
in local-window, reference-lookup and compatibility contexts.

For an added API, check the operation, input contract, result type, resource
identity and compatibility route, then keep NAMESPACE, help, examples,
API-SURFACE.md, tests, NEWS and pkgdown navigation consistent.
