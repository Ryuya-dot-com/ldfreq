test_that("the installed study template checks splits and replays frozen comparisons", {
  skip_if_not_installed("quanteda", "4.5.0")
  skip_if_not(isTRUE(l10n_info()[["UTF-8"]]))
  scripts <- system.file("examples", "contextual-study", package = "ldfreq", mustWork = TRUE)
  folder <- tempfile("study-test-")
  dir.create(folder)
  previous <- setwd(folder)
  run <- function(name) {
    env <- new.env(parent = globalenv())
    invisible(capture.output(sys.source(file.path(scripts, name), envir = env)))
    env
  }
  tryCatch({
    suppressMessages(run("01-prepare.R"))
    expect_error(run("01-prepare.R"), "inputs already exists")
    metadata <- read.csv("inputs/metadata.csv", colClasses = "character")
    broken <- metadata
    broken$group_id[broken$partition == "test"] <- metadata$group_id[1]
    write.csv(broken, "inputs/metadata.csv", row.names = FALSE)
    expect_error(run("02-evaluate.R"), "group occurs in more than one partition")
    expect_false(dir.exists("analysis"))
    broken <- metadata
    broken$document_id[1] <- "not-the-imported-document"
    write.csv(broken, "inputs/metadata.csv", row.names = FALSE)
    expect_error(run("02-evaluate.R"), "Model documents do not match")
    expect_false(dir.exists("analysis"))
    broken <- metadata
    broken$group_id[1] <- ""
    write.csv(broken, "inputs/metadata.csv", row.names = FALSE)
    expect_error(run("02-evaluate.R"), "metadata needs unique documents")
    broken <- metadata
    broken$document_id[1] <- broken$document_id[2]
    write.csv(broken, "inputs/metadata.csv", row.names = FALSE)
    expect_error(run("02-evaluate.R"), "metadata needs unique documents")
    write.csv(metadata, "inputs/metadata.csv", row.names = FALSE)
    # Renaming copied development contexts as test documents is also rejected.
    original_test <- readRDS("inputs/test-model.rds")
    dev <- readRDS("inputs/development-model.rds")
    source <- dev$review$source
    replacement <- metadata$document_id[metadata$partition == "test"]
    original <- metadata$document_id[metadata$partition == "development"]
    source$tokens$document_id <- replacement[match(source$tokens$document_id, original)]
    source$segments$document_id <- replacement[match(source$segments$document_id, original)]
    a <- lexdiv_import_annotations(source$tokens,
      source$segments[c("document_id", "segment_id", "text")], source$provenance$annotation)
    copied_review <- lexdiv_ambiguity_review(a, dev$review$summary$term,
      dev$review$candidates, dev$review$provenance$resource)
    data <- copied_review$occurrences[c("review_id", "occurrence_id", "segment_text",
      "surface", "start", "end")]
    data$status <- "skipped"
    data$reason <- "Authored copied-context test"
    copy <- lexdiv_import_contextual(copied_review, data, dev$provenance$model,
      dev$embeddings[FALSE, , drop = FALSE])
    saveRDS(copy, "inputs/test-model.rds")
    expect_error(run("02-evaluate.R"), "Identical target contexts occur")
    expect_false(dir.exists("analysis"))
    saveRDS(original_test, "inputs/test-model.rds")
    suppressMessages(run("02-evaluate.R"))
    saved_files <- list.files("analysis", full.names = TRUE)
    before <- tools::md5sum(saved_files)
    expect_error(run("02-evaluate.R"), "analysis already exists")
    # Report must work after the mutable preparation inputs are moved away.
    expect_true(file.rename("inputs", "archived-inputs"))
    result <- suppressMessages(run("03-report.R"))$report
    expect_identical(tools::md5sum(saved_files), before)
    expect_identical(result$comparison$method, c("centroid", "frequency"))
    expect_equal(result$comparison$predictions, c(3, 4))
    expect_equal(result$comparison$paired, c(2, 3))
    expect_equal(result$comparison$agreement, c(2, 2))
    expect_equal(result$comparison$agreement_among_paired, c(1, 2/3))
    expect_equal(result$comparison$matches_among_reference_selected, c(2/3, 2/3))
    expect_equal(result$common_comparison$paired, c(2, 2))
    expect_equal(result$common_comparison$agreement, c(2, 1))
    expect_equal(result$common_comparison$coverage_of_all_occurrences, c(0.5, 0.5))
    expect_equal(result$judgments$summary$both_selected, 3)
    expect_equal(result$judgments$summary$agreement, 2)
    expect_equal(table(result$pairs$reference_status)[["unresolved"]], 2)
    expect_setequal(result$pairs$language, c("en", "ja"))
    expect_identical(suppressMessages(run("03-report.R"))$report, result)
    expect_identical(tools::md5sum(saved_files), before)
    # A different run with no query vectors has no common evaluable cases.
    expect_true(file.rename("archived-inputs", "inputs"))
    expect_true(file.rename("analysis", "baseline-analysis"))
    missing <- readRDS("inputs/test-model.rds")
    data <- missing$occurrences[c("review_id", "occurrence_id", "segment_text",
      "surface", "start", "end")]
    data$status <- "skipped"
    data$reason <- "Authored no-query-vectors case"
    missing <- lexdiv_import_contextual(missing$review, data, missing$provenance$model,
      missing$embeddings[FALSE, , drop = FALSE])
    saveRDS(missing, "inputs/test-model.rds")
    suppressMessages(run("02-evaluate.R"))
    empty <- suppressMessages(run("03-report.R"))$report
    expect_equal(nrow(empty$common_occurrences), 0)
    expect_equal(empty$common_comparison$paired, c(0, 0))
    expect_true(all(is.na(empty$common_comparison$agreement_among_paired)))
    expect_equal(empty$comparison$predictions, c(0, 4))
  }, finally = {
    setwd(previous)
    unlink(folder, recursive = TRUE)
  })
})
