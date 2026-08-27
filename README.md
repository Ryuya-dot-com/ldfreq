# ldfreq

`ldfreq` provides explicitly versioned lexical-diversity and reference-frequency
profiles for R. The core computes twelve independently specified metrics from
ordered tokens. Separate adapters make raw-text tokenization,
lemma/flemma/POS annotations, lexical-unit selection, New JACET 8000 level profiles,
TUBELEX coverage, and exact term/content-word overlap visible rather than hiding
those decisions inside a score.

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
- deterministic expected-TTR D
- Yule K and Yule I

`expected_ttr_d` fits a D curve to exact finite-population expected TTR values.
It is deterministic, uses no random sampling or arbitrary D cap, and is not a
claim of CLAN VOCD compatibility.

## Installation

Install the current GitHub version with `pak`:

```r
pak::pak("Ryuya-dot-com/ldfreq")
```

## Basic use

### Pre-tokenized input

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

For the deterministic expected-TTR D fit, the default curve uses sample sizes
35 through 50. Short inputs are reported explicitly rather than resizing that
range:

```r
lexdiv_metrics(
  rep(c("a", "b", "a", "c"), 20),
  metrics = "expected_ttr_d"
)
```

Use `lexdiv_methods()` to see plain-language names, short definitions, score
direction, scale, exact method IDs, parameters, and advisory token floors:

```r
lexdiv_methods()[, c("metric_id", "label", "definition", "direction", "scale")]
```

### Raw text and annotations

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
  backend_version = "1",
  upos_backend_id = "documented-upos-pipeline",
  upos_backend_version = "1"
)

lexdiv_metrics_text(
  annotated,
  unit = "lemma",
  word_inclusion = "content",
  metrics = "ttr"
)
```

Whenever any UPOS tag is present, `upos_backend_id` and
`upos_backend_version` must be supplied explicitly. They are never inferred
from the lemma backend, even when one documented pipeline produced both
layers. The identifiers are returned provenance, so use path-free,
non-sensitive labels and do not put secrets or private hashes in them.

The stricter preprocessing contract `0.1.1` does not automatically migrate a
`lexdiv_tokenization` saved under `0.1.0`. Re-tokenize the original text and
reapply current annotations and explicit backend IDs.

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
used through the explicit flemma adapter. The list is not bundled or downloaded.
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

The flemma adapter and parser identities are fixed by `ldfreq`.
`resource_version` and, when a non-empty override table is used,
`override_version` are caller-declared labels rather than inferred content
identities.
They are disclosed in provenance and overlap comparability output. Use
path-free, non-sensitive labels; do not place credentials, private hashes, or
machine-specific information in them. File names and content hashes are not
included in flemma provenance or overlap results.

The unmodified AntBNC list is an approximation, not an end-to-end NWLC
compatibility claim. NWLC documents manually aligning AntBNC families to the
selected word list; `ldfreq` therefore supports explicit overrides and reports
New JACET headword conflicts rather than concealing them.

### Formula variants

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

### Exact term and content-word overlap

`lexdiv_term_overlap()` compares two explicit vectors as sets of distinct,
exact terms. `lexdiv_content_overlap()` first selects the existing Universal
POS content set (`ADJ`, `ADV`, `NOUN`, `PROPN`, `VERB`) from two annotated
tokenizations. It does not infer POS tags or lemmas.

```r
reference <- lexdiv_lemmatize(
  lexdiv_tokenize("Cats and birds ran."),
  lemmas = c("cat", "and", "bird", "run"),
  upos = c("NOUN", "CCONJ", "NOUN", "VERB"),
  backend_id = "documented-analysis-pipeline",
  backend_version = "1",
  upos_backend_id = "documented-upos-pipeline",
  upos_backend_version = "1"
)

overlap <- lexdiv_content_overlap(
  annotated,
  reference,
  unit = "lemma",
  details = "terms",
  document_ids = c("essay", "reference")
)
overlap$summary[, c(
  "measure_id", "value", "numerator", "denominator", "status"
)]
overlap$coverage
overlap$shared_terms
```

The result keeps Jaccard, Dice, A-covered-by-B, B-covered-by-A, and the overlap
coefficient as different method IDs because their denominators are not
interchangeable. Empty denominator and annotation-exclusion rules are explicit;
read `coverage` beside the values. Exact shared terms are retained only when
`details = "terms"`; the result provenance and print method disclose that
lexical strings are present. Comparability is conditional on `unit`. Surface
overlap compares tokenizer settings and the UPOS backend; lemma overlap also
compares the lemma method/backend. Flemma overlap instead compares the fixed
flemma adapter/parser and caller-declared resource/override settings, and
intentionally ignores the lemma backend because flemmatization consumes surface
forms. Resource-version labels must be present and equal. If neither side used
overrides, that setting is comparable; otherwise both sides must declare the
same `override_version`. Missing or different labels are unverifiable or
mismatched--the package does not infer content identity from file bytes. The
four-column `comparability` table (`component`, `value_a`, `value_b`, `matches`)
discloses these labels, so they must contain no paths, secrets, or private
hashes. Use
`mismatch = "warn"` or `"allow"` only as an explicit analysis decision. These
are lexical-sharing measures, not plagiarism, semantic-similarity, coherence,
proficiency, or writing-quality detectors.

### Reference-frequency and lexical-level profiles

TUBELEX values are returned as corpus-relative frequency/prevalence
measurements with adjacent coverage, not as a universal sophistication score.

```r
frequency <- tubelex_profile(tokenization)
frequency$summary
frequency$coverage
frequency$lookup
```

`count`, `videos`, and `channels` are raw resource counts. `zipf` is a
smoothed base-10 per-billion token score; `video_prevalence` and
`channel_prevalence` are smoothed base-10 log proportions. Negative prevalence
values are therefore expected, and values closer to zero indicate wider
prevalence. Exact formulas and denominators are documented in
`?tubelex_profile` and returned in
`frequency$provenance$formula_parameters`.

New JACET 8000 level profiles use a caller-supplied list. `ldfreq` does not
bundle, reproduce, or download that JACET resource. Exact level proportions use
all eligible terms as their denominator, so the Level 8 cumulative rate is the
observed list coverage and off-list terms remain visible.
The official workbook is linked from the
[Ishikawa Laboratory vocabulary page](https://language.sakura.ne.jp/s/voc.html).

```r
level_profile <- nj8_profile(
  annotated,
  "/path/to/j8_2016.xlsx",
  unit = "lemma"
)
level_profile$summary
level_profile$coverage

plot(level_profile)                    # token proportions + cumulative curve
plot(level_profile, weighting = "type")
```

For a corpus, `nj8_profile_batch()` accepts an explicitly named list
or an ID/list-column data frame. It validates and hashes the external list once,
preserves document order, and returns document-major summary, lookup, coverage,
conflict, exclusion, and preprocessing-provenance tables.

```r
level_batch <- nj8_profile_batch(
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

### Multiple documents and explicit parameter plans

For multiple documents, use an explicitly named list:

```r
documents <- list(
  document_a = c("one", "two", "one"),
  document_b = c("alpha", "beta", "gamma", "delta")
)

lexdiv_metrics_batch(documents, metrics = c("ttr", "hdd"))
```

Tidy one-token-per-row tables and `quanteda` tokens objects can be converted to
the same explicit named-list boundary:

```r
tidy_tokens <- data.frame(
  document_id = c("a", "a", "b", "b"),
  token = c("one", "two", "three", "three")
)
documents <- lexdiv_as_documents(tidy_tokens)
long <- lexdiv_metrics_batch(documents, metrics = c("ttr", "maas"))
wide <- lexdiv_widen(long, values_from = "value")
plot(long, metric_id = "ttr")
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
exact content-word overlap, plus coverage-aware TUBELEX and New JACET 8000
level-profile use.

See [`LIFECYCLE.md`](LIFECYCLE.md)
for the method, schema, deprecation, and future-surface rules defined for the
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
  "lexical-overlap-contract.json",
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
| `expected_ttr_d` | > 0; no finite upper bound | higher |
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
versioned `below_quality_floor` field.

`below_quality_floor` and `lexdiv_screen()` are advisory token-count evidence
screens. Here, `quality` is a field name retained for compatibility; it does not mean writing quality,
measurement validity, or reliability.
They do not change values, parameters, status, or document membership. Passing a
screen does not establish validity or reliability; failing one does not erase an
otherwise computable value. Always inspect `status`, `missing_reason`, `N`, `V`,
method identity, and requested/effective parameters together.

## Offline installed-package smoke test

After installation, the bundled smoke script exercises single-document, batch,
profile, profile-batch, term/content-word overlap, level-profile, and screen
workflows without network access or an external runtime:

```r
library(ldfreq)
smoke_path <- system.file("examples", "offline-smoke.R", package = "ldfreq")
stopifnot(nzchar(smoke_path))
source(smoke_path, local = TRUE)
```

## Scope

The package contains no learner corpus, raw subtitle text, source document
identifier, Python or Java runtime, or runtime network-dependent calculation.
It also contains no New JACET 8000 word-list payload; its exported adapter
requires an explicit caller-supplied data frame, local CSV, or local XLSX and never
downloads a fallback.
It contains the slim TUBELEX-EN Treebank aggregate at commit `7cb5fb36`. Its
exact manifest, 2.55 MB gzip artifact, canonical-content hash, build provenance,
BSD 3-Clause notice, and COPYRIGHTS entry are installed together. The
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
installed resource manifest, notice, and provenance allow the bundled resource
and its package boundary to be audited independently.

The installed CC0 cross-language fixture checks parsed semantic agreement with
the Python implementation for formulas that share exact method IDs. It also
records the strict-`<` R MTLD and `<=` Python MTLD as distinct variants; fixture
file-byte or hash equality is neither required nor asserted.

## License

The R source code is licensed under the MIT License. The installed TUBELEX
aggregate remains BSD-3-Clause material under its component-level NOTICE and
COPYRIGHTS entry; its inclusion in the package does not relicense it as MIT.
