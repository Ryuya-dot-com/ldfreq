# Public API surface audit

Status: pre-CRAN audit for package version 0.2.0

Audited: 2026-08-27

This repository-only record checks whether each exported function has a clear
role, result boundary, batch relationship, standard R interaction, and
analysis-ready extraction path. It is not installed with the package or
rendered by pkgdown.

## Decisions

- Keep the 26 exported function names unchanged after the 0.2.0 naming reset.
- Add no convenience alias and no new exported extractor solely to shorten
  component access.
- Use custom `print()` only where an object-specific header or bounded display
  materially improves a raw list or result table.
- Use package `plot()` methods only when one explicit scale or selection rule
  prevents unlike measurements from being compared silently. Every package
  plot method returns the plotted data invisibly.
- Do not add package `summary()` methods. Long result objects are already
  analysis-ready data frames; composite objects already expose a component
  explicitly named `summary` beside coverage, exclusions, diagnostics, and
  provenance. A generic that returned only one component would make it too
  easy to report a score without its denominator or coverage boundary.
- Do not add `as.data.frame()` methods for composite objects. Choosing one of
  several lossless tables implicitly would discard information. Users should
  select `$results`, `$tokens`, `$summary`, `$lookup`, `$coverage`, or another
  named component deliberately.

## Export inventory

| Export | Role and return boundary | Batch relation | Print | Plot | Analysis-ready access |
|---|---|---|---|---|---|
| `lexdiv_metric_ids()` | Core metric ID character vector | Catalog used by both core calls | Base | No | Vector |
| `lexdiv_content_overlap()` | Annotated content-word overlap composite | Pair operation; no batch inference | Overlap method | No: denominators differ by measure | `$summary`, `$coverage`, term and exclusion tables |
| `lexdiv_lemmatize()` | Adds explicit lemma/UPOS layers to `lexdiv_tokenization` | Tokenization object remains document-scoped | Tokenization method | No | `$tokens`, `$provenance` |
| `lexdiv_flemmatize()` | Adds explicit flemma layer to `lexdiv_tokenization` | Tokenization object remains document-scoped | Tokenization method | No | `$tokens`, `$provenance` |
| `lexdiv_grid()` | Bounded ordered list of method specifications | Feeds a plan, not documents | Concise grid method | No | List elements remain complete specs |
| `lexdiv_as_documents()` | Adapts named/tidy/quanteda tokens to a plain named list | Creates the batch boundary | Base | No | Plain named list |
| `lexdiv_length_evidence()` | Evidence registry data frame | Not document data | Base data-frame | No | Data frame |
| `lexdiv_methods()` | Method registry data frame | Shared by single and batch calls | Base data-frame | No | Data frame with list-column parameters |
| `lexdiv_metrics()` | One-row-per-metric long data frame | Paired with `lexdiv_metrics_batch()` | Result method | Single selected metric | Data frame |
| `lexdiv_metrics_batch()` | Document-major long metric data frame | Explicit batch form | Batch-result method | Single selected metric | Data frame |
| `lexdiv_metrics_text()` | Core results plus token audit and preprocessing | Document-scoped; callers batch explicitly | Text-result method | Delegates to unchanged `$results` | `$results`, `$token_audit`, `$preprocessing` |
| `lexdiv_overlap_ids()` | Overlap measure ID character vector | Shared by both pair operations | Base | No | Vector |
| `lexdiv_plan()` | Deduplicated bounded request plan | Shared by profile calls | Concise plan method | No | `$specifications` and plan identity fields |
| `lexdiv_presets()` | Preset registry data frame | Shared by profile calls | Base data-frame | No | Data frame |
| `lexdiv_profile()` | One-row-per-request long result data frame | Paired with `lexdiv_profile_batch()` | Profile-result method | Single selected request/metric | Data frame |
| `lexdiv_profile_batch()` | Document-major request-profile data frame | Explicit batch form | Profile-batch method | Single selected request/metric | Data frame |
| `lexdiv_screen()` | Independent token-floor screen data frame | Accepts single or batch profile rows | Base data-frame | One selected screen | Data frame |
| `lexdiv_spec()` | One normalized method/parameter request | Feeds grids/plans | Concise spec method | No | Named list fields |
| `lexdiv_tokenize()` | Lossless token rows and preprocessing provenance | Document-scoped | Tokenization method | No | `$tokens`, `$provenance` |
| `lexdiv_term_overlap()` | Exact term-set overlap composite | Pair operation; no batch inference | Overlap method | No: denominators differ by measure | `$summary`, `$counts`, optional term tables |
| `lexdiv_variant_ids()` | Variant registry data frame | Not document data | Base data-frame | No | Data frame |
| `lexdiv_variant_metrics()` | Cross-definition result data frame | Document-scoped | Variant-result method | No: families and scales differ | Data frame |
| `lexdiv_widen()` | Pure long-to-wide transformation | Preserves document IDs when present | Wide-result method | No | Data frame |
| `nj8_profile()` | Level summary, lookup, coverage, provenance, diagnostics | Paired with `nj8_profile_batch()` | Level-profile method | One weighting and scale | Named component tables |
| `nj8_profile_batch()` | Document-major level-profile composite | Explicit batch form | Batch-level method | No: document selection must be explicit | Named component tables with `document_id` |
| `tubelex_profile()` | Frequency/prevalence summary, lookup, coverage, provenance | Document-scoped | TUBELEX method | Token/type coverage | Named component tables |

## Documentation and reuse gate

The audit requires all 26 exports to have an installed help alias, an explicit
value section, and an executable example. Shared help topics are acceptable
when aliases, usage, argument ownership, and return types remain unambiguous.
Every help topic must appear in the pkgdown reference index.

Composite-result help must name every analysis table and warn when interpreting
the primary summary without coverage or denominator information would be
unsafe. Plot help must state the selected scale and invisible return table.
Internal identity, caching, and release records must not become an implicit
analysis column or a public-site page.

## Findings resolved in this audit

1. Raw list printing for `lexdiv_spec`, `lexdiv_grid`, and `lexdiv_plan`
   exposed long canonical identity strings and made plans difficult to scan.
   Their new print methods show bounded request/method/parameter tables, keep
   the full object unchanged, and return it invisibly.
2. `lexdiv_metrics_text()` contained an unchanged `lexdiv_results` table but
   did not support the same safe single-metric plot interaction. Its plot
   method now delegates to `$results` and returns the plotted data invisibly.
3. No default plot was added for overlap results, cross-definition variants,
   or multi-document NJ8 profiles. A generic chart would conceal denominator,
   scale, family, or document-selection differences; their named tables are
   the intended inputs to caller-controlled graphics and statistical models.

## Release gate

Before the first CRAN submission, regenerate this inventory from `NAMESPACE`
and fail review if an export is missing, undocumented, absent from pkgdown, or
lacks an explicit reusable-data path. Re-run examples, vignettes, the offline
smoke test, the complete pkgdown build, and `R CMD check` after any S3 change.
