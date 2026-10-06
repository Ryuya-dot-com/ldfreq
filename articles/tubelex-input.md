# Preparing English input for TUBELEX

## Match the resource’s word units

The question is the frequency and video/channel prevalence of a text’s
word forms in the bundled TUBELEX reference corpus. Its English Treebank
table uses NLTK’s sentence-aware `word_tokenize()`. The general R
tokenizer in ldfreq retains contractions; looking up its unsplit `don't`
is a different operation from looking up `do` and `n't`. Even if both
queries match, their reference counts and denominators differ.

This optional recipe prepares English text outside R. It uses the [fixed
TUBELEX tokenization
source](https://github.com/naist-nlp/tubelex/blob/7cb5fb36add76b83a266d1967536e1a1d3faa513/tubelex.py#L1336)
and its BSD-licensed apostrophe, number-replacement, and token-filter
rules. The package’s R functions never call Python or download a model.
The script ships as an example, with the source attribution and license
in its header.

This reproduces those word-splitting/filtering steps, not the
construction of the original corpus. Subtitle cleanup, language
selection, and deduplication remain outside the recipe. Its NLTK/Punkt
version may differ from the original corpus build, so the recipe records
them for assessment and reproducibility; it does not mark arbitrary
input as automatically aligned.

## One-time preparation outside R

Use an existing Python environment with NLTK. This recipe was checked
with NLTK 3.9.3. Install the English sentence model explicitly before an
offline run:

``` sh
python3 -m pip install nltk==3.9.3
python3 -m nltk.downloader punkt_tab
```

Skip these commands if that environment and model are already available.
The model is needed because `word_tokenize()` first segments sentences.
Calling `TreebankWordTokenizer` on a whole multi-sentence document, or
setting `preserve_line=True`, does not reproduce that step.

## Prepare named documents and run the script

These blocks are not executed during R package installation or checking.
Run them in your analysis directory after the Python setup. The script
refuses to overwrite an existing output, does no runtime downloading,
and processes the supplied text locally.

``` r
library(ldfreq)
texts <- list(
  first = "I don't think it's John's book.",
  second = "I don’t think it’s John’s book. She bought 12 books."
)
jsonlite::write_json(texts, "texts.json", auto_unbox = TRUE, pretty = TRUE)
script <- system.file("examples", "tubelex-tokenize.py", package = "ldfreq")
status <- system2("python3", c(shQuote(script), "texts.json", "tubelex-tokens.json"))
stopifnot(status == 0L)
prepared <- jsonlite::read_json("tubelex-tokens.json", simplifyVector = TRUE)
# Preserve empty token arrays as character(0), rather than an R list.
prepared$documents <- lapply(prepared$documents, function(x) {
  as.character(unlist(x, use.names = FALSE))
})
prepared$documents
prepared$preprocessing

profiles <- tubelex_profile_batch(prepared$documents, normalization = "identity")
audit <- tubelex_diagnostics(profiles)
audit$summary
audit$unmatched_terms
# Keep tokenization metadata beside the R profiles.
saveRDS(list(profiles = profiles, preprocessing = prepared$preprocessing),
        "tubelex-analysis.rds")
```

The first sentence yields:

``` r
c("i", "do", "n't", "think", "it", "'s", "john", "'s", "book")
#> [1] "i"     "do"    "n't"   "think" "it"    "'s"    "john"  "'s"    "book"
```

The curly-apostrophe spelling yields the same words for that sentence.
Paired quotation marks, short primes, and multiple sentences are handled
by the source rules and NLTK rather than a blanket apostrophe
replacement. The metadata records the Python, NLTK and Unicode versions,
SHA-256 values of the English Punkt model files, the script, and the
input JSON. Retain the input and environment alongside the results when
reproducibility requires it.

## Interpret coverage and report exclusions

The upstream number rule creates `<num>`. The slim lexical table does
not include this marker, so it remains an unmatched term if retained.
Some other source-token shapes are also outside the slim table’s lexical
filter. Inspect `lookup` and coverage rather than assigning missing
terms frequency zero or silently removing them to improve the match
rate. Any extra exclusion changes the analysis denominator and must be
applied consistently and reported.

``` r
library(ldfreq)
terms <- c("i", "do", "n't", "think", "it", "'s", "john", "'s", "book")
profile <- tubelex_profile(terms, normalization = "identity")
profile$summary[, c("weighting", "eligible_items", "matched_items", "coverage", "mean_zipf")]
#>   weighting eligible_items matched_items coverage mean_zipf
#> 1     token              9             9        1  6.601118
#> 2      type              8             8        1  6.533295
```

The means are conditional on matched terms. Compare frequency alongside
coverage, under the same preparation and filtering rules for every
document. These estimates describe frequency in the reference corpus,
not proficiency or context-independent lexical sophistication.
Character-vector inputs retain `caller_supplied_terms_unverified` in the
R profile; the companion preprocessing record explains how these
particular tokens were produced.

For learner-level vocabulary use, keep the corpus features separate from
recognition, recall and contextual-use responses. The worked guide
[Connecting corpus frequency with evidence of vocabulary
use](https://ryuya-dot-com.github.io/ldfreq/articles/vocabulary-knowledge-and-use.md)
shows item-ID joins, missing pairs and directional disagreement. TUBELEX
itself does not determine which words a learner can employ.

Cite Nohejl et al. (2025), *Beyond Film Subtitles: Is YouTube the Best
Approximation of Spoken Vocabulary?*, COLING 2025,
<https://aclanthology.org/2025.coling-main.641/>, as well as ldfreq and
the NLTK implementation used in the analysis.
