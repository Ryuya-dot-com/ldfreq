\name{lexdiv_metrics}
\alias{lexdiv_metrics}
\alias{lexdiv_metric_ids}
\alias{lexdiv_metrics_batch}
\alias{print.lexdiv_batch_results}
\alias{print.lexdiv_results}
\title{Compute Versioned Lexical-Diversity Metric Variants}
\usage{
lexdiv_metric_ids()

lexdiv_metrics(
  tokens,
  metrics = setdiff(lexdiv_metric_ids(), "expected_ttr_d"),
  segment_length = 50L,
  window_length = 50L,
  mtld_threshold = 0.72,
  sample_size = 42L,
  expected_ttr_sample_sizes = 35:50
)

lexdiv_metrics_batch(
  documents,
  id_col = "document_id",
  tokens_col = "tokens",
  ...
)

\method{print}{lexdiv_batch_results}(x, ...)

\method{print}{lexdiv_results}(x, ...)
}
\arguments{
  \item{tokens}{A plain, unclassed, one-dimensional character vector of ordered,
  already-tokenized strings. Missing and empty tokens, invalid UTF-8, and
  \code{bytes}- or \code{latin1}-marked strings invalidate the document. A
  zero-length character vector denotes an empty document. Valid non-ASCII
  strings with an unknown encoding marker are interpreted as UTF-8 on a local
  copy before equality and counting. Each vector element is exactly one token;
  a single string containing whitespace triggers a warning because it may be
  raw prose. Use \code{lexdiv_metrics_text()} for raw text.}
  \item{metrics}{A plain, non-empty, duplicate-free character vector selected
  from \code{lexdiv_metric_ids()}. The default excludes experimental
  \code{expected_ttr_d}; the catalog still lists every supported metric.}
  \item{segment_length}{One plain finite numeric scalar with an integer value
  at least one; requested complete non-overlapping MSTTR segment length.}
  \item{window_length}{One plain finite numeric scalar with an integer value at
  least one; requested step-one MATTR window length.}
  \item{mtld_threshold}{One plain finite numeric scalar strictly between zero
  and one.}
  \item{sample_size}{One plain finite numeric scalar with an integer value at
  least one; requested without-replacement HD-D sample size.}
  \item{expected_ttr_sample_sizes}{A non-empty, strictly increasing plain
  integer vector with values at least two. It fixes the sample-size curve used
  by deterministic expected-TTR D and is never resized to the document.}
  \item{documents}{Either a plain list with unique, non-empty document IDs as
  names, or a data frame with an explicit plain character ID column and a
  token-vector list-column. Zero-document inputs are accepted only when they
  retain the required structure.}
  \item{id_col}{One plain, non-empty character string selecting the document-ID
  column of data-frame input. IDs must be unique, non-missing, valid UTF-8 and
  may not be marked \code{bytes} or \code{latin1}.}
  \item{tokens_col}{One plain, non-empty character string selecting the token
  list-column of data-frame input.}
  \item{x}{A \code{lexdiv_results} or \code{lexdiv_batch_results} object.}
  \item{...}{For \code{lexdiv_metrics_batch()}, arguments forwarded to
  \code{lexdiv_metrics()}; for print methods, arguments passed to
  \code{print.data.frame()}.}
}
\value{
\code{lexdiv_metric_ids()} returns the versioned metric IDs in default order.
\code{lexdiv_metrics()} returns a \code{lexdiv_results} data frame with one row
per metric. Its columns are \code{metric_id}, \code{method_id},
\code{metric_contract_id}, \code{metric_contract_version},
\code{result_schema_id}, \code{result_schema_version}, \code{value}, \code{status},
\code{missing_reason}, requested and effective parameter list-columns,
\code{N}, \code{V}, \code{below_quality_floor}, and a diagnostics list-column.
The print method returns its input invisibly.

\code{lexdiv_metrics_batch()} returns a \code{lexdiv_batch_results} object in
document-major, requested-metric-minor long form. Its first three columns are
\code{document_id}, \code{batch_schema_id}, and
\code{batch_schema_version}; all single-document record columns follow.
}
\description{
Computes explicitly versioned lexical-diversity variants from pre-tokenized
input. The core performs no normalization, token deletion, or lemmatization.
Requested segment, window, and sample sizes are never silently reduced for a
short document. Missingness, method identity, sufficient counts, quality flags,
parameters, and diagnostics are returned beside each value.
}
\details{
Start with \code{lexdiv_metrics(c("a", "a", "b", "c"), metrics = "ttr")}.
Each vector element is one word occurrence: \code{N = 4} tokens contain
\code{V = 3} distinct types, so \code{value = 0.75}. The result is already a
data frame; use \code{result$value} to access its scores. For a raw sentence,
use \code{\link{lexdiv_metrics_text}} instead of putting the whole sentence
in one vector element. TTR varies with text length and is not an essay-quality
score.

The examples then show a computed value, an empty document, an invalid token,
and a text shorter than a requested window. An \code{NA} value has a reason:
inspect \code{status} and \code{missing_reason} before interpreting it or
combining results. Choosing \code{metrics = "ttr"} keeps the first example
small; omitting \code{metrics} requests the eleven default methods, some of
which cannot be computed for short inputs. Experimental expected-TTR D requires
explicit selection.

The current versioned set contains TTR, RTTR/Guiraud, CTTR, Herdan's C, natural-log
Maas a-squared, complete non-overlapping MSTTR, step-one MATTR, bidirectional
MTLD, sample-size-normalized hypergeometric HD-D on the TTR scale, Yule's K,
deterministic expected-TTR curve-fit D, and type-based Yule's I. Expected-TTR D
fits the model \eqn{2/(\sqrt{1+2n/D}+1)} to exact finite-population expected TTR
values. It is experimental: numerical accuracy has been checked, but empirical
equivalence to published vocd-D or CLAN has not. It uses no random sampling or
arbitrary D cap and is not CLAN VOCD. From package 0.3.0 it is excluded from
default computations and presets; select it explicitly when needed.
From package version 0.2.0, the same expected curve and objective are evaluated
through the expected duplicate-draw fraction to avoid cancellation near TTR=1.
The method ID is unchanged because this is a numerical correction, not a new
estimator. Record the package version as well as method and parameters.
\code{near_saturation} diagnoses a nearly flat curve; it does not establish
statistical precision or validity.

From package 0.3.0, the canonical MTLD method has no minimum factor length.
It closes a factor when running TTR is strictly less than the threshold,
including at the final token, and averages forward and reverse scores.
A residual factor receives \code{(1 - tail_TTR) / (1 - threshold)} credit.
Every threshold crossing closes a factor, so residual credit cannot exceed one.
All-unique input has zero factors and returns \code{missing / no_factor}.
For example, 50 copies of one word form 25 factors and return 2.
A computable short-input result is not evidence of reliable measurement.
koRpus 0.13.9 skips a terminal span of at most two tokens, while this method
checks every token; exact tool equivalence is not claimed.

An invalid token anywhere has precedence over empty-input and metric-specific
domain conditions. Invalid documents return \code{status = "invalid_input"},
\code{missing_reason = "invalid_token"}, and unknown \code{N}/\code{V}. A
zero-length document returns \code{status = "missing"} and
\code{missing_reason = "empty_input"}. Formula and requested-parameter domain
failures use more specific missing reasons. Parameter values are validated only
when their metric is requested; those selected-metric request errors are
structural and are checked before document-token state.

\code{below_quality_floor} is an advisory screening flag. It is deliberately
separate from mathematical computability and never changes a requested
parameter or suppresses an otherwise computable value. Passing the floor does
not establish validity or reliability, and falling below it does not erase an
otherwise computable value. Unicode encoding-marker canonicalization is not
Unicode normalization: canonically equivalent but scalar-distinct strings
remain distinct types.

For sequential bidirectional MTLD, the compact display adds two columns
derived from existing \code{diagnostics}: \code{mtld_tail_only} is true when
either direction has zero complete factors, and \code{mtld_gap_pct} is
\code{100 * abs(forward_score - reverse_score) / mean(c(forward_score,
reverse_score))}. These are display columns, not additional stored result
fields. Use \code{\link{lexdiv_widen}(x, mtld_diagnostics = TRUE)} to extract
them with the directional scores, factor counts and tail credits into ordinary
columns. A tail-only direction extrapolates from its fractional tail; a zero
gap is possible when both directions have no complete factors. The gap
describes order sensitivity, not standard error, reliability or a confidence
interval. The 50-token MTLD floor is a retained advisory length screen, not a
validated cutoff for the current no-minimum definition. The study-specific
50/100-token evidence and method-equivalence limits are recorded by
\code{lexdiv_length_evidence()}. Neither passing the length screen nor having
complete factors establishes precision. See the designing-comparisons guide
for a numeric table of counts, tails and directional scores.

Within the same exact method and design, Maas a-squared and Yule's K
conventionally decrease as repetition decreases; the other ten supported methods
conventionally increase with observed lexical variety or lower repetition.
These methods primarily operationalize lexical variety and repetition rather
than the full multidimensional lexical-diversity construct. Direction applies
only within the same method, parameters, preprocessing, and sampling design.
The metrics are not direct measures of language proficiency, writing quality,
reader response, or communicative effectiveness, and raw values from different
metric IDs are not interchangeable.

The batch adapter does not infer IDs, tokenize raw strings, recycle parameters
by document, or accept one-token-per-row long tables. Invalid token vectors are
contained as structured rows for their document, while malformed containers,
duplicate IDs, and invalid selected-metric arguments stop the whole call.
Named-list and data-frame inputs preserve document order, followed within each
document by requested metric order. Batch-envelope and core-record schemas have
separate explicit IDs and versions.
}
\section{Reading status and missing reason}{
Interpret \code{value} only after checking both fields:
\describe{
  \item{\code{status = "ok"}}{The requested method was computed. Its
  \code{missing_reason} is missing.}
  \item{\code{status = "missing"}}{The document was structurally valid, but
  the requested method had no value under its defined domain or parameter
  rules.}
  \item{\code{status = "invalid_input"}}{At least one token made the document
  invalid. The package returns an audited row rather than silently deleting
  that token.}
}

The versioned reason vocabulary is \code{empty_input}, \code{invalid_token},
\code{insufficient_tokens_for_formula},
\code{too_short_for_requested_parameter}, \code{zero_denominator},
\code{no_factor}, \code{non_convergence}, \code{boundary_censored}, and
\code{unbounded_high}. The reasons that can occur depend on the selected method. Structural request errors, such as
an unknown metric ID or invalid selected parameter, stop the call instead of
returning a result row.
}
\section{Migration from core contract 0.1.0}{
Package 0.3.0 uses core contract 0.2.0. MTLD has the new method ID
\code{mtld_seq_bidir_dirmean_lt_nomin_linear_tail_v1}. The old
\code{mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1} remains in
\code{lexdiv_variant_metrics()}, with the same minimum input length, values,
and tail behavior (including credit greater than one).

Read existing RDS results without editing their IDs or values. Old plans and
specifications must be explicitly recreated with the current \code{lexdiv_spec()}
and \code{lexdiv_plan()} before new computation. All specification hashes change
because they include the core contract version, even for unchanged formulas.
Record the package version, method ID, contract version, parameters and
preprocessing in reports. Analyze old and new MTLD results separately; the
wide-table and plot checks reject mixed measurement identities.

Default results now have eleven rows, and the canonical and length presets
have eleven and thirteen requests. \code{lexdiv_metric_ids()} still lists all
twelve supported metrics. Explicit \code{metrics = lexdiv_metric_ids()} includes
experimental expected-TTR D. Its estimator and method ID are unchanged.
Result schemas, tokenization and bundled reference data are unchanged.
}
\section{Formal contract}{
Exact formulas, domains, floating-point policy, method IDs, result fields, and
the complete status vocabulary are installed in
\file{lexical-diversity-contract.json}. Locate it with
\code{system.file("spec", "lexical-diversity-contract.json", package =
"ldfreq")}. The adjacent schema and hand-case fixture are installed under the
same \file{spec} directory.
}
\references{
Covington, M. A. and McFall, J. D. (2010). Cutting the Gordian Knot:
The Moving-Average Type-Token Ratio (MATTR). \emph{Journal of Quantitative
Linguistics}, 17(2), 94--100. \doi{10.1080/09296171003643098}.

McCarthy, P. M. and Jarvis, S. (2010). MTLD, vocd-D, and HD-D: A validation
study of sophisticated approaches to lexical diversity assessment.
\emph{Behavior Research Methods}, 42, 381--392. \doi{10.3758/BRM.42.2.381}.

Tweedie, F. J. and Baayen, R. H. (1998). How Variable May a Constant Be?
Measures of Lexical Richness in Perspective. \emph{Computers and the
Humanities}, 32, 323--352. \doi{10.1023/A:1001749303137}.

These references describe the method families. Use the exact formulas,
variants and parameter values documented here when reporting ldfreq results.
Expected-TTR D is a separately named exact-expectation curve fit, not CLAN VOCD.
}
\examples{
library(ldfreq)

# One vector element per token, in its original order.
tokens <- c("a", "a", "b", "c")
result <- lexdiv_metrics(tokens, metrics = "ttr")
result  # N = 4, V = 3, value = 0.75, status = "ok"
result$value

# Empty, invalid, and too-short inputs are different conditions.
lexdiv_metrics(character(), metrics = "ttr")  # missing / empty_input
lexdiv_metrics(c("a", NA_character_), metrics = "ttr")  # invalid_input / invalid_token
lexdiv_metrics(c("a", "b"), metrics = "mattr", window_length = 3)
# The last result is missing / too_short_for_requested_parameter, not zero.

# Named lists keep each document separate, including the empty document.
documents <- list(doc_a = c("a", "a", "b"), doc_b = character())
batch <- lexdiv_metrics_batch(documents, metrics = "ttr")
batch  # doc_a: N = 3, V = 2, TTR = 2/3; doc_b: missing / empty_input

# Further methods. Sample size 2 is for this tiny illustration only.
lexdiv_metric_ids()
lexdiv_metrics(tokens, metrics = c("ttr", "hdd"), sample_size = 2)

lexdiv_metrics(
  rep(c("a", "b", "a", "c"), 20),
  metrics = "expected_ttr_d"
)

mtld <- lexdiv_metrics(rep(c("a", "b"), 10), metrics = "mtld")
mtld$diagnostics[[1]]

# Reproduce the previous min10 formula explicitly (50 identical tokens -> 10).
legacy <- lexdiv_variant_metrics(
  rep("a", 50),
  variants = "mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1"
)
legacy$value
lexdiv_metrics(rep("a", 50), metrics = "mtld")$value  # new definition: 2

contract_path <- system.file(
  "spec", "lexical-diversity-contract.json", package = "ldfreq"
)
stopifnot(nzchar(contract_path))
basename(contract_path)
}
\seealso{\code{\link{lexdiv_metrics_text}}, \code{\link{lexdiv_text_batch}},
\href{https://ryuya-dot-com.github.io/ldfreq/articles/getting-started.html}{Getting started}}
