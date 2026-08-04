# Internal result and input helpers for the lexical-diversity core.

.lex_contract_id <- "ldfreq-lexical-diversity-core"
.lex_contract_version <- "0.1.0"
.lex_result_schema_id <- "lexdiv-core-metric-result"
.lex_result_schema_version <- "0.1.0"

.lex_missing_reasons <- c(
  "empty_input",
  "invalid_token",
  "insufficient_tokens_for_formula",
  "too_short_for_requested_parameter",
  "zero_denominator",
  "no_factor",
  "non_convergence",
  "boundary_censored",
  "unbounded_high"
)

.lex_input_state <- function(tokens) {
  if (
    !is.character(tokens) ||
      is.object(tokens) ||
      !is.null(dim(tokens))
  ) {
    return("invalid_token")
  }
  if (length(tokens) == 0L) {
    return("empty_input")
  }
  if (
    anyNA(tokens) ||
      any(!nzchar(tokens)) ||
      any(Encoding(tokens) %in% c("bytes", "latin1")) ||
      any(!validUTF8(tokens))
  ) {
    return("invalid_token")
  }
  "ok"
}

.lex_canonicalize_encoding <- function(tokens) {
  if (!is.character(tokens) || is.object(tokens) || !is.null(dim(tokens))) {
    stop("Internal error: encoding canonicalization requires plain character input.", call. = FALSE)
  }
  if (
    anyNA(tokens) ||
      any(Encoding(tokens) %in% c("bytes", "latin1")) ||
      any(!validUTF8(tokens))
  ) {
    stop("Internal error: encoding canonicalization requires valid UTF-8 input.", call. = FALSE)
  }

  # R's equality for an unknown-encoded non-ASCII string can depend on
  # LC_CTYPE. The input contract interprets valid unknown bytes as UTF-8, so
  # mark a local copy before counting. This does not normalize Unicode scalar
  # sequences or mutate the caller's object.
  Encoding(tokens) <- "UTF-8"
  tokens
}

.lex_counts <- function(tokens) {
  if (
    !is.character(tokens) ||
      is.object(tokens) ||
      !is.null(dim(tokens)) ||
      anyNA(tokens) ||
      any(Encoding(tokens) %in% c("bytes", "latin1")) ||
      any(!validUTF8(tokens))
  ) {
    stop(
      "Internal error: counts require a plain valid-UTF-8 character vector.",
      call. = FALSE
    )
  }

  token_count <- length(tokens)
  if (token_count == 0L) {
    return(list(N = 0L, V = 0L, freq = numeric(), M2 = 0))
  }

  tokens <- .lex_canonicalize_encoding(tokens)
  types <- unique(tokens)
  frequencies <- as.double(tabulate(match(tokens, types), nbins = length(types)))
  list(
    N = token_count,
    V = length(types),
    freq = frequencies,
    M2 = sum(frequencies * frequencies)
  )
}

.lex_invalid_counts <- function() {
  list(N = NA_integer_, V = NA_integer_, freq = numeric(), M2 = NA_real_)
}

.lex_scalar_integer <- function(value, name) {
  if (
    length(value) != 1L ||
      !is.numeric(value) ||
      is.na(value) ||
      !is.finite(value) ||
      value < 1 ||
      value != floor(value)
  ) {
    stop(sprintf("%s must be one finite integer greater than or equal to 1.", name), call. = FALSE)
  }
  as.double(value)
}

.lex_scalar_probability <- function(value, name) {
  if (
    length(value) != 1L ||
      !is.numeric(value) ||
      is.na(value) ||
      !is.finite(value) ||
      value <= 0 ||
      value >= 1
  ) {
    stop(sprintf("%s must be one finite number strictly between 0 and 1.", name), call. = FALSE)
  }
  as.double(value)
}

.lex_below_quality_floor <- function(counts, quality_floor_tokens) {
  if (
    length(counts$N) != 1L ||
      is.na(counts$N) ||
      !is.finite(counts$N)
  ) {
    return(NA)
  }
  counts$N < quality_floor_tokens
}

.lex_result <- function(
    metric_id,
    method_id,
    value,
    status,
    missing_reason,
    requested_parameters,
    effective_parameters,
    counts,
    quality_floor_tokens,
    diagnostics) {
  if (!is.list(requested_parameters) || !is.list(effective_parameters)) {
    stop("Internal error: parameter records must be lists.", call. = FALSE)
  }
  if (!is.list(diagnostics)) {
    stop("Internal error: diagnostics must be a list.", call. = FALSE)
  }

  list(
    metric_id = metric_id,
    method_id = method_id,
    value = as.double(value),
    status = status,
    missing_reason = missing_reason,
    requested_parameters = requested_parameters,
    effective_parameters = effective_parameters,
    N = counts$N,
    V = counts$V,
    below_quality_floor = .lex_below_quality_floor(counts, quality_floor_tokens),
    diagnostics = diagnostics
  )
}

.lex_ok <- function(
    metric_id,
    method_id,
    value,
    requested_parameters = list(),
    effective_parameters = requested_parameters,
    counts,
    quality_floor_tokens,
    diagnostics = list()) {
  if (
    length(value) != 1L ||
      !is.numeric(value) ||
      is.na(value) ||
      !is.finite(value)
  ) {
    stop("Internal error: an ok metric result must be one finite number.", call. = FALSE)
  }
  .lex_result(
    metric_id = metric_id,
    method_id = method_id,
    value = value,
    status = "ok",
    missing_reason = NA_character_,
    requested_parameters = requested_parameters,
    effective_parameters = effective_parameters,
    counts = counts,
    quality_floor_tokens = quality_floor_tokens,
    diagnostics = diagnostics
  )
}

.lex_missing <- function(
    metric_id,
    method_id,
    missing_reason,
    requested_parameters = list(),
    effective_parameters = list(),
    counts,
    quality_floor_tokens,
    diagnostics = list(),
    status = "missing") {
  if (
    length(missing_reason) != 1L ||
      is.na(missing_reason) ||
      !(missing_reason %in% .lex_missing_reasons)
  ) {
    stop("Internal error: unknown missing reason.", call. = FALSE)
  }
  if (!(status %in% c("missing", "invalid_input"))) {
    stop("Internal error: invalid non-ok status.", call. = FALSE)
  }
  .lex_result(
    metric_id = metric_id,
    method_id = method_id,
    value = NA_real_,
    status = status,
    missing_reason = missing_reason,
    requested_parameters = requested_parameters,
    effective_parameters = effective_parameters,
    counts = counts,
    quality_floor_tokens = quality_floor_tokens,
    diagnostics = diagnostics
  )
}

.lex_records_data_frame <- function(records) {
  if (length(records) == 0L) {
    stop("Internal error: at least one metric record is required.", call. = FALSE)
  }

  output <- data.frame(
    metric_id = vapply(records, `[[`, character(1L), "metric_id"),
    method_id = vapply(records, `[[`, character(1L), "method_id"),
    metric_contract_id = rep.int(.lex_contract_id, length(records)),
    metric_contract_version = rep.int(.lex_contract_version, length(records)),
    result_schema_id = rep.int(.lex_result_schema_id, length(records)),
    result_schema_version = rep.int(.lex_result_schema_version, length(records)),
    value = vapply(records, `[[`, numeric(1L), "value"),
    status = vapply(records, `[[`, character(1L), "status"),
    missing_reason = vapply(records, `[[`, character(1L), "missing_reason"),
    N = vapply(records, function(record) as.double(record$N), numeric(1L)),
    V = vapply(records, function(record) as.double(record$V), numeric(1L)),
    below_quality_floor = vapply(
      records,
      function(record) as.logical(record$below_quality_floor),
      logical(1L)
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  output$requested_parameters <- I(lapply(records, `[[`, "requested_parameters"))
  output$effective_parameters <- I(lapply(records, `[[`, "effective_parameters"))
  output$diagnostics <- I(lapply(records, `[[`, "diagnostics"))
  output <- output[c(
    "metric_id", "method_id", "metric_contract_id",
    "metric_contract_version", "result_schema_id", "result_schema_version",
    "value", "status",
    "missing_reason",
    "requested_parameters", "effective_parameters", "N", "V",
    "below_quality_floor", "diagnostics"
  )]
  class(output) <- c("lexdiv_results", "data.frame")
  attr(output, "contract_id") <- .lex_contract_id
  attr(output, "contract_version") <- .lex_contract_version
  attr(output, "result_schema_id") <- .lex_result_schema_id
  attr(output, "result_schema_version") <- .lex_result_schema_version
  output
}

#' @export
print.lexdiv_results <- function(x, ...) {
  cat(sprintf(
    "<lexdiv_results: %d metric%s; contract %s>\n",
    nrow(x),
    if (nrow(x) == 1L) "" else "s",
    attr(x, "contract_version", exact = TRUE)
  ))
  visible <- x[c(
    "metric_id", "value", "status", "missing_reason", "N", "V",
    "below_quality_floor"
  )]
  print.data.frame(visible, ...)
  invisible(x)
}
