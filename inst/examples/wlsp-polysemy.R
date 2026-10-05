# Source explicitly; no downloads, file writes or external ratings are bundled.
# See vignette("japanese-norms") for acquisition, reviewed keys and interpretation.
# The source WID is not a WLSP-familiarity record_id or a number of senses.
read_wlsp_polysemy <- function(path) {
  if (!is.character(path) || length(path) != 1L || is.na(path) ||
      !file.exists(path) || dir.exists(path)) stop("path must name a local polysemous.txt file.")
  if (!requireNamespace("digest", quietly = TRUE)) stop("Install package: digest")
  hash <- digest::digest(file = path, algo = "sha256")
  if (!identical(hash, "03ad0e12686c4cc015e52428a81ca53377681d87988a23ee8d4dcf116feca43b"))
    stop("File differs from inspected WLSP-norms v1.0 polysemous.txt; review its version first.")
  # Decode UTF-8 fields without conversion to the native character locale.
  norms <- utils::read.delim(path, encoding = "UTF-8", quote = "", comment.char = "",
    colClasses = c(rep("character", 4L), "numeric"), check.names = FALSE)
  stopifnot(identical(names(norms), c("WID", "WORD", "LABEL", "FACTOR", "VALUE")),
    nrow(norms) == 100827L, !anyNA(norms), !anyDuplicated(norms$WID),
    all(norms$FACTOR == "POLYSEMOUS"), all(is.finite(norms$VALUE)))
  revision <- "72125c8dc538aeb70b07cb1c76c183e338f0cde9"
  resource <- list(resource_id = "WLSP_norms_polysemy",
    resource_version = paste0("1.0-", revision),
    creator = "National Institute for Japanese Language and Linguistics (2025); Masayuki Asahara",
    source_reference = paste0("https://github.com/masayu-a/WLSP-norms/tree/", revision,
      "; https://doi.org/10.51094/jxiv.2164"),
    data_license = "CC BY-NC-SA 3.0", transformation_id = "published_VALUE_no_rescaling",
    lookup_unit = "source_WID_with_WORD_and_LABEL",
    resource_key_normalization_id = "identity-valid-utf8-v1")
  specs <- data.frame(measure_id = "polysemy", value_column = "VALUE",
    construct_id = "subjective_polysemousness", value_unit = "published_normalized_model_estimate",
    direction = "descriptive", language = "Japanese", variety = "unspecified",
    population_id = "Japanese_native_speakers_crowdsourced", collection_year = "2025",
    valid_min = NA_real_, valid_max = NA_real_)
  list(data = norms, measure_specs = specs, resource = resource,
    source = list(sha256 = hash, file = "polysemous.txt",
      source_url = paste0("https://raw.githubusercontent.com/masayu-a/WLSP-norms/",
        revision, "/polysemous.txt"),
      limitation = paste("VALUE is the released normalized estimate, not a raw 0-5 rating,",
        "sense count, uncertainty interval or contextual sense frequency.",
        "The inspected documentation does not establish its exact normalization transform.",
        "WID, WORD and LABEL are retained; no cross-resource ID equivalence is inferred.")))
}

# items: item_id, term, norm_word (exact source WORD, or NA), mapping_reason.
# decisions: item_id, wid (source WID as character), reason. No automatic choice.
review_wlsp_polysemy_items <- function(items, path, decisions = NULL) {
  required <- c("item_id", "term", "norm_word", "mapping_reason")
  if (!is.data.frame(items) || anyNA(names(items)) || anyDuplicated(names(items)) ||
      !all(required %in% names(items))) stop("items requires item_id, term, norm_word and mapping_reason.")
  for (field in required) {
    x <- items[[field]]
    if (!is.character(x) || !is.null(attributes(x)) || (field != "norm_word" && anyNA(x)) ||
        any(!nzchar(stringi::stri_trim_both(x[!is.na(x)]))) ||
        any(!validUTF8(x[!is.na(x)])) || any(Encoding(x) %in% c("bytes", "latin1")))
      stop(field, " must contain plain non-empty UTF-8 strings (NA only for norm_word).")
  }
  if (anyDuplicated(items$item_id)) stop("item_id must be unique.")
  fields <- c("candidate_count", "status", "reason", "wid", "word", "label", "value")
  if (any(paste0("polysemy_", fields) %in% names(items)))
    stop("items already contains polysemy output columns.")
  if (is.null(decisions))
    decisions <- data.frame(item_id = character(), wid = character(), reason = character())
  if (!is.data.frame(decisions) || anyNA(names(decisions)) || anyDuplicated(names(decisions)) ||
      !all(c("item_id", "wid", "reason") %in% names(decisions)))
    stop("decisions must contain item_id, wid and reason.")
  for (field in c("item_id", "wid", "reason")) {
    x <- decisions[[field]]
    if (!is.character(x) || !is.null(attributes(x)) || anyNA(x) ||
        any(!nzchar(stringi::stri_trim_both(x))) || any(!validUTF8(x)) ||
        any(Encoding(x) %in% c("bytes", "latin1")))
      stop("decisions$", field, " must contain plain non-empty UTF-8 strings.")
  }
  if (anyDuplicated(decisions$item_id) || any(!decisions$item_id %in% items$item_id))
    stop("Each decision must name a unique, existing item_id.")
  reference <- read_wlsp_polysemy(path)
  norms <- reference$data
  keys <- unique(norms$WORD)
  counts <- tabulate(match(norms$WORD, keys), nbins = length(keys))
  count <- counts[match(items$norm_word, keys)]
  count[is.na(count)] <- 0L
  if (sum(count) > 1e6) stop("More than one million candidate pairs; use fewer items.")
  candidates <- merge(items[c("item_id", "term", "norm_word")], norms,
    by.x = "norm_word", by.y = "WORD", sort = FALSE)
  candidates <- candidates[order(match(candidates$item_id, items$item_id),
    match(candidates$WID, norms$WID)), c("item_id", "term", "norm_word", "WID", "LABEL", "FACTOR", "VALUE")]
  rownames(candidates) <- NULL
  decision_item <- match(decisions$item_id, items$item_id)
  decision_record <- match(decisions$wid, norms$WID)
  if (anyNA(decision_record)) stop("A decision names an unknown source WID.")
  if (anyNA(items$norm_word[decision_item]) ||
      any(norms$WORD[decision_record] != items$norm_word[decision_item]))
    stop("Selected WID must be a candidate for that item's exact norm_word.")
  selected <- rep(NA_integer_, nrow(items)); selected[decision_item] <- decision_record
  out <- as.data.frame(items)
  out$polysemy_candidate_count <- count
  out$polysemy_status <- rep("unreviewed", nrow(items))
  out$polysemy_status[count == 0L] <- "unmatched"
  out$polysemy_status[is.na(items$norm_word)] <- "unresolved_key"
  out$polysemy_status[!is.na(selected)] <- "selected"
  out$polysemy_reason <- decisions$reason[match(items$item_id, decisions$item_id)]
  out[paste0("polysemy_", fields[4:7])] <- norms[selected, c("WID", "WORD", "LABEL", "VALUE"), drop = FALSE]
  profile <- ldfreq::lexdiv_norm_profile(out$polysemy_wid[!is.na(selected)], norms, "WID",
    reference$measure_specs, reference$resource)
  observed <- sum(!is.na(out$polysemy_value))
  n_selected <- sum(!is.na(selected))
  coverage <- data.frame(items = nrow(items), with_candidates = sum(count > 0L),
    selected = n_selected, with_value = observed,
    selection_coverage = if (nrow(items)) n_selected / nrow(items) else NA_real_,
    value_coverage = if (nrow(items)) observed / nrow(items) else NA_real_)
  list(items = out, candidates = candidates, decisions = as.data.frame(decisions),
    coverage = coverage, profile = profile, profile_item_ids = items$item_id[!is.na(selected)],
    source = c(list(resource = reference$resource, measure_specs = reference$measure_specs), reference$source))
}
