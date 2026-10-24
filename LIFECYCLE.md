# API and measurement lifecycle

## Current distributions

The current development release is **0.5.0.9001**. It includes all
current guide workflows. Stable **0.4.0** remains available as a
separate fixed release. Pin the package archive used in an analysis and
use `citation("ldfreq")` to cite that exact version. New releases do not
replace earlier fixed archives.

The [release-scope
guide](https://ryuya-dot-com.github.io/ldfreq/articles/release-scope.html)
explains supported inputs, optional integrations and compatibility. The
[NEWS](https://ryuya-dot-com.github.io/ldfreq/news/index.html) records
changes by version.

## Reference data in 0.5.0.9001

Third-party reference data are optional downloads with their own
licenses. Use
[`lexdiv_resource_info()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_resources.md)
to inspect the terms, source, version and hash, then explicitly use
`lexdiv_download_resources(..., accept_license = TRUE)`. Ordinary
computation and installation never download resources. The MIT code can
be installed and used without obtaining MorphoLex or any other reference
snapshot. Existing resource-based analyses need this one-time setup; the
reference data bytes and measurement definitions are unchanged.

Rendered guides are published on the website. The compact package
archive contains guide sources and installed example scripts; it does
not include rendered outputs from the separately licensed reference
data.

## Metric identities and saved results

Package version, metric method ID, metric-contract version, result
schema, preprocessing and reference-resource identity are separate.
Preserve them with the original inputs and complete results. Changes in
a package version do not relabel the methods or values inside an earlier
saved result.

The current catalog has thirteen metrics: eleven defaults, opt-in
`mtld_ma`, and experimental `expected_ttr_d`. MTLD-MA adds a separate
method definition; it does not change ordinary MTLD or existing presets.
Core contract 0.2.0 continues to describe the unchanged existing
definitions and result schema. Adding an opt-in method does not
invalidate plans for unchanged definitions.

For historical analyses, package 0.3.0 changed ordinary MTLD from a
minimum-ten factor rule to no minimum and advanced the core contract
from 0.1.0 to 0.2.0. The old rule remains an explicit variant. Do not
mix old and new MTLD values under one method label. Plans from the old
contract must be recreated; reading old RDS results does not require
rewriting their identities or values.

Expected-TTR D remains an experimental curve estimator, not CLAN VOCD.
Formula agreement, length sensitivity, sampling reliability and
proficiency validity are distinct claims. The [selection
guide](https://ryuya-dot-com.github.io/ldfreq/articles/choosing-metrics.html)
provides evidence and conditions for choosing among the implemented
measures.

## Naming and compatibility

General analysis functions use `lexdiv_`; resource-specific operations
retain resource prefixes. Operation names put the action before its
object. `_text` identifies raw text and `_batch` identifies separately
named documents.

| Current name | Earlier compatible name |
|----|----|
| [`lexdiv_compare_ngrams()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngram_compare.md) | [`lexdiv_ngram_compare()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngram_compare.md) |
| [`lexdiv_build_ngram_reference()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngram_reference_build.md) | [`lexdiv_ngram_reference_build()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngram_reference_build.md) |
| [`lexdiv_screen_lengths()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md) | [`lexdiv_screen()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md) |
| [`lexdiv_sort_concordance()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_concordance.md) | [`lexdiv_concordance_sort()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_concordance.md) |

These four pairs are exact aliases, with the same arguments and results.
Study-table, concordance, collocation and keyness functions are public
APIs; their earlier installed source helpers remain compatibility
wrappers. Saved old records remain accepted by the corresponding
operations. No implicit migration overwrites a saved record.

Ordination, readability, L2SCA import and teaching workflows remain
explicitly sourced recipes. Their guides define the required inputs and
external tools. Pin the package archive when using these scripts. Their
availability does not imply automatic linguistic annotation or
educational interpretation.

## Change policy

A change to a formula, threshold rule, token selection or missingness
meaning requires an identifiable method or contract change and migration
documentation. An added optional operation should preserve existing
defaults and result shapes. Document public renamings with compatibility
aliases before removing old names. Errors in input types must be
reported rather than silently coerced to scores; intended categorical
metadata and legitimate missing results retain their roles.
