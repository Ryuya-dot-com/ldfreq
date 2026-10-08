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
