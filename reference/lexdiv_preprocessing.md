# Versioned raw-text preprocessing for lexical-diversity metrics

Tokenize one raw text under an explicit Unicode contract, attach lemmas
and optional Universal POS tags with backend provenance, and select
surface, lemma, or separately annotated flemma units before calling the
versioned lexical-diversity core.

## Usage

``` r
lexdiv_tokenize(
  text,
  normalization = "NFC",
  case = "preserve",
  keep_numbers = FALSE,
  tokenizer = "unicode"
)

lexdiv_lemmatize(
  x,
  method = "supplied",
  lemmas = NULL,
  upos = NULL,
  backend_id = NULL,
  backend_version = NULL,
  upos_backend_id = NULL,
  upos_backend_version = NULL,
  dictionary = NULL,
  dictionary_id = NULL,
  dictionary_version = NULL
)

lexdiv_metrics_text(
  x,
  unit = "surface",
  word_inclusion = "all",
  normalization = "NFC",
  case = "preserve",
  keep_numbers = FALSE,
  metrics = lexdiv_metric_ids(),
  segment_length = 50L,
  window_length = 50L,
  mtld_threshold = 0.72,
  sample_size = 42L,
  expected_ttr_sample_sizes = 35:50,
  tokenizer = "unicode"
)

# S3 method for class 'lexdiv_tokenization'
print(x, ...)

# S3 method for class 'lexdiv_text_results'
print(x, ...)
```

## Arguments

- text:

  One plain valid-UTF-8 character string. An empty string is valid.

- normalization:

  Unicode normalization: `"NFC"`, `"NFKC"`, or `"none"`.

- case:

  Either `"preserve"` or locale-fixed English `"lower"`.

- keep_numbers:

  Whether numeric tokens are retained. With `"unicode"`, this concerns
  tokens consisting only of Unicode numbers; with `"english"`, it also
  covers recognized numeric expressions such as dates and percentages.
  This is a pattern rule, not a semantic NUM tag: spelled-out numbers
  and alphanumeric forms such as `"two"`, `"2nd"`, and `"COVID-19"`
  remain.

- tokenizer:

  `"unicode"` preserves the original word rules; `"english"` selects the
  English lexical rules described below.

- x:

  For `lexdiv_lemmatize()`, an object created by `lexdiv_tokenize()`.
  For `lexdiv_metrics_text()`, either that object or one raw character
  string. When an existing tokenization is supplied, its recorded
  normalization, case, and number-retention choices are authoritative;
  supplying `normalization`, `case`, `keep_numbers`, or `tokenizer`
  again is an error. Call `lexdiv_tokenize()` again to change those
  choices. For the print methods, `x` is the corresponding result
  object.

- method:

  Lemma source: caller-`"supplied"` values or the optional `"textstem"`
  backend.

- lemmas:

  An aligned character vector of lemmas for the supplied method. Missing
  values are allowed and are later reported as exclusions.

- upos:

  Optional aligned Universal POS tags. Missing values are allowed.
  Non-missing tags are uppercased and must belong to the Universal POS
  inventory; unsupported labels are errors rather than ordinary
  non-content words. The textstem backend supplies lemmas only and does
  not infer UPOS. Supply tags explicitly when a later
  `word_inclusion = "content"` analysis is required.

- backend_id, backend_version:

  Required non-empty, path-free lemma-backend identifiers for
  caller-supplied annotations. For textstem, package identity is
  recorded automatically and these arguments must be `NULL`. Caller
  labels are public provenance and must not contain paths, secrets, or
  private hashes.

- upos_backend_id, upos_backend_version:

  Required path-free UPOS-backend identifiers whenever any non-missing
  UPOS tag is present. They are never defaulted from the lemma backend,
  even when one pipeline created both layers. They must be `NULL` when
  no UPOS tags are present. These values are public provenance; callers
  must not put paths, secrets, or private hashes in them.

- dictionary:

  For `method = "textstem"`, an optional two-column data frame: unique
  lowercase lookup terms in column one and lemmas in column two. Both
  columns must be character vectors without empty or missing values.
  Column names and row order do not affect lookup. An empty dictionary
  is allowed. The default is
  [`lexicon::hash_lemmas`](https://rdrr.io/pkg/lexicon/man/hash_lemmas.html).
  Unmatched tokens retain their surface forms; lookup lowercases queries
  with base R in the current locale.

- dictionary_id, dictionary_version:

  Required non-empty path-free labels when supplying a dictionary;
  `NULL` for the default dictionary, whose identity and installed
  lexicon version are recorded automatically. All three dictionary
  arguments must be `NULL` for `method = "supplied"`.

- unit:

  One of `"surface"`, `"lemma"`, or `"flemma"`. Lemma and flemma
  analyses require the corresponding annotations on a
  `lexdiv_tokenization` object; raw character input supports surface
  analysis only.

- word_inclusion:

  Either `"all"` word tokens or `"content"`, defined as UPOS `ADJ`,
  `ADV`, `NOUN`, `PROPN`, and `VERB`.

- metrics:

  A duplicate-free vector from
  [`lexdiv_metric_ids()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md).

- segment_length:

  Requested complete segment length for MSTTR.

- window_length:

  Requested step-one window length for MATTR.

- mtld_threshold:

  Requested MTLD threshold strictly between zero and one.

- sample_size:

  Requested without-replacement sample size for HD-D.

- expected_ttr_sample_sizes:

  A non-empty, strictly increasing vector of sample sizes used to fit
  deterministic expected-TTR D.

- ...:

  Additional arguments passed to the underlying data-frame print method.

## Details

The default `"unicode"` tokenizer extracts Unicode letter, mark, and
number sequences, retaining internal apostrophes and hyphens while
excluding punctuation tokens. Start and end offsets refer to the
processed text after the requested normalization and case transformation
(Unicode code points, not bytes or original-text offsets).

The opt-in `"english"` tokenizer keeps contractions and hyphenated words
whole, preserves dotted initialisms such as `U.S.A.`, and excludes
recognized HTTP(S)/www URLs and dotted-domain email addresses before
looking for words. It recognizes number-like spans including decimals,
grouped numbers, numeric dates, fractions, exponents and percentages.
These are lexical rules, not numeric or date validation. By default they
are excluded; `keep_numbers = TRUE` retains them. Standalone combining
marks are ignored. After the requested normalization and case
conversion, left/right curly apostrophes become ASCII apostrophes and
Unicode hyphen/non-breaking hyphen become ASCII hyphens. This mapping
applies even with `normalization = "none"`. For example, `"can't"` stays
one word, `well-known` stays one word, `3.14` is one number, and `Dr.`
contributes `Dr`. URL recognition can include trailing punctuation. Bare
domains without www or HTTP(S), malformed addresses, and linguistic
exceptions are not inferred. Neither tokenizer expands contractions,
supplies lemmas, performs multilingual word segmentation, or reproduces
Treebank/TUBELEX segmentation.

English provenance includes `excluded_spans`, a data frame with
processed `start`/`end` offsets, `surface`, and `reason` (`url`,
`email`, or `number`), plus its SHA-256 fingerprint. These records
retain excluded text; they are an analysis audit, not redacted output.
Ordinary punctuation and ignored symbols are not listed. Only retained
word/number tokens enter the later lexical-unit selection denominator.
Saved Unicode tokenizations under preprocessing contract 0.2.0 remain
accepted with their recorded provenance, as do contract 0.3.0
tokenizations of either kind. New objects use contract 0.4.0, and
reapplying `lexdiv_lemmatize()` upgrades the annotation record. Older
textstem records lacking dictionary provenance remain readable but
cannot establish strict lemma comparability in
[`lexdiv_content_overlap()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_overlap.md).
Tokenization rules and metric schemas are unchanged.

The package does not silently choose or download a lemmatization model.
`lexdiv_lemmatize(method = "supplied")` accepts annotations created by
any documented external workflow and requires its identity and version.
`method = "textstem"` is an optional English lemma convenience backend.
It records the installed textstem version but does not create UPOS tags.
The annotation's `dictionary` record contains the dictionary ID,
version, entry count, SHA-256 content fingerprint, hash method, and
query casefold/locale. The fingerprint ignores row order and column
names but changes if a mapping changes, even with the same version
label. It hashes length-prefixed UTF-8 term/lemma pairs in sorted term
order, as specified in the installed contract. It is a content
comparison aid, not proof of authenticity or linguistic accuracy. The
dictionary itself is not retained: save it separately alongside the
prepared objects to rerun lookup, and retain the backend version and
locale. A loaded object can validate record structure but cannot
recompute the dictionary hash without the original dictionary. The
backend performs context-free lookup; use aligned supplied annotations
for occurrence-specific decisions. Consequently, it can be used directly
for `unit = "lemma"` with `word_inclusion = "all"`; content-word
selection additionally requires caller-supplied UPOS annotations.
Missing lemmas or UPOS tags are excluded and reported in the token audit
rather than imputed.

Lemma and UPOS backend identities are separate. Supplying UPOS tags
always requires explicit `upos_backend_id` and `upos_backend_version`;
the package does not derive them from `backend_id` or `backend_version`.
[`lexdiv_flemmatize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_flemmatize.md)
is a separate caller-supplied AntBNC adapter because flemma counting
does not preserve POS distinctions and is not synonymous with ordinary
lemmatization.

`lexdiv_metrics_text()` does not add preprocessing columns to the
versioned metric result schema. It returns the unchanged core results
beside a token-level audit and a separately versioned preprocessing
record. This allows surface/lemma/flemma and all/content-word analyses
to be compared without treating one choice as a universal default.

The tokenizer arguments `normalization`, `case`, `keep_numbers`, and
`tokenizer` apply only when `x` is raw text. They are never silently
reapplied to, or ignored for, an existing tokenization object.

## Saved-object compatibility

Preprocessing contract `0.4.0` validates annotation and provenance,
including explicit UPOS-backend identity, text hashes, character bounds,
normalization consistency, and a fingerprint of the surface token table,
whenever an object is consumed. Both tokenizer rule sets use their own
identity and version 0.1.0. Unicode objects saved under preprocessing
contract 0.2.0 remain accepted. Objects saved with preprocessing
contract 0.1.0 must be recreated from the original text; their
token-table fingerprint cannot be recovered as verified provenance by
simply relabeling the saved object. If a saved `lexdiv_tokenization` has
incomplete, unsupported, or manually altered provenance, recreate it
from the original text with `lexdiv_tokenize()` and then reapply
annotations with the current functions and explicit identities. The
fingerprint detects ordinary token-table edits; it is not authentication
and cannot reconstruct or verify the original text from its hash.

## Formal contract

The installed `ldfreq-preprocessing-contract.json` file fixes tokenizer,
normalization, annotation, lexical-unit, and result-boundary behavior.
Use [`system.file()`](https://rdrr.io/r/base/system.file.html) with
directory `"spec"`, that filename, and `package = "ldfreq"` to locate
it. The contract is ordinary JSON and can be inspected without running a
preprocessing backend.

## Value

`lexdiv_tokenize()`, `lexdiv_lemmatize()`, and
[`lexdiv_flemmatize()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_flemmatize.md)
return a `lexdiv_tokenization` object containing `tokens` and
`provenance`. `lexdiv_metrics_text()` returns a `lexdiv_text_results`
list containing `results`, `token_audit`, and `preprocessing`. The print
methods return `x` invisibly.

## See also

[`lexdiv_flemmatize`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_flemmatize.md),
[`lexdiv_metrics`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_metrics.md),
[`tubelex_profile`](https://ryuya-dot-com.github.io/ldfreq/reference/tubelex_profile.md)

## Examples

``` r
english <- lexdiv_tokenize(
  "John's well-known book costs 3.14. See https://example.org.",
  tokenizer = "english", case = "lower"
)
english$tokens
#>   token_index start end    surface is_number
#> 1           1     1   6     john's     FALSE
#> 2           2     8  17 well-known     FALSE
#> 3           3    19  22       book     FALSE
#> 4           4    24  28      costs     FALSE
#> 5           5    36  38        see     FALSE
english$provenance$excluded_spans
#>   start end              surface reason
#> 1    30  33                 3.14 number
#> 2    40  59 https://example.org.    url

tokenization <- lexdiv_tokenize("Cats and cat ran run.")
surface <- lexdiv_metrics_text(tokenization, metrics = "ttr")
surface$results
#> <lexdiv_results: 1 metric; contract 0.1.0>
#>   metric_id value status missing_reason N V below_quality_floor
#> 1       ttr     1     ok           <NA> 5 5               FALSE

annotated <- lexdiv_lemmatize(
  tokenization,
  lemmas = c("cat", "and", "cat", "run", "run"),
  upos = c("NOUN", "CCONJ", "NOUN", "VERB", "VERB"),
  backend_id = "documented-example-annotations",
  backend_version = "1",
  upos_backend_id = "documented-example-upos",
  upos_backend_version = "1"
)
lemma_content <- lexdiv_metrics_text(
  annotated,
  unit = "lemma",
  word_inclusion = "content",
  metrics = "ttr"
)
lemma_content$results
#> <lexdiv_results: 1 metric; contract 0.1.0>
#>   metric_id value status missing_reason N V below_quality_floor
#> 1       ttr   0.5     ok           <NA> 4 2               FALSE
lemma_content$token_audit
#>   token_index surface selected_unit unit_match_rule  upos eligible
#> 1           1    Cats           cat            <NA>  NOUN     TRUE
#> 2           2     and           and            <NA> CCONJ    FALSE
#> 3           3     cat           cat            <NA>  NOUN     TRUE
#> 4           4     ran           run            <NA>  VERB     TRUE
#> 5           5     run           run            <NA>  VERB     TRUE
#>   exclusion_reason
#> 1             <NA>
#> 2 non_content_upos
#> 3             <NA>
#> 4             <NA>
#> 5             <NA>

if (requireNamespace("textstem", quietly = TRUE)) {
  textstem_tokens <- lexdiv_tokenize(
    "The cats were running and studies.",
    case = "lower"
  )
  textstem_lemmas <- lexdiv_lemmatize(
    textstem_tokens,
    method = "textstem"
  )
  textstem_lemmas$tokens[, c("surface", "lemma")]
  textstem_lemmas$provenance$annotation
  lexdiv_metrics_text(textstem_lemmas, unit = "lemma", metrics = "ttr")
}
#> <lexdiv_text_results> 6/6 eligible tokens | unit=lemma | inclusion=all
#> <lexdiv_results: 1 metric; contract 0.1.0>
#>   metric_id value status missing_reason N V below_quality_floor
#> 1       ttr     1     ok           <NA> 6 6               FALSE
```
