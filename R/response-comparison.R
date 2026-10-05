# Descriptive paired binary responses; no automatic scoring or ability estimate.
#' Compare scored vocabulary responses with an explicit criterion
#'
#' Preserves learner/item keys, metadata and missing responses, and reports
#' directional disagreement with explicit complete-pair denominators.
#' @param data A data frame with one row per response pair.
#' @param test,criterion Names of distinct numeric or logical 0/1/NA columns.
#' @param keys Character vector of columns jointly identifying each pair.
#' @param by Character vector of categorical columns to tabulate separately.
#' @return A list with responses, counts, summary and provenance.
#' @export
lexdiv_compare_responses <- function(data, test, criterion,
    keys = c("learner_id", "item_id"), by = character()) {
  if (!is.data.frame(data)) stop("data must be a data frame.", call. = FALSE)
  column_names <- .lex_batch_column_names(names(data))
  if (any(!nzchar(column_names)) || anyDuplicated(column_names)) {
    stop("data must have non-empty, unique column names.", call. = FALSE)
  }
  test <- .lex_batch_scalar_name(test, "test")
  criterion <- .lex_batch_scalar_name(criterion, "criterion")
  if (test == criterion) stop("test and criterion must be distinct columns.", call. = FALSE)
  for (argument in c("keys", "by")) {
    value <- get(argument)
    if (!is.character(value) || !is.null(attributes(value)) || anyNA(value) ||
        any(!nzchar(value)) || any(!validUTF8(value)) ||
        any(Encoding(value) %in% c("bytes", "latin1")) || anyDuplicated(value) ||
        (argument == "keys" && !length(value))) {
      stop(sprintf("%s must be distinct, non-empty UTF-8 column names%s.",
        argument, if (argument == "by") " (or character())" else ""), call. = FALSE)
    }
  }
  if (!all(c(test, criterion, keys, by) %in% column_names)) {
    stop("Every selected column must exist in data.", call. = FALSE)
  }
  if (any(c(test, criterion) %in% c(keys, by))) {
    stop("Score columns cannot be used as keys or grouping columns.", call. = FALSE)
  }
  reserved <- c("comparison_outcome", "outcome", "n", "quantity", "numerator",
    "denominator", "proportion")
  if ("comparison_outcome" %in% column_names || any(by %in% reserved)) {
    stop("A selected name conflicts with a comparison output column.", call. = FALSE)
  }
  data <- as.data.frame(data)
  # Compare exact text keys. Only encoding markers change on these local copies.
  labels <- lapply(unique(c(keys, by)), function(name) {
    value <- data[[name]]
    if (is.factor(value)) value <- as.character(value)
    if (!is.character(value) || !is.null(attributes(value)) ||
        any(!validUTF8(value)) || any(Encoding(value) %in% c("bytes", "latin1")) ||
        any(!nzchar(trimws(value[!is.na(value)]))) ||
        (name %in% keys && anyNA(value))) {
      stop(sprintf("Column %s must contain non-blank UTF-8 character/factor labels; keys cannot be missing.",
        encodeString(name, quote = '"')), call. = FALSE)
    }
    Encoding(value) <- "UTF-8"
    value
  })
  names(labels) <- unique(c(keys, by))
  if (anyDuplicated(as.data.frame(labels[keys], optional = TRUE))) {
    stop("keys must jointly identify unique pairs; include occasion/format IDs for repeated observations.", call. = FALSE)
  }
  for (name in c(test, criterion)) {
    value <- data[[name]]
    if (!(is.numeric(value) || is.logical(value)) || !is.null(attributes(value)) ||
        any(is.nan(value)) || any(!is.na(value) & !(value %in% c(0, 1)))) {
      stop(sprintf("Score column %s must contain only numeric/logical 0, 1 or NA; partial credit must be handled explicitly.",
        encodeString(name, quote = '"')), call. = FALSE)
    }
  }
  a <- data[[test]]
  b <- data[[criterion]]
  complete <- !is.na(a) & !is.na(b)
  outcomes <- c("both_correct", "test_only", "criterion_only", "both_incorrect",
    "missing_test", "missing_criterion", "missing_both")
  outcome <- rep.int("missing_both", nrow(data))
  outcome[is.na(a) & !is.na(b)] <- "missing_test"
  outcome[!is.na(a) & is.na(b)] <- "missing_criterion"
  outcome[complete] <- outcomes[1L + 2L * (1L - a[complete]) + (1L - b[complete])]
  data$comparison_outcome <- outcome
  if (length(by)) {
    # Integer codes avoid collisions between labels containing separators.
    code <- do.call(paste, c(lapply(labels[by], function(x) match(x, unique(x))), sep = ":"))
    first <- !duplicated(code)
    groups <- data[first, by, drop = FALSE]
    rows <- unname(split(seq_len(nrow(data)), factor(code, levels = unique(code))))
  } else {
    groups <- data.frame(row.names = 1L)
    rows <- list(seq_len(nrow(data)))
  }
  quantities <- c("agreement_among_complete_pairs", "test_only_among_complete_pairs",
    "criterion_only_among_complete_pairs",
    "criterion_failure_among_test_correct_complete_pairs", "complete_pair_fraction")
  counts <- groups[rep(seq_len(nrow(groups)), each = length(outcomes)), , drop = FALSE]
  counts$outcome <- rep(outcomes, times = nrow(groups))
  counts$n <- integer(nrow(counts))
  summary <- groups[rep(seq_len(nrow(groups)), each = length(quantities)), , drop = FALSE]
  summary$quantity <- rep(quantities, times = nrow(groups))
  summary$numerator <- summary$denominator <- integer(nrow(summary))
  for (i in seq_along(rows)) {
    n <- tabulate(match(outcome[rows[[i]]], outcomes), nbins = length(outcomes))
    counts$n[(i - 1L) * length(outcomes) + seq_along(outcomes)] <- n
    j <- (i - 1L) * length(quantities) + seq_along(quantities)
    paired <- sum(n[1:4])
    summary$numerator[j] <- c(n[1] + n[4], n[2], n[3], n[2], paired)
    summary$denominator[j] <- c(rep(paired, 3L), n[1] + n[2], sum(n))
  }
  summary$proportion <- ifelse(summary$denominator == 0, NA_real_,
    summary$numerator / summary$denominator)
  rownames(counts) <- rownames(summary) <- NULL
  list(responses = data, counts = counts, summary = summary,
    provenance = list(comparison_version = "0.1.0", test = test, criterion = criterion,
      keys = keys, by = by, missing_policy = "retain; proportions use complete pairs except complete_pair_fraction"))
}
