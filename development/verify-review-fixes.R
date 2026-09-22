# Supplementary independent numerical and batch checks against an installation.
# R_LIBS=/path/to/library Rscript --vanilla development/verify-review-fixes.R
library(ldfreq)
set.seed(20260922)
max_curve_error <- max_D_error <- 0
for (i in seq_len(100L)) {
  N <- sample(50:500, 1)
  frequencies <- as.numeric(table(sample(seq_len(sample(2:100, 1)), N,
    replace = TRUE)))
  tokens <- rep(paste0("t", seq_along(frequencies)), frequencies)
  fit <- lexdiv_metrics(tokens, metrics = "expected_ttr_d")
  sizes <- 35:50
  target <- vapply(sizes, function(n) {
    sum(stats::phyper(0, frequencies, N - frequencies, n,
      lower.tail = FALSE)) / n
  }, numeric(1))
  inverse <- sizes * target^2 / (2 * (1 - target))
  interval <- range(log(inverse))
  independent <- if (diff(interval) < 1e-12) exp(mean(interval)) else {
    exp(stats::optimize(function(log_D) {
      sum((2 / (sqrt(1 + 2 * sizes / exp(log_D)) + 1) - target)^2)
    }, interval = interval, tol = 1e-11)$minimum)
  }
  curve_error <- max(abs(fit$diagnostics[[1]]$expected_ttr - target))
  relative_error <- abs(fit$value / independent - 1)
  stopifnot(fit$status == "ok", curve_error < 1e-12, relative_error < 1e-6)
  max_curve_error <- max(max_curve_error, curve_error)
  max_D_error <- max(max_D_error, relative_error)
}
cat(sprintf("100 independent fits: max curve error %.3g; max relative D error %.3g\n",
  max_curve_error, max_D_error))

verify_batch <- function() {
  calls <- 0L
  invisible(capture.output(trace(".lexres_load_tubelex",
    tracer = function() calls <<- calls + 1L,
    where = asNamespace("ldfreq"), print = FALSE)))
  on.exit(invisible(capture.output(untrace(".lexres_load_tubelex",
    where = asNamespace("ldfreq")))), add = TRUE)
  documents <- stats::setNames(rep(list(c("the", "cat", "book")), 10),
    paste0("document", seq_len(10)))
  single_time <- system.time(single <- lapply(documents, tubelex_profile))[["elapsed"]]
  stopifnot(calls == 10L)
  calls <- 0L
  batch_time <- system.time(batch <- tubelex_profile_batch(documents))[["elapsed"]]
  stopifnot(calls == 1L, identical(single, batch))
  calls <- 0L
  invisible(tubelex_profile_batch(documents))
  stopifnot(calls == 1L) # A new call must load its own verified snapshot.
  calls <- 0L
  stopifnot(inherits(try(tubelex_profile_batch(documents, max_rows = 1),
    silent = TRUE), "try-error"), calls == 0L)
  cat(sprintf("10 documents: separate %.3fs, batch %.3fs; identical full outputs; one load/call\n",
    single_time, batch_time))
}
verify_batch()
sessionInfo()
