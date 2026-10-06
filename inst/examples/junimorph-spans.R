# Explicit local recipe; no downloads, analyzer, corpus or reference data bundled.
# Source this file before junimorph-spans-demo.R. Not an exported package API.
.morph_span_hash <- function(x) digest::digest(x, algo = "sha256", serializeVersion = 2L)

# Preserve the three original fields, source row order and duplicate records.
read_junimorph <- function(path, resource) {
  required <- c("resource_id", "resource_version", "source_reference", "data_license")
  if (!is.list(resource) || is.null(names(resource)) || anyDuplicated(names(resource)) ||
      !all(required %in% names(resource)) ||
      !all(vapply(resource, function(z) is.character(z) && length(z) == 1L &&
        !is.na(z) && nzchar(trimws(z)), logical(1))))
    stop("Supply named, nonblank resource metadata: ", paste(required, collapse = ", "))
  if (!is.character(path) || length(path) != 1L || is.na(path) || !file.exists(path))
    stop("path must identify one local UTF-8 three-column file.")
  bytes <- readBin(path, "raw", n = file.info(path)$size)
  if (!length(bytes) || any(bytes == as.raw(0))) stop("Reference is empty or contains NUL.")
  text <- rawToChar(bytes)
  if (!validUTF8(text)) stop("Reference must be valid UTF-8.")
  Encoding(text) <- "UTF-8"
  lines <- strsplit(text, "\n", fixed = TRUE)[[1L]]
  lines <- sub("\r$", "", lines)
  fields <- strsplit(lines, "\t", fixed = TRUE)
  if (any(lengths(fields) != 3L)) stop("Each source row must have exactly three tab-separated fields.")
  records <- as.data.frame(do.call(rbind, fields), stringsAsFactors = FALSE)
  names(records) <- c("lemma", "form", "features")
  if (any(!nzchar(trimws(as.matrix(records)))) ||
      any(stringi::stri_detect_regex(records$form, "\\p{White_Space}")))
    stop("Reference fields must be nonblank; forms must not contain whitespace.")
  records$source_row <- seq_len(nrow(records))
  records$candidate_id <- paste0("row-", records$source_row)
  resource$file_sha256 <- digest::digest(bytes, algo = "sha256", serialize = FALSE)
  out <- list(records = records, resource = resource)
  out$content_sha256 <- .morph_span_hash(out)
  out
}

# Exact character spans, checked against complete imported token boundaries.
# KWIC context is measured in original Unicode codepoints, not token windows.
# This is a bounded local example: one fixed-string scan per form and segment;
# use a separately validated dictionary matcher if corpus-scale scans are needed.
review_morphology_spans <- function(x, reference, targets = unique(reference$records$form),
                                    decisions = NULL, window = 20L) {
  if (!is.list(reference) || !identical(reference$content_sha256,
      .morph_span_hash(reference[c("records", "resource")])))
    stop("Use an unmodified read_junimorph() result.")
  if (!is.list(x) || !all(c("tokens", "segments", "provenance") %in% names(x)))
    stop("Use complete lexdiv_import_annotations() input.")
  checked <- ldfreq::lexdiv_import_annotations(x$tokens,
    x$segments[setdiff(names(x$segments), c("token_count", "text_sha256"))],
    x$provenance$annotation)
  if (!identical(x, checked)) stop("Source changed; import complete annotations again.")
  if (!is.character(targets) || !is.null(dim(targets)) || !length(targets) ||
      anyNA(targets) || any(Encoding(targets) %in% c("bytes", "latin1")) ||
      any(!validUTF8(targets)) || any(!nzchar(targets)) ||
      any(stringi::stri_detect_regex(targets, "\\p{White_Space}")))
    stop("targets must be nonempty exact UTF-8 forms without whitespace.")
  # Mark already validated UTF-8 bytes explicitly, including restored RDS strings.
  Encoding(targets) <- "UTF-8"
  targets <- sort(unique(unname(targets)), method = "radix")
  if (!is.numeric(window) || length(window) != 1L || is.na(window) ||
      !is.finite(window) || window < 0 || window != floor(window) || window > .Machine$integer.max)
    stop("window must be one non-negative whole number of codepoints.")
  records <- reference$records
  candidates <- records[records$form %in% targets, , drop = FALSE]
  counts <- tabulate(match(candidates$form, targets), nbins = length(targets))
  review_id <- .morph_span_hash(list("morphology-spans-example-v1",
    x$provenance$input_sha256, reference$content_sha256, targets))
  empty <- data.frame(document_id = character(), segment_id = character(),
    start = integer(), end = integer(), form = character(), token_from = integer(),
    token_to = integer(), token_count = integer(), boundary_status = character(),
    overlap_n = integer(), pre = character(), keyword = character(), post = character(),
    occurrence_id = character())
  pieces <- lapply(seq_len(nrow(x$segments)), function(i) {
    s <- x$segments[i, ]; text <- s$text
    t <- x$tokens[x$tokens$document_id == s$document_id &
      x$tokens$segment_id == s$segment_id, , drop = FALSE]
    hits <- stringi::stri_locate_all_fixed(text, targets, overlap = TRUE, omit_no_match = TRUE)
    n <- vapply(hits, nrow, integer(1))
    if (!sum(n)) return(empty)
    positions <- do.call(rbind, hits)
    out <- data.frame(document_id = s$document_id, segment_id = s$segment_id,
      start = positions[, 1L], end = positions[, 2L], form = rep(targets, n))
    out <- out[order(out$start, out$end, out$form, method = "radix"), , drop = FALSE]
    from <- match(out$start, t$start); to <- match(out$end, t$end)
    aligned <- !is.na(from) & !is.na(to)
    out$token_from <- t$token_index[from]; out$token_to <- t$token_index[to]
    out$token_count <- ifelse(aligned, out$token_to - out$token_from + 1L, NA_integer_)
    out$boundary_status <- ifelse(aligned, "token_aligned", "boundary_mismatch")
    out$overlap_n <- findInterval(out$end, sort(out$start)) -
      findInterval(out$start - 1L, sort(out$end)) - 1L
    out$pre <- substring(text, pmax(1, out$start - window), out$start - 1L)
    out$keyword <- substring(text, out$start, out$end)
    out$post <- substring(text, out$end + 1, pmin(nchar(text), out$end + window))
    stopifnot(identical(out$keyword, out$form))
    out$occurrence_id <- vapply(seq_len(nrow(out)), function(j)
      .morph_span_hash(list(s$document_id, s$segment_id, s$text_sha256,
        out$start[j], out$end[j])), character(1))
    out
  })
  occurrences <- do.call(rbind, pieces); rownames(occurrences) <- NULL
  occurrences$review_id <- rep(review_id, nrow(occurrences))
  occurrences$candidate_count <- counts[match(occurrences$form, targets)]
  occurrences$status <- ifelse(occurrences$boundary_status != "token_aligned", "boundary_mismatch",
    ifelse(occurrences$candidate_count == 0L, "no_candidates", "unreviewed"))
  for (name in c("candidate_id", "reviewer", "reason")) occurrences[[name]] <- rep(NA_character_, nrow(occurrences))
  required <- c("review_id", "occurrence_id", "status", "candidate_id", "reviewer", "reason")
  if (is.null(decisions)) decisions <- as.data.frame(stats::setNames(rep(list(character()), length(required)), required))
  if (!is.data.frame(decisions) || anyDuplicated(names(decisions)) ||
      !all(required %in% names(decisions)) ||
      !all(vapply(decisions[required], is.character, logical(1))))
    stop("decisions requires character fields: ", paste(required, collapse = ", "))
  for (name in setdiff(required, "candidate_id"))
    if (anyNA(decisions[[name]]) || any(!nzchar(trimws(decisions[[name]]))))
      stop("Decision IDs, status, reviewer and reason must be nonmissing and nonblank.")
  if (any(decisions$review_id != review_id)) stop("Decision review_id differs from source, targets or reference.")
  row <- match(decisions$occurrence_id, occurrences$occurrence_id)
  if (anyNA(row) || anyDuplicated(row)) stop("Decisions must identify unique existing occurrences.")
  if (any(occurrences$boundary_status[row] != "token_aligned"))
    stop("Review token boundaries before assigning a candidate to a boundary_mismatch span.")
  selected <- decisions$status == "selected"
  if (any(!decisions$status %in% c("selected", "unresolved")) ||
      any(selected != !is.na(decisions$candidate_id)))
    stop("Use selected with a candidate_id, or unresolved with NA candidate_id.")
  chosen <- match(decisions$candidate_id[selected], candidates$candidate_id)
  if (anyNA(chosen) || any(candidates$form[chosen] != occurrences$form[row[selected]]))
    stop("Selected candidate does not belong to the occurrence's exact form.")
  for (name in c("status", "candidate_id", "reviewer", "reason")) occurrences[[name]][row] <- decisions[[name]]
  occurrences$selected_overlap_n <- integer(nrow(occurrences))
  for (i in seq_len(nrow(x$segments))) {
    idx <- which(occurrences$document_id == x$segments$document_id[i] &
      occurrences$segment_id == x$segments$segment_id[i] & occurrences$status == "selected")
    occurrences$selected_overlap_n[idx] <- findInterval(occurrences$end[idx], sort(occurrences$start[idx])) -
      findInterval(occurrences$start[idx] - 1L, sort(occurrences$end[idx])) - 1L
  }
  terms <- data.frame(form = targets, candidate_count = counts,
    exact_spans = tabulate(match(occurrences$form, targets), nbins = length(targets)))
  for (status in c("unreviewed", "selected", "unresolved", "no_candidates", "boundary_mismatch"))
    terms[[status]] <- tabulate(match(occurrences$form[occurrences$status == status], targets), nbins = length(targets))
  documents <- do.call(rbind, lapply(x$documents$document_id, function(id) {
    z <- occurrences[occurrences$document_id == id, , drop = FALSE]
    aligned <- z$boundary_status == "token_aligned"
    chosen <- z$status == "selected"
    data.frame(document_id = id, source_tokens = sum(x$tokens$document_id == id),
      exact_spans = nrow(z), aligned_spans = sum(aligned), boundary_mismatch = sum(!aligned),
      multi_token_spans = sum(z$token_count > 1L, na.rm = TRUE),
      selected = sum(chosen), unresolved = sum(z$status == "unresolved"),
      unreviewed = sum(z$status == "unreviewed"), no_candidates = sum(z$status == "no_candidates"),
      selected_overlap_spans = sum(z$selected_overlap_n > 0L),
      selection_coverage = if (any(aligned)) sum(chosen) / sum(aligned) else NA_real_)
  }))
  out <- list(occurrences = occurrences, candidates = candidates, decisions = decisions,
    terms = terms, documents = documents, source = x, reference = reference,
    provenance = list(review_id = review_id, window_codepoints = window,
      matching = "exact original form; all overlapping hits retained; no normalization",
      coordinates = "segment-local-1-based-inclusive-Unicode-codepoints",
      counting = "diagnostic spans, not words; overlapping spans cannot be added as word tokens",
      interpretation = "source alignment and candidate membership, not contextual correctness"))
  out$content_sha256 <- .morph_span_hash(out)
  out
}
