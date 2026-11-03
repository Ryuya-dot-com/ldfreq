# Release scope and compatibility

Install the fixed release linked in the
[README](https://ryuya-dot-com.github.io/ldfreq/index.html#install).
Open guides matching that installation with `browseVignettes("ldfreq")`;
individual workflows do not require separate development releases. NEWS
labels unreleased changes separately. Earlier releases are retained for
reproducing earlier analyses.

## What is available?

| Surface | Interface and interpretation |
|----|----|
| Diversity metrics, method plans, batches and plots | Eleven default measures plus opt-in MTLD-MA and experimental expected-TTR D. Definitions and parameters are explicit; see [metric selection](https://ryuya-dot-com.github.io/ldfreq/articles/choosing-metrics.md) for length and reliability evidence. |
| English text and caller-supplied annotations | Explicit tokenization and lexical units. Unicode splitting does not replace a Japanese morphological analyzer. |
| Reference-vocabulary and morphology profiles | Optional fixed downloads under separate terms. See [reference data](https://ryuya-dot-com.github.io/ldfreq/articles/reference-data.md). User-supplied reference tables are also supported. |
| Research tables, concordances, dispersion, collocations and keyness | Public functions with documented input, denominator and missing-value contracts. |
| Readability, traced L2SCA syntax, CA/MDS/MCA, textbook progression and DDL preparation | Installed example workflows loaded as shown in their guides. They connect specialized external tools or researcher/teacher decisions to the saved analysis. |
| Annotation alignment/evaluation, contextual review, family profiles and n-gram reference construction | Interfaces carrying experimental labels retain those labels; see the individual help topics. |

A stable computational contract means a documented calculation is
maintained; it does not establish validity for every population or task.
Core method, preprocessing, resource and result-schema versions identify
different parts of the analysis. Keep them in saved records.

## Languages and external tools

| Route | Verified scope and requirements | Limits |
|----|----|----|
| English core and profiles | Authored counts, numerical reference fixtures, input/batch/missingness checks and saved-record replay; required packages are `digest` and `stringi`. | A tokenizer/lexical unit must suit the research question. NJ8 and optional TUBELEX target English; generic tokens do not establish Treebank alignment. |
| Japanese | Complete caller-supplied, source-aligned annotations; the guide names the optional gibasa/MeCab, dictionary and external Sudachi routes used in comparisons. | Specific pinned analyses support those examples. The package does not bundle a general Japanese parser, promise agreement between all dictionaries, or implement a Japanese readability score. |
| English readability | Flesch Reading Ease and Flesch–Kincaid Grade Level with visible sentence, word and syllable counts; an optional `nsyllable` route distinguishes dictionary matches and fallback estimates. | Unresolved pronunciation and exclusions stay explicit. Agreement with the formulas does not validate comprehension or grade placement in a new population. |
| English syntactic complexity | MLC, MLT and DC/C from traced original L2SCA outputs, with pinned Stanford tools/models, trees, query matches and original text. The authored offline example requires no parser. | The external runner requires the documented local Python/Java tools and separately acquired software/models. It is not a generic parser adapter or a parser-accuracy validation. |
| CA and classical MDS | CA uses optional `ca`; classical MDS uses [`stats::cmdscale()`](https://rdrr.io/r/stats/cmdscale.html) with Jaccard presence/absence or Hellinger distances. Records preserve exclusions, feature selection, eigenvalues and source links. | Dense-matrix limits apply. Negative eigenvalues and reconstruction are reported, without automatic correction. Configurations are descriptive, not ability scales or group-effect tests. |
| Repeated observations and model tables | Explicit planned observations, submitted documents and result specifications; an optional `lme4` example uses an ordinary selected table. | No automatic missing-data mechanism, outcome selection, model choice or causal interpretation is supplied. |
| MASC and other corpora | Mini-MASC 1.0 Penn annotations and supported modern MASC 3.0.0 document-header layouts. | Only 122 of 392 documents in the audited MASC 3.0.0 archive met the reader rules. Whole-corpus MASC/OANC support is not claimed; corpus access and rights remain separate. |

The package declares R \>= 4.1.0. Release checks cover the named source
archive on current R for Linux, macOS and Windows, R-devel on Linux, and
the R 4.1 minimum on Linux. Ordinary checks also exercise a genuine C
locale and resource reconstruction. C-locale checks do not cover every
Unicode-dependent path: tests requiring UTF-8 paths are explicitly
skipped. The fixed release’s evidence records give the actual R, OS and
dependency versions; these are tested configurations, not a promise
about every older OS or future dependency release.

The R 4.1 diagnostic omits optional `gibasa` and `textstem`, whose
current versions require newer R, and uses compatible Matrix, MASS and
readxl versions. Use a current R installation for their optional routes.
Python, Java, MeCab, external dictionaries and trained models are not
required for the core R calculations. Their specific guide checks are
separate from the R/OS matrix; the matrix does not execute every
externally supplied model or corpus.

## Reproducibility and compatibility across versions

`ldfreq 1.0.0` separates core formula identities, raw-text
preprocessing, and reference-dataset versions so that each choice
remains auditable over time:

1.  **Unified entry points**: Execute multi-parameter plans by passing
    `plan = plan` to
    [`lexdiv_metrics()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md),
    [`lexdiv_metrics_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md),
    [`lexdiv_metrics_text()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md),
    or
    [`lexdiv_metrics_text_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md).
    Inspect Maas and MTLD comparison definitions via
    `lexdiv_methods(scope = "variants")` and
    [`lexdiv_variant_metrics()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_variant_metrics.md).
2.  **Explicit defaults and opt-in measures**: Raw-text helpers default
    to `case = "lower"` and `tokenizer = "english"`. Default metric
    calls compute eleven established measures; moving-average MTLD
    (`mtld_ma`) and experimental deterministic expected-TTR *D*
    (`expected_ttr_d`) require explicit selection.
3.  **Optional reference-data cache**: Third-party datasets (`tubelex`,
    `nj8`, `morpholex`, `bnccoca`, `morphynet`) are downloaded
    explicitly once with
    `lexdiv_download_resources(..., accept_license = TRUE)` and verified
    by SHA-256 hash on read. Custom word lists and norm tables work
    offline without downloads.
4.  **Saved-record integrity**: Recreate plans with
    [`lexdiv_spec()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_plan.md)
    and
    [`lexdiv_plan()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_plan.md)
    when starting a new study, and never manually edit IDs or hashes
    inside saved RDS objects. Comparison, study-table, and plotting
    functions verify measurement identities so unlike specifications
    cannot be mixed silently.

The package-level [lifecycle
policy](https://github.com/Ryuya-dot-com/ldfreq/blob/main/LIFECYCLE.md)
documents compatibility commitments for the 1.x release series.

## Saving, citing and interpreting a result

Save original text, complete result objects, study metadata, selections
and review decisions together. Keep external resource/model/dictionary
identities and the calculation-session record. CSV display tables alone
cannot recover source spans, missingness or full provenance. The guides
include persistent RDS saving and separate-session reopening without
rerunning external models.

`citation("ldfreq")` derives the package version from the installed
copy. Report the version actually used for calculation, method IDs,
parameters, word unit, preprocessing and resource versions. Cite the
relevant methods and resources as well as the software. A later
reporting session does not change the identity of the stored
measurements. Calculation versions shown in saved example output
identify the original run; they are not replaced by the version used to
reopen or report that record.

For guidance on selecting a measure, see the [metric-selection
guide](https://ryuya-dot-com.github.io/ldfreq/articles/choosing-metrics.md),
which reports real-corpus length sensitivity, sampling reliability and
external implementation comparisons. Population-level claims require a
corresponding research design.
