test_that("frozen actual external outputs distinguish MTLD variants and Maas scales", {
  root <- test_path("..", "fixtures", "external-metrics")
  inputs <- jsonlite::fromJSON(file.path(root, "inputs.json"))
  external <- jsonlite::fromJSON(file.path(root, "r-results.json"))
  taaled <- jsonlite::fromJSON(file.path(root, "taaled-results.json"))
  hash <- digest::digest(file = file.path(root, "inputs.json"), algo = "sha256")
  expect_identical(hash, external$inputs_sha256)
  expect_identical(hash, taaled$inputs_sha256)
  variants <- c(
    mtldo = "mtld_seq_bidir_dirmean_lt_min10_finaltail_linear_v1",
    mtldav = "mtld_seq_bidir_mfl_dirmean_lt_min10_finaltail_linear_v1",
    mtld = "mtld_seq_bidir_mfl_pooled_lt_min10_finaltail_linear_v1"
  )
  for (id in names(inputs$cases)) {
    tokens <- inputs$cases[[id]]
    saved <- external$results[[id]]
    python <- taaled$results[taaled$results$case == id, ]
    value <- setNames(python$value, python$metric)
    core <- lexdiv_metrics(tokens, metrics = c("ttr", "maas", "mtld"))
    ttr <- core$value[core$metric_id == "ttr"]
    maas <- core$value[core$metric_id == "maas"]
    expect_equal(ttr, saved$koRpus$ttr, tolerance = 1e-12, info = id)
    expect_equal(ttr, saved$quanteda.textstats$TTR, tolerance = 1e-12, info = id)
    expect_equal(ttr, unname(value["ttr"]), tolerance = 1e-12, info = id)
    # quanteda reports a (not a-squared); log.base was explicitly e.
    expect_equal(maas, saved$quanteda.textstats$Maas^2, tolerance = 1e-12, info = id)
    expect_equal(maas * log(10), unname(value["maas_log10"]), tolerance = 1e-12, info = id)
    if (length(tokens) >= 10L) {
      observed <- lexdiv_variant_metrics(tokens, variants = unname(variants))
      expect_equal(observed$value, unname(value[names(variants)]), tolerance = 1e-12, info = id)
    }
  }
  # Explicit counterexample: the names do not imply interchangeable outputs.
  expect_equal(external$results$repeated_50$koRpus$mtld, 50 / 24, tolerance = 1e-12)
  expect_equal(lexdiv_metrics(rep("a", 50), metrics = "mtld")$value, 2)
})

test_that("expected-TTR D is classified as experimental in metadata and contract", {
  methods <- lexdiv_methods()
  contract <- jsonlite::fromJSON(system.file(
    "spec", "lexical-diversity-contract.json", package = "ldfreq"))
  expect_identical(methods$stability, contract$metrics$stability)
  expect_identical(methods$stability[methods$metric_id == "expected_ttr_d"], "experimental")
  expect_match(contract$metrics$definition$validation_status[
    contract$metrics$metric_id == "expected_ttr_d"], "No such comparison has been completed")
})


test_that("no-minimum MTLD is compared with frozen koRpus outputs", {
  root <- test_path("..", "fixtures", "external-metrics")
  inputs <- jsonlite::fromJSON(file.path(root, "inputs.json"))$cases
  external <- jsonlite::fromJSON(file.path(root, "r-results.json"))$results
  expected <- c(repeated_9 = 9/4, repeated_10 = 2, repeated_19 = 19/9,
    repeated_50 = 2, threshold_equal = 9315/557, ordinary_tail = 14,
    short_tail = 2, asymmetric = 63/20, mixed_120 = 49/10)
  # koRpus skips a terminal span of <=2 tokens; only these cases differ.
  ending_two <- c("repeated_10", "repeated_50", "short_tail")
  for (id in names(inputs)) {
    result <- lexdiv_metrics(inputs[[id]], metrics = "mtld")
    expect_identical(result$method_id, "mtld_seq_bidir_dirmean_lt_nomin_linear_tail_v1")
    expect_equal(result$value, unname(expected[id]), tolerance = 1e-12, info = id)
    if (id %in% ending_two) {
      expect_true(external[[id]]$koRpus$mtld > result$value, info = id)
    } else {
      expect_equal(result$value, external[[id]]$koRpus$mtld, tolerance = 1e-12, info = id)
    }
    for (threshold in c(0.25, 0.5, 0.72, 0.9)) {
      a <- lexdiv_metrics(inputs[[id]], metrics = "mtld", mtld_threshold = threshold)
      b <- lexdiv_metrics(rev(inputs[[id]]), metrics = "mtld", mtld_threshold = threshold)
      expect_equal(a$value, b$value)
      tails <- unlist(a$diagnostics[[1]][c("forward_tail_credit", "reverse_tail_credit")])
      expect_true(all(tails >= 0 & tails <= 1 + 1e-14))
    }
  }
  expect_equal(lexdiv_metrics(c("a", "a"), metrics = "mtld")$value, 2)
  expect_identical(lexdiv_metrics("a", metrics = "mtld")$missing_reason, "no_factor")
})

test_that("saved old results retain their identity and legacy values", {
  old <- readRDS(test_path("..", "fixtures", "external-metrics", "legacy-core-0.1.0.rds"))
  inputs <- jsonlite::fromJSON(test_path("..", "fixtures", "external-metrics", "inputs.json"))$cases
  expect_true(all(old$results$metric_contract_version == "0.1.0"))
  expect_output(print(old$results), "lexdiv_batch_results")
  for (id in names(inputs)) {
    saved <- old$results[old$results$document_id == id, ]
    replay <- lexdiv_variant_metrics(inputs[[id]], variants = saved$method_id)
    expect_identical(replay$value, saved$value)
    expect_identical(replay$status, saved$status)
    expect_identical(replay$missing_reason, saved$missing_reason)
    if (saved$status == "ok") expect_identical(replay$diagnostics, saved$diagnostics)
  }
  expect_error(lexdiv_profile(inputs[[1]], old$plan), "contract|integrity|Unknown method")
  current <- lexdiv_metrics_batch(inputs, metrics = "mtld")
  expect_error(lexdiv_widen(rbind(old$results, current)), "different measurement")
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path))
  saveRDS(list(old = old, current = current), path)
  expect_identical(readRDS(path), list(old = old, current = current))
})

test_that("experimental D requires explicit selection across entry points", {
  tokens <- rep(c("a", "b", "a", "c"), 20)
  expect_false("expected_ttr_d" %in% lexdiv_metrics(tokens)$metric_id)
  expect_false("expected_ttr_d" %in% lexdiv_metrics_batch(list(a = tokens))$metric_id)
  expect_false("expected_ttr_d" %in% lexdiv_metrics_text(paste(tokens, collapse = " "))$results$metric_id)
  expect_false("expected_ttr_d" %in% lexdiv_profile(tokens)$metric_id)
  expect_true("expected_ttr_d" %in% lexdiv_metric_ids())
  explicit <- lexdiv_metrics(tokens, metrics = "expected_ttr_d")
  plan <- lexdiv_plan(presets = character(), specs = lexdiv_spec(explicit$method_id))
  expect_identical(lexdiv_profile(tokens, plan)$value, explicit$value)
})
