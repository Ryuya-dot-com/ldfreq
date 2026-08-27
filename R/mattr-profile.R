# Local MATTR trajectory and position-exposure diagnostics.

.lexmattr_profile_contract_id <- "ldfreq-mattr-profile"
.lexmattr_profile_contract_version <- "0.1.0"
.lexmattr_profile_schema_id <- "lexdiv-mattr-profile-result"
.lexmattr_profile_schema_version <- "0.1.0"

.lexmattr_empty_windows <- function() {
  data.frame(
    plan_md5 = character(),
    request_index = integer(),
    request_id = character(),
    specification_id = character(),
    metric_id = character(),
    method_id = character(),
    window_index = double(),
    window_start = double(),
    window_end = double(),
    window_midpoint = double(),
    window_length = double(),
    distinct_types = double(),
    value = double(),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.lexmattr_empty_exposure <- function() {
  data.frame(
    plan_md5 = character(),
    request_index = integer(),
    request_id = character(),
    specification_id = character(),
    metric_id = character(),
    method_id = character(),
    position = double(),
    exposure_count = double(),
    window_inclusion_rate = double(),
    nominal_observation_weight = double(),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.lexmattr_empty_diagnostics <- function() {
  data.frame(
    plan_md5 = character(),
    request_index = integer(),
    request_id = character(),
    specification_id = character(),
    status = character(),
    missing_reason = character(),
    N = double(),
    V = double(),
    window_length = double(),
    window_count = double(),
    endpoint_exposure_count = double(),
    maximum_exposure_count = double(),
    exposure_weight_sum = double(),
    local_mean = double(),
    core_value = double(),
    reconciliation_error = double(),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.lexmattr_request_fields <- function(plan, specification, request_index, n) {
  list(
    plan_md5 = rep.int(plan$plan_md5, n),
    request_index = rep.int(as.integer(request_index), n),
    request_id = rep.int(specification$request_id, n),
    specification_id = rep.int(specification$specification_id, n),
    metric_id = rep.int(specification$metric_id, n),
    method_id = rep.int(specification$method_id, n)
  )
}

.lexmattr_window_rows <- function(
    tokens,
    plan,
    specification,
    request_index) {
  window_length <- as.double(specification$parameters$window_length)
  distinct_types <- .mattr_window_type_counts(tokens, window_length)
  window_count <- length(distinct_types)
  if (window_count == 0L) return(.lexmattr_empty_windows())

  window_start <- seq_len(window_count)
  window_end <- window_start + window_length - 1
  fields <- .lexmattr_request_fields(
    plan, specification, request_index, window_count
  )
  data.frame(
    fields,
    window_index = as.double(window_start),
    window_start = as.double(window_start),
    window_end = as.double(window_end),
    window_midpoint = (as.double(window_start) + as.double(window_end)) / 2,
    window_length = rep.int(window_length, window_count),
    distinct_types = distinct_types,
    value = distinct_types / window_length,
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.lexmattr_exposure_rows <- function(
    token_count,
    window_count,
    plan,
    specification,
    request_index) {
  if (token_count == 0L || window_count == 0L) {
    return(.lexmattr_empty_exposure())
  }
  window_length <- as.double(specification$parameters$window_length)
  position <- seq_len(token_count)
  first_start <- pmax(1, position - window_length + 1)
  last_start <- pmin(position, window_count)
  exposure_count <- pmax(0, last_start - first_start + 1)
  fields <- .lexmattr_request_fields(
    plan, specification, request_index, token_count
  )
  data.frame(
    fields,
    position = as.double(position),
    exposure_count = as.double(exposure_count),
    window_inclusion_rate = as.double(exposure_count) / window_count,
    nominal_observation_weight = as.double(exposure_count) /
      (window_count * window_length),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
}

.lexmattr_bind <- function(rows, prototype) {
  non_empty <- vapply(rows, nrow, integer(1L)) > 0L
  if (!any(non_empty)) return(prototype)
  output <- do.call(base::rbind.data.frame, unname(rows[non_empty]))
  row.names(output) <- NULL
  output
}

#' Inspect the local MATTR trajectory and positional exposure
#'
#' Decomposes canonical step-one MATTR specifications into their complete
#' moving windows. It returns each local TTR and the number and nominal weight
#' of windows containing each token position. The function does not choose a
#' window length, resample tokens, infer a minimum valid text length, or turn
#' the local profile into an inferential stability test.
#'
#' @param tokens Input accepted by [lexdiv_metrics()]. Token strings are used
#'   for calculation but are not retained in the result.
#' @param plan A normalized [lexdiv_plan()] containing only MATTR
#'   specifications. Use [lexdiv_grid()] to request several window lengths.
#' @param max_rows Maximum combined rows across `summary`, `windows`,
#'   `exposure`, and `diagnostics`, checked before detail allocation.
#'
#' @return A `lexdiv_mattr_profile` list. `summary` contains the unchanged
#'   canonical [lexdiv_profile()] rows; `windows` contains local TTR values;
#'   `exposure` contains position-only inclusion counts and weights;
#'   `diagnostics` reconciles the local mean with the canonical result; and
#'   `provenance` records the profile contract, schema, and plan identity.
#' @export
lexdiv_mattr_profile <- function(tokens, plan, max_rows = 1e6) {
  plan <- .profile_validate_plan(plan)
  max_rows <- .profile_positive_integer(max_rows, "max_rows")
  metric_ids <- vapply(
    plan$specifications, `[[`, character(1L), "metric_id"
  )
  if (any(metric_ids != "mattr")) {
    stop("plan must contain only MATTR specifications.", call. = FALSE)
  }

  summary <- lexdiv_profile(tokens, plan)
  specification_count <- length(plan$specifications)
  fixed_rows <- 2 * as.double(specification_count)
  if (fixed_rows > max_rows) {
    stop(
      sprintf("The requested MATTR profile exceeds max_rows (%s).", format(max_rows)),
      call. = FALSE
    )
  }

  input_state <- .lex_input_state(tokens)
  token_count <- if (identical(input_state, "ok")) {
    as.double(length(tokens))
  } else if (identical(input_state, "empty_input")) {
    0
  } else {
    NA_real_
  }
  detail_rows <- 0
  for (index in seq_len(specification_count)) {
    if (!identical(summary$status[[index]], "ok")) next
    window_length <- as.double(
      plan$specifications[[index]]$parameters$window_length
    )
    window_count <- token_count - window_length + 1
    request_rows <- token_count + window_count
    if (request_rows > max_rows - fixed_rows - detail_rows) {
      stop(
        sprintf("The requested MATTR profile exceeds max_rows (%s).", format(max_rows)),
        call. = FALSE
      )
    }
    detail_rows <- detail_rows + request_rows
  }

  canonical_tokens <- if (identical(input_state, "ok")) {
    .lex_canonicalize_encoding(tokens)
  } else {
    character()
  }
  window_rows <- vector("list", specification_count)
  exposure_rows <- vector("list", specification_count)
  diagnostic_rows <- vector("list", specification_count)

  for (index in seq_len(specification_count)) {
    specification <- plan$specifications[[index]]
    result_row <- summary[index, , drop = FALSE]
    available <- identical(result_row$status[[1L]], "ok")
    windows <- if (available) {
      .lexmattr_window_rows(canonical_tokens, plan, specification, index)
    } else {
      .lexmattr_empty_windows()
    }
    exposure <- if (available) {
      .lexmattr_exposure_rows(
        token_count = token_count,
        window_count = nrow(windows),
        plan = plan,
        specification = specification,
        request_index = index
      )
    } else {
      .lexmattr_empty_exposure()
    }
    window_rows[[index]] <- windows
    exposure_rows[[index]] <- exposure

    local_mean <- if (nrow(windows)) {
      sum(windows$distinct_types) /
        (as.double(nrow(windows)) *
          as.double(specification$parameters$window_length))
    } else {
      NA_real_
    }
    core_value <- result_row$value[[1L]]
    diagnostic_rows[[index]] <- data.frame(
      plan_md5 = plan$plan_md5,
      request_index = as.integer(index),
      request_id = specification$request_id,
      specification_id = specification$specification_id,
      status = result_row$status[[1L]],
      missing_reason = result_row$missing_reason[[1L]],
      N = result_row$N[[1L]],
      V = result_row$V[[1L]],
      window_length = as.double(specification$parameters$window_length),
      window_count = if (available) as.double(nrow(windows)) else 0,
      endpoint_exposure_count = if (nrow(exposure)) {
        exposure$exposure_count[[1L]]
      } else {
        NA_real_
      },
      maximum_exposure_count = if (nrow(exposure)) {
        max(exposure$exposure_count)
      } else {
        NA_real_
      },
      exposure_weight_sum = if (nrow(exposure)) {
        sum(exposure$nominal_observation_weight)
      } else {
        NA_real_
      },
      local_mean = local_mean,
      core_value = core_value,
      reconciliation_error = if (available) local_mean - core_value else NA_real_,
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  }

  structure(
    list(
      summary = summary,
      windows = .lexmattr_bind(window_rows, .lexmattr_empty_windows()),
      exposure = .lexmattr_bind(exposure_rows, .lexmattr_empty_exposure()),
      diagnostics = .lexmattr_bind(
        diagnostic_rows, .lexmattr_empty_diagnostics()
      ),
      provenance = list(
        contract_id = .lexmattr_profile_contract_id,
        contract_version = .lexmattr_profile_contract_version,
        result_schema_id = .lexmattr_profile_schema_id,
        result_schema_version = .lexmattr_profile_schema_version,
        plan_schema_id = plan$plan_schema_id,
        plan_schema_version = plan$plan_schema_version,
        plan_md5 = plan$plan_md5,
        method_id = "mattr_sliding_step1_v1",
        order_sensitive = TRUE,
        local_window_step = 1,
        endpoint_exposure_is_unequal = TRUE,
        contains_token_strings = FALSE,
        interpretation = "descriptive_local_trajectory_not_stability_inference",
        max_rows = max_rows
      )
    ),
    class = "lexdiv_mattr_profile"
  )
}

#' @param x A `lexdiv_mattr_profile` object.
#' @param ... Additional arguments passed to [print.data.frame()].
#'
#' @return `print.lexdiv_mattr_profile()` returns `x` invisibly.
#' @rdname lexdiv_mattr_profile
#' @export
print.lexdiv_mattr_profile <- function(x, ...) {
  if (!inherits(x, "lexdiv_mattr_profile") || !is.list(x)) {
    stop("x must be a lexdiv_mattr_profile object.", call. = FALSE)
  }
  cat(sprintf(
    paste0(
      "<lexdiv_mattr_profile: %d specification%s; %d window%s; ",
      "%d exposure row%s; schema %s>\n"
    ),
    nrow(x$summary), if (nrow(x$summary) == 1L) "" else "s",
    nrow(x$windows), if (nrow(x$windows) == 1L) "" else "s",
    nrow(x$exposure), if (nrow(x$exposure) == 1L) "" else "s",
    x$provenance$result_schema_version
  ))
  visible <- intersect(
    c(
      "request_id", "value", "status", "missing_reason", "N", "V",
      "requested_parameters"
    ),
    names(x$summary)
  )
  print.data.frame(x$summary[visible], ...)
  invisible(x)
}

#' Plot one local MATTR trajectory
#'
#' @param x A `lexdiv_mattr_profile` object.
#' @param request_id One request ID. It may be omitted only when the plan has a
#'   single specification.
#' @param add_global_mean One `TRUE` or `FALSE` value indicating whether to add
#'   the canonical MATTR value as a horizontal line.
#' @param col,lwd,type,main,xlab,ylab,ylim Base-graphics settings.
#' @param mean_col,mean_lty Settings for the global-mean line.
#' @param ... Additional arguments passed to [graphics::plot()].
#'
#' @return Invisibly, the exact window rows displayed.
#' @export
plot.lexdiv_mattr_profile <- function(
    x,
    request_id = NULL,
    add_global_mean = TRUE,
    col = "#2166AC",
    lwd = 2,
    type = "l",
    main = NULL,
    xlab = "Window midpoint (token position)",
    ylab = "Local TTR",
    ylim = c(0, 1),
    mean_col = "#B2182B",
    mean_lty = 2,
    ...) {
  if (!inherits(x, "lexdiv_mattr_profile") || !is.list(x)) {
    stop("x must be a lexdiv_mattr_profile object.", call. = FALSE)
  }
  add_global_mean <- .lexprep_scalar_flag(
    add_global_mean,
    "add_global_mean"
  )
  request_ids <- x$summary$request_id
  if (is.null(request_id)) {
    if (length(request_ids) != 1L) {
      stop("request_id is required when the profile has multiple specifications.", call. = FALSE)
    }
    request_id <- request_ids[[1L]]
  }
  request_id <- .profile_scalar_identifier(request_id, "request_id")
  index <- match(request_id, request_ids)
  if (is.na(index)) {
    stop("request_id is not present in the MATTR profile.", call. = FALSE)
  }
  selected <- x$windows[x$windows$request_id == request_id, , drop = FALSE]
  if (!nrow(selected)) {
    reason <- x$summary$missing_reason[[index]]
    stop(
      sprintf(
        "The selected MATTR trajectory is unavailable%s.",
        if (is.na(reason)) "" else paste0(": ", reason)
      ),
      call. = FALSE
    )
  }
  if (is.null(main)) {
    main <- sprintf("Local MATTR: %s", request_id)
  }
  graphics::plot(
    selected$window_midpoint,
    selected$value,
    type = type,
    col = col,
    lwd = lwd,
    main = main,
    xlab = xlab,
    ylab = ylab,
    ylim = ylim,
    ...
  )
  if (isTRUE(add_global_mean)) {
    graphics::abline(
      h = x$summary$value[[index]], col = mean_col, lty = mean_lty
    )
  }
  invisible(selected)
}
