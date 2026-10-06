\name{lexdiv_family_profile}
\alias{lexdiv_family_profile}
\title{Count resource-defined word families while retaining source occurrences}
\description{
Matches complete imported annotations against a caller-supplied word-family
table. This experimental function retains original tokens, candidate records,
context, resource definitions, document counts and unresolved occurrences.
It runs no morphological analyzer. Use \code{\link{bnccoca_data}} for the
bundled Nation inventory or supply a differently defined table explicitly.
}
\usage{
lexdiv_family_profile(annotations, dictionary, resource,
  unit = c("surface", "lemma", "flemma"),
  normalization = c("identity", "nfkc_lower"),
  exclude_pos = character(), context_chars = 30L,
  max_tokens = 1e6, max_candidates = 1e6, review = NULL)
}
\arguments{
\item{annotations}{Unmodified \code{\link{lexdiv_import_annotations}} result,
including all source tokens and original segments before exclusions. Supplied
\code{lemma}/\code{flemma} columns are required when selected. A \code{upos}
column using UD tags is required for POS matching or exclusion. Missing
annotations use character \code{NA}, never blank strings or underscores.}
\item{dictionary}{Plain data frame with character \code{record_id},
\code{form} and \code{family_id}. Record IDs must be unique and keys nonblank;
family IDs may repeat. An optional \code{upos} column requires exact UD POS
matching, without wildcards or missing values. Other columns (e.g., inclusion
level, frequency band) are retained without determining assignment. Empty
tables are allowed. Read CSV identifiers as character to preserve leading zeros.}
\item{resource}{Named list of nonblank character scalars. Required fields:
\code{resource_id}, \code{resource_version}, \code{language},
\code{source_reference}, \code{data_license}, \code{family_definition},
\code{lookup_unit}. The last must equal \code{unit}. Specify the inclusion
criteria and inventory version; license declarations do not grant rights.}
\item{unit}{Column used to match \code{dictionary$form}. No lemma or flemma
is inferred. This chooses the lookup key, not the output counting unit.}
\item{normalization}{\code{identity} is exact and case-sensitive.
\code{nfkc_lower} applies Unicode NFKC, trims whitespace and lowercases with
English locale to both lookup keys. Original surfaces and IDs are unchanged.
Normalized-key collisions retain all candidate families.}
\item{exclude_pos}{Unique UD tags to exclude explicitly, e.g.,
\code{c("PUNCT", "SYM")}. Default excludes nothing, including numerals and
proper nouns. Missing POS makes selection unknown when exclusions are requested.}
\item{context_chars}{Non-negative whole number of Unicode codepoints on each
side of a token, limited to its original segment.}
\item{max_tokens}{Positive whole-number input token row ceiling.}
\item{max_candidates}{Positive whole-number ceiling on dictionary rows and
on expanded occurrence-by-record rows, checked before expanding candidates.
Neither ceiling is a total memory or source-text size limit.}
\item{review}{Optional unmodified \code{\link{lexdiv_ambiguity_review}} result
created using this profile's \code{annotations} and \code{review_input}.
Decisions select dictionary \code{record_id} values, not family IDs.
Source, complete table, resource declarations and counting policy must agree.
Creating the single-token, whitespace-free surface review uses optional
\pkg{quanteda}; applying an already saved
review requires no quanteda calls. Default \code{NULL} uses lookup alone.}
}
\details{
Only one distinct candidate family permits assignment. Multiple records for
that same family retain their record IDs but count as one family candidate.
Different families are \code{ambiguous}; absent keys are \code{unlisted}.
There is no first-record choice, identity fallback or automatic sense selection.
\code{review_input} prepares the existing ambiguity-review interface. If its
\code{targets} is empty, there are no candidate-bearing forms to review.
Its display lists the union of candidate records for each original surface;
\code{candidates} retains exact eligibility by occurrence, selected unit and
POS. A record eligible only for another occurrence cannot be selected here.

Explicit \code{selected} judgments assign the chosen record's family to that
occurrence only. Explicit \code{unresolved} judgments withhold any automatic
assignment: a previously matched occurrence becomes \code{review_unresolved}.
Unreviewed occurrences retain their lookup result. Occurrences without eligible
candidates, POS-excluded or unknown-selection occurrences cannot be assigned
a candidate by override.
Changing annotations, dictionary contents or order, resource declarations,
lookup unit, normalization or exclusions requires a new review snapshot.
Changing context display widths does not. Snapshots detect inconsistent reuse,
not whether the reviewer's linguistic judgment is correct.

Selection is evaluated first: known excluded POS is \code{excluded}; missing
POS with exclusions is \code{unknown_selection}. Remaining occurrences may be
\code{missing_unit}, \code{missing_pos} (known unit but POS needed for lookup),
\code{unlisted}, \code{ambiguous} or \code{matched}. A manual veto can add
\code{review_unresolved}. No source row is removed.

\code{token_coverage} is matched tokens divided by selected tokens. It is
undefined when selection is unknown or the denominator is zero.
\code{conditional_token_coverage} uses only known-selected tokens; report
\code{unknown_selection_tokens} beside it. \code{observed_family_types} counts
families assigned among matched tokens. \code{family_types} and
\code{family_ttr} are \code{NA} if any non-excluded occurrence is unresolved;
otherwise TTR is family types divided by selected tokens. Empty or fully
excluded documents have zero family types and undefined TTR and coverage.
The pooled \code{summary} is not the mean of document-level metrics.
Counts and coverage describe final assignments, including explicit selections;
\code{lookup_status}/\code{lookup_family_id} preserve the automatic result.

If an inventory places \emph{use} and \emph{reusability} together, these remain
two tokens with one family type. This is not evidence that a learner knows
both words, that any particular inventory includes them together, or that
derivational morphology has been analyzed. Flemma, lemma and family definitions
are distinct. Inclusion levels and frequency bands are not interchangeable.
For other diversity measures, pass the ordered family IDs from complete
documents to \code{\link{lexdiv_metrics}}. Never drop unresolved tokens to
close gaps for MATTR; declare any POS-selected sequence explicitly.
}
\value{
A plain list containing:
\itemize{
\item \code{occurrences}: all source IDs, selected unit, surface, Unicode
positions, query, selection, status, candidate counts, assigned family and
\code{pre}/\code{keyword}/\code{post} context. Also retains
\code{lookup_status}, \code{lookup_family_id}, \code{review_status},
\code{review_record_id}, \code{reviewer} and \code{reason}.
\item \code{candidates}: occurrence IDs and matching record IDs, forms,
family IDs and optional POS. Join extra metadata by \code{record_id}.
\item \code{members}: matched counts \code{n} by document, family, original
surface and normalized query. Repeated tokens are not collapsed in occurrences.
\item \code{documents} and \code{summary}: total, excluded, known-selected,
unknown-selection, selected, matched and unresolved token counts; separate
unlisted, ambiguous, missing-unit, missing-POS and \code{withheld_tokens}
(previous matches withheld by explicit unresolved judgments); both coverage measures;
observed and complete family types; family TTR and status. Status is
\code{empty}, \code{no_selected_tokens}, \code{incomplete} or \code{complete}.
\code{review_selected_tokens} and \code{review_unresolved_tokens} count
explicit judgments; the latter may also include already ambiguous occurrences.
\item \code{review_input}: \code{targets}, \code{candidates} and
\code{resource} arguments for \code{lexdiv_ambiguity_review()}. Candidate IDs
are record IDs; labels/family IDs and optional POS remain in the display.
The generated \code{family_profile_sha256} binds review to the analysis snapshot.
\item \code{review}: the complete supplied review, or \code{NULL}.
\item Complete \code{annotations}, \code{dictionary}, and \code{provenance}
with resource declarations, unit, normalization, selection, coordinates,
method version, dictionary hash and complete-result hash.
}
Use composite document/segment/token IDs to join occurrences, not row numbers.
Save the complete result as RDS to retain inputs and policies for replay.
}
\references{
Bauer, L., and Nation, P. (1993). Word families.
\emph{International Journal of Lexicography}, 6(4), 253--279.
\doi{10.1093/ijl/6.4.253}.
}
\seealso{\code{\link{lexdiv_import_annotations}},
\code{\link{lexdiv_flemmatize}}, \code{\link{lexdiv_metrics}},
\code{\link{lexdiv_compare_ambiguity}}}
\examples{
env <- new.env(parent = baseenv())
sys.source(system.file("examples", "word-families.R", package = "ldfreq",
  mustWork = TRUE), env)
x <- env$word_families_example
x$profile$documents
x$profile$members
x$profile$occurrences[c("document_id", "keyword", "status", "family_id")]
x$comparison
if (requireNamespace("quanteda", quietly = TRUE)) {
  sys.source(system.file("examples", "word-family-review.R", package = "ldfreq",
    mustWork = TRUE), env)
  env$word_family_review_example$reviewed$documents
}
}
