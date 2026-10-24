# Independently enumerate each prefix at each start, rather than sharing the
# implementation's running type-count state.
mtld_ma_reference <- function(tokens, threshold = .72) {
  sizes <- integer()
  for (start in seq_along(tokens)) {
    x <- tokens[start:length(tokens)]
    ttr <- vapply(seq_along(x), function(k) length(unique(head(x, k))) / k, numeric(1))
    crossings <- which(ttr < threshold)
    if (!length(crossings)) break
    sizes <- c(sizes, crossings[[1]])
  }
  retained <- sizes[sizes >= 10]
  if (length(retained)) mean(retained) else NA_real_
}

test_that("MTLD-MA uses completed overlapping factors and excludes short factors", {
  examples <- list(character(), "a", rep("a", 100), letters,
    c(letters[1:7], rep("a", 3)), rep(letters[1:20], 8),
    c(rep(letters[1:7], 4), letters, rep("a", 10)))
  set.seed(1953)
  examples <- c(examples, replicate(30, sample(letters, 120, TRUE), simplify = FALSE))
  for (tokens in examples) for (threshold in c(.5,.72,.9)) {
    got <- lexdiv_metrics(tokens, metrics = "mtld_ma", mtld_threshold = threshold)
    expect_equal(got$value, mtld_ma_reference(tokens, threshold), tolerance = 1e-12)
  }
  expect_equal(lexdiv_metrics(examples[[5]], metrics = "mtld_ma")$value, 10)
  expect_identical(lexdiv_metrics(rep("a", 100), metrics = "mtld_ma")$missing_reason, "no_factor")
})

test_that("MTLD-MA is opt-in and preserves plan, batch and raw-text dispatch", {
  x <- rep(letters[1:20], 8)
  expect_false("mtld_ma" %in% lexdiv_metrics(x)$metric_id)
  expect_false("mtld_ma" %in% lexdiv_profile(x)$metric_id)
  a <- lexdiv_metrics(x, metrics = "mtld_ma", mtld_threshold = .7)
  plan <- lexdiv_plan(presets = character(), specs = lexdiv_spec(a$method_id, list(threshold = .7)))
  expect_equal(lexdiv_profile(x, plan)$value, a$value)
  expect_equal(lexdiv_metrics_batch(list(doc = x), metrics = "mtld_ma", mtld_threshold = .7)$value, a$value)
  expect_equal(lexdiv_metrics_text(paste(x, collapse = " "), metrics = "mtld_ma",
    mtld_threshold = .7)$results$value, a$value)
})
