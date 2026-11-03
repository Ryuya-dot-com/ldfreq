recipe_test_plan <- function(window = 3) lexdiv_plan(presets = character(),
  specs = list(lexdiv_spec("ttr"), lexdiv_spec("mattr", list(window_length = window))))

test_that("recipes reuse core calculations and round-trip complete records", {
  skip_if_not_installed("jsonlite")
  texts <- c("001" = "A cat and a dog.\n", empty = "", unicode = "Caf\u00e9 cats.")
  recipe <- lexdiv_recipe(recipe_test_plan())
  run <- lexdiv_run_recipe(texts, recipe, metadata = data.frame(
    document_id = rev(names(texts)), writer_id = c("03", NA, "01")))
  original <- lexdiv_metrics_text_batch(texts, plan = recipe_test_plan())
  expect_equal(run$analysis$results$value, original$results$value)
  expect_identical(run$analysis$results, original$results)
  expect_identical(run$analysis$preprocessing, original$preprocessing)
  expect_equal(run$analysis$results$value[1], 4/5)
  file <- tempfile(); on.exit(unlink(file), add = TRUE)
  lexdiv_write(run, file)
  restored <- lexdiv_read(file)
  expect_identical(restored, run)
  expect_error(lexdiv_write(run, file), "already exists")
  expect_identical(lexdiv_methods_text(restored), lexdiv_methods_text(run))
})

test_that("restored records connect to planned observations without dropping missing submissions", {
  skip_if_not_installed("jsonlite")
  plan <- recipe_test_plan()
  texts <- c("001" = "A cat and a dog.", "002" = "Another small example.", "003" = "")
  run <- lexdiv_run_recipe(texts, lexdiv_recipe(plan), condition_id = "primary")
  file <- tempfile(); on.exit(unlink(file), add = TRUE)
  lexdiv_write(run, file)
  restored <- lexdiv_read(file)
  planned <- data.frame(observation_id = paste0("o", 1:4),
    writer_id = c("w1", "w1", "w2", "w2"), task = factor("description"),
    occasion = c(1, 2, 1, 2))
  submissions <- data.frame(observation_id = paste0("o", 1:3), document_id = names(texts))
  study <- lexdiv_study_table(planned, submissions, restored$analysis, plan, "primary")
  direct <- lexdiv_study_table(planned, submissions,
    lexdiv_metrics_text_batch(texts, plan = plan), plan, "primary")
  expect_identical(study, direct)
  expect_equal(nrow(study), 8L)
  expect_identical(study$input_status[study$observation_id == "o3"], rep("empty_text", 2))
  expect_identical(study$input_status[study$observation_id == "o4"], rep("not_submitted", 2))
})

test_that("vector parameters and empty-document sets retain their types", {
  skip_if_not_installed("jsonlite")
  plan <- lexdiv_plan(presets = character(), specs =
    lexdiv_spec("expected_ttr_d", list(sample_sizes = c(2L, 3L, 4L))))
  recipe <- lexdiv_recipe(plan)
  file <- tempfile(); on.exit(unlink(file), add = TRUE)
  lexdiv_write(recipe, file)
  expect_identical(lexdiv_read(file), recipe)
  unlink(file)
  run <- lexdiv_run_recipe(stats::setNames(character(), character()), recipe)
  expect_equal(nrow(run$analysis$results), 0)
  lexdiv_write(run, file)
  expect_identical(lexdiv_read(file), run)
})

test_that("recipe restoration rejects incompatible or unresolved settings", {
  recipe <- lexdiv_recipe(recipe_test_plan())
  changed <- recipe; changed$engine$package_version <- "0.0.0"
  expect_error(lexdiv_run_recipe(c(doc = "Some text."), changed), "requirements differ")
  changed <- recipe; changed$specifications[[2]]$parameters <- list()
  expect_error(lexdiv_run_recipe(c(doc = "Some text."), changed), "fully resolved")
  changed <- recipe; changed$schema_version <- "9"
  expect_error(lexdiv_run_recipe(c(doc = "Some text."), changed), "Unsupported")
  changed <- recipe; changed$preprocessing$unit <- "lemma"
  expect_error(lexdiv_run_recipe(c(doc = "Some text."), changed), "surface")
  changed <- recipe; changed$command <- "never execute this"
  expect_error(lexdiv_run_recipe(c(doc = "Some text."), changed), "unknown fields")
})

test_that("reference acquisition and segmentation changes remain explicit", {
  expect_error(lexdiv_recipe(resources = "tubelex"), "explicit")
  recipe <- lexdiv_recipe(resources = "nj8")
  withr::local_options(ldfreq.resource_dir = tempfile())
  expect_error(lexdiv_run_recipe(c(doc = "Some text."), recipe), "unavailable")
  changed <- recipe; changed$resources[[1]]$version <- "unknown"
  expect_error(lexdiv_run_recipe(c(doc = "Some text."), changed), "catalog")
})

test_that("comparison separates specification differences from length cautions", {
  skip_if_not_installed("jsonlite")
  a <- lexdiv_run_recipe(c(a = "One small example."), lexdiv_recipe(recipe_test_plan()))
  b <- lexdiv_run_recipe(c(b = "One much longer example with more words."), a$recipe)
  same <- lexdiv_compare_analyses(a, b)
  expect_identical(same$measurement, "same")
  expect_identical(same$study_comparability, "not_established")
  expect_true("selected_token_counts" %in% same$differences$field)
  c <- lexdiv_run_recipe(c(a = "One small example."), lexdiv_recipe(recipe_test_plan(4)))
  expect_identical(lexdiv_compare_analyses(a, c)$measurement, "different")
  renamed <- a$recipe
  renamed$specifications[[1]]$request_id <- "another_label"
  d <- lexdiv_run_recipe(c(a = "One small example."), renamed)
  expect_identical(lexdiv_compare_analyses(a, d)$measurement, "same")
  e <- lexdiv_run_recipe(c(a = "One small example."), lexdiv_recipe(recipe_test_plan(), case = "preserve"))
  expect_identical(lexdiv_compare_analyses(a, e)$measurement, "different")
})

test_that("inconsistent saved records cannot produce reassuring reports", {
  skip_if_not_installed("jsonlite")
  a <- lexdiv_run_recipe(c(a = "One small example."), lexdiv_recipe(recipe_test_plan()))
  b <- a; b$analysis$results$N[1] <- 200
  expect_error(lexdiv_compare_analyses(a, b), "counts disagree")
  b <- a; b$documents$text[1] <- "Changed text."
  expect_error(lexdiv_methods_text(b), "Source text")
  b <- a; b$analysis$preprocessing$a$tokenization$case <- "preserve"
  expect_error(lexdiv_methods_text(b), "preprocessing")
  b <- a; b$analysis$results <- b$analysis$results[1, ]
  expect_error(lexdiv_methods_text(b), "Incomplete")
  b <- a; b$analysis$results$effective_parameters[[2]] <- list(window_length = 2)
  expect_error(lexdiv_methods_text(b), "Effective parameters")
  b <- a; b$analysis$results$below_quality_floor <- NULL
  expect_error(lexdiv_compare_analyses(a, b), "saved recipe")
})

test_that("length comparisons preserve shared document identity", {
  skip_if_not_installed("jsonlite")
  recipe <- lexdiv_recipe(recipe_test_plan())
  a <- lexdiv_run_recipe(c(a = "one", b = "one two three"), recipe)
  swapped <- lexdiv_run_recipe(c(a = "one two three", b = "one"), recipe)
  result <- lexdiv_compare_analyses(a, swapped)
  expect_identical(result$measurement, "same")
  expect_false("selected_token_counts" %in% result$differences$field)
  counts <- result$differences[result$differences$field == "shared_document_token_counts", ]
  expect_equal(nrow(counts), 1L)
  expect_identical(counts$severity, "caution")
  expect_identical(jsonlite::fromJSON(counts$left)$document_id, c("a", "b"))
  expect_equal(jsonlite::fromJSON(counts$left)$selected_tokens, c(1, 3))
  expect_equal(jsonlite::fromJSON(counts$right)$selected_tokens, c(3, 1))
  reordered <- lexdiv_run_recipe(c(b = "one two three", a = "one"), recipe)
  expect_equal(nrow(lexdiv_compare_analyses(a, reordered)$differences), 0L)
  renamed <- lexdiv_run_recipe(c(c = "one", d = "one two three"), recipe)
  expect_false("shared_document_token_counts" %in% lexdiv_compare_analyses(a, renamed)$differences$field)
})

test_that("resource adapters preserve profiles, exact identities and coverage", {
  skip_if_not_installed("jsonlite")
  # Only resource acquisition is replaced with authored fixtures. The real
  # batch/profile calculations and the recipe/JSON/report path still execute.
  real_nj8 <- nj8_profile_batch
  local_mocked_bindings(
    lexdiv_resource_info = function(...) data.frame(available = TRUE),
    nj8_profile_batch = function(documents, ...) real_nj8(documents,
      wordlist = data.frame(NJ8 = c(1L, 1001L), Word = c("the", "apple")),
      resource_version = "jacet2016-8000-v1", ...),
    .lexres_load_tubelex = function() list(status = "ok", failure_reason = NA_character_,
      resource_ref = ldfreq:::.lexres_resource_ref(ldfreq:::.lexres_tubelex_expectation()),
      diagnostics = list(fallback_attempted = FALSE, download_attempted = FALSE),
      manifest = list(lookup_unit = "surface-form", normalization_id = "nfkc-trim-root-lower-filtered-source-keys-v1"),
      resource = list(tubelex_en_treebank_slim_csv_gz = list(word = c("apple", "the"),
        count = c(7403, 7448605), videos = c(3027, 103830), channels = c(2563, 60433),
        totals = list(count = 171805865, videos = 105733, channels = 68405)))),
    .package = "ldfreq")
  recipe <- lexdiv_recipe(recipe_test_plan(), resources = c("nj8", "tubelex"),
    tubelex_tokenization_mismatch = "allow")
  a <- lexdiv_run_recipe(c(doc = "The apple missing.", empty = ""), recipe)
  expect_equal(a$profiles$nj8$coverage$token_coverage[1], 2/3)
  expect_equal(a$profiles$tubelex$coverage$token_coverage[1], 2/3)
  file <- tempfile(); on.exit(unlink(file), add = TRUE)
  lexdiv_write(a, file)
  restored <- lexdiv_read(file)
  expect_identical(restored, a)
  prepared <- lexdiv_tokenize_batch(c(doc = "The apple missing.", empty = ""))
  direct_nj8 <- nj8_profile_batch(prepared, unit = "surface")
  direct_tubelex <- tubelex_profile_batch(prepared, tokenization_mismatch = "allow")
  expect_identical(a$profiles$nj8, direct_nj8)
  expect_identical(a$profiles$tubelex, direct_tubelex)
  plot_file <- tempfile(fileext = ".pdf")
  grDevices::pdf(plot_file)
  on.exit({ grDevices::dev.off(); unlink(plot_file) }, add = TRUE)
  for (record in list(a, restored)) {
    expect_identical(nj8_diagnostics(record$profiles$nj8), nj8_diagnostics(direct_nj8))
    expect_identical(tubelex_diagnostics(record$profiles$tubelex), tubelex_diagnostics(direct_tubelex))
    expect_identical(plot(record$profiles$tubelex), plot(direct_tubelex))
  }
  expect_match(paste(lexdiv_methods_text(a), collapse = "\n"), "jacet2016-8000-v1", fixed = TRUE)
  expect_match(paste(lexdiv_methods_text(a), collapse = "\n"), "segmentation mismatch", fixed = TRUE)
  b <- a
  b$profiles$nj8$provenance$resource_canonical_sha256 <- paste(rep("0",64),collapse="")
  expect_identical(lexdiv_compare_analyses(a,b)$measurement, "different")
  b$profiles$nj8$provenance$resource_version <- "different"
  expect_error(lexdiv_methods_text(b), "resource provenance")
  empty <- lexdiv_run_recipe(c(empty = ""), recipe)
  unlink(file)
  lexdiv_write(empty, file)
  expect_identical(lexdiv_read(file), empty)
})

test_that("compact displays keep source text out of the console and return the record", {
  recipe <- lexdiv_recipe(recipe_test_plan())
  run <- lexdiv_run_recipe(c(doc = "Private example sentence.", empty = ""), recipe)
  expect_identical(withVisible(print(recipe))$visible, FALSE)
  expect_identical(capture.output(result <- print(run)), c(
    "<lexdiv_analysis: 2 documents; 4 metric records; 0 resources>",
    paste0("  Available: 2 | Missing: 2 | ldfreq ", run$execution$package_version),
    "  Results: $analysis$results | Resources: $profiles | Settings: $recipe"))
  expect_identical(result, run)
})

test_that("methods paragraphs retain saved versions, exact parameters and references", {
  a <- lexdiv_run_recipe(c(a = "One small example."), lexdiv_recipe(lexdiv_plan(
    presets = character(), specs = list(lexdiv_spec("mtld"), lexdiv_spec("mattr")))))
  a$execution$package_version <- a$recipe$engine$package_version <- "1.0.0"
  english <- paste(lexdiv_methods_text(a), collapse = "\n")
  japanese <- paste(lexdiv_methods_text(a, "ja"), collapse = "\n")
  expect_match(english, "ldfreq 1.0.0", fixed = TRUE)
  expect_match(english, "threshold = 0.72", fixed = TRUE)
  expect_match(english, "window_length = 50", fixed = TRUE)
  expect_match(english, "final-token closure", fixed = TRUE)
  expect_match(english, "10.1080/09296171003643098", fixed = TRUE)
  expect_match(japanese, "0.72", fixed = TRUE)
  expect_false(grepl("0x", japanese, fixed = TRUE))
  exact <- 0.7200000000000001
  precise <- lexdiv_run_recipe(c(a = "A small example."), lexdiv_recipe(lexdiv_plan(
    presets = character(), specs = lexdiv_spec("mtld", list(threshold = exact)))))
  statement <- lexdiv_methods_text(precise)[2]
  decimal <- sub(".*threshold = ([0-9.]+)\\.$", "\\1", statement)
  expect_identical(as.numeric(decimal), exact)
})

test_that("methods output uses saved normalization versions and stable decimal parameters", {
  run <- lexdiv_run_recipe(c(doc = "One small example."), lexdiv_recipe(lexdiv_plan(
    presets = character(), specs = lexdiv_spec("mtld", list(threshold = 0.7200000000000001)))))
  run$recipe$engine$stringi_version <- "saved-stringi"
  run$recipe$engine$icu_version <- "saved-icu"
  baseline <- lapply(c("en", "ja"), function(lang) lexdiv_methods_text(run, lang))
  withr::local_options(OutDec = ",", scipen = -9)
  for (i in seq_along(baseline)) {
    expect_no_warning(actual <- lexdiv_methods_text(run, c("en", "ja")[[i]]))
    expect_identical(actual, baseline[[i]])
    expect_match(actual[[1]], "stringi saved-stringi", fixed = TRUE)
    expect_match(actual[[1]], "ICU saved-icu", fixed = TRUE)
    expect_match(actual[[2]], "threshold = 0.7200000000000001", fixed = TRUE)
  }
  expect_identical(getOption("OutDec"), ",")
})

test_that("CSV preserves document/request rows and unavailable values", {
  skip_if_not_installed("jsonlite")
  a <- lexdiv_run_recipe(c("001" = "One small example.", empty = ""),
    lexdiv_recipe(recipe_test_plan()), condition_id = "primary")
  file <- tempfile(); on.exit(unlink(file), add = TRUE)
  lexdiv_write(a, file, "csv")
  csv <- utils::read.csv(file, colClasses = c(document_id = "character"), na.strings = "")
  expect_equal(nrow(csv), 4)
  expect_identical(csv$document_id, c("001", "001", "empty", "empty"))
  expect_equal(csv$value, a$analysis$results$value)
  expect_true(all(csv$condition_id == "primary"))
  expect_true(all(nzchar(csv$missing_reason[csv$status == "missing"])))
  expect_equal(jsonlite::fromJSON(csv$requested_parameters[2])$window_length, 3)
})

test_that("JSON preserves full binary64 precision and canonical metadata labels", {
  skip_if_not_installed("jsonlite")
  a <- lexdiv_run_recipe(c(doc = paste(rep(letters[1:7], 5), collapse = " ")),
    lexdiv_recipe(), metadata = data.frame(document_id = "doc", group = factor("A"),
      date = as.Date("2026-01-01"), undefined = NaN, infinite = Inf, missing = NA_real_))
  file <- tempfile(); on.exit(unlink(file), add = TRUE)
  lexdiv_write(a, file)
  expect_identical(lexdiv_read(file), a)
  expect_identical(a$analysis$metadata$group, "A")
  expect_identical(a$analysis$metadata$date, "2026-01-01")
})
