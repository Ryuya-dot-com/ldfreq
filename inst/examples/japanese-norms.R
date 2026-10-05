# Source this example explicitly; it neither downloads data nor writes files.
# See vignette("japanese-norms", package = "ldfreq") for acquisition, licenses,
# scale interpretation and item selection. This is an example, not an export.
profile_japanese_norm_items <- function(items, path, resource = c("aoa", "boi")) {
  resource <- match.arg(resource)
  if (!is.data.frame(items) || anyDuplicated(names(items)) ||
      !all(c("item_id", "term") %in% names(items))) {
    stop("items must be a data.frame with unique column names, item_id and term.")
  }
  if (!is.character(items$item_id) || anyNA(items$item_id) ||
      any(!nzchar(items$item_id)) || anyDuplicated(items$item_id)) {
    stop("item_id must contain unique, non-missing, non-empty character IDs.")
  }
  if (!is.character(items$term) || anyNA(items$term) || any(!nzchar(items$term))) {
    stop("term must contain non-missing, non-empty character lookup forms.")
  }
  output_names <- c("norm_source_id", "norm_part_of_speech", "norm_n",
    "norm_mean", "norm_sd", "norm_min", "norm_max",
    "norm_lookup_status", "norm_value_status")
  if (any(output_names %in% names(items))) {
    stop("items already contains norm output columns; supply the original item table.")
  }
  if (!is.character(path) || length(path) != 1L || is.na(path) ||
      !file.exists(path) || dir.exists(path)) stop("path must name a local CSV file.")
  for (pkg in c("ldfreq", "digest")) {
    if (!requireNamespace(pkg, quietly = TRUE)) stop("Install package: ", pkg)
  }
  if (resource == "aoa") {
    expected <- "1a92d900d9a02ca3fe7616a64e27f1aeffcf2fd9e2b3cf1722ff42640db7f4f5"
    suffix <- "AoA"
    doi <- "10.3389/flang.2025.1605224"
    project <- "https://osf.io/fawmq/"
    license <- "CC BY-NC 4.0"
    construct <- "retrospective_age_of_acquisition"
    unit <- "mean_of_seven_age_categories_including_unknown_at_7"
    limitation <- paste("Category 7 includes 12+ years and unknown AoA.",
      "These aggregate ratings are not ages in years or L2 acquisition ages.")
  } else {
    expected <- "09f005f373b2545a69f06a1c3ef0fd80f46898bc1dbf4a08f73ab1281156d4b3"
    suffix <- "BOI"
    doi <- "10.3758/s13428-025-02939-1"
    project <- "https://osf.io/gkjmc/"
    license <- "CC BY 4.0 (OSF project)"
    construct <- "body_object_interaction"
    unit <- "mean_of_seven_point_boi_ratings"
    limitation <- paste("CSV and analysis script: 5736 words; publication title:",
      "5637. Correspondence to the correction (10.3758/s13428-026-03000-5)",
      "has not been resolved. This example processes the pinned aggregate CSV.")
  }
  hash <- digest::digest(file = path, algo = "sha256")
  if (!identical(hash, expected)) {
    stop("File differs from the inspected OSF CSV; review its version before use.")
  }
  norms <- utils::read.csv(path, fileEncoding = "UTF-8", check.names = FALSE,
    stringsAsFactors = FALSE)
  metadata <- list(resource_id = paste0("japanese_", resource),
    resource_version = paste0("osf-file-v1-sha256-", hash),
    creator = "Masaya Mochizuki; Naoto Ota",
    source_reference = paste0("https://doi.org/", doi, "; ", project),
    data_license = license, transformation_id = "original_mean_no_rescaling",
    lookup_unit = "published_Word_spelling",
    resource_key_normalization_id = "identity-valid-utf8-v1")
  specs <- data.frame(measure_id = resource, value_column = paste0("mean", suffix),
    construct_id = construct, value_unit = unit, direction = "descriptive",
    language = "Japanese", variety = "unspecified",
    population_id = "Japanese_native_speaker_adults", collection_year = "not_verified",
    valid_min = 1, valid_max = 7)
  profile <- ldfreq::lexdiv_norm_profile(items$term, norms, "Word", specs, metadata)
  # The profile validates unique source keys. Match by spelling, not shared
  # source Item numbers; preserve the input order, repeated terms and all groups.
  columns <- c("Item", "PartOfSpeech", paste0(c("n", "mean", "sd", "min", "max"), suffix))
  matched <- norms[match(items$term, norms$Word), columns, drop = FALSE]
  out <- as.data.frame(items)
  out[output_names[1:7]] <- matched
  out$norm_lookup_status <- profile$lookup$lookup_status
  out$norm_value_status <- profile$lookup$value_status
  list(items = out, profile = profile,
    source = list(metadata = metadata, sha256 = hash, limitation = limitation))
}
