# Reproducible Lexical Diversity and Frequency Profiles

Analyze lexical diversity in one or many texts, and describe vocabulary
using explicit reference lists. Start with
[`lexdiv_metrics_text()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
for one English text or
[`lexdiv_metrics_text_batch()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md)
for several. Results retain the words counted, analysis settings and
reasons for unavailable scores.

## Your first analysis

After installing the package, run:

    library(ldfreq)
    result <- lexdiv_metrics_text(
      "Cats chase cats and dogs.",
      tokenizer = "english", case = "lower", metrics = "ttr"
    )
    result$results

The text has five word occurrences (`N = 5`) and four distinct lowercase
forms (`V = 4`). Its type-token ratio is `4/5 = 0.8`, with
`status = "ok"`. TTR depends on text length; this is a small calculation
example, not evidence of writing ability. Use `result$token_audit` to
inspect the counted words. Other metrics can return `NA` when a text is
too short for their requested settings; read `missing_reason` beside the
value.

Open
[`?lexdiv_metrics_text`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md)
for the full help and
`example("lexdiv_metrics_text", package = "ldfreq")` to run its
examples. Several related functions share that help page, so its
examples also include optional annotation workflows. No model, Python or
optional R package is required for the first analysis above.

For a first document table, expected results, missing scores, a plot and
saving and reopening the complete record, see [Getting
started](https://ryuya-dot-com.github.io/ldfreq/articles/getting-started.html).
For your own files, see [TXT-folder and CSV
input](https://ryuya-dot-com.github.io/ldfreq/articles/english-tokenization.html#import-text-files).

## Connect the analysis steps

For ordinary text analyses, inspect `result$results` and
`result$token_audit`, then pass the result table to
[`lexdiv_widen`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_widen.md)
or plot document values with `plot(result, metric_id = "ttr")`. Save the
original text and complete result together as RDS.

For planned observations, start with token vectors and a
[`lexdiv_plan`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md).
Pass the complete output of
[`lexdiv_metrics_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md)`(tokens, plan = plan)`,
together with the schedule, submissions and reporting decisions, to
[`lexdiv_study_table`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_study_table.md).
Then use
[`lexdiv_study_model_data`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_study_table.md)
to select one response per observation for a modelling package. The
raw-text convenience functions do not accept a plan; their result tables
cannot replace this plan-based input.

For source-linked exploration, prepare complete annotations using
[`lexdiv_import_annotations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md).
A saved
[`lexdiv_concordance`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_concordance.md)
search feeds
[`lexdiv_sort_concordance`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_concordance.md),
[`lexdiv_concordance_dispersion`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_concordance.md),
[`lexdiv_collocations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_collocations.md)
or `plot(search, query_id)`. A
[`lexdiv_keyness`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_keyness.md)
comparison returns to source contexts with
[`lexdiv_keyness_concordance`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_keyness.md).
These operations use public functions without helper sourcing.

See the [input-to-output connection
map](https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report.html#connect-the-analysis-steps)
for complete workflows and the tables to inspect at each step.

## Choose a research question

Choose the route from your question, then inspect the counts and
availability beside its values. The guides specify the input tables and
any optional tools.

- How do counting choices change the same texts?:

  Start with document IDs and text in [From text to a research
  report](https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report.html).
  Compare paired metric rows, `N`, `V` and missing reasons, then return
  to the original text, counted forms and exclusions.

- How frequent are the words, or what matches a vocabulary list?:

  Use
  [`tubelex_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md)
  or
  [`nj8_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/nj8_profile.md)
  with prepared terms. Inspect lookup rows, resource identity and
  token/type coverage beside summaries. [Audit unmatched words and
  lexical
  units](https://ryuya-dot-com.github.io/ldfreq/articles/auditing-vocabulary-profiles.html);
  for your own norm table, follow [corpus reference
  profiles](https://ryuya-dot-com.github.io/ldfreq/articles/corpus-reference-profiles.html).

- What changes when counting families, roots or affixes?:

  Use complete annotations and a declared inventory in [Word families,
  roots and
  affixes](https://ryuya-dot-com.github.io/ldfreq/articles/word-families-and-affixes.html).
  Read shared occurrences, unresolved words and coverage; distinguish
  whole-document counts from counts on a resolved subset.

- Which words, contexts or positions characterize the documents?:

  Use complete source-aligned annotations for [concordance and
  dispersion](https://ryuya-dot-com.github.io/ldfreq/articles/concordance-and-dispersion.html),
  [collocation](https://ryuya-dot-com.github.io/ldfreq/articles/collocation-association.html),
  or
  [keyness](https://ryuya-dot-com.github.io/ldfreq/articles/keyness-comparison.html).
  Inspect original occurrences, zero-match documents and the relevant
  search, pair-opportunity or target/reference denominators.

- Where do target words recur in a textbook?:

  Use the explicitly sourced [textbook progression
  example](https://ryuya-dot-com.github.io/ldfreq/articles/textbook-progression.html).
  Join one saved search to ordered pages, Units and selected sections.
  Inspect counts, cumulative counts and recurrence after declared
  teaching introductions, keeping missing material, follow-up scope and
  original uses.

- How can teachers prepare materials from reviewed examples?:

  Use the explicitly sourced [DDL preparation
  example](https://ryuya-dot-com.github.io/ldfreq/articles/ddl-materials.html).
  Select accepted phrase occurrences, supply activity prompts and source
  notices, and write learner HTML, a separate teacher CSV and a complete
  private record. Pending candidates remain separate from the selected
  teaching examples.

- Which documents have similar lexical composition?:

  Use complete source annotations for [CA and classical
  MDS](https://ryuya-dot-com.github.io/ldfreq/articles/lexical-ordination.html).
  Inspect document and feature selection, CA contributions and squared
  cosines, or the chosen dissimilarity, negative eigenvalues and
  distance reconstruction. Return to the original occurrences; a
  configuration does not test group differences.

- Which categorical properties co-occur in individual uses?:

  Use the explicitly sourced [occurrence-MCA
  example](https://ryuya-dot-com.github.io/ldfreq/articles/lexical-ordination.html#occurrence-mca).
  Keep original token anchors, category definitions, incomplete-row
  exclusions, equal occurrence weights and unadjusted inertia
  diagnostics. These helpers do not select meanings or test group
  effects. Separate display labels on MCA maps are matched to the
  original point IDs.

- Which writer/task/occasion observations entered my analysis?:

  Keep planned observations, submissions and metric results separate in
  [From planned observations to a mixed
  model](https://ryuya-dot-com.github.io/ldfreq/articles/repeated-observations.html).
  Inspect the submission, calculation and reporting states and model-row
  audit; select one response specification for the model table. The
  guide continues with specified means, one planned time contrast,
  Kenward–Roger confidence intervals, diagnostics and saved-table
  replay. Optional emmeans and pbkrtest support this explicitly sourced
  reporting example; it is not an automatic model-selection API.

- How do lexical results relate to sentence or structural descriptions?:

  Use the same source texts and document IDs for [English
  readability](https://ryuya-dot-com.github.io/ldfreq/articles/english-readability.html)
  and [syntactic
  complexity](https://ryuya-dot-com.github.io/ldfreq/articles/syntactic-complexity.html).
  Retain each measure's counts, missing reasons and review decisions
  separately.

A shared document ID does not imply a shared denominator.
Reference-vocabulary profiles describe document words; keyness compares
declared corpora. Corpus-level statistics must not be copied into writer
rows as independent observations. Save original inputs and complete
results, not only displayed tables.

## Open a guide or installed example

The installed package includes rendered guides. Open their local index
with `browseVignettes("ldfreq")`, or use the online guide links above.
The source archive also includes the guide sources.

Study-table, concordance, collocation and keyness functions are exported
and have ordinary help entries. Ordination, readability, syntax and
teaching recipes remain installed example code. Their guides show the
[`system.file()`](https://rdrr.io/r/base/system.file.html) and
[`sys.source()`](https://rdrr.io/r/base/sys.source.html) calls needed to
load the helpers. Follow the guide's input requirements when replacing
its authored data with your own.

## Choose your input

Choose the entry point from the form of data you already have:

- One raw character string:

  Use
  [`lexdiv_metrics_text()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_preprocessing.md).
  It calls the explicit tokenizer and returns its preprocessing audit
  beside the metric rows.

- Several raw texts or a document/text table:

  Use
  [`lexdiv_metrics_text_batch`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_text_batch.md).
  Inspect `result$results` and keep the complete object when saving. The
  examples show both ID/text input and a prepared-token workflow.

- Word families:

  Use
  [`lexdiv_family_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_family_profile.md)
  with complete imported annotations and an explicit inventory. Its
  self-contained example uses
  [`bnccoca_data`](https://ryuya-dot-com.github.io/ldfreq/reference/bnccoca_data.md)
  and explains unlisted words and coverage.

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
  [`lexdiv_as_documents()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_as_documents.md)
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
  annotations guide for an optional gibasa/UniDic recipe; optional
  frequency resources remain English.

- A corpus-relative reference profile:

  Use
  [`tubelex_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md)
  for cached TUBELEX frequency/prevalence, or
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

## Available analyses and reference resources

The ldfreq package computes explicitly versioned lexical-diversity
metrics from ordered tokens and provides separate auditable raw-text,
annotation, lexical-unit, Maas/MTLD sensitivity, and TUBELEX
frequency-profile surfaces. It also provides local MATTR window and
positional-exposure diagnostics, exact term and annotated-content-word
type overlap, many-document coverage by one explicit reference term set,
caller-supplied lexical-norm profiles with separate resource and
annotation coverage, plus New JACET 8000 level profiles using the cached
table or an external copy.
[`bnccoca_data`](https://ryuya-dot-com.github.io/ldfreq/reference/bnccoca_data.md)
supplies Nation's BNC/COCA Level 6 family membership and separate
supplementary lists under CC BY-SA 4.0, for use with
[`lexdiv_family_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_family_profile.md).
[`morphynet_read_derivations`](https://ryuya-dot-com.github.io/ldfreq/reference/morphynet_read_derivations.md)
reads local MorphyNet formation relations, preserving source and target
POS, affixes and alternatives. Only a nine-row CC BY-SA 3.0 teaching
excerpt is an optional download, not the full database.
[`morpholex_data`](https://ryuya-dot-com.github.io/ldfreq/reference/morpholex_data.md)
provides the cached MorphoLex English worksheet tables and provenance.
Those data and their dictionary use CC BY-NC-SA 4.0 (noncommercial use,
attribution and applicable ShareAlike conditions), separately from the
MIT license of the independent R code. Adjacent bigram/trigram
extraction and caller-supplied reference frequencies retain segment
boundaries, original positions, opportunity totals and coverage.
[`lexdiv_ngram_compare`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngram_compare.md)
compares reference choices using the same target items, retaining
coverage and common-set differences from a baseline. Result rows retain
method, parameter or denominator, schema, and contract provenance.

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
quality norm. The cached TUBELEX resource describes YouTube subtitle
word forms; it does not certify the first-language background or ability
of each speaker.

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
maps cached or caller-supplied ranks to Levels 1–8 and reports exact and
cumulative token/type proportions beside off-list coverage. The Level 8
cumulative proportion equals matched coverage because off-list items
remain in the denominator. The optional download supplies the versioned
New JACET 8000 table with JACET permission and source attribution; an
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
[`lexdiv_screen_lengths()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_profile.md)
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
library(ldfreq)

# One raw English text: inspect the score and the counted words.
result <- lexdiv_metrics_text(
  "Cats chase cats and dogs.",
  tokenizer = "english", case = "lower", metrics = "ttr"
)
result$results  # N = 5, V = 4, TTR = 0.8
#> <lexdiv_results: 1 metric; contract 0.2.0>
#>   metric_id value status missing_reason N V below_quality_floor
#> 1       ttr   0.8     ok           <NA> 5 4               FALSE
result$token_audit
#>   token_index surface selected_unit unit_match_rule upos eligible
#> 1           1    cats          cats            <NA> <NA>     TRUE
#> 2           2   chase         chase            <NA> <NA>     TRUE
#> 3           3    cats          cats            <NA> <NA>     TRUE
#> 4           4     and           and            <NA> <NA>     TRUE
#> 5           5    dogs          dogs            <NA> <NA>     TRUE
#>   exclusion_reason
#> 1             <NA>
#> 2             <NA>
#> 3             <NA>
#> 4             <NA>
#> 5             <NA>

# Several texts: names identify documents, including the empty one.
texts <- c(essay_a = "Cats chase cats and dogs.", essay_b = "The reader reads a story.",
  empty = "")
batch <- lexdiv_metrics_text_batch(
  texts, tokenizer = "english", case = "lower", metrics = "ttr"
)
batch$results  # TTR = 0.8, 1, NA; the empty text has reason "empty_input".
#> <lexdiv_batch_results: 3 documents; 3 metric records; schema 0.1.0>
#>   document_id metric_id value  status missing_reason N V below_quality_floor
#> 1     essay_a       ttr   0.8      ok           <NA> 5 4               FALSE
#> 2     essay_b       ttr   1.0      ok           <NA> 5 5               FALSE
#> 3       empty       ttr    NA missing    empty_input 0 0                TRUE

# Other entry points: ?lexdiv_metrics for pre-tokenized words;
# ?lexdiv_family_profile for a complete Nation word-family example.
```
