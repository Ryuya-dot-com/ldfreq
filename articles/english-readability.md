# Calculate English readability with visible counting decisions

How much of a readability difference comes from sentence length, and how
much from counting syllables? Flesch Reading Ease and Flesch–Kincaid
Grade Level combine these components. Keeping the counts beside the
score lets you inspect the result before interpreting a difference
between texts.

This guide uses **ldfreq 0.3.0.9012 or later**. The helpers in
`examples/readability.R` are explicitly sourced installed examples, not
exported functions. They calculate the published formulas under
**recorded counting conditions**. Automatic syllables use optional
**nsyllable \>= 1.0.1** and are estimates; hand-supplied counts need no
optional package. These examples do not establish accuracy on learner
writing or validate a reader’s ability, a school placement, or an L2
proficiency level. Only declared English input is supported.

## Start from sentences and inspect what was counted

``` r
library(ldfreq)

demo <- new.env(parent = globalenv())
sys.source(system.file("examples", "readability-demo.R",
  package = "ldfreq", mustWork = TRUE), demo)
helper <- demo$helper
prepared <- demo$prepared
analysis <- demo$analysis
print(prepared$segments[c("document_id", "segment_id", "text", "status")], row.names = FALSE)
#>  document_id segment_id                  text           status
#>           d1         s1          The cat sat.          counted
#>           d1         s2          The dog ran.          counted
#>           d1    heading A heading to exclude. excluded_segment
#>           d2         s1 A little rabbit runs.          counted
#>           d3         s1 In 1918, R.F.D. grew.          counted
#>           d4         s1                               no_words
#>           d5         s1                 Bird.          counted
```

These short, authored texts expose the arithmetic; they are not a
readability validation sample. Supply one sentence per segment, with
unique `document_id`/`segment_id` pairs and the original text. An empty
document still has a row with `text = ""`. Preserve the original file
and the boundary decisions used to produce these segments. Offsets in
the result are local to each supplied segment, not offsets into an
unsupplied file.

``` r
helper <- new.env(parent = globalenv())
sys.source(system.file("examples", "readability.R", package = "ldfreq", mustWork = TRUE), helper)
prepared <- helper$readability_prepare(segments, language = "en",
  sentence_policy = "reviewed sentence boundaries; headings excluded",
  include = include_sentence)
```

`sentence_policy` describes your procedure; it does not run a sentence
splitter. The helper counts each included segment containing at least
one word as one sentence. It does not silently filter out very short or
long sentences. Review abbreviations, fragments, quotations, lists,
colons and semicolons when defining boundaries. Kincaid and colleagues’
[original instructions,
pp. 39–40](https://archive.org/download/DTIC_ADA006655/DTIC_ADA006655.pdf)
include independent units and fragments; punctuation alone is not a
complete boundary rule. `language = "en"` is your declaration, not
automatic detection.

The [English
tokenizer](https://ryuya-dot-com.github.io/ldfreq/articles/english-tokenization.md)
retains contractions, hyphenated words, dotted initialisms and numeric
expressions. URLs, email addresses and punctuation are excluded.
Original text and token spans remain available, including excluded
sentences and the tokenizer’s URL/email audit. Curly apostrophes and two
Unicode hyphens have canonical token surfaces; their original surfaces
and code-point positions are also saved. No Unicode normalization or
case folding is applied at this stage.

These are operational word rules, **not a reproduction of every original
sampling and counting instruction**. For example, a standalone currency
symbol does not become a spoken word in this tokenizer. [Flesch’s 1948
instructions, reprinted on
pp. 106–107](https://files.eric.ed.gov/fulltext/ED506404.pdf) count
hyphenated forms as one word and syllables by pronunciation, including
figures and symbols. They also describe 100-word sampling with a
sentence-end adjustment. Here the ratios use all included text. Audit
mismatches before use; if the operational word units do not fit your
protocol, this helper is unsuitable for that protocol. Do not force its
word total to equal a lexical-diversity analysis with different
preprocessing.

## Estimate syllables, then review pronunciations

``` r
automatic <- helper$readability_score(prepared)
audit <- cbind(prepared$tokens[c("document_id", "segment_id", "original_surface", "counted")],
  automatic$syllables[c("syllables", "method")])
print(audit, row.names = FALSE)
#>  document_id segment_id original_surface counted syllables
#>           d1         s1              The    TRUE         1
#>           d1         s1              cat    TRUE         1
#>           d1         s1              sat    TRUE         1
#>           d1         s2              The    TRUE         1
#>           d1         s2              dog    TRUE         1
#>           d1         s2              ran    TRUE         1
#>           d1    heading                A   FALSE         1
#>           d1    heading          heading   FALSE         2
#>           d1    heading               to   FALSE         1
#>           d1    heading          exclude   FALSE         2
#>           d2         s1                A    TRUE         1
#>           d2         s1           little    TRUE         2
#>           d2         s1           rabbit    TRUE         2
#>           d2         s1             runs    TRUE         1
#>           d3         s1               In    TRUE         1
#>           d3         s1             1918    TRUE        NA
#>           d3         s1           R.F.D.    TRUE        NA
#>           d3         s1             grew    TRUE         1
#>           d5         s1             Bird    TRUE         1
#>                  method
#>              dictionary
#>              dictionary
#>              dictionary
#>              dictionary
#>              dictionary
#>              dictionary
#>              dictionary
#>              dictionary
#>              dictionary
#>              dictionary
#>              dictionary
#>              dictionary
#>              dictionary
#>              dictionary
#>              dictionary
#>  pronunciation_required
#>  pronunciation_required
#>              dictionary
#>              dictionary
```

[nsyllable](https://search.r-project.org/CRAN/refmans/nsyllable/html/nsyllable.html)
uses a pronunciation dictionary and a vowel-group fallback for unknown
words. The helper distinguishes dictionary matches, fallback estimates
and unavailable counts. A finite estimate is not a verified
pronunciation. Digits and dotted initialisms are withheld for explicit
pronunciation review, even if a vowel guess would return a number. Other
abbreviations, names, compounds, misspellings and pronunciation variants
also require review. The result records the package version, dictionary
hash, lowercase policy and estimation method.

Every included word contributes to the word denominator. If even one
lacks a syllable count, both formula scores are `NA`; the known syllable
subtotal and number of unresolved words remain visible. Missing counts
are not replaced by one, and unresolved words are not removed from the
denominator.

In the hand-counted example, `1918` and `R.F.D.` initially have no
pronunciation decision. The second analysis supplies four and three
syllables respectively, with the spoken forms recorded in
`review_reason`.

``` r
print(demo$initial$components, row.names = FALSE)
#>  document_id words sentences syllables known_syllables missing_syllable_words
#>           d1     6         2         6               6                      0
#>           d2     4         1         6               6                      0
#>           d3     4         1        NA               2                      2
#>           d4     0         0        NA               0                      0
#>           d5     1         1         1               1                      0
#>  below_word_threshold            status
#>                  TRUE                ok
#>                  TRUE                ok
#>                  TRUE missing_syllables
#>                  TRUE          no_words
#>                  TRUE                ok
print(subset(demo$reviewed, nzchar(review_reason),
  select = c(token_row, syllables, method, review_reason)), row.names = FALSE)
#>  token_row syllables                 method
#>         16         4 declared pronunciation
#>         17         3 declared pronunciation
#>                                   review_reason
#>                  nineteen eighteen: 4 syllables
#>  letters R, F, D spoken separately: 3 syllables
```

For your own review, copy the **complete** syllable table, edit its
counts and methods, and retain reasons alongside the unchanged first
analysis. The `source_id` and `token_row` keys bind counts to this
preparation; tables from a different source or sentence policy,
duplicate keys and missing rows fail. Rows can be reordered because the
keys determine alignment. All source tokens, including excluded
sentences, keep a row; their unresolved counts do not make included text
unavailable.

``` r
reviewed <- automatic$syllables
reviewed$review_reason <- ""
# Change selected syllables, method, and review_reason after inspecting the text.
analysis <- helper$readability_score(prepared, reviewed,
  syllable_source = "pronunciation review; decisions recorded in review_reason")
record <- list(automatic = automatic, analysis = analysis, session = sessionInfo())
```

To supply counts entirely by hand, construct the same four columns:
`source_id` (the preparation’s `integrity_sha256`), `token_row`,
`syllables`, and `method`. Counts are positive whole numbers or `NA`,
never zero. A descriptive `syllable_source` is required. Extra review
columns are retained. The executable `readability-demo.R` shows this
without requiring nsyllable.

## Check components before interpreting scores

Let W be counted words, S counted sentences and Sy the complete syllable
total.

| Measure                    | Formula                         |
|----------------------------|---------------------------------|
| Flesch Reading Ease        | 206.835 − 1.015 W/S − 84.6 Sy/W |
| Flesch–Kincaid Grade Level | 0.39 W/S + 11.8 Sy/W − 15.59    |

The first is [Flesch’s reading-ease
equation](https://doi.org/10.1037/h0057532). The second is the
recalibrated equation in [Kincaid et al. (1975),
p. 40](https://archive.org/download/DTIC_ADA006655/DTIC_ADA006655.pdf).
That recalibration used Navy personnel and training-manual passages; its
[study description](https://stars.library.ucf.edu/istlibrary/56/) does
not establish a universal grade interpretation for L2 writers or
readers.

``` r
print(analysis$results[c("document_id", "measure", "value", "words", "sentences",
  "syllables", "below_word_threshold", "status")], digits = 3, row.names = FALSE)
#>  document_id              measure  value words sentences syllables
#>           d1  Flesch_Reading_Ease 119.19     6         2         6
#>           d1 Flesch_Kincaid_Grade  -2.62     6         2         6
#>           d2  Flesch_Reading_Ease  75.88     4         1         6
#>           d2 Flesch_Kincaid_Grade   3.67     4         1         6
#>           d3  Flesch_Reading_Ease  12.43     4         1         9
#>           d3 Flesch_Kincaid_Grade  12.52     4         1         9
#>           d4  Flesch_Reading_Ease     NA     0         0        NA
#>           d4 Flesch_Kincaid_Grade     NA     0         0        NA
#>           d5  Flesch_Reading_Ease 121.22     1         1         1
#>           d5 Flesch_Kincaid_Grade  -3.40     1         1         1
#>  below_word_threshold   status
#>                  TRUE       ok
#>                  TRUE       ok
#>                  TRUE       ok
#>                  TRUE       ok
#>                  TRUE       ok
#>                  TRUE       ok
#>                  TRUE no_words
#>                  TRUE no_words
#>                  TRUE       ok
#>                  TRUE       ok
```

For `d1`, the two three-word sentences contain six syllables: W = 6, S =
2, Sy = 6. Reading Ease is **119.190**, and Grade Level is **−2.620**.
Values are not clipped to 0–100 or to nonnegative grades. Neither these
values nor a short text’s computable score implies meaningful precision
or a reader classification.

`below_word_threshold` defaults to W \< 100. This is a configurable
**advisory flag**, not a validated minimum, exclusion rule, or reason to
hide a score. Record your study’s sample-length policy separately. Zero
words produce `no_words` and `NA` scores; no artificial sentence or
syllable is added. Document scores use ratios of total counts, not
averages of sentence scores.

[quanteda.textstats](https://search.r-project.org/CRAN/refmans/quanteda.textstats/html/textstat_readability.html)
implements both formulas. With identical component counts, the equations
agree. Its defaults can produce different inputs: hyphens may be split,
sentence length filters apply, and unavailable syllable estimates are
replaced by one in its
[implementation](https://github.com/quanteda/quanteda.textstats/blob/master/R/textstat_readability.R).
This helper reuses the optional syllable estimator but exposes
missingness and your supplied boundaries. Agreement on ordinary examples
does not establish end-to-end equivalence for arbitrary texts.

## Keep writer, task and occasion in the research table

``` r
print(demo$study_long[c("observation_id", "writer_id", "task", "occasion",
  "document_id", "measure", "value", "words", "status")], digits = 3, row.names = FALSE)
#>  observation_id writer_id        task occasion document_id              measure
#>              o1        w1 description       t1          d1 Flesch_Kincaid_Grade
#>              o1        w1 description       t1          d1  Flesch_Reading_Ease
#>              o2        w1   narrative       t2          d2 Flesch_Kincaid_Grade
#>              o2        w1   narrative       t2          d2  Flesch_Reading_Ease
#>              o3        w2 description       t1          d3 Flesch_Kincaid_Grade
#>              o3        w2 description       t1          d3  Flesch_Reading_Ease
#>              o4        w2   narrative       t2          d4 Flesch_Kincaid_Grade
#>              o4        w2   narrative       t2          d4  Flesch_Reading_Ease
#>              o5        w3 description       t1          d5 Flesch_Kincaid_Grade
#>              o5        w3 description       t1          d5  Flesch_Reading_Ease
#>              o6        w3   narrative       t2        <NA> Flesch_Kincaid_Grade
#>              o6        w3   narrative       t2        <NA>  Flesch_Reading_Ease
#>   value words        status
#>   -2.62     6            ok
#>  119.19     6            ok
#>    3.67     4            ok
#>   75.88     4            ok
#>   12.52     4            ok
#>   12.43     4            ok
#>      NA     0      no_words
#>      NA     0      no_words
#>   -3.40     1            ok
#>  121.22     1            ok
#>      NA    NA not_submitted
#>      NA    NA not_submitted
```

The executable example joins a planned observation roster and a unique
observation/document mapping to the two measures by document ID. The
sixth observation was not submitted; its word count stays `NA`. The
submitted empty fourth document has zero words. These states remain
distinct, as do unresolved syllables in the first analysis.
`analysis_id` identifies the saved input, syllable decisions and
settings. Keep one row per observation and selected measure in a model;
do not stack both differently scaled scores as replications.

``` r
model_data <- subset(demo$study_long,
  measure == "Flesch_Reading_Ease" & status == "ok")
stopifnot(!anyDuplicated(model_data$observation_id),
  length(unique(model_data$analysis_id)) == 1L)
```

This is an ordinary data frame with writer, task and occasion available
to `lme4`. A hypothetical formula is shown below; the tiny authored
dataset is insufficient to justify fitting it. Specify predictors,
coding, random effects and sample-length exclusions from your research
design. The [repeated-observations
guide](https://ryuya-dot-com.github.io/ldfreq/articles/repeated-observations.md)
demonstrates an actual model workflow and its diagnostics. This
readability table is separate from the lexical-metric plan contract used
there.

``` r
fit <- lme4::lmer(value ~ task + occasion + (1 | writer_id), data = model_data)
```

## Save enough to return to the text

``` r
saveRDS(demo$record, "readability-record.rds", version = 2)
write.csv(demo$study_long, "readability-study-long.csv", row.names = FALSE, na = "NA")
saved <- readRDS("readability-record.rds")
helper$readability_validate(saved$analysis)
saved$analysis$source$segments
saved$analysis$source$tokens
saved$analysis$syllables
```

The full record retains both analyses, original segments, tokenization
audits, source offsets, counts, decisions, formulas and session
information. The hash check detects changed saved fields; it is not a
judgment that the original sentence or pronunciation decisions were
correct. Pin the package revision and keep the full RDS alongside the
CSV. The flat table alone cannot recover the counting decisions.
