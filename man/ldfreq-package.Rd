\name{ldfreq-package}
\alias{ldfreq}
\alias{ldfreq-package}
\docType{package}
\title{Reproducible Lexical Diversity and Frequency Profiles}
\description{
Analyze lexical diversity in one or many texts, and describe vocabulary using
explicit reference lists. Start with \code{lexdiv_metrics_text()} for one
English text or \code{lexdiv_metrics_text_batch()} for several. Results retain
the words counted, analysis settings and reasons for unavailable scores.
}
\section{Your first analysis}{
After installing the package, run:
\preformatted{
library(ldfreq)
result <- lexdiv_metrics_text(
  "Cats chase cats and dogs.",
  tokenizer = "english", case = "lower", metrics = "ttr"
)
result$results
}
The text has five word occurrences (\code{N = 5}) and four distinct lowercase
forms (\code{V = 4}). Its type-token ratio is \code{4/5 = 0.8}, with
\code{status = "ok"}. TTR depends on text length; this is a small calculation
example, not evidence of writing ability. Use \code{result$token_audit} to
inspect the counted words. Other metrics can return \code{NA} when a text is
too short for their requested settings; read \code{missing_reason} beside
the value.

Open \code{?lexdiv_metrics_text} for the full help and
\code{example("lexdiv_metrics_text", package = "ldfreq")} to run its examples.
Several related functions share that help page, so its examples also include
optional annotation workflows. No model, Python or optional R package is
required for the first analysis above.

For an end-to-end workflow, see
\href{https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report.html}{From text to a research report}.
For your own files, see
\href{https://ryuya-dot-com.github.io/ldfreq/articles/english-tokenization.html#import-text-files}{TXT-folder and CSV input}.
For counting units and morphology, see
\href{https://ryuya-dot-com.github.io/ldfreq/articles/word-families-and-affixes.html}{Word families, roots and affixes}.
}
\section{Choose your input}{
Choose the entry point from the form of data you already have:
\describe{
  \item{One raw character string}{Use \code{lexdiv_metrics_text()}. It calls
  the explicit tokenizer and returns its preprocessing audit beside the metric
  rows.}
  \item{Several raw texts or a document/text table}{Use
  \code{\link{lexdiv_metrics_text_batch}}. Inspect \code{result$results} and
  keep the complete object when saving. The examples show both ID/text input
  and a prepared-token workflow.}
  \item{Word families}{Use \code{\link{lexdiv_family_profile}} with complete
  imported annotations and an explicit inventory. Its self-contained example
  uses \code{\link{bnccoca_data}} and explains unlisted words and coverage.}
  \item{One ordered token vector}{Use \code{lexdiv_metrics()}. The core will
  not change case, remove tokens, or lemmatize.}
  \item{Several tokenized documents}{Use \code{lexdiv_metrics_batch()} with a
  named list or an explicit ID and token-list-column data frame.}
  \item{Several documents and one reference set}{Use
  \code{lexdiv_reference_coverage()} for separate token- and type-weighted
  directional coverage with explicit numerators and denominators.}
  \item{One-token-per-row or \pkg{quanteda} input}{Use
  \code{lexdiv_as_documents()} to create the explicit named-list boundary.}
  \item{A local MATTR trajectory}{Use \code{lexdiv_mattr_profile()} with a
  MATTR-only plan to retain each window value and position's exposure.}
  \item{A caller-supplied lexical-norm table}{Use
  \code{lexdiv_norm_profile()} or \code{lexdiv_norm_profile_batch()} for
  conditional observed matched-only means and separate resource, value,
  and annotation coverage.}
  \item{Two texts or term sets}{Use \code{lexdiv_term_overlap()} for explicit
  terms, or \code{lexdiv_content_overlap()} for UPOS-annotated content words.}
  \item{Adjacent word combinations}{Use \code{\link{lexdiv_ngrams}} with
  explicit segment IDs and original positions, then construct or import a
  local reference with \code{lexdiv_ngram_reference()} and look up target
  sequences with \code{lexdiv_ngram_profile()}. Corpus text is not bundled.}
  \item{Chunked reference construction}{Use \code{\link{lexdiv_ngram_reference_build}}
  to accumulate exact counts from whole-document chunks without retaining
  all occurrence tables. Distinct types and the document roster stay in memory.}
  \item{Reference-choice sensitivity}{Use \code{\link{lexdiv_ngram_compare}}
  to retain separate reference coverage and compare frequencies on common
  target items, with explicit baseline differences and denominators.}
  \item{Supplied corpus annotations}{Use \code{\link{lexdiv_read_masc}} for
  the supported MASC Penn layout, and \code{lexdiv_as_quanteda()} to use
  quanteda without retokenizing or closing excluded positions. Both retain
  source mappings; see the annotated-corpora guide for the verified scope.}
  \item{Japanese and other external annotations}{Use
  \code{\link{lexdiv_import_annotations}} to verify complete supplied surfaces
  against original segment text and retain source positions and dictionary
  declarations. See the Japanese annotations guide for an optional gibasa/UniDic
  recipe; bundled frequency resources remain English.}
  \item{A corpus-relative reference profile}{Use
  \code{tubelex_profile()} for bundled TUBELEX frequency/prevalence,
  or \code{nj8_profile()} for New JACET 8000 levels.}
}

In the help pages, a \emph{token} is one occurrence. In core metric results, a
\emph{type} is one distinct, exactly equal token string supplied to the core;
Unicode-equivalent spellings remain different unless preprocessing normalized
them first. In a resource profile, a \emph{type} is instead one distinct
effective lookup term under that profile's documented lookup identity. A
\emph{lemma} is an annotation-provided base form. An AntBNC \emph{flemma} is a
family grouping that does not preserve part-of-speech distinctions.
\emph{Coverage} is the proportion of eligible tokens or types that received a
usable annotation or resource match; it is not a proficiency score.
}
\section{Available analyses and reference resources}{
The \pkg{ldfreq} package computes explicitly versioned lexical-diversity
metrics from ordered tokens and provides separate auditable raw-text,
annotation, lexical-unit, Maas/MTLD sensitivity, and TUBELEX frequency-profile
surfaces. It also provides local MATTR window and positional-exposure
diagnostics, exact term and annotated-content-word type overlap,
many-document coverage by one explicit reference term set, caller-supplied
lexical-norm profiles with separate resource and annotation coverage, plus
New JACET 8000 level profiles using the bundled table or an external copy.
\code{\link{bnccoca_data}} supplies Nation's BNC/COCA Level 6 family
membership and separate supplementary lists under CC BY-SA 4.0, for use with
\code{\link{lexdiv_family_profile}}.
\code{\link{morphynet_read_derivations}} reads local MorphyNet formation
relations, preserving source and target POS, affixes and alternatives. Only a
nine-row CC BY-SA 3.0 teaching excerpt is bundled, not the full database.
\code{\link{morpholex_data}} provides the bundled MorphoLex English worksheet
tables and provenance. Those data and their dictionary use CC BY-NC-SA 4.0
(noncommercial use, attribution and applicable ShareAlike conditions),
separately from the MIT license of the independent R code.
Adjacent bigram/trigram extraction and caller-supplied reference frequencies
retain segment boundaries, original positions, opportunity totals and coverage.
\code{\link{lexdiv_ngram_compare}} compares reference choices using the same
target items, retaining coverage and common-set differences from a baseline.
Result rows retain method, parameter or denominator, schema, and contract
provenance.
}
\section{Corpus scope}{
The functions can describe native-speaker and learner texts, including English
writing and prepared speech transcripts. Within-population register variation,
matched L1/L2 comparisons and reference-resource sensitivity are distinct
applications. Participant knowledge scores are not required for descriptive
corpus analysis. Retain language-background, corpus, register, task and
author/speaker metadata separately and link them to results by document ID.
The raw-text helpers do not infer these attributes or parse corpus XML and
transcription conventions. Document repeated speakers and turn boundaries
when preparing spoken data.

Native-speaker status does not establish a universal proficiency or quality
norm. The bundled TUBELEX resource describes YouTube subtitle word forms; it
does not certify the first-language background or ability of each speaker.
}
\section{Input boundary}{
The public core accepts ordered, already-tokenized character vectors. It does
not infer token boundaries, change case, normalize Unicode spelling, remove
tokens, or lemmatize. Batch inputs must carry explicit unique document IDs.
\code{lexdiv_tokenize()}, \code{lexdiv_lemmatize()}, and
\code{lexdiv_flemmatize()} form a separate
preprocessing contract so that these choices cannot silently change core
methods.
}
\section{Results and provenance}{
Metric results are long-form data frames. Read \code{status} and
\code{missing_reason} before \code{value}. Each row records the method, metric
contract, result schema, requested and effective parameters, token/type counts,
the versioned \code{below_quality_floor} field, and method diagnostics. Batch,
profile, and screen layers add separate envelopes without changing the core
record.
}
\section{Formal contracts}{
Human-readable help explains normal use; installed JSON contracts are the
auditable source for exact formulas, domains, schemas, normalization rules,
and resource boundaries. The main files are:
\itemize{
  \item \file{lexical-diversity-contract.json}
  \item \file{ldfreq-preprocessing-contract.json}
  \item \file{lexical-overlap-contract.json}
  \item \file{reference-coverage-contract.json}
  \item \file{mattr-profile-contract.json}
  \item \file{norm-profile-contract.json}
  \item \file{adjacent-ngram-contract.json}
  \item \file{lexical-diversity-variant-contract.json}
  \item \file{lexical-level-profile-contract.json}
  \item \file{tubelex-frequency-profile-contract.json}
}
Locate them with
\code{system.file("spec", filename, package = "ldfreq")}; schemas and
hand-case fixtures are installed in the same directory. Contract status is
also returned in ordinary result or provenance fields, so users do not need to
rely on an R attribute alone.
}
\section{Preprocessing and lexical units}{
The raw-text adapter records Unicode normalization, case handling, number
retention, offsets, and source/processed text hashes. Lemma analyses record the
lemma backend and version. Any UPOS tags require their own explicit backend ID
and version; these values are never defaulted from the lemma backend.
Caller-supplied AntBNC flemma analyses record fixed package adapter/parser IDs,
caller-declared resource and override versions, matching rules, and identity
fallback. They do not expose the local resource file name or a content hash.
Declared labels are public provenance and must contain no paths, secrets, or
private hashes. Surface/lemma/flemma and all/content-word choices are returned
with token-level exclusion reasons and coverage in an envelope that does not
alter the normative metric result schema.
}
\section{Exact lexical overlap}{
\code{lexdiv_term_overlap()} computes Jaccard, Dice, directional A-in-B and
B-in-A coverage, and the overlap coefficient from distinct exact terms.
\code{lexdiv_content_overlap()} first selects \code{ADJ}, \code{ADV},
\code{NOUN}, \code{PROPN}, and \code{VERB} from two validated annotated
tokenizations. It never infers UPOS or lemmas. Each row retains its numerator,
denominator, direction, unit, and contract identity; document-level coverage
separately counts missing UPOS, non-content UPOS, and missing selected units.
The comparability table discloses its label values in four columns:
\code{component}, \code{value_a}, \code{value_b}, and \code{matches}.
Surface comparison uses tokenizer and UPOS settings; lemma comparison also
uses lemma annotation identity. Flemma comparison instead adds its fixed
adapter/parser and declared resource/override settings and ignores lemma
backend identity because it consumes surface forms. Flemma resource versions
must be present and equal; override versions are required and compared only
when overrides are used. No file-content hash is a comparability key. The five
measures have different denominators and must not be reported as one
interchangeable generic percentage.
}
\section{Many-document reference coverage}{
\code{lexdiv_reference_coverage()} asks what proportion of each document's
tokens and distinct types occurs in one supplied reference term set. It uses
exact membership with no implicit tokenization, normalization, or annotation.
Document repetition affects token coverage but not type coverage; reference
repetition affects neither value. The document-major summary retains
numerators, denominators, match counts, status, and missing reasons. Exact term
details are opt-in. The measure does not validate the reference or measure
semantic similarity, plagiarism, proficiency, writing quality, or reference
quality.
}
\section{Caller-supplied lexical norms}{
\code{lexdiv_norm_profile()} exact-matches caller-prepared terms against one
caller-supplied data frame and reports one row per measure and requested
token/type weighting. Means use observed matched values only. Resource
coverage, input-relative value coverage, and matched-key annotation coverage
remain separate, and OOV terms are not merged with matched keys whose values
are missing. Measure and resource metadata are returned as provenance; they do
not establish redistribution rights, construct validity, population transfer,
or comparability across unlike scales. Exact terms are retained in the lookup
table. The function performs no download, implicit normalization, fuzzy
matching, thresholding, or composite scoring.
}
\section{Corpus-relative frequency}{
\code{tubelex_profile()} retains original and normalized lookup
terms, unmatched rows, token/type coverage, and matched-only token/type-weighted
summaries. TUBELEX values are relative to a general YouTube subtitle corpus.
They are not direct measures of proficiency, writing quality, academic
register, or context-independent lexical sophistication.
}
\section{Lexical frequency levels}{
\code{nj8_profile()} maps bundled or caller-supplied ranks to Levels 1--8 and
reports exact and cumulative token/type proportions beside off-list coverage.
The Level 8 cumulative proportion equals matched coverage because off-list
items remain in the denominator. The package bundles the versioned New JACET 8000 table with JACET
permission and source attribution; an external list can be supplied explicitly. Flemma input exposes conflicts between AntBNC families and
New JACET headwords instead of silently choosing one mapping.
}
\section{Direction and contract scale}{
Direction applies only within the exact method, parameters, preprocessing, and
sampling design. Values from different metric IDs are not interchangeable.

\tabular{lll}{
Metric ID \tab Contract scale \tab Conventional score direction \cr
\code{ttr} \tab 0 to 1 \tab higher \cr
\code{rttr} \tab 0 or greater; no finite upper bound \tab higher \cr
\code{cttr} \tab 0 or greater; no finite upper bound \tab higher \cr
\code{herdan} \tab 0 to 1 \tab higher \cr
\code{maas} \tab 0 to \eqn{1 / \ln(2)} (about 1.4427) \tab lower \cr
\code{msttr} \tab 0 to 1 \tab higher \cr
\code{mattr} \tab 0 to 1 \tab higher \cr
\code{mtld} \tab 0 or greater; no finite upper bound \tab higher \cr
\code{hdd} \tab 0 to 1 \tab higher \cr
\code{expected_ttr_d} \tab greater than 0; no finite upper bound \tab higher \cr
\code{yule_k} \tab 0 inclusive to 10,000 exclusive \tab lower \cr
\code{yule_i} \tab 0 or greater; no finite upper bound \tab higher
}
}
\section{Interpretation boundary}{
The methods primarily operationalize lexical variety and repetition. They are
indices used within the lexical-diversity research domain, but no single score
represents the full multidimensional lexical-diversity construct. The metrics
describe lexical-distribution properties of the supplied tokens.
They are not direct measures of language proficiency, writing quality, reader
response, or communicative effectiveness. Inferring those constructs requires a
separate validated study design and cannot be justified by one score or by the
versioned \code{below_quality_floor} field.

Exact term/content-word overlap describes lexical sharing under the selected
unit and annotation. It is not a plagiarism detector or a direct measure of
semantic similarity, coherence, proficiency, or writing quality.
}
\section{Quality screens}{
\code{below_quality_floor} and \code{lexdiv_screen()} are advisory token-count
evidence screens. Here, quality is a field name retained for compatibility; it does not mean writing
quality, measurement validity, or reliability. The screens never change a value,
effective parameter, status, or document membership. Passing a screen does not
establish validity or reliability; failing one does not erase an otherwise
computable value.
}
\section{Versioned surfaces}{
The core metrics, raw-text preprocessing, lexical overlap, reference coverage,
generic lexical-norm profiles, variant metrics, lexical-level profiles, and
TUBELEX profile have separate
versioned contracts. This keeps a change in tokenization or resource matching
from silently redefining a core metric. Expected-TTR D is separately named and
explicitly distinguished from CLAN VOCD.
}
\section{Offline smoke test}{
After loading \pkg{ldfreq}, run the installed script returned by
\code{system.file("examples", "offline-smoke.R", package = "ldfreq")}. It
exercises single, batch, profile, local-MATTR, profile-batch,
term/content-word overlap, many-document reference coverage, lexical-norm,
lexical-level, and screen workflows without
a network connection or external runtime.
}
\seealso{
\code{\link{lexdiv_metrics}}, \code{\link{lexdiv_convenience}},
\code{\link{lexdiv_preprocessing}},
\code{\link{lexdiv_flemmatize}},
\code{\link{lexdiv_overlap}},
\code{\link{lexdiv_reference_coverage}},
\code{\link{lexdiv_norm_profile}},
\code{\link{lexdiv_norm_profile_batch}},
\code{\link{lexdiv_profile}}, \code{\link{lexdiv_mattr_profile}},
\code{\link{lexdiv_variant_metrics}},
\code{\link{nj8_profile}},
\code{\link{tubelex_profile}}
}
\examples{
library(ldfreq)

# One raw English text: inspect the score and the counted words.
result <- lexdiv_metrics_text(
  "Cats chase cats and dogs.",
  tokenizer = "english", case = "lower", metrics = "ttr"
)
result$results  # N = 5, V = 4, TTR = 0.8
result$token_audit

# Several texts: names identify documents, including the empty one.
texts <- c(essay_a = "Cats chase cats and dogs.", essay_b = "The reader reads a story.",
  empty = "")
batch <- lexdiv_metrics_text_batch(
  texts, tokenizer = "english", case = "lower", metrics = "ttr"
)
batch$results  # TTR = 0.8, 1, NA; the empty text has reason "empty_input".

# Other entry points: ?lexdiv_metrics for pre-tokenized words;
# ?lexdiv_family_profile for a complete Nation word-family example.
}
\keyword{package}
