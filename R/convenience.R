# Explicit convenience adapters, wide transformation, and base-R plots.

.lex_convenience_name <- function(value, argument) {
  if (
    !is.character(value) || length(value) != 1L || is.na(value) ||
      !nzchar(value)
  ) {
    stop(sprintf("%s must be one non-empty column name.", argument), call. = FALSE)
  }
  value
}

.lex_document_ids <- function(ids, argument) {
  if (
    !is.character(ids) || is.object(ids) || !is.null(dim(ids)) ||
      anyNA(ids) || any(!nzchar(ids))
  ) {
    stop(
      sprintf("%s must contain plain, non-empty, non-missing character IDs.", argument),
      call. = FALSE
    )
  }
  ids
}

.lex_named_documents <- function(documents) {
  if (!is.list(documents) || is.object(documents) || !is.null(dim(documents))) {
    stop("x must resolve to a plain list of token vectors.", call. = FALSE)
  }
  document_ids <- names(documents)
  if (length(documents) > 0L && (
    is.null(document_ids) || anyNA(document_ids) ||
      any(!nzchar(document_ids)) || anyDuplicated(document_ids)
  )) {
    stop("Document lists must have unique, non-empty names.", call. = FALSE)
  }
  if (!all(vapply(documents, function(tokens) {
    is.character(tokens) && !is.object(tokens) && is.null(dim(tokens))
  }, logical(1L)))) {
    stop("Every document must be a plain character token vector.", call. = FALSE)
  }
  unclass(documents)
}

#' Convert common R token containers to named documents
#'
#' Creates the explicit named-list boundary accepted by
#' [lexdiv_metrics_batch()] and [lexdiv_profile_batch()]. A tidy token table
#' is grouped in first-document-appearance and row order. A `quanteda` tokens
#' object is converted through its registered `as.list()` method; no `quanteda`
#' runtime dependency is added to `ldfreq`.
#'
#' @param x A named list of token vectors, a data frame with one token per row,
#'   or a `quanteda` tokens object.
#' @param document_col Name of the document-ID column for data-frame input.
#' @param token_col Name of the token column for data-frame input.
#'
#' @return A plain named list of plain character vectors, preserving document
#'   and token order.
#' @export
lexdiv_as_documents <- function(
    x,
    document_col = "document_id",
    token_col = "token") {
  document_col <- .lex_convenience_name(document_col, "document_col")
  token_col <- .lex_convenience_name(token_col, "token_col")
  if (identical(document_col, token_col)) {
    stop("document_col and token_col must differ.", call. = FALSE)
  }

  if (inherits(x, "tokens")) {
    converted <- tryCatch(
      as.list(x),
      error = function(error) {
        stop(
          sprintf("The quanteda tokens object could not be converted: %s", error$message),
          call. = FALSE
        )
      }
    )
    converted <- lapply(converted, function(tokens) unname(as.character(tokens)))
    return(.lex_named_documents(converted))
  }

  if (is.data.frame(x)) {
    missing_columns <- setdiff(c(document_col, token_col), names(x))
    if (length(missing_columns) > 0L) {
      stop(
        sprintf("Data-frame input is missing column(s): %s.", paste(missing_columns, collapse = ", ")),
        call. = FALSE
      )
    }
    ids <- .lex_document_ids(x[[document_col]], document_col)
    tokens <- x[[token_col]]
    if (!is.character(tokens) || is.object(tokens) || !is.null(dim(tokens))) {
      stop(sprintf("%s must be a plain character token column.", token_col), call. = FALSE)
    }
    ordered_ids <- unique(ids)
    documents <- lapply(ordered_ids, function(document_id) {
      unname(tokens[ids == document_id])
    })
    names(documents) <- ordered_ids
    return(.lex_named_documents(documents))
  }

  .lex_named_documents(x)
}

.lex_wide_names <- function(value, argument, available) {
  if (
    !is.character(value) || is.object(value) || !is.null(dim(value)) ||
      anyNA(value) || any(!nzchar(value)) || anyDuplicated(value)
  ) {
    stop(sprintf("%s must be a plain, unique character vector.", argument), call. = FALSE)
  }
  unknown <- setdiff(value, available)
  if (length(unknown) > 0L) {
    stop(
      sprintf("Unknown %s column(s): %s.", argument, paste(unknown, collapse = ", ")),
      call. = FALSE
    )
  }
  value
}

.lex_wide_group_key <- function(frame) {
  if (ncol(frame) == 0L) {
    return(rep.int("", nrow(frame)))
  }
  pieces <- lapply(frame, function(column) {
    value <- ifelse(is.na(column), "<NA>", enc2utf8(as.character(column)))
    paste0(nchar(value, type = "bytes"), ":", value)
  })
  do.call(paste, c(pieces, sep = "|"))
}

#' Convert long lexical-diversity results to a deterministic wide table
#'
#' This is a pure reshaping operation: it never recomputes or changes metric
#' values. Profile results use `request_id` by default so multiple parameter
#' settings of one metric remain distinct; other results use `metric_id`.
#'
#' @param x A lexical-diversity result data frame.
#' @param id_cols Columns identifying output rows. By default this is
#'   `document_id` when present, otherwise a single row is produced.
#' @param names_from Column supplying wide field names. Defaults to `request_id`
#'   for profile results and `metric_id` otherwise.
#' @param values_from Result columns to widen. With one column, output columns
#'   use the metric/request IDs directly. With several, names have the form
#'   `ID__field`.
#'
#' @return A `lexdiv_wide_results` data frame.
#' @export
lexdiv_widen <- function(
    x,
    id_cols = NULL,
    names_from = NULL,
    values_from = c(
      "value", "status", "missing_reason", "method_id",
      "below_quality_floor"
    )) {
  if (!is.data.frame(x)) {
    stop("x must be a lexical-diversity result data frame.", call. = FALSE)
  }
  if (is.null(id_cols)) {
    id_cols <- if ("document_id" %in% names(x)) "document_id" else character()
  }
  if (is.null(names_from)) {
    names_from <- if ("request_id" %in% names(x)) "request_id" else "metric_id"
  }
  id_cols <- .lex_wide_names(id_cols, "id_cols", names(x))
  names_from <- .lex_convenience_name(names_from, "names_from")
  if (!(names_from %in% names(x))) {
    stop(sprintf("Unknown names_from column: %s.", names_from), call. = FALSE)
  }
  values_from <- .lex_wide_names(values_from, "values_from", names(x))
  if (length(values_from) == 0L) {
    stop("values_from must select at least one column.", call. = FALSE)
  }
  if (length(intersect(c(names_from, id_cols), values_from)) > 0L) {
    stop("ID/name columns cannot also be selected by values_from.", call. = FALSE)
  }
  wide_ids <- as.character(x[[names_from]])
  if (anyNA(wide_ids) || any(!nzchar(wide_ids))) {
    stop("names_from contains missing or empty values.", call. = FALSE)
  }

  if (nrow(x) == 0L) {
    output <- x[id_cols]
    row.names(output) <- NULL
    class(output) <- c("lexdiv_wide_results", "data.frame")
    return(output)
  }
  id_frame <- x[id_cols]
  id_keys <- .lex_wide_group_key(id_frame)
  first_group_rows <- !duplicated(id_keys)
  output <- id_frame[first_group_rows, , drop = FALSE]
  group_keys <- id_keys[first_group_rows]
  group_index <- match(id_keys, group_keys)
  cell_keys <- paste0(
    nchar(id_keys, type = "bytes"), ":", id_keys, "|",
    nchar(wide_ids, type = "bytes"), ":", wide_ids
  )
  if (anyDuplicated(cell_keys)) {
    stop(
      "x has multiple rows for the same output row and names_from value.",
      call. = FALSE
    )
  }
  ordered_wide_ids <- unique(wide_ids)
  output_names <- character()

  for (wide_id in ordered_wide_ids) {
    selected_rows <- which(wide_ids == wide_id)
    for (value_name in values_from) {
      column_name <- if (length(values_from) == 1L) {
        wide_id
      } else {
        paste0(wide_id, "__", value_name)
      }
      output_names <- c(output_names, column_name)
      source <- x[[value_name]]
      if (is.list(source)) {
        column <- vector("list", nrow(output))
        column[group_index[selected_rows]] <- source[selected_rows]
        output[[column_name]] <- I(column)
      } else {
        column <- source[rep.int(NA_integer_, nrow(output))]
        column[group_index[selected_rows]] <- source[selected_rows]
        output[[column_name]] <- column
      }
    }
  }
  if (anyDuplicated(c(id_cols, output_names))) {
    stop("The requested wide-column names collide.", call. = FALSE)
  }
  row.names(output) <- NULL
  class(output) <- c("lexdiv_wide_results", "data.frame")
  attr(output, "names_from") <- names_from
  attr(output, "values_from") <- values_from
  output
}

#' @export
print.lexdiv_wide_results <- function(x, ...) {
  cat(sprintf(
    "<lexdiv_wide_results: %d row%s; %d column%s>\n",
    nrow(x), if (nrow(x) == 1L) "" else "s",
    ncol(x), if (ncol(x) == 1L) "" else "s"
  ))
  print.data.frame(x, ...)
  invisible(x)
}

.lex_plot_metric_frame <- function(
    x,
    metric_id = NULL,
    request_id = NULL,
    col = NULL,
    pch = 19,
    main = NULL,
    xlab = "",
    ylab = NULL,
    ...) {
  if (!is.data.frame(x) || !all(c("metric_id", "value", "status") %in% names(x))) {
    stop("x is not a supported lexical-diversity result frame.", call. = FALSE)
  }
  available <- unique(x$metric_id)
  if (is.null(metric_id)) {
    if (length(available) != 1L) {
      stop("metric_id must select one metric when x contains several.", call. = FALSE)
    }
    metric_id <- available[[1L]]
  }
  metric_id <- .lex_convenience_name(metric_id, "metric_id")
  selected <- x$metric_id == metric_id
  if (!is.null(request_id)) {
    if (!("request_id" %in% names(x))) {
      stop("request_id is available only for profile results.", call. = FALSE)
    }
    request_id <- .lex_convenience_name(request_id, "request_id")
    selected <- selected & x$request_id == request_id
  }
  frame <- x[selected, , drop = FALSE]
  if (nrow(frame) == 0L) {
    stop("The requested metric/profile selection is absent from x.", call. = FALSE)
  }
  ok <- frame$status == "ok" & is.finite(frame$value)
  if (!any(ok)) {
    stop("The requested selection contains no finite ok values to plot.", call. = FALSE)
  }
  frame <- frame[ok, , drop = FALSE]
  labels <- if ("document_id" %in% names(frame)) {
    frame$document_id
  } else if ("request_id" %in% names(frame)) {
    frame$request_id
  } else {
    rep.int(metric_id, nrow(frame))
  }
  if (is.null(col)) {
    col <- ifelse(frame$below_quality_floor %in% TRUE, "#D55E00", "#0072B2")
  }
  if (is.null(main)) main <- metric_id
  if (is.null(ylab)) ylab <- "value"
  positions <- seq_len(nrow(frame))
  graphics::plot(
    positions, frame$value,
    xaxt = "n", xlab = xlab, ylab = ylab, main = main,
    col = col, pch = pch, ...
  )
  graphics::axis(1, at = positions, labels = labels)
  invisible(data.frame(
    label = labels,
    metric_id = frame$metric_id,
    value = frame$value,
    below_quality_floor = frame$below_quality_floor,
    stringsAsFactors = FALSE,
    check.names = FALSE
  ))
}

#' Plot lexical-diversity results
#'
#' Plots exactly one metric at a time so values on incompatible scales are not
#' visually compared. Points below the advisory token floor are orange; other
#' finite `ok` results are blue. The returned plot-data table is invisible.
#'
#' @param x A supported lexical-diversity result object.
#' @param metric_id One metric to plot. It may be omitted only when the object
#'   contains one metric.
#' @param request_id Optional profile request to select.
#' @param col,pch,main,xlab,ylab Base-graphics settings.
#' @param ... Additional arguments passed to [graphics::plot()].
#' @export
plot.lexdiv_results <- function(
    x, metric_id = NULL, request_id = NULL, col = NULL, pch = 19,
    main = NULL, xlab = "", ylab = NULL, ...) {
  .lex_plot_metric_frame(
    x, metric_id, request_id, col, pch, main, xlab, ylab, ...
  )
}

#' @export
plot.lexdiv_batch_results <- plot.lexdiv_results

#' @export
plot.lexdiv_profile_results <- plot.lexdiv_results

#' @export
plot.lexdiv_profile_batch_results <- plot.lexdiv_results

#' @export
plot.lexdiv_text_results <- function(x, ...) {
  if (
    !inherits(x, "lexdiv_text_results") || !is.list(x) ||
      !inherits(x$results, "lexdiv_results") || !is.data.frame(x$results)
  ) {
    stop("x must be a lexdiv_text_results object.", call. = FALSE)
  }
  plot(x$results, ...)
}

#' @export
plot.lexdiv_screen_results <- function(
    x,
    screen_id = NULL,
    col = NULL,
    pch = 19,
    main = "Token-count screen",
    xlab = "document / request",
    ylab = "tokens",
    ...) {
  if (!is.data.frame(x) || !all(c("screen_id", "N", "minimum_tokens") %in% names(x))) {
    stop("x must be a lexdiv_screen_results table.", call. = FALSE)
  }
  available <- unique(x$screen_id)
  if (is.null(screen_id)) {
    if (length(available) != 1L) {
      stop("screen_id must select one screen when x contains several.", call. = FALSE)
    }
    screen_id <- available[[1L]]
  }
  screen_id <- .lex_convenience_name(screen_id, "screen_id")
  frame <- x[x$screen_id == screen_id & is.finite(x$N), , drop = FALSE]
  if (nrow(frame) == 0L) stop("The requested screen has no finite token counts.", call. = FALSE)
  labels <- if ("document_id" %in% names(frame)) frame$document_id else frame$request_id
  if (is.null(col)) col <- ifelse(frame$N >= frame$minimum_tokens, "#009E73", "#D55E00")
  positions <- seq_len(nrow(frame))
  graphics::plot(
    positions, frame$N, xaxt = "n", xlab = xlab, ylab = ylab,
    main = main, col = col, pch = pch, ...
  )
  graphics::axis(1, at = positions, labels = labels)
  graphics::abline(h = unique(frame$minimum_tokens), lty = 2, col = "grey40")
  invisible(frame)
}

#' @export
plot.tubelex_profile <- function(
    x,
    col = "#0072B2",
    main = "TUBELEX match coverage",
    ylab = "coverage",
    ...) {
  if (!inherits(x, "tubelex_profile") || !is.data.frame(x$summary)) {
    stop("x must be a tubelex_profile object.", call. = FALSE)
  }
  frame <- x$summary[c("weighting", "coverage")]
  if (any(!is.finite(frame$coverage))) {
    stop("The TUBELEX profile has no finite coverage to plot.", call. = FALSE)
  }
  positions <- graphics::barplot(
    frame$coverage,
    names.arg = frame$weighting,
    ylim = c(0, 1),
    col = col,
    main = main,
    ylab = ylab,
    ...
  )
  invisible(data.frame(
    weighting = frame$weighting,
    coverage = frame$coverage,
    position = as.double(positions),
    stringsAsFactors = FALSE,
    check.names = FALSE
  ))
}
