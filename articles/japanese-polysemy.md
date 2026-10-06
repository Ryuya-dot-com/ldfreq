# Japanese polysemy: reviewed resource records and contextual choices

An experiment may need both a word’s normative polysemy estimate and a
judgment of its meaning in a particular sentence. These answer different
questions:

| Quantity | What it records | What it cannot establish |
|----|----|----|
| Candidate count | Records available under a declared lookup key | Number of psychologically distinct meanings |
| WLSP-norms `VALUE` | A released estimate of subjective polysemousness | Sense count, probability or an individual learner’s knowledge |
| KWIC decision | A reviewed candidate choice for one occurrence | Sense-specific reference frequency or correctness by itself |

This guide reuses
[`lexdiv_norm_profile()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_norm_profile.md)
and
[`lexdiv_ambiguity_review()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ambiguity_review.md)
with two explicitly sourced helpers. There is no new required package,
automatic download or external rating table bundled with ldfreq. All
chunks below require separately acquired data and run only on explicit
execution.

## Obtain and inspect the exact source

[WLSP-norms
v1.0](https://github.com/masayu-a/WLSP-norms/tree/72125c8dc538aeb70b07cb1c76c183e338f0cde9)
provides several subjective norms; this helper supports only
`polysemous.txt`. Credit National Institute for Japanese Language and
Linguistics (2025), *WLSP-norms (ver. 1.0)*, and Masayuki Asahara. The
data license is **CC BY-NC-SA 3.0**; apply its conditions to extracts
and joined tables. The MIT code license does not replace it.

``` r
data_dir <- "japanese-resources"
dir.create(data_dir, showWarnings = FALSE)
polysemy_path <- file.path(data_dir, "polysemous.txt")
revision <- "72125c8dc538aeb70b07cb1c76c183e338f0cde9"
if (!file.exists(polysemy_path)) {
  download.file(paste0("https://raw.githubusercontent.com/masayu-a/WLSP-norms/",
    revision, "/polysemous.txt"), polysemy_path, mode = "wb")
}
library(ldfreq)
source(system.file("examples", "wlsp-polysemy.R", package = "ldfreq"))
reference <- read_wlsp_polysemy(polysemy_path)
reference$source
```

The file must match SHA-256
`03ad0e12686c4cc015e52428a81ca53377681d87988a23ee8d4dcf116feca43b`. It
has 100,827 unique `WID` values but only 84,152 distinct `WORD` strings.
`WORD` includes decorated headings and readings; `LABEL` retains
classification information and a different ID. Neither ID is silently
converted into a WLSP-familiarity record ID. A new file requires
reviewing the version.

The [Asahara (2025) preprint](https://doi.org/10.51094/jxiv.2164)
describes native-speaker ratings collected in June 2025 and a Bayesian
linear mixed model. The repository calls `VALUE` a normalized estimate.
It includes negative values, and the inspected documentation does not
specify the exact normalization transform. Preserve released values: do
not clamp them to the original 0–5 response scale, convert them into
sense counts, or assume they are z-scores. The file provides no item
uncertainty intervals. A software check does not independently validate
the norm.

## Review the display key and then the candidate record

Inspect possible labels first. Substring search also finds compounds and
phrases; it does not establish a mapping. An exact `WORD` match may
still leave several records.

``` r
reference$data[grepl("人気", reference$data$WORD, fixed = TRUE), c("WID", "WORD", "LABEL")]
reference$data[reference$data$WORD == "【犬】（いぬ）", c("WID", "WORD", "LABEL")]
```

Keep the presented `term`, reviewed `norm_word`, and mapping reason
separately. These authored examples are not validated stimuli. `NA`
leaves the lookup key unresolved; a supplied key absent from the table
is instead unmatched.

``` r
items <- data.frame(item_id = paste0("item_", 1:6),
  condition = c("A", "B", "A", "B", "A", "B"),
  term = c("人気", "人気", "犬", "犬", "未登録の例語", "判断保留"),
  norm_word = c("【人気】（にんき）", "【人気（ひとけ）】（ひとけ）",
                "【犬】（いぬ）", "【犬】（いぬ）", "未登録の例語", NA_character_),
  mapping_reason = c("Example interpretation: popularity", "Example reading: hitoke",
    "Example animal interpretation", "Context not yet reviewed",
    "Deliberately absent test key", "No source display key chosen"))
initial <- review_wlsp_polysemy_items(items, polysemy_path)
initial$candidates[, c("item_id", "WID", "norm_word", "LABEL")]
initial$items[, c("item_id", "polysemy_candidate_count", "polysemy_status")]

# Inspect classification labels rather than taking the first matching record.
decisions <- data.frame(item_id = items$item_id[1:3], wid = c("92892", "63221", "86619"),
  reason = c("Reviewed popularity record", "Reviewed hitoke record",
             "Reviewed animal classification, not the occupational record"))
polysemy <- review_wlsp_polysemy_items(items, polysemy_path, decisions)
polysemy$items[, c("item_id", "polysemy_status", "polysemy_wid", "polysemy_value")]
polysemy$coverage
```

Even a single candidate remains `unreviewed` until selected. A decision
verifies record membership for the supplied display key, not whether it
fits the stimulus. Candidate values are available in the output; hide
them from reviewers when blinding to the norm is part of your design.

Here full-item selection/value coverage is **3/6**. The generic
`polysemy$profile` describes **selected WIDs only**: its 100% matching
coverage does not describe all six items. `profile_item_ids` identifies
that subset. Its `token` weighting counts supplied selected item rows;
`type` counts distinct WIDs, not distinct spellings. Unselected values
stay `NA`; records sharing a displayed word are not averaged together.

Join `polysemy$items` to the [stimulus review
table](https://ryuya-dot-com.github.io/ldfreq/articles/japanese-stimuli.md)
by unique study item ID after checking row coverage, and inspect
missingness by condition. Keep source objects and decisions. Do not join
by familiarity ID or assume a morphology analyzer’s reading resolves the
classification choice.

## Connect reviewed source records to KWIC

This self-contained example uses complete authored annotations. The
candidate mapping is explicit; the helper does not infer it from the
observed surface.

``` r
segments <- data.frame(document_id = "ja", segment_id = c("s1", "s2"),
  text = c("その店は人気がある。", "森には人気がない。"))
tokens <- data.frame(document_id = "ja", segment_id = rep(c("s1", "s2"), each = 7),
  token_index = rep(1:7, 2),
  surface = c("その", "店", "は", "人気", "が", "ある", "。",
              "森", "に", "は", "人気", "が", "ない", "。"))
ja <- lexdiv_import_annotations(tokens, segments,
  list(language = "ja", analyzer = "authored", analyzer_version = "1", dictionary = "none",
    dictionary_version = "none", unit = "authored-example", normalization = "none"))
rows <- match(c("92892", "63221"), reference$data$WID)
candidates <- data.frame(term = "人気", candidate_id = reference$data$WID[rows],
  label = reference$data$WORD[rows], classification = reference$data$LABEL[rows])
kwic <- lexdiv_ambiguity_review(ja, "人気", candidates, reference$resource)
kwic$occurrences[, c("pre", "keyword", "post", "segment_text", "status")]
choices <- kwic$occurrences[, c("review_id", "occurrence_id")]
choices$status <- "selected"
choices$candidate_id <- c("92892", "63221")
choices$reviewer <- "example-reviewer"
choices$reason <- c("Example interpretation: popularity", "Example interpretation: human presence")
kwic <- lexdiv_ambiguity_review(ja, "人気", candidates, reference$resource, choices)

# Keep unselected occurrences as unresolved keys, not dropped rows.
o <- kwic$occurrences
source_row <- match(o$candidate_id, reference$data$WID)
occurrence_items <- data.frame(item_id = o$occurrence_id, term = o$surface,
  norm_word = reference$data$WORD[source_row],
  mapping_reason = ifelse(o$status == "selected", o$reason, "No contextual candidate selected"))
selected <- which(o$status == "selected")
occurrence_decisions <- data.frame(item_id = o$occurrence_id[selected],
  wid = o$candidate_id[selected], reason = o$reason[selected])
occurrence_norms <- review_wlsp_polysemy_items(occurrence_items, polysemy_path, occurrence_decisions)
saveRDS(list(kwic = kwic, norms = occurrence_norms, item_review = polysemy,
             resource = reference$resource, session = sessionInfo()), "japanese-polysemy-review.rds")
```

These WIDs belong to the declared polysemy resource. A review based on
WLSP-familiarity or another inventory needs a separately inspected
crosswalk; do not transfer its candidate IDs into this join. For
independent reviewers, use
[`lexdiv_compare_ambiguity()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_compare_ambiguity.md)
as in the [ambiguity
guide](https://ryuya-dot-com.github.io/ldfreq/articles/ambiguity-review.md)
before creating a separately retained adjudicated result. Do not select
records because their norm values give the desired experimental
contrast.

The estimate still characterizes a resource record. A context choice
does not make it a rating collected for that sentence, split a
form-frequency table by sense, or measure similarity between meanings.
Studying processing effects requires a task, lexical unit, independent
outcome evidence, and treatment of repeated participants/items and
unresolved selections.
