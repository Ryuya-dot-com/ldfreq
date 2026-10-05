# Local MASC GrAF 1.0 Penn annotations, retaining the supplied tokenization.
.lexmasc_ns <- c(g = "http://www.xces.org/ns/GrAF/1.0/")

.lexmasc_bytes <- function(path) {
  if (!file.exists(path) || dir.exists(path))
    stop("Missing local corpus file: ", path, call. = FALSE)
  con <- file(path, "rb")
  on.exit(close(con))
  readBin(con, "raw", n = file.info(path)$size)
}

.lexmasc_xml <- function(bytes, root) {
  if (grepl("<!DOCTYPE|<!ENTITY", rawToChar(bytes)))
    stop("Corpus XML must not contain a DTD or entity declarations.", call. = FALSE)
  doc <- withCallingHandlers(xml2::read_xml(bytes, options = "NONET"),
    warning = function(w) stop("Invalid corpus XML: ", conditionMessage(w), call. = FALSE))
  if (length(xml2::xml_find_all(doc, paste0("/g:", root, collapse = " | "), .lexmasc_ns)) != 1L)
    stop("Expected MASC GrAF 1.0 ", paste(root, collapse = " or "), " XML.", call. = FALSE)
  doc
}

.lexmasc_ids <- function(nodes) {
  ids <- xml2::xml_attr(nodes, "id")
  if (anyNA(ids) || any(!nzchar(ids)) || anyDuplicated(ids))
    stop("Annotation IDs must be present and unique within each file.", call. = FALSE)
  ids
}

.lexmasc_regions <- function(doc, text, offset_unit) {
  nodes <- xml2::xml_find_all(doc, "/g:graph/g:region", .lexmasc_ns)
  ids <- .lexmasc_ids(nodes)
  anchors <- xml2::xml_attr(nodes, "anchors")
  if (anyNA(anchors) || any(!grepl("^[0-9]+[[:space:]]+[0-9]+$", anchors)))
    stop("Every region needs two non-negative integer anchors.", call. = FALSE)
  bounds <- if (length(anchors)) do.call(rbind, strsplit(anchors, "[[:space:]]+")) else
    matrix(character(), nrow = 0L, ncol = 2L)
  a <- as.double(bounds[, 1]); b <- as.double(bounds[, 2])
  codepoints <- utf8ToInt(text)
  boundaries <- c(0, cumsum(if (offset_unit == "utf16")
    ifelse(codepoints > 65535L, 2, 1) else rep.int(1, length(codepoints))))
  start <- match(a, boundaries); end <- match(b, boundaries) - 1L
  if (anyNA(start) || anyNA(end) || any(a >= b))
    stop("Region anchors exceed the text or split a character for offset_unit.", call. = FALSE)
  data.frame(region_id = ids, start = start, end = end,
    start_anchor = a, end_anchor = b, stringsAsFactors = FALSE)
}

.lexmasc_local_ref <- function(header, ref) {
  if (length(ref) != 1L || is.na(ref) || !nzchar(ref) ||
      grepl("[/\\\\:]", ref) || ref %in% c(".", ".."))
    stop("Header references must name a file in the header directory.", call. = FALSE)
  path <- normalizePath(file.path(dirname(header), ref), mustWork = TRUE)
  if (!identical(dirname(path), dirname(header)))
    stop("A corpus reference resolves outside the header directory.", call. = FALSE)
  path
}

lexdiv_read_masc <- function(files, resource_version, document_ids = NULL,
    offset_unit = c("codepoint", "utf16"), max_tokens = 1e6) {
  if (!requireNamespace("xml2", quietly = TRUE))
    stop("Install the optional xml2 package to read MASC annotations.", call. = FALSE)
  files <- .lexnorm_plain_character(files, "files")
  resource_version <- .lexnorm_scalar_string(resource_version, "resource_version")
  offset_unit <- match.arg(offset_unit)
  max_tokens <- .lexnorm_positive_whole(max_tokens, "max_tokens")
  files <- normalizePath(files, mustWork = TRUE)
  if (anyDuplicated(files)) stop("files must be unique.", call. = FALSE)
  if (is.null(document_ids)) document_ids <- tools::file_path_sans_ext(basename(files))
  document_ids <- .lex_batch_validate_ids(document_ids, length(files))
  pieces <- vector("list", length(files)); total <- 0
  for (i in seq_along(files)) {
    id <- document_ids[i]
    raw <- list(header = .lexmasc_bytes(files[i]))
    header <- .lexmasc_xml(raw$header, c("cesHeader", "documentHeader"))
    modern <- xml2::xml_name(header) == "documentHeader"
    primary <- xml2::xml_find_all(header, ".//g:primaryData", .lexmasc_ns)
    if (length(primary) != 1L) stop("Expected one primaryData entry for ", id, call. = FALSE)
    ann <- xml2::xml_find_all(header, ".//g:annotations/g:annotation", .lexmasc_ns)
    types <- xml2::xml_attr(ann, if (modern) "f.id" else "type")
    refs <- c(text = xml2::xml_attr(primary, "loc"))
    for (role in c("seg", "s", "penn")) {
      at <- which(types == if (modern) paste0("f.", role) else role)
      if (length(at) != 1L) stop("Expected one ", role, " annotation entry for ", id, call. = FALSE)
      refs[role] <- xml2::xml_attr(ann[at], if (modern) "loc" else "ann.loc")
    }
    for (role in names(refs)) raw[[role]] <- .lexmasc_bytes(.lexmasc_local_ref(files[i], refs[role]))
    text <- rawToChar(raw$text); Encoding(text) <- "UTF-8"
    if (is.na(iconv(text, "UTF-8", "UTF-8"))) stop("Primary text must be valid UTF-8.", call. = FALSE)
    reg <- .lexmasc_regions(.lexmasc_xml(raw$seg, "graph"), text, offset_unit)
    seg <- .lexmasc_regions(.lexmasc_xml(raw$s, "graph"), text, offset_unit)
    seg <- seg[order(seg$start, seg$end), , drop = FALSE]
    if (nrow(seg) > 1L && any(utils::tail(seg$start, -1L) <= utils::head(seg$end, -1L)))
      stop("Sentence/utterance regions overlap for ", id, call. = FALSE)
    penn <- .lexmasc_xml(raw$penn, "graph")
    nodes <- xml2::xml_find_all(penn, "/g:graph/g:node", .lexmasc_ns)
    node_ids <- .lexmasc_ids(nodes)
    total <- total + length(nodes)
    if (total > max_tokens) stop("Corpus token count exceeds max_tokens.", call. = FALSE)
    annotations <- xml2::xml_find_all(penn, "/g:graph/g:a", .lexmasc_ns)
    annotation_refs <- xml2::xml_attr(annotations, "ref")
    if (anyNA(annotation_refs) || anyDuplicated(annotation_refs) ||
        !setequal(annotation_refs, node_ids) ||
        anyNA(xml2::xml_attr(annotations, "label")) ||
        any(xml2::xml_attr(annotations, "label") != "tok"))
      stop("Expected one tok annotation per Penn node for ", id, call. = FALSE)
    annotations <- annotations[match(node_ids, annotation_refs)]
    features <- lapply(seq_along(nodes), function(j) {
      f <- xml2::xml_find_all(annotations[j], "g:fs/g:f", .lexmasc_ns)
      key <- xml2::xml_attr(f, "name"); value <- xml2::xml_attr(f, "value")
      if (anyNA(key) || any(!nzchar(key)) || anyDuplicated(key) || anyNA(value))
        stop("Expected unique, flat name/value Penn features for ", id, call. = FALSE)
      stats::setNames(value, key)
    })
    spans <- lapply(nodes, function(node) {
      links <- xml2::xml_find_all(node, "g:link", .lexmasc_ns)
      target <- xml2::xml_attr(links, "targets")
      if (!length(target) || anyNA(target)) stop("Penn node has no region links.", call. = FALSE)
      ids <- unlist(strsplit(trimws(target), "[[:space:]]+"), use.names = FALSE)
      idx <- match(ids, reg$region_id)
      if (!length(idx) || anyNA(idx) || anyDuplicated(idx))
        stop("Penn node has missing or duplicate region links.", call. = FALSE)
      r <- reg[idx, , drop = FALSE]; r <- r[order(r$start), , drop = FALSE]
      if (nrow(r) > 1L && any(utils::tail(r$start, -1L) != utils::head(r$end, -1L) + 1L))
        stop("Discontinuous or overlapping token regions are unsupported.", call. = FALSE)
      c(start = r$start[1], end = utils::tail(r$end, 1),
        start_anchor = r$start_anchor[1], end_anchor = utils::tail(r$end_anchor, 1))
    })
    spans <- if (length(spans)) do.call(rbind, spans) else
      matrix(numeric(), nrow = 0, ncol = 4,
        dimnames = list(NULL, c("start", "end", "start_anchor", "end_anchor")))
    ord <- order(spans[, "start"], spans[, "end"])
    spans <- spans[ord, , drop = FALSE]; node_ids <- node_ids[ord]; features <- features[ord]
    if (nrow(spans) > 1L && any(utils::tail(spans[, "start"], -1) <= utils::head(spans[, "end"], -1)))
      stop("Penn tokens overlap for ", id, call. = FALSE)
    group <- findInterval(spans[, "start"], seg$start)
    if (any(group == 0L) || any(spans[, "end"] > seg$end[group]))
      stop("Every Penn token must fit one sentence/utterance region for ", id, call. = FALSE)
    counts <- tabulate(group, nbins = nrow(seg))
    feature <- function(name) vapply(features, function(x)
      if (name %in% names(x)) unname(x[name]) else NA_character_, character(1))
    tokens <- data.frame(document_id = rep(id, length(node_ids)),
      segment_id = seg$region_id[group], token_index = sequence(counts),
      document_token_index = seq_along(node_ids), annotation_id = node_ids,
      surface = if (length(node_ids)) substring(text, spans[, "start"], spans[, "end"]) else character(),
      lemma = feature("base"), pos = feature("msd"), affix = feature("affix"),
      spans, stringsAsFactors = FALSE)
    # Keep other supplied feature values too; no Penn-to-UPOS mapping is inferred.
    tokens$features <- I(features)
    segments <- data.frame(document_id = rep(id, nrow(seg)), segment_id = seg$region_id,
      start = seg$start, end = seg$end, start_anchor = seg$start_anchor,
      end_anchor = seg$end_anchor, token_count = counts, stringsAsFactors = FALSE)
    header_text <- function(xpath) xml2::xml_text(xml2::xml_find_first(header, xpath, .lexmasc_ns))
    documents <- data.frame(document_id = id, text = text,
      title = header_text(".//g:titleStmt/g:title"), medium = header_text(".//g:textClass/g:medium"),
      genre = xml2::xml_attr(xml2::xml_find_first(header, ".//g:textClass", .lexmasc_ns), "catRef"),
      tokens = nrow(tokens), segments = nrow(segments), stringsAsFactors = FALSE)
    sources <- data.frame(document_id = id, role = names(raw),
      filename = c(basename(files[i]), unname(refs)),
      sha256 = vapply(raw, digest::digest, character(1), algo = "sha256", serialize = FALSE),
      stringsAsFactors = FALSE)
    pieces[[i]] <- list(tokens = tokens, segments = segments, documents = documents, sources = sources)
  }
  bind <- function(name) {
    value <- do.call(rbind, lapply(pieces, `[[`, name)); rownames(value) <- NULL; value
  }
  list(tokens = bind("tokens"), segments = bind("segments"), documents = bind("documents"),
    provenance = list(reader = "ldfreq-masc-penn", reader_version = "0.2.0",
      resource_version = resource_version, token_layer = "penn", segment_layer = "s",
      offset_unit = offset_unit, output_positions = "1-based inclusive Unicode codepoints",
      format_documentation = "https://anc.org/data/masc/corpus/masc-structure/",
      files = bind("sources")))
}

lexdiv_as_quanteda <- function(data, segments, term_col = "surface", max_tokens = 1e6) {
  if (!requireNamespace("quanteda", quietly = TRUE))
    stop("Install the optional quanteda package to create quanteda tokens.", call. = FALSE)
  data <- .lexnorm_plain_data_frame(data, "data")
  segments <- .lexnorm_plain_data_frame(segments, "segments")
  term_col <- .lex_batch_scalar_name(term_col, "term_col")
  if (!all(c("document_id", "segment_id", "token_index", term_col) %in% names(data)) ||
      !all(c("document_id", "segment_id", "token_count") %in% names(segments)))
    stop("Supply token IDs, positions and terms, and segment IDs with token_count.", call. = FALSE)
  if ("quanteda_docname" %in% c(names(data), names(segments)))
    stop("quanteda_docname is reserved for the adapter's segment mapping.", call. = FALSE)
  for (key in c("document_id", "segment_id")) {
    .lexnorm_plain_character(data[[key]], key, allow_zero = TRUE)
    .lexnorm_plain_character(segments[[key]], key, allow_zero = TRUE)
  }
  term <- .lexnorm_plain_character(data[[term_col]], term_col, allow_zero = TRUE)
  if (any(stringi::stri_detect_regex(term, "\\p{White_Space}")))
    stop("Terms must be non-empty single tokens without whitespace.", call. = FALSE)
  if (!isTRUE(l10n_info()[["UTF-8"]]) && any(!stringi::stri_enc_isascii(term)))
    stop("Use an R session with a UTF-8 LC_CTYPE locale to import non-ASCII terms into quanteda.",
      call. = FALSE)
  position <- .lexng_count(data$token_index, "token_index", 1)
  count <- .lexng_count(segments$token_count, "token_count")
  max_tokens <- .lexnorm_positive_whole(max_tokens, "max_tokens")
  if (!nrow(segments) || sum(count) > max_tokens)
    stop("Supply at least one segment, with total token_count <= max_tokens.", call. = FALSE)
  keys <- c("document_id", "segment_id")
  segment_key <- .lexng_key(segments[keys]); group <- match(.lexng_key(data[keys]), segment_key)
  if (anyDuplicated(segment_key) || anyNA(group) ||
      any(position > count[group]) || anyDuplicated(data.frame(group, position)))
    stop("Segment IDs and token positions must be unique, in range and matched.", call. = FALSE)
  # as.tokens() drops empty strings on import. Remove a collision-free placeholder
  # through the public API afterwards, so gaps and trailing positions survive.
  placeholder <- "ldfreq_padding"
  while (placeholder %in% term) placeholder <- paste0(placeholder, "_")
  values <- lapply(count, function(n) rep(placeholder, n))
  rows <- split(seq_along(group), factor(group, levels = seq_along(values)))
  for (i in seq_along(values)) values[[i]][position[rows[[i]]]] <- term[rows[[i]]]
  segments$quanteda_docname <- paste0("segment_", seq_len(nrow(segments)))
  names(values) <- segments$quanteda_docname
  toks <- quanteda::as.tokens(values)
  toks <- quanteda::tokens_remove(toks, placeholder, valuetype = "fixed",
    case_insensitive = FALSE, padding = TRUE)
  expected <- lapply(values, function(v) { v[v == placeholder] <- ""; v })
  if (!identical(as.list(toks), expected))
    stop("quanteda changed the supplied tokens or positions during import.", call. = FALSE)
  quanteda::docvars(toks) <- segments
  data$quanteda_docname <- segments$quanteda_docname[group]
  list(tokens = toks, positions = data, segments = segments,
    provenance = list(adapter = "ldfreq-quanteda", adapter_version = "0.1.0",
      quanteda_version = as.character(utils::packageVersion("quanteda")), term_col = term_col,
      retokenized = FALSE, padding = TRUE, source_token_slots = sum(count),
      retained_tokens = nrow(data),
      input_sha256 = digest::digest(list(data, segments), algo = "sha256", serializeVersion = 2L)))
}
