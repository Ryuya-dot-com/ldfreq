\name{lexdiv_preprocessing}
\alias{lexdiv_preprocessing}
\alias{lexdiv_tokenize}
\alias{lexdiv_lemmatize}
\alias{lexdiv_metrics_text}
\alias{print.lexdiv_tokenization}
\alias{print.lexdiv_text_results}
\title{Versioned raw-text preprocessing for lexical-diversity metrics}
\description{
Compute lexical diversity directly from one text with
\code{lexdiv_metrics_text()}. Use \code{lexdiv_tokenize()} first when you want
to inspect the words, or \code{lexdiv_lemmatize()} to attach supplied base
forms and optional part-of-speech tags. The examples start with a complete
English sentence and then change one analysis choice at a time.
}
\usage{
lexdiv_tokenize(
  text,
  normalization = "NFC",
  case = "preserve",
  keep_numbers = FALSE,
  tokenizer = "unicode"
)

lexdiv_lemmatize(
  x,
  method = "supplied",
  lemmas = NULL,
  upos = NULL,
  backend_id = NULL,
  backend_version = NULL,
  upos_backend_id = NULL,
  upos_backend_version = NULL,
  dictionary = NULL,
  dictionary_id = NULL,
  dictionary_version = NULL
)

lexdiv_metrics_text(
  x,
  unit = "surface",
  word_inclusion = "all",
  normalization = "NFC",
  case = "preserve",
  keep_numbers = FALSE,
  metrics = lexdiv_metric_ids(),
  segment_length = 50L,
  window_length = 50L,
  mtld_threshold = 0.72,
  sample_size = 42L,
  expected_ttr_sample_sizes = 35:50,
  tokenizer = "unicode"
)

\method{print}{lexdiv_tokenization}(x, ...)

\method{print}{lexdiv_text_results}(x, ...)
}
\arguments{
\item{text}{One plain valid-UTF-8 character string. An empty string is valid.}
\item{normalization}{Unicode normalization: \code{"NFC"}, \code{"NFKC"},
or \code{"none"}.}
\item{case}{Either \code{"preserve"} or locale-fixed English
\code{"lower"}.}
\item{keep_numbers}{Whether numeric tokens are retained. With \code{"unicode"},
this concerns tokens consisting only of Unicode numbers; with \code{"english"},
it also covers recognized numeric expressions such as dates and percentages.
This is a pattern rule, not a semantic NUM tag: spelled-out numbers and
alphanumeric forms such as \code{"two"}, \code{"2nd"}, and \code{"COVID-19"} remain.}
\item{tokenizer}{\code{"unicode"} preserves the original word rules;
\code{"english"} selects the English lexical rules described below.}
\item{x}{For \code{lexdiv_lemmatize()}, an object created by
\code{lexdiv_tokenize()}. For \code{lexdiv_metrics_text()}, either that object
or one raw character string. When an existing tokenization is supplied, its
recorded normalization, case, and number-retention choices are authoritative;
supplying \code{normalization}, \code{case}, \code{keep_numbers}, or \code{tokenizer} again is
an error. Call \code{lexdiv_tokenize()} again to change those choices. For
the print methods, \code{x} is the corresponding result object.}
\item{method}{Lemma source: caller-\code{"supplied"} values or the optional
\code{"textstem"} backend.}
\item{lemmas}{An aligned character vector of lemmas for the supplied method.
Missing values are allowed and are later reported as exclusions.}
\item{upos}{Optional aligned Universal POS tags. Missing values are allowed.
Non-missing tags are uppercased and must belong to the Universal POS inventory;
unsupported labels are errors rather than ordinary non-content words.
The \pkg{textstem} backend supplies lemmas only and does not infer UPOS. Supply
tags explicitly when a later \code{word_inclusion = "content"} analysis is
required.}
\item{backend_id, backend_version}{Required non-empty, path-free lemma-backend
identifiers for caller-supplied annotations. For textstem, package identity is
recorded automatically and these arguments must be \code{NULL}. Caller labels
are public provenance and must not contain paths, secrets, or private hashes.}
\item{upos_backend_id, upos_backend_version}{Required path-free UPOS-backend
identifiers whenever any non-missing UPOS tag is present. They are never
defaulted from the lemma backend, even when one pipeline created both layers.
They must be \code{NULL} when no UPOS tags are present. These values are
public provenance; callers must not put paths, secrets, or private hashes in
them.}
\item{dictionary}{For \code{method = "textstem"}, an optional two-column data
frame: unique lowercase lookup terms in column one and lemmas in column two.
Both columns must be character vectors without empty or missing values. Column
names and row order do not affect lookup. An empty dictionary is allowed.
The default is \code{lexicon::hash_lemmas}. Unmatched tokens retain their
surface forms; lookup lowercases queries with base R in the current locale.}
\item{dictionary_id, dictionary_version}{Required non-empty path-free labels
when supplying a dictionary; \code{NULL} for the default dictionary, whose
identity and installed lexicon version are recorded automatically. All three
dictionary arguments must be \code{NULL} for \code{method = "supplied"}.}
\item{unit}{One of \code{"surface"}, \code{"lemma"}, or \code{"flemma"}.
Lemma and flemma analyses require the corresponding annotations on a
\code{lexdiv_tokenization} object; raw character input supports surface
analysis only.}
\item{word_inclusion}{Either \code{"all"} word tokens or \code{"content"},
defined as UPOS \code{ADJ}, \code{ADV}, \code{NOUN}, \code{PROPN}, and
\code{VERB}.}
\item{metrics}{A duplicate-free vector from \code{lexdiv_metric_ids()}.}
\item{segment_length}{Requested complete segment length for MSTTR.}
\item{window_length}{Requested step-one window length for MATTR.}
\item{mtld_threshold}{Requested MTLD threshold strictly between zero and one.}
\item{sample_size}{Requested without-replacement sample size for HD-D.}
\item{expected_ttr_sample_sizes}{A non-empty, strictly increasing vector of
sample sizes used to fit deterministic expected-TTR D.}
\item{...}{Additional arguments passed to the underlying data-frame print
method.}
}
\details{
For a first analysis, choose \code{metrics = "ttr"},
\code{tokenizer = "english"} and an explicit case policy. In the first example,
\code{case = "lower"} makes \emph{Cats} and \emph{cats} the same type:
five word occurrences (\code{N}) contain four distinct forms (\code{V}),
so TTR is \code{V/N = 4/5 = 0.8}. TTR depends on text length; this small example
teaches the calculation, not a design for comparing essay quality.

Read \code{result$results} for scores and their status,
\code{result$token_audit} for the words included or excluded, and
\code{result$preprocessing} for the recorded settings. With the default metric
selection, a short sentence produces \code{NA} for methods requiring more
tokens. Check \code{missing_reason}; the function does not shorten a requested
MATTR window to make a value available. A small demonstration window is not a
recommended research setting. See \code{\link{lexdiv_metrics}} for status
definitions and \code{\link{lexdiv_text_batch}} for several texts.

The supplied-lemma example keeps all five tokens first (TTR \code{3/5 = 0.6}),
then selects content words (TTR \code{2/4 = 0.5}). Removing \emph{and} changes
the denominator as well as the type count. These are authored annotations;
no tagger is run. Surface input needs no optional package. Only the final
\pkg{textstem} example needs that separately installed package, and it is
skipped when unavailable.

The default \code{"unicode"} tokenizer extracts Unicode letter, mark, and number sequences, retaining
internal apostrophes and hyphens while excluding punctuation tokens. Start and
end offsets refer to the processed text after the requested normalization and
case transformation (Unicode code points, not bytes or original-text offsets).

The opt-in \code{"english"} tokenizer keeps contractions and hyphenated words
whole, preserves dotted initialisms such as \code{U.S.A.}, and excludes recognized
HTTP(S)/www URLs and dotted-domain email addresses before looking for words.
It recognizes number-like spans including decimals, grouped numbers, numeric
dates, fractions, exponents and percentages. These are lexical rules, not
numeric or date validation. By default they are excluded; \code{keep_numbers = TRUE}
retains them. Standalone combining marks are ignored.
After the requested normalization and case conversion, left/right curly
apostrophes become ASCII apostrophes and Unicode hyphen/non-breaking hyphen
become ASCII hyphens. This mapping applies even with \code{normalization = "none"}.
For example, \code{"can't"} stays one word, \code{well-known} stays one word,
\code{3.14} is one number, and \code{Dr.} contributes \code{Dr}.
URL recognition can include trailing punctuation. Bare domains without www or
HTTP(S), malformed addresses, and linguistic exceptions are not inferred.
Neither tokenizer expands contractions, supplies lemmas, performs multilingual
word segmentation, or reproduces Treebank/TUBELEX segmentation.

English provenance includes \code{excluded_spans}, a data frame with processed
\code{start}/\code{end} offsets, \code{surface}, and \code{reason}
(\code{url}, \code{email}, or \code{number}), plus its SHA-256 fingerprint.
These records retain excluded text; they are an analysis audit, not redacted
output. Ordinary punctuation and ignored symbols are not listed. Only retained
word/number tokens enter the later lexical-unit selection denominator.
Saved Unicode tokenizations under preprocessing contract 0.2.0 remain accepted
with their recorded provenance, as do contract 0.3.0 tokenizations of either
kind. New objects use contract 0.4.0, and reapplying \code{lexdiv_lemmatize()}
upgrades the annotation record. Older textstem records lacking dictionary
provenance remain readable but cannot establish strict lemma comparability in
\code{lexdiv_content_overlap()}. Tokenization rules and metric schemas are unchanged.

The package does not silently choose or download a lemmatization model.
\code{lexdiv_lemmatize(method = "supplied")} accepts annotations created by
any documented external workflow and requires its identity and version.
\code{method = "textstem"} is an optional English lemma convenience backend.
It records the installed \pkg{textstem} version but does not create UPOS tags.
The annotation's \code{dictionary} record contains the dictionary ID, version,
entry count, SHA-256 content fingerprint, hash method, and query casefold/locale.
The fingerprint ignores row order and column names but changes if a mapping
changes, even with the same version label. It hashes length-prefixed UTF-8
term/lemma pairs in sorted term order, as specified in the installed contract.
It is a content comparison aid, not proof of authenticity or linguistic accuracy.
The dictionary itself is not retained: save it separately alongside the prepared
objects to rerun lookup, and retain the backend version and locale. A loaded
object can validate record structure but cannot recompute the dictionary hash
without the original dictionary. The backend performs context-free lookup;
use aligned supplied annotations for occurrence-specific decisions.
Consequently, it can be used directly for \code{unit = "lemma"} with
\code{word_inclusion = "all"}; content-word selection additionally requires
caller-supplied UPOS annotations. Missing lemmas or UPOS tags are excluded and
reported in the token audit rather than imputed.

Lemma and UPOS backend identities are separate. Supplying UPOS tags always
requires explicit \code{upos_backend_id} and \code{upos_backend_version};
the package does not derive them from \code{backend_id} or
\code{backend_version}.
\code{lexdiv_flemmatize()} is a separate caller-supplied AntBNC adapter because
flemma counting does not preserve POS distinctions and is not synonymous with
ordinary lemmatization.

\code{lexdiv_metrics_text()} does not add preprocessing columns to the versioned
metric result schema. It returns the unchanged core results beside a token-level
audit and a separately versioned preprocessing record. This allows
surface/lemma/flemma
and all/content-word analyses to be compared without treating one choice as a
universal default.

The tokenizer arguments \code{normalization}, \code{case},
\code{keep_numbers}, and \code{tokenizer} apply only when \code{x} is raw text. They are never
silently reapplied to, or ignored for, an existing tokenization object.
}
\section{Saved-object compatibility}{
Preprocessing contract \code{0.4.0} validates annotation and provenance,
including explicit UPOS-backend identity, text hashes, character bounds,
normalization consistency, and a fingerprint of the surface token table,
whenever an object is consumed. Both tokenizer rule sets use their own identity and version 0.1.0.
Unicode objects saved under preprocessing contract 0.2.0 remain accepted.
Objects saved with preprocessing contract 0.1.0 must be recreated from the
original text; their token-table fingerprint cannot be recovered as verified
provenance by simply relabeling the saved object. If
a saved \code{lexdiv_tokenization} has incomplete, unsupported, or manually
altered provenance, recreate it from the original text with
\code{lexdiv_tokenize()} and then reapply annotations with the current
functions and explicit identities.
The fingerprint detects ordinary token-table edits; it is not authentication
and cannot reconstruct or verify the original text from its hash.
}
\section{Formal contract}{
The installed \file{ldfreq-preprocessing-contract.json} file fixes tokenizer,
normalization, annotation, lexical-unit, and result-boundary behavior. Use
\code{system.file()} with directory \code{"spec"}, that filename, and
\code{package = "ldfreq"} to locate it. The contract is ordinary JSON and can
be inspected without running a preprocessing backend.
}
\value{
\code{lexdiv_tokenize()}, \code{lexdiv_lemmatize()}, and
\code{lexdiv_flemmatize()} return a
\code{lexdiv_tokenization} object containing \code{tokens} and
\code{provenance}. \code{lexdiv_metrics_text()} returns a
\code{lexdiv_text_results} list containing \code{results},
\code{token_audit}, and \code{preprocessing}.
The print methods return \code{x} invisibly.
}
\examples{
library(ldfreq)

# 1. Paste one English text here. Lowercase before counting distinct forms.
result <- lexdiv_metrics_text(
  "Cats chase cats and dogs.",
  tokenizer = "english", case = "lower", metrics = "ttr"
)
result$results  # N = 5, V = 4, TTR = 0.8, status = "ok"
result$token_audit

# A 50-word MATTR window does not fit this five-word text.
short <- lexdiv_metrics_text(
  "Cats chase cats and dogs.",
  tokenizer = "english", case = "lower", metrics = "mattr",
  window_length = 50
)
short$results  # NA; missing_reason = "too_short_for_requested_parameter"

# 2. Inspect the English tokenizer's retained and excluded spans.
english <- lexdiv_tokenize(
  "John's well-known book costs 3.14. See https://example.org.",
  tokenizer = "english", case = "lower"
)
english$tokens
english$provenance$excluded_spans

# 3. Change the counting unit while retaining the same five tokens.
tokenization <- lexdiv_tokenize("Cats and cat ran run.", tokenizer = "english")
surface <- lexdiv_metrics_text(tokenization, metrics = "ttr")
surface$results  # Case preserved: N = 5, V = 5, TTR = 1

# These labels were written for this example. No automatic analysis is run.
annotated <- lexdiv_lemmatize(
  tokenization,
  lemmas = c("cat", "and", "cat", "run", "run"),
  upos = c("NOUN", "CCONJ", "NOUN", "VERB", "VERB"),
  backend_id = "documented-example-annotations",
  backend_version = "1",
  upos_backend_id = "documented-example-upos",
  upos_backend_version = "1"
)
lemma_all <- lexdiv_metrics_text(annotated, unit = "lemma", metrics = "ttr")
lemma_all$results  # Same N = 5; V = 3, TTR = 0.6

# 4. Now change word inclusion: exclude "and" using the supplied POS tags.
lemma_content <- lexdiv_metrics_text(
  annotated,
  unit = "lemma",
  word_inclusion = "content",
  metrics = "ttr"
)
lemma_content$results  # N = 4, V = 2, TTR = 0.5
lemma_content$token_audit

# Optional: install.packages("textstem") to run this lookup example.
if (requireNamespace("textstem", quietly = TRUE)) {
  textstem_tokens <- lexdiv_tokenize(
    "The cats were running and studies.",
    case = "lower"
  )
  textstem_lemmas <- lexdiv_lemmatize(
    textstem_tokens,
    method = "textstem"
  )
  textstem_lemmas$tokens[, c("surface", "lemma")]
  textstem_lemmas$provenance$annotation
  lexdiv_metrics_text(textstem_lemmas, unit = "lemma", metrics = "ttr")
}
}
\seealso{\code{\link{lexdiv_flemmatize}}, \code{\link{lexdiv_metrics}},
\code{\link{lexdiv_text_batch}}, \code{\link{tubelex_profile}},
\href{https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report.html}{From text to a research report},
\href{https://ryuya-dot-com.github.io/ldfreq/articles/english-tokenization.html#import-text-files}{Read your own TXT or CSV files}}
\keyword{text}
