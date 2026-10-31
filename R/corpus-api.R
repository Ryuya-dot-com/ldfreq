.lexdiv_concordance_result <- function(x) {
  x$integrity_sha256 <- .concordance_hash(unclass(x[names(x) != "integrity_sha256"]))
  class(x) <- "lexdiv_concordance"
  x
}

lexdiv_concordance <- function(x, queries, term_col = "surface",
    valuetype = c("fixed", "glob", "regex"), case_insensitive = FALSE,
    keep = rep(TRUE, nrow(x$tokens)), window = 5L, max_cells = 1e6) {
  .lexdiv_concordance_result(concordance_search(x, queries, term_col,
    valuetype, case_insensitive, keep, window, max_cells))
}

lexdiv_keyness_concordance <- function(x, term, window = 5L, max_cells = 1e6) {
  result <- keyness_concordance(x, term, window, max_cells)
  result$search <- .lexdiv_concordance_result(result$search)
  class(result) <- "lexdiv_keyness_concordance"
  result
}

#' @export
print.lexdiv_concordance <- function(x, ...) {
  .concordance_check(x)
  cat(sprintf(
    "<lexdiv_concordance: %d document%s; %d quer%s; %d occurrence%s>\n",
    nrow(x$documents), if (nrow(x$documents) == 1L) "" else "s",
    length(x$queries), if (length(x$queries) == 1L) "y" else "ies",
    nrow(x$occurrences), if (nrow(x$occurrences) == 1L) "" else "s"
  ))
  cols <- intersect(
    c("query_id", "document_id", "segment_id", "from", "to", "pre", "keyword", "post"),
    names(x$occurrences)
  )
  shown <- utils::head(x$occurrences[cols], 12L)
  print.data.frame(shown, row.names = FALSE, ...)
  if (nrow(x$occurrences) > nrow(shown)) {
    cat(sprintf("... %d additional occurrence%s omitted\n",
      nrow(x$occurrences) - nrow(shown),
      if (nrow(x$occurrences) - nrow(shown) == 1L) "" else "s"))
  }
  invisible(x)
}

#' @export
print.lexdiv_keyness_concordance <- function(x, ...) {
  if (!inherits(x, "lexdiv_keyness_concordance") || !is.list(x) ||
      !inherits(x$search, "lexdiv_concordance")) {
    stop("x must be a lexdiv_keyness_concordance object.", call. = FALSE)
  }
  cat(sprintf("<lexdiv_keyness_concordance: term=%s>\n",
    encodeString(x$term, quote = "\"")))
  print(x$search, ...)
  invisible(x)
}

#' @export
plot.lexdiv_concordance <- function(
    x,
    query_id = NULL,
    relative = TRUE,
    monochrome = FALSE,
    col = NULL,
    main = NULL,
    xlab = NULL,
    ylab = "",
    ...) {
  concordance_positions(
    x = x,
    query_id = query_id,
    relative = relative,
    monochrome = monochrome,
    col = col,
    main = main,
    xlab = xlab,
    ylab = ylab,
    ...
  )
}
