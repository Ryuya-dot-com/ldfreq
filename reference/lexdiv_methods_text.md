# Describe saved calculations in English or Japanese

Creates deterministic methods text from recorded settings, not a
language model. It uses the calculation version, never the current
reporting version. Saved stringi/ICU versions are reported. Numeric
parameters use a decimal point regardless of the current R display
options. Study sampling, justification of settings and inference require
the author's own account. References cover software, MATTR, MTLD/HD-D
and selected resources; other methods are identified by their saved
definition and ID.

## Usage

``` r
lexdiv_methods_text(x, language = c("en", "ja"))
```

## Arguments

- x:

  An analysis record or its JSON path.

- language:

  `"en"` or `"ja"`.

## Value

A character vector of paragraphs, including references. Write it with
`writeLines(..., useBytes = TRUE)` after UTF-8 encoding if necessary.

## Examples

``` r
recipe <- lexdiv_recipe(lexdiv_plan(presets = character(), specs = lexdiv_spec("ttr")))
run <- lexdiv_run_recipe(c(doc1 = "A short text."), recipe)
cat(lexdiv_methods_text(run), sep = "\n\n")
#> Lexical diversity was calculated for 1 documents using ldfreq 1.0.0.9001. Tokenization used ldfreq-english-word-tokenizer (version 0.1.0), NFC Unicode normalization, case handling 'lower', and exclusion of numeric tokens. Surface forms were analyzed without content-word filtering. Normalization used stringi 1.8.9 (ICU 74.2).
#> 
#> We calculated Type-token ratio (V / N). Method ID: ttr_v_over_n_v1. Parameters: none.
#> 
#> Of 1 document-by-specification rows, 0 were non-computable and retained with their missingness reasons. Advisory length flags did not automatically exclude scores. Matching settings and computability do not establish measurement precision or study comparability.
#> 
#> References:
#> Komuro, R. (2026). ldfreq: Reproducible Lexical Diversity and Frequency Profiles. R package version 1.0.0.9001.
```
