basic_metric <- function(metric_id) {
  getFromNamespace(paste0(".metric_", metric_id), "ldfreq")
}

test_that("basic formula metrics match the hand-calculated contract cases", {
  tokens <- c("a", "a", "b", "c")

  expect_equal(basic_metric("ttr")(tokens)$value, 3 / 4, tolerance = 1e-12)
  expect_equal(basic_metric("rttr")(tokens)$value, 3 / sqrt(4), tolerance = 1e-12)
  expect_equal(basic_metric("cttr")(tokens)$value, 3 / sqrt(8), tolerance = 1e-12)
  expect_equal(
    basic_metric("herdan")(tokens)$value,
    log(3) / log(4),
    tolerance = 1e-12
  )
  expect_equal(
    basic_metric("maas")(tokens)$value,
    (log(4) - log(3)) / log(4)^2,
    tolerance = 1e-12
  )

  msttr <- basic_metric("msttr")(
    tokens, parameters = list(segment_length = 2)
  )
  mattr <- basic_metric("mattr")(
    tokens, parameters = list(window_length = 2)
  )
  expect_equal(msttr$value, 3 / 4, tolerance = 1e-12)
  expect_equal(mattr$value, 5 / 6, tolerance = 1e-12)
})

test_that("records carry frozen identities, counts, parameters, and quality flags", {
  tokens <- c("a", "a", "b", "c")
  result <- basic_metric("msttr")(
    tokens, parameters = list(segment_length = 2)
  )

  expect_identical(result$metric_id, "msttr")
  expect_identical(result$method_id, "msttr_nonoverlap_complete_drop_v1")
  expect_identical(result$status, "ok")
  expect_identical(result$missing_reason, NA_character_)
  expect_equal(result$requested_parameters, list(segment_length = 2))
  expect_equal(result$effective_parameters, result$requested_parameters)
  expect_equal(result$N, 4)
  expect_equal(result$V, 3)
  expect_true(result$below_quality_floor)
  expect_equal(result$diagnostics, list())
})

test_that("Herdan and Maas enforce their singleton computational domain", {
  herdan <- basic_metric("herdan")("a")
  maas <- basic_metric("maas")("a")

  expect_identical(herdan$status, "missing")
  expect_identical(herdan$missing_reason, "insufficient_tokens_for_formula")
  expect_identical(maas$status, "missing")
  expect_identical(maas$missing_reason, "insufficient_tokens_for_formula")
  expect_equal(herdan$effective_parameters, list())
  expect_equal(maas$effective_parameters, list())
})

test_that("empty documents are domain-safe for every basic metric", {
  metric_ids <- c("ttr", "rttr", "cttr", "herdan", "maas", "msttr", "mattr")

  for (metric_id in metric_ids) {
    result <- basic_metric(metric_id)(character())
    expect_identical(result$status, "missing", info = metric_id)
    expect_identical(result$missing_reason, "empty_input", info = metric_id)
    expect_equal(result$N, 0, info = metric_id)
    expect_equal(result$V, 0, info = metric_id)
  }
})

test_that("MSTTR drops only the final incomplete segment", {
  tokens <- c("a", "b", "a", "b", "c")
  result <- basic_metric("msttr")(
    tokens, parameters = list(segment_length = 2)
  )

  expect_equal(result$value, 1, tolerance = 1e-12)
})

test_that("MATTR includes every complete step-one window", {
  tokens <- c("a", "b", "a", "b", "c")
  result <- basic_metric("mattr")(
    tokens, parameters = list(window_length = 3)
  )

  expect_equal(result$value, 7 / 9, tolerance = 1e-12)
  reversed <- basic_metric("mattr")(
    rev(tokens), parameters = list(window_length = 3)
  )
  expect_equal(reversed$value, result$value, tolerance = 1e-12)
})

test_that("MATTR uses a non-overflowing accumulator for long diverse input", {
  tokens <- paste0("type", seq_len(100000L))
  result <- basic_metric("mattr")(
    tokens,
    parameters = list(window_length = 50000L)
  )

  expect_identical(result$status, "ok")
  expect_equal(result$value, 1, tolerance = 0)
})

test_that("requested local length is never silently reduced", {
  tokens <- c("a", "b", "c")
  msttr <- basic_metric("msttr")(
    tokens, parameters = list(segment_length = 4)
  )
  mattr <- basic_metric("mattr")(
    tokens, parameters = list(window_length = 4)
  )

  for (result in list(msttr, mattr)) {
    expect_identical(result$status, "missing")
    expect_identical(
      result$missing_reason, "too_short_for_requested_parameter"
    )
    expect_equal(result$effective_parameters, list())
  }
  expect_equal(msttr$requested_parameters, list(segment_length = 4))
  expect_equal(mattr$requested_parameters, list(window_length = 4))

  default_msttr <- basic_metric("msttr")(tokens)
  default_mattr <- basic_metric("mattr")(tokens)
  expect_equal(default_msttr$requested_parameters, list(segment_length = 50))
  expect_equal(default_mattr$requested_parameters, list(window_length = 50))
})

test_that("local-length parameters are strictly positive integer-valued scalars", {
  invalid <- list(
    0, -1, 1.5, NA_real_, NaN, Inf, c(1, 2), "2", TRUE, NULL,
    matrix(2, nrow = 1),
    structure(2, class = "not-a-plain-number")
  )

  for (value in invalid) {
    expect_error(
      basic_metric("msttr")(
        rep("a", 4), parameters = list(segment_length = value)
      ),
      "segment_length.*finite numeric scalar.*integer value.*>= 1"
    )
    expect_error(
      basic_metric("mattr")(
        rep("a", 4), parameters = list(window_length = value)
      ),
      "window_length.*finite numeric scalar.*integer value.*>= 1"
    )
  }

  expect_error(
    basic_metric("msttr")(rep("a", 4), parameters = list(other = 2)),
    "Unknown parameter"
  )
  expect_error(
    basic_metric("mattr")(rep("a", 4), parameters = list(2)),
    "unique, non-empty name"
  )
  duplicated <- structure(list(2, 3), names = c("window_length", "window_length"))
  expect_error(
    basic_metric("mattr")(rep("a", 4), parameters = duplicated),
    "unique, non-empty name"
  )
})

test_that("parameter-free metrics reject accidental parameters", {
  for (metric_id in c("ttr", "rttr", "cttr", "herdan", "maas")) {
    expect_error(
      basic_metric(metric_id)(c("a", "b"), parameters = list(unused = 1)),
      "does not accept parameters",
      info = metric_id
    )
    expect_error(
      basic_metric(metric_id)(c("a", "b"), parameters = NULL),
      "named list",
      info = metric_id
    )
  }
})

test_that("basic metrics obey relabeling and algebraic properties", {
  tokens <- c("x", "x", "y", "z", "x", "w", "y")
  relabeled <- c("猫", "猫", "犬", "鳥", "猫", "魚", "犬")
  counts_fun <- getFromNamespace(".lex_counts", "ldfreq")
  precomputed <- counts_fun(tokens)

  for (metric_id in c("ttr", "rttr", "cttr", "herdan", "maas")) {
    direct <- basic_metric(metric_id)(tokens)
    reused <- basic_metric(metric_id)(tokens, counts = precomputed)
    changed_labels <- basic_metric(metric_id)(relabeled)
    expect_equal(reused$value, direct$value, tolerance = 1e-12, info = metric_id)
    expect_equal(
      changed_labels$value, direct$value, tolerance = 1e-12, info = metric_id
    )
  }

  n <- length(tokens)
  ttr <- basic_metric("ttr")(tokens)$value
  rttr <- basic_metric("rttr")(tokens)$value
  cttr <- basic_metric("cttr")(tokens)$value
  expect_equal(rttr, ttr * sqrt(n), tolerance = 1e-12)
  expect_equal(cttr, rttr / sqrt(2), tolerance = 1e-12)

  expect_equal(
    basic_metric("msttr")(tokens, parameters = list(segment_length = 1))$value,
    1
  )
  expect_equal(
    basic_metric("mattr")(tokens, parameters = list(window_length = 1))$value,
    1
  )
  expect_equal(
    basic_metric("msttr")(
      tokens, parameters = list(segment_length = n)
    )$value,
    ttr,
    tolerance = 1e-12
  )
  expect_equal(
    basic_metric("mattr")(
      tokens, parameters = list(window_length = n)
    )$value,
    ttr,
    tolerance = 1e-12
  )
})
