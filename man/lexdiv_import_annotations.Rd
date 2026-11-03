\name{lexdiv_import_annotations}
\alias{lexdiv_import_annotations}
\alias{lexdiv_as_annotations}
\alias{print.lexdiv_annotations}
\title{Import External Annotations or Bridge Raw Texts to Corpus Annotations}
\description{
\code{lexdiv_import_annotations()} aligns complete external token surfaces
(including Japanese morphological analyses) with original segment text.
\code{lexdiv_as_annotations()} bridges raw texts or \code{lexdiv_tokenization}
objects directly into sealed \code{lexdiv_annotations} objects ready for
\code{\link{lexdiv_concordance}}, \code{\link{lexdiv_collocations}},
\code{\link{lexdiv_keyness}}, \code{\link{lexdiv_ambiguity_review}}, and
\code{\link{lexdiv_family_profile}}.
}
\usage{
lexdiv_import_annotations(data, segments, provenance, max_tokens = 1e6)

lexdiv_as_annotations(
  documents,
  texts = NULL,
  id_col = "document_id",
  text_col = "text",
  normalization = "NFC",
  case = "lower",
  keep_numbers = FALSE,
  tokenizer = "english",
  language = "en",
  max_tokens = 1e6
)

\method{print}{lexdiv_annotations}(x, ...)
}
\arguments{
\item{data}{Data frame or tibble with character \code{document_id},
\code{segment_id}, \code{surface}, and consecutive positive \code{token_index}
covering all non-whitespace text in each segment.}
\item{segments}{Data frame or tibble with unique \code{document_id}/\code{segment_id}
pairs and UTF-8 \code{text}.}
\item{provenance}{Named list of scalar strings including \code{language},
\code{analyzer}, \code{analyzer_version}, \code{dictionary},
\code{dictionary_version}, \code{unit}, and \code{normalization}.}
\item{documents}{For \code{lexdiv_as_annotations()}, a named character vector,
a data frame/tibble with \code{id_col} and \code{text_col}, a single
\code{lexdiv_tokenization}, or a named list of \code{lexdiv_tokenization}
objects.}
\item{texts}{Original raw texts required only when \code{documents} supplies
\code{lexdiv_tokenization} objects (verified via \code{source_text_sha256}).}
\item{id_col, text_col}{Column selectors for data-frame inputs.}
\item{normalization, case, keep_numbers, tokenizer}{Preprocessing parameters
used when \code{documents} supplies raw texts directly.}
\item{language}{Language code recorded in provenance.}
\item{max_tokens}{Positive whole-number ceiling on total token rows.}
\item{x}{A \code{lexdiv_annotations} object.}
\item{...}{Additional arguments passed to \code{print.data.frame()}.}
}
\value{
A sealed \code{lexdiv_annotations} object containing \code{tokens},
\code{segments}, \code{documents}, \code{provenance}, and
\code{integrity_sha256} (used to verify that aligned source records remain
unmodified). When created by \code{lexdiv_as_annotations()},
\code{tokens} includes \code{is_word} (\code{TRUE} for lexical words,
\code{FALSE} for punctuation/excluded spans) and \code{term} (normalized/cased
word form or \code{NA_character_}). \code{print()} displays up to 12 token rows
and returns \code{x} invisibly.
}
\examples{
# Direct 1-line bridge from raw English texts:
ann <- lexdiv_as_annotations(c(
  d1 = "Hello, world! Cats chase dogs.",
  d2 = "Dogs bark loudly."
))
ann

# External morphological annotation import:
segments <- data.frame(document_id = "ja", segment_id = "s1",
  text = "\u732b\u304c\u6765\u305f\u3002")
tokens <- data.frame(document_id = "ja", segment_id = "s1", token_index = 1:5,
  surface = c("\u732b", "\u304c", "\u6765", "\u305f", "\u3002"))
x <- lexdiv_import_annotations(tokens, segments, list(
  language = "ja", analyzer = "authored", analyzer_version = "1",
  dictionary = "none", dictionary_version = "not-applicable",
  unit = "authored-example", normalization = "none"))
x
}
\seealso{\code{\link{lexdiv_concordance}}, \code{\link{lexdiv_keyness}},
\code{\link{lexdiv_tokenize}}}
