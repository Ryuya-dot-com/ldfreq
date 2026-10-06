# Explicitly sourced example helper, not an exported package API.
# Counts caller-supplied parts; does not discover roots or affixes.
# Exact surface/POS lookup only. Part order is display order, not derivation order.
word_parts_profile <- function(annotations, analyses, parts, resource,
                               exclude_pos = character(), context_chars = 30L,
                               max_rows = 1e6) {
  fail <- function(message) stop(message, call. = FALSE)
  string <- function(x, name, missing = FALSE) {
    if (!is.character(x) || !is.null(attributes(x)) ||
        (!missing && anyNA(x)) || any(!is.na(x) &
          (!stringi::stri_enc_isutf8(x) | !nzchar(stringi::stri_trim_both(x)))))
      fail(paste(name, "must contain plain nonblank UTF-8 strings."))
  }
  frame <- function(x, fields, name) {
    if (!identical(class(x), "data.frame") || anyDuplicated(names(x)) ||
        !all(fields %in% names(x)) || any(vapply(x, is.list, logical(1))))
      fail(paste(name, "must be a plain data.frame with", paste(fields, collapse = ", ")))
    if (nrow(x) > max_rows) fail(paste(name, "exceeds max_rows."))
  }
  # Length-prefix each field to avoid collisions in arbitrary source IDs.
  key <- function(x) if (!nrow(x)) character() else do.call(paste0, lapply(x, function(v)
    paste0(nchar(as.character(v), type = "bytes"), ":", v)))
  for (name in c("max_rows", "context_chars")) {
    v <- get(name)
    if (!is.numeric(v) || length(v) != 1L || is.na(v) || !is.finite(v) ||
        v != floor(v) || v < (if (name == "max_rows") 1 else 0) ||
        v > .Machine$integer.max) fail(paste(name, "must be a bounded whole number."))
  }
  if (!is.list(annotations) || !is.list(annotations$provenance) ||
      !identical(annotations$provenance$importer, "ldfreq-external-annotations"))
    fail("Use unmodified lexdiv_import_annotations() output.")
  checked <- ldfreq::lexdiv_import_annotations(annotations$tokens,
    annotations$segments[setdiff(names(annotations$segments), c("token_count", "text_sha256"))],
    annotations$provenance$annotation, max_tokens = max_rows)
  if (!identical(annotations, checked)) fail("Source annotations changed; reimport them.")
  frame(analyses, c("analysis_id", "form", "completeness"), "analyses")
  frame(parts, c("analysis_id", "part_index", "part_id", "canonical",
    "role", "process", "boundness"), "parts")
  if (any(c("document_id", "segment_id", "token_index") %in% names(analyses)) ||
      any(c("document_id", "segment_id", "token_index", "surface", "completeness") %in% names(parts)))
    fail("Reference columns conflict with reserved occurrence names.")
  for (field in c("analysis_id", "form", "completeness", intersect("upos", names(analyses))))
    string(analyses[[field]], paste0("analyses$", field))
  for (field in c("analysis_id", "part_id", "canonical", "role", "process", "boundness"))
    string(parts[[field]], paste0("parts$", field))
  if (anyDuplicated(analyses$analysis_id)) fail("analysis_id must be unique in analyses.")
  if (any(!analyses$completeness %in% c("complete", "partial", "unanalysed")))
    fail("completeness must be complete, partial or unanalysed.")
  if (any(!parts$analysis_id %in% analyses$analysis_id)) fail("parts contains unknown analysis_id.")
  if (!is.numeric(parts$part_index) || anyNA(parts$part_index) ||
      any(!is.finite(parts$part_index) | parts$part_index < 1 |
        parts$part_index != floor(parts$part_index))) fail("part_index must be positive whole numbers.")
  if (any(!parts$role %in% c("root", "prefix", "suffix")) ||
      any(!parts$process %in% c("none", "inflection", "derivation", "unknown")) ||
      any(!parts$boundness %in% c("free", "bound", "unknown"))) fail("Invalid part classification.")
  root <- parts$role == "root"
  if (any(root & parts$process != "none") || any(!root & parts$process == "none") ||
      any(!root & parts$boundness != "bound")) fail("Roots use process none; affixes must be bound with a process.")
  definition <- unique(parts[c("part_id", "canonical", "role", "process", "boundness")])
  if (anyDuplicated(definition$part_id)) fail("A part_id has conflicting definitions.")
  part_groups <- split(seq_len(nrow(parts)), factor(parts$analysis_id,
    levels = analyses$analysis_id))
  for (i in seq_len(nrow(analyses))) {
    p <- part_groups[[i]]
    if (!identical(as.numeric(sort(parts$part_index[p])), as.numeric(seq_along(p))))
      fail("part_index must be consecutive and unique within an analysis.")
    state <- analyses$completeness[i]
    if (state == "unanalysed" && length(p)) fail("Unanalysed entries cannot assert parts.")
    if (state == "complete" && (!any(root[p]) || any(parts$process[p] == "unknown")))
      fail("Complete analyses require a root and known affix processes; mark unsupported cases partial.")
  }
  required <- c("resource_id", "resource_version", "language", "source_reference",
    "data_license", "analysis_scope", "analysis_basis")
  if (!is.list(resource) || is.null(names(resource)) || anyDuplicated(names(resource)) ||
      !all(required %in% names(resource))) fail("resource lacks required declarations.")
  for (name in names(resource)) {
    string(resource[[name]], paste0("resource$", name))
    if (length(resource[[name]]) != 1L) fail("Resource declarations must be scalar strings.")
  }
  string(exclude_pos, "exclude_pos")
  upos <- c("ADJ", "ADP", "ADV", "AUX", "CCONJ", "DET", "INTJ", "NOUN", "NUM",
    "PART", "PRON", "PROPN", "PUNCT", "SCONJ", "SYM", "VERB", "X")
  if (anyDuplicated(exclude_pos) || any(!exclude_pos %in% upos)) fail("exclude_pos requires unique UD tags.")
  pos_match <- "upos" %in% names(analyses)
  t <- annotations$tokens
  if (pos_match || length(exclude_pos)) {
    if (!"upos" %in% names(t)) fail("Annotations require upos for this policy.")
    string(t$upos, "tokens$upos", missing = TRUE)
    if (any(!is.na(t$upos) & !t$upos %in% upos) ||
        (pos_match && any(!analyses$upos %in% upos))) fail("Map POS explicitly to UD tags.")
  }
  ids <- c("document_id", "segment_id", "token_index")
  o <- t[unique(c(ids, "surface", "start", "end", intersect("upos", names(t))))]
  o$selected <- if (length(exclude_pos)) ifelse(is.na(t$upos), NA,
    !t$upos %in% exclude_pos) else rep(TRUE, nrow(t))
  o$status <- rep("unlisted", nrow(o))
  o$status[is.na(o$selected)] <- "unknown_selection"
  o$status[o$selected %in% FALSE] <- "excluded"
  if (pos_match) o$status[o$selected %in% TRUE & is.na(t$upos)] <- "missing_pos"
  ref <- analyses[c("form", if (pos_match) "upos")]
  query <- data.frame(form = t$surface)
  if (pos_match) query$upos <- t$upos
  ref_key <- key(ref); keys <- unique(ref_key)
  groups <- split(seq_len(nrow(analyses)), factor(match(ref_key, keys), levels = seq_along(keys)))
  group <- match(key(query), keys)
  eligible <- which(o$status == "unlisted" & !is.na(group))
  o$candidate_count <- integer(nrow(o))
  o$candidate_count[eligible] <- lengths(groups)[group[eligible]]
  if (sum(as.double(o$candidate_count)) > max_rows) fail("Candidate expansion exceeds max_rows.")
  o$analysis_id <- rep(NA_character_, nrow(o))
  one <- eligible[o$candidate_count[eligible] == 1L]
  arow <- integer(length(one))
  if (length(one)) {
    arow <- unlist(groups[group[one]], use.names = FALSE)
    o$analysis_id[one] <- analyses$analysis_id[arow]
    o$status[one] <- analyses$completeness[arow]
  }
  o$status[eligible[o$candidate_count[eligible] > 1L]] <- "ambiguous"
  source_row <- match(key(t[c("document_id", "segment_id")]),
    key(annotations$segments[c("document_id", "segment_id")]))
  source <- annotations$segments$text[source_row]
  o$pre <- stringi::stri_sub(source, pmax(1, t$start - context_chars), t$start - 1)
  o$keyword <- t$surface
  o$post <- stringi::stri_sub(source, t$end + 1,
    pmin(stringi::stri_length(source), t$end + context_chars))
  tr <- rep(eligible, o$candidate_count[eligible])
  ar <- unlist(groups[group[eligible]], use.names = FALSE)
  if (is.null(ar)) ar <- integer()
  candidates <- cbind(t[tr, ids, drop = FALSE], analyses[ar, , drop = FALSE])
  # Only unique complete/partial analyses contribute parts. Candidate alternatives
  # remain in the input tables and are never summed as observed occurrences.
  counts <- lengths(part_groups)[arow]
  if (sum(as.double(counts)) > max_rows) fail("Part expansion exceeds max_rows.")
  pr <- unlist(lapply(part_groups[arow], function(idx) idx[order(parts$part_index[idx])]),
    use.names = FALSE)
  if (is.null(pr)) pr <- integer()
  part_occurrences <- cbind(t[rep(one, counts), ids, drop = FALSE],
    surface = t$surface[rep(one, counts)],
    completeness = o$status[rep(one, counts)], parts[pr, , drop = FALSE])
  for (field in c("root", "prefix", "suffix", "inflection", "derivation")) {
    hit <- if (field %in% c("root", "prefix", "suffix")) parts$role == field else parts$process == field
    n <- vapply(part_groups, function(idx) sum(hit[idx]), integer(1))
    o[[paste0("observed_", field, "_occurrences")]] <- rep(NA_integer_, nrow(o))
    usable <- which(o$status %in% c("complete", "partial"))
    o[[paste0("observed_", field, "_occurrences")]][usable] <-
      n[match(o$analysis_id[usable], analyses$analysis_id)]
  }
  summarize <- function(idx) {
    x <- o[idx, , drop = FALSE]
    complete <- all(x$status %in% c("complete", "excluded"))
    known <- sum(x$selected %in% TRUE); unknown <- sum(is.na(x$selected))
    done <- sum(x$status == "complete")
    usable <- x$status %in% c("complete", "partial")
    a <- match(x$analysis_id[usable], analyses$analysis_id)
    p <- unlist(part_groups[a], use.names = FALSE)
    if (is.null(p)) p <- integer()
    r <- parts$role[p] == "root"
    out <- data.frame(tokens = nrow(x), excluded_tokens = sum(x$status == "excluded"),
      known_selected_tokens = known, unknown_selection_tokens = unknown,
      selected_tokens = if (unknown) NA_integer_ else known,
      complete_tokens = done, partial_tokens = sum(x$status == "partial"),
      unanalysed_tokens = sum(x$status == "unanalysed"),
      ambiguous_tokens = sum(x$status == "ambiguous"), unlisted_tokens = sum(x$status == "unlisted"),
      missing_pos_tokens = sum(x$status == "missing_pos"),
      conditional_complete_coverage = if (known) done / known else NA_real_,
      complete_coverage = if (!unknown && known) done / known else NA_real_,
      observed_root_occurrences = sum(r), observed_affix_occurrences = sum(!r),
      observed_root_types = length(unique(parts$part_id[p[r]])),
      observed_affix_types = length(unique(parts$part_id[p[!r]])))
    observed_affixed <- sum((x$observed_prefix_occurrences + x$observed_suffix_occurrences) > 0,
      na.rm = TRUE)
    out$observed_affixed_tokens <- observed_affixed
    for (field in c("root_occurrences", "affix_occurrences", "root_types", "affix_types", "affixed_tokens"))
      out[[field]] <- if (complete) out[[paste0("observed_", field)]] else NA_integer_
    out$affixes_per_token <- if (complete && known) sum(!r) / known else NA_real_
    out$affixed_token_proportion <- if (complete && known) observed_affixed / known else NA_real_
    out$status <- if (!nrow(x)) "empty" else if (!complete) "incomplete" else
      if (!known) "no_selected_tokens" else "complete"
    out
  }
  doc <- annotations$documents
  doc_rows <- split(seq_len(nrow(t)), factor(t$document_id, levels = doc$document_id))
  documents <- cbind(doc, do.call(rbind, lapply(doc_rows, summarize)))
  frequency <- part_occurrences[c("document_id", "part_id", "canonical", "role", "process", "boundness")]
  k <- key(frequency); first <- !duplicated(k)
  frequency <- frequency[first, , drop = FALSE]
  frequency$observed_occurrences <- tabulate(match(k, k[first]), nbins = nrow(frequency))
  for (name in c("o", "candidates", "part_occurrences", "documents", "frequency")) {
    x <- get(name); rownames(x) <- NULL; assign(name, x)
  }
  inputs <- list(annotations = annotations, analyses = analyses, parts = parts,
    resource = resource, exclude_pos = exclude_pos, context_chars = context_chars, max_rows = max_rows)
  list(occurrences = o, candidates = candidates, part_occurrences = part_occurrences,
    frequency = frequency, documents = documents, summary = summarize(seq_len(nrow(t))),
    inputs = inputs, provenance = list(method = "word-parts-example-0.1.0",
      input_sha256 = digest::digest(inputs, algo = "sha256", serializeVersion = 2L),
      matching = "exact surface and optional UD POS; no normalization or fallback",
      counts = "observed includes unique partial analyses; complete totals require complete selection",
      scope = "completeness is relative to resource$analysis_scope; no knowledge or productivity inference"))
}
