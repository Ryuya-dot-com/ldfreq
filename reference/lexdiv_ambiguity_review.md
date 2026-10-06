# Review lexical candidates in their original contexts

Connects source-verified token occurrences to quanteda
keyword-in-context (KWIC) displays, caller-supplied lexical candidates
and explicit reviewer decisions. No readings or senses are inferred.
This experimental interface requires the optional quanteda package.

## Usage

``` r
lexdiv_ambiguity_review(x, targets, candidates, resource,
  decisions = NULL, window = 5, max_tokens = 1e6)
```

## Arguments

- x:

  An unmodified result of
  [`lexdiv_import_annotations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md),
  including complete tokens, original segment text and provenance.
  Alignment and snapshot identity are checked again. Do not filter or
  normalize it first.

- targets:

  Non-empty character vector of exact, case-sensitive surface forms to
  review. Duplicate targets are removed. Each target matches one token;
  phrases, whitespace, regular expressions and implicit case folding are
  not supported. An absent target remains in the summary with zero
  occurrences.

- candidates:

  Plain data frame with character `term`, `candidate_id` and `label`
  columns. Terms must belong to `targets`; each term/ID pair must be
  unique. Zero rows are allowed. Optional columns, such as reading,
  pronunciation, POS, lexeme ID, sense ID or gloss, are preserved
  without interpretation. Supply candidates for the chosen resource and
  research question; the function does not discover them.

- resource:

  Plain named list of non-empty scalar strings including `resource_id`,
  `resource_version`, `source_reference` and `data_license`. Additional
  scalar strings may describe transformations or inventory scope. These
  are caller declarations, not license verification.

- decisions:

  `NULL`, or a plain data frame containing `review_id`, `occurrence_id`,
  `status`, `candidate_id`, `reviewer` and `reason`. Copy the first two
  from an initial review. Each occurrence may appear at most once, in
  any order. Use `status = "selected"` with a valid candidate ID, or
  `status = "unresolved"` with `candidate_id = NA_character_`. Reviewer
  and reason must be non-blank strings. Omitted occurrences remain
  unreviewed or without candidates. Extra columns are retained in the
  returned decision table, for example an annotation date or an
  adjudication reference.

- window:

  One non-negative whole number giving quanteda's context window in
  token positions on each side, bounded by the supplied segment.
  Explicit whitespace-only tokens remain padding at their original
  positions.

- max_tokens:

  Positive whole-number ceiling on all source token slots, checked
  before KWIC search. This is not a byte-size or total memory ceiling.

## Details

The function reuses
[`lexdiv_as_quanteda`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_read_masc.md)
and [`quanteda::kwic()`](https://quanteda.io/reference/kwic.html) with
fixed, case-sensitive matching, then verifies exact source/query
equality to distinguish canonically equivalent Unicode spellings. It
never retokenizes. A token containing both whitespace and non-whitespace
characters is not supported by this adapter. Non-ASCII tokens require a
UTF-8 R session.

The `pre`, `keyword` and `post` columns are quanteda's reconstructed
display, with spaces between tokens. Consult `segment_text` for exact
original spelling, whitespace and punctuation. The `start`/`end` columns
index that original segment using 1-based, inclusive Unicode codepoints,
not bytes or positions in the KWIC display. Document and segment IDs
link to all original segments in `source`; the caller supplies
sentence/turn boundaries, which are not inferred.

Unreviewed occurrences with candidates have status `"unreviewed"`, even
when there is only one candidate. Those without candidates have status
`"no_candidates"`; this does not establish that they are unambiguous. An
explicit `"unresolved"` decision records that review did not settle the
interpretation. `"selected"` verifies ID membership, not semantic
correctness. Missing selections remain missing and input annotations are
not overwritten. No homonymy/polysemy classification, similarity score,
sense frequency or learner-knowledge inference is computed.

Occurrence IDs depend on document/segment identity, source text and
token position/span. Review IDs additionally bind the complete imported
snapshot, target set, candidate table and resource declarations.
Reordering targets, candidate rows or decisions, or changing the
displayed window, retains review identity. Changes to the source,
annotation metadata, target set, candidate values or resource invalidate
old decisions. Review the new snapshot and explicitly reconsider
decisions; replacing IDs mechanically defeats this check. Hashes detect
changes, not authorship or scientific validity.

The returned whole-result fingerprint allows
[`lexdiv_compare_ambiguity`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_compare_ambiguity.md)
to detect modified review outputs without rerunning KWIC. Change
decisions by calling this function again, not by editing the returned
occurrence table.

Candidates are canonically ordered by term and ID. Their count measures
the supplied inventory, not a person's number of known meanings.
Readings, phonemes, lexemes, word senses and synonym-set concepts are
different units. Selecting a sense does not split a TUBELEX or other
aggregate frequency count.

## Value

A plain list with `occurrences` (one row per matched source token,
including original token columns, KWIC, source text, IDs, candidate
count and decision fields), `candidates`, `decisions`, and `summary`
(one row per target with candidate count, occurrences and the four
status counts). Absent targets and empty source segments/documents are
retained. The complete imported object is returned as `source`;
`provenance` records review identity, resource declarations, quanteda
adapter/version and context settings. Use
[`saveRDS()`](https://rdrr.io/r/base/readRDS.html) to retain this
complete review object. It contains source text and inherits the input
data's sharing restrictions.

## See also

[`lexdiv_compare_ambiguity`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_compare_ambiguity.md),
[`lexdiv_import_contextual`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_contextual.md),
[`lexdiv_import_annotations`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_import_annotations.md),
[`lexdiv_as_quanteda`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_read_masc.md),
[`vignette("ambiguity-review", package = "ldfreq")`](https://ryuya-dot-com.github.io/ldfreq/articles/ambiguity-review.md)

## Examples

``` r
tokens <- data.frame(document_id = "d", segment_id = "s1", token_index = 1:5,
  surface = c("The", "bank", "lent", "money", "."))
segments <- data.frame(document_id = "d", segment_id = "s1",
  text = "The bank lent money.")
x <- lexdiv_import_annotations(tokens, segments, list(
  language = "en", analyzer = "authored", analyzer_version = "1",
  dictionary = "none", dictionary_version = "not-applicable",
  unit = "authored-example", normalization = "none"))
candidates <- data.frame(term = c("bank", "bank"),
  candidate_id = c("financial", "river"), label = c("financial institution", "river edge"))
resource <- list(resource_id = "authored-example", resource_version = "1",
  source_reference = "Authored illustration, not a dictionary", data_license = "MIT")
if (requireNamespace("quanteda", quietly = TRUE)) {
  review <- lexdiv_ambiguity_review(x, "bank", candidates, resource)
  review$occurrences[c("pre", "keyword", "post", "candidate_count", "status")]
  decisions <- review$occurrences[c("review_id", "occurrence_id")]
  decisions$status <- "selected"
  decisions$candidate_id <- "financial"
  decisions$reviewer <- "example-reviewer"
  decisions$reason <- "The context describes lending money."
  reviewed <- lexdiv_ambiguity_review(x, "bank", candidates, resource, decisions)
  reviewed$summary
}
#>   term candidate_count occurrences unreviewed selected unresolved no_candidates
#> 1 bank               2           1          0        1          0             0
```
