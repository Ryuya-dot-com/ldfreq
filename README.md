# ldfreq

`ldfreq` provides explicitly versioned lexical-diversity and reference-frequency
profiles for R. The core computes eleven independently specified metrics from
ordered tokens. Separate adapters make raw-text tokenization,
lemma/flemma/POS annotations, lexical-unit selection, New JACET 8000 level profiles,
and TUBELEX coverage visible rather than hiding those decisions inside a score.

## What it computes

The core metrics, preprocessing adapters, formula variants, and resource
profiles have separate versioned contracts. This makes it possible to identify
which tokenization, lexical unit, formula, and reference resource produced a
result.

The implemented metric set is:

- TTR, RTTR/Guiraud, and CTTR
- Herdan C and Maas a-squared
- MSTTR and MATTR
- MTLD
- HD-D
- Yule K and Yule I

The separately defined `expected_ttr_d` method is not part of the version 0.1.0
public metric set.

## Installation

Install the published v0.1.0 release. This command first installs `pak` from
CRAN if needed, then installs the version-pinned GitHub release:

```r
install.packages("pak") # once, if it is not already installed
pak::pak("Ryuya-dot-com/ldfreq@v0.1.0")
```

If `pak` cannot use your GitHub credentials, base R can install the same
published source archive. Install the two required dependencies first because
`repos = NULL` does not resolve them automatically:

```r
install.packages(c("digest", "stringi"))
install.packages(
  "https://github.com/Ryuya-dot-com/ldfreq/releases/download/v0.1.0/ldfreq_0.1.0.tar.gz",
  repos = NULL,
  type = "source"
)
```

The changing development version is available with
`pak::pak("Ryuya-dot-com/ldfreq")`. Use it only when you intend to test
unreleased changes.

## Choose your starting point

| Your input | Start with |
|---|---|
| One ordinary prose string | `lexdiv_metrics_text()` |
| One pre-tokenized character vector | `lexdiv_metrics()` |
| Several ordinary prose strings | `lapply(texts, lexdiv_metrics_text, ...)` |
| A folder of `.txt` files | `lexdiv_read_texts()` followed by `lapply()` |
| An Excel/data-frame essay table | Read/reshape explicitly, then use `lexdiv_text_corpus()` |
| Several pre-tokenized documents | `lexdiv_metrics_batch()` |
| A TUBELEX frequency profile | Tokenize first, then use `tubelex_frequency_profile()` |
| A New JACET 8000 level profile | Supply your local list to `new_jacet8000_profile()` |

## 60-second quick start

The core accepts only explicit tokens and performs no hidden case
conversion, Unicode normalization, token deletion, or lemmatization.

Here, a **token** is one word occurrence. In the core metrics, a **type** is one
distinct, exactly equal token string supplied to the core. In a resource
profile, a type is one distinct effective lookup term after that profile's
recorded normalization. A **lemma** is an annotation-provided base form; an
AntBNC **flemma** is a word-family grouping that does not preserve
part-of-speech distinctions. **Coverage** reports how many eligible tokens or
types received an annotation or reference-resource match. It is not a
proficiency score.

```r
library(ldfreq)

tokens <- c("the", "cat", "saw", "the", "other", "cat")

lexdiv_metrics(tokens, metrics = c("ttr", "rttr", "yule_k"))
```

Use `lexdiv_methods()` to see plain-language names, short definitions, score
direction, scale, exact method IDs, parameters, and advisory token floors:

```r
lexdiv_methods()[, c("metric_id", "label", "definition", "direction", "scale")]
```

For raw text, call `lexdiv_metrics_text()` directly. Its output retains
normalization/case settings and text hashes; the core result schema is
unchanged.

```r
lexdiv_metrics_text(
  "Cats and cat ran run.",
  normalization = "NFC",
  case = "preserve",
  metrics = "ttr"
)
```

These two calls are enough for an initial token-vector or raw-text analysis.
The sections below add inspection, annotation, reference resources, and
multi-document handling.

## Detailed workflows

### Inspecting and annotating tokens

Call `lexdiv_tokenize()` separately when you want to inspect or annotate the
tokens first:

```r
tokenization <- lexdiv_tokenize(
  "Cats and cat ran run.",
  normalization = "NFC",
  case = "preserve"
)

tokenization
```

Lemma analyses require an identified annotation backend. Caller-supplied
annotations can come from any documented workflow; missing annotations are
excluded and quantified rather than silently replaced.

```r
annotated <- lexdiv_lemmatize(
  tokenization,
  lemmas = c("cat", "and", "cat", "run", "run"),
  upos = c("NOUN", "CCONJ", "NOUN", "VERB", "VERB"),
  backend_id = "documented-analysis-pipeline",
  backend_version = "1"
)

lexdiv_metrics_text(
  annotated,
  unit = "lemma",
  word_inclusion = "content",
  metrics = "ttr"
)
```

For a quick English lemma baseline, the optional `textstem` package can supply
lemmas while `ldfreq` records its installed version. It does not supply UPOS
tags: `word_inclusion = "content"` therefore still requires caller-supplied
UPOS annotations.

```r
install.packages("textstem") # once, if it is not already installed

automatic_lemmas <- lexdiv_lemmatize(
  lexdiv_tokenize("The cats were running and studies.", case = "lower"),
  method = "textstem"
)
automatic_lemmas$tokens[, c("surface", "lemma")]
lexdiv_metrics_text(automatic_lemmas, unit = "lemma", metrics = "ttr")
```

For NWLC-oriented sensitivity analysis, a legitimately obtained local
[AntBNC Lemma List](https://www.laurenceanthony.net/software/antconc/) can be
used as an explicit flemma backend. The list is not bundled or downloaded.
Unknown forms remain visible through identity fallback, and every token records
whether AntBNC, an override, or fallback supplied its flemma.

```r
flemmas <- lexdiv_flemmatize(
  tokenization,
  "/path/to/antbnc_lemmas_ver_004.txt",
  resource_version = "004"
)

lexdiv_metrics_text(flemmas, unit = "flemma", metrics = "ttr")
```

The unmodified AntBNC list is an approximation, not an end-to-end NWLC
compatibility claim. NWLC documents manually aligning AntBNC families to the
selected word list; `ldfreq` therefore supports explicit overrides and reports
New JACET headword conflicts rather than concealing them.

### Formula-variant sensitivity

Maas log base/scale and sequential-MTLD aggregation variants are a separate
long-form sensitivity output. Multiple MTLD thresholds can be requested without
renaming them as different constructs.

```r
variants <- lexdiv_variant_metrics(
  rep(annotated$tokens$lemma, 20),
  mtld_thresholds = c(0.72, 0.92)
)
variants[, c("family", "method_id", "reference_label", "value", "status")]
```

Rows marked as TAALED-relevant comparators cover only documented formula,
factorization, and aggregation choices. They do not claim official equivalence
of preprocessing, missingness, or the licensed Python implementation.

### TUBELEX frequency profiles

TUBELEX values are returned as corpus-relative frequency/prevalence
measurements with adjacent coverage, not as a universal sophistication score.

```r
frequency <- tubelex_frequency_profile(tokenization)
frequency$summary
frequency$coverage
frequency$lookup
```

`count`, `videos`, and `channels` are raw resource counts. `zipf` is a
smoothed base-10 per-billion token score; `video_prevalence` and
`channel_prevalence` are smoothed base-10 log proportions. Negative prevalence
values are therefore expected, and values closer to zero indicate wider
prevalence. Exact formulas and denominators are documented in
`?tubelex_frequency_profile` and returned in
`frequency$provenance$formula_parameters`.

### New JACET 8000 profiles

New JACET 8000 level profiles use a caller-supplied list. `ldfreq` does not
bundle, reproduce, or download that JACET resource. Exact level proportions use
all eligible terms as their denominator, so the Level 8 cumulative rate is the
observed list coverage and off-list terms remain visible.
The official workbook is linked from the
[Ishikawa Laboratory vocabulary page](https://language.sakura.ne.jp/s/voc.html).

```r
level_profile <- new_jacet8000_profile(
  annotated,
  "/path/to/j8_2016.xlsx",
  unit = "lemma"
)
level_profile$summary
level_profile$coverage

plot(level_profile)                    # token proportions + cumulative curve
plot(level_profile, weighting = "type")
```

For a corpus, `new_jacet8000_profile_batch()` accepts an explicitly named list
or an ID/list-column data frame. It validates and hashes the external list once,
preserves document order, and returns document-major summary, lookup, coverage,
conflict, exclusion, and preprocessing-provenance tables.

```r
level_batch <- new_jacet8000_profile_batch(
  list(
    document_a = annotated,
    document_b = lexdiv_tokenize("A second short document.")
  ),
  "/path/to/j8_2016.xlsx",
  unit = "surface"
)
level_batch$coverage
```

With `unit = "flemma"`, `flemma_conflict = "antbnc"` retains the AntBNC
family, `"wordlist"` gives an exact New JACET surface headword precedence, and
`"error"` stops on the first audited conflict set. The lookup table retains the
chosen resolution and the alternative surface-headword rank and level.

The official `新J8` sheet and `新J8順位`/`代表レマ` columns are detected
automatically. Ranks are mapped to Levels 1--8 with `ceiling(rank / 1000)`.
Local-file and
canonical rank-entry hashes, normalization, surface/lemma/flemma selection, missing
ranks, alias expansion, and normalization collisions remain in provenance or
diagnostics. Provenance retains the source basename but neither stores nor
prints its absolute directory. The list remains outside the package; users are responsible for
obtaining and using their copy under the applicable terms.

### Multiple documents

For multiple **pre-tokenized** documents, use an explicitly named list:

```r
documents <- list(
  document_a = c("one", "two", "one"),
  document_b = c("alpha", "beta", "gamma", "delta")
)

lexdiv_metrics_batch(documents, metrics = c("ttr", "hdd"))
```

Do not pass ordinary prose strings directly to `lexdiv_metrics_batch()`: each
string would be treated as one already-tokenized item. For several raw texts,
apply `lexdiv_metrics_text()` to each named document instead:

```r
texts <- c(
  document_a = "One short document repeats one word.",
  document_b = "Another document uses several different words."
)

raw_documents <- lapply(
  texts,
  lexdiv_metrics_text,
  normalization = "NFC",
  case = "lower",
  metrics = c("ttr", "rttr")
)

# Keep these full objects: each one retains its token audit and preprocessing.
raw_documents$document_a$results
raw_documents$document_a$preprocessing
```

#### Reading a folder of text files

`lexdiv_read_texts()` reads each UTF-8 `.txt` file in a directory as one
document. Files are ordered alphabetically, filename stems become explicit
document IDs, and subfolders are not searched unless `recursive = TRUE`.
Invalid UTF-8, duplicate IDs, unreadable files, embedded NUL bytes, and
configurable per-file or total byte-limit violations stop before analysis.

```r
essay_dir <- file.path("data", "essays")

corpus <- lexdiv_read_texts(essay_dir)
corpus$documents

raw_documents <- lapply(
  corpus$texts,
  lexdiv_metrics_text,
  normalization = "NFC",
  case = "lower",
  metrics = c("ttr", "rttr")
)

names(raw_documents)
raw_documents[[1]]$results
raw_documents[[1]]$preprocessing
```

The returned `lexdiv_text_corpus` contains:

- `texts`: one named scalar string per file, including multiline files;
- `documents`: the document ID, text identity, source basename, byte count,
  and SHA-256 identity;
  and
- `provenance`: discovery choices, byte limits, encoding, and reader-contract
  identity.

Absolute directories are used only while reading and are not retained or
printed. Explicit file vectors and caller-supplied `document_ids` are also
supported; see `?lexdiv_read_texts`.

#### Reading essays from Excel

Workbook layout is dataset-specific, so `ldfreq` does not guess which sheet,
rows, or columns define an essay. Use `readxl` to preserve that choice
explicitly, reshape to one row per essay, and then validate the result with
`lexdiv_text_corpus()`:

```r
essay_sheet <- "Essays"
raw_rows <- readxl::read_excel(
  "data/essays.xlsx",
  sheet = essay_sheet
)

essays <- data.frame(
  document_id = as.character(raw_rows$essay_id),
  text = as.character(raw_rows$essay_text),
  source_sheet = essay_sheet,
  source_row = seq_len(nrow(raw_rows)) + 1L,
  stringsAsFactors = FALSE
)
essays <- essays[!is.na(essays$text), , drop = FALSE]

corpus <- lexdiv_text_corpus(
  essays,
  metadata_cols = c("source_sheet", "source_row")
)
corpus$documents

raw_documents <- lapply(
  corpus$texts,
  lexdiv_metrics_text,
  case = "lower",
  metrics = c("ttr", "rttr")
)
```

If one essay spans several spreadsheet rows, join those rows explicitly before
calling `lexdiv_text_corpus()`—for example with `dplyr::group_by()` and
`summarise(text = paste(paragraph, collapse = "\n"))`. Keep the original
workbook unchanged and record source sheet/row columns in the processed table.

For an ordinary rectangular analysis table, select the columns you need while
leaving the full audited objects in `raw_documents`:

```r
# Optional compact table for analysis across documents.
raw_metric_rows <- do.call(rbind, lapply(names(raw_documents), function(id) {
  rows <- raw_documents[[id]]$results
  data.frame(
    document_id = id,
    metric_id = rows$metric_id,
    value = rows$value,
    status = rows$status,
    N = rows$N,
    V = rows$V,
    stringsAsFactors = FALSE
  )
}))
rownames(raw_metric_rows) <- NULL
raw_metric_rows
```

Parameter variants are represented as explicit specifications rather than
silently changing defaults:

```r
plan <- lexdiv_plan(presets = "length_50_100")
profile <- lexdiv_profile(tokens, plan)
lexdiv_screen(profile)
```

See `vignette("getting-started", package = "ldfreq")` for the result contract,
batch inputs, profiles, and token-length screens. See
`vignette("preprocessing-and-frequency", package = "ldfreq")` for
surface/lemma/flemma sensitivity, the Maas/MTLD variant crosswalk, word inclusion, and
coverage-aware TUBELEX and New JACET 8000 level-profile use.

See the repository
[`LIFECYCLE.md`](https://github.com/Ryuya-dot-com/ldfreq/blob/main/LIFECYCLE.md)
for the method, schema, deprecation, and future-surface rules frozen for the
`0.1.x` line.

## Reproducibility boundary

Every metric row carries ordinary columns identifying the metric contract and
result schema. List-columns preserve requested and effective parameters and
method-specific diagnostics. Attributes are conveniences, not the sole source
of provenance.

Short documents never cause requested window, segment, or sample sizes to be
silently reduced. Non-computable requests return structured status and reason
fields.

Exact formulas, domains, schemas, normalization rules, and resource boundaries
are installed as JSON contracts. They can be located without relying on a
repository checkout:

```r
contract_files <- c(
  "lexical-diversity-contract.json",
  "ldfreq-preprocessing-contract.json",
  "ldfreq-text-corpus-contract.json",
  "ldfreq-text-file-input-contract.json",
  "lexical-diversity-variant-contract.json",
  "lexical-level-profile-contract.json",
  "tubelex-frequency-profile-contract.json"
)
contract_paths <- system.file("spec", contract_files, package = "ldfreq")
stopifnot(all(nzchar(contract_paths)))
basename(contract_paths) # avoids printing machine-specific directories
```

## Interpreting values

Direction and scale are properties of an exact `method_id`, not of a metric name
in the abstract. The v0.1 contract records:

| Metric ID | Contract scale | Conventional within-method score direction |
|---|---:|---|
| `ttr` | [0, 1] | higher |
| `rttr` | >= 0; no finite upper bound | higher |
| `cttr` | >= 0; no finite upper bound | higher |
| `herdan` | [0, 1] | higher |
| `maas` | 0 to 1 / ln(2) (about 1.4427) | lower |
| `msttr` | [0, 1] | higher |
| `mattr` | [0, 1] | higher |
| `mtld` | >= 0; no finite upper bound | higher |
| `hdd` | [0, 1] | higher |
| `yule_k` | [0, 10,000) | lower |
| `yule_i` | >= 0; no finite upper bound | higher |

Use a direction only within the same method, parameters, tokenization,
normalization, sampling design, and meaningfully comparable texts. Raw values
from different metric IDs are not interchangeable because their scales and
length sensitivities differ.

These methods primarily operationalize lexical variety and repetition. They are
indices used within the lexical-diversity research domain, but no single score
represents the full multidimensional construct of lexical diversity.

These measurements describe lexical-distribution properties of the supplied
tokens. They are not direct measures of language proficiency, writing quality,
reader response, or communicative effectiveness. Such interpretations require a
separate validated study design and cannot be inferred from one score or the
frozen `below_quality_floor` field.

`below_quality_floor` and `lexdiv_screen()` are advisory token-count evidence
screens. Here, `quality` is a frozen field name; it does not mean writing quality,
measurement validity, or reliability.
They do not change values, parameters, status, or document membership. Passing a
screen does not establish validity or reliability; failing one does not erase an
otherwise computable value. Always inspect `status`, `missing_reason`, `N`, `V`,
method identity, and requested/effective parameters together.

## Offline installed-package smoke test

After installation, the bundled smoke script exercises single-document, batch,
profile, profile-batch, level-profile, and screen workflows without network
access or an external runtime:

```r
library(ldfreq)
smoke_path <- system.file("examples", "offline-smoke.R", package = "ldfreq")
stopifnot(nzchar(smoke_path))
source(smoke_path, local = TRUE)
```

## Scope

This repository contains no learner corpus, raw subtitle text, source document
identifier, Python or Java runtime, or runtime network-dependent calculation.
It also contains no New JACET 8000 word-list payload; its exported adapter
requires an explicit caller-supplied data frame, local CSV, or local XLSX and never
downloads a fallback.
It contains the slim TUBELEX-EN Treebank aggregate at commit `7cb5fb36`. Its
exact manifest, 2.55 MB gzip artifact, canonical-content hash, build provenance,
BSD 3-Clause notice, and COPYRIGHTS entry are installed together. The new
frequency-profile API does not turn TUBELEX frequency into context-independent
lexical sophistication. No NGSL or Open English WordNet data are included.

A non-exported local-resource loader provides the integrity boundary. It reads
an exact manifest and each declared artifact once, hashes those same bytes
before decoding, rejects unavailable, mismatched, unsupported-version, and
schema-invalid inputs in a fixed order, and never downloads or searches for a
fallback. In addition to project-authored synthetic fixtures, the non-exported
TUBELEX path performs bounded streaming gzip expansion and validates the fixed
515,292-row four-column schema. A public wrapper adds an explicit source-aligned
normalization option while retaining both original and lookup terms. It
preserves order and duplicates, returns token/type coverage diagnostics, and
keeps unmatched measurements missing rather than coercing them to zero. The
installed manifest, notice, provenance, and machine-readable inventory allow
the bundled resource and its package boundary to be audited independently.

## License

The R source code is licensed under the MIT License. The installed TUBELEX
aggregate remains BSD-3-Clause material under its component-level NOTICE and
COPYRIGHTS entry; placement in this repository does not relicense it as MIT.
Any later lexical resource must retain the same separation of license, notice,
and provenance.
