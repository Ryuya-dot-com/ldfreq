# Explicitly sourced example helpers; one book and one unchanged saved search.
if (!exists("concordance_search", inherits = FALSE)) {
  sys.source(system.file("examples", "concordance.R", package = "ldfreq",
    mustWork = TRUE), envir = environment())
}

textbook_progression <- function(search, sections, targets,
    include = rep(TRUE, nrow(sections)), max_cells = 1e6) {
  .concordance_check(search)
  if (nrow(search$documents) != 1L)
    stop("Supply a search for exactly one book.", call. = FALSE)
  max_cells <- .concordance_whole(max_cells, "max_cells")
  required <- c("document_id", "segment_id", "page", "unit", "role", "observed")
  if (!is.data.frame(sections) || !nrow(sections) || !all(required %in% names(sections)) ||
      !is.data.frame(targets) || !all(c("query_id", "introduction_unit") %in% names(targets)))
    stop("Supply the documented section roster and target table.", call. = FALSE)
  text_ok <- function(x) is.character(x) && !anyNA(x) && all(validUTF8(x)) &&
    all(nzchar(stringi::stri_trim_both(x)))
  whole <- function(x, missing = FALSE) is.numeric(x) &&
    (missing || !anyNA(x)) && all(is.na(x) | (is.finite(x) & x >= 1 & x == floor(x)))
  if (!all(vapply(sections[c("document_id", "segment_id", "role")], text_ok, logical(1))) ||
      any(sections$document_id != search$documents$document_id) ||
      anyDuplicated(sections$segment_id) || !whole(sections$page) || !whole(sections$unit) ||
      any(diff(sections$page) < 0) || any(diff(sections$unit) < 0) ||
      !is.logical(sections$observed) || anyNA(sections$observed) ||
      !is.logical(include) || length(include) != nrow(sections) || anyNA(include))
    stop("Sections need unique IDs, ordered positive page/unit numbers and logical flags.",
      call. = FALSE)
  if (!text_ok(targets$query_id) || anyDuplicated(targets$query_id) ||
      !setequal(targets$query_id, names(search$queries)) ||
      !whole(targets$introduction_unit, missing = TRUE) ||
      any(!is.na(targets$introduction_unit) &
        !targets$introduction_unit %in% sections$unit))
    stop("Targets must match saved queries; introduction_unit must be a listed unit or NA.",
      call. = FALSE)
  pages <- sections[!duplicated(sections$page), c("page", "unit"), drop = FALSE]
  if (any(sections$unit != pages$unit[match(sections$page, pages$page)]))
    stop("Each page must belong to exactly one unit.", call. = FALSE)
  source <- search$source$segments
  source_row <- match(source$segment_id, sections$segment_id)
  if (anyNA(source_row) || any(diff(source_row) <= 0) ||
      !identical(which(sections$observed), as.integer(source_row)))
    stop("Observed sections must match all saved source segments in their original order.",
      call. = FALSE)
  if ((nrow(pages) + length(unique(sections$unit))) * as.double(nrow(targets)) > max_cells)
    stop("Page/unit query cells exceed max_cells.", call. = FALSE)
  sections$included <- include
  sections$source_tokens <- sections$searchable_tokens <- sections$missing_terms <- NA_integer_
  token_row <- match(search$source$tokens$segment_id, source$segment_id)
  sections$source_tokens[source_row] <- source$token_count
  sections$searchable_tokens[source_row] <- tabulate(
    token_row[search$settings$searchable], nrow(source))
  sections$missing_terms[source_row] <- tabulate(
    token_row[search$settings$keep & !search$settings$searchable], nrow(source))
  sections$complete <- !include |
    (sections$observed & !is.na(sections$missing_terms) & sections$missing_terms == 0)
  hits <- search$occurrences
  section_row <- match(hits$segment_id, sections$segment_id)
  hits <- cbind(hits, sections[section_row, c("page", "unit", "role", "included"), drop = FALSE])
  rownames(hits) <- NULL

  tabulate_progress <- function(by) {
    progress <- unique(sections[[by]])
    answer <- expand.grid(progress = progress, query_id = targets$query_id,
      KEEP.OUT.ATTRS = FALSE, stringsAsFactors = FALSE)
    names(answer)[1] <- by
    h <- hits[hits$included, , drop = FALSE]
    cell <- match(h[[by]], progress) + (match(h$query_id, targets$query_id) - 1L) * length(progress)
    answer$observed_occurrences <- tabulate(cell, nrow(answer))
    groups <- lapply(progress, function(value) which(sections[[by]] == value))
    selected <- vapply(groups, function(i) sum(sections$included[i]), integer(1))
    complete <- vapply(groups, function(i) all(sections$complete[i]), logical(1))
    answer$selected_sections <- rep(selected, nrow(targets))
    answer$complete <- rep(complete, nrow(targets))
    answer$occurrences <- ifelse(answer$complete, answer$observed_occurrences, NA_integer_)
    answer$status <- ifelse(answer$selected_sections == 0, "not_selected",
      ifelse(answer$complete, "ok", "incomplete"))
    answer$cumulative <- ave(answer$occurrences, answer$query_id, FUN = cumsum)
    answer$observed_cumulative <- ave(answer$observed_occurrences, answer$query_id, FUN = cumsum)
    answer
  }
  page_counts <- tabulate_progress("page")
  page_counts$unit <- pages$unit[match(page_counts$page, pages$page)]
  unit_counts <- tabulate_progress("unit")
  summary <- do.call(rbind, lapply(seq_len(nrow(targets)), function(i) {
    q <- targets$query_id[i]
    p <- page_counts[page_counts$query_id == q, ]
    u <- unit_counts[unit_counts$query_id == q, ]
    observed_pages <- p$page[p$observed_occurrences > 0]
    intro <- targets$introduction_unit[i]
    later <- u[!is.na(intro) & u$unit > intro & u$selected_sections > 0, ]
    reason <- if (is.na(intro)) "unknown_introduction" else if (!nrow(later))
      "no_later_units" else if (!all(later$complete)) "incomplete_later_units" else "ok"
    data.frame(query_id = q, observed_occurrences = sum(p$observed_occurrences),
      occurrences = sum(p$occurrences),
      first_observed_page = if (length(observed_pages)) min(observed_pages) else NA_real_,
      last_observed_page = if (length(observed_pages)) max(observed_pages) else NA_real_,
      observed_units_with_hits = sum(u$observed_occurrences > 0),
      introduction_unit = intro,
      later_units = if (is.na(intro)) NA_integer_ else nrow(later),
      complete_later_units = if (is.na(intro)) NA_integer_ else sum(later$complete),
      observed_later_occurrences = if (is.na(intro)) NA_integer_ else sum(later$observed_occurrences),
      later_occurrences = if (reason == "ok") sum(later$occurrences) else NA_real_,
      later_unit_coverage = if (reason == "ok") mean(later$occurrences > 0) else NA_real_,
      later_status = reason)
  }))
  result <- list(pages = page_counts, units = unit_counts, summary = summary,
    occurrences = hits, sections = sections, targets = targets, search = search,
    settings = list(recipe_version = "1", max_cells = max_cells,
      scope = "one-book; supplied-page-unit-order; included-sections",
      cumulative = "exact-total-NA-from-first-incomplete-selected-section",
      recurrence = "selected-units-strictly-after-declared-introduction-unit",
      source = "unchanged-concordance; no-cross-segment-matches"))
  result$integrity_sha256 <- .concordance_hash(result)
  result
}

.textbook_check <- function(x) {
  if (!is.list(x) || !identical(x$settings$recipe_version, "1") ||
      !identical(x$integrity_sha256, .concordance_hash(x[names(x) != "integrity_sha256"])))
    stop("The saved progression changed; recreate it from the original search and roster.",
      call. = FALSE)
  invisible(x)
}

textbook_progression_plot <- function(x, by = c("page", "unit"),
    cumulative = FALSE, monochrome = FALSE) {
  .textbook_check(x)
  by <- match.arg(by)
  for (flag in list(cumulative, monochrome))
    if (!is.logical(flag) || length(flag) != 1L || is.na(flag))
      stop("Plot flags must be TRUE or FALSE.", call. = FALSE)
  if (!requireNamespace("ggplot2", quietly = TRUE))
    stop("Install optional ggplot2 to draw progression.", call. = FALSE)
  d <- x[[if (by == "page") "pages" else "units"]]
  d$progress <- d[[by]]
  d$target <- factor(d$query_id, levels = rev(x$targets$query_id))
  d$value <- if (cumulative) d$cumulative else d$occurrences
  d$display_label <- ifelse(is.na(d$value), "NA", as.character(d$value))
  if (!cumulative) d$display_label[d$status == "not_selected"] <- "\u2014"
  finite <- d$value[is.finite(d$value)]
  top <- max(c(1, finite))
  d$text_colour <- ifelse(!is.na(d$value) & d$value > top * .55, "white", "black")
  ggplot2::ggplot(d, ggplot2::aes(progress, target)) +
    ggplot2::geom_tile(ggplot2::aes(fill = value), width = .95, height = .92,
      colour = "grey60", linewidth = .3) +
    ggplot2::geom_text(ggplot2::aes(label = display_label, colour = text_colour), size = 3.4) +
    ggplot2::scale_colour_identity() +
    ggplot2::scale_fill_gradient(low = "white", high = if (monochrome) "#333333" else "#005A82",
      limits = c(0, top), na.value = "#E5E5E5", guide = "none") +
    ggplot2::scale_x_continuous(breaks = unique(d[[by]]),
      expand = ggplot2::expansion(add = .55)) +
    ggplot2::scale_y_discrete(drop = FALSE, expand = ggplot2::expansion(add = .05)) +
    ggplot2::labs(x = if (by == "page") "Page" else "Unit", y = "Target query") +
    ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(panel.grid = ggplot2::element_blank())
}
