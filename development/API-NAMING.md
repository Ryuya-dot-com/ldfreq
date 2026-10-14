# Public API naming

This document fixes the naming rules for exported R functions from the initial
`ldfreq` 0.1.0 release onward. It controls discoverability and vocabulary only; measurement
formulas, denominators, result schemas, and resource identities remain governed
by their feature-specific contracts.

## Rules

- General lexical-diversity and analysis operations use the `lexdiv_` prefix.
  The prefix prevents collisions with generic R names such as `metrics`,
  `profile`, `plan`, and `validate`.
- Resource-branded entry points begin with the shortest unambiguous public
  resource name, as in `nj8_profile()` and `tubelex_profile()`.
- Function names use lower-case snake case and normally contain no more than
  three semantic words after `lexdiv_`. A longer name is retained when removing
  a word would conceal a measurement boundary, as with
  `lexdiv_content_overlap()`.
- `_batch` is reserved for an explicit multi-document contract with distinct
  identifiers, row bounds, or result structure. It is not replaced by silent
  input-type guessing merely to shorten a name.
- Identifier catalogs end in `_ids`. The noun before `_ids` names the public
  family rather than its implementation table.
- Prefer an argument for a choice within one operation. Consider an S3 generic
  when known input/result classes identify specialized implementations. Methods
  may have different validators and result details: identical schemas are not
  a prerequisite for a common user-facing operation. The discriminator, shared
  meaning, method-specific arguments and return boundaries must be explicit.
  Preserve measurement identity, missingness, provenance and document boundaries;
  do not guess raw text versus tokens from string length or whitespace. Keep
  separate entry points when a common call would conceal different tasks or
  require silently ignored arguments.
- New aliases require a demonstrated compatibility need. Synonymous aliases
  are not added solely to save keystrokes because they enlarge autocomplete,
  help, testing, and deprecation surfaces.

## Pre-publication naming decision

The package had not been submitted to CRAN when this one-time canonical naming
decision was made. Earlier development names are removed rather than retained
as aliases; version 0.1.0 therefore exposes only the canonical vocabulary.

`lexdiv_mattr_profile()` retains the metric name because it exposes diagnostics
specific to the canonical MATTR method. A generic `lexdiv_stability_profile()`
would imply validated support across methods and inferential interpretations
that the package does not provide.

`lexdiv_norm_profile()` names a resource-neutral operation rather than one
construct such as familiarity or concreteness. Those identities belong in
measure rows, and a resource brand belongs in its own adapter. The name does
not imply that unlike measures are comparable or that the function computes a
lexical-sophistication score.

| Earlier development name | Canonical in 0.1.0 | Reason |
|---|---|---|
| `new_jacet8000_profile()` | `nj8_profile()` | avoids constructor-like `new_`; keeps the recognized NJ8 resource identity |
| `new_jacet8000_profile_batch()` | `nj8_profile_batch()` | applies the same resource name and retains the explicit batch contract |
| `tubelex_frequency_profile()` | `tubelex_profile()` | removes a redundant modifier from the sole TUBELEX profile entry point |
| `lexdiv_overlap_measure_ids()` | `lexdiv_overlap_ids()` | aligns public identifier-catalog names |

The corresponding resource-specific S3 classes use `nj8_profile`,
`nj8_profile_batch`, and `tubelex_profile`. The general
`lexical_level_profile` and `lexical_level_profile_batch` classes remain because
their print and plot contracts describe the result structure rather than the
resource adapter name.

## Review gate for another export

Before adding an exported function, reviewers should verify that:

1. an existing entry point cannot express the operation without weakening its
   contract;
2. the name identifies the operation or resource without repeating information
   already supplied by the package namespace;
3. `_batch`, `_ids`, and resource prefixes follow the rules above;
4. the name does not add another meaning to an already overloaded family word
   such as `profile`; and
5. `NAMESPACE`, help, examples, pkgdown navigation, tests, `NEWS.md`, and the
   offline smoke test use one canonical name; and
6. the return type, S3 interactions, and analysis-ready extraction path are
   recorded in `API-SURFACE.md`.

## 2026-10-14 readability review

All 57 exports were inspected against the implementation and help. Names range
from 11 to 28 characters, with a median of 19; nine have at least 25 characters.
These counts describe the surface, not an empirical usability threshold.
No novice-user study or API migration was performed. The 9006 publication
preserves all names and return contracts; the new-export freeze remains active.

| Finding | Evidence and direction for a future decision |
| --- | --- |
| `profile` hides different operations | `lexdiv_profile()` executes a method/parameter plan; MATTR profiles expose local windows; norm/resource profiles summarize lookups. Clarify the plan-execution role first. `lexdiv_run_plan()` is a candidate name, not an adopted replacement. |
| `_ids` does not predict one return shape | Installed calls confirm that `lexdiv_metric_ids()` and `lexdiv_overlap_ids()` return character vectors, whereas `lexdiv_variant_ids()` returns a six-column data frame. A full catalog name such as `lexdiv_variant_methods()` would better match the existing `lexdiv_methods()` vocabulary. Do not silently change the old return shape. |
| Short names can conceal the object of an action | `lexdiv_screen()` checks declared token-count floors on profile results; it does not assess general measurement or writing quality. A future name should identify that limited operation. |
| Action order varies | `lexdiv_compare_annotations()` is action-first; `lexdiv_ngram_compare()` and `lexdiv_ngram_reference_build()` group by object first. Document one predictable convention for future names, while considering existing family discovery and migration costs. This alone does not justify a mass rename. |
| Some length is informative | `lexdiv_metrics_text_batch()` identifies computation, raw-text input and a multi-document contract. Removing `_text` or `_batch` obscures a real input/result distinction. The compare/evaluate/align annotation operations also have distinct purposes and accepted inputs. |

Priority: clarify operation and return-shape expectations before cosmetic word
ordering or abbreviation. The first-use input map should introduce only the
relevant entry points. Help can explain distinctions but does not itself make
inconsistent naming consistent. A future rename decision must specify migration
and compatibility for already public GitHub users; lack of a CRAN release is not
permission to break their scripts. Candidate names above neither authorize
aliases nor change the current roadmap's implementation scope.

## Consolidation before standalone renaming

The subsequent 2026-10-14 request considers shared functions and argument-driven
output, following the existing `plot()` design. The detailed
[consolidation review](API-SURFACE.md#2026-10-14-api-consolidation-review)
distinguishes display choices, typed method dispatch, input multiplicity and
different analysis tasks. It supersedes the priority of standalone `run_plan`
and `variant_methods` renames above: first assess an explicit `plan` argument
on the existing metric entry point and a scope selector on the existing method
catalog. These are unimplemented alternatives, not additional exports.

A different return component or validator alone is not a reason to reject an
S3 method. Conversely, replacing several names with one name plus a collection
of unrelated mode strings does not establish simpler use. Compare the complete
call, discovery, invalid combinations, error messages and extraction path.
Do not reuse base graphics' `type` argument to select a scientific quantity;
a future quantity/component selector such as `view` has a different role.
Actual consolidation must preserve old named/positional calls and saved objects,
with a declared migration before retiring public names. Current exports, S3
registrations and the audit's summary/coercion restriction remain unchanged.
