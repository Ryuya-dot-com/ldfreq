# Explicit local-file example, not an exported API. No downloads or file writes.
# See vignette("japanese-stimuli") for acquisition, attribution and key review.
# items: item_id, term, orth_base (NA if unresolved), base_reason.
profile_japanese_tubelex_items <- function(items, path) {
  required <- c("item_id", "term", "orth_base", "base_reason")
  if (!is.data.frame(items) || anyNA(names(items)) || anyDuplicated(names(items)) ||
      !all(required %in% names(items))) {
    stop("items must have unique column names and item_id, term, orth_base, base_reason.")
  }
  for (field in required) {
    x <- items[[field]]
    if (!is.character(x) || (field != "orth_base" && anyNA(x)) ||
        any(!nzchar(trimws(x[!is.na(x)]))) ||
        any(!validUTF8(x[!is.na(x)])) || any(Encoding(x) == "bytes")) {
      stop(field, " must contain non-empty UTF-8 strings (NA only for orth_base).")
    }
  }
  if (anyDuplicated(items$item_id)) stop("item_id must be unique.")
  fields <- c("lookup_term", "normalization_changed", "status", "count", "videos",
    "channels", "majority_pos", "per_million", "video_proportion", "channel_proportion")
  if (any(paste0("tubelex_", fields) %in% names(items))) {
    stop("items already contains TUBELEX output columns.")
  }
  if (!is.character(path) || length(path) != 1L || is.na(path) ||
      !file.exists(path) || dir.exists(path)) stop("path must name a local TSV.xz file.")
  for (pkg in c("ldfreq", "digest", "stringi")) {
    if (!requireNamespace(pkg, quietly = TRUE)) stop("Install package: ", pkg)
  }
  hash <- digest::digest(file = path, algo = "sha256")
  if (!identical(hash, "be1a66ac600d5e7efe6a301f63fba5321352742ae5dbaaa231529cdf2ab11710")) {
    stop("File differs from the inspected Japanese base table; review its version first.")
  }
  con <- xzfile(path, open = "rt", encoding = "UTF-8")
  on.exit(close(con), add = TRUE)
  raw <- utils::read.delim(con, quote = "", comment.char = "", check.names = FALSE,
    stringsAsFactors = FALSE, colClasses = c("character", rep("numeric", 3L),
      "character", rep("NULL", 15L)))
  stopifnot(identical(names(raw), c("word", "count", "videos", "channels", "pos")),
    !anyNA(raw$word), !anyDuplicated(raw$word), tail(raw$word, 1L) == "[TOTAL]")
  totals <- as.list(raw[nrow(raw), c("count", "videos", "channels")])
  norms <- raw[-nrow(raw), ]
  stopifnot(identical(unname(unlist(totals)), c(165932178, 100660, 30550)),
    sum(norms$count) == totals$count)
  norms$per_million <- norms$count / totals$count * 1e6
  norms$video_proportion <- norms$videos / totals$videos
  norms$channel_proportion <- norms$channels / totals$channels
  # Upstream aggregates NFKC/lowercase keys AFTER extracting orthBase.
  # This is lookup normalization, not raw-text tokenization or lemmatization.
  query <- stringi::stri_trans_tolower(stringi::stri_trans_nfkc(items$orth_base), locale = "en")
  if (any(query == "[total]", na.rm = TRUE)) stop("[TOTAL] is metadata, not a word.")
  queried <- which(!is.na(query))
  version <- "7cb5fb36add76b83a266d1967536e1a1d3faa513"
  metadata <- list(resource_id = "tubelex_ja_base", resource_version = version,
    creator = "Adam Nohejl et al. (2025)",
    source_reference = "https://aclanthology.org/2025.coling-main.641/",
    data_license = "BSD-3-Clause; upstream LICENSE at pinned commit",
    transformation_id = "counts_divided_by_published_totals_no_smoothing",
    lookup_unit = "UniDic_2.1.2_unidic-lite_1.0.8_orthBase",
    resource_key_normalization_id = "upstream-nfkc-then-lower")
  measures <- c("per_million", "video_proportion", "channel_proportion")
  specs <- data.frame(measure_id = measures, value_column = measures,
    construct_id = c("corpus_frequency", "video_range", "channel_range"),
    value_unit = c("occurrences_per_million_tokens", "proportion_of_videos", "proportion_of_channels"),
    direction = "descriptive", language = "Japanese", variety = "YouTube_subtitles",
    population_id = "TUBELEX_Japanese_reference_corpus", collection_year = "not_verified",
    valid_min = 0, valid_max = c(1e6, 1, 1))
  profile <- ldfreq::lexdiv_norm_profile(unname(query[queried]), norms, "word", specs, metadata)
  index <- match(query, norms$word)
  out <- as.data.frame(items)
  out$tubelex_lookup_term <- query
  out$tubelex_normalization_changed <- query != items$orth_base
  out$tubelex_status <- ifelse(is.na(query), "unresolved_base",
    ifelse(is.na(index), "unmatched", "matched"))
  out[paste0("tubelex_", fields[4:10])] <- norms[index,
    c("count", "videos", "channels", "pos", measures), drop = FALSE]
  list(items = out, profile = profile, profile_item_ids = items$item_id[queried],
    source = list(metadata = metadata, sha256 = hash, totals = totals,
      file = "tubelex-ja-base-pos.tsv.xz",
      source_url = paste0("https://raw.githubusercontent.com/naist-nlp/tubelex/", version,
        "/frequencies/tubelex-ja-base-pos.tsv.xz"),
      license_url = paste0("https://github.com/naist-nlp/tubelex/blob/", version, "/LICENSE"),
      query_normalization = "stringi NFKC then English-locale lowercase; no trim",
      stringi_version = as.character(utils::packageVersion("stringi")),
      unicode_version = stringi::stri_info()$Unicode.version,
      icu_version = stringi::stri_info()$ICU.version,
      limitation = paste("Caller-reviewed orthBase keys, not an upstream tokenizer replica.",
        "Majority POS is descriptive; counts are not reading-, sense- or POS-specific.",
        "Profile denominators omit unresolved bases; retain the full items table.")))
}
