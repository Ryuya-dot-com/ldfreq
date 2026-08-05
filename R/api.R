# Public orchestration for the frozen lexical-diversity metric set.

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
    method_id = "mtld_seq_bidir_dirmean_lt_min10_linear_tail_v1",
    quality_floor_tokens = 50,
    function_name = ".metric_mtld",
    unavailable_diagnostics_name = ".mtld_unavailable_diagnostics"
  ),
  hdd = list(
    method_id = "hdd_expected_ttr_scaled_v1",
    quality_floor_tokens = 42,
    function_name = ".metric_hdd"
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

#' Frozen lexical-diversity metric identifiers
#'
#' Returns the metric identifiers admitted to the current core implementation.
#' The deferred `expected_ttr_d` candidate is deliberately absent from v0.1.
#'
#' @return A character vector in the default result order.
#' @export
lexdiv_metric_ids <- function() {
  names(.lex_metric_registry)
}

.lex_requested_parameters <- function(
    metric_id,
    segment_length,
    window_length,
    mtld_threshold,
    sample_size) {
  switch(
    metric_id,
    msttr = list(segment_length = segment_length),
    mattr = list(window_length = window_length),
    mtld = list(threshold = mtld_threshold),
    hdd = list(sample_size = sample_size),
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
    hdd = .hdd_sample_size(parameters),
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

#' Compute frozen lexical-diversity metrics from pre-tokenized input
#'
#' Computes one or more explicitly versioned lexical-diversity variants from an
#' ordered character vector. The core performs no case conversion, Unicode
#' normalization, token deletion, or lemmatization.
#'
#' @param tokens Plain, unclassed, one-dimensional character vector of ordered,
#'   already-tokenized strings. `NA`, empty strings, invalid UTF-8, and strings
#'   marked `bytes` or `latin1` make the whole document invalid. A zero-length
#'   character vector is an empty document. Valid non-ASCII strings whose
#'   encoding marker is unknown are interpreted as UTF-8 on a local copy.
#' @param metrics Plain, non-empty, duplicate-free character vector selected
#'   from [lexdiv_metric_ids()].
#' @param segment_length Requested complete non-overlapping segment length for
#'   MSTTR. It is never reduced to the document length.
#' @param window_length Requested step-one window length for MATTR. It is never
#'   reduced to the document length.
#' @param mtld_threshold MTLD TTR threshold strictly between zero and one. The
#'   frozen comparator is strict `<`, with a minimum complete-factor length of 10.
#' @param sample_size Requested without-replacement sample size for HD-D. It is
#'   never reduced to the document length.
#'
#' @return A `lexdiv_results` data frame with one row per requested metric and
#'   list-columns for requested/effective parameters and diagnostics. Metric
#'   contract identity and result-schema version are explicit columns as well
#'   as convenience attributes. Invalid and empty documents return structured
#'   rows rather than throwing; structural API errors still throw. Read
#'   `status` and `missing_reason` before interpreting `value`: `ok` means a
#'   value was computed, `missing` means the valid input did not meet a method
#'   domain, and `invalid_input` means the token document was invalid.
#' @export
lexdiv_metrics <- function(
    tokens,
    metrics = lexdiv_metric_ids(),
    segment_length = 50L,
    window_length = 50L,
    mtld_threshold = 0.72,
    sample_size = 42L) {
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
        "Unknown or non-frozen metric ID(s): %s.",
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
      sample_size = sample_size
    )
  })
  for (index in seq_along(metrics)) {
    .lex_validate_requested_parameters(
      metric_id = metrics[[index]],
      parameters = parameters_by_metric[[index]]
    )
  }

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
