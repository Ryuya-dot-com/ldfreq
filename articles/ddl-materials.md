# Prepare teaching materials from reviewed examples

A teacher may want to choose clear, contrasting examples, ask learners
to explain patterns, and reuse the activity in another class. This guide
prepares **a learner handout and a separate teacher record from
explicitly reviewed source occurrences**. Learners need a browser or a
printed handout, not R. An R user prepares the search and runs the
input/output steps; a teacher can edit the selection and activity
tables.

Use development **ldfreq 0.4.0.9004 or later**; see the [installation
instructions](https://ryuya-dot-com.github.io/ldfreq/index.html#installation).
`ddl_material()` and `ddl_material_write()` are installed examples to
source explicitly, not exported functions. Construction revalidates the
existing phrase review and requires optional **quanteda \>= 4.5.0**.
Japanese input also requires a UTF-8 `LC_CTYPE` locale; the bilingual
demo runs in that environment. Reopening a completed material record and
writing it again uses only ldfreq’s required packages.

## Run the authored English and Japanese examples

``` r
demo <- new.env(parent = globalenv())
sys.source(system.file("examples", "ddl-materials-demo.R",
  package = "ldfreq", mustWork = TRUE), demo)
helper <- demo$helper
x <- demo$materials$en # Use $ja for the Japanese handout.
x$selected[c("phrase_id", "pre", "keyword", "post", "citation")]
#>   phrase_id             pre  keyword        post                       citation
#> 1 departure         Please  take off  your coat. ldfreq authored example: en s2
#> 2 departure The plane will  take off       soon. ldfreq authored example: en s1
x$candidate_summary
#>       status count
#> 1   accepted     5
#> 2   rejected     0
#> 3 unresolved     2
#> 4 unreviewed     3
```

The English examples contrast uses of *take off*. The Japanese examples
contrast contextual interpretations of *ashi o hippatta*. They are
authored, MIT-licensed illustrations with manually specified token
boundaries, not observations from a textbook corpus or an evaluation of
an automatic analyzer. The new teaching-selection criterion is separate
from the earlier phrase-sense review. Both clear interpretations can be
selected for comparison.

Each handout contains two selected examples. Other accepted, unresolved
and unreviewed candidates remain in the private record. Selecting
examples does not imply that the complete candidate collection has been
reviewed.

``` r
output <- tempfile("ldfreq-teaching-")
files <- helper$ddl_material_write(x, output)
stopifnot(identical(readRDS(files["record"]), x))
basename(files)
#> [1] "learner.html" "teacher.csv"  "material.rds"
```

For actual teaching, replace the temporary directory with a lasting
**new** directory inside an existing parent, for example
`"materials/lesson-01"`. An existing directory or file is rejected; the
writer never overwrites it. Open `learner.html` in a browser and print
using the paper size you need. Check the print preview at the intended
size, especially for long contexts or citations. Browser fonts and
pagination can differ.

| File | Audience and contents |
|----|----|
| `learner.html` | Selected original KWIC contexts, bold matched expressions, teacher-written prompts, response space, citations and usage notices. Self-contained UTF-8 HTML with print styling; no scripts or external assets. |
| `teacher.csv` | The same selected occurrences in display order, original segment text, IDs, source coordinates, decisions, prompts and teacher notes. UTF-8; import fields as literal text. |
| `material.rds` | Complete private record: original search and text, all decisions including pending ones, selection, activities, source declarations, settings and session. Keep it for reuse; do not distribute it as the learner handout. |

Teacher notes, decision reasons, unselected rows and complete source
records are not embedded in the learner file, including hidden elements.
The selected KWIC still includes its original surrounding text: inspect
that context before distribution. A selected context can contain another
expression that is also matched elsewhere in the review.

## Prepare your own reviewed candidates

Start with the [phrase-review
workflow](https://ryuya-dot-com.github.io/ldfreq/articles/annotated-corpora.html#review-phrase-matches).
It accepts complete source-aligned annotations and an explicitly
declared phrase list. Its existing search matches **at least two
tokens**, exactly and case-sensitively, by their original surface forms.
A word such as *influence* alone is outside this first recipe; an
explicitly tokenized sequence can be searched. Japanese inflections and
spelling variants are not automatically merged. Keep the analyzer,
dictionary, token unit and original text in the annotation record; see
[Japanese
annotations](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-annotations.md).

Use a criterion such as “clear contrasting contexts for this observation
task”. An example rejected for this activity is not thereby incorrect
language. The following continues from `before`, a
`phrase_list_review()` result:

``` r
write.csv(before$worksheet, "decisions.csv", row.names = FALSE,
  na = "<MISSING>", fileEncoding = "UTF-8")
# In the table, edit only status, reviewer and reason; keep every original row.
decisions <- read.csv("decisions.csv", colClasses = "character",
  check.names = FALSE, na.strings = "<MISSING>", encoding = "UTF-8")
review <- helper$phrase_list_review(before$source, before$criterion, decisions)
```

Use `accepted`, `rejected`, `unresolved` or `unreviewed` as documented
in that workflow. Only accepted IDs can be selected for a handout. You
need not finish reviewing every candidate, but pending candidates remain
pending in the saved record. A no-match target remains in the review’s
count table. A handout needs at least one selected example; no matches
or no accepted examples produce an input error rather than an empty
worksheet presented as a completed lesson.

## Supply the teaching tables

``` r
x$activities
#>   activity_id
#> 1     observe
#>                                                                                                                                                                                                                                                              prompt
#> 1 1. Compare the uses of the highlighted expression.\n2. Group the examples and underline the context supporting each interpretation.\n3. Explain your proposed distinction and check another example.\n4. Write your own example and explain the intended meaning.
#>                                                          teacher_note
#> 1 Teacher only: contrast a flight's departure with removing clothing.
x$items
#>                                                      occurrence_id activity_id
#> 1 5a93271e18c09f51f0859db14bc67e7a6d3ba6b9f2aa0a002425bb321c6d6aa2     observe
#> 2 c18d34d6f3910132a5b0cf972b1c88658b0e0cc2de243c7f263ee57fefafc19d     observe
x$sources
#>   document_id segment_id                       citation
#> 1          en         s1 ldfreq authored example: en s1
#> 2          en         s2 ldfreq authored example: en s2
#>                                                            usage
#> 1 MIT. Authored teaching examples; not observed corpus evidence.
#> 2 MIT. Authored teaching examples; not observed corpus evidence.
```

| Table | Required columns and interpretation |
|----|----|
| `activities` | Unique `activity_id`, learner-facing `prompt`, private `teacher_note` (use `""` if empty). Rows set activity order. |
| `items` | Unique accepted `occurrence_id` and its `activity_id`. Row order sets example order within each activity. Every activity must have an example; accepted examples not listed here are not distributed. |
| `sources` | `document_id`, `segment_id`, learner-facing `citation` and `usage`. Supply exactly one row for each selected source pair, with nonblank attribution and usage text. |

IDs and text columns must be character vectors without missing values.
These tables can be stored as UTF-8 CSV and read with
`colClasses = "character"`. The activity prompt can contain several
numbered questions separated by newlines. Teacher notes can describe the
intended contrast, alternative interpretations or discussion points;
they are not automatically correct answers. The source `usage` text is a
declaration supplied by the teacher, not an automated license check or
permission grant.

``` r
rebuilt <- helper$ddl_material(
  review = x$review,
  activities = x$activities,
  items = x$items,
  sources = x$sources,
  title = x$title,
  language = "en" # "ja" changes the fixed handout labels.
)
stopifnot(identical(rebuilt$selected, x$selected))
```

Every input string is treated as literal text, not HTML or Markdown.
Emphasis is applied only to the original matched span. No source text is
rewritten, normalized or silently shortened. Formula-like character
fields in the teacher CSV receive an apostrophe prefix for display; the
unmodified values remain in the RDS. This CSV is an output reference,
not the editable review worksheet.

Different phrase IDs at the same or nested source spans remain different
candidates. Choose which ones to distribute; the recipe does not
silently deduplicate them or convert their selected proportions into
corpus frequencies. The material fingerprint detects accidental changes;
it does not establish that annotation, attribution, permissions or
pedagogical judgments are correct.

## Design the observation task

The authored prompts ask learners to compare contexts, group
interpretations, explain their evidence, check another example, and
produce their own use. The teacher supplies the further example and
decides how to discuss competing explanations. Neither highlighting an
expression nor deleting a word by itself establishes an effective
data-driven learning activity.

Use the [textbook progression
guide](https://ryuya-dot-com.github.io/ldfreq/articles/textbook-progression.md)
to inspect where target expressions recur and choose revision
opportunities. That concordance record and the phrase-review record have
different input formats and IDs; they are not interchangeable. A general
corpus, a local textbook and a selected classroom worksheet also
represent different collections. Retain their source and selection
boundaries instead of treating the handout as a representative frequency
sample.

This recipe does not download corpora, parse textbook PDFs, infer
teaching level, generate readings or furigana, choose examples by a
quality score, collect learner responses or grade them. Such
information, when needed, must come from an explicit source or teacher
judgment. Actual preparation time, classroom usability and learning
outcomes have not been evaluated.

## Reopen and reproduce without a new search

``` r
library(ldfreq)
helper <- new.env(parent = globalenv())
sys.source(system.file("examples", "ddl-materials.R",
  package = "ldfreq", mustWork = TRUE), helper)
saved <- readRDS("materials/lesson-01/material.rds")
helper$ddl_material_write(saved, "materials/lesson-01-copy")
```

This uses the stored examples and original session record without
loading quanteda or searching again. To change the selection or prompts,
rebuild with `ddl_material()` from the saved review and revised teaching
tables. Do not edit the sealed record or its fingerprint to bypass the
source checks.
