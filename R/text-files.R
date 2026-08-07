# Explicit local text-file ingestion for raw-text preprocessing.

.lexfiles_contract_id <- "ldfreq-text-file-input"
.lexfiles_contract_version <- "0.1.0"

.lexfiles_paths <- function(value, argument) {
  if (
    !is.character(value) || is.object(value) || !is.null(dim(value)) ||
      !is.null(attributes(value)) || length(value) == 0L || anyNA(value) ||
      any(!nzchar(value)) || any(Encoding(value) %in% c("bytes", "latin1")) ||
      any(!validUTF8(value))
  ) {
    stop(
      sprintf(
        "%s must contain one or more plain, non-empty valid-UTF-8 local paths.",
        argument
      ),
      call. = FALSE
    )
  }
  Encoding(value) <- "UTF-8"
  value
}

.lexfiles_byte_limit <- function(value, argument) {
  if (
    !is.numeric(value) || is.object(value) || !is.null(dim(value)) ||
      !is.null(attributes(value)) || length(value) != 1L || is.na(value) ||
      !is.finite(value) || value < 1 || value != floor(value) ||
      value > .Machine$integer.max
  ) {
    stop(
      sprintf(
        "%s must be one positive integer no greater than %d.",
        argument,
        .Machine$integer.max
      ),
      call. = FALSE
    )
  }
  as.double(value)
}

.lexfiles_pattern <- function(value) {
  if (
    !is.character(value) || is.object(value) || !is.null(dim(value)) ||
      !is.null(attributes(value)) || length(value) != 1L || is.na(value) ||
      !nzchar(value) || Encoding(value) %in% c("bytes", "latin1") ||
      !validUTF8(value)
  ) {
    stop(
      "pattern must be one plain, non-empty valid-UTF-8 regular expression.",
      call. = FALSE
    )
  }
  Encoding(value) <- "UTF-8"
  value
}

.lexfiles_normalize_paths <- function(paths) {
  missing <- !file.exists(paths)
  if (any(missing)) {
    stop(
      sprintf(
        "Text file does not exist: %s.",
        basename(paths[[which(missing)[[1L]]]])
      ),
      call. = FALSE
    )
  }

  normalized <- vapply(paths, function(path) {
    tryCatch(
      normalizePath(path, winslash = "/", mustWork = TRUE),
      error = function(error) NA_character_
    )
  }, character(1), USE.NAMES = FALSE)
  if (anyNA(normalized)) {
    stop(
      sprintf(
        "Text file path could not be resolved: %s.",
        basename(paths[[which(is.na(normalized))[[1L]]]])
      ),
      call. = FALSE
    )
  }
  Encoding(normalized) <- "UTF-8"
  if (anyDuplicated(normalized)) {
    stop("path must not identify the same text file more than once.", call. = FALSE)
  }
  normalized
}

.lexfiles_information <- function(paths, max_file_bytes, max_total_bytes) {
  information <- file.info(paths)
  sizes <- unname(information$size)
  regular <- vapply(paths, function(path) {
    isTRUE(utils::file_test("-f", path))
  }, logical(1))
  readable <- unname(file.access(paths, mode = 4L)) == 0L

  invalid <- is.na(sizes) | !regular | !readable | !is.finite(sizes) | sizes < 0
  if (any(invalid)) {
    stop(
      sprintf(
        "Not a readable regular text file: %s.",
        basename(paths[[which(invalid)[[1L]]]])
      ),
      call. = FALSE
    )
  }
  too_large <- sizes > max_file_bytes
  if (any(too_large)) {
    stop(
      sprintf(
        "Text file exceeds max_file_bytes: %s.",
        basename(paths[[which(too_large)[[1L]]]])
      ),
      call. = FALSE
    )
  }
  if (sum(sizes) > max_total_bytes) {
    stop("Selected text files exceed max_total_bytes.", call. = FALSE)
  }
  sizes
}

.lexfiles_read_one <- function(path, size) {
  label <- basename(path)
  payload <- tryCatch({
    connection <- file(path, open = "rb")
    on.exit(close(connection), add = TRUE)
    bytes <- readBin(connection, what = "raw", n = as.integer(size))
    trailing <- readBin(connection, what = "raw", n = 1L)
    list(bytes = bytes, trailing = trailing)
  }, error = function(error) NULL)

  if (
    is.null(payload) || length(payload$bytes) != size ||
      length(payload$trailing) != 0L
  ) {
    stop(
      sprintf("Text file changed or could not be read: %s.", label),
      call. = FALSE
    )
  }
  if (any(payload$bytes == as.raw(0L))) {
    stop(
      sprintf("Text file contains an embedded NUL byte: %s.", label),
      call. = FALSE
    )
  }

  text <- rawToChar(payload$bytes)
  Encoding(text) <- "UTF-8"
  if (!validUTF8(text)) {
    stop(
      sprintf("Text file is not valid UTF-8: %s.", label),
      call. = FALSE
    )
  }
  list(
    text = text,
    source_sha256 = digest::digest(
      payload$bytes,
      algo = "sha256",
      serialize = FALSE
    )
  )
}

#' Read one or more UTF-8 text files as named raw documents
#'
#' Reads explicit local file paths, or discovers files from one local directory,
#' without tokenizing or otherwise changing their contents. Each file becomes
#' one scalar character string suitable for [lexdiv_metrics_text()].
#'
#' @param path Either one local directory or a plain character vector containing
#'   one or more explicit local file paths. URLs are not supported.
#' @param document_ids Optional explicit document IDs aligned one-to-one with
#'   the selected files. By default, IDs are filename stems. IDs must be unique,
#'   non-empty valid-UTF-8 strings.
#' @param pattern Regular expression used only when `path` is a directory.
#'   Matching is case-insensitive; the default selects `.txt` files.
#' @param recursive Whether directory discovery includes subdirectories.
#' @param max_file_bytes Maximum allowed size of each file in bytes.
#' @param max_total_bytes Maximum combined size of all selected files in bytes.
#'
#' @return A `lexdiv_text_corpus` list containing `texts`, a named character
#'   vector in selected-file order; `documents`, a path-private input manifest;
#'   and `provenance`, the versioned corpus and reader choices and bounds.
#'   Absolute paths are not retained in the result.
#'
#' @details
#' Directory discovery is deterministic: files are returned in the order
#' produced by [list.files()], which is alphabetical for a fixed directory.
#' Explicit file vectors preserve caller order. A directory with no matching
#' files, duplicate resolved paths, duplicate derived IDs, unreadable files,
#' invalid UTF-8, embedded NUL bytes, and size-bound violations are errors.
#'
#' The function only reads text. Use
#' `lapply(corpus$texts, lexdiv_metrics_text, ...)`
#' to retain a separate token and preprocessing audit for every raw document.
#' Use [lexdiv_metrics_batch()] only after every document has already been
#' converted to a token vector.
#'
#' @export
lexdiv_read_texts <- function(
    path,
    document_ids = NULL,
    pattern = "[.]txt$",
    recursive = FALSE,
    max_file_bytes = 10 * 1024^2,
    max_total_bytes = 100 * 1024^2) {
  path <- .lexfiles_paths(path, "path")
  pattern <- .lexfiles_pattern(pattern)
  recursive <- .lexprep_scalar_flag(recursive, "recursive")
  max_file_bytes <- .lexfiles_byte_limit(max_file_bytes, "max_file_bytes")
  max_total_bytes <- .lexfiles_byte_limit(max_total_bytes, "max_total_bytes")

  directory_input <- length(path) == 1L && dir.exists(path)
  if (directory_input) {
    directory <- tryCatch(
      normalizePath(path, winslash = "/", mustWork = TRUE),
      error = function(error) NA_character_
    )
    if (is.na(directory)) {
      stop("The input directory could not be resolved.", call. = FALSE)
    }
    files <- tryCatch(
      list.files(
        directory,
        pattern = pattern,
        all.files = FALSE,
        full.names = TRUE,
        recursive = recursive,
        ignore.case = TRUE,
        include.dirs = FALSE,
        no.. = TRUE
      ),
      error = function(error) NULL,
      warning = function(warning) NULL
    )
    if (is.null(files)) {
      stop("pattern is not a valid regular expression.", call. = FALSE)
    }
    if (length(files) == 0L) {
      stop("No matching text files were found in the directory.", call. = FALSE)
    }
    Encoding(files) <- "UTF-8"
  } else {
    files <- path
  }

  files <- .lexfiles_normalize_paths(files)
  sizes <- .lexfiles_information(files, max_file_bytes, max_total_bytes)

  if (is.null(document_ids)) {
    document_ids <- unname(tools::file_path_sans_ext(basename(files)))
  }
  document_ids <- .lex_batch_validate_ids(document_ids, length(files))

  pieces <- lapply(seq_along(files), function(index) {
    .lexfiles_read_one(files[[index]], sizes[[index]])
  })
  texts <- vapply(pieces, `[[`, character(1), "text", USE.NAMES = FALSE)
  names(texts) <- document_ids
  corpus_data <- data.frame(
    document_id = document_ids,
    text = unname(texts),
    source_file = basename(files),
    source_bytes = as.double(sizes),
    source_sha256 = vapply(
      pieces,
      `[[`,
      character(1),
      "source_sha256",
      USE.NAMES = FALSE
    ),
    stringsAsFactors = FALSE,
    check.names = FALSE
  )
  corpus <- lexdiv_text_corpus(
    corpus_data,
    metadata_cols = c("source_file", "source_bytes", "source_sha256")
  )
  corpus$provenance <- c(corpus$provenance, list(
    input_contract_id = .lexfiles_contract_id,
    input_contract_version = .lexfiles_contract_version,
    source_mode = if (directory_input) "directory" else "explicit_files",
    pattern = if (directory_input) pattern else NA_character_,
    recursive = if (directory_input) recursive else FALSE,
    file_count = length(files),
    total_bytes = sum(sizes),
    max_file_bytes = max_file_bytes,
    max_total_bytes = max_total_bytes,
    path_retained = FALSE
  ))
  corpus
}
