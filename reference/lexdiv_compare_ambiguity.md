# Compare two contextual lexical-candidate reviews

Pairs intact review results by occurrence ID, describes
candidate-selection agreement with explicit coverage, and retains
disagreements and other open cases with both KWIC contexts and reasons.
No decisions are altered or inferred.

## Usage

``` r
lexdiv_compare_ambiguity(a, b)
```

## Arguments

- a,b:

  Unmodified results from
  [`lexdiv_ambiguity_review`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ambiguity_review.md),
  including their whole-result fingerprints. Both must use the same
  complete source annotations, target set, candidate inventory and
  resource declarations. Decisions and KWIC window sizes may differ;
  each review's settings are retained. No quanteda call, text search or
  resource lookup is repeated for comparison.

## Details

Each pair receives one outcome: `agreement` (both selected the same
candidate), `disagreement` (both selected different candidates),
`selected_a_only`, `selected_b_only`, or `neither_selected`.
`same_candidate` is missing unless both reviews selected a candidate.
Two unresolved, unreviewed or no-candidate statuses are not semantic
agreement. An unresolved decision counts as reviewed, but not as a
selected interpretation.

`agreement_among_both_selected` is the number of agreements divided by
`both_selected`. `both_selected_proportion` divides that denominator by
all matched target occurrences. A zero denominator gives `NA_real_`. The
summary retains counts as well as these proportions; target-level rows
include targets with zero occurrences. Overall agreement pools
occurrence counts, not target-level percentages. It depends on which
cases both reviewers selected and is not a chance-corrected coefficient
or a reliability estimate for all source tokens. Candidate inventories
and ambiguity may differ by term; the same candidate ID on two terms is
not assumed to denote the same meaning.

The input decision fields preserve actual reviewer labels. The function
can compare different reviewers or repeat reviews by one person; it
cannot verify independence, adequate context, rater blinding, accuracy,
or the annotation scheme's validity. It does not estimate kappa, alpha,
confidence intervals or population reliability. Study design must
address repeated items, documents, raters and unresolved cases before
inference. Keep pre-adjudication reviews separately; consensus after
discussion is not independent agreement.

To update a review, change its decision input and regenerate it with
[`lexdiv_ambiguity_review()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ambiguity_review.md).
Older saved reviews lacking a content fingerprint can be regenerated
from their `source`, `summary$term`, `candidates`,
`provenance$resource`, `decisions` and `provenance$window`. Source and
candidate checks remain in force. Fingerprints detect accidental
changes, not authenticity or semantic validity.

## Value

A plain list with:

- summary:

  One overall row containing all matched occurrences, no-candidate
  occurrences, reviewed counts for each side and both sides,
  `both_selected`, the five outcome counts and the two proportions.

- terms:

  The same quantities for each target in `a`'s target order.

- pairs:

  One row per source occurrence, retaining source IDs, positions,
  surface, original segment text, candidate count, both KWIC windows,
  statuses, candidate IDs, reviewers and reasons, `same_candidate` and
  `outcome`.

- review_queue:

  All non-agreement rows, including unresolved, unreviewed and
  no-candidate cases. These cases may need further context or an
  inventory revision, not just adjudication. Neither side is chosen
  automatically.

- status_pairs:

  Observed term/A-status/B-status combinations and their counts.

- reviews:

  Both complete input reviews, including additional source-token
  metadata, original decisions and provenance.

- provenance:

  Comparison identity, pairing and denominator definitions,
  missing-value policy and interpretation boundary.

## See also

[`lexdiv_ambiguity_review`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_ambiguity_review.md),
[`vignette("ambiguity-review", package = "ldfreq")`](https://ryuya-dot-com.github.io/ldfreq/articles/ambiguity-review.md)

## Examples

``` r
tokens <- data.frame(document_id = "d", segment_id = "s", token_index = 1:2,
  surface = c("river", "bank"))
x <- lexdiv_import_annotations(tokens,
  data.frame(document_id = "d", segment_id = "s", text = "river bank"),
  list(language = "en", analyzer = "authored", analyzer_version = "1",
    dictionary = "none", dictionary_version = "none", unit = "example",
    normalization = "none"))
candidates <- data.frame(term = c("bank", "bank"),
  candidate_id = c("financial", "river"), label = c("financial institution", "river edge"))
resource <- list(resource_id = "authored", resource_version = "1",
  source_reference = "Authored illustration", data_license = "MIT")
if (requireNamespace("quanteda", quietly = TRUE)) {
  initial <- lexdiv_ambiguity_review(x, "bank", candidates, resource)
  decisions <- initial$occurrences[c("review_id", "occurrence_id")]
  decisions$status <- "selected"; decisions$candidate_id <- "river"
  decisions$reviewer <- "A"; decisions$reason <- "River context."
  a <- lexdiv_ambiguity_review(x, "bank", candidates, resource, decisions)
  decisions$status <- "unresolved"; decisions$candidate_id <- NA_character_
  decisions$reviewer <- "B"; decisions$reason <- "Retained for review in this illustration."
  b <- lexdiv_ambiguity_review(x, "bank", candidates, resource, decisions)
  comparison <- lexdiv_compare_ambiguity(a, b)
  comparison$summary # No pair has two selections: agreement is undefined.
  comparison$review_queue[c("surface", "a_status", "b_status", "outcome")]
}
#>   surface a_status   b_status         outcome
#> 1    bank selected unresolved selected_a_only
```
