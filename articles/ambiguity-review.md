# Review lexical ambiguity with KWIC and original context

External embeddings or model-scored candidates can be attached to these
same occurrences with
[`lexdiv_import_contextual()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_contextual.md).
See [the contextual model
guide](https://ryuya-dot-com.github.io/ldfreq/articles/contextual-models.md)
for checked source joins, missing-output coverage and an optional
Hugging Face example. Model suggestions remain separate from human
decisions.

A frequency table can give the same value to *bank* in a financial
context and *bank* beside a river. For an experiment or a corpus study,
the intended meaning may matter. This guide shows how to inspect each
occurrence with its context, keep possible interpretations, and record a
reviewed choice or an unresolved decision without losing its original
location.

[`lexdiv_ambiguity_review()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ambiguity_review.md)
is an experimental review interface. It reuses [quanteda’s KWIC
search](https://quanteda.io/reference/kwic.html), adding source
identity, explicit candidates and decisions. The examples are authored,
MIT-licensed illustrations, not corpus observations, dictionary extracts
or validated semantic annotations. There are no downloads or semantic
models. Install the optional quanteda package to run the review chunks;
Japanese KWIC also needs a UTF-8 R session.

## Prepare complete annotations and a candidate inventory

Import complete tokens, including punctuation, before review. Preserve
sentence/turn boundaries appropriate for your study. The following token
rows are supplied by hand to make the demonstration transparent. In
research, use complete annotations from an appropriate tokenizer or
morphological analyzer and inspect their alignment; successful import
does not validate their meaning.

``` r
segments <- data.frame(document_id = c("en", "en", "empty"),
  segment_id = c("s1", "s2", "s1"),
  text = c("The bank lent money.", "The river bank flooded.", ""))
tokens <- data.frame(document_id = "en", segment_id = rep(c("s1", "s2"), each = 5),
  token_index = rep(1:5, 2),
  surface = c("The", "bank", "lent", "money", ".", "The", "river", "bank", "flooded", "."))
x <- lexdiv_import_annotations(tokens, segments, list(
  language = "en", analyzer = "authored", analyzer_version = "1",
  dictionary = "none", dictionary_version = "not-applicable",
  unit = "authored-example", normalization = "none"))
candidates <- data.frame(term = c("bank", "bank"),
  candidate_id = c("bank-financial", "bank-river"),
  label = c("financial institution", "river edge"))
resource <- list(resource_id = "authored-illustration", resource_version = "1",
  source_reference = "Study-authored candidate inventory, not a dictionary",
  data_license = "MIT")
```

An actual candidate inventory can include reading, pronunciation, POS,
lexeme ID, sense ID and gloss columns. Keep these units separate.
Candidate IDs identify entries within this resource; a WordNet
synonym-set ID denotes a concept and should not automatically replace
lexical identity. Record the dictionary version and any transformation
in `resource`. Downloaded resources retain their own terms; no external
inventory is bundled here.

## Inspect a KWIC row and the complete original segment

``` r
review <- lexdiv_ambiguity_review(x, c("bank", "absent"), candidates, resource,
  window = 2)
review$occurrences[c("segment_id", "token_index", "pre", "keyword", "post",
  "candidate_count", "status")]
#>   segment_id token_index       pre keyword       post candidate_count
#> 1         s1           2       The    bank lent money               2
#> 2         s2           3 The river    bank  flooded .               2
#>       status
#> 1 unreviewed
#> 2 unreviewed
review$summary
#>     term candidate_count occurrences unreviewed selected unresolved
#> 1   bank               2           2          2        0          0
#> 2 absent               0           0          0        0          0
#>   no_candidates
#> 1             0
#> 2             0
```

There are two *bank* occurrences, each with two supplied candidates and
status `unreviewed`. A single candidate would still require review.
`no_candidates` means the supplied inventory has no entry, not that the
word has only one meaning. An absent target remains in the summary with
zero occurrences.

KWIC displays reconstruct token sequences with spaces. For exact
original text, inspect `segment_text` and its character offsets:

``` r
review$occurrences[c("document_id", "segment_id", "start", "end", "segment_text")]
#>   document_id segment_id start end            segment_text
#> 1          en         s1     5   8    The bank lent money.
#> 2          en         s2    11  14 The river bank flooded.
stopifnot(identical(stringi::stri_sub(review$occurrences$segment_text,
  review$occurrences$start, review$occurrences$end), review$occurrences$surface))
```

The window never crosses a supplied segment boundary. If a short window
is insufficient, enlarge it or read `segment_text`. To inspect
earlier/later sentences or turns, use document and segment IDs in
`review$source$segments`, which preserves input order and empty
segments. Sentence boundaries are not inferred. The original source,
rather than the space-separated KWIC display, is the basis for all
character positions.

## Record a choice, or explicitly leave it unresolved

Use the returned IDs, not row numbers, as decision keys. These decisions
are deliberately incomplete to illustrate a retained unresolved
occurrence; the second example sentence itself strongly suggests the
river sense.

``` r
decisions <- review$occurrences[c("review_id", "occurrence_id")]
decisions$status <- c("selected", "unresolved")
decisions$candidate_id <- c("bank-financial", NA_character_)
decisions$reviewer <- "example-reviewer"
decisions$reason <- c("The context describes lending money.",
  "This demonstration leaves the second occurrence for adjudication.")
# Sorting a review worksheet must not move decisions to other occurrences.
reviewed <- lexdiv_ambiguity_review(x, c("bank", "absent"), candidates, resource,
  decisions = decisions[2:1, ], window = 5)
reviewed$occurrences[c("segment_id", "surface", "candidate_id", "status", "reason")]
#>   segment_id surface   candidate_id     status
#> 1         s1    bank bank-financial   selected
#> 2         s2    bank           <NA> unresolved
#>                                                              reason
#> 1                              The context describes lending money.
#> 2 This demonstration leaves the second occurrence for adjudication.
reviewed$summary
#>     term candidate_count occurrences unreviewed selected unresolved
#> 1   bank               2           2          0        1          1
#> 2 absent               0           0          0        0          0
#>   no_candidates
#> 1             0
#> 2             0
stopifnot(identical(reviewed$occurrences$occurrence_id, review$occurrences$occurrence_id))
```

`selected` verifies that the named candidate belongs to the occurrence’s
surface form, not that the interpretation is linguistically correct.
`unresolved` records an explicit review without a selection. Occurrences
not included in `decisions` remain `unreviewed` or `no_candidates`.

The snapshot check rejects decisions from changed source text,
annotations, candidate values, target sets or resource versions.
Changing the KWIC window, reordering target/candidate rows, or sorting
the decision table is allowed. After a substantive change, generate a
new review and reconsider decisions; mechanically replacing the review
ID bypasses the protection. Save previous reviews separately if an audit
trail of revisions or independent raters is needed. This interface holds
one current decision per occurrence; it does not automatically
adjudicate disagreements. Keep each review intact, including its content
fingerprint, and change decision inputs rather than the output table.

## Edit a decision worksheet and apply it again

Use this workflow when you want to inspect occurrences in R or a
spreadsheet, record some decisions, and resume later. It uses the
existing review API and base R; the reading function defined below is a
tutorial recipe, not an exported ldfreq function. Run the section from
its first chunk in a fresh R session. It requires the optional quanteda
package and the installed text-file example from the [documented
installation](https://ryuya-dot-com.github.io/ldfreq/#installation).

### Know which table you are opening

| Table | One row represents | Use |
|----|----|----|
| Annotation import `$segments` / `$tokens` | One original segment / token | Check source text, boundaries, positions and available labels; retain the complete import |
| Review `$occurrences` | One target occurrence | Inspect KWIC, candidate count, current status and exact original context |
| Review `$candidates` | One supplied term–candidate pair | Inspect the inventory; its rows are not corpus occurrences |
| Review `$decisions` | One submitted occurrence decision | Record `selected` or `unresolved`, candidate ID, reviewer and reason |
| Text-batch `$token_audit` | One audited token occurrence | Inspect the analysis selection and exclusion reasons; this is a different output contract |

An English `lexdiv_tokenization` object and a complete external
annotation import are different inputs. This section starts with
[`lexdiv_import_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md).
For lemma/POS correction on an existing English tokenization, use the
[annotation sensitivity
example](https://ryuya-dot-com.github.io/ldfreq/articles/auditing-vocabulary-profiles.html#connect-annotation-changes-to-document-results).
For external annotations, reimport a complete corrected table and check
[position
alignment](https://ryuya-dot-com.github.io/ldfreq/articles/annotation-alignment.md).
Editing a sense decision does not change tokenization, lemma/POS or the
source text.

### Prepare and save a small complete review

These authored sentences deliberately include two occurrences of the
same word, a target without candidates, a document without any target,
and an empty document. The three candidate IDs are strings with leading
zeros. They are illustrations, not entries from a sense dictionary or
independently validated annotations.

``` r
library(ldfreq)
worksheet_segments <- data.frame(
  document_id = c("en", "en", "other", "empty"),
  segment_id = c("s1", "s2", "s1", "s1"),
  text = c("The bank lent money.", "The river bank flooded.", "Clouds move.", ""))
worksheet_tokens <- data.frame(
  document_id = c(rep("en", 10), rep("other", 3)),
  segment_id = c(rep("s1", 5), rep("s2", 5), rep("s1", 3)),
  token_index = c(1:5, 1:5, 1:3),
  surface = c("The", "bank", "lent", "money", ".",
    "The", "river", "bank", "flooded", ".", "Clouds", "move", "."))
worksheet_annotations <- lexdiv_import_annotations(
  worksheet_tokens, worksheet_segments,
  list(language = "en", analyzer = "authored", analyzer_version = "1",
    dictionary = "none", dictionary_version = "not-applicable",
    unit = "authored-example", normalization = "none"))
worksheet_candidates <- data.frame(term = c("bank", "bank", "money"),
  candidate_id = c("001", "002", "003"),
  label = c("financial institution", "river edge", "medium of exchange"))
worksheet_resource <- list(
  resource_id = "authored-worksheet", resource_version = "1",
  source_reference = "ldfreq authored worksheet example", data_license = "MIT")
worksheet_before <- lexdiv_ambiguity_review(worksheet_annotations,
  c("bank", "money", "river", "absent"), worksheet_candidates, worksheet_resource)

review_dir <- tempfile("ldfreq-review-")
dir.create(review_dir)
saveRDS(worksheet_before, file.path(review_dir, "review-before.rds"), version = 2)
```

For your study, use a persistent project directory such as
`"results/review-a"` and start with your own complete review. Keep each
reviewer’s directory and later adjudication separate. The saved RDS
contains the source text and inherits its sharing conditions. Do not
overwrite your original files or earlier rounds.

### Export context, candidates and editable decisions

The context and candidate CSVs are reference tables. The worksheet
contains fixed identifiers and location cues beside four editable
decision columns. Only the decision columns are sent back to the review
API. Filtering a display is fine; retain all worksheet rows when saving
this complete-sheet workflow.

``` r
worksheet_context <- worksheet_before$occurrences[c("review_id", "occurrence_id",
  "document_id", "segment_id", "token_index", "surface", "pre", "keyword", "post",
  "start", "end", "segment_text", "candidate_count", "status")]
worksheet <- worksheet_before$occurrences[c("review_id", "occurrence_id",
  "document_id", "segment_id", "token_index", "surface",
  "status", "candidate_id", "reviewer", "reason")]
worksheet$status[
  !worksheet$status %in% c("selected", "unresolved")] <- NA_character_
write.csv(worksheet_context, file.path(review_dir, "context.csv"),
  row.names = FALSE, na = "", fileEncoding = "UTF-8")
write.csv(worksheet_before$candidates, file.path(review_dir, "candidates.csv"),
  row.names = FALSE, na = "", fileEncoding = "UTF-8")
write.csv(worksheet, file.path(review_dir, "decisions-blank.csv"),
  row.names = FALSE, na = "", fileEncoding = "UTF-8")
worksheet_context[c("document_id", "segment_id", "surface", "pre", "post",
  "candidate_count", "status")]
#>   document_id segment_id surface           pre           post candidate_count
#> 1          en         s1    bank           The   lent money .               2
#> 2          en         s1   money The bank lent              .               1
#> 3          en         s2   river           The bank flooded .               0
#> 4          en         s2    bank     The river      flooded .               2
#>          status
#> 1    unreviewed
#> 2    unreviewed
#> 3 no_candidates
#> 4    unreviewed
worksheet_before$candidates
#>    term candidate_id                 label
#> 1  bank          001 financial institution
#> 2  bank          002            river edge
#> 3 money          003    medium of exchange
# In interactive R, View(worksheet_context) opens the reference table.
```

Import CSV columns **as text** in a spreadsheet, including
`candidate_id`; otherwise `001` may become `1`. Save CSV as UTF-8. You
can hide long ID columns for display, but retain their complete values.
Use the IDs to associate a row with context, even when the same word
occurs several times in one sentence. A candidate must belong to that
occurrence’s surface, not just exist elsewhere in the inventory.

| Fields | What to enter |
|----|----|
| `review_id`, `occurrence_id`, `document_id`, `segment_id`, `token_index`, `surface` | Keep unchanged; row order may change |
| `status` | `selected`, `unresolved`, or blank for an unsubmitted row |
| `candidate_id` | A valid candidate ID for `selected`; blank for `unresolved` |
| `reviewer`, `reason` | Both required for a submitted decision; leave both blank on an unsubmitted row |

Blank status is not a decision to leave a meaning unresolved. A row with
all four decision cells blank remains `unreviewed`, or `no_candidates`
when the inventory has no entry. A partly filled row is rejected so that
a typed reason or candidate is not silently discarded. The template
retains existing submitted decisions when you start from a previously
reviewed object; clearing all four cells explicitly removes that
decision in the new round. The old RDS remains the record of the
preceding round.

The following code **simulates editing** so the tutorial runs without
manual steps. In your study, edit a copy named `decisions-edited.csv`
and skip this simulation. Here the financial-bank occurrence is
selected, the river-bank occurrence is deliberately left unresolved, and
the other two rows are left unsubmitted. The river-bank sentence is
clear; its unresolved status illustrates workflow accounting, not a
claim that its interpretation is unknowable.

``` r
edited_sheet <- worksheet
finance_row <- which(edited_sheet$segment_id == "s1" &
  edited_sheet$surface == "bank")
river_row <- which(edited_sheet$segment_id == "s2" &
  edited_sheet$surface == "bank")
edited_sheet$status[c(finance_row, river_row)] <- c("selected", "unresolved")
edited_sheet$candidate_id[finance_row] <- "001"
edited_sheet$reviewer[c(finance_row, river_row)] <- "example-reviewer"
edited_sheet$reason[c(finance_row, river_row)] <- c(
  'The context mentions lending, so choose "financial institution".',
  "Demo: keep this case for a later review.\nNo selection submitted.")
# Simulate sorting the worksheet before saving.
edited_sheet <- edited_sheet[rev(seq_len(nrow(edited_sheet))), ]
write.csv(edited_sheet, file.path(review_dir, "decisions-edited.csv"),
  row.names = FALSE, na = "", fileEncoding = "UTF-8")
```

### Read, check and apply the edited file

This recipe uses the strict UTF-8 reader from the file-input tutorial.
It keeps the CSV’s byte hash and then parses every column as character.
Only empty cells mean missing; literal `NA` and `TRUE` remain text.
Quoted commas and line breaks in reasons are supported. CSV parsing can
convert CRLF inside quoted fields to LF, as explained in the [file-input
guide](https://ryuya-dot-com.github.io/ldfreq/articles/english-tokenization.html#import-text-files).

The reader requires the complete original row set, permits sorting,
checks the fixed cells by occurrence ID, and rejects partial or invalid
status entries. The existing review API then checks candidate
membership, required decision fields and whether the source/candidate
snapshot still matches.

``` r
input_helpers <- new.env(parent = baseenv())
sys.source(system.file("examples", "text-file-input.R", package = "ldfreq",
  mustWork = TRUE), input_helpers)
read_review_sheet <- function(path, before) {
  decoded <- input_helpers$read_text_file(path, encoding = "UTF-8")
  sheet <- read.csv(text = decoded$text, colClasses = "character",
    na.strings = "", check.names = FALSE)
  fixed <- c("review_id", "occurrence_id", "document_id",
    "segment_id", "token_index", "surface")
  editable <- c("status", "candidate_id", "reviewer", "reason")
  if (anyDuplicated(names(sheet)) || !setequal(names(sheet), c(fixed, editable)))
    stop(
      "Keep the original worksheet columns; edit only the four decision fields.")
  if (anyNA(sheet[fixed]) || anyDuplicated(sheet$occurrence_id) ||
      !setequal(sheet$occurrence_id, before$occurrences$occurrence_id))
    stop(
      "Keep every original occurrence ID exactly once, including unsubmitted rows.")
  row <- match(sheet$occurrence_id, before$occurrences$occurrence_id)
  for (field in fixed) {
    if (!identical(sheet[[field]],
      as.character(before$occurrences[[field]][row])))
      stop("A fixed worksheet field changed: ", field)
  }
  submitted <- !is.na(sheet$status)
  if (any(!sheet$status[submitted] %in% c("selected", "unresolved")))
    stop("Status must be selected, unresolved, or blank.")
  if (any(rowSums(!is.na(sheet[editable]))[!submitted] != 0L))
    stop(
      "An unsubmitted row is partly filled; finish or clear its four decision fields.")
  list(sheet = sheet, source = decoded$source,
    decisions = sheet[submitted,
      c("review_id", "occurrence_id", editable), drop = FALSE])
}
```

``` r
worksheet_saved <- readRDS(file.path(review_dir, "review-before.rds"))
worksheet_input <- read_review_sheet(
  file.path(review_dir, "decisions-edited.csv"), worksheet_saved)
worksheet_after <- lexdiv_ambiguity_review(worksheet_saved$source,
  worksheet_saved$summary$term, worksheet_saved$candidates,
  worksheet_saved$provenance$resource, decisions = worksheet_input$decisions,
  window = worksheet_saved$provenance$window)
worksheet_change <- lexdiv_compare_ambiguity(worksheet_saved, worksheet_after)
stopifnot(identical(worksheet_saved$source, worksheet_after$source),
  identical(worksheet_saved$occurrences$occurrence_id,
    worksheet_after$occurrences$occurrence_id),
  identical(worksheet_after$occurrences$status,
    c("selected", "unreviewed", "no_candidates", "unresolved")),
  identical(worksheet_after$occurrences$candidate_id[1], "001"))
worksheet_after$occurrences[c("document_id", "segment_id", "surface",
  "candidate_id", "status")]
#>   document_id segment_id surface candidate_id        status
#> 1          en         s1    bank          001      selected
#> 2          en         s1   money         <NA>    unreviewed
#> 3          en         s2   river         <NA> no_candidates
#> 4          en         s2    bank         <NA>    unresolved
```

The `worksheet_change` object compares two stages of one review. It is
not independent inter-rater agreement. The returned review contains
**all four** target occurrences, even though only two decisions were
submitted. Submitted decisions replace the current decision set; they
are not an incremental patch. Use a template from the latest saved
review to retain its existing decisions. Do not edit the returned review
object directly or replace its content fingerprint.

If application fails, correct the worksheet and apply it again from the
saved baseline. Changing the source text, annotations, targets or
candidate inventory requires a new review and renewed decisions;
changing IDs to force acceptance would destroy that correspondence. The
snapshot checks detect outdated inputs, not whether a human chose the
linguistically correct candidate or assigned a valid choice to the
intended occurrence.

### Summarize all documents and save the completed round

Count one row per target occurrence, not per candidate or decision.
Start from the complete source document list to retain the empty
document and the document without targets. Here “reviewed” means a
submitted selection **or** an explicit unresolved judgment. Its
denominator is the searched target occurrences, not all words, writers,
or only occurrences with candidates.

``` r
worksheet_report <- data.frame(
  document_id = unique(worksheet_after$source$segments$document_id))
occ <- worksheet_after$occurrences
where <- match(occ$document_id, worksheet_report$document_id)
worksheet_report$target_occurrences <- tabulate(where,
  nbins = nrow(worksheet_report))
for (state in c("selected", "unresolved", "unreviewed", "no_candidates")) {
  worksheet_report[[state]] <- tabulate(where[occ$status == state],
    nbins = nrow(worksheet_report))
}
worksheet_report$reviewed_proportion <- with(worksheet_report,
  ifelse(target_occurrences > 0,
    (selected + unresolved) / target_occurrences, NA_real_))
stopifnot(identical(rowSums(worksheet_report[
  c("selected", "unresolved", "unreviewed", "no_candidates")]),
  as.numeric(worksheet_report$target_occurrences)),
  identical(worksheet_report$target_occurrences, c(4L, 0L, 0L)),
  is.na(worksheet_report$reviewed_proportion[2]),
  is.na(worksheet_report$reviewed_proportion[3]))
knitr::kable(worksheet_report, digits = 2, col.names = c("Document", "Targets",
  "Selected", "Unresolved", "Unreviewed", "No candidates", "Reviewed / targets"))
```

| Document | Targets | Selected | Unresolved | Unreviewed | No candidates | Reviewed / targets |
|:---|---:|---:|---:|---:|---:|---:|
| en | 4 | 1 | 1 | 1 | 1 | 0.5 |
| other | 0 | 0 | 0 | 0 | 0 | NA |
| empty | 0 | 0 | 0 | 0 | 0 | NA |

``` r
worksheet_after$summary  # The absent target also remains, with zero occurrences.
#>     term candidate_count occurrences unreviewed selected unresolved
#> 1   bank               2           2          0        1          1
#> 2  money               1           1          1        0          0
#> 3  river               0           1          0        0          0
#> 4 absent               0           0          0        0          0
#>   no_candidates
#> 1             0
#> 2             0
#> 3             1
#> 4             0

worksheet_record <- list(before = worksheet_saved, input = worksheet_input,
  after = worksheet_after, comparison = worksheet_change,
  documents = worksheet_report, session = sessionInfo())
saveRDS(worksheet_record, file.path(review_dir, "review-after.rds"), version = 2)
write.csv(worksheet_report, file.path(review_dir, "review-counts.csv"),
  row.names = FALSE, na = "", fileEncoding = "UTF-8")
stopifnot(identical(readRDS(file.path(review_dir, "review-after.rds")),
  worksheet_record))
```

Two of four target occurrences have been reviewed; one has a selected
candidate. The zero-target documents have an undefined reviewed
proportion (`NA`), not 0%. These counts describe review progress, not
annotation accuracy or lexical ability. The original word forms and
token boundaries are unchanged, so a surface-based MATTR analysis of the
same text is unchanged too. A declared [word-family
workflow](https://ryuya-dot-com.github.io/ldfreq/articles/preprocessing-and-frequency.html#apply-contextual-judgments-to-individual-occurrences)
can apply reviewed membership candidates to its own accounting; a sense
choice does not automatically redefine a word family or recover
sense-specific frequency.

## Compare two reviews and return to open cases

[`lexdiv_compare_ambiguity()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_compare_ambiguity.md)
compares two reviews of the same source and candidate snapshot. It does
not search again. The next decisions are authored to demonstrate a
disagreement and a one-sided selection; they are not measurements of
annotator performance. In a study, collect independent decisions before
sharing them.

``` r
decisions_b <- review$occurrences[c("review_id", "occurrence_id")]
decisions_b$status <- "selected"
decisions_b$candidate_id <- c("bank-river", "bank-river")
decisions_b$reviewer <- "example-reviewer-B"
decisions_b$reason <- c("Deliberate conflicting choice for this demonstration.",
  "The sentence describes a river bank.")
review_b <- lexdiv_ambiguity_review(x, c("bank", "absent"), candidates, resource,
  decisions = decisions_b)
comparison <- lexdiv_compare_ambiguity(reviewed, review_b)
comparison$summary
#>   occurrences no_candidates a_reviewed b_reviewed both_reviewed both_selected
#> 1           2             0          2          2             2             1
#>   agreement disagreement selected_a_only selected_b_only neither_selected
#> 1         0            1               0               1                0
#>   both_selected_proportion agreement_among_both_selected
#> 1                      0.5                             0
comparison$review_queue[c("segment_id", "surface", "a_status", "b_status",
  "a_candidate_id", "b_candidate_id", "outcome")]
#>   segment_id surface   a_status b_status a_candidate_id b_candidate_id
#> 1         s1    bank   selected selected bank-financial     bank-river
#> 2         s2    bank unresolved selected           <NA>     bank-river
#>           outcome
#> 1    disagreement
#> 2 selected_b_only
comparison$status_pairs
#>   term   a_status b_status count
#> 1 bank   selected selected     1
#> 2 bank unresolved selected     1
```

Only the first occurrence has a selection in **both** reviews, and its
choices disagree. Thus conditional agreement is 0/1, while
joint-selection coverage is 1/2. The second occurrence is not an
agreement or a two-selection disagreement: one side remains unresolved.
Two unresolved decisions also do not count as semantic agreement. If
neither side selects any jointly reviewed case, the agreement
denominator is zero and the value is `NA`, not zero or one.

Always inspect the numerator, denominator, selection coverage and
target-level `comparison$terms` together. For example, 9 matching
choices among 10 jointly selected cases gives 90% conditional agreement;
if there were 100 target occurrences, it covers only 10% of them.
Difficult cases may be disproportionately unresolved. The overall result
pools occurrence counts; it is not an unweighted average of word-level
percentages or a reliability estimate for all corpus tokens.

`review_queue` includes original text, both KWIC windows and both
reasons for every non-agreement case. Some cases need more context or a
revised candidate inventory. Create a separate adjudicated decision
table and regenerate a review after resolving cases; neither reviewer
wins automatically. Keep the original reviews and comparison alongside
the adjudicated result. Post-discussion consensus must not be reported
as independent agreement.

This function supplies descriptive agreement, not kappa, alpha,
confidence intervals or evidence of correctness. Choosing a reliability
model requires attention to category definitions, rater sampling,
dependence and missingness; agreement alone cannot establish validity
([Artstein & Poesio, 2008](https://aclanthology.org/J08-4004/), sections
2.1–2.3). Sense candidates are term-specific, so pooling arbitrary
numeric candidate IDs across words into one chance-corrected calculation
is not justified automatically. The function can also compare two passes
by one person; it cannot establish that two reviewers worked
independently.

## Japanese readings and meanings need context too

The same spelling `人気` can appear with the reading *ninki*
(popularity) or *hitoke* (presence of people). This is a homograph
example, not a pair with the same pronunciation. Both candidates are
retained; the function does not infer a reading from the sentence or
discard a candidate using upstream POS.

``` r
ja_segments <- data.frame(document_id = "ja", segment_id = c("s1", "s2"),
  text = c("その店は人気がある。", "ここは人気がない。"))
ja_tokens <- data.frame(document_id = "ja", segment_id = rep(c("s1", "s2"), c(7, 6)),
  token_index = c(1:7, 1:6),
  surface = c("その", "店", "は", "人気", "が", "ある", "。",
              "ここ", "は", "人気", "が", "ない", "。"))
ja_provenance <- x$provenance$annotation
ja_provenance$language <- "ja"
ja <- lexdiv_import_annotations(ja_tokens, ja_segments, ja_provenance)
ja_candidates <- data.frame(term = c("人気", "人気"),
  candidate_id = c("popularity", "human-presence"),
  label = c("popularity", "presence of people"), reading = c("にんき", "ひとけ"))
ja_review <- lexdiv_ambiguity_review(ja, "人気", ja_candidates, resource, window = 2)
ja_review$occurrences[c("pre", "keyword", "post", "segment_text", "status")]
#>       pre keyword    post         segment_text     status
#> 1   店 は    人気 が ある その店は人気がある。 unreviewed
#> 2 ここ は    人気 が ない   ここは人気がない。 unreviewed
ja_review$candidates
#>   term   candidate_id              label reading
#> 1 人気 human-presence presence of people  ひとけ
#> 2 人気     popularity         popularity  にんき
```

For an actual local inventory, the installed WLSP helper reuses the
verified reader from the [Japanese norms
guide](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-norms.md).
Obtain the pinned WLSP-familiarity v4.0 CSV using that guide first. The
following chunk is explicit local-file work and is not run during
installation or site building:

``` r
source(system.file("examples", "wlsp-items.R", package = "ldfreq"))
inventory <- wlsp_ambiguity_candidates("人気", "japanese-resources/bunruidb-fam.csv")
wlsp_review <- lexdiv_ambiguity_review(ja, "人気",
  inventory$candidates, inventory$resource)
wlsp_review$occurrences[c("pre", "keyword", "post", "status")]
wlsp_review$candidates
inventory$coverage
```

This helper is explicitly sourced, not an exported package function. It
keeps WLSP record IDs as strings (including leading zeros), readings,
headings and classification fields. It does not choose candidates by
reading or POS and does not carry familiarity values into the candidate
table. Multiple records can share a reading or classification; their
count is not a validated count of distinct psychological senses. The
resource is a thesaurus-based inventory, not a context-sensitive
sense-disambiguation model.

The helper verifies the same v4.0 file hash as the norms reader and
records its source, citation and data license.
[WLSP-familiarity](https://github.com/masayu-a/WLSP-familiarity) is
distributed under CC BY-NC-SA 3.0; derived candidate/review data do not
acquire the package’s MIT license. No WLSP entries or ratings are
bundled with ldfreq. An empty candidate result remains explicit and does
not establish unambiguity.

For the [gibasa/UniDic
workflow](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-annotations.md),
pass the complete
[`lexdiv_import_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md)
result before excluding punctuation or missing lemmas. The current
review interface searches exact **surface** forms. A candidate table
keyed only by base form needs a separately reviewed mapping to the
observed surfaces; do not relabel it silently. General phrase KWIC
remains available through quanteda; multi-token sense decisions are
outside this initial interface.

To study English homophones such as *right/write*, supply both surface
targets and appropriate pronunciation/lexeme candidates. This function
retains supplied pronunciation columns but does not group homophones or
model dialect, stress or Japanese pitch accent. These require an
explicit phonological resource and an operational definition appropriate
to the presentation modality.

## Keep meaning judgments separate from frequency and outcome measures

The two *bank* occurrences receive the same value in an aggregate
form-frequency lookup, even after a reviewer chooses different meanings.
The same applies to `人気` in the [Japanese stimulus
workflow](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-stimuli.md).
A sense decision cannot recover sense-specific frequencies from an
aggregate table, and a spelling-based familiarity rating is not
automatically a rating for each of its senses. Missing decisions are not
zero frequency or zero knowledge.

For a separately obtained subjective polysemy estimate, follow the
[WLSP-norms
workflow](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-polysemy.md).
Its WIDs, displayed keys and classification labels need their own
reviewed mapping. They are not the WLSP-familiarity IDs, and its signed
estimates are not counts of meanings.

Candidate counts reflect inventory coverage and sense granularity, not a
learner’s knowledge. Related senses and unrelated meanings need not have
the same processing consequences ([Rodd et al.,
2002](https://doi.org/10.1006/jmla.2001.2810)). Semantic similarity and
association also require distinct definitions and validation ([Hill et
al., 2015](https://aclanthology.org/J15-4004/)). Neither is measured by
this review function. Human/automatic annotation accuracy and agreement
on the target population, register and task remain research questions.

For analysis, retain all occurrence IDs and status counts when joining
decisions to item or response data. If analysing only selected
occurrences, report the excluded/unresolved proportion by relevant
condition. A distribution of chosen senses in this reviewed sample is
not a general reference-frequency norm or evidence of each learner’s
ability to use every sense.

``` r
path <- tempfile(fileext = ".rds")
bundle <- list(review_a = reviewed, review_b = review_b, comparison = comparison)
saveRDS(bundle, path)
restored <- readRDS(path)
stopifnot(identical(restored, bundle))
unlink(path)
```

RDS preserves the complete source, candidate inventory, decisions and
metadata. For spreadsheet review, export only the decision worksheet
alongside a saved RDS review and read all ID columns as character on
return; use blank fields as missing candidate IDs for `unresolved`
decisions. The saved review contains original text and inherits its
sharing restrictions. Keeping a local review does not grant permission
to distribute a restricted corpus.
