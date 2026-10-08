# ldfreq

**Compare lexical diversity and vocabulary profiles while keeping the analysis
conditions attached to the results.** `ldfreq` is an R package for researchers
working with first- and additional-language writing, transcribed speech,
teaching materials, and other texts. It combines
lexical-diversity measures, New JACET 8000 level coverage, and TUBELEX reference
frequency with explicit preprocessing, parameter settings, and match coverage.
The bundled resources and built-in linguistic rules target English; prepared
tokens can represent other languages, with an experimental Japanese workflow.

A difference between two scores can reflect different word units, window sizes,
or reference-list matches. `ldfreq` helps you inspect those choices and report
what was actually measured. It records non-computable requests and their reasons,
and checks that reshaped tables and plots do not mix incompatible specifications.

[![Local vocabulary diversity for three window sizes in an authored example](https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report_files/figure-html/trajectory-overlay-1.png)](https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report.html#plot-local-vocabulary-diversity)

**[Reproduce this plot in R](https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report.html#plot-local-vocabulary-diversity).**
The complete example includes the text, analysis, color/monochrome drawing and
PNG/PDF export. It illustrates local vocabulary diversity and window-size
sensitivity with authored text, not learner data.

## Why use ldfreq?

- **Keep comparisons explicit.** Retain the formula, requested and effective
  parameters, token/type counts, and preprocessing decisions with each result.
  Short documents do not silently reduce a requested window for other documents.
- **Connect diversity with reference vocabulary.** Describe New JACET 8000
  levels and TUBELEX frequency/prevalence alongside token/type coverage. Unmatched
  terms remain visible; missing frequency values are not replaced by zero.
- **Examine sensitivity.** Compare lexical units, parameter settings, and selected
  Maas/MTLD definitions; inspect local MATTR windows and positional exposure.
- **Connect word families, roots and affixes to the original text.** Compare
  counting units on shared occurrences, distinguish derivation from inflection,
  and retain reference entries, coverage and review decisions. The executable
  [word families and affixes tutorial](https://ryuya-dot-com.github.io/ldfreq/articles/word-families-and-affixes.html)
  connects Nation, MorphoLex and MorphyNet with CSV decisions and saved results.
- **Trace annotation errors to the analysis.** Evaluate supplied labels against
  an explicit reference on the same tokenization. Keep missing labels and
  class-specific precision/recall beside source-text context, then examine how
  different word selections change document scores. See the
  [annotation evaluation guide](https://ryuya-dot-com.github.io/ldfreq/articles/annotation-evaluation.html).
- **Describe word combinations with your own reference.** Extract adjacent
  bigrams/trigrams from prepared segments and original positions, then look up
  local reference counts with explicit opportunity totals. Sample zeros and
  unlisted keys in pruned tables remain distinct. No corpus needs to be bundled.
  See the [n-gram guide](https://ryuya-dot-com.github.io/ldfreq/articles/ngram-profiles.html)
  for CSV/RDS inputs, boundary requirements and phrase-level research examples.
- **Trace the effect of reference choice.** Compare the same target phrases
  across references, keeping coverage and sample sizes beside common-item
  differences. A higher mean caused by missing phrases should not be mistaken
  for greater familiarity.

These are features for describing and comparing texts. A score alone does not
establish proficiency, writing quality, measurement validity, or reliability.

The Japanese workflow also connects [source-linked frequency profiles](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-annotations.html#connect-document-selections-to-reference-frequency)
to full-token coverage, common-span comparisons and saved-input replay.

The text workflow supports surface forms, lemmas and AntBNC flemmas.
For resource-defined word families, experimental `lexdiv_family_profile()`
matches complete imported annotations to a caller-supplied form–family table.
It retains token occurrences, member counts, unresolved candidates and KWIC;
`use` and `reusability` remain two tokens even if a declared table places them
in one family. See the [word-family example](https://ryuya-dot-com.github.io/ldfreq/articles/preprocessing-and-frequency.html#resource-defined-word-families).
An optional `review` connects the existing ambiguity-review workflow to
occurrence-specific family choices, retaining reviewers, reasons and original
lookup results. Changed source, inventory or counting policies require a new
review snapshot; one decision never changes every occurrence of a spelling.
Flemmas and derivational families are distinct. `bnccoca_data()` supplies
Nation's BNC/COCA Level 6 lists: 25,000 families and 75,679 headword/member
records, with 29,798 supplementary records kept separate. The data use
**CC BY-SA 4.0**, with attribution and ShareAlike conditions; see the
[source and conversion notice](https://github.com/Ryuya-dot-com/ldfreq/blob/main/inst/licenses/bnccoca/NOTICE.md).
Family membership does not establish a learner's knowledge of every member.
The bundled version groups `use`/`uses` and `colour`/`color`; `reusability`
is unlisted and remains unresolved. Frequency bands are distinct from the
Bauer–Nation Level 6 inclusion criterion.

`morphynet_read_derivations()` reads a separately obtained MorphyNet TSV in R,
retaining formation relations, original POS symbols, source hashes and
alternatives. An [installed example](https://ryuya-dot-com.github.io/ldfreq/articles/preprocessing-and-frequency.html#inspect-morphynet-formation-relations)
connects a nine-row, CC BY-SA 3.0 excerpt to existing KWIC review. Multiple
incoming relations are not summed as affixes or converted to Nation families.
The full database is not bundled; optional KWIC review uses quanteda.
An explicitly sourced [roots-and-affixes recipe](https://ryuya-dot-com.github.io/ldfreq/articles/preprocessing-and-frequency.html#source-linked-roots-and-affixes)
links supplied parts to original occurrences, retaining analysis scope, alternatives,
partial analyses and coverage. `morpholex_data()` reads the bundled MorphoLex-en
tables with their provenance and CC BY-NC-SA 4.0 terms. The word-parts recipe
can use these tables offline or an optional local workbook;
these recipes are not exported APIs or automatic morphology analyzers.

## Corpus scope

The same analysis functions accept native-speaker and learner texts. Research
can examine variation within native-speaker corpora, compare matched L1/L2
samples, or evaluate reference-frequency choices across registers. Learner
assessment is one application; no participant knowledge scores are required
for descriptive corpus analysis.

Keep author/speaker, task, register, corpus version and documented language
background in a metadata table linked by document ID. Match relevant sampling
conditions before interpreting L1/L2 differences. Native-speaker status is not
a universal quality target, and a general English corpus need not contain only
verified L1 speakers. See [corpus roles and comparison design](https://ryuya-dot-com.github.io/ldfreq/articles/designing-comparisons.html)
for reference-corpus candidates and limits.

The token-based calculations accept caller-prepared strings without inferring a
language. Segmentation and lexical units still need validation for the target
language and register. The raw-text English rules and bundled English reference
resources have narrower scope. Automatic POS tagging, sense disambiguation,
corpus-XML import and proficiency scoring are not part of the default pipeline.

To inspect lexical ambiguity in context, `lexdiv_ambiguity_review()` connects
complete imported annotations to optional quanteda KWIC displays. It keeps
original segment text, source positions, caller-supplied candidates and explicit
reviewer decisions together, including unresolved occurrences. See the
[English/Japanese review guide](https://ryuya-dot-com.github.io/ldfreq/articles/ambiguity-review.html).
It does not infer senses or split aggregate reference frequencies by meaning.
`lexdiv_compare_ambiguity()` pairs two reviews, reports descriptive agreement
alongside joint-selection coverage, and returns open cases with both contexts
and reasons. The guide also connects a separately obtained WLSP inventory to
the same review interface.
The [Japanese polysemy guide](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-polysemy.html)
connects separately obtained WLSP-norms estimates to reviewed stimulus items
and KWIC occurrences, preserving source IDs, signed values and selection coverage.

`lexdiv_import_contextual()` attaches externally computed target embeddings or
candidate scores after checking original text, positions and review identity.
Model suggestions stay separate from human choices; failed or absent outputs
remain in the denominator. The [contextual model guide](https://ryuya-dot-com.github.io/ldfreq/articles/contextual-models.html)
includes an offline example and an optional, explicit Python call using a cached
Hugging Face model. No model or Python installation is required for the R importer.
The same guide also provides an [offline categorical-proposal worksheet](https://ryuya-dot-com.github.io/ldfreq/articles/contextual-models.html#review-categorical-proposals-without-inventing-scores)
and an optional OpenAI recipe. Paid requests require your own API key and an
explicit opt-in; saved responses are reused. Candidate choices, abstentions and
human judgments remain separate, and ordinary analysis makes no model calls.
`lexdiv_evaluate_contextual()` compares scored candidates to an explicitly
declared reference review. It abstains on incomplete inventories and ties,
keeps all-occurrence coverage beside conditional agreement, and returns a KWIC
queue of disagreements and unavailable comparisons. A human reference is not
automatically a validated gold standard; model exposure and evaluation role
remain part of the research design.
`lexdiv_score_contextual()` supplies two explicit baselines from separately
labeled training examples: cosine to a candidate's mean target vector and its
training-label count. It checks document/context separation, candidate inventories
and embedding compatibility, and retains missing prototypes and excluded examples.
Both score outputs connect to evaluation and KWIC; no model weights or new R
dependency are needed. These baselines do not establish semantic validity.
The guide includes a copyable three-script study folder for preparation,
development/frozen evaluation and replay in a new R session. It checks declared
document/group splits, keeps individual judgments alongside the reference, and
compares methods on all available cases and their common evaluable occurrences.
Its authored English/Japanese values demonstrate the workflow, not model accuracy.

For Japanese, use an existing morphological analyzer and import its complete
annotations with `lexdiv_import_annotations()`. It verifies surfaces against
original text, derives source positions, retains lexical-form/POS columns and
dictionary metadata, and connects to the existing metrics and n-gram functions.
The [Japanese guide](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-annotations.html)
provides an R-only gibasa/UniDic recipe, explicit missing-feature handling, and
gap-preserving exclusions. Start with the executable
[Japanese file-to-review walkthrough](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-annotations.html#japanese-file-workflow):
read authored files, retain title/body boundaries, review contextual identities,
and save whole-body measures separately from target counts. This first example
uses prepared annotations and needs no analyzer or dictionary.
Continue with [document descriptions](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-annotations.html#describe-script-word-origin-and-pos-by-document)
to separate script/codepoint counts from dictionary word origins and declared
POS groups, retaining exclusions, missing labels, denominators and saved inputs.
A Japanese dictionary is optional and separately
obtained; the package does not bundle one or establish cross-language score
equivalence. The Unicode tokenizer alone is not a Japanese word segmenter.
The [word-unit comparison](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-annotations.html#compare-japanese-word-units)
shows how segmentation and punctuation selection affect counts, paired score
comparisons and short-text eligibility, using separately obtained annotations.

For experimental stimuli, the [Japanese norms guide](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-norms.html)
shows how to attach separately obtained AoA or BOI ratings while retaining item
IDs, experimental conditions, rating counts, missing matches and resource terms.
It includes an offline illustration and a local-file R example; external norm
data are not bundled. A WLSP-familiarity example lists spelling candidates and
retains explicit record choices and reasons, including unresolved items.
The [stimulus-selection guide](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-stimuli.html)
adds a pinned Japanese TUBELEX base-form lookup and joins all four resources by
study item ID. It retains source denominators and mapping decisions, inspects
per-condition missingness and distributions, and saves a complete RDS record.
Adult native-speaker norms do not measure individual L2
knowledge or acquisition history.

## Relationship to existing tools

| Existing tool | Its focus | Where ldfreq fits |
|---|---|---|
| [quanteda.textstats](https://quanteda.io/reference/textstat_lexdiv.html) | Text statistics and lexical diversity for quanteda tokens and document-feature matrices | Use prepared tokens with explicit method/parameter records, non-computability reasons, and reference-resource profiles |
| [koRpus](https://reaktanz.de/?c=hacking&s=koRpus) | Text analysis including lemma workflows, MTLD, HD-D, MTLD-MA, and detailed diagnostics | Compare the exact definitions and add a common workflow for condition tracking and reference coverage |
| [tidytext](https://juliasilge.github.io/tidytext/) | Text processing with tidy tables | Pass one-token-per-row tables through `lexdiv_as_documents()` |
| [gibasa](https://paithiov909.github.io/gibasa/) | MeCab morphological analysis from R using separately supplied dictionaries | Import complete Japanese annotations with original-text alignment and retain lexical-form choices and dictionary metadata alongside analysis results |
| [text](https://www.r-text.org/) | Transformer embeddings and language analysis from R using Python | Attach source-aligned external outputs to KWIC reviews, human decisions and explicit missing-output coverage; model inference is not reimplemented |
| [zipfR](https://r-forge.r-project.org/projects/zipfr/) | Statistical models for word-frequency distributions and vocabulary growth | Use ldfreq for document-level descriptive measures and reference-list profiles |
| [KH Coder](https://khcoder.net/diagram.html) | An application for quantitative content analysis: exploratory word analysis, explicit concept-coding rules, KWIC, correspondence analysis and co-occurrence networks | Complement content analysis with lexical-measure definitions, NJ8/TUBELEX/norm profiles and preprocessing sensitivity; direct KH Coder interoperability is not implemented or validated |

Existing R packages already implement many of these metrics and document their
parameters. The contribution here is their integration with explicit comparison
conditions and resource coverage, not a claim to have invented the measures.
Same-named metrics can differ in formula, log base, aggregation, or short-text
handling. See [definition and preprocessing comparisons](https://ryuya-dot-com.github.io/ldfreq/articles/preprocessing-and-frequency.html).
No speed or empirical-validity advantage over these packages is claimed.

From package 0.3.0 (core contract 0.2.0), `mtld` has no minimum factor
length, uses strict `<`, and checks every token including the last. The
previous min10 calculation remains explicitly available through
`lexdiv_variant_metrics()`; it is not silently relabelled. The
[executed external comparisons](https://github.com/Ryuya-dot-com/ldfreq/tree/main/experiments/external-metrics)
record identical inputs, tool versions, outputs and reasons for differences.
The [raw-text comparison](https://github.com/Ryuya-dot-com/ldfreq/tree/main/experiments/raw-text-comparison)
additionally records eight preprocessing configurations, actual scoring tokens
and native/common-formula scores. It distinguishes TAALED's space-split fallback
from pinned Pylats surface, lemma/POS and explicit content-word configurations.
`expected_ttr_d` is experimental: accurate computation of this estimator does
not establish equivalence to CLAN vocd-D. `lexdiv_methods()` reports each
method's classification. Default computations and presets exclude it; request
`metrics = "expected_ttr_d"` to compute it explicitly. See
`?lexdiv_metrics` for the migration example and keep the full saved results.
The [worked migration comparison](https://ryuya-dot-com.github.io/ldfreq/articles/designing-comparisons.html#check-the-effect-on-your-documents)
shows how to check paired scores, missing cases and rank correlation on your
own texts. All 30 authored tutorial essays retain their values; this does not
estimate effects in a learner population.

`below_quality_floor` is an advisory screen, not a quality score. TTR's value
of 1 merely checks for non-empty input. MATTR's fixed 50-token floor does not
validate every possible window size: consult `lexdiv_length_evidence()` and
report the chosen window and available text length separately.

For MTLD, also inspect factor support. From development version 0.3.0.9002,
the compact display flags `mtld_tail_only` when either direction has no
complete factors and shows `mtld_gap_pct`, the absolute directional difference
as a percentage of their mean. `status = "ok"` means computable. Passing
the advisory 50-token floor does not establish precision, and a zero
directional gap can occur when **both** directions depend entirely on their
fractional tails. The gap describes order sensitivity, not a confidence
interval. The [factor-support example](https://ryuya-dot-com.github.io/ldfreq/articles/designing-comparisons.html#inspect-mtld-factor-support)
extracts the underlying counts and scores into an ordinary table, including
when using an earlier package version. The 50-token MTLD screen is inherited
guidance, not a validated reliability cutoff for the present definition.
For your own sample, the same guide supplies a token-count correlation recipe
and an [executed PELIC learner-text example](https://github.com/Ryuya-dot-com/ldfreq/tree/main/experiments/learner-length).
These are descriptive checks, not evidence of length invariance or a validated
novice-user workflow.

KH Coder already uses R and documents
[exporting plotting commands as R Source](https://khcoder.net/scr_r.html).
R integration, Japanese support and returning to source context therefore do
not by themselves distinguish ldfreq. A complementary study could link content
codes and lexical measures through explicit document IDs, without treating a
topic/code as a lexical type or corpus co-occurrence as a direct measure of
mental lexical organization. Its documented
[document-by-word exports](https://khcoder.net/FAQ.html) are an exchange route
to assess, not a tested ldfreq connector. An unordered count matrix cannot
recover original-token MATTR, MTLD, adjacent n-grams or occurrence-level KWIC.
Record tokenization, selected POS, text versions, aggregation units and export
filters; complete token/source exports require separate validation. Current
compatibility with KH Coder 5 has not been tested.

KH Coder is an optional companion, not a prerequisite for ldfreq. Its current
[official distributions](https://khcoder.net/dl3.html) include paid editions
and a restricted free Windows edition; the
[Mac distribution](https://khcoder.net/mac_com.html) is paid and requires
Apple Silicon. These distribution conditions are distinct from the older
public source release. The ldfreq workflow does not require a KH Coder purchase.

N-gram extraction is also established functionality in
[quanteda](https://quanteda.io/reference/tokens_ngrams.html), and
[TAALES](https://www.linguisticanalysistools.org/taales.html) provides word and
phrase measures with coverage diagnostics. In ldfreq, the emphasis is a shared
R workflow retaining document/segment locations, reference definitions,
eligible-window denominators and missingness alongside other lexical measures.
The current n-gram functions provide frequencies, not MI/t-score or a validated
phraseological-sophistication score.

Phrase-list profiling and source-text overlap also have existing tools.
Masaki Eguchi's [Multi-Word Units Profiler](https://github.com/egumasa/Multi-Word-Units-Profiler)
highlights expressions from published phrase lists, while
[cx-overlaps](https://github.com/egumasa/cx-overlaps), his extension of Philip
Tillman's fluencysimilarity, compares unigram/trigram use across performances
or against a source. Phrase matching, overlap and cosine similarity are not
new contributions of ldfreq. Its focus is connecting analysis units and source
locations to reference-resource definitions, human decisions and missingness
in an R workflow. An [installed phrase-list example](https://ryuya-dot-com.github.io/ldfreq/articles/annotated-corpora.html#match-your-phrase-list-and-inspect-its-coverage)
uses quanteda for exact sequences of two or more supplied tokens, including
long expressions, and returns original-text KWIC and overlap-aware document
coverage. It is an explicitly sourced helper, not an exported API or a
phrase-sense/discourse-function classifier. Phrase lists are supplied by the
caller and are not bundled.

## Installation

Version 0.3.0.9002 is a development prerelease and has not been released on CRAN.
The fixed tag below preserves this measurement-contract migration.
It requires R 4.1.0 or later. Install the tested snapshot used by this
documentation:

```r
# Run install.packages("pak") first if pak is not installed.
pak::pak("Ryuya-dot-com/ldfreq@v0.3.0.9002")
```

Pinning the revision fixes the implementation, even when development snapshots
share the same version number. The package's required dependencies are `digest`
and `stringi`; additional tools are optional for their documented
workflows. For example, candidate-review examples use `quanteda`.

If you have a built source archive, install it locally:

```r
# Install digest and stringi first if they are not already available.
install.packages("ldfreq_0.3.0.9002.tar.gz", repos = NULL, type = "source")
```

The built archive includes rendered guides. A GitHub source installation may
omit them; the online guides remain available.

## A first analysis

After `library(ldfreq)`, open `?ldfreq` for a short first analysis and an input
map. `?lexdiv_metrics_text` explains the counted words and scores;
`?lexdiv_family_profile` contains a complete Nation word-family example.
Run `example("lexdiv_metrics_text", package = "ldfreq")` to execute the text
examples. These help pages include expected values and explain missing results.


For TXT files, folders or ID/text CSV files, start with the
[executable file-input tutorial](https://ryuya-dot-com.github.io/ldfreq/articles/english-tokenization.html#import-text-files).
It includes sample files, metadata joins and complete analysis saving.

```r
library(ldfreq)

# Thirty authored texts and one empty file, supplied with the package.
paths <- list.files(
  system.file("examples", "text-input", "texts", package = "ldfreq"),
  pattern = "\\.txt$", full.names = TRUE
)
texts <- setNames(vapply(paths, function(path) {
  paste(readLines(path, encoding = "UTF-8", warn = FALSE), collapse = "\n")
}, character(1)), tools::file_path_sans_ext(basename(paths)))
prepared <- lexdiv_tokenize_batch(
  texts, tokenizer = "english", normalization = "NFC", case = "lower"
)

# Use the same declared 50-token window for every document.
analysis <- lexdiv_metrics_text_batch(
  prepared, metrics = c("ttr", "mattr"), window_length = 50
)
print(analysis$results)  # Compact display; full metadata stay in the object.

# The bundled NJ8 table is available offline, with JACET's permission.
# This is surface-form coverage; it does not silently lemmatize the text.
levels <- nj8_profile_batch(prepared, unit = "surface")
levels$coverage
nj8_diagnostics(levels)$unmatched_terms
plot(analysis, metric_id = "mattr")
plot(analysis, metric_id = "mattr", monochrome = TRUE)
saveRDS(analysis, "analysis.rds")
```

All package plots default to color; `monochrome = TRUE` selects black and gray.
No title or subtitle is added automatically. Place figure numbers, titles and
notes outside the image in the manuscript. Both color modes distinguish
points below the advisory token floor by shape; custom `pch` settings are retained.
The plotted values and returned data are identical in both modes. Plot defaults
use a sans serif font, horizontal tick labels and an open frame.
See the [report guide](https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report.html)
for final-size PDF/PNG export and the distinction between descriptive and
inferential figures.

The English tokenizer runs entirely in R. It retains contractions and
hyphenated words, recognizes dotted initialisms, and records excluded URLs,
email addresses and number-like spans. Named text vectors and ID/text data
frames share the same batch interface. Existing calls keep the original
`tokenizer = "unicode"` default; select the English rules explicitly.
See [English tokenization and document input](https://ryuya-dot-com.github.io/ldfreq/articles/english-tokenization.html)
for segmentation examples, CSV/text-file input, and limitations. An offline
counting-policy example separates spelling equivalence from lookup aliases,
proper-noun/numeral selection, and symbol boundaries without altering the source.

These authored texts illustrate the workflow, not a population effect. The
empty file remains visible with a missing result; the plot has 30 scored texts.
Report the counting unit, tokenizer/case choices, document length, window size,
and reference version/coverage alongside the results.
TTR uses the full document denominator; MATTR uses the selected local window.
NJ8 coverage asks how much of the selected vocabulary matches the list, not how
much vocabulary a writer knows. For lemma coverage, supply or explicitly generate
lemmas first. Report the selected unit, exclusions, and off-list proportion.
Use [the vocabulary-audit guide](https://ryuya-dot-com.github.io/ldfreq/articles/auditing-vocabulary-profiles.html)
to inspect unmatched terms and surface-to-unit mappings before interpreting coverage.

[From text to a report](https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report.html) extends this example
to a reusable analysis table, an interpretation, saved results, and citations.

## Reference frequency needs its own tokenization

The bundled TUBELEX table uses NLTK Treebank tokenization. The general
`lexdiv_tokenize()` keeps contractions together and is a different tokenizer.
For example, the appropriate segmentation of this illustrative sentence is:

```r
terms <- c("I", "do", "n't", "think", "it", "'s", "John", "'s", "book")
frequency <- tubelex_profile(terms)
frequency$summary
frequency$coverage
```

For raw text, follow the optional, executable
[TUBELEX input recipe](https://ryuya-dot-com.github.io/ldfreq/articles/tubelex-input.html). It uses NLTK externally,
records its version and sentence-model identity, and reproduces the English
word-splitting and filtering steps of the pinned TUBELEX source. It does not
reproduce subtitle collection, cleaning, or deduplication. R calculations have
no Python or network dependency. Character-vector inputs remain caller-supplied;
a high match rate does not prove that arbitrary tokens use the right segmentation.

## Available analyses

| Task | Entry points |
|---|---|
| Twelve diversity measures | `lexdiv_metrics()`, `lexdiv_metrics_text()`, `lexdiv_metrics_batch()` |
| Named raw texts or document ID/text tables | `lexdiv_tokenize_batch()`, `lexdiv_metrics_text_batch()` |
| Raw text, lemmas, or externally supplied AntBNC flemmas | `lexdiv_tokenize()`, `lexdiv_lemmatize()`, `lexdiv_flemmatize()` |
| Count families under an explicit inventory | `lexdiv_family_profile()` retains occurrences, candidates, member counts, KWIC and incomplete coverage |
| Record or choose the lemma dictionary | `lexdiv_lemmatize(method = "textstem", dictionary = ...)` records content identity and lookup locale |
| Audit annotation changes on the same documents | `lexdiv_compare_annotations()` retains changed labels and both provenance records |
| Evaluate external labels against a supplied reference | `lexdiv_evaluate_annotations()` returns per-label errors, document coverage and source context on the same segmentation |
| Compare different English/Japanese token segmentations | `lexdiv_align_annotations()` separates source-span/boundary correspondence from conditional label agreement and retains split/merge KWIC |
| Trace adjective–common-noun dependencies | `lexdiv_amod_pairs()` validates supplied basic UD trees and retains both endpoints, KWIC, document counts and incomplete-sentence coverage |
| Parameter and definition sensitivity | `lexdiv_spec()`, `lexdiv_grid()`, `lexdiv_plan()`, `lexdiv_profile()`, `lexdiv_profile_batch()`, `lexdiv_variant_metrics()` |
| Local MATTR windows and exposure | `lexdiv_mattr_profile()` |
| Exact term/content-word overlap | `lexdiv_term_overlap()`, `lexdiv_content_overlap()` |
| Coverage of a supplied reference set | `lexdiv_reference_coverage()` |
| Numeric lexical norms with observed-value and annotation coverage | `lexdiv_norm_profile()` |
| Apply your reference table across a corpus with document-level coverage | `lexdiv_norm_profile_batch()` |
| Bundled or external NJ8 levels | `nj8_profile()`, `nj8_profile_batch()` |
| Bundled TUBELEX frequency/prevalence | `tubelex_profile()`, `tubelex_profile_batch()` |
| Tabulate TUBELEX results with coverage and input conditions | `tubelex_diagnostics()` |
| Compare scored recognition/recall pairs with explicit denominators | `lexdiv_compare_responses()` |
| Token-table adapters, wide tables, and plots | `lexdiv_as_documents()`, `lexdiv_widen()`, `plot()` |
| Import local MASC Penn annotations with original positions | `lexdiv_read_masc()` (experimental; Mini-MASC 1.0 and a validated subset of MASC 3.0.0) |
| Import complete external annotations, including Japanese morphology | `lexdiv_import_annotations()` (experimental; exact source alignment before exclusions) |
| Use quanteda n-grams and KWIC while retaining gaps and source IDs | `lexdiv_as_quanteda()` (optional quanteda dependency) |
| Compare reference choices with coverage and a common set of target phrases | `lexdiv_ngram_compare()` |
| Build local reference counts from whole-document chunks | `lexdiv_ngram_reference_build()` (retains types and document IDs in memory) |

The eleven default measures are TTR, RTTR/Guiraud, CTTR, Herdan C, Maas a-squared,
MSTTR, MATTR, MTLD, HD-D, and Yule K/I. Experimental expected-TTR D is opt-in.
`lexdiv_methods()` describes their definitions, scales, parameters, and direction.
Expected-TTR D fits an exact finite-population expectation; it is not CLAN VOCD.

`lexdiv_screen()` and `lexdiv_length_evidence()` describe advisory token-count
criteria. Passing a screen does not establish validity or precision. Missing
results do not change the requested parameters or silently remove documents.

## Learning and reporting

- [Annotated corpora and quanteda](https://ryuya-dot-com.github.io/ldfreq/articles/annotated-corpora.html): import supplied annotations, preserve exclusions and return from KWIC to source positions; includes an offline authored example.
- [Getting started](https://ryuya-dot-com.github.io/ldfreq/articles/getting-started.html): inputs, result tables, annotation, and parameter plans.
- [From text to a report](https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report.html): one complete workflow and what to cite.
- [Designing comparisons](https://ryuya-dot-com.github.io/ldfreq/articles/designing-comparisons.html): questions, common settings, sensitivity, answers, and limits.
- [Audit annotations and vocabulary profiles](https://ryuya-dot-com.github.io/ldfreq/articles/auditing-vocabulary-profiles.html): connect changed labels to original context, document-score differences, selection/reference coverage and saved-input replay. Includes a reviewed-text example that preserves learner errors in the original and compares explicitly approved spelling/grammar edits under separate policies.
- [Evaluate annotations and their effect on document scores](https://ryuya-dot-com.github.io/ldfreq/articles/annotation-evaluation.html): explicit references, label-specific errors, missing predictions and English/Japanese examples.
- [Compare token boundaries and document scores](https://ryuya-dot-com.github.io/ldfreq/articles/annotation-alignment.html): source-based split/merge correspondence, conditional label coverage, and full-document TTR/MATTR sensitivity.
- [Trace adjective–noun dependencies](https://ryuya-dot-com.github.io/ldfreq/articles/dependency-pairs.html): source-linked basic UD pairs, missing annotations, and occurrence differences hidden by equal document counts; offline English/Japanese examples and an optional real-parser workflow using a local UDPipe model in R.
- [Your own reference data across a corpus](https://ryuya-dot-com.github.io/ldfreq/articles/corpus-reference-profiles.html): custom norms, document metadata, missingness, and reproducible saving.
- [Analyze open-access papers](https://ryuya-dot-com.github.io/ldfreq/articles/open-access-papers.html): a reproducible example using three CC BY papers, with explicit text extraction, attribution and unknown author language backgrounds.
- [Preprocessing and frequency](https://ryuya-dot-com.github.io/ldfreq/articles/preprocessing-and-frequency.html): lexical units, formula variants, and resource coverage.
- [Vocabulary knowledge and use](https://ryuya-dot-com.github.io/ldfreq/articles/vocabulary-knowledge-and-use.html): relate corpus features to learner evidence without inferring ability from frequency.
- [TUBELEX input recipe](https://ryuya-dot-com.github.io/ldfreq/articles/tubelex-input.html): optional external token preparation.

Use `vignette(package = "ldfreq")` to list guides included in your installation.
Exact formulas and result specifications are installed under `system.file("spec",
package = "ldfreq")`. Preserve the full results with `saveRDS()`, together with
preprocessing and session information; flat exports of selected values alone
cannot retain all analysis settings.

## Data and attribution

New JACET 8000 is copyright JACET and is redistributed with permission and source
attribution. Cite JACET Basic Word Revision Committee (Ed.). (2016).
*The New JACET List of 8000 Basic Words*. Tokyo: Kirihara Shoten.
The bundled `jacet2016-8000-v1` table has all 8,000 rank/entry pairs, checked
against the official workbook. Three corrections to the supplied snapshot
(`nan`, `true`, and `false`) are documented in the
[NJ8 notice](https://github.com/Ryuya-dot-com/ldfreq/blob/main/inst/licenses/nj8/NOTICE.md).
An external data frame, CSV, or XLSX can still be supplied as `wordlist`.

TUBELEX is copyright Adam Nohejl and is distributed under BSD-3-Clause.
Cite Nohejl et al. (2025),
[Beyond Film Subtitles: Is YouTube the Best Approximation of Spoken Vocabulary?](https://aclanthology.org/2025.coling-main.641/).
The bundled resource is a slim aggregate at source commit `7cb5fb36`; no raw
subtitles are included. Its source, changes, and complete license are recorded
in the [TUBELEX notice](https://github.com/Ryuya-dot-com/ldfreq/blob/main/inst/licenses/tubelex/NOTICE.md).
NGSL, Open English WordNet, and AntBNC data are not bundled.

MorphoLex-en is bundled under **CC BY-NC-SA 4.0**, which permits noncommercial
sharing and adaptation with attribution and applicable ShareAlike conditions;
it does not grant commercial-use permission. Cite Sánchez-Gutiérrez, Mailhot,
Deacon, and Wilson (2018), [MorphoLex: A derivational morphological database
for 70,000 English words](https://doi.org/10.3758/s13428-017-0981-8).
All 34 worksheets and the original data dictionary are included, with no
inferred parts or corrections. The [MorphoLex notice](https://github.com/Ryuya-dot-com/ldfreq/blob/main/inst/licenses/morpholex/NOTICE.md)
records the conversion, source checksums and full license location.

```r
reference <- morpholex_data(c("0-1-1", "All roots"))
words <- reference$sheets[["0-1-1"]]
words[words$Word %in% c("teacher", "teachers"),
      c("Word", "MorphoLexSegm", "ROOT1_FamSize")]
reference$provenance$data_license
```

Columns retain source values as character strings; convert selected numeric
measures explicitly. See `?morpholex_data` for sheet names and interpretation.

Use `citation("ldfreq")` for the software and cite the methods and resources
used in the analysis. The R code is MIT licensed. Bundled resources retain
their own terms; see `LICENSE` and the installed `COPYRIGHTS` file.
