# Source concordance.R into the same environment first. These are example helpers.
.ordination_seal <- function(x) {
  x$integrity_sha256 <- .concordance_hash(x)
  x
}

ordination_validate <- function(x) {
  if (!is.list(x) || !is.character(x$kind) || length(x$kind) != 1L ||
      is.na(x$kind) || !x$kind %in% c("table", "ca", "mds", "mca_table", "mca") ||
      !identical(x$integrity_sha256, .concordance_hash(x[names(x) != "integrity_sha256"])))
    stop("The saved ordination record changed; rebuild it from its source.", call. = FALSE)
  invisible(x)
}

ordination_table <- function(x, document_ids, preprocessing_id, term_col = "surface",
    keep = rep(TRUE, nrow(x$tokens)), min_count = 1L, min_documents = 1L,
    max_cells = 1e6, max_tokens = 1e6) {
  max_cells <- .concordance_whole(max_cells, "max_cells")
  max_tokens <- .concordance_whole(max_tokens, "max_tokens")
  min_count <- .concordance_whole(min_count, "min_count")
  min_documents <- .concordance_whole(min_documents, "min_documents")
  if (!is.list(x) || !identical(x$provenance$importer, "ldfreq-external-annotations"))
    stop("Supply an unchanged lexdiv_import_annotations() result.", call. = FALSE)
  checked <- ldfreq::lexdiv_import_annotations(x$tokens,
    x$segments[setdiff(names(x$segments), c("token_count", "text_sha256"))],
    x$provenance$annotation, max_tokens = max_tokens)
  if (!identical(x, checked))
    stop("Source annotations changed; import the complete source again.", call. = FALSE)
  strings <- function(z) is.character(z) && length(z) > 0L && !anyNA(z) &&
    all(validUTF8(z)) && all(nzchar(stringi::stri_trim_both(z)))
  ids <- x$documents$document_id
  if (!strings(document_ids) || anyDuplicated(document_ids) || !all(document_ids %in% ids))
    stop("document_ids must contain unique, known document IDs.", call. = FALSE)
  if (!strings(preprocessing_id) || length(preprocessing_id) != 1L)
    stop("preprocessing_id must describe one explicit selection policy.", call. = FALSE)
  if (!strings(term_col) || length(term_col) != 1L ||
      !term_col %in% names(x$tokens) || !is.character(x$tokens[[term_col]]))
    stop("term_col must name a character column in the source tokens.", call. = FALSE)
  if (!is.logical(keep) || length(keep) != nrow(x$tokens) || anyNA(keep))
    stop("keep must have one non-missing logical value per original token.", call. = FALSE)
  term <- enc2utf8(x$tokens[[term_col]])
  if (any(!validUTF8(term[!is.na(term)]))) stop("Terms must be valid UTF-8.", call. = FALSE)
  available <- !is.na(term) & nzchar(stringi::stri_trim_both(term))
  doc <- match(x$tokens$document_id, ids)
  requested <- ids %in% document_ids
  counted <- requested[doc] & keep & available
  documents <- data.frame(document_id = ids, requested = requested,
    source_tokens = tabulate(doc, length(ids)), kept_tokens = tabulate(doc[keep], length(ids)),
    missing_terms = tabulate(doc[keep & !available], length(ids)),
    counted_tokens = tabulate(doc[counted], length(ids)), stringsAsFactors = FALSE)
  documents$status <- with(documents, ifelse(!requested, "not_requested",
    ifelse(source_tokens == 0, "empty_source", ifelse(kept_tokens == 0, "no_selected_tokens",
    ifelse(missing_terms > 0, "incomplete_terms", "eligible")))))
  eligible <- documents$status == "eligible"
  vocabulary <- unique(term[counted])
  if (as.double(length(document_ids)) * length(vocabulary) > max_cells)
    stop("Document-term cells exceed max_cells; select fewer documents or terms.", call. = FALSE)
  counts <- matrix(0, length(document_ids), length(vocabulary),
    dimnames = list(document_ids, vocabulary))
  if (length(vocabulary)) {
    cell <- match(ids[doc[counted]], document_ids) +
      (match(term[counted], vocabulary) - 1L) * length(document_ids)
    counts[] <- tabulate(cell, length(counts))
  }
  complete <- counts[rownames(counts) %in% ids[eligible], , drop = FALSE]
  features <- data.frame(term = vocabulary, count = colSums(complete),
    documents = colSums(complete > 0), stringsAsFactors = FALSE, row.names = NULL)
  features$selected <- features$count >= min_count & features$documents >= min_documents
  active <- complete[, features$selected, drop = FALSE]
  active <- active[rowSums(active) > 0, , drop = FALSE]
  documents$active_tokens <- 0
  documents$active_tokens[match(rownames(active), ids)] <- rowSums(active)
  documents$status[eligible] <- ifelse(documents$active_tokens[eligible] > 0,
    "active", "no_selected_features")
  # A feature can become zero only when no active documents remain; retain its audit.
  active <- active[, colSums(active) > 0, drop = FALSE]
  token_audit <- data.frame(token_row = seq_len(nrow(x$tokens)), document_id = ids[doc],
    term = term, keep = keep, available = available, counted = counted,
    active = counted & ids[doc] %in% rownames(active) & term %in% colnames(active),
    stringsAsFactors = FALSE)
  occurrences <- x$tokens[token_audit$active,
    c("document_id", "segment_id", "token_index", "start", "end"), drop = FALSE]
  occurrences$token_row <- which(token_audit$active)
  occurrences$term <- term[token_audit$active]
  rownames(occurrences) <- NULL
  settings <- list(document_ids = document_ids, preprocessing_id = preprocessing_id,
    term_col = term_col, keep = keep, min_count = min_count, min_documents = min_documents,
    max_cells = max_cells, max_tokens = max_tokens,
    unit = "one-row-per-original-document; exact-UTF8 terms; no normalization",
    missing_policy = "exclude-whole-document-if-any-kept-term-is-unavailable",
    feature_population = "requested documents with complete selected terms; thresholds applied once")
  .ordination_seal(list(kind = "table", counts = counts, active_counts = active,
    documents = documents, features = features, token_audit = token_audit,
    occurrences = occurrences, source = x, settings = settings,
    provenance = list(recipe = "ldfreq-example-ordination", recipe_version = "1",
      ldfreq_version = as.character(utils::packageVersion("ldfreq")), R = R.version.string)))
}

.ordination_input <- function(x, k) {
  ordination_validate(x)
  if (!identical(x$kind, "table")) stop("Supply an ordination_table() record.", call. = FALSE)
  k <- .concordance_whole(k, "k")
  if (nrow(x$active_counts) < 2L || ncol(x$active_counts) < 1L)
    stop("At least two nonempty, complete active documents are needed; inspect documents.", call. = FALSE)
  k
}

ordination_ca <- function(x, k = 2L) {
  k <- .ordination_input(x, k)
  if (!requireNamespace("ca", quietly = TRUE))
    stop("Install the optional ca package to run correspondence analysis.", call. = FALSE)
  a <- x$active_counts
  if (ncol(a) < 2L) stop("CA needs at least two active terms.", call. = FALSE)
  p <- a / sum(a); r <- rowSums(p); c <- colSums(p)
  inertia <- sum((p - outer(r, c))^2 / outer(r, c))
  if (inertia <= .Machine$double.eps)
    stop("No nonzero CA inertia: the document profiles are identical.", call. = FALSE)
  fit <- ca::ca(a, nd = NA)
  eigenvalues <- fit$sv^2
  tolerance <- max(eigenvalues) * 1e-10
  dimensions <- seq_len(min(k, sum(eigenvalues > tolerance)))
  point_table <- function(id, standard, mass, distance) {
    do.call(rbind, lapply(dimensions, function(j) {
      coordinate <- standard[, j] * fit$sv[j]
      data.frame(id = id, axis = j, coordinate = coordinate, mass = mass,
        contribution = mass * standard[, j]^2,
        cos2 = ifelse(distance^2 > tolerance, coordinate^2 / distance^2, NA_real_),
        stringsAsFactors = FALSE, row.names = NULL)
    }))
  }
  .ordination_seal(list(kind = "ca", input = x, fit = fit,
    rows = point_table(rownames(a), fit$rowcoord, fit$rowmass, fit$rowdist),
    columns = point_table(colnames(a), fit$colcoord, fit$colmass, fit$coldist),
    axes = data.frame(axis = seq_along(eigenvalues), eigenvalue = eigenvalues,
      inertia_fraction = eigenvalues / sum(eigenvalues)),
    diagnostics = list(total_inertia = inertia, requested_dimensions = k,
      effective_dimensions = length(dimensions), eigenvalue_tolerance = tolerance),
    settings = list(coordinates = "principal; row and column maps plotted separately",
      weights = "observed row and column marginal proportions"),
    provenance = list(engine = "ca::ca", engine_version = as.character(utils::packageVersion("ca")),
      R = R.version.string)))
}

ordination_mds <- function(x, distance = c("jaccard", "hellinger"), k = 2L) {
  k <- .ordination_input(x, k)
  distance <- match.arg(distance)
  a <- x$active_counts
  n <- nrow(a)
  if (as.double(n) * n > x$settings$max_cells)
    stop("Document-distance cells exceed max_cells; select fewer documents.", call. = FALSE)
  if (distance == "jaccard") {
    present <- 1 * (a > 0)
    shared <- tcrossprod(present)
    union <- outer(rowSums(present), rowSums(present), "+") - shared
    d <- stats::as.dist(1 - shared / union)
  } else {
    d <- stats::dist(sqrt(a / rowSums(a)))
  }
  if (!any(d > 0))
    stop("All active distances are zero; there is no nontrivial MDS configuration.", call. = FALSE)
  warnings <- character()
  fit <- withCallingHandlers(stats::cmdscale(d, k = min(k, n - 1L), eig = TRUE, add = FALSE),
    warning = function(w) {
      if (grepl("only .* of the first .* eigenvalues are > 0", conditionMessage(w))) {
        warnings <<- c(warnings, conditionMessage(w))
        invokeRestart("muffleWarning")
      }
    })
  tolerance <- max(abs(fit$eig)) * 1e-10
  effective <- min(k, sum(fit$eig > tolerance), ncol(fit$points))
  points <- fit$points[, seq_len(effective), drop = FALSE]
  colnames(points) <- paste0("axis", seq_len(effective))
  fitted <- stats::dist(points)
  pair <- which(lower.tri(matrix(FALSE, n, n)), arr.ind = TRUE)
  pairs <- data.frame(document_a = rownames(a)[pair[, 2]], document_b = rownames(a)[pair[, 1]],
    original_distance = as.numeric(d), fitted_distance = as.numeric(fitted), stringsAsFactors = FALSE)
  squared_error <- (pairs$original_distance - pairs$fitted_distance)^2
  .ordination_seal(list(kind = "mds", input = x, distance = d, fit = fit, points = points,
    pairs = pairs, axes = data.frame(axis = seq_along(fit$eig), eigenvalue = fit$eig),
    diagnostics = list(requested_dimensions = k, effective_dimensions = effective,
      negative_eigenvalues = sum(fit$eig < -tolerance),
      negative_inertia_fraction = sum(abs(fit$eig[fit$eig < -tolerance])) / sum(abs(fit$eig)),
      eigenvalue_tolerance = tolerance, distance_rmse = sqrt(mean(squared_error)),
      relative_distance_error = sqrt(sum(squared_error) / sum(as.numeric(d)^2)),
      GOF = fit$GOF, engine_warnings = warnings),
    settings = list(distance = distance, correction = "none",
      distance_definition = if (distance == "jaccard") "1 - shared-types / union-types" else
        "Euclidean distance of square-root row proportions; no 1/sqrt(2) factor",
      inference = "descriptive configuration; no significance tests or automatic axis labels"),
    provenance = list(engine = "stats::cmdscale", engine_version = as.character(utils::packageVersion("stats")),
      R = R.version.string)))
}

ordination_occurrences <- function(x, term) {
  ordination_validate(x)
  if (!identical(x$kind, "table")) stop("Supply an ordination_table() record.", call. = FALSE)
  if (!is.character(term) || length(term) != 1L || is.na(term) || !term %in% colnames(x$active_counts))
    stop("term must select one exact active term.", call. = FALSE)
  hits <- x$occurrences[x$occurrences$term == term, , drop = FALSE]
  source_key <- paste(x$source$segments$document_id, x$source$segments$segment_id, sep = "\r")
  hit_key <- paste(hits$document_id, hits$segment_id, sep = "\r")
  hits$text <- x$source$segments$text[match(hit_key, source_key)]
  hits$surface <- stringi::stri_sub(hits$text, hits$start, hits$end)
  hits
}

ordination_plot <- function(x, which = c("documents", "terms"), monochrome = FALSE) {
  ordination_validate(x)
  which <- match.arg(which)
  if (!is.logical(monochrome) || length(monochrome) != 1L || is.na(monochrome))
    stop("monochrome must be TRUE or FALSE.", call. = FALSE)
  if (x$kind == "ca") {
    data <- if (which == "documents") x$rows else x$columns
    first <- data[data$axis == 1L, ]
    second <- data[data$axis == 2L, ]
    plotted <- data.frame(id = first$id, x = first$coordinate,
      y = if (nrow(second)) second$coordinate[match(first$id, second$id)] else 0)
    label <- sprintf("CA %d (%.1f%% inertia)", 1:2, 100 * x$axes$inertia_fraction[1:2])
  } else if (x$kind == "mds") {
    if (which != "documents") stop("MDS supplies document coordinates only.", call. = FALSE)
    plotted <- data.frame(id = rownames(x$points), x = x$points[, 1],
      y = if (ncol(x$points) >= 2L) x$points[, 2] else 0)
    label <- c("PCoA 1", "PCoA 2")
  } else stop("Supply an ordination_ca() or ordination_mds() record.", call. = FALSE)
  one_dimensional <- x$diagnostics$effective_dimensions < 2L
  expand <- function(z) range(z) + c(-.2, .2) * max(diff(range(z)), .1)
  graphics::plot(plotted$x, plotted$y, asp = 1, pch = if (which == "documents") 16 else 17,
    col = if (monochrome) "black" else if (which == "documents") "#0072B2" else "#D55E00",
    xlab = label[1], ylab = if (one_dimensional) "" else label[2],
    yaxt = if (one_dimensional) "n" else "s", xlim = expand(plotted$x), ylim = expand(plotted$y))
  # Combine co-located display labels without jittering fitted coordinates.
  location <- paste(signif(plotted$x, 8), signif(plotted$y, 8), sep = ":")
  first <- !duplicated(location)
  labels <- vapply(location[first], function(z) paste(plotted$id[location == z], collapse = "/"), "")
  graphics::text(plotted$x[first], plotted$y[first], labels = labels, pos = 3, cex = .8)
  invisible(plotted)
}
