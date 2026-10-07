# Explicit local-input recipe for NINJAL's Essay Database.
# https://mmsrv.ninjal.ac.jp/essay/essay_05.html
# No download, corpus text, metadata or license conversion is supplied here.
# Read the official XLSX files as text columns (e.g. with readxl) before calling.
read_ninjal_essays <- function(zip_path, essay_metadata, writer_metadata,
                               files = NULL, encoding = "UTF-8") {
  essay <- as.data.frame(essay_metadata, stringsAsFactors = FALSE)
  writer <- as.data.frame(writer_metadata, stringsAsFactors = FALSE)
  required <- list(essay = c("\u4f5c\u6587ID", "\u57f7\u7b46\u8005ID", "\u65e5\u672c\u8a9e\u4f5c\u6587txt", "\u4f5c\u6587\u30c6\u30fc\u30de"),
    writer = c("\u57f7\u7b46\u8005ID", "\u6bcd\u8a9e"))
  for (name in names(required)) {
    table <- if (name == "essay") essay else writer
    if (anyDuplicated(names(table)) || !all(required[[name]] %in% names(table)))
      stop(name, " metadata has missing or duplicate required columns.", call. = FALSE)
    for (column in required[[name]]) {
      if (!is.character(table[[column]]))
        stop("Read metadata columns as character: ", column, call. = FALSE)
    }
  }
  for (key in list(essay[["\u4f5c\u6587ID"]], essay[["\u65e5\u672c\u8a9e\u4f5c\u6587txt"]], writer[["\u57f7\u7b46\u8005ID"]]))
    if (anyNA(key) || any(!nzchar(trimws(key))) || anyDuplicated(key))
      stop("Essay IDs, filenames and writer-table IDs must be nonmissing and unique.", call. = FALSE)
  if (!is.character(zip_path) || length(zip_path) != 1L || is.na(zip_path) || !file.exists(zip_path))
    stop("zip_path must identify one existing local ZIP file.", call. = FALSE)
  inventory <- utils::unzip(zip_path, list = TRUE)
  if (anyDuplicated(inventory$Name))
    stop("ZIP member names must be unique.", call. = FALSE)
  if (is.null(files)) files <- essay[["\u65e5\u672c\u8a9e\u4f5c\u6587txt"]]
  if (!is.character(files) || !is.null(dim(files)) || !length(files) || anyNA(files) ||
      any(!nzchar(files)) || anyDuplicated(files))
    stop("files must contain unique, nonmissing filenames.", call. = FALSE)
  row <- match(files, essay[["\u65e5\u672c\u8a9e\u4f5c\u6587txt"]])
  member <- match(files, inventory$Name)
  if (anyNA(row) || anyNA(member))
    stop("Each requested file must occur in both the ZIP and essay metadata.", call. = FALSE)
  if (!is.character(encoding) || anyNA(encoding) || !is.null(dim(encoding)))
    stop("encoding must be UTF-8 or CP932, or a named per-file vector.", call. = FALSE)
  if (length(encoding) == 1L && is.null(names(encoding))) {
    encoding <- rep(encoding, length(files))
  } else {
    keys <- names(encoding)
    if (is.null(keys) || anyNA(keys) || any(!nzchar(keys)) || anyDuplicated(keys) ||
        anyNA(match(files, keys)))
      stop("Named encoding must supply exactly one entry for each requested file.", call. = FALSE)
    encoding <- unname(encoding[match(files, keys)])
  }
  if (any(!encoding %in% c("UTF-8", "CP932")))
    stop("This recipe supports explicitly supplied UTF-8 or CP932 only.", call. = FALSE)

  read_member <- function(i) {
    connection <- unz(zip_path, files[i], open = "rb")
    on.exit(close(connection))
    bytes <- readBin(connection, "raw", n = inventory$Length[member[i]])
    if (length(bytes) != inventory$Length[member[i]] || any(bytes == as.raw(0)))
      stop("Incomplete read or embedded NUL in ", files[i], call. = FALSE)
    bom <- length(bytes) >= 3L && identical(bytes[1:3], as.raw(c(239, 187, 191)))
    if (bom && encoding[i] != "UTF-8")
      stop("UTF-8 BOM conflicts with declared encoding in ", files[i], call. = FALSE)
    payload <- if (bom) bytes[-(1:3)] else bytes
    text <- iconv(rawToChar(payload), from = encoding[i], to = "UTF-8", sub = NA)
    if (is.na(text))
      stop("Cannot decode ", files[i], " as ", encoding[i], "; inspect and supply its encoding.", call. = FALSE)
    restored <- iconv(text, from = "UTF-8", to = encoding[i], sub = NA)
    if (is.na(restored) || !identical(charToRaw(restored), payload))
      stop("Byte round-trip failed for ", files[i], call. = FALSE)
    list(text = text, bom = bom, bytes = length(bytes),
      sha256 = digest::digest(bytes, algo = "sha256", serialize = FALSE))
  }
  decoded <- lapply(seq_along(files), read_member)
  writer_row <- match(essay[["\u57f7\u7b46\u8005ID"]][row], writer[["\u57f7\u7b46\u8005ID"]])
  documents <- data.frame(document_id = essay[["\u4f5c\u6587ID"]][row],
    writer_id = essay[["\u57f7\u7b46\u8005ID"]][row], source_file = files,
    task = essay[["\u4f5c\u6587\u30c6\u30fc\u30de"]][row], l1_reported = writer[["\u6bcd\u8a9e"]][writer_row],
    writer_metadata_status = ifelse(is.na(writer_row), "missing", "matched"),
    source_encoding = encoding, utf8_bom_removed = vapply(decoded, `[[`, logical(1), "bom"),
    source_bytes = vapply(decoded, `[[`, integer(1), "bytes"),
    source_sha256 = vapply(decoded, `[[`, character(1), "sha256"))
  segments <- data.frame(document_id = documents$document_id, segment_id = "text",
    text = vapply(decoded, `[[`, character(1), "text"))
  documents$text_sha256 <- vapply(segments$text, function(text)
    digest::digest(charToRaw(enc2utf8(text)), algo = "sha256", serialize = FALSE), character(1))
  list(documents = documents, segments = segments,
    essay_metadata = essay, writer_metadata = writer,
    inventory = inventory,
    provenance = list(source = "https://mmsrv.ninjal.ac.jp/essay/essay_05.html",
      data_license = "CC BY-NC-ND 4.0", zip_sha256 = digest::digest(file = zip_path, algo = "sha256"),
      text_policy = "Explicit decoding; leading UTF-8 BOM recorded and removed; all other characters and line endings retained",
      id_policy = "Official metadata mapping; no filename parsing or inferred L1; missing writer rows retained"))
}
