word_parts_fixture <- function() {
  e <- new.env(parent = baseenv())
  for (file in c("word-parts.R", "word-parts-demo.R"))
    sys.source(system.file("examples", file, package = "ldfreq", mustWork = TRUE), e)
  list(run = e$word_parts_profile, x = e$word_parts_example)
}

test_that("part counts retain independent linguistic dimensions and denominators", {
  f <- word_parts_fixture(); x <- f$x$profile; d <- x$documents
  expect_equal(d$selected_tokens, c(5, 3, 0))
  expect_equal(d$root_occurrences, c(5, NA, 0))
  expect_equal(d$affix_occurrences, c(7, NA, 0))
  expect_equal(d$root_types, c(4, NA, 0))
  expect_equal(d$affix_types, c(6, NA, 0))
  expect_equal(d$affixes_per_token, c(7/5, NA, NA))
  expect_equal(d$affixed_token_proportion, c(1, NA, NA))
  expect_equal(d$complete_coverage, c(1, 0, NA))
  expect_identical(d$status, c("complete", "incomplete", "empty"))
  o <- x$occurrences
  expect_equal(o$observed_derivation_occurrences[1:5], c(1, 0, 1, 1, 2))
  expect_equal(o$observed_inflection_occurrences[1:5], c(1, 1, 0, 0, 0))
  expect_equal(o$observed_prefix_occurrences[1:5], c(0, 0, 1, 1, 1))
  expect_equal(o$observed_suffix_occurrences[1:5], c(2, 1, 0, 0, 1))
  expect_identical(o$status[7:10], c("ambiguous", "unanalysed", "unlisted", "excluded"))
  expect_true(all(is.na(o$observed_root_occurrences[7:10])))
  expect_equal(nrow(x$candidates[x$candidates$document_id == "uncertain", ]), 3)
  expect_false(any(x$part_occurrences$document_id == "uncertain"))
  expect_equal(x$frequency$observed_occurrences[x$frequency$part_id == "MIT_MISS"], 2)
  expect_identical(x$part_occurrences$realization[x$part_occurrences$part_id == "MIT_MISS"], c("mit", "miss"))
  expect_equal(f$x$alternative$documents$affix_occurrences, c(6, NA, 0))
  expect_equal(f$x$alternative$documents$root_types, c(5, NA, 0))
  expect_identical(f$x$alternative$inputs$annotations, x$inputs$annotations)
  expect_equal(x$summary$complete_coverage, 5/8)
  expect_true(is.na(x$summary$affix_occurrences))
  expect_equal(x$summary$observed_affix_occurrences, 7)
  expect_identical(o$pre[1], "")
  expect_identical(o$keyword, x$inputs$annotations$tokens$surface)
})

test_that("partial, unknown selection, POS and empty references are explicit", {
  f <- word_parts_fixture(); input <- f$x$profile$inputs
  input$analyses$completeness[1] <- "partial"
  x <- do.call(f$run, input)
  expect_equal(x$documents$partial_tokens, c(1, 0, 0))
  expect_equal(x$documents$complete_coverage[1], 4/5)
  expect_equal(x$documents$observed_affix_occurrences[1], 7)
  expect_true(is.na(x$documents$affix_occurrences[1]))
  input <- f$x$profile$inputs
  input$analyses$upos <- c("NOUN", "ADJ", "VERB", "VERB", "NOUN", "NOUN", "VERB", "VERB")
  x <- do.call(f$run, input)
  expect_identical(x$occurrences$status[7], "complete")
  tok <- input$annotations$tokens; tok$upos[1] <- NA_character_
  seg <- input$annotations$segments[c("document_id", "segment_id", "text")]
  input$annotations <- lexdiv_import_annotations(tok, seg, input$annotations$provenance$annotation)
  x <- do.call(f$run, input)
  expect_identical(x$occurrences$status[1], "unknown_selection")
  expect_true(is.na(x$documents$selected_tokens[1]))
  expect_true(is.na(x$documents$complete_coverage[1]))
  expect_equal(x$documents$conditional_complete_coverage[1], 1)
  input$exclude_pos <- character()
  expect_identical(do.call(f$run, input)$occurrences$status[1], "missing_pos")
  input <- f$x$profile$inputs
  input$analyses <- input$analyses[FALSE, ]; input$parts <- input$parts[FALSE, ]
  x <- do.call(f$run, input)
  expect_equal(nrow(x$frequency), 0)
  expect_equal(x$documents$unlisted_tokens, c(5, 3, 0))
  expect_equal(x$documents$observed_root_occurrences, c(0, 0, 0))
})

test_that("invalid morphology tables and excessive expansions are rejected", {
  f <- word_parts_fixture(); original <- f$x$profile$inputs
  run <- function(input) do.call(f$run, input)
  i <- original; i$annotations$tokens$surface[1] <- "teacher"
  expect_error(run(i), "source|Source|align|surface|token|text")
  i <- original; i$analyses$analysis_id[2] <- "01"
  expect_error(run(i), "unique")
  i <- original; i$parts$analysis_id[1] <- "absent"
  expect_error(run(i), "unknown analysis_id")
  i <- original; i$parts$part_index[2] <- 1
  expect_error(run(i), "consecutive")
  i <- original; i$parts$process[1] <- "inflection"
  expect_error(run(i), "Roots")
  i <- original; i$parts$boundness[2] <- "free"
  expect_error(run(i), "bound")
  i <- original; i$parts$part_id[5] <- "ER_AGENT"
  expect_error(run(i), "conflicting definitions")
  i <- original; i$parts$process[2] <- "unknown"
  expect_error(run(i), "Complete analyses")
  i$analyses$completeness[1] <- "partial"
  expect_equal(run(i)$documents$partial_tokens[1], 1)
  i <- original; i$analyses$completeness[1] <- "unanalysed"
  expect_error(run(i), "cannot assert parts")
  i <- original; i$parts$surface <- i$parts$canonical
  expect_error(run(i), "reserved")
  i <- original; i$resource$analysis_scope <- " "
  expect_error(run(i), "nonblank")
  for (v in c(NA, -1, 1.5, Inf, .Machine$integer.max + 1)) {
    i <- original; i$max_rows <- v
    expect_error(run(i), "whole number")
  }
  # Every input fits, but repeated occurrences make the part join exceed its cap.
  i <- original; i$analyses <- i$analyses[1, ]; i$parts <- i$parts[1:3, ]
  seg <- data.frame(document_id = "d", segment_id = "s", text = paste(rep("teachers", 6), collapse = " "))
  tok <- data.frame(document_id = "d", segment_id = "s", token_index = 1:6, surface = "teachers")
  i$annotations <- lexdiv_import_annotations(tok, seg, i$annotations$provenance$annotation)
  i$exclude_pos <- character(); i$max_rows <- 10
  expect_error(run(i), "Part expansion")
  i$analyses <- i$analyses[rep(1, 2), ]; i$analyses$analysis_id <- c("01", "other")
  i$parts <- rbind(i$parts, transform(i$parts, analysis_id = "other"))
  expect_error(run(i), "Candidate expansion")
})

test_that("saved inputs replay with IDs intact and no model or quanteda", {
  f <- word_parts_fixture(); x <- f$x$profile
  p <- tempfile(); on.exit(unlink(p))
  saveRDS(x, p)
  expect_identical(do.call(f$run, readRDS(p)$inputs), x)
  write.csv(x$inputs$analyses, p, row.names = FALSE, na = "")
  restored <- read.csv(p, colClasses = "character", na.strings = "", check.names = FALSE)
  expect_identical(restored, x$inputs$analyses)
  i <- x$inputs; i$context_chars <- 0L
  o <- do.call(f$run, i)$occurrences
  expect_true(all(o$pre == "" & o$post == ""))
  i <- x$inputs
  # Delimiters, leading zeros and literal NA are identifiers, not missing values.
  i$analyses$analysis_id[1] <- "NA:01|x"; i$parts$analysis_id[i$parts$analysis_id == "01"] <- "NA:01|x"
  expect_identical(do.call(f$run, i)$occurrences$analysis_id[1], "NA:01|x")
})

test_that("a wholly empty source and a declared uninflected root have different denominators", {
  f <- word_parts_fixture(); i <- f$x$profile$inputs
  tok <- i$annotations$tokens[FALSE, ]
  seg <- data.frame(document_id = "empty", segment_id = "s", text = "")
  i$annotations <- lexdiv_import_annotations(tok, seg, i$annotations$provenance$annotation)
  x <- do.call(f$run, i)
  expect_equal(nrow(x$occurrences), 0)
  expect_equal(nrow(x$frequency), 0)
  expect_equal(x$documents$affix_occurrences, 0)
  expect_true(is.na(x$documents$affixes_per_token))
  expect_identical(x$occurrences$status, character())
  i <- f$x$profile$inputs
  i$analyses <- i$analyses[6, ]; i$parts <- i$parts[i$parts$analysis_id == "b1", ]
  seg$text <- "bank"; tok <- data.frame(document_id = "empty", segment_id = "s", token_index = 1L,
    surface = "bank", upos = "NOUN")
  i$annotations <- lexdiv_import_annotations(tok, seg, i$annotations$provenance$annotation)
  x <- do.call(f$run, i)
  expect_equal(x$summary$root_occurrences, 1)
  expect_equal(x$summary$affixes_per_token, 0)
  expect_equal(x$summary$affixed_token_proportion, 0)
})

test_that("the optional reader preserves unsupported and absent entries", {
  skip_if_not_installed("readxl")
  e <- new.env(parent = baseenv())
  sys.source(system.file("examples", "morpholex-word-parts.R", package = "ldfreq", mustWork = TRUE), e)
  # Authored workbook rows: exercise syntax and declared-count checks without
  # including any third-party spreadsheet or requiring a workbook writer.
  rows <- data.frame(ELP_ItemID = c("01", "NA", "03", "04", "05"),
    Word = c("cats", "cats", "bad", "wrong", "rootless"), Nmorph = c("1", "2", "1", "3", "1"),
    PRS_signature = c("0,1,0", "0,1,1", "0,1,0", "0,1,1", "1,0,0"),
    MorphoLexSegm = c("{(cat)}", "{(cat)}>s>", "}(bad){", "{(wrong)}>ly>", "<un<"),
    ROOT1_Freq_HAL = "12")
  testthat::local_mocked_bindings(read_excel = function(...) rows, .package = "readxl")
  p <- tempfile(); on.exit(unlink(p)); writeLines("authored workbook stand-in", p)
  x <- e$read_morpholex_parts(p, "0-1-0", c(rows$Word, "absent"))
  expect_identical(x$analyses$analysis_id[1:2], c("01", "NA"))
  expect_identical(x$analyses$completeness, c("complete", "complete", rep("unanalysed", 3)))
  expect_identical(x$unlisted_words, "absent")
  expect_equal(nrow(x$parts), 3)
  expect_true(all(x$parts$boundness[x$parts$role == "root"] == "unknown"))
  expect_identical(x$source_rows[[1]]$ROOT1_Freq_HAL, rows$ROOT1_Freq_HAL)
  expect_match(x$resource$analysis_scope, "inflection excluded")
  expect_error(e$read_morpholex_parts(p, rep("0-1-0", 2), "cats"), "unique PRS")
  x <- e$read_morpholex_parts(p, "0-1-0", "absent")
  expect_equal(nrow(x$analyses), 0)
  expect_equal(nrow(x$parts), 0)
})

test_that("Unicode contexts and repeated compound roots preserve original occurrences", {
  f <- word_parts_fixture(); i <- f$x$profile$inputs
  seg <- data.frame(document_id = "d:|01", segment_id = "s:|NA", text = "\U0001f600 caf\u00e9-caf\u00e9 caf\u00e9-caf\u00e9")
  tok <- data.frame(document_id = "d:|01", segment_id = "s:|NA", token_index = 1:3,
    surface = c("\U0001f600", "caf\u00e9-caf\u00e9", "caf\u00e9-caf\u00e9"), upos = c("SYM", "NOUN", "NOUN"))
  i$annotations <- lexdiv_import_annotations(tok, seg, i$annotations$provenance$annotation)
  i$analyses <- data.frame(analysis_id = "01", form = "caf\u00e9-caf\u00e9", completeness = "complete")
  i$parts <- i$parts[c(1, 1), ]; i$parts$part_index <- 1:2
  i$parts$canonical <- i$parts$realization <- rep("caf\u00e9", 2)
  i$exclude_pos <- "SYM"; i$context_chars <- 2L
  x <- do.call(f$run, i)
  expect_equal(x$documents$root_occurrences, 4)
  expect_equal(x$documents$root_types, 1)
  expect_equal(x$frequency$observed_occurrences, 4)
  expect_equal(x$documents$affix_occurrences, 0)
  expect_identical(x$occurrences$pre[2], "\U0001f600 ")
  expect_identical(x$occurrences$start, c(1L, 3L, 13L))
  expect_identical(x$inputs$parts$realization, rep("caf\u00e9", 2))
  # Extra realization metadata is retained, NOT validated as literal source spans.
})
