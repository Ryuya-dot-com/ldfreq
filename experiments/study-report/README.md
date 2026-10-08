# From saved learner results to a study report

This example asks whether the reporting guide preserves real documents,
writer/task identities, original results and diagnostic information through a
metadata join, descriptive summary and saved-file replay. It reuses the
[executed PELIC length example](../learner-length/README.md); it does not rerun
tokenization or metric calculations, or add a new corpus sample.

## Run with your existing PELIC cache

Use ldfreq 0.3.0.9003 or later and a checkout of this repository. `digest` is
already a package dependency. If you have not run the PELIC example, follow
its explicit acquisition instructions and access terms first. The reporting
script does not download anything and does not run during installation or CI.

```sh
Rscript --vanilla experiments/study-report/pelic.R . /path/to/pelic-cache /path/to/local-report
Rscript --vanilla experiments/study-report/pelic.R . --replay /path/to/local-report
```

Keep the output **outside the repository**. `study.rds` contains original
corpus text and tokens; `document-results.csv` contains original anonymized
document/writer IDs. Keep both local. Only aggregate statistics and methods
text are published here. Corpus access terms are described in the existing
PELIC example; this does not bundle or relicense its contents.

The script reads the three existing helper definitions from
`vignettes/from-text-to-report.Rmd`: `diagnostic_rows()`,
`join_study_metadata()` and `summarize_study_documents()`. These are guide-local
functions, not exported APIs. It verifies the cached original CSV identities,
then matches the saved response metadata to those original files. It preserves
the saved selection rule rather than selecting essays again based on scores.

| Original PELIC field | Study field | Meaning |
| --- | --- | --- |
| `answer_id` | `document_id` | Original response ID, kept as character |
| `anon_id` | `writer_id` | Original anonymized writer ID |
| `question_id` | `task` | Prompt ID, not an inferred topic |
| `course_id` | `course_id` | Key into the original course table |
| course `level_id` | `course_level` | Recorded course level, not a calibrated ability score |

Each response appears once for each of three metrics. The 48 result rows are
**16 documents, not 48 observations of writers**. Summary keys retain corpus,
task, course level, counting condition, metric, method and parameter values.
The supplied `text_len` is preserved in the original metadata but is not used
as analyzed `N`; `N` is checked against each saved selected token sequence.

## Executed results

All 16 documents by 16 writers belong to prompt 3042 and course level 3.
There is one lowercase surface-form condition, with TTR, MATTR50 and sequential
MTLD (`< 0.72`, no minimum factor length). Each metric retains all 16 values:
zero unavailable, zero withheld and zero unknown-writer documents.

| Metric | Documents / writers | Mean | Sample SD | Median |
| --- | ---: | ---: | ---: | ---: |
| TTR | 16 / 16 | 0.5552 | 0.0664 | 0.5540 |
| MATTR50 | 16 / 16 | 0.7347 | 0.0580 | 0.7429 |
| MTLD | 16 / 16 | 54.2450 | 15.4654 | 51.3867 |

Analyzed length is 70–314 tokens. No MTLD direction is tail-only; the
forward/reverse gap is 8.54% at the median and 47.08% at the maximum. Those are
the same diagnostics as in the earlier calculation. They describe order
sensitivity, not confidence intervals or reliability. No diagnostic flag
automatically excludes a document. No vocabulary-list coverage is added.

The numeric files under `results/` retain full precision and the group keys.
These are document-weighted descriptive statistics for one small selected
sample. Since there is one essay per writer, the example does not exercise
repeated-writer inference or support group/level comparisons. Missing and
withheld values are covered by the separate authored guide checks, not by
this all-available sample. This integration check does not establish metric
validity or novice usability.

## Inspect, report and reopen

```r
study <- readRDS("/path/to/local-report/study.rds")
study$study$summary[c("metric_id", "n_documents", "n_writers_known",
  "n_reported", "n_unavailable", "n_withheld", "mean", "sd", "median")]
study$study$diagnostic_summary
cat(study$study$methods, sep = "\n\n")

# Preserve character IDs and all-missing character columns when reading CSV.
flat <- read.csv("/path/to/local-report/document-results.csv",
  colClasses = vapply(study$study$table, class, character(1)),
  na.strings = "<MISSING>", encoding = "UTF-8")
stopifnot(isTRUE(all.equal(flat, study$study$table, tolerance = 1e-14)))
```

The generated [methods text](results/methods.txt) reports the actual sample
selection, preprocessing, formulas, reporting policy and software versions.
The saved metric calculations used **0.3.0.9002**; reporting used
**0.3.0.9003**. Reusing a calculation does not relabel it with the currently
installed version. Adapt this text only after replacing the corresponding
study inputs and settings; do not copy the PELIC sample description for your
own study.

The `--replay` command starts in a fresh R session, checks the guide identity,
re-extracts original diagnostics and rebuilds the joined table and summaries.
It also checks the CSV and methods text. The complete original analysis
object is preserved unchanged. This verifies reporting replay, not an
independent reimplementation of the metric formulas. Keep this repository
revision and your R environment together with the local RDS.

For your own study, use the
[file-to-report guide](https://ryuya-dot-com.github.io/ldfreq/articles/from-text-to-report.html#study-metadata):
replace its input directory/CSV and one-row-per-document metadata, declare
counting settings, then run the join and summary steps. `pelic.R` deliberately
checks this specific saved sample; do not remove its checks to turn it into a
general corpus importer. The existing guide supports repeated writers,
unknown labels and unavailable results without a new package API.
