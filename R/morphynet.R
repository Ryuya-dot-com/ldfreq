# Read supplied one-step relations; do not infer families, roots or POS mappings.
morphynet_read_derivations <- function(path, language, resource_version, max_rows = 1e6) {
  path <- .lexnorm_scalar_string(path, "path")
  language <- .lexnorm_scalar_string(language, "language")
  resource_version <- .lexnorm_scalar_string(resource_version, "resource_version")
  if (!nzchar(stringi::stri_trim_both(language)) || !nzchar(stringi::stri_trim_both(resource_version)))
    stop("language and resource_version must not be blank.", call. = FALSE)
  max_rows <- .lexnorm_positive_whole(max_rows, "max_rows")
  if (max_rows >= .Machine$integer.max)
    stop("max_rows must be below the integer limit.", call. = FALSE)
  if (!file.exists(path) || dir.exists(path))
    stop("path must identify a local, uncompressed UTF-8 TSV file.", call. = FALSE)
  bytes <- readBin(path, what = "raw", n = file.info(path)$size)
  if (any(bytes == as.raw(0L)))
    stop("Cannot read relation text: embedded NUL bytes.", call. = FALSE)
  sha <- digest::digest(bytes, algo = "sha256", serialize = FALSE)
  connection <- rawConnection(bytes)
  on.exit(close(connection))
  lines <- readLines(connection, n = max_rows + 1L, warn = FALSE, encoding = "UTF-8")
  if (!length(lines)) stop("The relation file is empty.", call. = FALSE)
  if (length(lines) > max_rows) stop("Relation rows exceed max_rows.", call. = FALSE)
  if (anyNA(iconv(lines, from = "UTF-8", to = "UTF-8", sub = NA)))
    stop("The relation file must use valid UTF-8.", call. = FALSE)
  fields <- strsplit(lines, "\t", fixed = TRUE)
  if (any(lengths(fields) != 6L) || any(stringi::stri_count_fixed(lines, "\t") != 5L))
    stop("Every line must contain six tab-separated derivational fields; no header or blank lines.",
      call. = FALSE)
  relations <- as.data.frame(do.call(rbind, fields), stringsAsFactors = FALSE)
  names(relations) <- c("source_word", "target_word", "source_pos", "target_pos",
    "morpheme", "affix_position")
  if (any(vapply(relations, function(x) any(!nzchar(stringi::stri_trim_both(x))), logical(1))))
    stop("Derivational fields must not be empty or whitespace-only.", call. = FALSE)
  if (any(!relations$affix_position %in% c("prefix", "suffix")))
    stop("The final field must be prefix or suffix.", call. = FALSE)
  relations$source_line <- seq_len(nrow(relations))
  relations$relation_id <- sprintf("morphynet:%s:%07d", substr(sha, 1L, 12L), relations$source_line)
  relations <- relations[c("relation_id", "source_line", "source_word", "target_word",
    "source_pos", "target_pos", "morpheme", "affix_position")]
  # A local file could change while being read: bind the result to one snapshot.
  if (!identical(sha, digest::digest(file = path, algo = "sha256")))
    stop("The relation file changed during reading.", call. = FALSE)
  resource <- list(resource_id = "MorphyNet-derivational", resource_version = resource_version,
    language = language, source_sha256 = sha,
    source_reference = paste("Batsuren, K., Bella, G., & Giunchiglia, F. (2021).",
      "MorphyNet: a Large Multilingual Database of Derivational and Inflectional Morphology.",
      "SIGMORPHON, 39-48. doi:10.18653/v1/2021.sigmorphon-1.5"),
    source_url = "https://github.com/kbatsuren/MorphyNet",
    data_license = "CC BY-SA 3.0",
    license_url = "https://creativecommons.org/licenses/by-sa/3.0/",
    scope = "Supplied one-step derivational relations; not complete segmentation or educational families")
  list(relations = relations, resource = resource,
    provenance = list(reader = "ldfreq-morphynet-derivations", reader_version = "0.1.0",
      source_sha256 = sha, rows = nrow(relations), max_rows = max_rows,
      transformation = paste("Six UTF-8 fields preserved literally; source lines and scoped IDs added.",
        "Initial BOM and line endings are encoding delimiters; no spelling or POS normalization.",
        "Duplicates, whitespace inside fields and literal NA retained; no local path recorded."),
      language_and_version = "Caller declarations; not inferred or independently authenticated",
      pos = "Original resource symbols retained; no UD mapping",
      completeness = "Unlisted target is not evidence of an unanalysable or unaffixed word"))
}
