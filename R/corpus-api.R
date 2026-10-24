# Only the new search facade adds a class; legacy sourced calls keep plain lists.
.lexdiv_concordance_result <- function(x) {
  class(x) <- "lexdiv_concordance"
  x$integrity_sha256 <- .concordance_hash(x[names(x) != "integrity_sha256"])
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
  result
}

plot.lexdiv_concordance <- function(x, query_id, relative = TRUE,
                                    monochrome = FALSE, ...) {
  if (length(list(...)))
    stop("Unsupported plot arguments; use query_id, relative and monochrome.", call. = FALSE)
  p <- concordance_positions(x, query_id, relative, monochrome)
  print(p)
  invisible(list(occurrences = p$data, documents = p$layers[[1L]]$data,
    counts = x$counts[x$counts$query_id == query_id, , drop = FALSE]))
}
