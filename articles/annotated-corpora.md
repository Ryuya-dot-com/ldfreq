# From corpus annotations to quanteda and lexical profiles

Suppose a corpus already provides token boundaries, lemmas and
part-of-speech tags. Retokenizing the text can change the units being
counted. This guide imports those annotations, uses **quanteda** for
n-grams and concordances, and keeps the IDs and positions needed to
inspect the original evidence.

The example is an original, MIT-licensed text with authored annotations,
included with ldfreq. It runs offline. It is not a sample of MASC and is
not a frequency norm. Install the optional `xml2` and `quanteda`
packages to run the corresponding steps; no Python or AntConc
installation is needed.

## Read an annotated document

``` r
header <- system.file("extdata", "masc-example", "example.anc", package = "ldfreq")
corpus <- lexdiv_read_masc(header, resource_version = "authored-example-1")
corpus$tokens[c("annotation_id", "segment_id", "token_index",
                "surface", "lemma", "pos", "start", "end")]
#>   annotation_id segment_id token_index surface  lemma pos start end
#> 1            t0         s0           1      We     we PRP     1   2
#> 2            t1         s0           2  re-use re-use VBP     4   9
#> 3            t2         s0           3   words   word NNS    11  15
#> 4            t3         s0           4       .      .   .    16  16
#> 5            t4         s1           1      We     we PRP    18  19
#> 6            t5         s1           2      go     go VBP    21  22
#> 7            t6         s1           3       .      .   .    23  23
```

The text is `We re-use words. We go.` The supplied annotation treats
`re-use` as one token, assembled from three adjacent source regions. The
reader keeps that decision and returns `words` with the supplied lemma
`word`. It does not correct the tags, invent missing lemmas, or
translate Penn tags into UPOS.

`start` and `end` are 1-based inclusive Unicode-codepoint positions in
the unchanged primary text. Original zero-based, end-exclusive anchors
remain in `start_anchor` and `end_anchor`. For a source whose anchors
count UTF-16 code units, specify `offset_unit = "utf16"`. UTF-8 file
encoding alone does not tell you which coordinate convention an
annotation uses.

The document table retains original text and available header metadata.
The segment table retains the supplied sentence/utterance regions,
including regions without tokens. A completely empty document may have
no segment rows; its existence remains in `corpus$documents` and must be
retained when setting document-level denominators.

## Transfer selected tokens without closing gaps

Choose exclusions explicitly. Here punctuation is identified by the
authored Penn tag `.`. This small example is not a complete punctuation
policy for all corpora or tagsets.

``` r
words <- corpus$tokens[corpus$tokens$pos != ".", ]
q <- lexdiv_as_quanteda(words, corpus$segments)
as.list(q$tokens)
#> $segment_1
#> [1] "We"     "re-use" "words"  ""      
#> 
#> $segment_2
#> [1] "We" "go" ""
quanteda::docvars(q$tokens)[c("document_id", "segment_id", "token_count")]
#>   document_id segment_id token_count
#> 1     example         s0           4
#> 2     example         s1           3
quanteda::ntoken(q$tokens, remove_padding = TRUE)
#> segment_1 segment_2 
#>         3         2
```

Every quanteda document represents one original segment. `docvars`
connects it to the original document. Removed token positions remain
empty padding, including at segment ends. Keep `token_index` and the
segment’s original `token_count` unchanged when filtering. Renumbering
after removing `a` from `make a decision` would incorrectly create the
adjacent bigram `make decision`. The adapter preserves gaps; it cannot
reconstruct positions already discarded.

For supplied lemmas, use `term_col = "lemma"`. Missing or multiword
values require an explicit decision and are rejected by the adapter. To
compare surface and lemma analyses, retain both sets of settings and
results rather than overwriting one analysis.

For non-ASCII terms, run the quanteda step in an R session with a UTF-8
`LC_CTYPE` locale (`l10n_info()[["UTF-8"]]` should be `TRUE`). The
adapter rejects other locales because the public quanteda import can
alter such terms. It does not change the session locale. This
restriction does not apply to the reader’s UTF-8 text and
source-coordinate conversion.

This is a setting of the running R session, not a restriction on Macs.
Check the session used for your analysis:

``` r
l10n_info()[["UTF-8"]]
#> [1] TRUE
```

If this returns `TRUE`, no locale change is needed. `C.UTF-8` is
UTF-8-capable; it is different from the plain `C` locale used in an
encoding stress test. RStudio, R.app and terminal R can start with
different environment settings, so check the session where you run the
analysis. The package does not require changing your Mac’s display
language. See [R’s locale
documentation](https://stat.ethz.ch/R-manual/R-devel/library/base/html/locales.html).

## Use quanteda for n-grams and original-document frequencies

``` r
ng <- quanteda::tokens_ngrams(q$tokens, n = 2:4)
segment_counts <- quanteda::dfm(ng, tolower = FALSE)
document_counts <- quanteda::dfm_group(
  segment_counts, groups = quanteda::docvars(ng, "document_id")
)
quanteda::topfeatures(document_counts)
#>       We_re-use    re-use_words We_re-use_words           We_go 
#>               1               1               1               1
quanteda::docfreq(document_counts)
#>       We_re-use    re-use_words We_re-use_words           We_go 
#>               1               1               1               1
```

Grouping matters: counting how many segments contain a phrase does not
give the number of original documents containing it. This example has
one original document and two segments. The returned tables do not
establish population prevalence, proficiency, or lexical employability.

`tolower = FALSE` preserves the case of the supplied tokens. The default
of `dfm()` lowercases features, which changes case-sensitive frequency
tables. Choose the same case policy for targets and references and
record it.

Quanteda already supports four-word and longer n-grams. The ldfreq
adjacent reference API currently supports only bigrams and trigrams, so
a quanteda four-gram table is not yet interchangeable with that
reference format. Also retain component keys when preparing reference
tables: splitting a concatenated feature on `_` is ambiguous if a
component already contains `_`.

## Return from a result to a source annotation

Search the original token object, not the n-gram token object whose
positions refer to a transformed sequence.

``` r
hits <- as.data.frame(quanteda::kwic(q$tokens, "re-use", valuetype = "fixed"))
locations <- q$positions[c("quanteda_docname", "token_index", "document_id",
                           "annotation_id", "start", "end")]
evidence <- merge(hits, locations,
  by.x = c("docname", "from"), by.y = c("quanteda_docname", "token_index"))
evidence[c("keyword", "document_id", "annotation_id", "start", "end")]
#>   keyword document_id annotation_id start end
#> 1  re-use     example            t1     4   9
```

This joins the start of a hit. For a multi-token phrase, also join its
`to` position to obtain the final token’s character endpoint. The
mapping applies to the returned tokens and transformations that preserve
positions. Collapsing padding, compounding tokens, or rebuilding
tokenization requires a new mapping.

For single-token candidate decisions, the [ambiguity review
guide](https://ryuya-dot-com.github.io/ldfreq/articles/ambiguity-review.md)
shows a source-verified KWIC workflow with complete external imports,
original context, occurrence IDs and explicit unresolved decisions. That
interface accepts
[`lexdiv_import_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md)
results; do not pass the MASC reader’s document-relative coordinates as
segment-relative positions without conversion.

## Match your phrase list and inspect its coverage

Suppose you want to find a supplied list of expressions in essays,
articles, or conversations, then check whether each occurrence is
relevant in context. The installed `phrase-list-kwic.R` helper connects
existing quanteda phrase search to original source spans and document
summaries. It is a **copyable example**, sourced explicitly, rather than
a new exported ldfreq function. It does not download phrase lists, run a
parser, or infer idiomatic meanings.

Run the complete English/Japanese illustration:

``` r
example_env <- new.env()
sys.source(system.file("examples", "phrase-list-demo.R", package = "ldfreq"),
           envir = example_env)
#>  phrase_id document_id segment_id from to start end    pre
#>       long          en         s1    1  6     1  21       
#>     nested          en         s1    2  3     4  10    In 
#>     nested          en         s1    9 10    27  33  , in 
#>      short          en         s1    8 10    24  33  day, 
#>   japanese          ja         s1    4  7     6  12 連合で
#>                keyword    post
#>  In the end of the day    , in
#>                the end  of the
#>                the end       .
#>             in the end       .
#>         国際協力を学ぶ      。
#>  document_id source_tokens retained_tokens occurrences covered_tokens  coverage
#>           en            15              12           4              9 0.7500000
#>           ja             8               7           1              4 0.5714286
#>        empty             0               0           0              0        NA
#>  phrase_id tokens occurrences documents
#>       long      6           1         1
#>     nested      2           2         1
#>      short      3           1         1
#>   japanese      4           1         1
#>     absent      2           0         0
phrase_result <- example_env$result
```

All text, annotations and list entries in this example were authored for
ldfreq and carry its MIT licence. They are not extracts from published
phrase inventories or empirical frequency norms. The example requires
only optional quanteda and a UTF-8 R session; the XML reader is not
needed for this step.

For your own analysis, first import **complete** token annotations using
[`lexdiv_import_annotations()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md),
as in the [Japanese annotation
guide](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-annotations.md).
The helper rechecks this unchanged object before any exclusions. It
accepts segment-local positions from that importer; it does not accept
the MASC reader’s document-relative positions directly. Token and
segment boundaries must already be specified. The helper never guesses
where sentences end.

Provide a named list of explicit component vectors:

``` r
phrases <- list(
  long = c("In", "the", "end", "of", "the", "day"),
  nested = c("the", "end"),
  short = c("in", "the", "end"),
  japanese = c("国際", "協力", "を", "学ぶ"),
  absent = c("not", "present")
)
```

IDs must be unique and each entry needs at least two tokens. There is no
bigram/trigram restriction. Japanese components follow the supplied
analyzer’s segmentation: `c("国際", "協力")` will not match a single
token `"国際協力"`. Underscores within components are literal. Searches
are case sensitive and surface based; no lemmatization, Unicode
normalization, variant expansion or discontinuous matching occurs. `In`
and `in` are different. Canonically equivalent Unicode strings are
checked against their original components after quanteda search, so they
are not silently merged.

To prepare the list in a spreadsheet, use long columns `phrase_id`,
`component_index`, `term`, with one component per row. Read IDs and
terms as character strings; validate unique consecutive component
indices starting at 1 within each ID, sort by those indices, and convert
each group to a vector. Keep citation, version and permission
information with the list. Merely putting spaces into a Japanese
expression does not establish token boundaries.

``` r
source(system.file("examples", "phrase-list-kwic.R", package = "ldfreq"), local = TRUE)
a <- example_env$annotations
keep <- !a$tokens$surface %in% c(",", ".", "。", "very")
result <- phrase_list_kwic(a, phrases, example_env$resource, keep, window = 2L)
result$occurrences[c("phrase_id", "document_id", "segment_id", "from", "to",
                     "start", "end", "keyword")]
#>   phrase_id document_id segment_id from to start end               keyword
#> 1      long          en         s1    1  6     1  21 In the end of the day
#> 2    nested          en         s1    2  3     4  10               the end
#> 3    nested          en         s1    9 10    27  33               the end
#> 4     short          en         s1    8 10    24  33            in the end
#> 5  japanese          ja         s1    4  7     6  12        国際協力を学ぶ
result$counts
#>    document_id phrase_id occurrences
#> 1           en      long           1
#> 2           ja      long           0
#> 3        empty      long           0
#> 4           en    nested           2
#> 5           ja    nested           0
#> 6        empty    nested           0
#> 7           en     short           1
#> 8           ja     short           0
#> 9        empty     short           0
#> 10          en  japanese           0
#> 11          ja  japanese           1
#> 12       empty  japanese           0
#> 13          en    absent           0
#> 14          ja    absent           0
#> 15       empty    absent           0
result$documents
#>   document_id source_tokens retained_tokens occurrences covered_tokens
#> 1          en            15              12           4              9
#> 2          ja             8               7           1              4
#> 3       empty             0               0           0              0
#>    coverage
#> 1 0.7500000
#> 2 0.5714286
#> 3        NA
```

Exclusions are an explicit logical mask over the original token table,
not deletions followed by renumbering. Kept surfaces must be
non-whitespace tokens. If your annotations include whitespace tokens,
exclude their slots explicitly; those slots remain barriers to matching.
Punctuation is retained unless you exclude it and can be part of a
listed sequence. In the illustration, removing `very` from
`in the very end` does **not** create `in the end`. No match crosses a
removed slot, segment boundary, or document boundary.

`from` and `to` count original token slots within a segment. `start` and
`end` are **1-based inclusive Unicode-codepoint positions in
`segment_text`**, not byte offsets or whole-document offsets. `keyword`
is the exact substring between those endpoints, including original
spacing. `pre` and `post` retain original text up to `window` token
slots either side, within that segment; excluded punctuation/words can
therefore remain visible as context. A window of zero produces empty
`pre`/`post`. This source display differs from quanteda’s space-joined
display, particularly for Japanese. Save the full segment for
interpretation when a short window is insufficient.

Three outputs answer distinct questions:

| Output | Interpretation |
|----|----|
| `occurrences` | Every matched phrase ID and span, including nested and overlapping matches |
| `counts` / `summary` | Per-document/per-ID occurrences, and occurrence/document totals for each ID; absent phrases and empty documents stay visible |
| `documents` | All original token slots, retained tokens, occurrence counts, and the union of covered tokens divided by retained tokens |

For the English example, four occurrences cover nine distinct tokens out
of 12 retained tokens: coverage is `9/12`, not the sum of phrase lengths
divided by 12. The longer expression contains a shorter listed
expression, and both are recorded. Repeated identical sequences under
different IDs also remain separate list entries; they increase per-ID
occurrence totals, but not union coverage. For an empty or fully
excluded document, coverage is `NA`, with zero counts. A nonempty
retained document with no match has coverage zero. The denominator
includes every retained token, including punctuation if kept; it is not
automatically a word-only or eligible-window denominator.

Keep a full result for replay and a separate review table for judgments:

``` r
path <- tempfile(fileext = ".rds")
saveRDS(result, path)
restored <- readRDS(path)
replayed <- phrase_list_kwic(restored$source, restored$phrases, restored$resource,
  restored$settings$keep, restored$settings$window)
stopifnot(identical(replayed, restored))
unlink(path)
```

The saved object includes source annotations, phrase components,
resource declarations, exclusions, settings, input hash and package
versions. The next section adds a checked worksheet for
occurrence-specific decisions. Record literal/idiomatic or other
functional judgments separately, with reviewer, criteria and unresolved
cases. Phrase matches do not establish collocational strength,
formulaicity, proficiency, or a learner’s knowledge. The current
single-token ambiguity API does not accept these phrase rows; this
example does not create a phrase-sense classifier.

This helper is intended for inspectable, modest lists: it calls quanteda
once per ID and retains source text plus every document-by-ID count,
including zeros. It is not a large dictionary index or a streaming
corpus search. The resource record documents caller declarations, not
verified redistribution rights; saving or sharing the result also copies
your source text and phrase list. Existing [quanteda phrase
patterns](https://quanteda.io/reference/phrase.html) and
[KWIC](https://quanteda.io/reference/kwic.html) perform the search. The
addition here is the reproducible connection to source spans,
exclusions, overlap-aware denominators and subsequent human inspection.

## Review phrase matches and return decisions to document counts

A match for `take off` can describe a departing plane or removing a
coat. Whether it belongs in an analysis depends on the declared question
and its context. Similarly, the authored Japanese examples distinguish
hindering a plan from physically pulling a doll’s leg. The search finds
both; it does not make that contextual judgment.

From development version **0.3.0.9003**, the explicitly sourced
`phrase_list_review()` helper connects the existing phrase search to a
complete decision worksheet. It is not an exported package API. Install
that version or later using the [installation
instructions](https://ryuya-dot-com.github.io/ldfreq/#installation), and
use optional quanteda \>= 4.5.0 in a UTF-8 R session. The standalone
example runs offline, without a corpus, model or API key:

``` r
source(system.file("examples", "phrase-review-demo.R",
  package = "ldfreq", mustWork = TRUE), local = TRUE)
phrase_after$documents
phrase_after$counts
```

All texts, phrase entries and decisions are authored teaching material,
not learner observations, an established phrase inventory or an
independent human reference. Six document IDs include complete
English/Japanese reviews, pending reviews, a nonempty no-match document
and an empty document.

| document_id | segment_id | phrase_id | keyword | segment_text |
|:---|:---|:---|:---|:---|
| en | s1 | departure | take off | The plane will take off soon. |
| en | s2 | departure | take off | Please take off your coat. |
| en_pending | s1 | departure | take off | Later they take off. |
| en_pending | s2 | departure | take off | The crew will take off at noon. |
| en | s1 | departure_long | will take off | The plane will take off soon. |
| en_pending | s2 | departure_long | will take off | The crew will take off at noon. |
| ja | s1 | hindrance | 足を引っ張った | 彼の失言が計画の足を引っ張った。 |
| ja | s2 | hindrance | 足を引っ張った | 子供が人形の足を引っ張った。 |
| ja_pending | s1 | hindrance | 足を引っ張った | 彼は足を引っ張った。 |
| ja_pending | s2 | hindrance | 足を引っ張った | 会議でまた足を引っ張った。 |

The declared criterion accepts the English departure interpretation and
the Japanese hindrance interpretation. A longer `will take off` entry
deliberately overlaps `take off`, so both entries remain inspectable.
The Japanese entry uses the supplied authored components
`足 / を / 引っ張っ / た`; other tokenizations require correspondingly
specified entries. No automatic lemmatization, alternative-form
expansion or discontinuous search is implied.

For your own unchanged search result, start with:

``` r
source(system.file("examples", "phrase-list-kwic.R",
  package = "ldfreq", mustWork = TRUE), local = TRUE)
before <- phrase_list_review(my_search,
  criterion = "Write the study's interpretation and inclusion rule here.")
```

### Export context separately from the editable worksheet

``` r
phrase_review_dir <- tempfile("ldfreq-phrase-review-")
dir.create(phrase_review_dir)
saveRDS(phrase_before, file.path(phrase_review_dir, "review-before.rds"), version = 2)
write.csv(phrase_before$occurrences, file.path(phrase_review_dir, "context.csv"),
  row.names = FALSE, na = "<MISSING>", fileEncoding = "UTF-8")
write.csv(phrase_before$worksheet, file.path(phrase_review_dir, "decisions.csv"),
  row.names = FALSE, na = "<MISSING>", fileEncoding = "UTF-8")
```

`context.csv` is for reading the KWIC and complete original segment.
`decisions.csv` is the editable worksheet. It has one row per **phrase
ID and source occurrence**, including nested spans and identical forms
listed under different IDs. Edit only `status`, `reviewer` and `reason`;
keep all other cells and every row, although you may reorder rows. Read
all columns as character when importing the CSV so IDs and coordinates
survive unchanged.

| Status | Meaning and required fields |
|----|----|
| `accepted` | The occurrence meets the declared criterion; supply reviewer and reason |
| `rejected` | The match is outside that criterion; supply reviewer and reason. This does not label the writer’s expression incorrect |
| `unresolved` | It was examined but the interpretation remains unsettled; supply reviewer and reason |
| `unreviewed` | No decision has been submitted; leave reviewer and reason missing |

Here `<MISSING>` is the CSV missing-value marker. Do not use that
literal string as a reviewer name or reason. To resume an existing
review, export its latest `$worksheet`; starting again from the initial
blank worksheet replaces the earlier decisions. Save each stage or rater
separately when that history matters.

The following edits encode the teaching interpretations and deliberately
leave some rows unresolved or unreviewed. They are not automated
semantic analysis.

``` r
# Illustrative edits to the worksheet; in a study inspect context and edit the CSV.
phrase_sheet <- phrase_before$worksheet
complete_docs <- phrase_sheet$document_id %in% c("en", "ja")
phrase_sheet$status[complete_docs & phrase_sheet$segment_id == "s1"] <- "accepted"
phrase_sheet$status[complete_docs & phrase_sheet$segment_id == "s2"] <- "rejected"
pending_docs <- phrase_sheet$document_id %in% c("en_pending", "ja_pending")
phrase_sheet$status[pending_docs & phrase_sheet$segment_id == "s1"] <- "unresolved"
submitted <- phrase_sheet$status != "unreviewed"
phrase_sheet$reviewer[submitted] <- "authored-demo-reviewer"
reasons <- c(accepted = "Authored context supplies the declared target interpretation.",
  rejected = "Removing a coat or physically pulling a doll's leg is outside the criterion.",
  unresolved = "The short authored context does not settle the interpretation.")
phrase_sheet$reason[submitted] <- unname(reasons[phrase_sheet$status[submitted]])
# Reordering must never move a decision to another source occurrence.
phrase_sheet <- phrase_sheet[rev(seq_len(nrow(phrase_sheet))), ]
write.csv(phrase_sheet, file.path(phrase_review_dir, "decisions-edited.csv"),
  row.names = FALSE, na = "<MISSING>", fileEncoding = "UTF-8")
```

### Reapply by identity, then inspect counts and coverage

``` r
phrase_reader <- new.env(parent = baseenv())
sys.source(system.file("examples", "text-file-input.R", package = "ldfreq",
  mustWork = TRUE), phrase_reader)
phrase_csv <- phrase_reader$read_text_file(
  file.path(phrase_review_dir, "decisions-edited.csv"), encoding = "UTF-8")
phrase_connection <- textConnection(phrase_csv$text, encoding = "UTF-8")
phrase_sheet_read <- read.csv(phrase_connection, colClasses = "character",
  check.names = FALSE, na.strings = "<MISSING>", encoding = "UTF-8")
close(phrase_connection)
phrase_saved <- readRDS(file.path(phrase_review_dir, "review-before.rds"))
phrase_after <- phrase_list_review(phrase_saved$source, phrase_saved$criterion,
  worksheet = phrase_sheet_read)
phrase_after$documents[c("document_id", "occurrences", "accepted", "rejected",
  "unresolved", "unreviewed", "review_complete")]
#>   document_id occurrences accepted rejected unresolved unreviewed
#> 1          en           3        2        1          0          0
#> 2  en_pending           3        0        0          1          2
#> 3          ja           2        1        1          0          0
#> 4  ja_pending           2        0        0          1          1
#> 5    no_match           0        0        0          0          0
#> 6       empty           0        0        0          0          0
#>   review_complete
#> 1            TRUE
#> 2           FALSE
#> 3            TRUE
#> 4           FALSE
#> 5            TRUE
#> 6            TRUE
phrase_after$documents[c("document_id", "retained_tokens", "covered_tokens",
  "accepted_covered_tokens", "accepted_coverage", "reportable_accepted_coverage")]
#>   document_id retained_tokens covered_tokens accepted_covered_tokens
#> 1          en              11              5                       3
#> 2  en_pending              11              5                       0
#> 3          ja              18              8                       4
#> 4  ja_pending              13              8                       0
#> 5    no_match               5              0                       0
#> 6       empty               0              0                       0
#>   accepted_coverage reportable_accepted_coverage
#> 1         0.2727273                    0.2727273
#> 2         0.0000000                           NA
#> 3         0.2222222                    0.2222222
#> 4         0.0000000                           NA
#> 5         0.0000000                    0.0000000
#> 6                NA                           NA
```

The helper replays the original search before applying the worksheet. It
checks the full row set, source anchors, review fingerprint and required
decision fields. A removed/duplicated row, edited fixed cell or partly
filled unreviewed row fails. Changed source, phrase entries, resource
declaration, search settings **including the context window**, or
criterion require a new worksheet. Do not replace IDs to force old
decisions onto changed material.

Each document and document-by-phrase cell satisfies
`occurrences = accepted + rejected + unresolved + unreviewed`.
`covered_tokens` describes all exact matches; `accepted_covered_tokens`
describes only the **union** of accepted spans. The English complete
review accepts two nested occurrences of lengths three and two, but
their union is three tokens, so accepted coverage is `3/11`, not `5/11`.
The Japanese complete review gives `4/18`. These authored ratios are not
a language or ability comparison.

`accepted_coverage` retains the coverage of decisions accepted so far.
`reportable_accepted_coverage` is missing whenever a document still has
an unresolved or unreviewed match. A zero in the former column for a
pending review is therefore not reported as an observed absence of
relevant uses. The no-match document has zero coverage; the empty
document has missing coverage because its denominator is zero.

`review_complete` means that every **matched entry** has an
accepted/rejected decision. It does not establish that the inventory is
exhaustive, that the annotations are correct, or that the decisions are
reliable. Different list entries at the same span retain separate
decisions; union coverage prevents double counting but does not
adjudicate inconsistent judgments. Original tokens remain unchanged:
this workflow does not compound accepted expressions into single words
or alter TTR, MATTR or MTLD.

### Save the complete review and reproduce its tables

``` r
phrase_record <- list(before = phrase_saved, after = phrase_after,
  worksheet_input = phrase_csv, session = sessionInfo())
saveRDS(phrase_record, file.path(phrase_review_dir, "analysis.rds"), version = 2)
write.csv(phrase_after$documents, file.path(phrase_review_dir, "document-results.csv"),
  row.names = FALSE, na = "<MISSING>", fileEncoding = "UTF-8")
write.csv(phrase_after$counts, file.path(phrase_review_dir, "phrase-counts.csv"),
  row.names = FALSE, na = "<MISSING>", fileEncoding = "UTF-8")
phrase_restored <- readRDS(file.path(phrase_review_dir, "analysis.rds"))
stopifnot(identical(phrase_restored, phrase_record), identical(
  phrase_list_review(phrase_restored$after$source, phrase_restored$after$criterion,
    worksheet = phrase_restored$after$worksheet), phrase_restored$after))
```

The temporary directory makes the example runnable. For a study, use a
persistent project directory and separate files for successive review
stages; writing the same filename overwrites it. The RDS retains
original text, search settings, the declared criterion, every judgment
and the imported CSV record. The two result CSVs are flat tables for
later analysis. Reproduction uses the same software versions; retain the
original files and saved environment. These records contain source text
and the phrase inventory, so their sharing conditions follow those
materials.

A methods description should identify the phrase inventory/version,
analyzer and word unit, case/normalization policy, segment boundaries,
exclusions, context and decision criterion, reviewers and handling of
disagreements. Report accepted/rejected/unresolved/unreviewed counts and
the retained-token denominator. State that overlapping accepted spans
contribute their union to coverage, and report how many documents remain
incomplete. Search and worksheet checks verify correspondence, not
inter-rater agreement or psycholinguistic validity.

## Compare phrase judgments before discussion

Two researchers may read the same `take off` match differently. The
question here is **whether they make the same inclusion decision, and
whether their decisions change the document profile**. It is not a test
of phrase-detection recall: expressions absent from the list have not
been sampled for review. The following guide-local code runs with the
existing 0.3.0.9003 installation.

The design follows these distinctions in the annotation literature:

| Research basis | Consequence for this workflow |
|----|----|
| [Carletta (1996)](https://aclanthology.org/J96-2004/), pp. 250–253: chance agreement and the choice of coding unit matter | Declare one phrase ID at one original span as the item; retain the category counts and all sampled items |
| [Di Eugenio and Glass (2004)](https://aclanthology.org/J04-1005/), pp. 96–100: kappa variants and marginal distributions can change the interpretation | Name unweighted **Cohen’s kappa**, show both raters’ margins, and do not label a fixed cutoff as a universal pass criterion |
| [Artstein and Poesio (2008)](https://aclanthology.org/J08-4004/), sections 2.1–2.4: agreement, validity and chance models are different questions | Preserve independent decisions before discussion; a high agreement coefficient or a consensus is not evidence that the interpretation is correct |

For this binary inclusion task, `accepted` and `rejected` are nominal
labels, not ordered scores. `unresolved` records an examined but
unsettled case; `unreviewed` records no submitted decision. **Our
analysis policy** retains all four states, but estimates binary
agreement only where both raters made an accepted/rejected decision.
This conditional subset may omit the hardest cases. Its agreement is not
an estimate for all occurrences without further assumptions. If
uncertainty itself is a substantive response category, define and
evaluate that different coding scheme explicitly.

### Pair two unchanged reviews and expose the denominators

The two review columns must each belong to one declared person, with
different IDs. Different names cannot verify independent work: in a
study, assign the same sampled material and written criterion, collect
decisions separately, and retain the pre-discussion files. Treat a
repeated pass by one person as intra-rater comparison instead. The
helper below is local to this guide.

``` r
compare_phrase_reviews <- function(a, b, reviewers) {
  if (!is.character(reviewers) || length(reviewers) != 2L ||
      anyNA(reviewers) || anyDuplicated(reviewers) ||
      any(!validUTF8(reviewers)) ||
      any(!nzchar(stringi::stri_trim_both(reviewers))))
    stop("Declare two distinct, nonblank reviewer IDs.")
  reviews <- list(a, b)
  for (i in seq_along(reviews)) {
    x <- reviews[[i]]
    checked <- phrase_list_review(x$source, x$criterion, x$worksheet)
    if (!identical(x, checked)) stop("Review changed; reapply its worksheet first.")
    submitted <- x$worksheet$status != "unreviewed"
    if (any(x$worksheet$reviewer[submitted] != reviewers[i]))
      stop("Each review must contain decisions from its declared reviewer only.")
  }
  if (!identical(a$provenance$review_id, b$provenance$review_id))
    stop("Reviews must share source, inventory, settings and criterion.")
  p <- a$occurrences[c("review_id", "occurrence_id", "phrase_id", "document_id",
    "segment_id", "start", "end", "pre", "keyword", "post", "segment_text")]
  j <- match(p$occurrence_id, b$occurrences$occurrence_id)
  if (anyNA(j) || anyDuplicated(j) || length(j) != nrow(b$occurrences))
    stop("Keep the same complete occurrence set in both reviews.")
  for (field in c("status", "reviewer", "reason")) {
    p[[paste0("a_", field)]] <- a$occurrences[[field]]
    p[[paste0("b_", field)]] <- b$occurrences[[field]][j]
  }
  labels <- c("accepted", "rejected")
  states <- c(labels, "unresolved", "unreviewed")
  p$both_decided <- p$a_status %in% labels & p$b_status %in% labels
  p$outcome <- ifelse(p$both_decided,
    ifelse(p$a_status == p$b_status, "agreement", "disagreement"), "incomplete")
  ids <- names(a$source$phrases)
  status_counts <- as.data.frame(table(
    phrase_id = factor(p$phrase_id, levels = ids),
    a_status = factor(p$a_status, levels = states),
    b_status = factor(p$b_status, levels = states)), responseName = "occurrences")
  ratings <- setNames(lapply(ids, function(id) {
    rows <- p$phrase_id == id & p$both_decided
    data.frame(a = factor(p$a_status[rows], levels = labels),
      b = factor(p$b_status[rows], levels = labels))
  }), ids)
  summary <- do.call(rbind, lapply(ids, function(id) {
    rows <- p$phrase_id == id
    r <- ratings[[id]]; n <- sum(rows); paired <- nrow(r)
    agreement <- sum(r$a == r$b)
    data.frame(phrase_id = id, occurrences = n,
      documents = length(unique(p$document_id[rows])), both_decided = paired,
      paired_documents = length(unique(p$document_id[rows & p$both_decided])),
      incomplete = n - paired, agreement = agreement, disagreement = paired - agreement,
      paired_proportion = if (n) paired / n else NA_real_,
      observed_agreement = if (paired) agreement / paired else NA_real_,
      a_accepted = sum(r$a == "accepted"), b_accepted = sum(r$b == "accepted"))
  }))
  list(summary = summary, status_counts = status_counts, ratings = ratings,
    pairs = p, review_queue = p[p$outcome != "agreement", , drop = FALSE],
    reviews = reviews, reviewers = reviewers,
    policy = "Per phrase ID; binary agreement conditional on both decisive; all states retained")
}
```

For your files, use [`readRDS()`](https://rdrr.io/r/base/readRDS.html)
to restore the separately saved reviews, then call
`compare_phrase_reviews(a, b, reviewers = c("rater-1", "rater-2"))` with
the actual recorded IDs. It reuses the installed worksheet checks before
pairing by occurrence identity; altered source or criterion cannot be
joined silently. No-match phrase IDs remain in the summary with a zero
denominator.

### Run the authored example and inspect open cases

Continue the example above, or first run `phrase-review-demo.R`. The
following second worksheet deliberately introduces disagreements and
different completion states. **It is simulated teaching material, not an
independent human rating.**

``` r
review_a <- phrase_after
sheet_b <- phrase_before$worksheet
complete <- sheet_b$document_id %in% c("en", "ja")
sheet_b$status[complete & sheet_b$segment_id == "s1"] <- "accepted"
sheet_b$status[complete & sheet_b$segment_id == "s2"] <- "rejected"
sheet_b$status[sheet_b$document_id == "en" & sheet_b$segment_id == "s2"] <- "accepted"
sheet_b$status[sheet_b$document_id == "en" & sheet_b$phrase_id == "departure_long"] <- "unresolved"
sheet_b$status[sheet_b$document_id == "en_pending" & sheet_b$segment_id == "s1"] <- "rejected"
sheet_b$status[sheet_b$document_id == "ja_pending" & sheet_b$segment_id == "s1"] <- "unresolved"
sheet_b$status[sheet_b$document_id == "ja_pending" & sheet_b$segment_id == "s2"] <- "accepted"
submitted <- sheet_b$status != "unreviewed"
sheet_b$reviewer[submitted] <- "authored-B"
sheet_b$reason[submitted] <- "Deliberately varied teaching decision; not a human observation."
review_b <- phrase_list_review(phrase_search, phrase_criterion,
  sheet_b[rev(seq_len(nrow(sheet_b))), ])
phrase_comparison <- compare_phrase_reviews(review_a, review_b,
  reviewers = c("authored-demo-reviewer", "authored-B"))
phrase_comparison$summary
#>        phrase_id occurrences documents both_decided paired_documents incomplete
#> 1      departure           4         2            2                1          2
#> 2 departure_long           2         2            0                0          2
#> 3      hindrance           4         2            2                1          2
#> 4         absent           0         0            0                0          0
#>   agreement disagreement paired_proportion observed_agreement a_accepted
#> 1         1            1               0.5                0.5          1
#> 2         0            0               0.0                 NA          0
#> 3         2            0               0.5                1.0          1
#> 4         0            0                NA                 NA          0
#>   b_accepted
#> 1          2
#> 2          0
#> 3          1
#> 4          0
subset(phrase_comparison$status_counts, occurrences > 0)
#>         phrase_id   a_status   b_status occurrences
#> 1       departure   accepted   accepted           1
#> 3       hindrance   accepted   accepted           1
#> 5       departure   rejected   accepted           1
#> 15      hindrance unreviewed   accepted           1
#> 23      hindrance   rejected   rejected           1
#> 25      departure unresolved   rejected           1
#> 34 departure_long   accepted unresolved           1
#> 43      hindrance unresolved unresolved           1
#> 61      departure unreviewed unreviewed           1
#> 62 departure_long unreviewed unreviewed           1
phrase_comparison$review_queue[c("document_id", "phrase_id", "keyword",
  "a_status", "b_status", "a_reason", "b_reason", "outcome")]
#>    document_id      phrase_id        keyword   a_status   b_status
#> 2           en      departure       take off   rejected   accepted
#> 3   en_pending      departure       take off unresolved   rejected
#> 4   en_pending      departure       take off unreviewed unreviewed
#> 5           en departure_long  will take off   accepted unresolved
#> 6   en_pending departure_long  will take off unreviewed unreviewed
#> 9   ja_pending      hindrance 足を引っ張った unresolved unresolved
#> 10  ja_pending      hindrance 足を引っ張った unreviewed   accepted
#>                                                                        a_reason
#> 2  Removing a coat or physically pulling a doll's leg is outside the criterion.
#> 3                The short authored context does not settle the interpretation.
#> 4                                                                          <NA>
#> 5                 Authored context supplies the declared target interpretation.
#> 6                                                                          <NA>
#> 9                The short authored context does not settle the interpretation.
#> 10                                                                         <NA>
#>                                                           b_reason      outcome
#> 2  Deliberately varied teaching decision; not a human observation. disagreement
#> 3  Deliberately varied teaching decision; not a human observation.   incomplete
#> 4                                                             <NA>   incomplete
#> 5  Deliberately varied teaching decision; not a human observation.   incomplete
#> 6                                                             <NA>   incomplete
#> 9  Deliberately varied teaching decision; not a human observation.   incomplete
#> 10 Deliberately varied teaching decision; not a human observation.   incomplete
```

There are ten list matches. Four have binary decisions from both sides:
three agree and one disagrees. The other six remain incomplete,
including two unresolved judgments on the same occurrence. The queue
therefore has seven rows; `$pairs` also retains the original KWIC and
full segment text. The per-phrase summaries keep the denominators
separate: `departure` has one agreement in two paired decisions out of
four matches; `hindrance` has two in two out of four. Neither
`departure_long` nor `absent` has any paired binary decision, for
different reasons visible in their counts.

### Optional Cohen kappa with an existing R package

For two fixed raters applying these binary labels, use the optional
[`irr::kappa2()`](https://search.r-project.org/CRAN/refmans/irr/html/kappa2.html)
with `weight = "unweighted"`. Its missing rows are removed listwise;
here the paired rows have already been selected explicitly and their
excluded states remain in the comparison. Install `irr` separately to
run this block.

``` r
# install.packages("irr")  # once, when this optional analysis is needed
stopifnot(requireNamespace("irr", quietly = TRUE))
phrase_kappa <- do.call(rbind, lapply(names(phrase_comparison$ratings), function(id) {
  r <- phrase_comparison$ratings[[id]]
  status <- if (!nrow(r)) "no_paired_decisions" else if
    (length(unique(c(as.character(r$a), as.character(r$b)))) == 1L)
      "constant_single_category" else "computed_descriptive"
  value <- if (status == "computed_descriptive")
    irr::kappa2(r, weight = "unweighted")$value else NA_real_
  data.frame(phrase_id = id, both_decided = nrow(r), kappa = value, status = status)
}))
phrase_kappa
saveRDS(list(comparison = phrase_comparison, estimates = phrase_kappa,
  irr_version = as.character(packageVersion("irr"))),
  file.path(phrase_review_dir, "kappa.rds"), version = 2)
```

The authored `departure` and `hindrance` values are 0 and 1; their tiny
paired samples are not evidence of real annotator reliability. No pooled
kappa across different phrase criteria/languages is calculated. Two
raters assigning only one identical category have observed agreement 1
but undefined kappa, not a kappa of 1. Ordinal ratings or more than two
raters require a different declared model; ICC and a correlation between
document scores do not replace this nominal-label comparison.

To check the external implementation against a published calculation,
this block reconstructs [Artstein and Poesio’s Tables
1–2](https://aclanthology.org/J08-4004/) (pp. 558, 560). The counts
describe dialogue-act categories, not learner data.

``` r
published_ratings <- data.frame(
  a = rep(c("STAT", "IREQ", "STAT", "IREQ"), c(20, 20, 10, 50)),
  b = rep(c("STAT", "STAT", "IREQ", "IREQ"), c(20, 20, 10, 50)))
published_kappa <- irr::kappa2(published_ratings, weight = "unweighted")$value
stopifnot(isTRUE(all.equal(published_kappa, 8/23, tolerance = 1e-12)))
published_kappa  # 0.3478261; observed agreement is 70/100
```

The verification also reproduced the prevalence examples in Di Eugenio
and Glass (2004), Figure 3 (p. 99), using `irr` 0.85: both tables have
90% observed agreement, but counts `90, 5; 5, 0` give kappa -0.052632,
whereas `45, 5; 5, 45` give 0.8. The former figure prints -0.048; its
displayed counts and expected agreement 0.905 instead imply
`(0.9 - 0.905)/(1 - 0.905)`. The check follows those counts. Retaining
the table and margins makes this distinction inspectable; a single
threshold would conceal it. In Figure 4, the Example 5 counts
(`40, 15; 20, 25`) imply expected agreement 0.51 and kappa 0.285714,
rather than the printed 0.52 and 0.27. Example 6 (`40, 35; 0, 25`) gives
kappa 0.363636, rather than 0.418. Independent exact fraction arithmetic
confirms the recomputed values. These are count-versus-text
discrepancies, not differences between definitions of kappa.

A document can contribute several related or overlapping occurrences.
This recipe reports descriptive point estimates, not the default test
statistic or p-value returned by `irr`. Uncertainty analysis needs the
study’s sampling design and dependence structure, for example retaining
related occurrences together when resampling writers/documents. A
different coefficient alone does not resolve selective missing judgments
or non-independent sampling.

### Record discussion separately and compare document profiles

After inspecting the queue, record discussion decisions separately.
These three authored edits resolve the coat/flight examples and decide
one Japanese context; other open cases remain open. Starting from A here
is an explicit working-copy choice, not automatic acceptance of A
whenever the raters differ.

``` r
discussion <- review_a$worksheet
edit <- (discussion$document_id == "en" & discussion$segment_id == "s2") |
  (discussion$document_id == "en" & discussion$phrase_id == "departure_long") |
  (discussion$document_id == "ja_pending" & discussion$segment_id == "s2")
discussion_log <- discussion[edit, ]
discussion_log$status <- ifelse(discussion_log$document_id == "en" &
  discussion_log$segment_id == "s2", "rejected", "accepted")
discussion_log$reviewer <- "authored-discussion"
discussion_log$reason <- ifelse(discussion_log$status == "rejected",
  "Authored discussion: removing a coat is outside the departure criterion.",
  "Authored discussion: flight departure or hindrance in the meeting fits the criterion.")
j <- match(discussion_log$occurrence_id, discussion$occurrence_id)
discussion[j, c("status", "reviewer", "reason")] <-
  discussion_log[c("status", "reviewer", "reason")]
after_discussion <- phrase_list_review(phrase_search, phrase_criterion, discussion)
stages <- list(A = review_a, B = review_b, partial_discussion = after_discussion)
phrase_profiles <- do.call(rbind, lapply(names(stages), function(stage) {
  data.frame(stage = stage, stages[[stage]]$documents, row.names = NULL)
}))
rownames(phrase_profiles) <- NULL
phrase_profiles[c("stage", "document_id", "accepted", "unresolved", "unreviewed",
  "retained_tokens", "accepted_covered_tokens", "reportable_accepted_coverage")]
#>                 stage document_id accepted unresolved unreviewed
#> 1                   A          en        2          0          0
#> 2                   A  en_pending        0          1          2
#> 3                   A          ja        1          0          0
#> 4                   A  ja_pending        0          1          1
#> 5                   A    no_match        0          0          0
#> 6                   A       empty        0          0          0
#> 7                   B          en        2          1          0
#> 8                   B  en_pending        0          0          2
#> 9                   B          ja        1          0          0
#> 10                  B  ja_pending        1          1          0
#> 11                  B    no_match        0          0          0
#> 12                  B       empty        0          0          0
#> 13 partial_discussion          en        2          0          0
#> 14 partial_discussion  en_pending        0          1          2
#> 15 partial_discussion          ja        1          0          0
#> 16 partial_discussion  ja_pending        1          1          0
#> 17 partial_discussion    no_match        0          0          0
#> 18 partial_discussion       empty        0          0          0
#>    retained_tokens accepted_covered_tokens reportable_accepted_coverage
#> 1               11                       3                    0.2727273
#> 2               11                       0                           NA
#> 3               18                       4                    0.2222222
#> 4               13                       0                           NA
#> 5                5                       0                    0.0000000
#> 6                0                       0                           NA
#> 7               11                       4                           NA
#> 8               11                       0                           NA
#> 9               18                       4                    0.2222222
#> 10              13                       4                           NA
#> 11               5                       0                    0.0000000
#> 12               0                       0                           NA
#> 13              11                       3                    0.2727273
#> 14              11                       0                           NA
#> 15              18                       4                    0.2222222
#> 16              13                       4                           NA
#> 17               5                       0                    0.0000000
#> 18               0                       0                           NA
```

All six documents remain in each stage. For the English document, A
accepts three original token slots, B accepts four, and the partial
discussion returns three. B still has an unresolved match there, so its
complete-review coverage is unavailable. Empty documents keep a zero
denominator and missing coverage. Discussion changes neither the
original tokens nor the stored pre-discussion agreement. Report these
original profiles side by side, with their completion status; do not
turn a discussion result into an independent third rating.

``` r
agreement_record <- list(comparison = phrase_comparison,
  discussion_log = discussion_log, after_discussion = after_discussion,
  profiles = phrase_profiles, session = sessionInfo())
saveRDS(agreement_record, file.path(phrase_review_dir, "agreement.rds"), version = 2)
write.csv(phrase_comparison$summary, file.path(phrase_review_dir, "agreement-summary.csv"),
  row.names = FALSE, na = "<MISSING>", fileEncoding = "UTF-8")
write.csv(phrase_profiles, file.path(phrase_review_dir, "review-stage-profiles.csv"),
  row.names = FALSE, na = "<MISSING>", fileEncoding = "UTF-8")
agreement_restored <- readRDS(file.path(phrase_review_dir, "agreement.rds"))
stopifnot(identical(agreement_restored, agreement_record), identical(
  compare_phrase_reviews(agreement_restored$comparison$reviews[[1]],
    agreement_restored$comparison$reviews[[2]], agreement_restored$comparison$reviewers),
  agreement_restored$comparison))
```

The optional block saves `kappa.rds` with its comparison, estimates and
`irr` version. For a study, retain the original submitted CSVs and the
sampling record. The RDS above retains original text, both reviews,
comparison and discussion; use a persistent study directory and respect
the source materials’ sharing terms.

A methods paragraph can follow this structure, replacing bracketed
fields with the actual design and numbers:

> Two raters independently applied \[criterion/version\] to \[sampling
> rule\] occurrences from \[documents/writers\]. Each item was one
> phrase ID at a fixed source span under \[inventory/version and
> segmentation\]. We retained unresolved and unreviewed states. For each
> phrase, binary observed agreement and unweighted Cohen’s kappa (irr
> \[version\]) used the \[n\] jointly decisive occurrences of \[N\]
> sampled matches; category cross-tables and each rater’s margins were
> reported. Discussion followed the independent ratings and was recorded
> separately. We compared document profiles under both ratings and
> subsequent decisions, counting overlapping accepted spans by their
> token union and withholding complete-review coverage for unfinished
> documents.

Use the independence sentence only for genuinely independent human work.
A pilot should test the written rules on separate practice material
before a held-out agreement sample; revised rules need a new recorded
evaluation, not a relabeled post-discussion score. This executable
teaching example validates the workflow, not human reliability,
phrase-inventory completeness or learner proficiency.

## Connect to the existing ldfreq reference workflow

``` r
prepared <- q$positions
prepared$term <- prepared$surface
sequences <- lexdiv_ngrams(prepared,
  preprocessing_id = "authored-penn-surface-exclude-period-tag-v1",
  documents = corpus$documents$document_id)
sequences$counts
#>   n  term1  term2 term3 count document_count
#> 1 2     We re-use  <NA>     1              1
#> 2 2 re-use  words  <NA>     1              1
#> 3 2     We     go  <NA>     1              1
#> 4 3     We re-use words     1              1
```

Follow the **Adjacent n-gram frequency profiles** guide to build a local
reference with explicit source metadata and denominators. A
preprocessing ID is a declaration of comparable rules, not proof that an
unrelated tokenizer is compatible. MASC Penn tokens, quanteda word4
tokens and the bundled TUBELEX tokenization must not be silently treated
as the same tokenization.

Save source evidence with the analysis:

``` r
path <- tempfile(fileext = ".rds")
saveRDS(list(corpus = corpus, quanteda = q, sequences = sequences), path)
restored <- readRDS(path)
stopifnot(identical(restored$corpus$provenance, corpus$provenance),
          identical(as.list(restored$quanteda$tokens), as.list(q$tokens)))
unlink(path)
```

## Use your local MASC files

The reader is verified against the **Penn layer of Mini-MASC 1.0**,
using its GrAF 1.0 `cesHeader` layout. Supply local `.anc` document
headers and the actual resource version. No corpus is downloaded by this
function. In the verified eight-document Mini-MASC release, 851 of 7,263
Penn tokens have no `base` feature. They retain `NA` lemmas; a lemma
analysis therefore needs an explicit missingness policy even when
surface tokens are available.

``` r
headers <- list.files("/path/to/Mini-MASC/data", pattern = "\\.anc$",
                      recursive = TRUE, full.names = TRUE)
masc <- lexdiv_read_masc(headers, resource_version = "Mini-MASC-1.0")
```

The source format includes separate primary text, segmentation, sentence
or utterance, and Penn feature files. Header references must resolve
within the header’s directory. The reader rejects missing links,
overlapping spans, tokens crossing segment boundaries, and discontinuous
tokens. It does not silently repair those cases or switch to another
annotation layer.

Reader interface 0.2.0 also accepts MASC 3.0.0’s GrAF `documentHeader`
layout: `.hdr` files use `f.id="f.penn"` etc. and `loc` attributes. This
is format support with a restricted validated scope. A local audit of
all 392 documents in the [official MASC 3.0.0
archive](https://anc.org/data/masc/downloads/data-download/) accepted
**122 documents** under the existing strict rules. First failures among
the other 270 were: 130 documents with tokens outside a single supplied
sentence/utterance region, 126 with overlapping sentence/utterance
regions, nine with invalid or incompatible anchors, four with
overlapping tokens and one with a feature structure outside the
supported flat name/value format. These are reader diagnostics, not a
comprehensive correction of the corpus. Multiple issues may exist in one
file. No rejected annotations were repaired or silently replaced by new
sentence/token boundaries.

Consequently, do not catch errors, omit these files and label the
remaining sample “full MASC”. Such exclusions can change register
composition and reference frequencies. Record accepted and rejected
document IDs, reasons, source hashes and preparation choices before
interpreting any subset. The accepted subset is useful for exercising
the software; it is not supplied as a representative English norm. The
inspected archive’s SHA-256 was
`0b300d96016233c7c79b43559b477a6bb0ed16bb416d5c517eccb108a6228493`.

The inspected [OANC GrAF archive](https://anc.org/data/oanc/download/)
mainly uses a `hepple` annotation layer with token regions in the same
graph. It is not the MASC Penn/seg layout. This reader does not provide
a validated OANC importer; shared GrAF namespaces alone do not establish
compatibility.

[MASC](https://anc.org/data/masc/) is distributed under CC BY 3.0 US.
Retain its attribution, licence and changes when redistributing
material. The reader records file hashes and the declared release but
does not determine the licence of arbitrary input files. Corpus rights
differ from the licence of this package and its authored example.

MASC and [OANC](https://anc.org/data/oanc/) can support different
reference sizes and registers. Their sample composition, overlapping
source material, annotation choices and sparse long n-grams matter. A
reference’s usefulness for your question requires more than successful
file import. These functions do not yet provide a validated standard
MASC/OANC frequency resource.

Once inputs have been validated,
[`lexdiv_ngram_reference_build()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ngram_reference_build.md)
can accumulate references in whole-document chunks. This avoids
retaining every occurrence table, while counts and the document roster
remain in memory. See the [n-gram
guide](https://ryuya-dot-com.github.io/ldfreq/articles/ngram-profiles.html#accumulate-a-reference-in-whole-document-chunks)
for the callback, denominator and exclusion-record requirements.
