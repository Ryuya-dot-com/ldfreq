# Explicit local-file example; see vignette("japanese-norms").
# WLSP-familiarity v4.0: NINJAL (2024), Masayuki Asahara, CC BY-NC-SA 3.0.
# No external ratings are bundled, downloaded, or relicensed by this code.
# Review spelling candidates and supply an item_id/record_id/reason table.
# Neither a unique candidate nor a supplied reading is selected automatically.
review_wlsp_items <- function(items, path, decisions = NULL) {
  if (!is.data.frame(items) || anyNA(names(items)) || anyDuplicated(names(items)) ||
      !all(c("item_id", "term") %in% names(items))) {
    stop("items must be a data.frame with unique column names, item_id and term.")
  }
  for (field in c("item_id", "term")) {
    if (!is.character(items[[field]]) || anyNA(items[[field]]) ||
        any(!nzchar(items[[field]])) || any(!validUTF8(items[[field]])) ||
        any(Encoding(items[[field]]) == "bytes")) {
      stop(field, " must contain non-missing, non-empty UTF-8 strings.")
    }
  }
  if (anyDuplicated(items$item_id)) stop("item_id must be unique.")
  fields <- c("record_id", "record_type", "heading", "surface", "reading",
    "classification", "classification_label", "know", "write", "read", "speak", "listen")
  output_names <- paste0("wlsp_", c("candidate_count", "status", "reason", fields))
  if (any(output_names %in% names(items))) stop("items already contains WLSP output columns.")
  if (is.null(decisions)) {
    decisions <- data.frame(item_id = character(), record_id = character(), reason = character())
  }
  if (!is.data.frame(decisions) || anyNA(names(decisions)) || anyDuplicated(names(decisions)) ||
      !all(c("item_id", "record_id", "reason") %in% names(decisions))) {
    stop("decisions must contain item_id, record_id and reason columns.")
  }
  for (field in c("item_id", "record_id", "reason")) {
    if (!is.character(decisions[[field]]) || anyNA(decisions[[field]]) ||
        any(!nzchar(trimws(decisions[[field]])))) {
      stop("decisions$", field, " must contain non-empty character values.")
    }
  }
  if (anyDuplicated(decisions$item_id) || any(!decisions$item_id %in% items$item_id)) {
    stop("Each decision must name a unique, existing study item_id.")
  }
  if (!is.character(path) || length(path) != 1L || is.na(path) ||
      !file.exists(path) || dir.exists(path)) stop("path must name a local CSV file.")
  if (!requireNamespace("digest", quietly = TRUE)) stop("Install package: digest")
  hash <- digest::digest(file = path, algo = "sha256")
  if (!identical(hash, "76c33363a78fc72b6c659a96829e276dd3a9f699b65ce7e841774a0359e62dc5")) {
    stop("File differs from inspected WLSP-familiarity v4.0; review its version first.")
  }
  raw <- utils::read.csv(path, fileEncoding = "UTF-8", check.names = FALSE,
    colClasses = c(rep("character", 15L), rep("numeric", 11L)))
  norms <- raw[c(1, 3, 12, 13, 14, 8, 7, 16:20)]
  names(norms) <- fields
  stopifnot(!anyNA(norms$record_id), !anyDuplicated(norms$record_id))
  # Exact spelling only. Reading and contextual columns in items stay as
  # study metadata; do not infer a reading or discard other candidates.
  counts <- table(norms$surface)
  count <- as.integer(counts[match(items$term, names(counts))])
  count[is.na(count)] <- 0L
  if (sum(count) > 1e6) stop("More than one million candidate pairs; review a smaller item set.")
  candidates <- merge(items[c("item_id", "term")], norms,
    by.x = "term", by.y = "surface", sort = FALSE)
  candidates <- candidates[order(match(candidates$item_id, items$item_id),
    match(candidates$record_id, norms$record_id)), c("item_id", "term", setdiff(fields, "surface"))]
  rownames(candidates) <- NULL

  decision_item <- match(decisions$item_id, items$item_id)
  decision_record <- match(decisions$record_id, norms$record_id)
  if (anyNA(decision_record)) stop("A decision names an unknown WLSP record_id.")
  if (any(norms$surface[decision_record] != items$term[decision_item])) {
    stop("Selected record_id must be a spelling candidate for that study item.")
  }
  selected <- rep(NA_integer_, nrow(items))
  selected[decision_item] <- decision_record
  out <- as.data.frame(items)
  out$wlsp_candidate_count <- count
  out$wlsp_status <- ifelse(count == 0L, "unmatched", "unreviewed")
  out$wlsp_status[!is.na(selected)] <- "selected"
  out$wlsp_reason <- decisions$reason[match(items$item_id, decisions$item_id)]
  out[paste0("wlsp_", fields)] <- norms[selected, , drop = FALSE]
  # Selected means an explicit correspondence, not an observed value or a
  # validated sense-specific rating. Source NA values stay NA in every measure.
  list(items = out, candidates = candidates, decisions = as.data.frame(decisions),
    source = list(resource_id = "WLSP-familiarity", version = "4.0 (2024-06-30)",
      creator = "National Institute for Japanese Language and Linguistics; Masayuki Asahara",
      source_reference = paste0("https://github.com/masayu-a/WLSP-familiarity/tree/",
        "38af7500b9177cf7dc086bd0eabae1b7b3a66c8d"),
      publication = "https://doi.org/10.5715/jnlp.27.133",
      data_license = "CC BY-NC-SA 3.0", sha256 = hash,
      matching = "exact UTF-8 spelling; explicit item-to-record decisions",
      value_unit = "published Bayesian estimates, no rescaling",
      selection_validation = "ID and spelling consistency only; contextual validity requires review"))
}
