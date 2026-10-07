test_that("D remains accurate near saturation and agrees with hypergeometric targets", {
  # One doubleton, all other types singletons: E[TTR(n)] =
  # 1 - (n-1)/(N*(N-1)). 80-digit minimization of the stated SSE gives this D.
  N <- 1000000L
  tokens <- c("repeated", "repeated", paste0("u", seq_len(N - 2L)))
  fit <- lexdiv_metrics(tokens, metrics = "expected_ttr_d")
  reference <- 511904249956.534883722
  expect_identical(fit$status, "ok")
  expect_lt(abs(fit$value / reference - 1), 1e-12)
  expect_true(fit$diagnostics[[1L]]$near_saturation)

  # Independent hypergeometric probabilities, including highly uneven spectra.
  for (frequencies in list(c(1, 1, 2), c(98, 1, 1), rep(2, 25), c(30, 15, 5))) {
    N <- sum(frequencies)
    sizes <- 2:min(50, N)
    tokens <- rep(paste0("t", seq_along(frequencies)), frequencies)
    fit <- lexdiv_metrics(tokens, metrics = "expected_ttr_d",
      expected_ttr_sample_sizes = sizes)
    reference_ttr <- vapply(sizes, function(n) {
      sum(stats::phyper(0, frequencies, N - frequencies, n, lower.tail = FALSE)) / n
    }, numeric(1L))
    expect_equal(fit$diagnostics[[1L]]$expected_ttr, reference_ttr, tolerance = 1e-14)
  }
})

test_that("widening cannot conceal different parameter or contract identities", {
  tokens <- c("a", "b", "a", "b")
  a <- lexdiv_metrics_batch(list(a = tokens), metrics = "mattr", window_length = 2)
  b <- lexdiv_metrics_batch(list(b = tokens), metrics = "mattr", window_length = 4)
  expect_error(lexdiv_widen(rbind(a, b)), "different measurement specifications")
  b$requested_parameters <- a$requested_parameters
  b$effective_parameters <- a$effective_parameters
  b$metric_contract_version <- "another-version"
  expect_error(lexdiv_widen(rbind(a, b)), "different measurement specifications")

  mixed_domain <- lexdiv_metrics_batch(list(a = tokens, b = "a"),
    metrics = "mattr", window_length = 2)
  wide <- lexdiv_widen(mixed_domain)
  expect_equal(wide$mattr__value, c(1, NA_real_))
  expect_identical(wide$mattr__requested_parameters, mixed_domain$requested_parameters)
  expect_identical(wide$mattr__N, mixed_domain$N)

  method <- lexdiv_methods()$method_id[lexdiv_methods()$metric_id == "mattr"]
  p2 <- lexdiv_plan(presets = character(), specs = lexdiv_spec(method,
    list(window_length = 2), request_id = "mattr"))
  p4 <- lexdiv_plan(presets = character(), specs = lexdiv_spec(method,
    list(window_length = 4), request_id = "mattr"))
  combined <- rbind(lexdiv_profile_batch(list(a = tokens), p2),
    lexdiv_profile_batch(list(b = tokens), p4))
  expect_error(lexdiv_widen(combined), "different measurement specifications")
  expect_equal(ncol(lexdiv_widen(combined, names_from = "specification_id",
    values_from = "value")), 3L)
})

test_that("metric plots require one specification and retain its identity", {
  method <- lexdiv_methods()$method_id[lexdiv_methods()$metric_id == "mattr"]
  plan <- lexdiv_plan(presets = character(), grids = lexdiv_grid(
    method, "window_length", c(2, 4), request_id_prefix = "window"))
  x <- lexdiv_profile_batch(list(essay = c("a", "b", "a", "b")), plan)
  path <- tempfile(fileext = ".pdf")
  grDevices::pdf(path)
  on.exit({grDevices::dev.off(); unlink(path)}, add = TRUE)
  expect_error(plot(x, metric_id = "mattr"), "one measurement specification")
  shown <- plot(x, metric_id = "mattr", request_id = "window_1")
  expect_identical(shown$request_id, "window_1")
  expect_identical(shown$requested_parameters[[1]], list(window_length = 2L))
  expect_identical(shown$specification_id, x$specification_id[1])
})

test_that("preprocessing validation detects missing records and ordinary edits", {
  original <- lexdiv_tokenize("cat cat", case = "lower")
  for (field in c("source_text_sha256", "processed_text_sha256", "token_pattern",
                  "token_table_sha256", "processed_characters")) {
    broken <- original
    broken$provenance[[field]] <- NULL
    expect_error(lexdiv_metrics_text(broken, metrics = "ttr"), "provenance")
  }
  for (replacement in c("CAT", "dog")) {
    broken <- original
    broken$tokens$surface[2] <- replacement
    expect_error(lexdiv_metrics_text(broken, metrics = "ttr"), "inconsistent")
  }
  old <- original
  old$provenance$contract_version <- "0.1.0"
  expect_error(lexdiv_metrics_text(old), "recreate")
  annotated <- lexdiv_lemmatize(original, lemmas = c("cat", "cat"),
    backend_id = "fixture", backend_version = "1")
  expect_equal(lexdiv_metrics_text(annotated, unit = "lemma", metrics = "ttr")$results$value, 0.5)
  expect_identical(lexdiv_metrics_text(lexdiv_tokenize(""), metrics = "ttr")$results$missing_reason,
    "empty_input")
})

test_that("legacy MTLD tail behavior stays reproducible beside the new method", {
  lengths <- c(50, 51, 52, 59, 60)
  values <- vapply(lengths, function(n) {
    lexdiv_variant_metrics(rep("a", n),
      variants = "mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1")$value
  }, numeric(1L))
  current <- vapply(lengths, function(n) {
    lexdiv_metrics(rep("a", n), metrics = "mtld")$value
  }, numeric(1L))
  expect_equal(current, lengths / floor(lengths / 2))
  # Exact consequences of the legacy minimum-factor and linear-tail rules.
  expect_equal(values, c(10, 51/5, 52/(5 + 0.5/0.28),
    59/(5 + (8/9)/0.28), 10), tolerance = 1e-13)
})
