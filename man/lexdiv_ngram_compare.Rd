\name{lexdiv_ngram_compare}
\alias{lexdiv_ngram_compare}
\title{Compare N-gram References on the Same Target Items}
\description{
Applies multiple reference frequency tables to one unchanged target extraction.
Reports each reference's coverage and available-value mean, then compares rates
on the items with defined values in every reference. Uses the existing
\code{lexdiv_ngram_profile()} arithmetic without re-extracting target tokens.
}
\usage{
lexdiv_ngram_compare(x, references, baseline = NULL, max_rows = 1e6)
}
\arguments{
\item{x}{An unmodified \code{lexdiv_ngrams} result, with explicit document,
segment and original-position information. Bigrams and trigrams stay separate.}
\item{references}{A plain named list of at least two unmodified
\code{lexdiv_ngram_reference} results. Names must be unique, nonempty UTF-8
labels and identify references in output. These labels are distinct from the
resource IDs in each reference's metadata. All references must support every
requested \code{n}, match the target's \code{preprocessing_id}, and agree on
\code{lookup_unit} and \code{resource_key_normalization_id}. These declarations
do not prove that the underlying preparation was equivalent.}
\item{baseline}{One name in \code{references}. Defaults to the first reference.
Differences are the current reference minus this baseline, in frequencies per
million eligible n-gram opportunities, using the common target items only.}
\item{max_rows}{Positive whole-number ceiling on combined lookup and summary
rows across references, checked before profiling. Defaults to one million.
This is not a total-memory limit.}
}
\value{
A plain list under comparison contract 0.1.0:
\describe{
\item{summary}{Reference-major rows containing \code{reference_id} and all
unchanged per-document, per-\code{n}, token/type-weighted profile summary
columns. Additional columns are \code{reference_opportunities},
\code{reference_documents}, \code{reference_complete}, \code{common_items},
\code{common_coverage}, \code{common_mean_frequency_per_million},
\code{difference_from_baseline}, and \code{comparison_status}.
Common coverage divides common items by all eligible target items.
Status is \code{"empty"} if there are no target items, \code{"no_common_values"}
if none has a defined rate in all references, and \code{"ok"} otherwise.
An \code{"ok"} status permits partial common coverage. Without common items,
common means and differences are missing. Empty-target coverage is also missing.}
\item{lookup}{Reference-major occurrence rows, retaining all profile lookup
columns and original target positions. Adds \code{reference_id}, logical
\code{common_available}, and \code{difference_from_baseline} for each common
occurrence. Non-common differences are missing even if that particular pair
of references has values.}
\item{documents}{Unchanged target document diagnostics, including empty
documents. No target documents are pooled.}
\item{references}{Reference-major, then reference-\code{n}-order rows with
\code{reference_id}, \code{n}, \code{opportunities}, \code{documents},
\code{complete}, the eight resource metadata fields, and \code{content_sha256}.
These are metadata and denominators, not copies of reference count tables.}
\item{provenance}{Comparison contract ID/version, baseline and reference
order, complete target/reference provenance, common-set and difference
definitions, denominator definition, row ceiling and network policy.}
}
Counts, rates and coverage columns are double; \code{n} is integer. Empty
target inputs retain typed zero-row lookup, summary and document tables.
The reference metadata table still describes the supplied references.
}
\details{
The common set is the intersection of \emph{defined rates} across all supplied
references. It includes a sample-zero rate for a key absent from a complete
reference with a positive denominator. It excludes unlisted keys in incomplete
references and all rates with zero reference opportunities. It is not restricted
to phrases observed in every reference. Adding a third reference may shrink
the common set and change all comparisons. To answer a pairwise question, pass
just that pair. There is no imputation, smoothing, ratio, automatic ranking or
inference test.

Token weighting retains repeated target occurrences. Type weighting uses each
exact component sequence once within its document and \code{n}. Available-value
means in the original profile columns can involve different items in each
reference; \code{difference_from_baseline} never subtracts those unmatched means.
It subtracts common-set means. A baseline difference of zero is returned only
when a common mean exists; otherwise it is missing, not zero.

Common coverage is an availability diagnostic, not proof of adequate reference
sample size. Two complete samples can have common coverage one even when many
target phrases were unobserved. Always inspect lookup coverage, sample sizes,
register composition and source overlap too. This comparison describes the
consequence of reference choice; it does not identify a superior reference,
estimate individual employability, or establish a proficiency scale.

Save \code{x}, \code{references} and the comparison together with
\code{saveRDS()} if the analysis must be rerun. The output records source
fingerprints and metadata but does not contain the full reference count tables.
No quanteda installation or locale change is needed by this comparison itself.
}
\examples{
tokens <- data.frame(document_id = "item", segment_id = "s",
  token_index = 1:3, term = c("make", "a", "choice"))
target <- lexdiv_ngrams(tokens, "authored-v1", n = 2)
resource <- list(resource_id = "authored_demo", resource_version = "1",
  creator = "Example author", source_reference = "Authored sequences",
  data_license = "Project-authored example", transformation_id = "none",
  lookup_unit = "adjacent_surface_ngram", resource_key_normalization_id = "identity")
counts <- data.frame(n = 2L, term1 = c("make", "a"),
  term2 = c("a", "decision"), term3 = NA_character_, count = c(3, 2),
  document_count = c(2, 1))
totals <- data.frame(n = 2L, opportunities = 5, documents = 2)
full <- lexdiv_ngram_reference(counts, resource, totals, "authored-v1", TRUE)
partial <- lexdiv_ngram_reference(counts[1, ], resource, totals, "authored-v1", FALSE)
compared <- lexdiv_ngram_compare(target, list(full = full, partial = partial))
compared$summary[c("reference_id", "weighting", "value_coverage",
  "mean_frequency_per_million", "common_coverage", "difference_from_baseline")]
}
\seealso{\code{\link{lexdiv_ngrams}}, \code{\link{lexdiv_read_masc}}}
\keyword{text}
