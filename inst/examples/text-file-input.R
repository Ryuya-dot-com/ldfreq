# Source explicitly: this teaching helper is not an exported ldfreq function.
# One local file, one declared encoding; no normalization or tokenization.
read_text_file <- function(path, encoding = "UTF-8", max_bytes = 10 * 1024^2) {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path) ||
      !isTRUE(utils::file_test("-f", path)))
    stop("path must identify one existing regular file.", call. = FALSE)
  if (!is.character(encoding) || length(encoding) != 1L || is.na(encoding) ||
      !encoding %in% c("UTF-8", "CP932"))
    stop("Declare encoding as UTF-8 or CP932; this example does not guess.", call. = FALSE)
  if (!is.numeric(max_bytes) || length(max_bytes) != 1L || is.na(max_bytes) ||
      !is.finite(max_bytes) || max_bytes < 1 || max_bytes != floor(max_bytes) ||
      max_bytes >= .Machine$integer.max)
    stop("max_bytes must be a positive whole number below the integer limit.", call. = FALSE)
  size <- file.info(path)$size
  if (is.na(size) || size > max_bytes)
    stop("File exceeds max_bytes or its size is unavailable: ", path, call. = FALSE)
  connection <- file(path, open = "rb")
  on.exit(close(connection))
  bytes <- readBin(connection, "raw", n = as.integer(size) + 1L)
  if (length(bytes) != size || any(bytes == as.raw(0)))
    stop("Incomplete/changed file or embedded NUL: ", path, call. = FALSE)
  bom <- length(bytes) >= 3L && identical(bytes[1:3], as.raw(c(239, 187, 191)))
  if (bom && encoding != "UTF-8")
    stop("UTF-8 BOM conflicts with declared encoding: ", path, call. = FALSE)
  payload <- if (bom) bytes[-(1:3)] else bytes
  text <- iconv(rawToChar(payload), from = encoding, to = "UTF-8", sub = NA)
  if (is.na(text) || !validUTF8(text))
    stop("Cannot decode as ", encoding, ": ", path, call. = FALSE)
  restored <- iconv(text, from = "UTF-8", to = encoding, sub = NA)
  if (is.na(restored) || !identical(charToRaw(restored), payload))
    stop("Byte round-trip failed; inspect the declared encoding: ", path, call. = FALSE)
  Encoding(text) <- "UTF-8"
  list(text = text, source = data.frame(
    source_file = path, source_encoding = encoding, source_bytes = length(bytes),
    utf8_bom_removed = bom, characters = nchar(text, type = "chars"),
    source_sha256 = digest::digest(bytes, algo = "sha256", serialize = FALSE),
    text_sha256 = digest::digest(charToRaw(text), algo = "sha256", serialize = FALSE),
    text_policy = "Decode explicitly; remove leading UTF-8 BOM only; retain all other characters and line endings",
    stringsAsFactors = FALSE))
}
