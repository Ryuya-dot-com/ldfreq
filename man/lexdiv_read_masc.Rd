\name{lexdiv_read_masc}
\alias{lexdiv_read_masc}
\alias{lexdiv_as_quanteda}
\title{Read local MASC Penn annotations and retain positions in quanteda}
\description{
Imports supplied Penn tokens from the MASC GrAF 1.0 layout, or transfers
an explicit token/segment table to quanteda without retokenizing it.
These experimental functions retain source positions and explicit segment
boundaries. They do not download a corpus or infer missing annotations.
}
\usage{
lexdiv_read_masc(files, resource_version, document_ids = NULL,
  offset_unit = c("codepoint", "utf16"), max_tokens = 1e6)

lexdiv_as_quanteda(data, segments, term_col = "surface", max_tokens = 1e6)
}
\arguments{
\item{files}{Non-empty character vector of local document headers. Each must
use GrAF 1.0 \code{cesHeader} (Mini-MASC \file{.anc}) or \code{documentHeader}
(MASC 3.0.0 \file{.hdr}), with one primary text and references for \code{seg},
\code{s}, and \code{penn}. Modern headers use \code{f.id="f.seg"} etc. and
\code{loc}; older headers use \code{type} and \code{ann.loc}. References must
resolve to files in the same directory as the header.}
\item{resource_version}{A non-empty caller-supplied label for the actual data
release. This declaration is recorded, not independently authenticated.}
\item{document_ids}{Unique document IDs, in file order. Defaults to header
basenames without their extensions; supply IDs when basenames repeat.}
\item{offset_unit}{Unit of the source's zero-based, end-exclusive anchors:
Unicode codepoints or UTF-16 code units. Choose from source documentation;
the reader does not infer the unit. Primary text must be UTF-8 in either case.}
\item{max_tokens}{Positive integer bound. For the reader, maximum total Penn
token rows; for the adapter, maximum sum of segment \code{token_count}, including
excluded positions. This is an output allocation bound, not a total memory limit.}
\item{data}{Plain data frame with \code{document_id}, \code{segment_id},
\code{token_index}, and the selected term column. Indices are positive integers
within each original segment. Keep them unchanged when excluding rows.
Additional columns, including annotation IDs and character positions, survive.}
\item{segments}{Plain data frame with unique \code{document_id}/\code{segment_id}
pairs and the original non-negative \code{token_count} for each segment.
Its row order determines quanteda document order. Include empty segments.
At least one segment is required. Do not replace the counts by retained counts.}
\item{term_col}{Column of non-missing, non-empty, whitespace-free token strings.
For example, \code{surface} or \code{lemma}. No case conversion or normalization
is requested. Missing lemmas require an explicit exclusion or other decision.}
}
\details{
\code{lexdiv_read_masc()} requires the optional \pkg{xml2} package. It is
verified against Mini-MASC 1.0's Penn layer and accepts MASC 3.0.0's modern
header layout. This does not establish whole-corpus support: a local audit of
the official 392-document MASC 3.0.0 archive accepted 122 documents under the
reader's strict span/feature conditions and rejected 270. Do not silently
omit failures and describe the remaining subset as full MASC. PTB layers,
arbitrary GrAF graphs and OANC are not validated inputs.
It sorts tokens and segments by source anchors, resolves
adjacent multi-region tokens, and rejects missing links, duplicate IDs,
overlapping tokens/segments, discontinuous token regions and tokens outside
the supplied sentence/utterance regions. XML with DTD/entity declarations is
not accepted. The \code{s} layer may describe utterances; it is not replaced
by automatic sentence splitting. Unannotated text outside these regions stays
in the original document text but does not become a token.

The source \code{base}, \code{msd}, and \code{affix} features are exposed as
\code{lemma}, \code{pos}, and \code{affix}. Missing features stay \code{NA}.
All flat feature values are also retained in a list column. Penn tags are not
converted to UPOS. An imported annotation is not a guarantee of accuracy.
The file format does not establish ownership or permission to redistribute
the input; retain the actual dataset's attribution and terms separately.

\code{lexdiv_as_quanteda()} requires the optional \pkg{quanteda} package.
It makes each segment a quanteda document, preserving position gaps as
padding and retaining source document IDs in \code{docvars}. It verifies that
the public quanteda import/removal operations preserve all supplied terms and
positions. \code{quanteda_docname} is a reserved output column.
Non-ASCII terms require a UTF-8 \code{LC_CTYPE} locale for the quanteda import;
the adapter errors in other locales and never changes the session locale.
Check \code{l10n_info()[["UTF-8"]]} in the session running the analysis;
\code{TRUE} needs no locale change. This is not a restriction on macOS.
\code{C.UTF-8} is different from the non-UTF-8 \code{C} locale.
The reader itself accepts UTF-8 primary text independently of this restriction.
Aggregate segment counts back to original documents before computing document
frequency. Use \code{quanteda::ntoken(x, remove_padding = TRUE)} to count
retained tokens. The position mapping applies to the returned token object;
compounding, collapsing gaps, and n-gram construction can change positions.
For phrase locations, search the original token object with \code{kwic()}.
}
\value{
The reader returns a plain list:
\itemize{
\item \code{tokens}: document/segment IDs, within-segment \code{token_index},
\code{document_token_index}, source \code{annotation_id}, surface/lemma/POS/affix,
\code{start}/\code{end} in 1-based inclusive Unicode codepoints, original
\code{start_anchor}/\code{end_anchor}, and supplied \code{features}.
\item \code{segments}: IDs, both coordinate forms, and original \code{token_count}.
\item \code{documents}: IDs, unchanged primary text, title/medium/genre from the
header (missing values remain missing), and token/segment counts. Empty source
documents remain here even if they have no segments.
\item \code{provenance}: reader/version, declared resource version, layer and
offset choices, format documentation, and SHA-256 of every consumed file.
}
The adapter returns \code{tokens} (a quanteda tokens object), \code{positions}
(all supplied token rows plus \code{quanteda_docname}), \code{segments}
(the segment table plus that mapping), and \code{provenance} (adapter and
quanteda versions, selected term column, counts and input fingerprint).
It accepts tables independently of the MASC reader. Save the reader's
provenance alongside the adapter result; the adapter cannot recover source
metadata absent from its input tables.
}
\examples{
if (requireNamespace("xml2", quietly = TRUE)) {
  header <- system.file("extdata", "masc-example", "example.anc",
                        package = "ldfreq")
  corpus <- lexdiv_read_masc(header, resource_version = "authored-example-1")
  corpus$tokens[c("surface", "lemma", "pos", "start", "end")]
  if (requireNamespace("quanteda", quietly = TRUE)) {
    words <- corpus$tokens[corpus$tokens$pos != ".", ]
    q <- lexdiv_as_quanteda(words, corpus$segments)
    quanteda::kwic(q$tokens, "re-use", valuetype = "fixed")
    quanteda::tokens_ngrams(q$tokens, n = 2:4)
  }
}
}
\seealso{\code{\link{lexdiv_ngrams}}, \code{\link{lexdiv_as_documents}}}
