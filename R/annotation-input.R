# Import complete external annotations before selecting lexical forms or rows.
lexdiv_import_annotations <- function(data, segments, provenance, max_tokens = 1e6) {
  data <- .lexnorm_plain_data_frame(data, "data")
  segments <- .lexnorm_plain_data_frame(segments, "segments")
  keys <- c("document_id", "segment_id")
  if (!all(c(keys, "token_index", "surface") %in% names(data)) ||
      !all(c(keys, "text") %in% names(segments)))
    stop("Supply token IDs, token_index and surface, and segment IDs with text.", call. = FALSE)
  if (any(c("token_count", "text_sha256") %in% names(segments)))
    stop("token_count and text_sha256 are reserved segment output columns.", call. = FALSE)
  max_tokens <- .lexnorm_positive_whole(max_tokens, "max_tokens")
  if (nrow(data) > max_tokens)
    stop("The number of input rows exceeds max_tokens.", call. = FALSE)
  for (key in keys) {
    data[[key]] <- .lexnorm_plain_character(data[[key]], key, allow_zero = TRUE)
    segments[[key]] <- .lexnorm_plain_character(segments[[key]], key, allow_zero = TRUE)
  }
  data$surface <- .lexnorm_plain_character(data$surface, "surface", allow_zero = TRUE)
  source <- segments$text
  if (!is.character(source) || !is.null(attributes(source)) || anyNA(source) ||
      any(Encoding(source) %in% c("bytes", "latin1")) || any(!validUTF8(source)))
    stop("segments$text must contain plain valid-UTF-8 strings; empty text is allowed.",
      call. = FALSE)
  Encoding(source) <- "UTF-8"
  segments$text <- source
  position <- .lexng_count(data$token_index, "token_index", 1)
  segment_key <- .lexng_key(segments[keys])
  group <- match(.lexng_key(data[keys]), segment_key)
  if (!nrow(segments) || anyDuplicated(segment_key) || anyNA(group) ||
      any(diff(group) < 0))
    stop("Supply unique segments and token rows in matching segment order.", call. = FALSE)
  document_ids <- unique(segments$document_id)
  if (any(diff(match(segments$document_id, document_ids)) < 0))
    stop("Each document must occupy one contiguous block of segments.", call. = FALSE)
  provenance <- .lexnorm_plain_list(provenance, "provenance")
  required <- c("language", "analyzer", "analyzer_version", "dictionary",
    "dictionary_version", "unit", "normalization")
  if (!all(required %in% names(provenance)))
    stop("provenance requires: ", paste(required, collapse = ", "), ".", call. = FALSE)
  for (key in names(provenance)) {
    value <- provenance[[key]]
    if (identical(value, NA_character_) && !key %in% required) next
    provenance[[key]] <- .lexnorm_scalar_string(value, paste0("provenance$", key))
  }
  # Work in Unicode codepoints, not bytes, UTF-16 units or normalized text.
  # Only whitespace may occur between supplied surfaces. In particular, a
  # later repeated token cannot conceal an omitted non-whitespace token.
  rows <- split(seq_len(nrow(data)), factor(group, levels = seq_len(nrow(segments))))
  starts <- ends <- integer(nrow(data))
  width <- stringi::stri_length(data$surface)
  begins_space <- stringi::stri_detect_regex(data$surface, "^\\p{White_Space}")
  for (i in seq_len(nrow(segments))) {
    idx <- rows[[i]]
    if (!identical(position[idx], as.double(seq_along(idx))))
      stop("Import all tokens with consecutive token_index starting at 1; filter afterwards.",
        call. = FALSE)
    space <- rep(FALSE, stringi::stri_length(source[i]))
    whitespace <- stringi::stri_locate_all_regex(source[i], "\\p{White_Space}")[[1L]][, 1L]
    space[whitespace[!is.na(whitespace)]] <- TRUE
    cursor <- 1L
    for (j in idx) {
      if (begins_space[j]) {
        # An analyzer may emit CR tokens but omit LF in CRLF sequences.
        # Match the earliest exact surface after whitespace-only gaps; never
        # advance across an omitted letter, punctuation or other content.
        while (cursor <= length(space) && space[cursor] &&
            stringi::stri_sub(source[i], cursor, cursor + width[j] - 1L) != data$surface[j])
          cursor <- cursor + 1L
      } else {
        while (cursor <= length(space) && space[cursor]) cursor <- cursor + 1L
      }
      starts[j] <- cursor
      ends[j] <- cursor + width[j] - 1L
      cursor <- ends[j] + 1L
    }
    if (length(idx) && (any(ends[idx] > length(space)) ||
        any(stringi::stri_sub(source[i], starts[idx], ends[idx]) != data$surface[idx])))
      stop("Surfaces do not align exactly with original text in segment row ", i,
        "; import complete, unnormalized annotations before filtering.", call. = FALSE)
    if (cursor <= length(space) && any(!space[seq.int(cursor, length(space))]))
      stop("Unannotated non-whitespace text remains in segment row ", i, ".", call. = FALSE)
  }
  for (key in c("start", "end")) {
    computed <- if (key == "start") starts else ends
    if (key %in% names(data) &&
        !identical(.lexng_count(data[[key]], key, 1), as.double(computed)))
      stop("Supplied ", key, " does not match segment-local, 1-based codepoint positions.",
        call. = FALSE)
    data[[key]] <- computed
  }
  segments$token_count <- as.integer(lengths(rows))
  segments$text_sha256 <- vapply(source, digest::digest, character(1),
    algo = "sha256", serialize = FALSE, USE.NAMES = FALSE)
  documents <- data.frame(document_id = document_ids, stringsAsFactors = FALSE)
  rownames(data) <- rownames(segments) <- NULL
  list(tokens = data, segments = segments, documents = documents,
    provenance = list(importer = "ldfreq-external-annotations", importer_version = "0.1.0",
      coordinates = "segment-local-1-based-inclusive-Unicode-codepoints",
      alignment = "exact-surfaces-whitespace-gaps-only", normalization = "none",
      annotation = provenance,
      input_sha256 = digest::digest(list(data, segments, provenance),
        algo = "sha256", serializeVersion = 2L)))
}
