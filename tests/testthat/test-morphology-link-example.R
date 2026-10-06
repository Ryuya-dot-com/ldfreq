morphology_link_recipe <- function() {
  skip_if_not_installed("quanteda")
  skip_if_not(isTRUE(l10n_info()[["UTF-8"]]), "quanteda requires a UTF-8 session")
  e <- new.env(parent = baseenv())
  sys.source(system.file("examples", "morphology-link.R", package = "ldfreq", mustWork = TRUE), e)
  sys.source(system.file("examples", "morphology-link-demo.R", package = "ldfreq", mustWork = TRUE), e)
  e
}

test_that("morphology joins retain token identity and distinguish decisions from lookup", {
  e <- morphology_link_recipe(); a <- e$morphology_link_example$initial; b <- e$morphology_link_example$reviewed
  expect_equal(nrow(a$occurrences), 5)
  expect_identical(a$occurrences$occurrence_id, b$occurrences$occurrence_id)
  expect_identical(a$occurrences$family_id, b$occurrences$family_id)
  expect_identical(a$inputs$family, b$inputs$family)
  expect_identical(a$occurrences[c("surface", "start", "end")], b$occurrences[c("surface", "start", "end")])
  expect_equal(a$documents$morpholex_selected_N, c(0, 0))
  expect_equal(a$documents$morphynet_selected_N, c(0, 0))
  expect_equal(b$documents$eligible_N, c(5, 0))
  expect_equal(b$documents$morpholex_selected_complete_N, c(1, 0))
  expect_equal(b$documents$reviewed_root_instances, c(1, 0))
  expect_equal(b$documents$reviewed_suffix_instances, c(1, 0))
  expect_equal(b$documents$reviewed_prefix_instances, c(0, 0))
  expect_equal(b$documents$morpholex_unresolved_N, c(1, 0))
  expect_true(is.na(b$documents$full_suffix_instances[1]))
  expect_equal(b$documents$full_suffix_instances[2], 0)
  expect_equal(b$documents$morphynet_selected_N, c(1, 0))
  expect_equal(b$documents$selected_suffix_relations, c(1, 0))
  expect_equal(b$documents$morphynet_unresolved_N, c(1, 0))
  expect_equal(b$occurrences$morphynet_candidate_count[3:4], c(3, 3))
  expect_equal(b$occurrences$morphynet_candidate_count[5], 0)
  expect_identical(b$reviewed_relations$morpheme, "ity")
  expect_equal(b$documents$morpholex_review_selection_coverage[1], 1/5)
  expect_true(is.na(b$documents$morpholex_review_selection_coverage[2]))
  path <- tempfile(); on.exit(unlink(path)); saveRDS(b, path)
  restored <- readRDS(path)
  expect_identical(do.call(e$link_morphology_candidates, restored$inputs), restored)
})

test_that("invalid joins, exclusions and stale decisions fail rather than change denominators", {
  e <- morphology_link_recipe(); b <- e$morphology_link_example$reviewed; input <- b$inputs
  changed <- input; changed$family$occurrences$family_id[1] <- "other"
  expect_error(do.call(e$link_morphology_candidates, changed), "unmodified")
  changed <- input; changed$selected[1] <- NA
  expect_error(do.call(e$link_morphology_candidates, changed), "selected")
  changed <- input; changed$selected[] <- FALSE
  expect_error(do.call(e$link_morphology_candidates, changed), "at least one")
  changed <- input; changed$morphynet$relations$relation_id[2] <- changed$morphynet$relations$relation_id[1]
  expect_error(do.call(e$link_morphology_candidates, changed), "unique MorphyNet")
  changed <- input; changed$morpholex_decisions$review_id <- "stale"
  expect_error(do.call(e$link_morphology_candidates, changed), "review_id differs")
  changed <- input; changed$morphynet_decisions$candidate_id[1] <- "absent"
  expect_error(do.call(e$link_morphology_candidates, changed), "not a candidate")
  # Excluding just one of two equal surfaces must not permit its old decision.
  changed <- input; changed$selected[4] <- FALSE
  expect_error(do.call(e$link_morphology_candidates, changed), "excluded occurrence")
  changed$morphynet_decisions <- changed$morphynet_decisions[1, ]
  z <- do.call(e$link_morphology_candidates, changed)
  expect_equal(z$documents$eligible_N, c(4, 0))
  expect_equal(nrow(z$occurrences), 4)
  expect_identical(z$occurrences$token_index, c(1L, 2L, 3L, 5L))
})

test_that("alternative segmentations are candidates, not additional observed parts", {
  e <- morphology_link_recipe(); input <- e$morphology_link_example$initial$inputs
  ml <- input$morpholex
  row <- which(ml$analyses$form == "teacher")
  alt <- ml$analyses[row, ]; alt$analysis_id <- "authored-alternative"
  ml$analyses <- rbind(ml$analyses, alt)
  part <- ml$parts[ml$parts$analysis_id == input$morpholex$analyses$analysis_id[row] & ml$parts$role == "root", ]
  part$analysis_id <- "authored-alternative"; part$part_index <- 1L
  part$part_id <- "root:authored-teacher"; part$canonical <- "teacher"
  ml$parts <- rbind(ml$parts, part)
  ml$resource$resource_id <- "authored-alternative-to-reference"
  ml$resource$analysis_basis <- "Authored whole-word alternative for regression checking"
  input$morpholex <- ml
  a <- do.call(e$link_morphology_candidates, input)
  expect_identical(a$occurrences$morpholex_lookup_status[1], "ambiguous")
  expect_equal(a$occurrences$morpholex_candidate_count[1], 2)
  expect_equal(nrow(a$reviewed_parts), 0)
  d <- a$reviews$morpholex$occurrences[1, c("review_id", "occurrence_id")]
  d$status <- "selected"; d$candidate_id <- "authored-alternative"; d$reviewer <- "test"; d$reason <- "Declared fixture choice"
  input$morpholex_decisions <- d
  b <- do.call(e$link_morphology_candidates, input)
  expect_equal(nrow(b$reviewed_parts), 1)
  expect_equal(b$documents$reviewed_suffix_instances, c(0, 0))
  expect_equal(b$documents$reviewed_root_instances, c(1, 0))
})
