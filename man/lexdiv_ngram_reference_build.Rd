\name{lexdiv_ngram_reference_build}
\alias{lexdiv_ngram_reference_build}
\title{Build an N-gram Reference from Whole-document Chunks}
\description{
Reads successive extractions and accumulates exact frequency and document
frequency without retaining every chunk's occurrence table. Reuses the
existing adjacent bigram/trigram extraction and reference contracts.
}
\usage{
lexdiv_ngram_reference_build(sources, read_chunk, resource, max_types = 1e6)
}
\arguments{
\item{sources}{Nonempty character vector of unique, nonempty UTF-8 source
labels, in processing order. These can be local paths or IDs understood by
\code{read_chunk}. Labels are recorded verbatim; choose portable labels if
the build record will be shared.}
\item{read_chunk}{Function taking one source label and returning an unmodified
\code{lexdiv_ngrams} result. Called once per source, sequentially. Each chunk
may contain several complete documents. A document ID, including an empty
document, must occur in exactly one chunk. All chunks must use the same
\code{preprocessing_id} and set of \code{n} values.}
\item{resource}{The eight resource metadata fields described in
\code{\link{lexdiv_ngrams}}. Identify the actual corpus, version, subset,
preparation, citation and terms. These are caller declarations.}
\item{max_types}{Positive whole-number limit on accumulated distinct n-gram
types across all requested \code{n}. Defaults to one million. Checked after
each callback and key construction, before summing combined counts.
This is not a limit on total memory or callback allocations.}
}
\value{
A plain list under experimental builder version 0.1.0:
\describe{
\item{reference}{A standard, complete \code{lexdiv_ngram_reference} object
usable by \code{lexdiv_ngram_profile()} and \code{lexdiv_ngram_compare()}.
Count rows follow first appearance across chunks; totals follow the first
chunk's \code{n} order. Different chunkings can change row order and hashes
while retaining the same counts and profile values.}
\item{sources}{Source-major rows with \code{source_id}, \code{n},
\code{opportunities}, \code{documents} and \code{extraction_sha256}.
Each source retains its own requested \code{n} order.}
\item{documents}{\code{source_id}/\code{document_id} roster, in chunk then
document order, including documents without any n-gram opportunities.}
\item{provenance}{Builder name/version, preprocessing ID, source order,
whole-document policy, retained information, type bound and network policy.}
}
The package makes no network calls here. A caller-supplied callback can have
side effects or access the network; the function does not sandbox it.
}
\details{
Document counts can be added only because document IDs do not recur across
chunks. Do not split one document between chunks or assign new IDs to its
parts to bypass this check. Keep sentence/utterance boundaries and original
position gaps inside each extraction. The builder validates declarations
and extraction fingerprints; it cannot prove equivalent preprocessing or
detect repeated passages under different document IDs.

Each chunk's counts and denominator are added without pruning. A limit breach
or invalid chunk stops the build; no partial result or automatic resume is
returned. A \code{complete} reference contains every observed key in the
supplied sample. It does not certify that the whole intended corpus was read
or that exclusions were unbiased. Maintain a separate input/exclusion audit.

Memory still grows with distinct types and the document/source roster. The
current implementation merges cumulative type tables in R after each chunk;
many small chunks can be slower than one larger extraction. The callback is
responsible for bounding its own extraction, for example through
\code{lexdiv_ngrams(max_ngrams = ...)}. This is an in-memory accumulator, not
an on-disk index. No additional package is required.

Save the full returned list with \code{saveRDS()} to preserve the build record.
It contains hashes, not source text or source bytes; archive the original
files and their annotation/preparation provenance separately when permitted.
}
\examples{
documents <- list(first = c("make", "a", "choice"),
                  second = c("make", "a", "plan"))
read <- function(id) {
  tokens <- data.frame(document_id = id, segment_id = "s",
    token_index = seq_along(documents[[id]]), term = documents[[id]])
  lexdiv_ngrams(tokens, "authored-v1")
}
resource <- list(resource_id = "authored_chunks", resource_version = "1",
  creator = "Example author", source_reference = "Two authored sequences",
  data_license = "Project-authored example", transformation_id = "none",
  lookup_unit = "adjacent_surface_ngram", resource_key_normalization_id = "identity")
built <- lexdiv_ngram_reference_build(names(documents), read, resource)
built$reference$counts
built$reference$totals
built$documents
}
\seealso{\code{\link{lexdiv_ngrams}}, \code{\link{lexdiv_ngram_compare}},
\code{\link{lexdiv_read_masc}}}
\keyword{text}
