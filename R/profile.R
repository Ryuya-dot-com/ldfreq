# Bounded request-plan and profile layer for the frozen v0.1 method set.

.lex_profile_schema_id <- "lexdiv-r-profile-result"
.lex_profile_schema_version <- "0.1.0-draft.1"
.lex_plan_schema_id <- "lexdiv-r-request-plan"
.lex_plan_schema_version <- "0.1.0-draft.1"
.lex_screen_schema_id <- "lexdiv-r-screen-result"
.lex_screen_schema_version <- "0.1.0-draft.1"
.lex_plan_max_candidates <- 1024L

.profile_scalar_identifier <- function(value, argument, allow_null = FALSE) {
  if (allow_null && is.null(value)) {
    return(NULL)
  }
  if (
    !is.character(value) ||
      is.object(value) ||
      !is.null(dim(value)) ||
      !is.null(attributes(value)) ||
      length(value) != 1L ||
      is.na(value) ||
      !nzchar(value) ||
      Encoding(value) %in% c("bytes", "latin1") ||
      !validUTF8(value) ||
      !grepl("^[A-Za-z][A-Za-z0-9._-]*$", value)
  ) {
    stop(
      sprintf(
        "%s must be one plain ASCII identifier beginning with a letter.",
        argument
      ),
      call. = FALSE
    )
  }
  value
}

.profile_positive_integer <- function(value, argument) {
  if (
    !is.numeric(value) ||
      is.object(value) ||
      !is.null(dim(value)) ||
      !is.null(attributes(value)) ||
      length(value) != 1L ||
      is.na(value) ||
      !is.finite(value) ||
      value < 1 ||
      value != floor(value)
  ) {
    stop(
      sprintf("%s must be one plain finite integer greater than or equal to 1.", argument),
      call. = FALSE
    )
  }
  as.double(value)
}

.profile_canonical_integer <- function(value) {
  if (value <= .Machine$integer.max) {
    return(as.integer(value))
  }
  as.double(value)
}

.profile_plain_list <- function(value, argument) {
  attribute_names <- names(attributes(value))
  valid_attributes <- is.null(attribute_names) ||
    identical(attribute_names, "names")
  if (
    !is.list(value) ||
      is.object(value) ||
      !is.null(dim(value)) ||
      !valid_attributes
  ) {
    stop(sprintf("%s must be a plain list.", argument), call. = FALSE)
  }
  value
}

.profile_plain_parameter_list <- function(parameters) {
  attribute_names <- names(attributes(parameters))
  valid_attributes <- is.null(attribute_names) ||
    identical(attribute_names, "names")
  if (
    !is.list(parameters) ||
      is.object(parameters) ||
      !is.null(dim(parameters)) ||
      !valid_attributes
  ) {
    stop("parameters must be a plain list.", call. = FALSE)
  }
  parameters
}

.profile_method_definitions <- function() {
  metric_ids <- names(.lex_metric_registry)
  methods <- lapply(metric_ids, function(metric_id) {
    parameter <- switch(
      metric_id,
      msttr = "segment_length",
      mattr = "window_length",
      mtld = "threshold",
      hdd = "sample_size",
      NA_character_
    )
    default_parameters <- switch(
      metric_id,
      msttr = list(segment_length = 50L),
      mattr = list(window_length = 50L),
      mtld = list(threshold = 0.72),
      hdd = list(sample_size = 42L),
      list()
    )
    list(
      metric_id = metric_id,
      method_id = .lex_metric_registry[[metric_id]]$method_id,
      parameter = parameter,
      default_parameters = default_parameters,
      default_quality_floor_tokens = as.double(
        .lex_metric_registry[[metric_id]]$quality_floor_tokens
      )
    )
  })
  method_ids <- vapply(methods, `[[`, character(1L), "method_id")
  if (anyDuplicated(method_ids)) {
    stop("Internal error: frozen method IDs must be unique.", call. = FALSE)
  }
  methods
}

.profile_method <- function(method_id) {
  method_id <- .profile_scalar_identifier(method_id, "method_id")
  methods <- .profile_method_definitions()
  method_ids <- vapply(methods, `[[`, character(1L), "method_id")
  index <- match(method_id, method_ids)
  if (is.na(index)) {
    stop(sprintf("Unknown or non-frozen method_id: %s.", method_id), call. = FALSE)
  }
  methods[[index]]
}

.profile_normalize_parameters <- function(metric_id, parameters) {
  parameters <- .profile_plain_parameter_list(parameters)
  .lex_validate_requested_parameters(metric_id, parameters)
  switch(
    metric_id,
    msttr = list(segment_length = .profile_canonical_integer(
      .basic_positive_integer_parameter(parameters, "segment_length", 50L)
    )),
    mattr = list(window_length = .profile_canonical_integer(
      .basic_positive_integer_parameter(parameters, "window_length", 50L)
    )),
    mtld = .mtld_parameters(parameters),
    hdd = list(sample_size = .profile_canonical_integer(
      .hdd_sample_size(parameters)
    )),
    .basic_empty_parameters(parameters)
  )
}

.profile_parameter_text <- function(parameters) {
  if (length(parameters) == 0L) {
    return("{}")
  }
  pieces <- vapply(names(parameters), function(parameter_name) {
    value <- parameters[[parameter_name]]
    if (!is.numeric(value) || length(value) != 1L || !is.finite(value)) {
      stop("Internal error: v0.1 plan parameters must be finite numeric scalars.", call. = FALSE)
    }
    paste0(parameter_name, "=", sprintf("%a", as.double(value)))
  }, character(1L))
  paste0("{", paste(pieces, collapse = ";"), "}")
}

.profile_md5_text <- function(value) {
  if (!is.character(value) || length(value) != 1L || is.na(value)) {
    stop("Internal error: MD5 input must be one character string.", call. = FALSE)
  }
  path <- tempfile(pattern = "lexdiv-plan-md5-")
  on.exit(unlink(path, force = TRUE), add = TRUE)
  writeBin(charToRaw(enc2utf8(value)), path)
  unname(as.character(tools::md5sum(path)[[1L]]))
}

.profile_specification_key <- function(method_id, parameters) {
  paste(
    .lex_contract_id,
    .lex_contract_version,
    method_id,
    .profile_parameter_text(parameters),
    sep = "|"
  )
}

#' Describe one frozen method and one normalized parameter setting
#'
#' @param method_id One method identifier returned by [lexdiv_methods()].
#' @param parameters A plain named list of method-local parameters. Omitted
#'   values are materialized from the frozen defaults.
#' @param request_id Optional ASCII identifier used to join profile rows.
#'
#' @return A normalized `lexdiv_spec` object.
#' @export
lexdiv_spec <- function(method_id, parameters = list(), request_id = NULL) {
  method <- .profile_method(method_id)
  request_id <- .profile_scalar_identifier(
    request_id,
    "request_id",
    allow_null = TRUE
  )
  parameters <- .profile_normalize_parameters(method$metric_id, parameters)
  identity_key <- .profile_specification_key(method$method_id, parameters)
  specification_id <- paste0(
    method$metric_id,
    "-",
    .profile_md5_text(identity_key)
  )
  structure(
    list(
      request_id = request_id,
      specification_id = specification_id,
      metric_id = method$metric_id,
      method_id = method$method_id,
      parameters = parameters,
      default_quality_floor_tokens = method$default_quality_floor_tokens,
      identity_key = identity_key
    ),
    class = c("lexdiv_spec", "list")
  )
}

#' Expand one scalar parameter of one frozen method
#'
#' @param method_id One frozen method identifier.
#' @param parameter The method's single user-settable parameter name.
#' @param values A non-empty numeric vector. Each element becomes one spec.
#' @param request_id_prefix Optional ASCII prefix; generated IDs append the
#'   one-based value position.
#' @param max_values Maximum values expanded eagerly by this grid call. Raise
#'   it explicitly only when the corresponding allocation is intentional.
#'
#' @return A `lexdiv_grid`, represented as an ordered list of specs.
#' @export
lexdiv_grid <- function(
    method_id,
    parameter,
    values,
    request_id_prefix = NULL,
    max_values = 128L) {
  method <- .profile_method(method_id)
  parameter <- .profile_scalar_identifier(parameter, "parameter")
  request_id_prefix <- .profile_scalar_identifier(
    request_id_prefix,
    "request_id_prefix",
    allow_null = TRUE
  )
  max_values <- .profile_positive_integer(max_values, "max_values")
  if (is.na(method$parameter) || !identical(parameter, method$parameter)) {
    stop(
      sprintf("parameter is not the user-settable parameter for %s.", method$method_id),
      call. = FALSE
    )
  }
  if (
    !is.numeric(values) ||
      is.object(values) ||
      !is.null(dim(values)) ||
      !is.null(attributes(values)) ||
      length(values) == 0L
  ) {
    stop("values must be a non-empty plain numeric vector.", call. = FALSE)
  }
  if (length(values) > max_values) {
    stop(
      sprintf("The grid exceeds max_values (%s).", format(max_values)),
      call. = FALSE
    )
  }

  specifications <- lapply(seq_along(values), function(index) {
    request_id <- if (is.null(request_id_prefix)) {
      NULL
    } else {
      paste0(request_id_prefix, "_", index)
    }
    parameters <- list(values[[index]])
    names(parameters) <- parameter
    lexdiv_spec(
      method_id = method$method_id,
      parameters = parameters,
      request_id = request_id
    )
  })
  structure(specifications, class = c("lexdiv_grid", "list"))
}

.profile_canonical_specs <- function() {
  methods <- .profile_method_definitions()
  lapply(methods, function(method) {
    lexdiv_spec(
      method_id = method$method_id,
      parameters = method$default_parameters,
      request_id = method$metric_id
    )
  })
}

.profile_preset_specs <- function(preset_id) {
  canonical <- .profile_canonical_specs()
  if (identical(preset_id, "canonical")) {
    return(canonical)
  }
  if (identical(preset_id, "length_50_100")) {
    methods <- .profile_method_definitions()
    method_by_metric <- vapply(methods, `[[`, character(1L), "method_id")
    names(method_by_metric) <- vapply(
      methods,
      `[[`,
      character(1L),
      "metric_id"
    )
    return(c(
      canonical,
      list(
        lexdiv_spec(
          method_by_metric[["msttr"]],
          list(segment_length = 100L),
          "msttr_100"
        ),
        lexdiv_spec(
          method_by_metric[["mattr"]],
          list(window_length = 100L),
          "mattr_100"
        )
      )
    ))
  }
  stop(sprintf("Unknown preset: %s.", preset_id), call. = FALSE)
}

.profile_specs_argument <- function(specs) {
  if (inherits(specs, "lexdiv_spec")) {
    return(list(specs))
  }
  specs <- .profile_plain_list(specs, "specs")
  if (length(specs) > 0L && !all(vapply(specs, inherits, logical(1L), "lexdiv_spec"))) {
    stop("Every element of specs must be a lexdiv_spec object.", call. = FALSE)
  }
  specs
}

.profile_grids_argument <- function(grids) {
  if (inherits(grids, "lexdiv_grid")) {
    return(list(grids))
  }
  grids <- .profile_plain_list(grids, "grids")
  if (length(grids) > 0L && !all(vapply(grids, inherits, logical(1L), "lexdiv_grid"))) {
    stop("Every element of grids must be a lexdiv_grid object.", call. = FALSE)
  }
  grids
}

.profile_normalize_spec_object <- function(specification) {
  if (!inherits(specification, "lexdiv_spec") || !is.list(specification)) {
    stop("Every request must be a lexdiv_spec object.", call. = FALSE)
  }
  required <- c("method_id", "parameters", "request_id")
  if (!all(required %in% names(specification))) {
    stop("A lexdiv_spec object is incomplete.", call. = FALSE)
  }
  lexdiv_spec(
    method_id = specification$method_id,
    parameters = specification$parameters,
    request_id = specification$request_id
  )
}

.profile_plan_md5 <- function(specifications) {
  records <- vapply(seq_along(specifications), function(index) {
    specification <- specifications[[index]]
    paste(
      index,
      specification$request_id,
      specification$identity_key,
      sep = "|"
    )
  }, character(1L))
  .profile_md5_text(paste(
    .lex_plan_schema_id,
    .lex_plan_schema_version,
    paste(records, collapse = "\n"),
    sep = "\n"
  ))
}

#' Compile presets and custom requests into a bounded plan
#'
#' @param presets Plain character vector selected from [lexdiv_presets()]. Use
#'   `character()` to construct a custom-only plan.
#' @param specs A spec or plain list of specs appended after presets.
#' @param grids A grid or plain list of grids appended after specs.
#' @param max_specs Maximum number of distinct normalized specifications.
#'
#' @return A normalized, deduplicated `lexdiv_plan`.
#' @export
lexdiv_plan <- function(
    presets = "canonical",
    specs = list(),
    grids = list(),
    max_specs = 128L) {
  max_specs <- .profile_positive_integer(max_specs, "max_specs")
  if (
    !is.character(presets) ||
      is.object(presets) ||
      !is.null(dim(presets)) ||
      !is.null(attributes(presets)) ||
      anyNA(presets) ||
      any(!nzchar(presets)) ||
      anyDuplicated(presets)
  ) {
    stop("presets must be a plain duplicate-free character vector.", call. = FALSE)
  }
  known_presets <- c("canonical", "length_50_100")
  unknown_presets <- setdiff(presets, known_presets)
  if (length(unknown_presets) > 0L) {
    stop(
      sprintf("Unknown preset(s): %s.", paste(unknown_presets, collapse = ", ")),
      call. = FALSE
    )
  }

  custom_specs <- .profile_specs_argument(specs)
  grid_objects <- .profile_grids_argument(grids)
  preset_candidate_count <- sum(vapply(presets, function(preset_id) {
    if (identical(preset_id, "canonical")) 11 else 13
  }, numeric(1L)))
  grid_candidate_count <- sum(vapply(
    grid_objects,
    length,
    numeric(1L)
  ))
  candidate_count <- preset_candidate_count +
    as.double(length(custom_specs)) + grid_candidate_count
  if (candidate_count > .lex_plan_max_candidates) {
    stop(
      sprintf(
        "The plan exceeds the input-candidate bound (%d).",
        .lex_plan_max_candidates
      ),
      call. = FALSE
    )
  }
  expanded_grids <- unlist(grid_objects, recursive = FALSE, use.names = FALSE)
  candidates <- c(
    unlist(lapply(presets, .profile_preset_specs), recursive = FALSE, use.names = FALSE),
    custom_specs,
    expanded_grids
  )
  if (length(candidates) == 0L) {
    stop("A plan must contain at least one specification.", call. = FALSE)
  }

  normalized <- list()
  seen_keys <- character()
  for (candidate in candidates) {
    specification <- .profile_normalize_spec_object(candidate)
    if (specification$identity_key %in% seen_keys) {
      next
    }
    seen_keys <- c(seen_keys, specification$identity_key)
    normalized[[length(normalized) + 1L]] <- specification
    if (length(normalized) > max_specs) {
      stop(
        sprintf("The normalized plan exceeds max_specs (%s).", format(max_specs)),
        call. = FALSE
      )
    }
  }

  for (index in seq_along(normalized)) {
    if (is.null(normalized[[index]]$request_id)) {
      normalized[[index]]$request_id <- normalized[[index]]$specification_id
    }
  }
  request_ids <- vapply(normalized, `[[`, character(1L), "request_id")
  if (anyDuplicated(request_ids)) {
    stop("Distinct specifications must not share a request_id.", call. = FALSE)
  }

  plan_md5 <- .profile_plan_md5(normalized)
  structure(
    list(
      plan_schema_id = .lex_plan_schema_id,
      plan_schema_version = .lex_plan_schema_version,
      plan_md5 = plan_md5,
      presets = presets,
      specifications = normalized,
      max_specs = max_specs
    ),
    class = c("lexdiv_plan", "list")
  )
}

.profile_validate_plan <- function(plan) {
  if (!inherits(plan, "lexdiv_plan") || !is.list(plan)) {
    stop("plan must be a lexdiv_plan object.", call. = FALSE)
  }
  required <- c(
    "plan_schema_id", "plan_schema_version", "plan_md5", "presets",
    "specifications", "max_specs"
  )
  if (!identical(names(plan), required)) {
    stop("plan fields are incomplete, reordered, duplicated, or unexpected.", call. = FALSE)
  }
  if (
    !identical(plan$plan_schema_id, .lex_plan_schema_id) ||
      !identical(plan$plan_schema_version, .lex_plan_schema_version)
  ) {
    stop("plan schema identity is unsupported.", call. = FALSE)
  }
  max_specs <- .profile_positive_integer(plan$max_specs, "plan$max_specs")
  presets <- plan$presets
  if (
    !is.character(presets) ||
      is.object(presets) ||
      !is.null(dim(presets)) ||
      !is.null(attributes(presets)) ||
      anyNA(presets) ||
      any(!nzchar(presets)) ||
      anyDuplicated(presets) ||
      length(setdiff(presets, c("canonical", "length_50_100"))) > 0L
  ) {
    stop("plan presets are malformed or unsupported.", call. = FALSE)
  }
  if (
    !is.list(plan$specifications) ||
      length(plan$specifications) == 0L ||
      length(plan$specifications) > max_specs
  ) {
    stop("plan specifications violate plan$max_specs.", call. = FALSE)
  }
  rebuilt <- lexdiv_plan(
    presets = character(),
    specs = plan$specifications,
    max_specs = max_specs
  )
  if (
    !identical(plan$plan_md5, rebuilt$plan_md5) ||
      !identical(plan$specifications, rebuilt$specifications)
  ) {
    stop("plan failed normalization or integrity validation.", call. = FALSE)
  }
  plan
}

#' List the frozen v0.1 methods
#'
#' @return A data frame with method identity, default parameters, and the
#'   method's advisory default token floor.
#' @export
lexdiv_methods <- function() {
  methods <- .profile_method_definitions()
  output <- data.frame(
    metric_id = vapply(methods, `[[`, character(1L), "metric_id"),
    method_id = vapply(methods, `[[`, character(1L), "method_id"),
    parameter = vapply(methods, `[[`, character(1L), "parameter"),
    default_quality_floor_tokens = vapply(
      methods,
      `[[`,
      numeric(1L),
      "default_quality_floor_tokens"
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  output$default_parameters <- I(lapply(methods, `[[`, "default_parameters"))
  output <- output[c(
    "metric_id", "method_id", "parameter", "default_parameters",
    "default_quality_floor_tokens"
  )]
  row.names(output) <- NULL
  output
}

#' List the bounded v0.1 presets
#'
#' @return A data frame containing immutable preset identity and size.
#' @export
lexdiv_presets <- function() {
  data.frame(
    preset_id = c("canonical", "length_50_100"),
    preset_version = rep.int("0.1.0-draft.1", 2L),
    specification_count = c(11L, 13L),
    description = c(
      "The eleven frozen methods at their canonical defaults.",
      "Canonical plus MSTTR and MATTR at length 100."
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.profile_core_result <- function(tokens, specification) {
  arguments <- list(tokens = tokens, metrics = specification$metric_id)
  parameters <- specification$parameters
  switch(
    specification$metric_id,
    msttr = arguments$segment_length <- parameters$segment_length,
    mattr = arguments$window_length <- parameters$window_length,
    mtld = arguments$mtld_threshold <- parameters$threshold,
    hdd = arguments$sample_size <- parameters$sample_size
  )
  result <- do.call(lexdiv_metrics, arguments)
  if (!identical(result$method_id, specification$method_id)) {
    stop("Internal error: method dispatch did not preserve method identity.", call. = FALSE)
  }
  result
}

.profile_restore_result_attributes <- function(output, source) {
  source_attributes <- attributes(source)
  custom_attributes <- setdiff(
    names(source_attributes),
    c("names", "row.names", "class")
  )
  for (attribute_name in custom_attributes) {
    attr(output, attribute_name) <- source_attributes[[attribute_name]]
  }
  class(output) <- class(source)
  output
}

.profile_prepend_envelope <- function(result, plan, specification, request_index) {
  source <- result
  result_names <- names(result)
  result[["profile_schema_id"]] <- rep.int(.lex_profile_schema_id, nrow(result))
  result[["profile_schema_version"]] <- rep.int(
    .lex_profile_schema_version,
    nrow(result)
  )
  result[["plan_md5"]] <- rep.int(plan$plan_md5, nrow(result))
  result[["request_index"]] <- rep.int(as.integer(request_index), nrow(result))
  result[["request_id"]] <- rep.int(specification$request_id, nrow(result))
  result[["specification_id"]] <- rep.int(
    specification$specification_id,
    nrow(result)
  )
  result[["default_quality_floor_tokens"]] <- rep.int(
    specification$default_quality_floor_tokens,
    nrow(result)
  )
  envelope_names <- c(
    "profile_schema_id", "profile_schema_version", "plan_md5",
    "request_index", "request_id", "specification_id",
    "default_quality_floor_tokens"
  )
  result <- result[c(envelope_names, result_names)]
  result <- .profile_restore_result_attributes(result, source)
  attr(result, "profile_schema_id") <- .lex_profile_schema_id
  attr(result, "profile_schema_version") <- .lex_profile_schema_version
  attr(result, "plan_md5") <- plan$plan_md5
  class(result) <- c("lexdiv_profile_results", class(source))
  result
}

#' Compute a normalized method plan for one tokenized document
#'
#' @param tokens Input accepted by [lexdiv_metrics()].
#' @param plan A normalized plan returned by [lexdiv_plan()].
#'
#' @return A `lexdiv_profile_results` long data frame in plan order.
#' @export
lexdiv_profile <- function(tokens, plan = lexdiv_plan()) {
  plan <- .profile_validate_plan(plan)
  rows <- lapply(seq_along(plan$specifications), function(index) {
    specification <- plan$specifications[[index]]
    result <- .profile_core_result(tokens, specification)
    .profile_prepend_envelope(result, plan, specification, index)
  })
  prototype <- rows[[1L]]
  output <- do.call(base::rbind.data.frame, unname(rows))
  row.names(output) <- NULL
  .profile_restore_result_attributes(output, prototype)
}

#' @export
print.lexdiv_profile_results <- function(x, ...) {
  schema_version <- attr(x, "profile_schema_version", exact = TRUE)
  if (!is.character(schema_version) || length(schema_version) != 1L) {
    schema_version <- "unknown"
  }
  cat(sprintf(
    "<lexdiv_profile_results: %d specification%s; schema %s>\n",
    nrow(x),
    if (nrow(x) == 1L) "" else "s",
    schema_version
  ))
  visible_names <- intersect(
    c(
      "request_id", "metric_id", "value", "status", "missing_reason",
      "N", "V", "below_quality_floor"
    ),
    names(x)
  )
  print.data.frame(x[visible_names], ...)
  invisible(x)
}

.profile_profile_batch_class <- function(output) {
  class(output) <- unique(c("lexdiv_profile_batch_results", class(output)))
  output
}

#' @export
print.lexdiv_profile_batch_results <- function(x, ...) {
  document_count <- if ("document_id" %in% names(x)) {
    length(unique(x$document_id))
  } else {
    0L
  }
  schema_version <- attr(x, "profile_schema_version", exact = TRUE)
  if (!is.character(schema_version) || length(schema_version) != 1L) {
    schema_version <- "unknown"
  }
  cat(sprintf(
    paste0(
      "<lexdiv_profile_batch_results: %d document%s; ",
      "%d specification result%s; schema %s>\n"
    ),
    document_count,
    if (document_count == 1L) "" else "s",
    nrow(x),
    if (nrow(x) == 1L) "" else "s",
    schema_version
  ))
  visible_names <- intersect(
    c(
      "document_id", "request_id", "metric_id", "value", "status",
      "missing_reason", "N", "V", "below_quality_floor"
    ),
    names(x)
  )
  print.data.frame(x[visible_names], ...)
  invisible(x)
}

#' Compute a normalized method plan for multiple tokenized documents
#'
#' @param documents Input accepted by [lexdiv_metrics_batch()].
#' @param plan A normalized plan returned by [lexdiv_plan()].
#' @param id_col,tokens_col Data-frame column selectors.
#' @param max_rows Maximum document-by-specification output rows.
#'
#' @return A document-major `lexdiv_profile_batch_results` long data frame.
#' @export
lexdiv_profile_batch <- function(
    documents,
    plan = lexdiv_plan(),
    id_col = "document_id",
    tokens_col = "tokens",
    max_rows = 1e6) {
  id_col <- .lex_batch_scalar_name(id_col, "id_col")
  tokens_col <- .lex_batch_scalar_name(tokens_col, "tokens_col")
  if (identical(id_col, tokens_col)) {
    stop("id_col and tokens_col must select different columns.", call. = FALSE)
  }
  max_rows <- .profile_positive_integer(max_rows, "max_rows")
  plan <- .profile_validate_plan(plan)
  batch <- .lex_batch_documents(documents, id_col, tokens_col)
  document_count <- length(batch$tokens)
  specification_count <- length(plan$specifications)
  if (
    document_count > 0L &&
      as.double(document_count) > max_rows / as.double(specification_count)
  ) {
    stop(
      sprintf("The requested profile exceeds max_rows (%s).", format(max_rows)),
      call. = FALSE
    )
  }

  if (document_count == 0L) {
    prototype <- lexdiv_profile(character(), plan)
    output <- prototype[FALSE, , drop = FALSE]
    output <- .lex_batch_prepend_id(output, character())
    row.names(output) <- NULL
    return(.profile_profile_batch_class(output))
  }

  pieces <- lapply(seq_len(document_count), function(index) {
    result <- lexdiv_profile(batch$tokens[[index]], plan)
    result <- .lex_batch_prepend_id(result, batch$ids[[index]])
    .profile_profile_batch_class(result)
  })
  prototype <- pieces[[1L]]
  output <- do.call(base::rbind.data.frame, unname(pieces))
  row.names(output) <- NULL
  output <- .profile_restore_result_attributes(output, prototype)
  .profile_profile_batch_class(output)
}

.profile_validate_floors <- function(floors) {
  attribute_names <- names(attributes(floors))
  if (
    !is.numeric(floors) ||
      is.object(floors) ||
      !is.null(dim(floors)) ||
      !identical(attribute_names, "names") ||
      length(floors) == 0L ||
      anyNA(floors) ||
      any(!is.finite(floors)) ||
      any(floors < 1) ||
      any(floors != floor(floors))
  ) {
    stop("floors must be a non-empty named vector of positive finite integers.", call. = FALSE)
  }
  floor_ids <- names(floors)
  if (anyDuplicated(floor_ids)) {
    stop("floor names must be unique.", call. = FALSE)
  }
  for (floor_id in floor_ids) {
    .profile_scalar_identifier(floor_id, "floor name")
  }
  values <- as.double(floors)
  names(values) <- floor_ids
  values
}

.profile_validate_screen_source <- function(x) {
  required <- c(
    "profile_schema_id", "profile_schema_version", "plan_md5",
    "request_index", "request_id", "specification_id",
    "default_quality_floor_tokens", "metric_id", "method_id",
    "metric_contract_id", "metric_contract_version", "result_schema_id",
    "result_schema_version", "requested_parameters", "N"
  )
  if (!all(required %in% names(x))) {
    stop("x is missing required profile-result columns.", call. = FALSE)
  }
  if (
    !identical(attr(x, "profile_schema_id", exact = TRUE), .lex_profile_schema_id) ||
      !identical(
        attr(x, "profile_schema_version", exact = TRUE),
        .lex_profile_schema_version
      ) ||
      !identical(attr(x, "contract_id", exact = TRUE), .lex_contract_id) ||
      !identical(attr(x, "contract_version", exact = TRUE), .lex_contract_version) ||
      !identical(attr(x, "result_schema_id", exact = TRUE), .lex_result_schema_id) ||
      !identical(
        attr(x, "result_schema_version", exact = TRUE),
        .lex_result_schema_version
      )
  ) {
    stop("x has inconsistent profile or core schema attributes.", call. = FALSE)
  }
  plan_md5 <- attr(x, "plan_md5", exact = TRUE)
  if (
    !is.character(plan_md5) ||
      length(plan_md5) != 1L ||
      is.na(plan_md5) ||
      !grepl("^[0-9a-f]{32}$", plan_md5)
  ) {
    stop("x has an invalid plan_md5 attribute.", call. = FALSE)
  }

  expected_constants <- list(
    profile_schema_id = .lex_profile_schema_id,
    profile_schema_version = .lex_profile_schema_version,
    plan_md5 = plan_md5,
    metric_contract_id = .lex_contract_id,
    metric_contract_version = .lex_contract_version,
    result_schema_id = .lex_result_schema_id,
    result_schema_version = .lex_result_schema_version
  )
  for (field in names(expected_constants)) {
    value <- x[[field]]
    if (!is.character(value) || anyNA(value) ||
        any(value != expected_constants[[field]])) {
      stop(sprintf("x has an inconsistent %s column.", field), call. = FALSE)
    }
  }
  if (
    !is.numeric(x$request_index) ||
      anyNA(x$request_index) ||
      any(!is.finite(x$request_index)) ||
      any(x$request_index < 1) ||
      any(x$request_index != floor(x$request_index))
  ) {
    stop("x has an invalid request_index column.", call. = FALSE)
  }
  if (
    !is.numeric(x$N) ||
      any(!is.na(x$N) & (!is.finite(x$N) | x$N < 0 | x$N != floor(x$N)))
  ) {
    stop("x has an invalid N column.", call. = FALSE)
  }
  if (
    !is.character(x$request_id) || anyNA(x$request_id) ||
      !is.character(x$specification_id) || anyNA(x$specification_id) ||
      !is.character(x$metric_id) || anyNA(x$metric_id) ||
      !is.character(x$method_id) || anyNA(x$method_id) ||
      !is.list(x$requested_parameters) ||
      !is.numeric(x$default_quality_floor_tokens) ||
      anyNA(x$default_quality_floor_tokens) ||
      any(!is.finite(x$default_quality_floor_tokens)) ||
      any(x$default_quality_floor_tokens < 1) ||
      any(
        x$default_quality_floor_tokens !=
          floor(x$default_quality_floor_tokens)
      )
  ) {
    stop("x has malformed request or method identity columns.", call. = FALSE)
  }

  has_document_id <- "document_id" %in% names(x)
  batch_fields <- c("batch_schema_id", "batch_schema_version")
  if (has_document_id) {
    if (
      !inherits(x, "lexdiv_profile_batch_results") ||
        !inherits(x, "lexdiv_batch_results") ||
        !all(batch_fields %in% names(x)) ||
        !identical(
          attr(x, "batch_schema_id", exact = TRUE),
          .lex_batch_schema_id
        ) ||
        !identical(
          attr(x, "batch_schema_version", exact = TRUE),
          .lex_batch_schema_version
        ) ||
        !is.character(x$document_id) ||
        anyNA(x$document_id) ||
        any(!nzchar(x$document_id)) ||
        any(Encoding(x$document_id) %in% c("bytes", "latin1")) ||
        any(!validUTF8(x$document_id)) ||
        !is.character(x$batch_schema_id) ||
        anyNA(x$batch_schema_id) ||
        !is.character(x$batch_schema_version) ||
        anyNA(x$batch_schema_version) ||
        any(x$batch_schema_id != .lex_batch_schema_id) ||
        any(x$batch_schema_version != .lex_batch_schema_version)
    ) {
      stop("x has an inconsistent profile-batch envelope.", call. = FALSE)
    }
  } else if (
    inherits(x, "lexdiv_profile_batch_results") ||
      inherits(x, "lexdiv_batch_results") ||
      any(batch_fields %in% names(x))
  ) {
    stop("x has an incomplete profile-batch envelope.", call. = FALSE)
  }

  specification_ids <- unique(x$specification_id)
  specification_groups <- split(
    seq_len(nrow(x)),
    match(x$specification_id, specification_ids)
  )
  reconstructed <- vector("list", length(specification_groups))
  request_indices <- numeric(length(specification_groups))
  group_number <- 0L
  for (group in specification_groups) {
    group_number <- group_number + 1L
    index <- group[[1L]]
    specification_id <- x$specification_id[[index]]
    constant_fields <- c(
      "request_index", "request_id", "metric_id", "method_id",
      "default_quality_floor_tokens"
    )
    group_is_consistent <- all(vapply(constant_fields, function(field) {
      all(x[[field]][group] == x[[field]][[index]])
    }, logical(1L))) && all(vapply(group, function(row) {
      identical(
        x$requested_parameters[[row]],
        x$requested_parameters[[index]]
      )
    }, logical(1L)))
    if (!group_is_consistent) {
      stop("x contains inconsistent rows for one specification_id.", call. = FALSE)
    }
    specification <- tryCatch(
      lexdiv_spec(
        method_id = x$method_id[[index]],
        parameters = x$requested_parameters[[index]],
        request_id = x$request_id[[index]]
      ),
      error = function(error) NULL
    )
    if (
      is.null(specification) ||
        !identical(specification$metric_id, x$metric_id[[index]]) ||
        !identical(specification$specification_id, specification_id) ||
        !identical(
          specification$default_quality_floor_tokens,
          as.double(x$default_quality_floor_tokens[[index]])
        )
    ) {
      stop("x contains a row whose specification identity is inconsistent.", call. = FALSE)
    }
    reconstructed[[group_number]] <- specification
    request_indices[[group_number]] <- x$request_index[[index]]
  }
  if (length(reconstructed) > 0L) {
    if (
      anyDuplicated(request_indices) ||
        !identical(sort(request_indices), as.double(seq_along(reconstructed)))
    ) {
      stop("x has an inconsistent request_index sequence.", call. = FALSE)
    }
    reconstructed <- reconstructed[order(request_indices)]
    if (!identical(.profile_plan_md5(reconstructed), plan_md5)) {
      stop("x has an inconsistent plan fingerprint.", call. = FALSE)
    }
  }
  invisible(TRUE)
}

#' Evaluate independent token-count screens without duplicating metric values
#'
#' @param x A result returned by [lexdiv_profile()] or
#'   [lexdiv_profile_batch()].
#' @param floors Named positive integer screening floors.
#' @param max_rows Maximum source-row-by-floor output rows, checked before
#'   allocation.
#'
#' @return A `lexdiv_screen_results` table without a metric-value column.
#' @export
lexdiv_screen <- function(
    x,
    floors = c(tokens_50 = 50L, tokens_100 = 100L),
    max_rows = 2e6) {
  if (
    !inherits(x, "lexdiv_profile_results") ||
      !is.data.frame(x)
  ) {
    stop("x must be a lexdiv profile result.", call. = FALSE)
  }
  .profile_validate_screen_source(x)
  floors <- .profile_validate_floors(floors)
  max_rows <- .profile_positive_integer(max_rows, "max_rows")
  if (
    nrow(x) > 0L &&
      as.double(nrow(x)) > max_rows / as.double(length(floors))
  ) {
    stop(
      sprintf("The requested screen exceeds max_rows (%s).", format(max_rows)),
      call. = FALSE
    )
  }
  row_index <- rep(seq_len(nrow(x)), each = length(floors))
  floor_index <- rep(seq_along(floors), times = nrow(x))
  output <- data.frame(
    screen_schema_id = rep.int(.lex_screen_schema_id, length(row_index)),
    screen_schema_version = rep.int(
      .lex_screen_schema_version,
      length(row_index)
    ),
    profile_schema_id = x$profile_schema_id[row_index],
    profile_schema_version = x$profile_schema_version[row_index],
    plan_md5 = x$plan_md5[row_index],
    request_index = x$request_index[row_index],
    request_id = x$request_id[row_index],
    specification_id = x$specification_id[row_index],
    metric_id = x$metric_id[row_index],
    method_id = x$method_id[row_index],
    N = x$N[row_index],
    screen_id = names(floors)[floor_index],
    minimum_tokens = unname(floors[floor_index]),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  if ("document_id" %in% names(x)) {
    output[["document_id"]] <- x$document_id[row_index]
    output <- output[c("document_id", setdiff(names(output), "document_id"))]
  }
  output$passes_screen <- ifelse(
    is.na(output$N),
    NA,
    output$N >= output$minimum_tokens
  )
  row.names(output) <- NULL
  class(output) <- c("lexdiv_screen_results", "data.frame")
  attr(output, "screen_schema_id") <- .lex_screen_schema_id
  attr(output, "screen_schema_version") <- .lex_screen_schema_version
  attr(output, "plan_md5") <- attr(x, "plan_md5", exact = TRUE)
  output
}
