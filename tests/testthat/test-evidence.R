length_evidence_function <- getFromNamespace("lexdiv_length_evidence", "ldfreq")

test_that("length evidence keeps computation, evidence, and guidance separate", {
  evidence <- length_evidence_function()

  expect_s3_class(evidence, "data.frame")
  expect_equal(nrow(evidence), 7L)
  expect_identical(
    names(evidence),
    c(
      "evidence_id", "source_id", "source_kind", "metric_id",
      "method_scope", "floor_tokens", "evidence_role", "population",
      "modality_genre", "target_method_equivalence", "universal_cutoff",
      "doi", "url"
    )
  )
  expect_identical(anyDuplicated(evidence$evidence_id), 0L)
  expect_setequal(unique(evidence$floor_tokens), c(50, 100))
  expect_true(all(!evidence$universal_cutoff))
  expect_setequal(
    unique(evidence$source_kind),
    c("empirical_study", "versioned_tool_guidance")
  )
  expect_true(all(evidence$target_method_equivalence != "direct"))
})

test_that("50 and 100 MTLD records retain their distinct research contexts", {
  evidence <- length_evidence_function()
  mtld <- evidence[evidence$metric_id == "mtld", , drop = FALSE]
  empirical <- mtld[mtld$source_kind == "empirical_study", , drop = FALSE]

  expect_setequal(empirical$floor_tokens, c(50, 100))
  expect_match(empirical$population[empirical$floor_tokens == 50], "4,542")
  expect_match(empirical$modality_genre[empirical$floor_tokens == 50], "written")
  expect_match(empirical$population[empirical$floor_tokens == 100], "20")
  expect_match(empirical$modality_genre[empirical$floor_tokens == 100], "spoken")
  expect_true(all(empirical$target_method_equivalence == "not_asserted"))
})

test_that("public length evidence stays synchronized with the installed registry", {
  registry_path <- system.file(
    "spec",
    "length-quality-evidence.json",
    package = "ldfreq"
  )
  registry <- jsonlite::read_json(registry_path, simplifyVector = FALSE)
  evidence <- length_evidence_function()

  registry_empirical_ids <- vapply(
    registry$evidence_records[1:3],
    `[[`,
    character(1L),
    "evidence_id"
  )
  public_empirical_ids <- evidence$evidence_id[
    evidence$source_kind == "empirical_study"
  ]
  expect_identical(public_empirical_ids, registry_empirical_ids)

  registry_screens <- vapply(
    registry$descriptive_screen_profiles,
    function(x) as.numeric(x$floor_tokens),
    numeric(1L)
  )
  expect_identical(registry_screens, c(50, 100))

  tool_rows <- evidence$source_kind == "versioned_tool_guidance"
  expect_setequal(
    paste(evidence$metric_id[tool_rows], evidence$floor_tokens[tool_rows]),
    c("mattr 50", "mtld 50", "hdd 50", "maas 100")
  )
  expect_match(
    registry$evidence_records[[4L]]$method_scope,
    "MATTR 50, MTLD Original 50, HD-D 50, Maas 100",
    fixed = TRUE
  )
})
