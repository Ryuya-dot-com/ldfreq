\name{lexdiv_align_annotations}
\alias{lexdiv_align_annotations}
\title{Align different token segmentations using original source positions}
\description{
Connects complete external annotations of the same original segments by
overlapping character intervals. Reports splits, merges, complex overlap,
exact-span correspondence and internal-boundary agreement. Optional single-label
evaluation is restricted to exact span pairs. This experimental function runs
no tokenizer, model or automatic adjudication.
}
\usage{
lexdiv_align_annotations(predicted, reference, column = NULL,
  labels = NULL, reference_info = NULL, context_chars = 30L,
  max_tokens = 1e6)
}
\arguments{
\item{predicted, reference}{
\code{\link{lexdiv_import_annotations}} results, unmodified,
with the same document/segment ID
pairs and exact original text, including empty segments. Token boundaries and
indices may differ. Results follow reference segment order. Complete imports
retain punctuation and all non-whitespace source text. Inputs with different
segment rosters are rejected, even if their concatenated text is identical.}
\item{column, labels, reference_info}{Omit all three for geometry alone, or
supply all three for optional label evaluation.

\code{\link{lexdiv_evaluate_annotations}} defines their requirements:
a plain character label column in both inputs, a complete unique label inventory,
and explicit reference declarations. Missing labels use \code{NA_character_}.
All supplied labels are
validated, including tokens excluded from conditional evaluation. No tagset
mapping or transfer of a compound's label to its parts is performed.}
\item{context_chars}{Non-negative whole number of original Unicode codepoints
on each side of a group's source span, limited to that segment. Zero gives
empty contexts. Positions are not byte offsets or grapheme-cluster indices.}
\item{max_tokens}{Positive whole-number limit for each imported token table;
not a total memory or source-size limit.}
}
\details{
The reference is the designated comparison baseline. Designating it does not
establish that its word units or labels are linguistically correct. Interpreting
differences as errors requires a declared annotation standard and suitable
independent reference data.

Token correspondence uses segment-local, one-based, inclusive Unicode codepoint
intervals. Connected components of overlapping intervals form groups; adjacency
alone does not connect them. One reference token with several predicted tokens
is a \code{split}; the converse is a \code{merge}. Several tokens on each side
form a \code{complex} component, with no inferred one-to-one pairing.
One token on each side is \code{exact} only if both endpoints match; otherwise
it is \code{changed_span}. Unmatched components are \code{reference_only} or
\code{prediction_only}. With complete imports these can arise from optional
whitespace tokens. Explicit whitespace tokens and punctuation participate in
all geometry counts; no filtering or normalization occurs.

An internal boundary is the ordered pair consisting of the left token's end
and the next token's start, within one segment. This preserves omitted
whitespace gaps and differences in whitespace ownership. Segment edges are
excluded: a zero- or one-token segment has no internal boundary. This explicit
junction measure is not an implementation of every external tokenizer
benchmark's boundary convention.

For token spans and internal boundaries separately, precision is matched divided
by predicted count, recall is matched divided by reference count, and F1 is
twice matched divided by the sum of the two counts. FP and FN are the unmatched
predicted and reference counts relative to this baseline. Zero denominators give
\code{NA}. For token spans, precision and recall also describe each side's
coverage by exact pairs eligible for label evaluation. These descriptive,
occurrence-weighted rates provide no confidence intervals or macro average.

Optional label evaluation uses only exact span pairs and retains both original
token indices, which can differ after an earlier split. Within this subset,
missing predictions on available references count as label false negatives;
unknown reference labels are not scored. Non-exact spans are excluded from
label TP/FP/FN, not counted as missing predictions. Thus even perfect conditional
label agreement can accompany poor overall correspondence. Report the geometry
counts and rates alongside conditional label results. Selection-based bias
cannot be corrected by treating the aligned subset as the whole corpus.

For downstream lexical metrics, use each complete input and its original
document roster, applying a declared selection and lexical-form policy. Using
only exact pairs would remove the very segmentation differences under study.
The annotation-alignment vignette demonstrates full-document TTR/MATTR with
fixed parameters and preserves empty/short-document missing results. POS
agreement does not measure word-sense or dependency-head accuracy.
}
\value{
A plain list containing:
\item{summary, documents}{Overall and per-document tables with two rows per
unit. The \code{measure} column identifies \code{token_span} or
\code{internal_boundary}.

Counts are \code{reference_n}, \code{predicted_n}, and \code{matched}.
Unmatched counts are \code{fp} and \code{fn};
rates are \code{precision}, \code{recall}, and \code{f1}.
Empty documents remain with zero counts and undefined rates.}
\item{groups}{Overlap components with \code{alignment_id}, source IDs,
union \code{start}/\code{end}, per-side token counts, \code{relation}, and
original context \code{pre}/\code{keyword}/\code{post}. IDs are local to this
result, not permanent across modified inputs.}
\item{members}{Every imported token exactly once, carrying its group ID,
\code{side}, original document/segment/token IDs, surface, positions and relation.

\code{label_eligible} is logical and describes geometry, not label availability.
When labels are requested, \code{label} retains the
chosen value even on excluded tokens. Other annotations remain in the complete
inputs; join by side and compound source IDs, not row numbers.}
\item{boundaries}{Union of observed internal junctions with source IDs and
positions \code{left_end} and \code{right_start}. Original left/right token
indices are retained for each side; absent indices are \code{NA}.

\code{outcome} is \code{matched}, \code{reference_only}, or
\code{prediction_only}.}
\item{review_queue}{All non-exact groups. These are differences to inspect,
not automatically errors. Optional label disagreements have their own queue.}
\item{annotation_evaluation}{\code{NULL} unless labels were requested;
otherwise contains tables \code{summary}, \code{labels}, and \code{documents},
plus \code{pairs}, \code{confusion}, and \code{review_queue}.

\code{\link{lexdiv_evaluate_annotations}} documents the scoring rules.
All label denominators are conditional on exact spans.

\code{reference_token_index} identifies the reference token in pair rows.

\code{predicted_token_index} identifies its counterpart.}
\item{predicted, reference}{Complete inputs, including auxiliary annotations,
segments, empty documents and provenance.}
\item{provenance}{Aligner ID/version, coordinate and boundary policies,
context window, optional label policy and reference declarations, interpretation
limits, and a content SHA-256 fingerprint. Save the full object with
\code{saveRDS()}; the hash does not authenticate reference judgments.}
}
\examples{
segments <- data.frame(document_id = "d", segment_id = "s",
  text = "can't read.")
metadata <- list(language = "en", analyzer = "authored",
  analyzer_version = "1", dictionary = "none",
  dictionary_version = "none", unit = "authored", normalization = "none")
ref <- data.frame(document_id = "d", segment_id = "s",
  token_index = 1:3, surface = c("can't", "read", "."))
pred <- data.frame(document_id = "d", segment_id = "s",
  token_index = 1:4, surface = c("ca", "n't", "read", "."))
x <- lexdiv_align_annotations(
  lexdiv_import_annotations(pred, segments, metadata),
  lexdiv_import_annotations(ref, segments, metadata))
x$groups
x$summary
}
\seealso{\code{\link{lexdiv_import_annotations}},
\code{\link{lexdiv_evaluate_annotations}}, \code{\link{lexdiv_metrics}}}
