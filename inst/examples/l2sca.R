# Source explicitly; see vignette("syntactic-complexity", package = "ldfreq").
# The original parser/queries are external; these helpers never download or run them.
.l2sca_hash <- function(x) digest::digest(x, algo = "sha256", serializeVersion = 2L)
.l2sca_text_hash <- function(x) digest::digest(enc2utf8(x), algo = "sha256", serialize = FALSE)
.l2sca_string <- function(x, blank = FALSE) is.character(x) && length(x) == 1L &&
  !is.na(x) && validUTF8(x) && (blank || nzchar(stringi::stri_trim_both(x)))
.l2sca_fields <- function(x, fields) is.list(x) && !is.data.frame(x) &&
  !is.null(names(x)) && !anyDuplicated(names(x)) && all(fields %in% names(x))
.l2sca_documents <- function(documents) {
  if (!is.data.frame(documents) || anyDuplicated(names(documents)) || !nrow(documents) ||
      !all(c("document_id", "text") %in% names(documents)))
    stop("Supply a nonempty document table with document_id and original text.", call. = FALSE)
  x <- documents[c("document_id", "text")]
  if (any(!vapply(x, function(z) is.character(z) && !is.object(z) && !anyNA(z) &&
      all(validUTF8(z)) && !any(Encoding(z) %in% c("bytes", "latin1")), logical(1))) ||
      any(!nzchar(stringi::stri_trim_both(x$document_id))) || anyDuplicated(x$document_id))
    stop("Use unique nonblank character document IDs and non-missing UTF-8 text.", call. = FALSE)
  x[] <- lapply(x, enc2utf8); rownames(x) <- NULL
  x
}

l2sca_write_inputs <- function(documents, path) {
  documents <- .l2sca_documents(documents)
  if (!requireNamespace("jsonlite", quietly = TRUE))
    stop("Install optional jsonlite to write the external runner input.", call. = FALSE)
  if (!.l2sca_string(path) || file.exists(path))
    stop("Choose a new input filename; existing files are not replaced.", call. = FALSE)
  jsonlite::write_json(lapply(seq_len(nrow(documents)), function(i) as.list(documents[i, ])),
    path, auto_unbox = TRUE, pretty = TRUE)
  invisible(path)
}

# Read the preserved Penn representation, not a new syntactic analysis. Node
# numbers include terminals, as in Tregex -x, and restart at each ROOT.
.l2sca_trees <- function(penn, max_nodes) {
  parts <- stringi::stri_extract_all_regex(penn, "\\(|\\)|[^\\s()]+")[[1L]]
  parts <- parts[!is.na(parts)]
  empty_nodes <- data.frame(tree_id = integer(), node_id = integer(), label = character(),
    first_token = integer(), last_token = integer(), terminal = logical())
  empty_tokens <- data.frame(token_index = integer(), parser_surface = character(), xpos = character())
  if (!length(parts)) return(list(nodes = empty_nodes, tokens = empty_tokens))
  nodes <- vector("list", min(length(parts), max_nodes)); leaves <- nodes
  cursor <- 1L; count <- 0L; nleaf <- 0L; tree <- 0L; base <- 0L
  fail <- function() stop("Malformed, unsupported or excessively nested Penn tree.", call. = FALSE)
  add <- function(label, first, last, terminal) {
    count <<- count + 1L
    if (count > max_nodes) stop("Parse exceeds max_nodes; no parse was truncated.", call. = FALSE)
    nodes[[count]] <<- list(tree_id = tree, node_id = count - base, label = label,
      first_token = first, last_token = last, terminal = terminal)
    count
  }
  peek <- function() if (cursor <= length(parts)) parts[cursor] else ""
  visit <- function(depth = 0L) {
    if (depth > 200L || peek() != "(") fail()
    cursor <<- cursor + 1L; label <- peek()
    if (!nzchar(label) || label %in% c("(", ")")) fail()
    cursor <<- cursor + 1L
    row <- add(label, nleaf + 1L, NA_integer_, FALSE)
    if (peek() == "(") {
      while (peek() == "(") visit(depth + 1L)
    } else {
      word <- peek()
      if (!nzchar(word) || word == ")") fail()
      nleaf <<- nleaf + 1L
      leaves[[nleaf]] <<- list(token_index = nleaf, parser_surface = word, xpos = label)
      add(word, nleaf, nleaf, TRUE)
      cursor <<- cursor + 1L
    }
    if (peek() != ")") fail()
    cursor <<- cursor + 1L; nodes[[row]]$last_token <<- nleaf
    if (nodes[[row]]$first_token > nleaf) fail()
    row
  }
  while (cursor <= length(parts)) {
    tree <- tree + 1L; base <- count
    top <- visit()
    if (nodes[[top]]$label != "ROOT") fail()
  }
  as_table <- function(x, n) do.call(rbind, lapply(x[seq_len(n)], as.data.frame,
    stringsAsFactors = FALSE))
  nodes <- as_table(nodes, count); tokens <- as_table(leaves, nleaf)
  # X is the parser's fallback category; an aligned fallback is not a valid parse.
  if (any(nodes$label[!nodes$terminal] == "X"))
    stop("Parser fallback X tree; retain the source and inspect its parse log.", call. = FALSE)
  list(nodes = nodes, tokens = tokens)
}

.l2sca_surfaces <- function(tokens, text) {
  # Prefer literal source text. Only the six PTB bracket escapes are decoded;
  # unsupported transformations must remain visible instead of being guessed.
  escapes <- c("-LRB-" = "(", "-RRB-" = ")", "-LSB-" = "[", "-RSB-" = "]",
    "-LCB-" = "{", "-RCB-" = "}")
  tokens$surface <- tokens$parser_surface
  tokens$surface_rule <- rep("exact", nrow(tokens))
  cursor <- 1L; size <- stringi::stri_length(text)
  for (j in seq_len(nrow(tokens))) {
    while (cursor <= size && stringi::stri_detect_regex(
      stringi::stri_sub(text, cursor, cursor), "^\\p{White_Space}$")) cursor <- cursor + 1L
    word <- tokens$parser_surface[j]
    exact <- identical(stringi::stri_sub(text, cursor, cursor + stringi::stri_length(word) - 1L), word)
    if (!exact && word %in% names(escapes)) {
      tokens$surface[j] <- unname(escapes[word]); tokens$surface_rule[j] <- "PTB_bracket"
    }
    cursor <- cursor + stringi::stri_length(tokens$surface[j])
  }
  tokens
}

.l2sca_command <- function(x) {
  if (!.l2sca_fields(x, c("exit_status", "stdout", "stderr", "stdout_sha256")) ||
      !is.numeric(x$exit_status) || length(x$exit_status) != 1L || is.na(x$exit_status) ||
      !is.finite(x$exit_status) || x$exit_status != floor(x$exit_status) ||
      !.l2sca_string(x$stdout, TRUE) || !.l2sca_string(x$stderr, TRUE) ||
      !identical(x$stdout_sha256, .l2sca_text_hash(x$stdout)))
    stop("Incomplete or changed parser/query output; retain the original trace file.", call. = FALSE)
  invisible(x)
}

l2sca_import <- function(trace, documents, max_nodes = 1e6) {
  documents <- .l2sca_documents(documents)
  if (is.character(trace) && length(trace) == 1L) {
    if (!requireNamespace("jsonlite", quietly = TRUE))
      stop("Install optional jsonlite to read the saved trace JSON.", call. = FALSE)
    trace <- jsonlite::read_json(trace, simplifyVector = FALSE)
  }
  if (!is.numeric(max_nodes) || length(max_nodes) != 1L || is.na(max_nodes) ||
      !is.finite(max_nodes) || max_nodes < 1 || max_nodes != floor(max_nodes) || max_nodes > 1e7)
    stop("max_nodes must be one positive whole number <= 10000000.", call. = FALSE)
  if (!.l2sca_fields(trace, c("format", "provenance", "documents")) ||
      !identical(trace$format, "ldfreq-l2sca-trace-1") || !is.list(trace$documents) ||
      length(trace$documents) != nrow(documents))
    stop("Supply the complete trace for the original document roster.", call. = FALSE)
  p <- trace$provenance
  if (!.l2sca_fields(p, c("kind", "language", "source", "settings")) ||
      !identical(p$language, "en") || !.l2sca_string(p$kind) ||
      !p$kind %in% c("l2sca-pinned", "authored-fixture") ||
      !.l2sca_string(p$source) || !.l2sca_string(p$settings))
    stop("Declare the English trace source, kind and settings.", call. = FALSE)
  patterns <- c("s", "c", "t", "dc", "fc", "ft")
  if (identical(p$kind, "l2sca-pinned")) {
    hashes <- c("analyzeText.py" = "4e9d7a130a802a540e2902d47d6c1b830f47dff09b3799480110163d1c040aef",
      "stanford-tregex-4.2.0.jar" = "31c9783188f58092ff093972f39747c5a18ba6d3ce4aed288c3d9cbd8cfc59ae",
      "stanford-parser-full-2020-11-17/stanford-parser.jar" = "af563212c61a491a9787591f8c05e722c0924196e64a57d011c20b38de83208c",
      "stanford-parser-full-2020-11-17/stanford-parser-4.2.0-models.jar" = "e604e5582835ff810b96488c39767df9e05ae9a9cd41fe63ee3d55f8db8d9c78")
    if (!identical(p$distribution, "L2SCA-2023-08-15") ||
        !.l2sca_fields(p, c("hashes", "patterns", "java", "python", "exporter_sha256", "parser")) ||
        !.l2sca_fields(p$hashes, names(hashes)) ||
        !identical(p$hashes[names(hashes)], as.list(hashes)) ||
        !.l2sca_fields(p$patterns, patterns) ||
        any(!vapply(p$patterns[patterns], .l2sca_string, logical(1))) ||
        any(!vapply(p[c("python", "exporter_sha256", "parser")], .l2sca_string, logical(1))) ||
        !grepl("^[a-f0-9]{64}$", p$exporter_sha256))
      stop("Unsupported L2SCA identity; use the pinned external runner.", call. = FALSE)
    .l2sca_command(p$java)
    if (p$java$exit_status != 0) stop("Java identity was not recorded successfully.", call. = FALSE)
  }
  checked <- vector("list", nrow(documents)); matches <- checked
  empty_matches <- data.frame(tree_id = integer(), node_id = integer(), label = character(),
    first_token = integer(), last_token = integer(), terminal = logical(), pattern = character(),
    document_id = character(), start = integer(), end = integer(), source_span = character(),
    span_kind = character())
  components <- data.frame(document_id = documents$document_id, W = NA_integer_, S = NA_integer_,
    C = NA_integer_, T = NA_integer_, DC = NA_integer_, status = "", reason = "",
    stringsAsFactors = FALSE)
  used_nodes <- 0L
  for (i in seq_len(nrow(documents))) {
    d <- trace$documents[[i]]
    if (!.l2sca_fields(d, c("document_id", "text", "text_sha256", "parser", "queries", "status")) ||
        !identical(d$document_id, documents$document_id[i]) || !identical(d$text, documents$text[i]) ||
        !identical(d$text_sha256, .l2sca_text_hash(documents$text[i])) ||
        !.l2sca_string(d$status) || !d$status %in% c("parsed", "parser_failed", "query_failed"))
      stop("Trace IDs, source text or hashes do not match the complete ordered document roster.", call. = FALSE)
    .l2sca_command(d$parser)
    if (!is.list(d$queries) || (length(d$queries) && is.null(names(d$queries))) ||
        anyDuplicated(names(d$queries)) ||
        any(!names(d$queries) %in% patterns))
      stop("Invalid or duplicated query names.", call. = FALSE)
    for (q in d$queries) .l2sca_command(q)
    if (d$status == "parser_failed") {
      if (d$parser$exit_status == 0) stop("Inconsistent parser failure status.", call. = FALSE)
    } else if (d$parser$exit_status != 0) stop("Inconsistent parser success status.", call. = FALSE)
    if (d$status == "query_failed" &&
        all(vapply(d$queries, function(q) q$exit_status == 0, logical(1))))
      stop("Inconsistent query failure status.", call. = FALSE)
    if (d$status != "parsed") {
      components$status[i] <- d$status
      components$reason[i] <- "External process failed; inspect saved parser/query logs."
      next
    }
    if (!setequal(names(d$queries), patterns) || length(d$queries) != length(patterns) ||
        any(vapply(d$queries, function(q) q$exit_status != 0, logical(1))))
      stop("A successful trace must contain all six successful queries.", call. = FALSE)
    # Structural/alignment failure is retained for this document, not dropped or
    # converted to zero. Its unchanged raw source, parse and logs remain in trace.
    part <- tryCatch({
      tree <- .l2sca_trees(d$parser$stdout, max_nodes)
      used_nodes <- used_nodes + nrow(tree$nodes)
      if (used_nodes > max_nodes) stop("Parse exceeds max_nodes; no parse was truncated.")
      tokens <- .l2sca_surfaces(tree$tokens, d$text)
      tokens$document_id <- rep(d$document_id, nrow(tokens)); tokens$segment_id <- rep("document", nrow(tokens))
      imported <- ldfreq::lexdiv_import_annotations(tokens,
        data.frame(document_id = d$document_id, segment_id = "document", text = d$text),
        list(language = "en", analyzer = p$kind, analyzer_version = "trace-1",
          dictionary = "declared in full trace", dictionary_version = .l2sca_hash(p),
          unit = "parser leaf", normalization = "exact source; explicit PTB brackets only"))
      tokens <- imported$tokens
      tokens$counted_word <- grepl("^[A-Z]+\\$?$", tokens$xpos) &
        !grepl("[()\\-]", tokens$parser_surface)
      nodes <- tree$nodes
      found <- lapply(patterns, function(name) {
        lines <- strsplit(trimws(d$queries[[name]]$stdout), "\n", fixed = TRUE)[[1L]]
        lines <- lines[nzchar(lines)]
        if (any(!grepl("^[1-9][0-9]*:[1-9][0-9]*$", lines)) || anyDuplicated(lines))
          stop("Malformed or duplicated query node IDs.")
        idx <- match(lines, paste(nodes$tree_id, nodes$node_id, sep = ":"))
        if (anyNA(idx) || any(nodes$terminal[idx])) stop("Query refers to a missing or terminal node.")
        x <- nodes[idx, , drop = FALSE]
        allowed <- switch(name, s = "ROOT", c = c("S", "SINV", "SQ"),
          t = c("S", "SBARQ", "SINV", "SQ"), dc = "SBAR", fc = "FRAG", ft = "FRAG")
        if (any(!x$label %in% allowed)) stop("Query refers to an incompatible node label.")
        x$pattern <- rep(name, nrow(x)); x
      })
      hits <- do.call(rbind, found); rownames(hits) <- NULL
      roots <- nodes$node_id == 1L
      if (!identical(sort(hits$tree_id[hits$pattern == "s"]), sort(nodes$tree_id[roots])))
        stop("Sentence query does not cover all ROOT nodes.")
      hits$document_id <- rep(d$document_id, nrow(hits))
      hits$start <- tokens$start[hits$first_token]; hits$end <- tokens$end[hits$last_token]
      hits$source_span <- stringi::stri_sub(rep(d$text, nrow(hits)), hits$start, hits$end)
      hits$span_kind <- rep("query_matched_subtree", nrow(hits))
      imported$tokens <- tokens
      list(source = imported, nodes = nodes, matches = hits)
    }, error = function(e) list(error = conditionMessage(e)))
    if (!is.null(part$error)) {
      components$status[i] <- "unusable_parse"; components$reason[i] <- part$error
      next
    }
    checked[[i]] <- part[c("source", "nodes")]; matches[[i]] <- part$matches
    W <- sum(part$source$tokens$counted_word)
    count <- table(factor(part$matches$pattern, levels = patterns))
    components[i, c("W", "S", "C", "T", "DC")] <- list(W, unname(count["s"]),
      unname(count["c"] + count["fc"]), unname(count["t"] + count["ft"]), unname(count["dc"]))
    components$status[i] <- if (W == 0) "no_words" else "parsed"
  }
  names(checked) <- documents$document_id
  results <- components[rep(seq_len(nrow(components)), each = 3L), , drop = FALSE]
  results$measure <- rep(c("MLC", "MLT", "DC_C"), nrow(components))
  results$numerator <- ifelse(results$measure == "DC_C", results$DC, results$W)
  results$denominator <- ifelse(results$measure == "MLT", results$T, results$C)
  results$original_rule_value <- ifelse(is.na(results$denominator), NA_real_,
    ifelse(results$denominator == 0 | results$numerator == 0, 0, results$numerator / results$denominator))
  results$value <- ifelse(results$status == "parsed" & results$denominator > 0,
    results$numerator / results$denominator, NA_real_)
  zero <- results$status == "parsed" & !is.na(results$denominator) & results$denominator == 0
  results$status[zero] <- "zero_denominator"
  results$status[results$status == "parsed"] <- "computed"
  results$reason[zero] <- "The measure's denominator is zero."
  results$reason[results$status == "no_words"] <- "No words under the recorded parser/counting rules."
  results$review_status <- "not_reviewed"
  rownames(results) <- NULL
  settings <- list(max_nodes = max_nodes, measures = c(MLC = "W/C", MLT = "W/T", DC_C = "DC/C"),
    aggregation = "document totals; matched subtrees may overlap; no mean of subtree lengths",
    word_rule = "terminal POS: capital ASCII letters with optional final $; terminal contains no parentheses or hyphen",
    reporting = "no words and zero denominators reported as NA; failed documents retain NA counts",
    original_rule_value = "recomputed original zero-division rule, unrounded; not an imported official CSV score")
  analysis_id <- .l2sca_hash(list(trace, documents, settings))
  results$analysis_id <- analysis_id
  all_matches <- do.call(rbind, c(list(empty_matches), matches)); rownames(all_matches) <- NULL
  result <- list(kind = "l2sca-import", recipe_version = "1", documents = documents,
    trace = trace, checked = checked, matches = all_matches, components = components,
    results = results, settings = settings, analysis_id = analysis_id,
    ldfreq_version = as.character(utils::packageVersion("ldfreq")))
  result$integrity_sha256 <- .l2sca_hash(result)
  result
}

l2sca_validate <- function(x) {
  if (!.l2sca_fields(x, c("kind", "recipe_version", "integrity_sha256")) ||
      !identical(x$kind, "l2sca-import") || !identical(x$recipe_version, "1") ||
      !identical(x$integrity_sha256, .l2sca_hash(x[names(x) != "integrity_sha256"])))
    stop("The saved syntax record changed; import its complete original trace again.", call. = FALSE)
  invisible(x)
}
