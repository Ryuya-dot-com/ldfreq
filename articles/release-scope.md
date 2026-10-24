# Release scope and compatibility

`ldfreq` 0.4.0 is a fixed stable GitHub distribution for tracing lexical
descriptions from original texts and counting conditions to research
tables and reports. It is not a CRAN release. Install the named archive
or fixed tag in the [installation
instructions](https://ryuya-dot-com.github.io/ldfreq/index.html#installation);
keep that archive, original inputs and complete saved results for later
reuse.

Development **0.4.0.9001** adds a separately sourced [occurrence-MCA
example](https://ryuya-dot-com.github.io/ldfreq/articles/lexical-ordination.html#occurrence-mca),
absent from stable 0.4.0. It uses the existing optional `ca` package,
with complete indicator rows, equal occurrence weights, unadjusted
inertia and original source links. Category coding and inference remain
the researcher’s responsibility. It adds no exported API, required
dependency, core calculation or bundled resource. The stable-release
tables below continue to describe the fixed 0.4.0 archive.

Development **0.4.0.9002** lets that MCA plot use separately named
display labels for long occurrence IDs. The original IDs, saved fits and
numerical results are unchanged; save the display mapping with the
complete analysis record.

Development **0.4.0.9003** adds a separately sourced [textbook
progression
example](https://ryuya-dot-com.github.io/ldfreq/articles/textbook-progression.md).
It joins saved concordance matches to ordered pages, Units and selected
sections, retaining missing material and the scope available after a
declared teaching introduction. It is a descriptive example, not an
automatic learning-effect assessment.

Development **0.4.0.9004** adds a separately sourced [DDL preparation
example](https://ryuya-dot-com.github.io/ldfreq/articles/ddl-materials.md).
It writes selected, reviewed phrase occurrences and teacher-written
prompts to learner HTML, a separate teacher CSV and a complete private
record. Original sources and pending decisions remain intact; it does
not conduct or evaluate a classroom lesson.

Development **0.4.0.9006** adds eight public entry points for research
tables, concordance/dispersion, collocations and keyness. These
interfaces preserve the previous counting and missingness rules; they do
not broaden the statistical claims or add an analyzer. A new concordance
class supports [`plot()`](https://rdrr.io/r/graphics/plot.default.html).
Original sourced names and plain-list records remain supported. The
updated specialist guides use these public calls; install the 9006
archive to follow them.

## What is stable, experimental or an example?

Stable means the documented computational and compatibility contract is
maintained. It does not mean that a measure is valid for every
population, text length, language or research claim. Method, schema,
preprocessing and resource contract versions are separate from the
package version.

| Surface | Status in 0.4.0 | Boundary |
|----|----|----|
| Eleven default lexical-diversity metrics; explicit Maas/MTLD variants; local MATTR; specifications, plans, batches, tables and plots | Stable computational contracts | Ordered tokens and explicit parameters determine the result. Short-input failures remain `NA` with reasons; advisory length guidance is not a precision guarantee. |
| English/Unicode tokenization, supplied lemma/POS/flemma annotations, exact overlap and reference coverage | Stable documented contracts | English rules are explicit options. Unicode tokenization is not a Japanese morphological analyzer. Supplied labels and dictionaries require their own justification. |
| NJ8 levels, TUBELEX frequency, supplied lexical norms, adjacent n-gram frequencies/comparisons and paired scored responses | Stable documented contracts | Preserve the declared resource, units, denominator and coverage. Neither high coverage nor frequency establishes vocabulary knowledge or proficiency. The n-gram reference *builder* remains experimental. |
| Bundled NJ8, TUBELEX, MorphoLex and BNC/COCA resources; MorphyNet reader/example excerpt | Fixed attributed resource versions | The release does not change the resource bytes or rights. MorphoLex includes noncommercial restrictions. Consult the installed notices and resource manifest before redistribution. A fixed resource does not make every downstream analysis stable. |
| Expected-TTR D | Experimental estimator, explicit opt-in | Excluded from default metrics and presets. It fits an exact expectation curve; it is not CLAN VOCD, and CLAN equivalence is not established. |
| Family profiles; annotation import/alignment/evaluation; MASC/quanteda adapters; n-gram reference builder; ambiguity and contextual-model review/evaluation/baselines; adjective–noun dependencies | Experimental interfaces | Existing help and interface versions continue to apply. Models and human decisions remain distinct. Alignment and replay checks do not establish analyzer or model accuracy. |
| Study tables, corpus search/dispersion, collocation, keyness, readability, traced syntax and CA/classical MDS | Documented, explicitly sourced examples | Installed helpers are not exported APIs. Pin the package archive and preserve complete records. Examples connect existing calculations to source occurrences and reporting; they do not automatically choose a model or justify an inferential claim. |

Stable 0.4.0 has 57 exports; development 0.4.0.9006 has 65. The eight
new entry points have a documented initial interface; their formulas and
analysis scope are those of the earlier examples. Stable release status
does not remove the experimental labels in help or change the
`stability` column returned by
[`lexdiv_methods()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md).
An example helper is located with
[`system.file()`](https://rdrr.io/r/base/system.file.html) and loaded
with [`sys.source()`](https://rdrr.io/r/base/sys.source.html) as its
guide shows; it has no separate `?function` help entry. See
[`?ldfreq`](https://ryuya-dot-com.github.io/ldfreq/reference/ldfreq-package.md)
for the input and guide map.

## Languages and external tools

| Route | Verified scope and requirements | Limits |
|----|----|----|
| English core and profiles | Authored counts, numerical reference fixtures, input/batch/missingness checks and saved-record replay; required packages are `digest` and `stringi`. | A tokenizer/lexical unit must suit the research question. NJ8 and bundled TUBELEX target English; generic tokens do not establish Treebank alignment. |
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

MCA, nonmetric MDS, Japanese readability, a universal ability scale and
a new model-fitting API are not included. Their absence does not leave
an unfinished step in the documented CA/classical-MDS or reporting
workflows.

## Moving from an earlier version

**From 0.3.0.9019:** calculations, exports, schemas, helpers and
resources are unchanged. New calculations record package version 0.4.0.
Reopening an older RDS must preserve its original calculation version
and session information; do not replace those fields with the currently
installed version.

**From 0.1.0 or 0.2.0:** the intervening changes below affect
interpretation or compatibility. Retain the old archive and results
before computing again.

1.  Core contract 0.2.0 uses no-minimum MTLD, with method ID
    `mtld_seq_bidir_dirmean_lt_nomin_linear_tail_v1`. The former min10
    method remains explicitly available in
    [`lexdiv_variant_metrics()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_variant_metrics.md).
    Do not mix their values under one unlabeled MTLD column. See the
    migration section of
    [`?lexdiv_metrics`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
    and the [formula-variant
    help](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_variant_metrics.md).
2.  Default metric results have eleven rows. Canonical and
    length-comparison presets contain eleven and thirteen requests.
    [`lexdiv_metric_ids()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
    still lists twelve supported metrics, including experimental
    expected-TTR D. Select that estimator explicitly when it is part of
    the study design.
3.  Recreate old specifications and plans with current
    [`lexdiv_spec()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
    and
    [`lexdiv_plan()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
    before new calculations. Specification hashes include the core
    contract version, even for an unchanged formula. Read saved results
    without editing their IDs or values; comparison and plot checks
    reject unlike measurement identities.
4.  Preprocessing contract 0.1.0 objects must be recreated from original
    text and explicit annotations. The current 0.4.0 contract retains
    valid 0.3.0 objects and 0.2.0 Unicode objects. A legacy object
    without recorded textstem dictionary identity cannot establish
    strict lemma comparability. Do not manually fill provenance fields
    to bypass validation.
5.  TUBELEX contract 0.2.0 rejects known tokenizer mismatch by default.
    Prepare compatible terms, or explicitly record a sensitivity
    analysis with `tokenization_mismatch = "allow"`. Character-vector
    alignment remains unverified. NJ8 contract 0.2.0 defaults to the
    bundled list when `wordlist` is omitted or `NULL`; explicit external
    lists retain their own identity.
6.  Version 0.2.0 corrected cancellation in near-saturated expected-TTR
    D without changing its estimator or method ID. Keep the package
    version as well as the method ID when comparing historical
    calculations. Details and the numerical correction are recorded in
    NEWS.

Pre-1.0 breaking changes require a minor-version increment and an
explicit migration explanation. Exported functions, arguments, methods
and schemas require a documented deprecation cycle before removal. The
package-level [lifecycle
policy](https://github.com/Ryuya-dot-com/ldfreq/blob/main/LIFECYCLE.md)
also separates formula, preprocessing and resource changes from cosmetic
fixes.

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

The release evidence distinguishes successful computation/replay,
agreement with independent numerical or software references, and
empirical measurement validity. The first two do not prove the third.
The documentation checks use independent development sessions; they are
not a usability study with novice researchers. Population-level claims
still need an appropriate research design.
