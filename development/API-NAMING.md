# Public API naming

This document fixes the naming rules for exported R functions from `ldfreq`
0.2.0 onward. It controls discoverability and vocabulary only; measurement
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
- An orthogonal option belongs in an argument only when all choices share the
  same validation, identity, missingness, disclosure, and return-shape
  contract. Otherwise a separate, explicit function remains preferable to a
  shorter but ambiguous dispatcher.
- New aliases require a demonstrated compatibility need. Synonymous aliases
  are not added solely to save keystrokes because they enlarge autocomplete,
  help, testing, and deprecation surfaces.

## Version 0.2.0 migration

The package had not been submitted to CRAN when this one-time canonical reset
was made. The previous pre-release names are removed rather than retained as
aliases.

| Before 0.2.0 | Canonical from 0.2.0 | Reason |
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
