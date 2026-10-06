# Reproducible Lexical Diversity and Frequency Profiles

The ldfreq package computes explicitly versioned lexical-diversity
metrics from ordered tokens and provides separate auditable raw-text,
annotation, lexical-unit, Maas/MTLD sensitivity, and TUBELEX
frequency-profile surfaces. It also provides local MATTR window and
positional-exposure diagnostics, exact term and annotated-content-word
type overlap, many-document coverage by one explicit reference term set,
caller-supplied lexical-norm profiles with separate resource and
annotation coverage, plus New JACET 8000 level profiles using the
bundled table or an external copy.
[`bnccoca_data`](https://ryuya-dot-com.github.io/ldfreq/reference/bnccoca_data.md)
supplies Nation's BNC/COCA Level 6 family membership and separate
supplementary lists under CC BY-SA 4.0, for use with
[`lexdiv_family_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_family_profile.md).
[`morphynet_read_derivations`](https://ryuya-dot-com.github.io/ldfreq/reference/morphynet_read_derivations.md)
reads local MorphyNet formation relations, preserving source and target
POS, affixes and alternatives. Only a nine-row CC BY-SA 3.0 teaching
excerpt is bundled, not the full database.
[`morpholex_data`](https://ryuya-dot-com.github.io/ldfreq/reference/morpholex_data.md)
provides the bundled MorphoLex English worksheet tables and provenance.
Those data and their dictionary use CC BY-NC-SA 4.0 (noncommercial use,
attribution and applicable ShareAlike conditions), separately from the
MIT license of the independent R code. Adjacent bigram/trigram
extraction and caller-supplied reference frequencies retain segment
boundaries, original positions, opportunity totals and coverage.
[`lexdiv_ngram_compare`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngram_compare.md)
compares reference choices using the same target items, retaining
coverage and common-set differences from a baseline. Result rows retain
method, parameter or denominator, schema, and contract provenance.

## Details

Start with
[`lexdiv_metrics()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
for explicit tokens,
[`lexdiv_metrics_text()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
for one raw or annotated text,
[`lexdiv_metrics_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
for multiple tokenized documents,
[`lexdiv_tokenize_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md)
and
[`lexdiv_metrics_text_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md)
for named raw texts or explicit ID/text tables,
[`lexdiv_as_documents()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md)
for tidy or quanteda token containers,
[`lexdiv_widen()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md)
for a pure wide transformation,
[`lexdiv_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
for explicit parameter variants,
[`lexdiv_mattr_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_mattr_profile.md)
for one or more canonical MATTR trajectories,
[`lexdiv_variant_metrics()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_variant_metrics.md)
for separately contracted Maas/MTLD sensitivity variants, or
[`lexdiv_term_overlap()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_overlap.md)
for two explicit term vectors,
[`lexdiv_content_overlap()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_overlap.md)
for two UPOS-annotated texts, or
[`lexdiv_reference_coverage()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_reference_coverage.md)
for several term vectors against one reference set, or
[`lexdiv_norm_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile.md)
and
[`lexdiv_norm_profile_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile_batch.md)
for exact matching against a caller-supplied numeric lexical-norm table,
or
[`lexdiv_ngrams()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md),
[`lexdiv_ngram_reference()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
and
[`lexdiv_ngram_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
for adjacent sequences and local reference counts, or
[`nj8_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md)
for exact and cumulative pedagogical frequency levels from the bundled
or an external list, or
[`tubelex_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md)
for coverage-aware corpus-relative frequency and prevalence.

## Corpus scope

The functions can describe native-speaker and learner texts, including
English writing and prepared speech transcripts. Within-population
register variation, matched L1/L2 comparisons and reference-resource
sensitivity are distinct applications. Participant knowledge scores are
not required for descriptive corpus analysis. Retain
language-background, corpus, register, task and author/speaker metadata
separately and link them to results by document ID. The raw-text helpers
do not infer these attributes or parse corpus XML and transcription
conventions. Document repeated speakers and turn boundaries when
preparing spoken data.

Native-speaker status does not establish a universal proficiency or
quality norm. The bundled TUBELEX resource describes YouTube subtitle
word forms; it does not certify the first-language background or ability
of each speaker.

## Start here

Choose the entry point from the form of data you already have:

- One raw character string:

  Use
  [`lexdiv_metrics_text()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md).
  It calls the explicit tokenizer and returns its preprocessing audit
  beside the metric rows.

- One ordered token vector:

  Use
  [`lexdiv_metrics()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md).
  The core will not change case, remove tokens, or lemmatize.

- Several tokenized documents:

  Use
  [`lexdiv_metrics_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)
  with a named list or an explicit ID and token-list-column data frame.

- Several documents and one reference set:

  Use
  [`lexdiv_reference_coverage()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_reference_coverage.md)
  for separate token- and type-weighted directional coverage with
  explicit numerators and denominators.

- One-token-per-row or quanteda input:

  Use
  [`lexdiv_as_documents()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md)
  to create the explicit named-list boundary.

- A local MATTR trajectory:

  Use
  [`lexdiv_mattr_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_mattr_profile.md)
  with a MATTR-only plan to retain each window value and position's
  exposure.

- A caller-supplied lexical-norm table:

  Use
  [`lexdiv_norm_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile.md)
  or
  [`lexdiv_norm_profile_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile_batch.md)
  for conditional observed matched-only means and separate resource,
  value, and annotation coverage.

- Two texts or term sets:

  Use
  [`lexdiv_term_overlap()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_overlap.md)
  for explicit terms, or
  [`lexdiv_content_overlap()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_overlap.md)
  for UPOS-annotated content words.

- Adjacent word combinations:

  Use
  [`lexdiv_ngrams`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
  with explicit segment IDs and original positions, then construct or
  import a local reference with
  [`lexdiv_ngram_reference()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md)
  and look up target sequences with
  [`lexdiv_ngram_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngrams.md).
  Corpus text is not bundled.

- Chunked reference construction:

  Use
  [`lexdiv_ngram_reference_build`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngram_reference_build.md)
  to accumulate exact counts from whole-document chunks without
  retaining all occurrence tables. Distinct types and the document
  roster stay in memory.

- Reference-choice sensitivity:

  Use
  [`lexdiv_ngram_compare`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngram_compare.md)
  to retain separate reference coverage and compare frequencies on
  common target items, with explicit baseline differences and
  denominators.

- Supplied corpus annotations:

  Use
  [`lexdiv_read_masc`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_read_masc.md)
  for the supported MASC Penn layout, and
  [`lexdiv_as_quanteda()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_read_masc.md)
  to use quanteda without retokenizing or closing excluded positions.
  Both retain source mappings; see the annotated-corpora guide for the
  verified scope.

- Japanese and other external annotations:

  Use
  [`lexdiv_import_annotations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md)
  to verify complete supplied surfaces against original segment text and
  retain source positions and dictionary declarations. See the Japanese
  annotations guide for an optional gibasa/UniDic recipe; bundled
  frequency resources remain English.

- A corpus-relative reference profile:

  Use
  [`tubelex_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md)
  for bundled TUBELEX frequency/prevalence, or
  [`nj8_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md)
  for New JACET 8000 levels.

In the help pages, a *token* is one occurrence. In core metric results,
a *type* is one distinct, exactly equal token string supplied to the
core; Unicode-equivalent spellings remain different unless preprocessing
normalized them first. In a resource profile, a *type* is instead one
distinct effective lookup term under that profile's documented lookup
identity. A *lemma* is an annotation-provided base form. An AntBNC
*flemma* is a family grouping that does not preserve part-of-speech
distinctions. *Coverage* is the proportion of eligible tokens or types
that received a usable annotation or resource match; it is not a
proficiency score.

## Input boundary

The public core accepts ordered, already-tokenized character vectors. It
does not infer token boundaries, change case, normalize Unicode
spelling, remove tokens, or lemmatize. Batch inputs must carry explicit
unique document IDs.
[`lexdiv_tokenize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md),
[`lexdiv_lemmatize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md),
and
[`lexdiv_flemmatize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_flemmatize.md)
form a separate preprocessing contract so that these choices cannot
silently change core methods.

## Results and provenance

Metric results are long-form data frames. Read `status` and
`missing_reason` before `value`. Each row records the method, metric
contract, result schema, requested and effective parameters, token/type
counts, the versioned `below_quality_floor` field, and method
diagnostics. Batch, profile, and screen layers add separate envelopes
without changing the core record.

## Formal contracts

Human-readable help explains normal use; installed JSON contracts are
the auditable source for exact formulas, domains, schemas, normalization
rules, and resource boundaries. The main files are:

- `lexical-diversity-contract.json`

- `ldfreq-preprocessing-contract.json`

- `lexical-overlap-contract.json`

- `reference-coverage-contract.json`

- `mattr-profile-contract.json`

- `norm-profile-contract.json`

- `adjacent-ngram-contract.json`

- `lexical-diversity-variant-contract.json`

- `lexical-level-profile-contract.json`

- `tubelex-frequency-profile-contract.json`

Locate them with `system.file("spec", filename, package = "ldfreq")`;
schemas and hand-case fixtures are installed in the same directory.
Contract status is also returned in ordinary result or provenance
fields, so users do not need to rely on an R attribute alone.

## Preprocessing and lexical units

The raw-text adapter records Unicode normalization, case handling,
number retention, offsets, and source/processed text hashes. Lemma
analyses record the lemma backend and version. Any UPOS tags require
their own explicit backend ID and version; these values are never
defaulted from the lemma backend. Caller-supplied AntBNC flemma analyses
record fixed package adapter/parser IDs, caller-declared resource and
override versions, matching rules, and identity fallback. They do not
expose the local resource file name or a content hash. Declared labels
are public provenance and must contain no paths, secrets, or private
hashes. Surface/lemma/flemma and all/content-word choices are returned
with token-level exclusion reasons and coverage in an envelope that does
not alter the normative metric result schema.

## Exact lexical overlap

[`lexdiv_term_overlap()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_overlap.md)
computes Jaccard, Dice, directional A-in-B and B-in-A coverage, and the
overlap coefficient from distinct exact terms.
[`lexdiv_content_overlap()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_overlap.md)
first selects `ADJ`, `ADV`, `NOUN`, `PROPN`, and `VERB` from two
validated annotated tokenizations. It never infers UPOS or lemmas. Each
row retains its numerator, denominator, direction, unit, and contract
identity; document-level coverage separately counts missing UPOS,
non-content UPOS, and missing selected units. The comparability table
discloses its label values in four columns: `component`, `value_a`,
`value_b`, and `matches`. Surface comparison uses tokenizer and UPOS
settings; lemma comparison also uses lemma annotation identity. Flemma
comparison instead adds its fixed adapter/parser and declared
resource/override settings and ignores lemma backend identity because it
consumes surface forms. Flemma resource versions must be present and
equal; override versions are required and compared only when overrides
are used. No file-content hash is a comparability key. The five measures
have different denominators and must not be reported as one
interchangeable generic percentage.

## Many-document reference coverage

[`lexdiv_reference_coverage()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_reference_coverage.md)
asks what proportion of each document's tokens and distinct types occurs
in one supplied reference term set. It uses exact membership with no
implicit tokenization, normalization, or annotation. Document repetition
affects token coverage but not type coverage; reference repetition
affects neither value. The document-major summary retains numerators,
denominators, match counts, status, and missing reasons. Exact term
details are opt-in. The measure does not validate the reference or
measure semantic similarity, plagiarism, proficiency, writing quality,
or reference quality.

## Caller-supplied lexical norms

[`lexdiv_norm_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile.md)
exact-matches caller-prepared terms against one caller-supplied data
frame and reports one row per measure and requested token/type
weighting. Means use observed matched values only. Resource coverage,
input-relative value coverage, and matched-key annotation coverage
remain separate, and OOV terms are not merged with matched keys whose
values are missing. Measure and resource metadata are returned as
provenance; they do not establish redistribution rights, construct
validity, population transfer, or comparability across unlike scales.
Exact terms are retained in the lookup table. The function performs no
download, implicit normalization, fuzzy matching, thresholding, or
composite scoring.

## Corpus-relative frequency

[`tubelex_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md)
retains original and normalized lookup terms, unmatched rows, token/type
coverage, and matched-only token/type-weighted summaries. TUBELEX values
are relative to a general YouTube subtitle corpus. They are not direct
measures of proficiency, writing quality, academic register, or
context-independent lexical sophistication.

## Lexical frequency levels

[`nj8_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md)
maps bundled or caller-supplied ranks to Levels 1–8 and reports exact
and cumulative token/type proportions beside off-list coverage. The
Level 8 cumulative proportion equals matched coverage because off-list
items remain in the denominator. The package bundles the versioned New
JACET 8000 table with JACET permission and source attribution; an
external list can be supplied explicitly. Flemma input exposes conflicts
between AntBNC families and New JACET headwords instead of silently
choosing one mapping.

## Direction and contract scale

Direction applies only within the exact method, parameters,
preprocessing, and sampling design. Values from different metric IDs are
not interchangeable.

|  |  |  |
|----|----|----|
| Metric ID | Contract scale | Conventional score direction |
| `ttr` | 0 to 1 | higher |
| `rttr` | 0 or greater; no finite upper bound | higher |
| `cttr` | 0 or greater; no finite upper bound | higher |
| `herdan` | 0 to 1 | higher |
| `maas` | 0 to \\1 / \ln(2)\\ (about 1.4427) | lower |
| `msttr` | 0 to 1 | higher |
| `mattr` | 0 to 1 | higher |
| `mtld` | 0 or greater; no finite upper bound | higher |
| `hdd` | 0 to 1 | higher |
| `expected_ttr_d` | greater than 0; no finite upper bound | higher |
| `yule_k` | 0 inclusive to 10,000 exclusive | lower |
| `yule_i` | 0 or greater; no finite upper bound | higher |

## Interpretation boundary

The methods primarily operationalize lexical variety and repetition.
They are indices used within the lexical-diversity research domain, but
no single score represents the full multidimensional lexical-diversity
construct. The metrics describe lexical-distribution properties of the
supplied tokens. They are not direct measures of language proficiency,
writing quality, reader response, or communicative effectiveness.
Inferring those constructs requires a separate validated study design
and cannot be justified by one score or by the versioned
`below_quality_floor` field.

Exact term/content-word overlap describes lexical sharing under the
selected unit and annotation. It is not a plagiarism detector or a
direct measure of semantic similarity, coherence, proficiency, or
writing quality.

## Quality screens

`below_quality_floor` and
[`lexdiv_screen()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
are advisory token-count evidence screens. Here, quality is a field name
retained for compatibility; it does not mean writing quality,
measurement validity, or reliability. The screens never change a value,
effective parameter, status, or document membership. Passing a screen
does not establish validity or reliability; failing one does not erase
an otherwise computable value.

## Versioned surfaces

The core metrics, raw-text preprocessing, lexical overlap, reference
coverage, generic lexical-norm profiles, variant metrics, lexical-level
profiles, and TUBELEX profile have separate versioned contracts. This
keeps a change in tokenization or resource matching from silently
redefining a core metric. Expected-TTR D is separately named and
explicitly distinguished from CLAN VOCD.

## Offline smoke test

After loading ldfreq, run the installed script returned by
`system.file("examples", "offline-smoke.R", package = "ldfreq")`. It
exercises single, batch, profile, local-MATTR, profile-batch,
term/content-word overlap, many-document reference coverage,
lexical-norm, lexical-level, and screen workflows without a network
connection or external runtime.

## See also

[`lexdiv_metrics`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md),
[`lexdiv_convenience`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_convenience.md),
[`lexdiv_preprocessing`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md),
[`lexdiv_flemmatize`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_flemmatize.md),
[`lexdiv_overlap`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_overlap.md),
[`lexdiv_reference_coverage`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_reference_coverage.md),
[`lexdiv_norm_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile.md),
[`lexdiv_norm_profile_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile_batch.md),
[`lexdiv_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md),
[`lexdiv_mattr_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_mattr_profile.md),
[`lexdiv_variant_metrics`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_variant_metrics.md),
[`nj8_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md),
[`tubelex_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md)

## Examples

``` r
metric_ids <- lexdiv_metric_ids()
head(metric_ids)
#> [1] "ttr"    "rttr"   "cttr"   "herdan" "maas"   "msttr" 

smoke_path <- system.file("examples", "offline-smoke.R", package = "ldfreq")
stopifnot(nzchar(smoke_path))
source(smoke_path, local = TRUE)

contract_files <- c(
  "lexical-diversity-contract.json",
  "ldfreq-preprocessing-contract.json",
  "lexical-overlap-contract.json",
  "reference-coverage-contract.json",
  "mattr-profile-contract.json",
  "norm-profile-contract.json",
  "norm-profile-batch-contract.json",
  "lexical-diversity-variant-contract.json",
  "lexical-level-profile-contract.json",
  "tubelex-frequency-profile-contract.json"
)
contract_paths <- system.file("spec", contract_files, package = "ldfreq")
stopifnot(all(nzchar(contract_paths)))
basename(contract_paths)
#>  [1] "lexical-diversity-contract.json"        
#>  [2] "ldfreq-preprocessing-contract.json"     
#>  [3] "lexical-overlap-contract.json"          
#>  [4] "reference-coverage-contract.json"       
#>  [5] "mattr-profile-contract.json"            
#>  [6] "norm-profile-contract.json"             
#>  [7] "norm-profile-batch-contract.json"       
#>  [8] "lexical-diversity-variant-contract.json"
#>  [9] "lexical-level-profile-contract.json"    
#> [10] "tubelex-frequency-profile-contract.json"
```
