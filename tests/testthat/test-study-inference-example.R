inference_record <- function(transform = identity, formula = NULL) {
  for (p in c("lme4", "emmeans", "pbkrtest")) skip_if_not_installed(p)
  e <- new.env(parent = globalenv())
  sys.source(system.file("examples", "repeated-study-demo.R",
    package = "ldfreq", mustWork = TRUE), e)
  record <- e$record
  record$selected$data <- transform(record$selected$data)
  data <- record$selected$data
  if (is.null(formula)) formula <- record$model_formula
  warnings <- messages <- character()
  fit <- withCallingHandlers(
    lme4::lmer(formula, data = data, REML = TRUE, na.action = na.fail),
    warning = function(w) {
      warnings <<- c(warnings, conditionMessage(w)); invokeRestart("muffleWarning")
    },
    message = function(m) {
      messages <<- c(messages, conditionMessage(m)); invokeRestart("muffleMessage")
    })
  record$model <- list(fit = fit,
    diagnostics = list(warnings = warnings, messages = messages))
  record
}

run_inference <- function(record) {
  e <- new.env(parent = globalenv()); e$record <- record
  sys.source(system.file("examples", "study-inference.R",
    package = "ldfreq", mustWork = TRUE), e)
  e$record$inference
}

test_that("the recipe agrees with GLS, explicit contrasts and the KR reference", {
  record <- inference_record()
  x <- run_inference(record)
  fit <- record$model$fit; d <- record$selected$data
  expect_identical(x$status, "computed_not_validated_for_substantive_inference")
  expect_identical(x$observation_ids, d$observation_id)
  expect_equal(x$writers, 18)
  expect_equal(nrow(x$observations), 102)
  expect_identical(x$selection_audit, record$selected$audit)
  expect_equal(x$settings$task_weights, c(description = 0.5, argument = 0.5))
  expect_identical(x$settings$df_method, "kenward-roger")
  expect_length(x$diagnostics$issues, 0)

  # Independently solve GLS using the fitted marginal covariance, not emmeans'
  # design grid or fixed-effect vector. This does not revalidate KR's coverage.
  X <- cbind(1, d$occasion, as.numeric(d$task == "argument"))
  ZL <- as.matrix(lme4::getME(fit, "Z") %*% lme4::getME(fit, "Lambda"))
  V <- stats::sigma(fit)^2 * (tcrossprod(ZL) + diag(nrow(d)))
  VinvX <- solve(V, X)
  cov_beta <- solve(crossprod(X, VinvX))
  beta <- cov_beta %*% crossprod(VinvX, d$value)
  expect_equal(as.numeric(beta), unname(lme4::fixef(fit)), tolerance = 1e-7)
  expect_equal(unname(cov_beta), unname(as.matrix(stats::vcov(fit))),
    tolerance = 1e-7)
  adjusted <- pbkrtest::vcovAdj(fit)
  cells <- x$tables$cells
  L <- cbind(1, cells$occasion, as.numeric(cells$task == "argument"))
  se <- sqrt(diag(L %*% as.matrix(adjusted) %*% t(L)))
  df <- apply(L, 1, pbkrtest::Lb_ddf, V0 = stats::vcov(fit), Vadj = adjusted)
  expect_equal(cells$emmean, as.numeric(L %*% beta), tolerance = 1e-7)
  expect_equal(cells$SE, unname(se), tolerance = 1e-7)
  expect_equal(cells$df, unname(df), tolerance = 1e-7)
  expect_equal(cells$lower.CL, cells$emmean - stats::qt(.975, df) * se,
    ignore_attr = TRUE, tolerance = 1e-7)
  expect_equal(cells$upper.CL, cells$emmean + stats::qt(.975, df) * se,
    ignore_attr = TRUE, tolerance = 1e-7)
  expect_identical(cells$observed_n, c(12L, 18L, 18L, 18L, 18L, 18L))
  expect_true(all(cells$support == "observed_cell"))
  weeks <- x$tables$weeks
  W <- cbind(1, weeks$occasion, 0.5)
  expect_equal(weeks$emmean, as.numeric(W %*% beta), tolerance = 1e-7)
  expect_equal(weeks$SE, sqrt(diag(W %*% as.matrix(adjusted) %*% t(W))),
    ignore_attr = TRUE, tolerance = 1e-7)
  C <- matrix(c(0, 8, 0), nrow = 1)
  comparison <- x$tables$comparison
  expect_equal(comparison$estimate, as.numeric(C %*% beta), tolerance = 1e-7)
  expect_equal(comparison$SE, as.numeric(sqrt(C %*% adjusted %*% t(C))),
    tolerance = 1e-7)
  expect_equal(comparison$df,
    pbkrtest::Lb_ddf(C, stats::vcov(fit), adjusted), tolerance = 1e-7)
  expect_equal(comparison$lower.CL,
    comparison$estimate - qt(.975, comparison$df) * comparison$SE)
  expect_equal(comparison$upper.CL,
    comparison$estimate + qt(.975, comparison$df) * comparison$SE)
  expect_false("p.value" %in% names(comparison))
  expect_equal(sum(x$contrast_coefficients), 0)
})

test_that("factor coding and row order do not change the specified estimands", {
  original <- run_inference(inference_record())
  changed <- run_inference(inference_record(function(d) {
    d <- d[nrow(d):1, ]
    d$task <- factor(d$task, levels = c("argument", "description"))
    contrasts(d$task) <- stats::contr.sum(2)
    d
  }))
  for (name in c("weeks", "comparison")) {
    columns <- if (name == "weeks") c("emmean", "SE", "df", "lower.CL", "upper.CL")
      else c("estimate", "SE", "df", "lower.CL", "upper.CL")
    expect_equal(as.matrix(original$tables[[name]][columns]),
      as.matrix(changed$tables[[name]][columns]), tolerance = 2e-4)
  }
  expect_identical(original$observation_ids, rev(changed$observation_ids))
})

test_that("unobserved cells and extrapolation remain labelled", {
  x <- run_inference(inference_record(function(d)
    d[!(d$task == "argument" & d$occasion == 4), ],
    value ~ occasion + task + (1 | writer_id)))
  cell <- x$tables$cells
  expect_identical(cell$support[cell$task == "argument" & cell$occasion == 4],
    "unobserved_cell")
  expect_identical(x$tables$weeks$support[2], "unobserved_cell")
  y <- run_inference(inference_record(function(d) d[d$occasion != 8, ],
    value ~ occasion + task + (1 | writer_id)))
  expect_true(all(y$tables$cells$support[y$tables$cells$occasion == 8] ==
    "extrapolation"))
  expect_identical(y$tables$comparison$support, "inspect_endpoint_support")
})

test_that("problem fits and mismatched saved rows cannot yield routine intervals", {
  record <- inference_record(formula =
    value ~ occasion + I(occasion * 2) + task + (1 | writer_id))
  x <- run_inference(record)
  expect_null(x$tables)
  expect_identical(x$status, "model_diagnostics_require_review")
  expect_true("rank_deficient" %in% x$diagnostics$issues)
  record <- inference_record()
  record$model$diagnostics$warnings <- "A fitting warning requiring review"
  expect_null(run_inference(record)$tables)
  record$selected$data <- record$selected$data[102:1, ]
  expect_error(run_inference(record), "observation IDs")
  record$selected$data <- record$selected$data[102:1, ]
  record$selected$data$value[1] <- 0
  expect_error(run_inference(record), "Model data differ")
  record$selected$data$method_id <- "ttr_v_over_n_v1"
  expect_error(run_inference(record), "MATTR10 specification")
})

test_that("session preferences cannot silently change the interval method", {
  record <- inference_record()
  old <- emmeans::emm_options()
  on.exit(emmeans::emm_options(old))
  emmeans::emm_options(lmer.df = "asymptotic", disable.pbkrtest = TRUE,
    pbkrtest.limit = 1)
  x <- run_inference(record)
  expect_identical(attr(x$grid@dffun, "mesg"), "kenward-roger")
  expect_true(all(is.finite(x$tables$cells$df)))
  record$model$fit <- lme4::lmer(record$model_formula,
    data = record$selected$data, REML = FALSE)
  expect_error(run_inference(record), "requires a REML fit")
})

test_that("saving preserves inference, original rows and reporting settings", {
  record <- inference_record()
  record$inference <- run_inference(record)
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path))
  saveRDS(record, path)
  saved <- readRDS(path)
  expect_identical(saved$inference$tables, record$inference$tables)
  expect_identical(saved$inference$settings, record$inference$settings)
  expect_identical(saved$inference$diagnostics, record$inference$diagnostics)
  expect_identical(saved$inference$observation_ids, saved$selected$data$observation_id)
  expect_identical(saved$planned, record$planned)
  expect_identical(saved$texts, record$texts)
})
