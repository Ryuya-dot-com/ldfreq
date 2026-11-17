# Public orchestration for the versioned lexical-diversity metric set.

.lex_metric_registry <- list(
  ttr = list(
    method_id = "ttr_v_over_n_v1",
    quality_floor_tokens = 1,
    function_name = ".metric_ttr"
  ),
  rttr = list(
    method_id = "rttr_guiraud_v_over_sqrt_n_v1",
    quality_floor_tokens = 1,
    function_name = ".metric_rttr"
  ),
  cttr = list(
    method_id = "cttr_v_over_sqrt_2n_v1",
    quality_floor_tokens = 1,
    function_name = ".metric_cttr"
  ),
  herdan = list(
    method_id = "herdan_c_logv_over_logn_v1",
    quality_floor_tokens = 2,
    function_name = ".metric_herdan"
  ),
  maas = list(
    method_id = "maas_a2_ln_v1",
    quality_floor_tokens = 2,
    function_name = ".metric_maas"
  ),
  msttr = list(
    method_id = "msttr_nonoverlap_complete_drop_v1",
    quality_floor_tokens = 50,
    function_name = ".metric_msttr"
  ),
  mattr = list(
    method_id = "mattr_sliding_step1_v1",
    quality_floor_tokens = 50,
    function_name = ".metric_mattr"
  ),
  mtld = list(
    method_id = "mtld_seq_bidir_dirmean_lt_nomin_linear_tail_v1",
    quality_floor_tokens = 50,
    function_name = ".metric_mtld",
    unavailable_diagnostics_name = ".mtld_unavailable_diagnostics"
  ),
  mtld_ma = list(
    method_id = "mtld_ma_forward_lt_min10_step1_complete_v1",
    quality_floor_tokens = 50,
    function_name = ".metric_mtld_ma",
    unavailable_diagnostics_name = ".mtld_ma_unavailable_diagnostics"
  ),
  hdd = list(
    method_id = "hdd_expected_ttr_scaled_v1",
    quality_floor_tokens = 42,
    function_name = ".metric_hdd"
  ),
  expected_ttr_d = list(
    method_id = "expected_ttr_d_hypergeom_fit_v1",
    quality_floor_tokens = 50,
    function_name = ".metric_expected_ttr_d",
    unavailable_diagnostics_name = ".expected_ttr_d_unavailable_diagnostics"
  ),
  yule_k = list(
    method_id = "yule_k_m2_tokens_v1",
    quality_floor_tokens = 100,
    function_name = ".metric_yule_k"
  ),
  yule_i = list(
    method_id = "yule_i_types_v2_over_m2_minus_v_v1",
    quality_floor_tokens = 100,
    function_name = ".metric_yule_i"
  )
)

#' Versioned lexical-diversity metric identifiers
#'
#' Returns the metric identifiers admitted to the current core implementation.
#' The deterministic `expected_ttr_d` method fits a D curve to exact
#' finite-population expected TTR values. It is not CLAN VOCD.
#'
#' @return All supported identifiers in registry order, including experimental
#'   `expected_ttr_d` and opt-in `mtld_ma`, both excluded from default computations.
#' @export
lexdiv_metric_ids <- function() {
  names(.lex_metric_registry)
}

.lex_requested_parameters <- function(
    metric_id,
    segment_length,
    window_length,
    mtld_threshold,
    sample_size,
    expected_ttr_sample_sizes) {
  switch(
    metric_id,
    msttr = list(segment_length = segment_length),
    mattr = list(window_length = window_length),
    mtld = list(threshold = mtld_threshold),
    mtld_ma = list(threshold = mtld_threshold),
    hdd = list(sample_size = sample_size),
    expected_ttr_d = list(sample_sizes = expected_ttr_sample_sizes),
    list()
  )
}

.lex_validate_requested_parameters <- function(metric_id, parameters) {
  switch(
    metric_id,
    msttr = .basic_positive_integer_parameter(
      parameters,
      "segment_length",
      50L
    ),
    mattr = .basic_positive_integer_parameter(
      parameters,
      "window_length",
      50L
    ),
    mtld = .mtld_parameters(parameters),
    mtld_ma = .mtld_parameters(parameters),
    hdd = .hdd_sample_size(parameters),
    expected_ttr_d = .expected_ttr_d_sample_sizes(parameters),
    .basic_empty_parameters(parameters)
  )
  invisible(NULL)
}

.lex_generic_non_ok_record <- function(metric_id, reason, status, counts, parameters) {
  specification <- .lex_metric_registry[[metric_id]]
  diagnostics <- if (is.null(specification$unavailable_diagnostics_name)) {
    list()
  } else {
    get(
      specification$unavailable_diagnostics_name,
      mode = "function",
      inherits = TRUE
    )()
  }
  .lex_missing(
    metric_id = metric_id,
    method_id = specification$method_id,
    missing_reason = reason,
    requested_parameters = parameters,
    effective_parameters = list(),
    counts = counts,
    quality_floor_tokens = specification$quality_floor_tokens,
    diagnostics = diagnostics,
    status = status
  )
}

.lex_is_tokenization_batch <- function(x) {
  inherits(x, "lexdiv_tokenization_batch") ||
    (is.list(x) && !is.data.frame(x) && length(x) > 0L &&
      !is.null(names(x)) &&
      all(vapply(x, inherits, logical(1L), "lexdiv_tokenization")))
}

.lexdiv_extract_tokenization_terms <- function(tokenization, term_col) {
  .lexprep_validate_tokenization(tokenization)
  columns <- .lex_batch_column_names(names(tokenization$tokens))
  matches <- which(columns == term_col)
  if (length(matches) != 1L) {
    stop(
      sprintf("term_col (%s) was not found in tokenization$tokens.", term_col),
      call. = FALSE
    )
  }
  values <- .subset2(tokenization$tokens, matches)
  if (!is.character(values) || is.object(values) || !is.null(dim(values))) {
    stop(
      sprintf("Selected tokenization column %s must be a plain character vector.", term_col),
      call. = FALSE
    )
  }
  keep <- if ("is_word" %in% names(tokenization$tokens)) {
    tokenization$tokens$is_word %in% TRUE
  } else {
    !is.na(values)
  }
  unname(values[keep])
}

.lexdiv_metrics_single <- function(
    tokens,
    metrics = setdiff(lexdiv_metric_ids(), c("expected_ttr_d", "mtld_ma")),
    segment_length = 50L,
    window_length = 50L,
    mtld_threshold = 0.72,
    sample_size = 42L,
    expected_ttr_sample_sizes = 35:50,
    plan = NULL,
    metrics_supplied = !missing(metrics),
    segment_supplied = !missing(segment_length),
    window_supplied = !missing(window_length),
    mtld_supplied = !missing(mtld_threshold),
    sample_supplied = !missing(sample_size),
    expected_supplied = !missing(expected_ttr_sample_sizes)) {
  if (!is.null(plan)) {
    if (metrics_supplied || segment_supplied || window_supplied ||
        mtld_supplied || sample_supplied || expected_supplied) {
      stop("With plan, omit metrics and individual metric parameters.", call. = FALSE)
    }
    return(.lexdiv_profile(tokens, plan = plan))
  }

  if (
    !is.character(metrics) ||
      is.object(metrics) ||
      !is.null(dim(metrics)) ||
      length(metrics) == 0L ||
      anyNA(metrics) ||
      any(!nzchar(metrics))
  ) {
    stop("metrics must be a non-empty character vector without missing values.", call. = FALSE)
  }
  if (anyDuplicated(metrics)) {
    stop("metrics must not contain duplicates.", call. = FALSE)
  }
  unknown <- setdiff(metrics, lexdiv_metric_ids())
  if (length(unknown) > 0L) {
    stop(
      sprintf(
        paste0(
          "Unknown metric ID(s): %s. ",
          "Use lexdiv_metric_ids() to list valid metric IDs."
        ),
        paste(unknown, collapse = ", ")
      ),
      call. = FALSE
    )
  }

  parameters_by_metric <- lapply(metrics, function(metric_id) {
    .lex_requested_parameters(
      metric_id = metric_id,
      segment_length = segment_length,
      window_length = window_length,
      mtld_threshold = mtld_threshold,
      sample_size = sample_size,
      expected_ttr_sample_sizes = expected_ttr_sample_sizes
    )
  })
  for (index in seq_along(metrics)) {
    .lex_validate_requested_parameters(
      metric_id = metrics[[index]],
      parameters = parameters_by_metric[[index]]
    )
  }

  .lex_warn_likely_raw_text(
    tokens,
    "x",
    "lexdiv_metrics",
    "use lexdiv_metrics_text() instead"
  )

  input_state <- .lex_input_state(tokens)
  if (identical(input_state, "ok")) {
    tokens <- .lex_canonicalize_encoding(tokens)
  }
  counts <- if (identical(input_state, "invalid_token")) {
    .lex_invalid_counts()
  } else {
    .lex_counts(tokens)
  }

  records <- lapply(seq_along(metrics), function(index) {
    metric_id <- metrics[[index]]
    parameters <- parameters_by_metric[[index]]

    if (identical(input_state, "invalid_token")) {
      return(.lex_generic_non_ok_record(
        metric_id = metric_id,
        reason = "invalid_token",
        status = "invalid_input",
        counts = counts,
        parameters = parameters
      ))
    }
    if (identical(input_state, "empty_input")) {
      return(.lex_generic_non_ok_record(
        metric_id = metric_id,
        reason = "empty_input",
        status = "missing",
        counts = counts,
        parameters = parameters
      ))
    }

    function_name <- .lex_metric_registry[[metric_id]]$function_name
    metric_function <- get(function_name, mode = "function", inherits = TRUE)
    metric_function(tokens = tokens, counts = counts, parameters = parameters)
  })

  .lex_records_data_frame(records)
}

#' Compute versioned lexical-diversity metrics for one or more tokenized documents
#'
#' Computes one or more explicitly versioned lexical-diversity variants from a
#' single document (an ordered character vector or `lexdiv_tokenization` object)
#' or multiple documents (a plain named list of token vectors, a
#' `lexdiv_tokenization_batch` object, or a data frame with `id_col` and a
#' list-column selected by `term_col`). The core performs no case conversion,
#' Unicode normalization, token deletion, or lemmatization.
#'
#' @param x For a single document, a plain one-dimensional character vector of
#'   ordered, already-tokenized strings (or a `lexdiv_tokenization` object).
#'   For multiple documents, a plain named list of token vectors, a
#'   `lexdiv_tokenization_batch` object, or a data frame with the columns
#'   selected by `id_col` and `term_col`. `NA`, empty strings, invalid UTF-8,
#'   and strings marked `bytes` or `latin1` make a document invalid. A
#'   zero-length character vector is an empty document. Use
#'   [lexdiv_metrics_text()] for raw text.
#' @param metrics Plain, non-empty, duplicate-free character vector selected
#'   from [lexdiv_metric_ids()]. The default excludes experimental `expected_ttr_d` and opt-in `mtld_ma`.
#' @param segment_length Requested complete non-overlapping segment length for
#'   MSTTR. It is never reduced to the document length.
#' @param window_length Requested step-one window length for MATTR. It is never
#'   reduced to the document length.
#' @param mtld_threshold MTLD TTR threshold strictly between zero and one. The
#'   defined comparator is strict `<`, with no minimum complete-factor length.
#' @param sample_size Requested without-replacement sample size for HD-D. It is
#'   never reduced to the document length.
#' @param expected_ttr_sample_sizes Strictly increasing sample sizes used by
#'   the deterministic expected-TTR D curve fit. They are never reduced to the
#'   document length. This experimental estimator uses no random sampling and
#'   is not CLAN VOCD; empirical equivalence to published vocd-D is untested.
#' @param plan Optional normalized plan from [lexdiv_plan()]. When supplied,
#'   do not also supply `metrics` or individual metric parameters. The plan
#'   fixes all method requests and their order.
#' @param id_col Name of the explicit document-ID column for multi-document
#'   data-frame input.
#' @param term_col Name of the token list-column for multi-document data-frame
#'   input (default `"tokens"`), or the word-token column to extract when `x` is
#'   a `lexdiv_tokenization` or `lexdiv_tokenization_batch` object (defaults to
#'   `"term"` when omitted).
#' @param max_rows Maximum document-by-specification rows when `plan` is
#'   supplied for multi-document input.
#'
#' @return For a single document, a `lexdiv_results` data frame (or
#'   `lexdiv_profile_results` with `plan`). For multiple documents, a long-form
#'   `lexdiv_batch_results` data frame (or `lexdiv_profile_batch_results` with
#'   `plan`) ordered by document and then requested metric. Invalid and empty
#'   documents return structured rows rather than throwing; structural API
#'   errors still throw. Read `status` and `missing_reason` before interpreting
#'   `value`.
#' @export
lexdiv_metrics <- function(
    x,
    metrics = setdiff(lexdiv_metric_ids(), c("expected_ttr_d", "mtld_ma")),
    segment_length = 50L,
    window_length = 50L,
    mtld_threshold = 0.72,
    sample_size = 42L,
    expected_ttr_sample_sizes = 35:50,
    plan = NULL,
    id_col = "document_id",
    term_col = "tokens",
    max_rows = 1e6) {
  metrics_supplied <- !missing(metrics)
  segment_supplied <- !missing(segment_length)
  window_supplied <- !missing(window_length)
  mtld_supplied <- !missing(mtld_threshold)
  sample_supplied <- !missing(sample_size)
  expected_supplied <- !missing(expected_ttr_sample_sizes)
  any_metric_arg <- metrics_supplied || segment_supplied || window_supplied ||
    mtld_supplied || sample_supplied || expected_supplied

  if (inherits(x, "lexdiv_tokenization")) {
    if (!missing(id_col) || !missing(max_rows)) {
      stop("id_col and max_rows apply only to multi-document inputs.", call. = FALSE)
    }
    tok_col <- if (missing(term_col)) "surface" else .lex_batch_scalar_name(term_col, "term_col")
    tokens <- .lexdiv_extract_tokenization_terms(x, tok_col)
    return(.lexdiv_metrics_single(
      tokens = tokens,
      metrics = metrics,
      segment_length = segment_length,
      window_length = window_length,
      mtld_threshold = mtld_threshold,
      sample_size = sample_size,
      expected_ttr_sample_sizes = expected_ttr_sample_sizes,
      plan = plan,
      metrics_supplied = metrics_supplied,
      segment_supplied = segment_supplied,
      window_supplied = window_supplied,
      mtld_supplied = mtld_supplied,
      sample_supplied = sample_supplied,
      expected_supplied = expected_supplied
    ))
  }

  if (.lex_is_tokenization_batch(x) || is.data.frame(x) || is.list(x)) {
    batch_call <- list(
      documents = x,
      id_col = id_col,
      term_col = if (.lex_is_tokenization_batch(x) && missing(term_col)) "surface" else term_col,
      plan = plan
    )
    if (!missing(max_rows)) {
      batch_call$max_rows <- max_rows
    }
    if (is.null(plan)) {
      if (metrics_supplied) batch_call$metrics <- metrics
      if (segment_supplied) batch_call$segment_length <- segment_length
      if (window_supplied) batch_call$window_length <- window_length
      if (mtld_supplied) batch_call$mtld_threshold <- mtld_threshold
      if (sample_supplied) batch_call$sample_size <- sample_size
      if (expected_supplied) batch_call$expected_ttr_sample_sizes <- expected_ttr_sample_sizes
    } else if (any_metric_arg) {
      stop("With plan, omit metrics and individual metric parameters.", call. = FALSE)
    }
    return(do.call(.lexdiv_metrics_batch, batch_call))
  }

  if (!missing(id_col) || !missing(term_col) || !missing(max_rows)) {
    stop("id_col, term_col, and max_rows apply only to multi-document inputs.", call. = FALSE)
  }

  .lexdiv_metrics_single(
    tokens = x,
    metrics = metrics,
    segment_length = segment_length,
    window_length = window_length,
    mtld_threshold = mtld_threshold,
    sample_size = sample_size,
    expected_ttr_sample_sizes = expected_ttr_sample_sizes,
    plan = plan,
    metrics_supplied = metrics_supplied,
    segment_supplied = segment_supplied,
    window_supplied = window_supplied,
    mtld_supplied = mtld_supplied,
    sample_supplied = sample_supplied,
    expected_supplied = expected_supplied
  )
}
