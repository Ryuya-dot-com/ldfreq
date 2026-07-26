spec_function <- getFromNamespace("lexdiv_spec", "ldfreq")
grid_function <- getFromNamespace("lexdiv_grid", "ldfreq")
plan_function <- getFromNamespace("lexdiv_plan", "ldfreq")
methods_function <- getFromNamespace("lexdiv_methods", "ldfreq")
presets_function <- getFromNamespace("lexdiv_presets", "ldfreq")
profile_function <- getFromNamespace("lexdiv_profile", "ldfreq")
profile_batch_function <- getFromNamespace("lexdiv_profile_batch", "ldfreq")
screen_function <- getFromNamespace("lexdiv_screen", "ldfreq")
core_function <- getFromNamespace("lexdiv_metrics", "ldfreq")

method_id_for <- function(metric_id) {
  methods <- methods_function()
  methods$method_id[[match(metric_id, methods$metric_id)]]
}

test_that("the v0.1 method and preset registries are bounded and ordered", {
  methods <- methods_function()
  presets <- presets_function()

  expect_identical(
    methods$metric_id,
    c(
      "ttr", "rttr", "cttr", "herdan", "maas", "msttr", "mattr",
      "mtld", "hdd", "yule_k", "yule_i"
    )
  )
  expect_equal(nrow(methods), 11L)
  expect_identical(anyDuplicated(methods$method_id), 0L)
  expect_identical(
    methods$parameter,
    c(
      rep(NA_character_, 5L), "segment_length", "window_length",
      "threshold", "sample_size", NA_character_, NA_character_
    )
  )
  expect_identical(
    methods$default_quality_floor_tokens,
    c(1, 1, 1, 2, 2, 50, 50, 50, 42, 100, 100)
  )
  expect_true(all(vapply(methods$default_parameters, is.list, logical(1L))))
  expect_identical(presets$preset_id, c("canonical", "length_50_100"))
  expect_identical(presets$specification_count, c(11L, 13L))
})

test_that("specs materialize defaults and normalize scalar representations", {
  method_id <- method_id_for("msttr")
  default <- spec_function(method_id)
  integer <- spec_function(method_id, list(segment_length = 50L), "window_a")
  double <- spec_function(method_id, list(segment_length = 50), "window_b")

  expect_s3_class(default, "lexdiv_spec")
  expect_identical(default$parameters, list(segment_length = 50L))
  expect_identical(default$specification_id, integer$specification_id)
  expect_identical(integer$specification_id, double$specification_id)
  expect_identical(integer$identity_key, double$identity_key)
  expect_identical(integer$request_id, "window_a")
  expect_identical(integer$default_quality_floor_tokens, 50)

  expect_error(spec_function("msttr"), "method_id")
  expect_error(spec_function(method_id, list(segment_length = 0)), "segment_length")
  expect_error(spec_function(method_id, list(window_length = 50)), "Unknown parameter")
  expect_error(
    spec_function(method_id, request_id = "not a valid id"),
    "request_id"
  )
  expect_error(
    spec_function(method_id, structure(list(), class = "adversarial")),
    "plain list"
  )
})

test_that("one-dimensional grids preserve order and defer deduplication", {
  method_id <- method_id_for("msttr")
  grid <- grid_function(
    method_id,
    parameter = "segment_length",
    values = c(50L, 100L, 50L),
    request_id_prefix = "msttr_grid"
  )

  expect_s3_class(grid, "lexdiv_grid")
  expect_equal(length(grid), 3L)
  expect_identical(
    vapply(grid, function(x) x$parameters$segment_length, numeric(1L)),
    c(50, 100, 50)
  )
  expect_identical(
    vapply(grid, `[[`, character(1L), "request_id"),
    c("msttr_grid_1", "msttr_grid_2", "msttr_grid_3")
  )
  expect_error(
    grid_function(method_id, "window_length", c(50, 100)),
    "not the user-settable"
  )
  expect_error(
    grid_function(method_id_for("ttr"), "threshold", 0.72),
    "not the user-settable"
  )
  expect_error(grid_function(method_id, "segment_length", numeric()), "non-empty")
  expect_error(
    grid_function(
      method_id,
      "segment_length",
      structure(c(50, 100), names = c("a", "b"))
    ),
    "plain numeric"
  )
  expect_error(
    grid_function(method_id, "segment_length", seq_len(129L)),
    "max_values"
  )
  expect_equal(
    length(grid_function(
      method_id,
      "segment_length",
      seq_len(129L),
      max_values = 129L
    )),
    129L
  )
})

test_that("plans resolve presets, collapse semantic duplicates, and hash order", {
  canonical <- plan_function()
  canonical_again <- plan_function()
  length_plan <- plan_function("length_50_100")
  merged <- plan_function(c("canonical", "length_50_100"))

  expect_s3_class(canonical, "lexdiv_plan")
  expect_equal(length(canonical$specifications), 11L)
  expect_identical(canonical$plan_md5, canonical_again$plan_md5)
  expect_identical(
    vapply(canonical$specifications, `[[`, character(1L), "request_id"),
    c(
      "ttr", "rttr", "cttr", "herdan", "maas", "msttr", "mattr",
      "mtld", "hdd", "yule_k", "yule_i"
    )
  )
  expect_equal(length(length_plan$specifications), 13L)
  expect_equal(length(merged$specifications), 13L)
  expect_identical(
    tail(vapply(length_plan$specifications, `[[`, character(1L), "request_id"), 2L),
    c("msttr_100", "mattr_100")
  )

  msttr_grid <- grid_function(
    method_id_for("msttr"),
    "segment_length",
    c(50, 100)
  )
  augmented <- plan_function(grids = msttr_grid)
  expect_equal(length(augmented$specifications), 12L)
  expect_equal(sum(vapply(
    augmented$specifications,
    function(x) x$metric_id == "msttr",
    logical(1L)
  )), 2L)

  reversed_custom <- plan_function(
    presets = character(),
    specs = rev(augmented$specifications),
    max_specs = 20
  )
  expect_false(identical(augmented$plan_md5, reversed_custom$plan_md5))
})

test_that("draft.5 specification and plan fingerprints are golden", {
  canonical <- plan_function()
  length_plan <- plan_function("length_50_100")

  expect_identical(canonical$plan_md5, "e47650df2045d217af9db701a2154830")
  expect_identical(length_plan$plan_md5, "98f9598072d9ffe9f359f60851056fcd")

  expected <- c(
    msttr_50 = "msttr-730b7112303bbeb5b6720740c4df81be",
    msttr_100 = "msttr-0b6210602feed0f43bd2623f5f3e7ac1",
    mattr_50 = "mattr-03c69eb18487b047d5f0d82dbfa8352c",
    mattr_100 = "mattr-10e30e588dd99f4fd62666c75cd4d74a",
    mtld_072 = "mtld-d4675d20183df0f25f29560f961fb9b2"
  )
  observed <- c(
    msttr_50 = spec_function(
      method_id_for("msttr"), list(segment_length = 50)
    )$specification_id,
    msttr_100 = spec_function(
      method_id_for("msttr"), list(segment_length = 100L)
    )$specification_id,
    mattr_50 = spec_function(
      method_id_for("mattr"), list(window_length = 50L)
    )$specification_id,
    mattr_100 = spec_function(
      method_id_for("mattr"), list(window_length = 100)
    )$specification_id,
    mtld_072 = spec_function(
      method_id_for("mtld"), list(threshold = 0.72)
    )$specification_id
  )
  expect_identical(observed, expected)
})

test_that("plan limits and request IDs fail before computation", {
  grid <- grid_function(
    method_id_for("msttr"),
    "segment_length",
    c(25, 50, 75)
  )
  expect_error(
    plan_function(presets = character(), grids = grid, max_specs = 2),
    "max_specs"
  )
  deduplicated_boundary <- plan_function(
    presets = character(),
    grids = grid_function(
      method_id_for("msttr"),
      "segment_length",
      c(25, 50, 25)
    ),
    max_specs = 2
  )
  expect_equal(length(deduplicated_boundary$specifications), 2L)
  expect_error(
    plan_function(presets = character(), specs = list()),
    "at least one"
  )
  expect_error(plan_function("not_a_preset"), "Unknown preset")
  expect_error(plan_function(c("canonical", "canonical")), "duplicate-free")
  expect_error(
    plan_function(
      specs = structure(list(), adversarial = TRUE)
    ),
    "plain list"
  )

  first <- spec_function(method_id_for("ttr"), request_id = "same")
  second <- spec_function(method_id_for("rttr"), request_id = "same")
  expect_error(
    plan_function(presets = character(), specs = list(first, second)),
    "share a request_id"
  )

  duplicate_candidate <- spec_function(method_id_for("ttr"))
  at_candidate_bound <- plan_function(
    presets = character(),
    specs = rep(list(duplicate_candidate), 1024L),
    max_specs = 1L
  )
  expect_equal(length(at_candidate_bound$specifications), 1L)
  expect_error(
    plan_function(
      presets = character(),
      specs = rep(list(duplicate_candidate), 1025L),
      max_specs = 1L
    ),
    "input-candidate bound"
  )
})

test_that("profile execution rejects tampered plan metadata and shape", {
  plan <- plan_function()

  impossible_bound <- plan
  impossible_bound$max_specs <- 1L
  expect_error(profile_function(c("a"), impossible_bound), "max_specs")

  forged_preset <- plan
  forged_preset$presets <- "forged"
  expect_error(profile_function(c("a"), forged_preset), "presets")

  extra_field <- plan
  extra_field$evil <- TRUE
  expect_error(profile_function(c("a"), extra_field), "unexpected")
})

test_that("canonical profiles preserve core records under a separate envelope", {
  tokens <- rep(c("a", "b", "a", "c", "d"), 24L)
  plan <- plan_function()
  result <- profile_function(tokens, plan)
  core <- core_function(tokens)
  envelope <- c(
    "profile_schema_id", "profile_schema_version", "plan_md5",
    "request_index", "request_id", "specification_id",
    "default_quality_floor_tokens"
  )

  expect_s3_class(result, "lexdiv_profile_results")
  expect_true(inherits(result, "lexdiv_results"))
  expect_identical(names(result), c(envelope, names(core)))
  expect_identical(result$request_index, seq_len(11L))
  expect_identical(result$metric_id, core$metric_id)
  expect_identical(result$method_id, core$method_id)
  expect_equal(result$value, core$value, tolerance = 0)
  expect_identical(result$status, core$status)
  expect_identical(result$missing_reason, core$missing_reason)
  expect_identical(result$N, core$N)
  expect_identical(result$V, core$V)
  for (field in names(core)) {
    expect_identical(result[[field]], core[[field]], info = field)
  }
  expect_identical(
    result$default_quality_floor_tokens,
    c(1, 1, 1, 2, 2, 50, 50, 50, 42, 100, 100)
  )
  expect_true(all(result$profile_schema_id == "lexdiv-r-profile-result"))
  expect_true(all(result$profile_schema_version == "0.1.0-draft.1"))
  expect_true(all(result$plan_md5 == plan$plan_md5))
  expect_identical(attr(result, "plan_md5"), plan$plan_md5)
  expect_identical(attr(result, "contract_id"), attr(core, "contract_id"))
  expect_output(
    print(result[, c("request_id", "metric_id", "value", "status")]),
    "lexdiv_profile_results"
  )
})

test_that("length preset adds settings, not methods or quality-floor variants", {
  tokens <- rep(c("a", "b", "a", "c"), 30L)
  result <- profile_function(tokens, plan_function("length_50_100"))
  msttr <- result[result$metric_id == "msttr", , drop = FALSE]
  mattr <- result[result$metric_id == "mattr", , drop = FALSE]

  expect_equal(nrow(result), 13L)
  expect_equal(nrow(msttr), 2L)
  expect_equal(nrow(mattr), 2L)
  expect_identical(
    vapply(msttr$requested_parameters, `[[`, numeric(1L), "segment_length"),
    c(50, 100)
  )
  expect_identical(
    vapply(mattr$requested_parameters, `[[`, numeric(1L), "window_length"),
    c(50, 100)
  )
  expect_identical(msttr$method_id, rep(method_id_for("msttr"), 2L))
  expect_identical(mattr$method_id, rep(method_id_for("mattr"), 2L))
  expect_identical(msttr$default_quality_floor_tokens, c(50, 50))
  expect_identical(mattr$default_quality_floor_tokens, c(50, 50))
  expect_identical(anyDuplicated(result$specification_id), 0L)
})

test_that("profile requests preserve invalid, empty, and strict-domain rows", {
  plan <- plan_function(
    presets = character(),
    specs = list(
      spec_function(method_id_for("msttr"), list(segment_length = 4)),
      spec_function(method_id_for("hdd"), list(sample_size = 4))
    )
  )
  invalid <- profile_function(c("a", NA_character_), plan)
  empty <- profile_function(character(), plan)
  short <- profile_function(c("a", "b", "c"), plan)

  expect_true(all(invalid$status == "invalid_input"))
  expect_true(all(invalid$missing_reason == "invalid_token"))
  expect_true(all(empty$missing_reason == "empty_input"))
  expect_true(all(short$missing_reason == "too_short_for_requested_parameter"))

  tampered <- plan
  tampered$specifications[[1L]]$parameters$segment_length <- 5
  expect_error(profile_function(c("a"), tampered), "integrity")
})

test_that("profile batches are document-major and equivalent across containers", {
  plan <- plan_function(
    presets = character(),
    specs = list(
      spec_function(method_id_for("ttr"), request_id = "first"),
      spec_function(method_id_for("mtld"), request_id = "second")
    )
  )
  documents <- list(
    doc_b = c("a", "b", "a"),
    doc_a = character(),
    doc_c = c("x", NA_character_)
  )
  frame <- data.frame(document_id = names(documents), stringsAsFactors = FALSE)
  frame$tokens <- unname(documents)

  from_list <- profile_batch_function(documents, plan)
  from_frame <- profile_batch_function(frame, plan)

  expect_identical(from_frame, from_list)
  expect_s3_class(from_list, "lexdiv_profile_batch_results")
  expect_true(inherits(from_list, "lexdiv_batch_results"))
  expect_identical(
    from_list$document_id,
    rep(names(documents), each = 2L)
  )
  expect_identical(from_list$request_id, rep(c("first", "second"), 3L))
  expect_identical(
    names(from_list)[1:3],
    c("document_id", "batch_schema_id", "batch_schema_version")
  )
  expect_true(all(from_list$status[from_list$document_id == "doc_c"] == "invalid_input"))
  expect_output(
    print(from_list[, c("document_id", "request_id", "status")]),
    "lexdiv_profile_batch_results"
  )

  expect_error(
    profile_batch_function(documents, plan, max_rows = 5),
    "max_rows"
  )
  expect_identical(
    profile_batch_function(documents, plan, max_rows = 6),
    from_list
  )
  for (invalid_max_rows in list(0, 1.5, Inf)) {
    expect_error(
      profile_batch_function(documents, plan, max_rows = invalid_max_rows),
      "max_rows"
    )
  }
})

test_that("zero-document profile batches retain the complete typed schema", {
  plan <- plan_function(
    presets = character(),
    specs = spec_function(method_id_for("ttr"))
  )
  empty_list <- setNames(vector("list", 0L), character())
  empty_frame <- data.frame(document_id = character(), stringsAsFactors = FALSE)
  empty_frame$tokens <- vector("list", 0L)

  from_list <- profile_batch_function(empty_list, plan)
  from_frame <- profile_batch_function(empty_frame, plan)

  expect_identical(from_frame, from_list)
  expect_equal(nrow(from_list), 0L)
  expect_s3_class(from_list, "lexdiv_profile_batch_results")
  expect_true(all(c(
    "document_id", "profile_schema_id", "plan_md5", "specification_id",
    "metric_id", "requested_parameters", "diagnostics"
  ) %in% names(from_list)))
  expect_identical(attr(from_list, "plan_md5"), plan$plan_md5)
})

test_that("screening floors never duplicate metric values", {
  plan <- plan_function(
    presets = character(),
    specs = spec_function(
      method_id_for("mtld"),
      list(threshold = 0.72),
      "mtld_primary"
    )
  )
  profile <- profile_function(rep(c("a", "b"), 35L), plan)
  screened <- screen_function(
    profile,
    floors = c(tokens_50 = 50L, tokens_100 = 100L)
  )

  expect_equal(nrow(profile), 1L)
  expect_equal(nrow(screened), 2L)
  expect_false("value" %in% names(screened))
  expect_identical(screened$specification_id, rep(profile$specification_id, 2L))
  expect_identical(screened$screen_id, c("tokens_50", "tokens_100"))
  expect_identical(screened$minimum_tokens, c(50, 100))
  expect_identical(screened$passes_screen, c(TRUE, FALSE))
  expect_s3_class(screened, "lexdiv_screen_results")

  invalid <- profile_function(c("a", NA_character_), plan)
  invalid_screen <- screen_function(invalid, floors = c(tokens_50 = 50L))
  expect_true(is.na(invalid_screen$passes_screen))

  empty <- profile_function(character(), plan)
  empty_screen <- screen_function(empty, floors = c(tokens_50 = 50L))
  expect_identical(empty$status, "missing")
  expect_identical(empty_screen$passes_screen, FALSE)
})

test_that("screening preserves batch IDs and validates named floors", {
  plan <- plan_function(
    presets = character(),
    specs = spec_function(method_id_for("ttr"))
  )
  batch <- profile_batch_function(
    list(a = rep("a", 10L), b = rep("b", 20L)),
    plan
  )
  screened <- screen_function(batch, floors = c(tokens_15 = 15L))

  expect_identical(screened$document_id, c("a", "b"))
  expect_identical(screened$passes_screen, c(FALSE, TRUE))
  expect_false("value" %in% names(screened))
  expect_equal(
    nrow(screen_function(batch, floors = c(tokens_15 = 15L), max_rows = 2L)),
    2L
  )
  expect_error(
    screen_function(batch, floors = c(tokens_15 = 15L), max_rows = 1L),
    "max_rows"
  )
  for (invalid_max_rows in list(0, 1.5, Inf)) {
    expect_error(screen_function(batch, max_rows = invalid_max_rows), "max_rows")
  }
  expect_error(screen_function(batch, floors = c(50, 100)), "named vector")
  expect_error(
    screen_function(batch, floors = c(tokens = 0L)),
    "positive finite"
  )
  expect_error(
    screen_function(batch, floors = c(a = 50L, a = 100L)),
    "unique"
  )
  expect_error(screen_function(data.frame(N = 10)), "profile result")

  forged_n <- batch
  forged_n$N[[1L]] <- -1L
  expect_error(screen_function(forged_n), "invalid N")

  forged_schema <- batch
  forged_schema$profile_schema_id[[1L]] <- "evil"
  expect_error(screen_function(forged_schema), "profile_schema_id")

  forged_batch_schema <- batch
  forged_batch_schema$batch_schema_id[[1L]] <- "evil"
  expect_error(screen_function(forged_batch_schema), "profile-batch envelope")

  forged_method <- batch
  forged_method$method_id[] <- method_id_for("rttr")
  expect_error(screen_function(forged_method), "specification identity")

  inconsistent_group <- batch
  inconsistent_group$request_id[[2L]] <- "different"
  expect_error(screen_function(inconsistent_group), "inconsistent rows")

  stale_plan <- batch
  stale_plan$plan_md5[] <- paste(rep("0", 32L), collapse = "")
  attr(stale_plan, "plan_md5") <- stale_plan$plan_md5[[1L]]
  expect_error(screen_function(stale_plan), "plan fingerprint")

  single <- profile_function(rep("a", 10L), plan)
  single$document_id <- 1
  expect_error(screen_function(single), "profile-batch envelope")
})

test_that("zero-row screens retain schema and never synthesize values", {
  plan <- plan_function(
    presets = character(),
    specs = spec_function(method_id_for("ttr"))
  )
  empty_documents <- setNames(vector("list", 0L), character())
  profile <- profile_batch_function(empty_documents, plan)
  screened <- screen_function(profile)

  expect_equal(nrow(screened), 0L)
  expect_s3_class(screened, "lexdiv_screen_results")
  expect_false("value" %in% names(screened))
  expect_identical(attr(screened, "plan_md5"), plan$plan_md5)
})

test_that("the legacy API remains scalar and schema-compatible", {
  result <- core_function(
    c("a", "a", "b", "c"),
    metrics = c("ttr", "msttr"),
    segment_length = 2
  )
  expect_identical(result$metric_id, c("ttr", "msttr"))
  expect_identical(
    names(result),
    c(
      "metric_id", "method_id", "metric_contract_id",
      "metric_contract_version", "result_schema_id", "result_schema_version",
      "value", "status", "missing_reason", "requested_parameters",
      "effective_parameters", "N", "V", "below_quality_floor", "diagnostics"
    )
  )
  expect_error(
    core_function(c("a", "b"), metrics = "msttr", segment_length = c(1, 2)),
    "segment_length"
  )
})
