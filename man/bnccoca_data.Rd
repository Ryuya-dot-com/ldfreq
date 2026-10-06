\name{bnccoca_data}
\alias{bnccoca_data}
\title{Read Nation's BNC/COCA Level 6 Word-Family Lists}
\usage{bnccoca_data()}
\description{
Reads an offline snapshot of Nation's BNC/COCA Level 6 lists, Version 1.0.0,
with original source membership, spelling and attribution. No model, download
or additional package is needed. These data use CC BY-SA 4.0.
}
\value{
A plain list with five components:
\describe{
\item{dictionary}{75,679 rows representing 25,000 families in frequency/range
bands 1--25. Each row includes character \code{record_id}, \code{form},
\code{family_id}, \code{headword}, \code{list_type}, \code{source_file} and
\code{range_flag}; integer \code{frequency_band} and \code{source_line};
and logical \code{is_headword}. Headwords are included as records.}
\item{supplementary}{29,798 rows with the same columns from lists 31--34:
proper names, marginal words, transparent compounds and acronyms. Their
\code{frequency_band} is \code{NA}. They are kept separate from the dictionary.}
\item{catalog}{Names, SHA-256 hashes, row counts, source family counts, list
types and inclusion flags for all 34 list files. Slots 26--30 are placeholders,
excluded from both analysis tables.}
\item{resource}{Scalar declarations suitable for
\code{\link{lexdiv_family_profile}} with \code{dictionary}: citation, version,
language, family definition, lookup unit, source and CC BY-SA 4.0 license.}
\item{provenance}{Archive URL and SHA-256, retrieval date, terms and information
URLs, transformation identifier and description. Save the whole list to retain
the supplementary-list and conversion information.}
}
}
\details{
Family membership follows source headwords and indented members. IDs are
scoped to the fixed snapshot and derive from source list/line positions.
Spellings remain uppercase as supplied; choose
\code{normalization = "nfkc_lower"} explicitly when matching lower-case text.
The final Range field \code{0} is retained as \code{range_flag}; it is not a
frequency count. No POS tags, senses or morphological analyses are inferred.

Bauer--Nation inclusion Level 6 is distinct from frequency/range bands 1--25.
No row-level affix inclusion level is supplied. The Level 3 partial lists are
a separate inventory, not a subset obtained by selecting frequency bands.
The bands reflect frequency, range and pedagogical decisions, not a raw corpus
frequency ranking. A reference match does not establish learner knowledge.

For example, this snapshot groups USE/USES and COLOUR/COLOR, but REUSABILITY
is unlisted. Do not silently assign it to USE from an authored illustration.
Supplementary membership does not perform contextual named-entity recognition.
If combining supplementary and core tables, declare the resulting scope in
the resource metadata and examine conflicting candidates. The default example
uses only \code{dictionary}.

The data and this conversion are CC BY-SA 4.0; independent R code remains MIT.
Retain attribution, changes and ShareAlike conditions when redistributing the
data. The complete license and notice are installed under
\file{licenses/bnccoca/}. Other bundled resources have separate terms.
}
\references{
Nation, I. S. P. (2017). The BNC/COCA Level 6 word family lists
(Version 1.0.0) [Data file]. Victoria University of Wellington.
\url{https://www.wgtn.ac.nz/lals/resources/paul-nations-resources/vocabulary-analysis-programs}

Bauer, L., and Nation, P. (1993). Word families.
International Journal of Lexicography, 6(4), 253--279.
\doi{10.1093/ijl/6.4.253}
}
\seealso{\code{\link{lexdiv_family_profile}}, \code{\link{morpholex_data}}}
\examples{
reference <- bnccoca_data()
reference$dictionary[reference$dictionary$form \%in\%
  c("USE", "USES", "REUSABILITY", "COLOUR", "COLOR"),
  c("form", "headword", "frequency_band")]

env <- new.env(parent = baseenv())
sys.source(system.file("examples", "bnccoca-families.R", package = "ldfreq",
  mustWork = TRUE), env)
profile <- env$bnccoca_example$profile
profile$documents[c("document_id", "selected_tokens", "matched_tokens",
  "unresolved_tokens", "family_types", "family_ttr", "status")]
}
