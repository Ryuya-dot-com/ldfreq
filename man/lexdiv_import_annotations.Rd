\name{lexdiv_import_annotations}
\alias{lexdiv_import_annotations}
\title{Align complete external token annotations with original text}
\description{
Imports external annotations, including Japanese morphological analyses, as
plain tables with verified source positions and declared analysis metadata.
No analyzer, dictionary, corpus, or language-specific segmentation is bundled
or invoked. This is an experimental input interface.
}
\usage{
lexdiv_import_annotations(data, segments, provenance, max_tokens = 1e6)
}
\arguments{
\item{data}{Plain data frame with character \code{document_id}, \code{segment_id},
and \code{surface}, and positive whole-number \code{token_index}. Import all
tokens, including punctuation, in segment order before excluding any rows.
Indices must start at 1 and be consecutive within each segment. Additional
columns, such as \code{lemma}, \code{orthBase}, readings, POS, unknown flags,
and raw features, are preserved without interpretation or imputation.
If \code{start}/\code{end} are supplied, they must agree with the derived
segment-local, 1-based, inclusive Unicode codepoint positions.}
\item{segments}{Plain data frame with unique character \code{document_id}/
\code{segment_id} pairs and the original UTF-8 \code{text} for each segment.
Include empty segments/documents. At least one segment is required; each
document occupies one contiguous block. Segment boundaries, including sentence
or turn boundaries, are supplied by the caller, not inferred. Additional
columns survive. \code{token_count} and \code{text_sha256} are reserved.}
\item{provenance}{Named plain list of scalar, non-empty UTF-8 strings including
\code{language}, \code{analyzer}, \code{analyzer_version}, \code{dictionary},
\code{dictionary_version}, \code{unit}, and \code{normalization}. Record actual
upstream settings. Use explicit \code{"unknown"} or \code{"not-applicable"}
labels when appropriate; they do not establish reproducibility. Optional
fields, such as dictionary file hashes, user-dictionary versions, configuration,
source reference and license, may be strings or \code{NA_character_}.
These are caller declarations, not independently authenticated metadata.}
\item{max_tokens}{Positive whole-number ceiling on input token rows, checked
before alignment. This is not a total memory or source-text size limit.}
}
\details{
Surfaces are matched exactly, in order, against the supplied original segment
text. Unicode whitespace may occur between tokens and before/after them. A
token starting with whitespace begins at the current cursor; other tokens
begin after any whitespace at that cursor. All non-whitespace text must be
accounted for. Omitted punctuation, replaced characters, wrong ordering, and
skipped repeated words therefore cause an error. Neither text nor surfaces
are normalized. Combining marks and supplementary characters count as Unicode
codepoints, not graphemes, bytes or UTF-16 code units.

Positions refer to \code{segments$text}, not to a concatenated document or
to normalized text. If upstream preprocessing changed the original surfaces,
supply the actual analyzed text and retain its relationship to the original
separately; this importer does not invent that mapping. Supplied segment
boundaries are not checked against an unsupplied full document.

Import before selecting lexical forms and excluding punctuation, function
words or missing lemmas. Keep \code{token_index} unchanged after exclusions:
\code{\link{lexdiv_ngrams}} and \code{\link{lexdiv_as_quanteda}} then retain
gaps instead of creating false neighbors. Core diversity measures accept the
explicitly retained sequence; their interpretation depends on that selection.
Keep selection settings and missingness counts with the imported object.

Surface, orthographic base and lexeme are different analytical choices. The
importer does not translate source POS to UPOS, infer unknown-word status,
merge Japanese homographs, or establish compatibility with a frequency table.
The bundled NJ8 and TUBELEX profiles are English resources. See the Japanese
annotations vignette for an R-only gibasa/UniDic recipe. Other analyzers may
provide these same columns; successful alignment is not evidence of accurate
morphology or cross-language measurement equivalence.
}
\value{
A plain list with:
\item{tokens}{Input token columns plus verified integer \code{start} and
\code{end}; existing coordinate columns are validated and replaced by these
integers. UTF-8 ID/surface encoding labels and row names are canonicalized.}
\item{segments}{Input segment columns plus original integer \code{token_count}
and \code{text_sha256}, the SHA-256 of each UTF-8 text string.}
\item{documents}{One \code{document_id} per document, in input order, including
those with no tokens.}
\item{provenance}{Importer ID/version, coordinate convention, alignment rule,
importer normalization (always \code{"none"}), caller metadata in
\code{annotation}, and \code{input_sha256} of the canonical input tables and
declarations. Hashes describe the imported snapshot, not later modifications;
they are reproducibility labels, not authentication or license verification.}
The list can be saved with \code{saveRDS()} and read with \code{readRDS()}.
It is not a \code{lexdiv_tokenization} object and is not an input to
\code{lexdiv_compare_annotations()}, whose one-to-one contract is unchanged.
}
\examples{
# Authored illustration, not automatic morphological analysis.
segments <- data.frame(document_id = "ja", segment_id = "s1",
  text = "\u732b\u304c\u6765\u305f\u3002")
tokens <- data.frame(document_id = "ja", segment_id = "s1", token_index = 1:5,
  surface = c("\u732b", "\u304c", "\u6765", "\u305f", "\u3002"))
x <- lexdiv_import_annotations(tokens, segments, list(
  language = "ja", analyzer = "authored", analyzer_version = "1",
  dictionary = "none", dictionary_version = "not-applicable",
  unit = "authored-example", normalization = "none"))
x$tokens
lexdiv_metrics(x$tokens$surface[1:4], metrics = "ttr")
lexdiv_ngrams(x$tokens[1:4, ], "authored-surface-v1", term_col = "surface")
}
\seealso{\code{\link{lexdiv_ngrams}}, \code{\link{lexdiv_as_quanteda}},
\code{\link{lexdiv_metrics}}, \code{vignette("japanese-annotations", package = "ldfreq")}}
