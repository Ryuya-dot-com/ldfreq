#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) {
  stop(
    paste(
      "Usage: Rscript build-tubelex-from-source.R",
      "<pinned-source.tsv.xz> <slim.csv.gz> <manifest.json>"
    ),
    call. = FALSE
  )
}

input_path <- normalizePath(args[[1L]], mustWork = TRUE)
output_path <- normalizePath(args[[2L]], mustWork = FALSE)
manifest_path <- normalizePath(args[[3L]], mustWork = FALSE)

for (package in c("digest", "jsonlite", "stringi")) {
  if (!requireNamespace(package, quietly = TRUE)) {
    stop(sprintf("The builder requires the R package %s.", package), call. = FALSE)
  }
}
if (!grepl("\\.tsv\\.xz$", input_path, ignore.case = TRUE)) {
  stop("The pinned source must use the .tsv.xz suffix.", call. = FALSE)
}
if (file.exists(output_path) || file.exists(manifest_path)) {
  stop("Refusing to overwrite an existing output or manifest.", call. = FALSE)
}
if (identical(output_path, manifest_path)) {
  stop("Artifact and manifest paths must differ.", call. = FALSE)
}

source_contract <- list(
  project = "TUBELEX",
  repository = "https://github.com/naist-nlp/tubelex",
  commit = "7cb5fb36add76b83a266d1967536e1a1d3faa513",
  asset = "tubelex-en-treebank.tsv.xz",
  url = paste0(
    "https://raw.githubusercontent.com/naist-nlp/tubelex/",
    "7cb5fb36add76b83a266d1967536e1a1d3faa513/",
    "frequencies/tubelex-en-treebank.tsv.xz"
  ),
  bytes = 4152940,
  sha256 = "4096022259d5eaa7261c3bf22c3b0af9fd58ae8eebe17894c0b34a163954f936",
  decompressed_sha256 = "5ccfde4184698c1fa8049ba7c761d253d039fa5ad4e93e15239644fe6034b5c1",
  physical_rows = 613311L,
  word_rows = 613309L
)

base_columns <- c("word", "count", "videos", "channels")
categories <- c(
  "howto", "gaming", "entertainment", "education", "science", "sports",
  "nonprofits", "autos", "people", "music", "news", "film", "travel",
  "comedy", "pets"
)
expected_columns <- c(base_columns, paste0("count:", categories))
expected_totals <- c(
  count = 171805865,
  videos = 105733,
  channels = 68405,
  howto = 10331143,
  gaming = 11190388,
  entertainment = 21712969,
  education = 45682925,
  science = 14890400,
  sports = 3969422,
  nonprofits = 8026361,
  autos = 2269188,
  people = 29417376,
  music = 2667215,
  news = 9400743,
  film = 5390228,
  travel = 4491301,
  comedy = 1448434,
  pets = 917772
)
expected_retained_rows <- 515292L
expected_retained_count <- 169889910
expected_canonical_bytes <- 8260448
expected_canonical_sha256 <- "423dd4631c9da2f7442705d2930126da4cba980e46b6a5c0dda98336dce74916"

max_compressed_bytes <- 64 * 1024 * 1024
max_decompressed_bytes <- 256 * 1024 * 1024
max_line_bytes <- 64 * 1024
max_integer <- 2^32 - 1

input_bytes <- unname(file.info(input_path)$size)
if (!is.finite(input_bytes) || input_bytes > max_compressed_bytes) {
  stop("The compressed source exceeds the safety limit.", call. = FALSE)
}
if (!identical(as.numeric(input_bytes), as.numeric(source_contract$bytes))) {
  stop(
    sprintf("Source byte mismatch: expected %d, got %d.", source_contract$bytes, input_bytes),
    call. = FALSE
  )
}
input_sha256 <- digest::digest(file = input_path, algo = "sha256", serialize = FALSE)
if (!identical(input_sha256, source_contract$sha256)) {
  stop(
    sprintf("Source SHA-256 mismatch: expected %s, got %s.", source_contract$sha256, input_sha256),
    call. = FALSE
  )
}

# Create output directories only after the fixed input has passed its compressed
# size and hash checks. A rejected source therefore leaves no build directory.
dir.create(dirname(output_path), recursive = TRUE, showWarnings = FALSE)
dir.create(dirname(manifest_path), recursive = TRUE, showWarnings = FALSE)

main <- function() {
  old_collate <- Sys.getlocale("LC_COLLATE")
  on.exit(suppressWarnings(Sys.setlocale("LC_COLLATE", old_collate)), add = TRUE)
  set_collate <- suppressWarnings(Sys.setlocale("LC_COLLATE", "C"))
  if (is.na(set_collate) || !nzchar(set_collate) ||
      !identical(Sys.getlocale("LC_COLLATE"), "C")) {
    stop("The builder requires the C collation locale.", call. = FALSE)
  }

  decompressed_path <- tempfile(
    pattern = ".tubelex-source-",
    tmpdir = dirname(output_path),
    fileext = ".tsv"
  )
  canonical_path <- tempfile(
    pattern = ".tubelex-canonical-",
    tmpdir = dirname(output_path),
    fileext = ".csv"
  )
  staged_output <- tempfile(
    pattern = ".tubelex-artifact-",
    tmpdir = dirname(output_path),
    fileext = ".csv.gz"
  )
  staged_manifest <- tempfile(
    pattern = ".tubelex-manifest-",
    tmpdir = dirname(manifest_path),
    fileext = ".json"
  )
  roundtrip_path <- tempfile(
    pattern = ".tubelex-roundtrip-",
    tmpdir = dirname(output_path),
    fileext = ".csv"
  )
  on.exit(
    unlink(
      c(
        decompressed_path, canonical_path, staged_output, staged_manifest,
        roundtrip_path
      ),
      force = TRUE
    ),
    add = TRUE
  )

  # R's xz connection is copied to a bounded temporary file so the digest of
  # the exact decompressed bytes is checked before any row transformation.
  compressed_connection <- xzfile(input_path, open = "rb")
  decompressed_connection <- file(decompressed_path, open = "wb")
  on.exit(try(close(compressed_connection), silent = TRUE), add = TRUE)
  on.exit(try(close(decompressed_connection), silent = TRUE), add = TRUE)
  decompressed_bytes <- 0
  current_line_bytes <- 0
  observed_max_line_bytes <- 0
  repeat {
    payload <- readBin(compressed_connection, what = "raw", n = 1048576L)
    if (!length(payload)) break
    decompressed_bytes <- decompressed_bytes + length(payload)
    if (decompressed_bytes > max_decompressed_bytes) {
      stop("The decompressed source exceeds the safety limit.", call. = FALSE)
    }

    # Enforce the physical-line bound on raw decompressed bytes before
    # readLines() sees the file. This avoids allocating an attacker-controlled
    # giant text line even if this builder is later generalized beyond the pin.
    newline_positions <- which(payload == as.raw(10L))
    if (length(newline_positions)) {
      complete_line_lengths <- diff(c(0L, newline_positions))
      complete_line_lengths[[1L]] <- complete_line_lengths[[1L]] + current_line_bytes
      observed_max_line_bytes <- max(observed_max_line_bytes, complete_line_lengths)
      if (any(complete_line_lengths > max_line_bytes)) {
        stop("A decompressed source line exceeds the safety limit.", call. = FALSE)
      }
      current_line_bytes <- length(payload) - newline_positions[[length(newline_positions)]]
    } else {
      current_line_bytes <- current_line_bytes + length(payload)
    }
    if (current_line_bytes > max_line_bytes) {
      stop("A decompressed source line exceeds the safety limit.", call. = FALSE)
    }
    writeBin(payload, decompressed_connection, useBytes = TRUE)
  }
  observed_max_line_bytes <- max(observed_max_line_bytes, current_line_bytes)
  close(compressed_connection)
  close(decompressed_connection)

  decompressed_sha256 <- digest::digest(
    file = decompressed_path,
    algo = "sha256",
    serialize = FALSE
  )
  if (!identical(decompressed_sha256, source_contract$decompressed_sha256)) {
    stop(
      sprintf(
        "Decompressed SHA-256 mismatch: expected %s, got %s.",
        source_contract$decompressed_sha256,
        decompressed_sha256
      ),
      call. = FALSE
    )
  }

  source_connection <- file(decompressed_path, open = "rt", encoding = "UTF-8")
  on.exit(try(close(source_connection), silent = TRUE), add = TRUE)
  header <- readLines(source_connection, n = 1L, warn = FALSE, encoding = "UTF-8")
  if (length(header) != 1L) stop("The decompressed source is empty.", call. = FALSE)
  if (nchar(header, type = "bytes") > max_line_bytes) {
    stop("The source header exceeds the line-size limit.", call. = FALSE)
  }
  header_fields <- strsplit(header, "\t", fixed = TRUE)[[1L]]
  if (!identical(header_fields, expected_columns)) {
    stop("The source does not have the pinned 19-column schema.", call. = FALSE)
  }

  all_word_chunks <- list()
  retained_word_chunks <- list()
  retained_line_chunks <- list()
  source_word_rows <- 0L
  retained_rows <- 0L
  retained_count <- 0
  source_count <- 0
  source_category_counts <- numeric(length(categories))
  total_values <- NULL
  total_fields <- NULL
  total_rows <- 0L
  physical_rows <- 1L
  chunk_number <- 0L

  # This full-match is the R/ICU spelling of Python's source predicate:
  # optional leading ASCII apostrophe followed by non-empty Unicode Letter
  # components separated by ASCII apostrophes or hyphens. Unicode Letter
  # (general category L*) matches Python str.isalpha(); ICU's broader derived
  # Alphabetic property would incorrectly admit combining marks and U+3007.
  lookup_pattern <- "^'?(?:\\p{L}+)(?:['-]\\p{L}+)*$"

  repeat {
    lines <- readLines(source_connection, n = 10000L, warn = FALSE, encoding = "UTF-8")
    if (!length(lines)) break
    chunk_number <- chunk_number + 1L
    physical_rows <- physical_rows + length(lines)
    if (physical_rows > source_contract$physical_rows) {
      stop("The source exceeds the pinned physical-row count.", call. = FALSE)
    }
    if (any(nchar(lines, type = "bytes") > max_line_bytes)) {
      stop("A source row exceeds the line-size limit.", call. = FALSE)
    }

    fields <- strsplit(lines, "\t", fixed = TRUE)
    field_counts <- lengths(fields)
    if (any(field_counts != length(expected_columns))) {
      bad <- which(field_counts != length(expected_columns))[[1L]]
      stop(
        sprintf(
          "Unexpected field count at physical row %d.",
          physical_rows - length(lines) + bad
        ),
        call. = FALSE
      )
    }

    words <- vapply(fields, `[[`, character(1L), 1L, USE.NAMES = FALSE)
    if (any(!nzchar(words))) stop("The source contains an empty word.", call. = FALSE)
    if (anyNA(iconv(words, from = "UTF-8", to = "UTF-8", sub = NA_character_))) {
      stop("The source contains invalid UTF-8.", call. = FALSE)
    }
    if (any(grepl("[\\t\\r\\n\\x00]", words, perl = TRUE))) {
      stop("A source word contains a forbidden control character.", call. = FALSE)
    }
    if (any(stringi::stri_length(words) > 4096L)) {
      stop("A source word exceeds the 4,096-code-point limit.", call. = FALSE)
    }

    numeric_text <- unlist(lapply(fields, `[`, -1L), use.names = FALSE)
    if (any(!grepl("^(0|[1-9][0-9]*)$", numeric_text))) {
      stop("The source contains a non-canonical non-negative integer.", call. = FALSE)
    }
    numeric_values <- matrix(
      as.numeric(numeric_text),
      ncol = length(expected_columns) - 1L,
      byrow = TRUE
    )
    if (any(!is.finite(numeric_values)) || any(numeric_values > max_integer)) {
      stop("The source contains an out-of-range integer.", call. = FALSE)
    }

    is_total <- words == "[TOTAL]"
    if (any(is_total)) {
      total_rows <- total_rows + sum(is_total)
      if (total_rows > 1L) stop("The [TOTAL] row is duplicated.", call. = FALSE)
      total_index <- which(is_total)[[1L]]
      total_values <- numeric_values[total_index, , drop = TRUE]
      total_fields <- fields[[total_index]]
    }

    lexical <- which(!is_total)
    if (!length(lexical)) next
    lexical_words <- words[lexical]
    lexical_values <- numeric_values[lexical, , drop = FALSE]
    count <- lexical_values[, 1L]
    videos <- lexical_values[, 2L]
    channels <- lexical_values[, 3L]
    category_values <- lexical_values[, 4L:ncol(lexical_values), drop = FALSE]
    if (any(channels > videos) || any(videos > count)) {
      stop("A source row violates channels <= videos <= count.", call. = FALSE)
    }
    if (any(rowSums(category_values) != count)) {
      stop("A source row violates the category-count total.", call. = FALSE)
    }

    source_word_rows <- source_word_rows + length(lexical)
    source_count <- source_count + sum(count)
    source_category_counts <- source_category_counts + colSums(category_values)
    all_word_chunks[[chunk_number]] <- lexical_words

    normalized <- stringi::stri_trans_tolower(
      stringi::stri_trim_both(stringi::stri_trans_nfkc(lexical_words)),
      locale = "und"
    )
    compatible <- (
      stringi::stri_length(lexical_words) <= 64L &
        lexical_words == normalized &
        stringi::stri_detect_regex(lexical_words, lookup_pattern)
    )
    if (anyNA(compatible)) stop("The lookup predicate produced NA.", call. = FALSE)
    retained <- which(compatible)
    if (length(retained)) {
      retained_words <- lexical_words[retained]
      retained_fields <- fields[lexical[retained]]
      retained_word_chunks[[chunk_number]] <- retained_words
      retained_line_chunks[[chunk_number]] <- vapply(
        retained_fields,
        function(row) paste(row[seq_along(base_columns)], collapse = ","),
        character(1L),
        USE.NAMES = FALSE
      )
      retained_rows <- retained_rows + length(retained)
      retained_count <- retained_count + sum(count[retained])
    }
  }
  close(source_connection)

  if (!identical(physical_rows, source_contract$physical_rows)) {
    stop(
      sprintf(
        "Physical-row mismatch: expected %d, got %d.",
        source_contract$physical_rows,
        physical_rows
      ),
      call. = FALSE
    )
  }
  if (!identical(source_word_rows, source_contract$word_rows)) {
    stop(
      sprintf(
        "Source word-row mismatch: expected %d, got %d.",
        source_contract$word_rows,
        source_word_rows
      ),
      call. = FALSE
    )
  }
  if (total_rows != 1L || is.null(total_values) || is.null(total_fields)) {
    stop("The source must contain exactly one [TOTAL] row.", call. = FALSE)
  }
  if (!identical(as.numeric(total_values), as.numeric(expected_totals))) {
    stop("The [TOTAL] row does not match the pinned source contract.", call. = FALSE)
  }
  if (!identical(as.numeric(source_count), as.numeric(expected_totals[["count"]]))) {
    stop("Source word counts do not sum to the declared total.", call. = FALSE)
  }
  if (!identical(
    as.numeric(source_category_counts),
    as.numeric(expected_totals[4L:length(expected_totals)])
  )) {
    stop("Source category counts do not sum to the declared totals.", call. = FALSE)
  }

  all_words <- unlist(all_word_chunks, use.names = FALSE)
  if (length(all_words) != source_word_rows) {
    stop("Internal source-word accumulation mismatch.", call. = FALSE)
  }
  sorted_all_words <- sort(all_words, method = "radix")
  if (anyDuplicated(sorted_all_words)) {
    stop("The source contains a duplicate word.", call. = FALSE)
  }
  rm(all_words, sorted_all_words, all_word_chunks)

  retained_words <- unlist(retained_word_chunks, use.names = FALSE)
  retained_lines <- unlist(retained_line_chunks, use.names = FALSE)
  if (!identical(length(retained_words), retained_rows) ||
      !identical(length(retained_lines), retained_rows)) {
    stop("Internal retained-row accumulation mismatch.", call. = FALSE)
  }
  if (!identical(retained_rows, expected_retained_rows)) {
    stop(
      sprintf(
        "Lookup-filter row mismatch: expected %d, got %d.",
        expected_retained_rows,
        retained_rows
      ),
      call. = FALSE
    )
  }
  if (!identical(as.numeric(retained_count), as.numeric(expected_retained_count))) {
    stop(
      sprintf(
        "Lookup-filter token-mass mismatch: expected %d, got %.0f.",
        expected_retained_count,
        retained_count
      ),
      call. = FALSE
    )
  }

  ordering <- order(retained_words, method = "radix")
  if (anyDuplicated(retained_words[ordering])) {
    stop("The retained lookup contains a duplicate word.", call. = FALSE)
  }
  canonical_connection <- file(canonical_path, open = "wb")
  on.exit(try(close(canonical_connection), silent = TRUE), add = TRUE)
  writeLines(
    paste(base_columns, collapse = ","),
    canonical_connection,
    sep = "\n",
    useBytes = TRUE
  )
  writeLines(
    retained_lines[ordering],
    canonical_connection,
    sep = "\n",
    useBytes = TRUE
  )
  writeLines(
    paste(total_fields[seq_along(base_columns)], collapse = ","),
    canonical_connection,
    sep = "\n",
    useBytes = TRUE
  )
  close(canonical_connection)

  canonical_bytes <- unname(file.info(canonical_path)$size)
  canonical_sha256 <- digest::digest(
    file = canonical_path,
    algo = "sha256",
    serialize = FALSE
  )
  if (!identical(as.numeric(canonical_bytes), as.numeric(expected_canonical_bytes)) ||
      !identical(canonical_sha256, expected_canonical_sha256)) {
    stop(
      paste(
        "The direct R build did not reproduce the reviewed semantic artifact:",
        sprintf("got %d bytes and SHA-256 %s.", canonical_bytes, canonical_sha256)
      ),
      call. = FALSE
    )
  }

  canonical_input <- file(canonical_path, open = "rb")
  gzip_output <- gzfile(staged_output, open = "wb", compression = 9L)
  on.exit(try(close(canonical_input), silent = TRUE), add = TRUE)
  on.exit(try(close(gzip_output), silent = TRUE), add = TRUE)
  repeat {
    payload <- readBin(canonical_input, what = "raw", n = 1048576L)
    if (!length(payload)) break
    writeBin(payload, gzip_output, useBytes = TRUE)
  }
  close(canonical_input)
  close(gzip_output)

  gzip_header <- readBin(staged_output, what = "raw", n = 10L)
  if (length(gzip_header) != 10L ||
      !identical(as.integer(gzip_header[1L:3L]), c(31L, 139L, 8L))) {
    stop("R did not produce a valid gzip header.", call. = FALSE)
  }
  if (!identical(as.integer(gzip_header[5L:8L]), rep(0L, 4L))) {
    stop("R gzip output contains a non-zero modification timestamp.", call. = FALSE)
  }

  # Check the actual compressed stream, not only its header. The canonical hash
  # is recomputed after a complete gzip round trip.
  gzip_input <- gzfile(staged_output, open = "rb")
  roundtrip_output <- file(roundtrip_path, open = "wb")
  on.exit(try(close(gzip_input), silent = TRUE), add = TRUE)
  on.exit(try(close(roundtrip_output), silent = TRUE), add = TRUE)
  repeat {
    payload <- readBin(gzip_input, what = "raw", n = 1048576L)
    if (!length(payload)) break
    writeBin(payload, roundtrip_output, useBytes = TRUE)
  }
  close(gzip_input)
  close(roundtrip_output)
  roundtrip_bytes <- unname(file.info(roundtrip_path)$size)
  roundtrip_sha256 <- digest::digest(
    file = roundtrip_path,
    algo = "sha256",
    serialize = FALSE
  )
  if (!identical(as.numeric(roundtrip_bytes), as.numeric(canonical_bytes)) ||
      !identical(roundtrip_sha256, canonical_sha256)) {
    stop("The gzip artifact failed its canonical round-trip check.", call. = FALSE)
  }

  artifact_bytes <- unname(file.info(staged_output)$size)
  artifact_sha256 <- digest::digest(
    file = staged_output,
    algo = "sha256",
    serialize = FALSE
  )
  stringi_build <- stringi::stri_info()
  manifest <- list(
    schema_version = "0.2.0-experiment",
    status = "direct-source-r-build-candidate-not-production",
    id = "tubelex-en-treebank-7cb5fb36-slim-r-direct-v1",
    source = c(
      source_contract,
      list(
        local_path_recorded = FALSE,
        bundled_in_output = FALSE,
        decompressed_bytes = decompressed_bytes,
        verified_before_parsing = TRUE
      )
    ),
    reviewed_reference = list(
      id = "tubelex-en-treebank-7cb5fb36-frequency-index",
      role = paste(
        "audit-only reviewed 19-column artifact; not used as a build input",
        "and not bundled in the release unit"
      ),
      bytes = 4572297,
      sha256 = "3731f23f3385ed630777ff56b5edbed5db46eee256ededceb0ac213016f31675",
      used_as_build_input = FALSE,
      local_path_recorded = FALSE,
      projection_measurement = NULL,
      projection_measurement_retained = FALSE,
      retained_set_equivalence_measurement =
        "experiments/tubelex-source-build/measurement.json",
      set_equivalence_audit = "experiments/tubelex-source-build/audit-unicode-filter.R",
      retained_set_result = "R-only 0; reviewed-reference-only 0",
      expected_projection_canonical_sha256 = expected_canonical_sha256
    ),
    artifact = list(
      file = basename(output_path),
      format = "deterministic gzip-compressed UTF-8 CSV",
      bytes = artifact_bytes,
      sha256 = artifact_sha256,
      canonical_bytes = canonical_bytes,
      canonical_sha256 = canonical_sha256,
      canonical_identity_gate = "matched-reviewed-r-projection",
      columns = base_columns,
      word_rows = retained_rows,
      physical_rows_including_header_and_total = retained_rows + 2L,
      total_row = "[TOTAL]"
    ),
    validation = list(
      exact_header = TRUE,
      canonical_integers = TRUE,
      row_count = TRUE,
      unique_words = TRUE,
      channels_le_videos_le_count = TRUE,
      category_row_sums = TRUE,
      complete_declared_totals = TRUE,
      compressed_and_decompressed_hashes = TRUE,
      observed_max_decompressed_line_bytes = observed_max_line_bytes,
      utf8 = TRUE,
      line_and_size_limits = TRUE,
      gzip_roundtrip_to_canonical_hash = TRUE
    ),
    lookup_filter = list(
      method = paste(
        "NFKC + trim + Unicode lowercase equality; <=64 code points;",
        "optional leading ASCII apostrophe; Unicode Letter (L*) components",
        "separated by ASCII apostrophes or hyphens"
      ),
      r_engine = "stringi/ICU",
      regex = lookup_pattern,
      source_rows = source_word_rows,
      retained_rows = retained_rows,
      excluded_rows = source_word_rows - retained_rows,
      retained_token_mass = retained_count,
      retained_token_mass_ratio = retained_count / expected_totals[["count"]]
    ),
    totals = list(
      count = expected_totals[["count"]],
      videos = expected_totals[["videos"]],
      channels = expected_totals[["channels"]],
      source_vocabulary_size = source_word_rows
    ),
    formulas = list(
      zipf = "log10(1e9 * (count + 1) / (N + source_V))",
      video_prevalence = "log10((videos + 1) / (D_video + 2))",
      channel_prevalence = "log10((channels + 1) / (D_channel + 2))"
    ),
    transformation = list(
      builder = "experiments/tubelex-source-build/build-tubelex-from-source.R",
      network_access = FALSE,
      removed_columns = paste0("count:", categories),
      ordering = "ascending Unicode code-point order under C collation",
      line_endings = "LF",
      gzip_mtime = 0,
      compressed_hash_portability = paste(
        "not used as the cross-platform identity gate; zlib output may differ",
        "while canonical CSV bytes remain identical"
      )
    ),
    license = list(
      spdx = "BSD-3-Clause",
      copyright = "Copyright (c) 2022-4, Adam Nohejl",
      attribution_and_disclaimer_required = TRUE,
      raw_subtitles_or_identifiers_included = FALSE
    ),
    build_environment = list(
      r = R.version.string,
      platform = R.version$platform,
      zlib = unname(extSoftVersion()[["zlib"]]),
      r_linked_icu = unname(extSoftVersion()[["ICU"]]),
      stringi = as.character(utils::packageVersion("stringi")),
      stringi_icu = unname(stringi_build$ICU.version),
      stringi_unicode = unname(stringi_build$Unicode.version),
      stringi_icu_system = unname(stringi_build$ICU.system)
    )
  )

  jsonlite::write_json(
    manifest,
    staged_manifest,
    pretty = TRUE,
    auto_unbox = TRUE,
    null = "null",
    digits = NA
  )
  write("", file = staged_manifest, append = TRUE)

  if (!file.rename(staged_output, output_path)) {
    stop("Could not atomically promote the artifact.", call. = FALSE)
  }
  if (!file.rename(staged_manifest, manifest_path)) {
    unlink(output_path, force = TRUE)
    stop("Could not atomically promote the manifest.", call. = FALSE)
  }

  cat(sprintf(
    paste0(
      "Built %s directly from the pinned source: %d bytes, SHA-256 %s; ",
      "canonical CSV: %d bytes, SHA-256 %s.\n"
    ),
    basename(output_path),
    artifact_bytes,
    artifact_sha256,
    canonical_bytes,
    canonical_sha256
  ))
}

main()
