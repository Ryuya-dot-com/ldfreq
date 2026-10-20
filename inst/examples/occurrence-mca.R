# Source concordance.R and lexical-ordination.R into the same environment first.
# Explicitly sourced examples, not exported APIs or automatic category coders.
ordination_mca_table <- function(source, occurrences, definitions, coding_id,
                                 max_cells = 1e6, max_tokens = 1e6) {
  fail <- function(message) stop(message, call. = FALSE)
  strings <- function(z) is.character(z) && !is.object(z) && is.null(dim(z)) &&
    length(z) > 0L && !anyNA(z) && all(validUTF8(z)) &&
    all(nzchar(stringi::stri_trim_both(z)))
  max_cells <- .concordance_whole(max_cells, "max_cells")
  max_tokens <- .concordance_whole(max_tokens, "max_tokens")
  if (!is.list(source) || !identical(source$provenance$importer, "ldfreq-external-annotations"))
    fail("Supply an unchanged lexdiv_import_annotations() result.")
  checked <- ldfreq::lexdiv_import_annotations(source$tokens,
    source$segments[setdiff(names(source$segments), c("token_count", "text_sha256"))],
    source$provenance$annotation, max_tokens = max_tokens)
  if (!identical(checked, source)) fail("Source annotations changed; import the complete source again.")
  anchors <- c("document_id", "segment_id", "token_index", "start", "end", "surface")
  if (!is.data.frame(occurrences) || anyDuplicated(names(occurrences)) ||
      !all(c("occurrence_id", anchors) %in% names(occurrences)) ||
      !strings(occurrences$occurrence_id) || anyDuplicated(occurrences$occurrence_id) ||
      anyDuplicated(occurrences[anchors]) || "source_text" %in% names(occurrences))
    fail("Supply unique occurrence IDs and one row per original token with complete source anchors.")
  if (!all(vapply(occurrences[c("document_id", "segment_id", "surface")], strings, TRUE)) ||
      !all(vapply(occurrences[c("token_index", "start", "end")], function(z)
        is.numeric(z) && !is.object(z) && all(is.finite(z) & z >= 1 & z == floor(z)), TRUE)))
    fail("Source anchors must retain original strings and positive integer positions.")
  # Check all columns together: neither row order nor a concatenated key defines identity.
  linked <- merge(occurrences[anchors], source$tokens[anchors], by = anchors)
  if (nrow(linked) != nrow(occurrences)) fail("Occurrence anchors do not match the original source tokens.")
  variables <- names(definitions)
  if (!strings(definitions) || !strings(variables) || length(variables) < 2L ||
      anyDuplicated(variables) || !all(variables %in% names(occurrences)) ||
      any(variables %in% c("occurrence_id", anchors)) ||
      !strings(coding_id) || length(coding_id) != 1L)
    fail("Define at least two distinct category columns and one coding_id; keep source IDs out of the active variables.")
  if (!all(vapply(occurrences[variables], function(z)
    (is.character(z) && !is.object(z) && is.null(dim(z))) ||
      (is.factor(z) && !is.ordered(z)), TRUE)))
    fail("Active categories must be character or unordered factors; do not silently bin numeric variables.")
  values <- lapply(occurrences[variables], as.character)
  levels_by_variable <- lapply(seq_along(variables), function(j) {
    z <- occurrences[[variables[j]]]
    if (is.factor(z)) levels(z) else unique(z[!is.na(z)])
  })
  if (any(vapply(levels_by_variable, function(z) length(z) > 0L && !strings(z), TRUE)))
    fail("Category levels must be nonblank valid UTF-8 strings; use NA for missing codes.")
  missing <- as.data.frame(lapply(values, is.na))
  active <- rowSums(missing) == 0L
  observations <- data.frame(occurrence_id = occurrences$occurrence_id, active = active,
    status = ifelse(active, "active", "missing_active_category"),
    missing_variables = apply(missing, 1, function(z) paste(variables[z], collapse = ",")),
    stringsAsFactors = FALSE)
  categories <- do.call(rbind, lapply(seq_along(variables), function(j) {
    lev <- levels_by_variable[[j]]
    data.frame(category_id = if (length(lev)) paste0("v", j, "l", seq_along(lev)) else character(),
      variable = rep(variables[j], length(lev)), level = lev,
      observed_n = tabulate(match(values[[j]], lev), length(lev)),
      active_n = tabulate(match(values[[j]][active], lev), length(lev)),
      stringsAsFactors = FALSE)
  }))
  rownames(categories) <- NULL
  categories$active <- categories$active_n > 0L
  categories$status <- ifelse(categories$active, "active", "no_complete_observations")
  variable_table <- data.frame(variable = variables, definition = unname(definitions),
    missing_n = colSums(missing),
    active_levels = vapply(variables, function(z) sum(categories$variable == z & categories$active), 0L),
    stringsAsFactors = FALSE, row.names = NULL)
  if (as.double(sum(active)) * sum(categories$active) > max_cells)
    fail("Indicator cells exceed max_cells; select fewer occurrences or variables.")
  cols <- categories[categories$active, , drop = FALSE]
  indicator <- matrix(0, sum(active), nrow(cols),
    dimnames = list(occurrences$occurrence_id[active], cols$category_id))
  for (j in seq_len(nrow(cols)))
    indicator[, j] <- as.integer(values[[cols$variable[j]]][active] == cols$level[j])
  .ordination_seal(list(kind = "mca_table", source = source, occurrences = occurrences,
    observations = observations, categories = categories, variables = variable_table,
    indicator = indicator,
    settings = list(coding_id = coding_id, definitions = definitions,
      missing_policy = "complete-observations; no imputation or missing category",
      weighting = "equal occurrences; not equal writers", max_cells = max_cells, max_tokens = max_tokens),
    provenance = list(recipe = "ldfreq-example-occurrence-mca", recipe_version = "1",
      ldfreq_version = as.character(utils::packageVersion("ldfreq")), R = R.version.string)))
}

ordination_mca <- function(x, k = 2L) {
  ordination_validate(x)
  if (!identical(x$kind, "mca_table")) stop("Supply an ordination_mca_table() record.", call. = FALSE)
  k <- .concordance_whole(k, "k")
  if (nrow(x$indicator) < 2L || any(x$variables$active_levels < 2L))
    stop("MCA needs at least two complete observations and two active levels per variable; inspect the table audit.", call. = FALSE)
  if (!requireNamespace("ca", quietly = TRUE)) stop("Install the optional ca package for MCA.", call. = FALSE)
  z <- x$indicator
  p <- z / sum(z); r <- rowSums(p); c <- colSums(p)
  residual <- (p - outer(r, c)) / sqrt(outer(r, c))
  total <- sum(residual^2)
  fit <- ca::ca(z, nd = NA)
  eigenvalues <- fit$sv^2
  tolerance <- max(eigenvalues) * 1e-10
  rank <- sum(eigenvalues > tolerance)
  dimensions <- seq_len(min(k, rank))
  distances <- list(rows = sqrt(rowSums(residual^2) / r),
    categories = sqrt(colSums(residual^2) / c))
  points <- function(ids, standard, mass, distance) {
    do.call(rbind, lapply(dimensions, function(j) {
      coordinate <- standard[, j] * fit$sv[j]
      data.frame(id = ids, axis = j, coordinate = coordinate, mass = mass,
        distance = distance, contribution = mass * standard[, j]^2,
        cos2 = ifelse(distance^2 > tolerance, coordinate^2 / distance^2, NA_real_),
        stringsAsFactors = FALSE, row.names = NULL)
    }))
  }
  rows <- points(rownames(z), fit$rowcoord, r, distances$rows)
  categories <- points(colnames(z), fit$colcoord, c, distances$categories)
  j <- match(categories$id, x$categories$category_id)
  categories$variable <- x$categories$variable[j]
  categories$level <- x$categories$level[j]
  tied <- c(diff(eigenvalues) >= -tolerance, FALSE)
  cut <- length(dimensions)
  .ordination_seal(list(kind = "mca", input = x, fit = fit, rows = rows, categories = categories,
    axes = data.frame(axis = seq_along(eigenvalues), eigenvalue = eigenvalues,
      inertia_fraction = eigenvalues / total, retained = seq_along(eigenvalues) %in% dimensions,
      tied_with_next = tied),
    diagnostics = list(total_inertia = total, indicator_inertia = (ncol(z) - nrow(x$variables)) / nrow(x$variables),
      requested_dimensions = k, effective_dimensions = cut, numerical_rank = rank,
      eigenvalue_tolerance = tolerance,
      retained_fraction = sum(eigenvalues[dimensions]) / total,
      cut_through_tied_axes = cut < rank && tied[cut]),
    settings = list(method = "indicator MCA via ca::ca; unadjusted inertia",
      coordinates = "principal; occurrence and category maps kept separate",
      weighting = "equal complete occurrences; category mass = count / (n * variables)",
      inference = "descriptive; no automatic labels, tests or writer-weight adjustment"),
    provenance = list(recipe_version = "1", engine = "ca::ca",
      engine_version = as.character(utils::packageVersion("ca")), R = R.version.string)))
}

ordination_mca_occurrences <- function(x, ids = x$occurrences$occurrence_id) {
  ordination_validate(x)
  if (!identical(x$kind, "mca_table")) stop("Supply an ordination_mca_table() record.", call. = FALSE)
  if (!is.character(ids) || anyNA(ids) || anyDuplicated(ids) || !all(ids %in% x$occurrences$occurrence_id))
    stop("Select unique known occurrence IDs.", call. = FALSE)
  out <- x$occurrences[match(ids, x$occurrences$occurrence_id), , drop = FALSE]
  # Join each source pair without assuming an ID separator cannot occur in the input.
  out$source_text <- vapply(seq_len(nrow(out)), function(i) {
    j <- x$source$segments$document_id == out$document_id[i] &
      x$source$segments$segment_id == out$segment_id[i]
    x$source$segments$text[j]
  }, "")
  rownames(out) <- NULL
  out
}

ordination_mca_plot <- function(x, which = c("occurrences", "categories"), monochrome = FALSE) {
  ordination_validate(x)
  if (!identical(x$kind, "mca")) stop("Supply an ordination_mca() record.", call. = FALSE)
  which <- match.arg(which)
  if (!is.logical(monochrome) || length(monochrome) != 1L || is.na(monochrome))
    stop("monochrome must be TRUE or FALSE.", call. = FALSE)
  a <- if (which == "occurrences") x$rows else x$categories
  first <- a[a$axis == 1L, ]; second <- a[a$axis == 2L, ]
  plotted <- data.frame(id = first$id, x = first$coordinate,
    y = if (nrow(second)) second$coordinate[match(first$id, second$id)] else 0,
    label = if (which == "categories") paste(first$variable, first$level, sep = ": ") else first$id)
  if (x$axes$tied_with_next[1] || (nrow(second) > 0L && x$axes$tied_with_next[2]))
    warning("Displayed axes touch a repeated eigenvalue; their orientation is not unique. Inspect axes and diagnostics.", call. = FALSE)
  expand <- function(z) range(z) + c(-.25, .25) * max(diff(range(z)), .1)
  labels <- sprintf("MCA %d (%.1f%% unadjusted inertia)", 1:2, 100 * x$axes$inertia_fraction[1:2])
  graphics::plot(plotted$x, plotted$y, asp = 1, las = 1, bty = "l",
    pch = if (which == "occurrences") 16 else 17,
    col = if (monochrome) "black" else if (which == "occurrences") "#0072B2" else "#D55E00",
    xlab = labels[1], ylab = if (nrow(second)) labels[2] else "",
    yaxt = if (nrow(second)) "s" else "n", xlim = expand(plotted$x), ylim = expand(plotted$y))
  location <- paste(signif(plotted$x, 8), signif(plotted$y, 8), sep = ":")
  selected <- !duplicated(location)
  text <- vapply(location[selected], function(z) paste(plotted$label[location == z], collapse = "/"), "")
  graphics::text(plotted$x[selected], plotted$y[selected], labels = text, pos = 3, cex = .75)
  invisible(plotted)
}
