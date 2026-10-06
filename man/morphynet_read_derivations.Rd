\name{morphynet_read_derivations}
\alias{morphynet_read_derivations}
\title{Read MorphyNet Derivational Relations from a Local File}
\usage{
morphynet_read_derivations(path, language, resource_version, max_rows = 1e6)
}
\arguments{
\item{path}{Local UTF-8 TSV file in the six-column MorphyNet derivational
format, without a header. No download or external runtime is invoked.}
\item{language}{Nonblank character scalar declaring the language, e.g.,
\code{"en"}. This is supplied metadata, not automatic language detection.}
\item{resource_version}{Nonblank character scalar identifying the source
version and any subset or modification, e.g., \code{"English v1"}.}
\item{max_rows}{Positive whole-number row ceiling, below the integer limit.
The reader stops if more rows are present. This is not a byte or total-memory limit.}
}
\description{
Reads supplied source word, target word, source POS, target POS, morpheme and
prefix/suffix fields. Preserves alternative relations and source identity for
inspection and optional keyword-in-context review. The complete English v1
file has been checked; the bundled nine-row excerpt is only a teaching example.
}
\value{
A plain list:
\describe{
\item{relations}{A data frame with character \code{relation_id}, integer
\code{source_line}, and six unchanged character fields: \code{source_word},
\code{target_word}, \code{source_pos}, \code{target_pos}, \code{morpheme},
\code{affix_position}. Original ordering, duplicates and literal \code{NA}
strings are retained. IDs include a shortened file hash and line number;
their interpretation requires the complete source hash in the metadata.}
\item{resource}{Scalar declarations including language/version, full source
SHA-256, citation, URLs, CC BY-SA 3.0 terms and derivational scope. Suitable for
the \code{resource} argument of \code{\link{lexdiv_ambiguity_review}}.}
\item{provenance}{Reader identity, row ceiling, observed rows, source hash,
transformation and interpretation limits. No local path is recorded.}
}
}
\details{
Use files obtained from the official MorphyNet repository under its CC BY-SA
3.0 conditions. This reader validates the format, not the linguistic accuracy,
language/version declarations or authenticity of arbitrary files. Missing,
empty, invalid UTF-8, over-limit and malformed files produce errors. The final
column must be \code{prefix} or \code{suffix}; the inflectional format is a
different input and is rejected. An initial UTF-8 BOM is consumed as an encoding
marker. Field whitespace, punctuation and POS symbols are not normalized.

The source uses symbols such as N, V, J, R and U; these are not silently
converted to Universal Dependencies tags. For example, its teach-to-teacher
row carries N/N, which should be inspected rather than silently corrected.
Full English v1 includes multiword fields; they are retained. The existing
ambiguity-review API supports single-token, whitespace-free target surfaces,
so a multiword target needs a separately defined alignment method.

A relation is one formation step, not a complete root/affix segmentation.
Reusability has three incoming relations in this snapshot: reuse with ability,
reusable with ity, and usability with re. These need not be mutually exclusive
claims. Do not add them as three observed affixes or treat graph connectivity
as educational word-family membership. Selecting one relation in a review
records an explicitly declared study analysis, not that other edges are false.
An absent target does not prove absence of morphology. This reader does not
lemmatize, infer inflections, predict learner knowledge or compute productivity.

The full English file is obtained separately. Only nine attributed example
rows and their original line mapping are bundled, under
\file{extdata/morphynet-example/}. Resource and conversion terms are recorded
under \file{licenses/morphynet/}; the independent R code remains MIT.
}
\references{
Batsuren, K., Bella, G., and Giunchiglia, F. (2021). MorphyNet: a Large
Multilingual Database of Derivational and Inflectional Morphology.
Proceedings of the 18th SIGMORPHON Workshop, 39--48.
\doi{10.18653/v1/2021.sigmorphon-1.5}
\url{https://github.com/kbatsuren/MorphyNet}
}
\seealso{\code{\link{lexdiv_ambiguity_review}}, \code{\link{morpholex_data}},
\code{\link{bnccoca_data}}}
\examples{
path <- system.file("extdata", "morphynet-example", "eng.derivational.example.tsv",
  package = "ldfreq", mustWork = TRUE)
reference <- morphynet_read_derivations(path, language = "en",
  resource_version = "English v1; nine-row teaching excerpt")
reference$relations[reference$relations$target_word == "reusability", ]
# For a complete, separately obtained English v1 file:
# reference <- morphynet_read_derivations("eng.derivational.v1.tsv", "en", "English v1")
}
