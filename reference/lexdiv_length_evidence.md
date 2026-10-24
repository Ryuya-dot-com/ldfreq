# Inspect Context-Specific Token-Length Evidence

Returns the empirical-study and versioned-tool-guidance records that
motivate descriptive 50- and 100-token screens. The records do not
define computational domains, suppress values, or claim universal
validity cutoffs.

## Usage

``` r
lexdiv_length_evidence()
```

## Value

A data frame with one row per metric/evidence relationship. Columns
retain the source kind, metric and method scope, token floor, evidence
role, population, modality/genre, target-method equivalence status,
universal-cutoff flag, DOI, and URL.

## Details

The 100-token MTLD record concerns Koizumi's study of 20
lower-intermediate Japanese adolescent L2 English speakers. The 50-token
records from Zenker and Kyle concern 4,542 written L2 argumentative
essays and use 50 as the minimum observed segment length. TAALED 0.32
versioned usage guidance is identified separately as versioned tool
guidance rather than primary empirical evidence.

Method equivalence is not inferred from a shared metric label. In
particular, the evidence table does not assert that Gramulator, TAALED,
or another package's MTLD implementation is numerically identical to the
defined target method.

## Examples

``` r
evidence <- lexdiv_length_evidence()
evidence[evidence$metric_id == "mtld", ]
#>                                    evidence_id                 source_id
#> 1              koizumi_2012_mtld_spoken_l2_100              koizumi_2012
#> 2 zenker_kyle_2021_mtld_original_written_l2_50          zenker_kyle_2021
#> 5        taaled_0_32_mtld_original_guidance_50 taaled_0_32_documentation
#>               source_kind metric_id
#> 1         empirical_study      mtld
#> 2         empirical_study      mtld
#> 5 versioned_tool_guidance      mtld
#>                                                             method_scope
#> 1 Gramulator 5.0 raw bidirectional MTLD; target equivalence not asserted
#> 2                         MTLD Original; target equivalence not asserted
#> 5                                              TAALED 0.32 MTLD Original
#>   floor_tokens                     evidence_role
#> 1          100   context_specific_recommendation
#> 2           50    minimum_observed_stable_length
#> 5           50 use_with_confidence_tool_guidance
#>                                                      population
#> 1 20 lower-intermediate Japanese adolescent L2 English learners
#> 2                  4,542 ICNALE L2 English argumentative essays
#> 5                                 not one validation population
#>                                      modality_genre target_method_equivalence
#> 1 tape-mediated spoken responses on familiar topics              not_asserted
#> 2                      written argumentative essays              not_asserted
#> 5                             general tool guidance              not_asserted
#>   universal_cutoff                       doi
#> 1            FALSE 10.7820/vli.v01.1.koizumi
#> 2            FALSE 10.1016/j.asw.2020.100505
#> 5            FALSE                      <NA>
#>                                                                              url
#> 1 https://www.castledown.com/journals/vli/article/download/vli.v01.1.koizumi/213
#> 2            https://www.sciencedirect.com/science/article/pii/S1075293520300660
#> 5                                          https://pypi.org/project/taaled/0.32/
```
