\name{lexdiv_metrics}
\alias{lexdiv_metrics}
\alias{lexdiv_metric_ids}
\alias{lexdiv_metrics_batch}
\alias{print.lexdiv_batch_results}
\alias{print.lexdiv_results}
\title{Compute Frozen Lexical-Diversity Metric Variants}
\usage{
lexdiv_metric_ids()

lexdiv_metrics(
  tokens,
  metrics = lexdiv_metric_ids(),
  segment_length = 50L,
  window_length = 50L,
  mtld_threshold = 0.72,
  sample_size = 42L
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
  copy before equality and counting.}
  \item{metrics}{A plain, non-empty, duplicate-free character vector selected
  from \code{lexdiv_metric_ids()}.}
  \item{segment_length}{One plain finite numeric scalar with an integer value
  at least one; requested complete non-overlapping MSTTR segment length.}
  \item{window_length}{One plain finite numeric scalar with an integer value at
  least one; requested step-one MATTR window length.}
  \item{mtld_threshold}{One plain finite numeric scalar strictly between zero
  and one.}
  \item{sample_size}{One plain finite numeric scalar with an integer value at
  least one; requested without-replacement HD-D sample size.}
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
\code{lexdiv_metric_ids()} returns the frozen metric IDs in default order.
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
The current frozen set contains TTR, RTTR/Guiraud, CTTR, Herdan's C, natural-log
Maas a-squared, complete non-overlapping MSTTR, step-one MATTR, bidirectional
MTLD, sample-size-normalized hypergeometric HD-D on the TTR scale, Yule's K,
and type-based Yule's I. The separately named deterministic expected-TTR
curve-fit D candidate is distinct from HD-D, is deferred from v0.1, and is not
accepted by this API.

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

Within the same exact method and design, Maas a-squared and Yule's K
conventionally decrease as repetition decreases; the other nine v0.1 methods
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
\examples{
lexdiv_metric_ids()

tokens <- c("a", "a", "b", "c")
lexdiv_metrics(tokens, metrics = c("ttr", "hdd"), sample_size = 2)

lexdiv_metrics(character(), metrics = "ttr")
lexdiv_metrics(c("a", NA_character_), metrics = "ttr")
lexdiv_metrics(c("a", "b"), metrics = "mattr", window_length = 3)

mtld <- lexdiv_metrics(rep(c("a", "b"), 10), metrics = "mtld")
mtld$diagnostics[[1]]

documents <- list(doc_a = c("a", "a", "b"), doc_b = character())
lexdiv_metrics_batch(documents, metrics = c("ttr", "mtld"))
}
