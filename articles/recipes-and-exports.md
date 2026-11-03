# Reuse settings and export an auditable analysis

A recipe preserves calculation settings. An analysis record also
preserves original texts, counted units, unavailable results, document
metadata and the calculation environment. You can reuse settings on
another folder, inspect differences between runs and describe what was
actually calculated. This does not decide whether two study populations
are comparable.

The initial recipe schema supports **raw text, surface forms and all
word tokens**, with either built-in tokenizer and optional pinned
NJ8/TUBELEX references. Lemma/flemma reconstruction, custom resources
and external annotation pipelines continue to use the existing APIs and
complete RDS records. Their settings are not inferred from partially
recorded metadata.

## Define and reuse settings

``` r

plan <- lexdiv_plan(presets = character(), specs = list(
  lexdiv_spec("ttr"),
  lexdiv_spec("mattr", list(window_length = 5), request_id = "mattr5"),
  lexdiv_spec("mtld", list(threshold = 0.72))))
recipe <- lexdiv_recipe(plan, normalization = "NFC", case = "lower")
texts <- c("001" = "A small cat watches another small cat near the window.",
           "002" = "Writers revise their texts and retain earlier drafts.",
           "003" = "")
metadata <- data.frame(document_id = names(texts),
  writer_id = c("w1", "w1", "w2"), task = "description", occasion = c(1, 2, 1))
run <- lexdiv_run_recipe(texts, recipe, metadata = metadata, condition_id = "primary")
run$analysis$results[, c("document_id", "request_id", "value", "status", "missing_reason")]
#> <lexdiv_profile_batch_results: 3 documents; 9 specification results; schema unknown>
#>   document_id                            request_id      value  status
#> 1         001  ttr-4fb55d484c9910369ed7bfb8e1bb1631  0.8000000      ok
#> 2         001                                mattr5  0.9333333      ok
#> 3         001 mtld-f3c9dc19ce5334b9bd2c0d537d29daac 12.0000000      ok
#> 4         002  ttr-4fb55d484c9910369ed7bfb8e1bb1631  1.0000000      ok
#> 5         002                                mattr5  1.0000000      ok
#> 6         002 mtld-f3c9dc19ce5334b9bd2c0d537d29daac         NA missing
#> 7         003  ttr-4fb55d484c9910369ed7bfb8e1bb1631         NA missing
#> 8         003                                mattr5         NA missing
#> 9         003 mtld-f3c9dc19ce5334b9bd2c0d537d29daac         NA missing
#>   missing_reason
#> 1           <NA>
#> 2           <NA>
#> 3           <NA>
#> 4           <NA>
#> 5           <NA>
#> 6      no_factor
#> 7    empty_input
#> 8    empty_input
#> 9    empty_input
```

The two documents by `w1` remain linked. Three documents and several
measures do not become independent writer observations. The saved
`$analysis` retains the complete batch result accepted by
[`lexdiv_study_table()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_study_table.md).

Presets are expanded before saving. Reading does not substitute today’s
defaults. Execution requires the recorded package, method/preprocessing
contracts, tokenizer, stringi and ICU versions. To deliberately change
environments, construct a new recipe and retain the original. Reusing a
recipe restores settings; reproducing a result also requires identical
source texts.

``` r

folder <- tempfile("ldfreq-example-")
dir.create(folder)
lexdiv_write(recipe, file.path(folder, "recipe.json"))
lexdiv_write(run, file.path(folder, "analysis.json"))
restored <- lexdiv_read(file.path(folder, "analysis.json"))
stopifnot(identical(restored, run))
repeated <- lexdiv_run_recipe(texts,
  lexdiv_read(file.path(folder, "recipe.json")), metadata = metadata)
stopifnot(identical(repeated$analysis$results, run$analysis$results))
```

Recipes contain no source texts. Analysis JSON contains source texts and
token audits: keep it under the study’s access rules. Existing files are
never overwritten. Factor and date/time metadata become character labels
in this portable record; retain original R objects if their classes or
levels are needed.

Keep the study’s planned observations separately from the submitted
documents. Here `w2` submitted an empty text at the first occasion and
no text at the second:

``` r

planned <- data.frame(observation_id = paste0("o", 1:4),
  writer_id = c("w1", "w1", "w2", "w2"), task = factor("description"),
  occasion = c(1, 2, 1, 2))
submissions <- data.frame(observation_id = paste0("o", 1:3),
  document_id = restored$documents$document_id)
study <- lexdiv_study_table(planned, submissions, restored$analysis, plan,
  condition_id = restored$condition_id)
study[, c("observation_id", "writer_id", "occasion", "request_id", "input_status")]
#>    observation_id writer_id occasion                            request_id
#> 1              o1        w1        1  ttr-4fb55d484c9910369ed7bfb8e1bb1631
#> 2              o1        w1        1                                mattr5
#> 3              o1        w1        1 mtld-f3c9dc19ce5334b9bd2c0d537d29daac
#> 4              o2        w1        2  ttr-4fb55d484c9910369ed7bfb8e1bb1631
#> 5              o2        w1        2                                mattr5
#> 6              o2        w1        2 mtld-f3c9dc19ce5334b9bd2c0d537d29daac
#> 7              o3        w2        1  ttr-4fb55d484c9910369ed7bfb8e1bb1631
#> 8              o3        w2        1                                mattr5
#> 9              o3        w2        1 mtld-f3c9dc19ce5334b9bd2c0d537d29daac
#> 10             o4        w2        2  ttr-4fb55d484c9910369ed7bfb8e1bb1631
#> 11             o4        w2        2                                mattr5
#> 12             o4        w2        2 mtld-f3c9dc19ce5334b9bd2c0d537d29daac
#>       input_status
#> 1  selected_tokens
#> 2  selected_tokens
#> 3  selected_tokens
#> 4  selected_tokens
#> 5  selected_tokens
#> 6  selected_tokens
#> 7       empty_text
#> 8       empty_text
#> 9       empty_text
#> 10   not_submitted
#> 11   not_submitted
#> 12   not_submitted
```

This retains four planned observations, three submitted documents and
their distinct missingness states. Use
[`lexdiv_study_model_data()`](https://ryuya-dot-com.github.io/ldfreq/reference/lexdiv_study_table.md)
to select a single response after making reporting decisions. The
planned table retains its R types and factor levels; save it and the
study table as RDS alongside the JSON.

## Inspect differences

``` r

other <- lexdiv_run_recipe(c(other = "A different text."), recipe)
comparison <- lexdiv_compare_analyses(run, other)
comparison$measurement
#> [1] "same"
comparison$differences
#>                   field severity
#> 1 selected_token_counts  caution
#> 2          availability  caution
#>                                                       left
#> 1                                                 [0,8,10]
#> 2 {"documents":3,"unavailable":4,"below_advisory_floor":7}
#>                                                      right
#> 1                                                        3
#> 2 {"documents":1,"unavailable":2,"below_advisory_floor":2}
#>                                                                                                      explanation
#> 1 Document counts or length distributions differ. Evaluate length sensitivity for each measure and study design.
#> 2                       Availability or advisory-length flags differ; flags do not automatically exclude scores.
```

`measurement = "same"` means no recorded measurement-definition,
preprocessing engine or resource-setting difference was found.
Package-version changes are separate cautions: review release changes
before treating implementations as equivalent. `study_comparability`
remains `"not_established"`. Task, sampling, genre, writer dependencies
and uncertainty require the study’s own analysis. Length/coverage
differences do not impose a universal exclusion cutoff. Lengths are
checked both as a batch distribution and by shared document ID. Swapped
lengths therefore produce a caution even when the distributions match. A
shared ID does not by itself establish that two rows are paired
observations.

Different windows or resources may be intentional sensitivity
conditions. The checker identifies different measurements and preserves
both runs; it does not forbid that question or pool the scores. Unknown
schemas, incomplete request rows and inconsistent source/count records
are rejected.

## Write methods text and tidy CSV

``` r

cat(lexdiv_methods_text(run, "en"), sep = "\n\n")
#> Lexical diversity was calculated for 3 documents using ldfreq 1.0.0.9001. Tokenization used ldfreq-english-word-tokenizer (version 0.1.0), NFC Unicode normalization, case handling 'lower', and exclusion of numeric tokens. Surface forms were analyzed without content-word filtering. Normalization used stringi 1.8.9 (ICU 74.2).
#> 
#> We calculated Type-token ratio (V / N). Method ID: ttr_v_over_n_v1. Parameters: none.
#> 
#> We calculated Moving-average TTR (mean TTR of all step-one overlapping windows). Method ID: mattr_sliding_step1_v1. Parameters: window_length = 5.
#> 
#> We calculated Measure of textual lexical diversity (mean forward/reverse tokens per factor; strict <, no minimum length with final-token closure checks, residual credit (1 - TTR) / (1 - threshold), and the arithmetic mean of directional scores). Method ID: mtld_seq_bidir_dirmean_lt_nomin_linear_tail_v1. Parameters: threshold = 0.72.
#> 
#> Of 9 document-by-specification rows, 4 were non-computable and retained with their missingness reasons. Advisory length flags did not automatically exclude scores. Matching settings and computability do not establish measurement precision or study comparability.
#> 
#> References:
#> Komuro, R. (2026). ldfreq: Reproducible Lexical Diversity and Frequency Profiles. R package version 1.0.0.9001.
#> Covington, M. A., & McFall, J. D. (2010). Cutting the Gordian Knot: The Moving-Average Type-Token Ratio (MATTR). https://doi.org/10.1080/09296171003643098
#> McCarthy, P. M., & Jarvis, S. (2010). MTLD, vocd-D, and HD-D: A validation study of sophisticated approaches to lexical diversity assessment. https://doi.org/10.3758/BRM.42.2.381
```

Use `lexdiv_methods_text(run, "ja")` for Japanese. Both languages retain
the calculation version, including the saved stringi and ICU
normalization versions. Numeric parameters use a decimal point even if
R’s `OutDec` option is a comma. Parameters, MTLD closure/tail rules,
unavailable rows and resource lookup choices are explicit. References
cover software, MATTR, MTLD/HD-D and used resources. Other methods
retain their precise definitions and IDs; review and add literature
needed for the paper’s substantive claims. Supply your sampling
description, setting rationale and inferential methods.

``` r

lexdiv_write(run, file.path(folder, "results.csv"), format = "csv")
flat <- read.csv(file.path(folder, "results.csv"),
  colClasses = c(document_id = "character", missing_reason = "character"),
  na.strings = "", encoding = "UTF-8")
stopifnot(identical(flat$document_id, run$analysis$results$document_id),
  isTRUE(all.equal(flat$value, run$analysis$results$value)))
```

Each row is a **document x condition x measurement request**. Two MATTR
windows retain distinct requests. Missing values/reasons survive;
parameter/diagnostic list columns become JSON strings. Explicit
character types retain leading zeros in CSV IDs. Keep JSON beside CSV:
preprocessing, resource profiles and metadata remain in the complete
record rather than being discarded or flattened into misleading repeated
observations.

## Optional references

``` r

lexdiv_resource_info(c("nj8", "tubelex"))
# After reviewing terms and explicitly obtaining the pinned resources:
reference_recipe <- lexdiv_recipe(plan, resources = c("nj8", "tubelex"),
  tubelex_tokenization_mismatch = "allow")
reference_run <- lexdiv_run_recipe(texts, reference_recipe)
reference_run$profiles$nj8$coverage
reference_run$profiles$tubelex$summary
nj8_diagnostics(reference_run$profiles$nj8)
tubelex_diagnostics(reference_run$profiles$tubelex)
# These same diagnostics and plot(reference_run$profiles$tubelex) also work
# after lexdiv_write() followed by lexdiv_read().
```

NJ8 uses surface forms, NFKC/lowercase lookup and parenthetical aliases;
off-list forms remain in the denominator. The built-in tokenizer differs
from TUBELEX’s Treebank segmentation, so explicit `"allow"` records a
segmentation-sensitivity analysis. Coverage does not establish
alignment. Missing/modified caches stop execution; there is no automatic
download or resource substitution.

## Terminal and Python entry points

Locate the installed CLI with
`system.file("exec", "ldfreq.R", package = "ldfreq")`:

``` sh
Rscript /path/to/ldfreq/exec/ldfreq.R --init recipe.json
Rscript /path/to/ldfreq/exec/ldfreq.R --recipe recipe.json --input texts --output new-results
```

UTF-8 `.txt` files, including empty files, are read in sorted
relative-path order. Add `--recursive` for subfolders; relative paths
are document IDs. The new output folder contains recipe/analysis JSON,
metric CSV and both methods texts. Failures return nonzero status
without publishing a partial output folder. Existing output folders are
refused.

Add the installed directory returned by
`system.file("python", package = "ldfreq")` to Python’s module path:

``` python
import ldfreq_r
recipe = ldfreq_r.default_recipe()
result = ldfreq_r.analyze_text("A short example text.", recipe)
batch = ldfreq_r.analyze_folder("texts", "recipe.json", output="python-results")
```

Python uses only its standard library and invokes the installed R CLI. R
and R’s `jsonlite` are required. The returned dictionary is the CLI’s
JSON: tables contain `table_schema`, `types` and column arrays under
`data`. Typed vectors retain empty arrays, missing values and binary64
numbers.

The separate Python/Web UI package named `ldfreq` uses its own analysis
engine and aggregate-only export schema. Its exports omit source text,
filenames and token-level data and round finite numbers to 12 decimal
places. Its ASCII word tokenizer also differs from the R tokenizers.
These records therefore cannot be treated as interchangeable with the R
recipe schema. `ldfreq_r` leaves that Python package’s imports and
behavior intact. For the Web UI schema, use the Web UI’s JSON exporter.
A native folder CLI and `ldfreq.cli.analyze_folder()` are developed in
that separate Python project; they require a distribution of that
project containing `ldfreq.cli` and are not installed by this R package.
That workflow uses the UI analysis service and JSON exporter, with the
same aggregate-only retention policy; its settings must match the UI
run.
