\name{lexdiv_family_profile}
\alias{lexdiv_family_profile}
\title{Count resource-defined word families while retaining source occurrences}
\description{
Count the word families represented in each document using an explicit
form-to-family inventory. The example below imports a small token table and
uses the bundled Nation inventory from \code{\link{bnccoca_data}}.
Original word occurrences and unresolved matches remain available for
inspection. This experimental function requires prepared tokens; it does
not tokenize raw text or run a morphological analyzer.
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
The first example is self-contained and needs no optional package or download.
It has three steps: import complete tokens with their original text, load the
family inventory, and call \code{lexdiv_family_profile()}. The short texts and
token boundaries were written for teaching; they are not analyzer output.
Nation's list uses uppercase forms, so the example explicitly selects
\code{normalization = "nfkc_lower"} to match the lowercase input.

Start by reading \code{profile$documents}. For \emph{listed}, the four tokens
\emph{use uses colour color} match two families: \code{family_types = 2},
\code{family_ttr = 2/4 = 0.5}, and \code{token_coverage = 1}. For
\emph{unlisted}, \emph{use} matches but \emph{reusability} does not occur in
this inventory: coverage is 0.5 and \code{observed_family_types = 1}, while
the whole-document \code{family_types} and \code{family_ttr} remain \code{NA}.
Do not interpret the observed count as the complete vocabulary or replace
unresolved families with zero. The empty document has zero family types and
undefined TTR and coverage.

Read \code{profile$members} for the matched forms within each family and
\code{profile$occurrences} to trace every match or missing assignment back to
its original position and context. The pooled \code{profile$summary} combines
documents; it does not replace their individual rows. Save the complete
\code{profile} as RDS to retain the inputs, inventory and analysis choices.

To use your own data, prepare the \code{segments} and \code{tokens} tables
shown below, keeping punctuation and the original segment text. The example
texts have no punctuation. To exclude punctuation in other texts, supply
documented UD \code{upos} tags and set \code{exclude_pos = c("PUNCT", "SYM")}
after import. Lemmas are only needed for \code{unit = "lemma"}; they are not
needed for this surface lookup. A \code{lexdiv_tokenize()} result is a different
object and cannot be passed directly as \code{annotations}. See the linked
word-family tutorial for CSV inputs, shared-token comparisons and review.

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
\code{\link{bnccoca_data}}, \code{\link{lexdiv_flemmatize}},
\code{\link{lexdiv_metrics}}, \code{\link{lexdiv_compare_ambiguity}},
\href{https://ryuya-dot-com.github.io/ldfreq/articles/word-families-and-affixes.html}{Word families, roots and affixes tutorial}}
\examples{
library(ldfreq)

# 1. Complete authored texts and their tokens. Empty documents have no
# token rows.
segments <- data.frame(
  document_id = c("listed", "unlisted", "empty"), segment_id = "s1",
  text = c("use uses colour color", "use reusability", "")
)
tokens <- data.frame(
  document_id = c(rep("listed", 4), rep("unlisted", 2)), segment_id = "s1",
  token_index = c(1:4, 1:2),
  surface = c("use", "uses", "colour", "color",
    "use", "reusability")
)
# Describe how these tokens were prepared; use your actual metadata for
# real data.
annotations <- lexdiv_import_annotations(tokens, segments, list(
  language = "en", analyzer = "authored-example",
  analyzer_version = "1",
  dictionary = "none", dictionary_version = "not-applicable",
  unit = "word", normalization = "none"
))

# 2. Load Nation's bundled inventory. It does not include REUSABILITY.
reference <- bnccoca_data()
profile <- lexdiv_family_profile(
  annotations, reference$dictionary, reference$resource,
  normalization = "nfkc_lower"
)

# 3. Read document totals together with coverage and status.
profile$documents[c("document_id", "selected_tokens", "matched_tokens",
  "token_coverage", "observed_family_types", "family_types",
  "family_ttr", "status")]
# listed: 4 tokens, 2 families, TTR 0.5, coverage 1, complete
# unlisted: 2 tokens, coverage 0.5; whole-document family count/TTR are NA
# empty: 0 tokens, 0 families; TTR and coverage are NA
profile$members
profile$occurrences[c("document_id", "keyword", "status", "family_id")]

# Save all inputs and choices, not only the displayed document table.
path <- tempfile(fileext = ".rds")
saveRDS(profile, path)
restored <- readRDS(path)
restored$documents
unlink(path)

# Advanced, separate authored review example; inspect the script before
# adapting it.
# Optional: install.packages("quanteda") to run the review example.
if (requireNamespace("quanteda", quietly = TRUE)) {
  env <- new.env(parent = baseenv())
  sys.source(system.file("examples", "word-family-review.R", package = "ldfreq",
    mustWork = TRUE), env)
  env$word_family_review_example$reviewed$documents
}
}
