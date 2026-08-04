# Offline installed-package smoke test for the exported ldfreq workflows.

tokens <- c("the", "cat", "saw", "the", "other", "cat")
documents <- list(
  document_a = tokens,
  document_b = c("one", "two", "one", "three")
)

single <- lexdiv_metrics(tokens, metrics = c("ttr", "rttr", "yule_k"))
batch <- lexdiv_metrics_batch(documents, metrics = c("ttr", "hdd"), sample_size = 2)

methods <- lexdiv_methods()
mattr_method <- methods$method_id[methods$metric_id == "mattr"]
mattr_4 <- lexdiv_spec(
  mattr_method,
  parameters = list(window_length = 4),
  request_id = "mattr_4"
)
plan <- lexdiv_plan(presets = character(), specs = mattr_4)
profile <- lexdiv_profile(tokens, plan)
profile_batch <- lexdiv_profile_batch(documents, plan)
screen <- lexdiv_screen(profile_batch, floors = c(tokens_4 = 4L))

stopifnot(
  identical(single$status, rep("ok", 3L)),
  nrow(batch) == 4L,
  all(batch$status == "ok"),
  identical(profile$status, "ok"),
  nrow(profile_batch) == 2L,
  all(profile_batch$status == "ok"),
  all(screen$passes_screen)
)

invisible(TRUE)
