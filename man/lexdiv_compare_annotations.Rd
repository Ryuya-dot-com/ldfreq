\name{lexdiv_compare_annotations}
\alias{lexdiv_compare_annotations}
\title{Compare annotation versions on identical tokenized documents}
\usage{
lexdiv_compare_annotations(before, after, max_tokens = 1e6)
}
\arguments{
\item{before,after}{Two \code{lexdiv_tokenization} objects, or two plain named
lists of these objects. Batches must have exactly the same unique document IDs.
Annotation layers may be absent; original text and tokenization must match.}
\item{max_tokens}{Positive integer limit on the total paired token positions,
checked before constructing token-level comparison tables.}
}
\description{
Checks one-to-one token alignment and compares lemma, UPOS and flemma labels
without modifying either input. This supports auditing revised annotations and
explicit alternative counting schemes.
}
\value{
A plain list with three components:
\describe{
\item{documents}{One row per document, including empty documents, with
\code{document_id}, \code{tokens}, \code{before_has_*}/\code{after_has_*} for
each of \code{lemma}, \code{upos}, and \code{flemma}, the corresponding
\code{*_changed_tokens} counts, and \code{changed_tokens}, the count of positions
changed in at least one layer.}
\item{changes}{Only positions where a label differs. Columns are
\code{document_id}, \code{token_index}, \code{start}, \code{end}, \code{surface},
and \code{before_*}, \code{after_*}, \code{*_changed} for each layer.
Offsets are those of the processed text, as in \code{lexdiv_tokenize()}.}
\item{provenance}{Complete \code{before} and \code{after} preprocessing lists,
each named by document ID, including annotation backend labels and versions.}
}
Single inputs use \code{document_1}. Batch order follows \code{before};
\code{after} is matched by ID, never by its input position. Zero-document
batches produce empty tables and named provenance lists.
}
\details{
The comparison requires equal original and processed text hashes, tokenizer
identity/version, normalization, case, number policy, token pattern, character
counts and base token rows. It therefore rejects edited texts and differently
tokenized inputs even if their retained word strings happen to agree. Use
separate sensitivity analyses for those changes. The recorded hashes detect
ordinary inconsistency; they do not authenticate the original texts.

Absent annotation columns are represented as missing labels for token-level
comparison. Two missing labels are unchanged; missing-to-value and
value-to-missing transitions count as changes. Layer-presence columns distinguish
an absent layer from an existing layer containing only missing values, including
on empty documents. Changes in backend or resource metadata alone do not create
token change rows; inspect both complete provenance records.

A difference is not an annotation error, linguistic improvement or proficiency
gain. A morphologically refined counting key can legitimately differ from a
base lemma. The function does not infer POS, tense or mood, choose a counting
scheme, correct spellings, or calculate metric differences. It does not assert
dictionary identity from a backend version: retain the actual resource and its
version separately when that identity is not recorded by the annotator.
Unchanged flemma labels with different match-rule metadata are likewise visible
in the original objects/provenance rather than counted as changed labels.

Save both prepared inputs with the comparison to preserve unchanged annotation
rows and resource details. The comparison contains text-derived surface and
annotation labels and is not an anonymization step.
}
\examples{
tokens <- lexdiv_tokenize("Students saw students.", case = "lower")
base <- lexdiv_lemmatize(tokens,
  lemmas = c("student", "see", "student"),
  backend_id = "authored-annotations", backend_version = "base-v1")
refined <- lexdiv_lemmatize(tokens,
  lemmas = c("student", "see_VERB_Ind_Past", "student"),
  backend_id = "authored-annotations", backend_version = "tense-v1")
audit <- lexdiv_compare_annotations(base, refined)
audit$documents
audit$changes

before <- list(essay = base, blank = lexdiv_tokenize(""))
after <- list(blank = lexdiv_tokenize(""), essay = refined)
lexdiv_compare_annotations(before, after)$documents
}
\seealso{\code{\link{lexdiv_preprocessing}}, \code{\link{nj8_diagnostics}}}
\keyword{text}
