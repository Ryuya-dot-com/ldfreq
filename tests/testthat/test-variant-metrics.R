test_that("the variant catalog is explicit and duplicate-free", {
  catalog <- lexdiv_variant_ids()

  expect_identical(nrow(catalog), 8L)
  expect_identical(anyDuplicated(catalog$method_id), 0L)
  expect_identical(
    as.integer(table(catalog$family)),
    c(4L, 4L)
  )
  expect_true(all(catalog$direction %in% c("higher", "lower")))
  expect_identical(
    catalog$reference_label[catalog$method_id == "maas_a2_log10_v1"],
    "TAALED-0.32:maas"
  )
  expect_true(all(nzchar(catalog$reference_label)))
  expect_true(all(nzchar(catalog$comparison_scope)))
})

test_that("Maas scale and logarithm-base variants follow their formulas", {
  tokens <- c("a", "b", "c", "a")
  ids <- lexdiv_variant_ids()$method_id
  maas_ids <- ids[startsWith(ids, "maas_")]
  result <- lexdiv_variant_metrics(tokens, variants = maas_ids)
  values <- stats::setNames(result$value, result$method_id)
  a2_ln <- (log(4) - log(3)) / log(4)^2
  a2_log10 <- (log10(4) - log10(3)) / log10(4)^2

  expect_equal(values[["maas_a2_ln_v1"]], a2_ln, tolerance = 1e-15)
  expect_equal(values[["maas_a_ln_v1"]], sqrt(a2_ln), tolerance = 1e-15)
  expect_equal(
    values[["maas_a2_log10_v1"]],
    a2_log10,
    tolerance = 1e-15
  )
  expect_equal(
    values[["maas_a_log10_v1"]],
    sqrt(a2_log10),
    tolerance = 1e-15
  )
  expect_equal(a2_log10, log(10) * a2_ln, tolerance = 1e-15)
  expect_true(all(result$status == "ok"))
  expect_true(all(result$direction == "lower"))
  expect_output(
    print(result[, c("family", "method_id", "value", "status")]),
    "lexdiv_variant_results"
  )
})

test_that("variant metrics warn about likely raw prose", {
  expect_warning(
    lexdiv_variant_metrics(
      "The cat sat on the mat.",
      variants = "maas_a2_ln_v1"
    ),
    "each vector element as one lexical unit"
  )
})

test_that("the canonical MTLD row is unchanged in the variant surface", {
  tokens <- c(rep("a", 10L), "b", "c", "d", "e")
  method_id <- "mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1"
  variant <- lexdiv_variant_metrics(tokens, variants = method_id)
  core <- lexdiv_metrics(tokens, metrics = "mtld")

  expect_identical(variant$method_id, core$method_id)
  expect_identical(variant$value, core$value)
  expect_identical(variant$status, core$status)
  expect_identical(variant$missing_reason, core$missing_reason)
  expect_identical(variant$diagnostics[[1L]], core$diagnostics[[1L]])
})

test_that("final-tail and mean-factor-length aggregations remain distinct", {
  tokens <- rep("a", 50L)
  methods <- c(
    "mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1",
    "mtld_seq_bidir_dirmean_lt_min10_finaltail_linear_v1",
    "mtld_seq_bidir_mfl_dirmean_lt_min10_finaltail_linear_v1",
    "mtld_seq_bidir_mfl_pooled_lt_min10_finaltail_linear_v1"
  )
  result <- lexdiv_variant_metrics(tokens, variants = methods)
  values <- stats::setNames(result$value, result$method_id)
  tail_credit <- (1 - 0.1) / (1 - 0.72)
  finaltail_directional <- 50 / (4 + tail_credit)
  finaltail_mfl <- mean(c(rep(10, 4), 10 / tail_credit))

  expect_identical(
    values[["mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1"]],
    10
  )
  expect_equal(
    values[["mtld_seq_bidir_dirmean_lt_min10_finaltail_linear_v1"]],
    finaltail_directional,
    tolerance = 1e-14
  )
  expect_equal(
    values[["mtld_seq_bidir_mfl_dirmean_lt_min10_finaltail_linear_v1"]],
    finaltail_mfl,
    tolerance = 1e-14
  )
  expect_equal(
    values[["mtld_seq_bidir_mfl_pooled_lt_min10_finaltail_linear_v1"]],
    finaltail_mfl,
    tolerance = 1e-14
  )
  diagnostics <- result$diagnostics[[2L]]
  expect_identical(diagnostics$forward_factor_lengths, rep.int(10L, 5L))
  expect_identical(
    diagnostics$forward_is_tail,
    c(FALSE, FALSE, FALSE, FALSE, TRUE)
  )
})

test_that("multiple MTLD thresholds expand in stable request order", {
  method <- "mtld_seq_bidir_mfl_pooled_lt_min10_finaltail_linear_v1"
  result <- lexdiv_variant_metrics(
    rep(c("a", "b", "c"), 20L),
    variants = method,
    mtld_thresholds = c(0.72, 0.92)
  )

  expect_identical(nrow(result), 2L)
  expect_identical(result$method_id, rep.int(method, 2L))
  expect_identical(
    vapply(result$requested_parameters, `[[`, numeric(1L), "threshold"),
    c(0.72, 0.92)
  )
  expect_true(all(result$status == "ok"))
})

test_that("variant input and domain failures remain structured", {
  methods <- c("maas_a2_ln_v1", "mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1")
  invalid <- lexdiv_variant_metrics(factor("a"), variants = methods)
  empty <- lexdiv_variant_metrics(character(), variants = methods)
  singleton <- lexdiv_variant_metrics("a", variants = methods)

  expect_identical(invalid$status, rep.int("invalid_input", 2L))
  expect_identical(invalid$missing_reason, rep.int("invalid_token", 2L))
  expect_true(all(is.na(invalid$N)))
  expect_identical(empty$status, rep.int("missing", 2L))
  expect_identical(empty$missing_reason, rep.int("empty_input", 2L))
  expect_identical(
    singleton$missing_reason,
    rep.int("insufficient_tokens_for_formula", 2L)
  )

  expect_error(lexdiv_variant_metrics(c("a", "b"), variants = "unknown"))
  expect_error(
    lexdiv_variant_metrics(c("a", "b"), mtld_thresholds = c(0.72, 0.72)),
    "distinct"
  )
})

test_that("the installed variant contract matches the public catalog", {
  skip_if_not_installed("jsonlite")
  contract_path <- system.file(
    "spec", "lexical-diversity-variant-contract.json",
    package = "ldfreq"
  )
  schema_path <- system.file(
    "spec", "lexical-diversity-variant-contract.schema.json",
    package = "ldfreq"
  )
  expect_true(nzchar(contract_path) && file.exists(contract_path))
  expect_true(nzchar(schema_path) && file.exists(schema_path))
  contract <- jsonlite::read_json(contract_path, simplifyVector = FALSE)
  schema <- jsonlite::read_json(schema_path, simplifyVector = FALSE)
  contract_ids <- c(
    vapply(contract$maas_methods, `[[`, character(1L), "method_id"),
    vapply(contract$mtld_methods, `[[`, character(1L), "method_id")
  )
  contract_labels <- c(
    vapply(contract$maas_methods, `[[`, character(1L), "reference_label"),
    vapply(contract$mtld_methods, `[[`, character(1L), "reference_label")
  )

  expect_identical(contract$contract_id, "ldfreq-lexical-diversity-variants")
  expect_identical(contract$contract_version, "0.1.0")
  expect_identical(contract$status, "normative")
  expect_identical(contract$core_contract_changed, FALSE)
  expect_identical(contract_ids, lexdiv_variant_ids()$method_id)
  expect_identical(contract_labels, lexdiv_variant_ids()$reference_label)
  expect_identical(
    contract$compatibility_boundary$official_TAALED_compatibility_claimed,
    FALSE
  )
  expect_identical(schema$properties$contract_id$const, contract$contract_id)
})
