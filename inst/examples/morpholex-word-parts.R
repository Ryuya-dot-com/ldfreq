# Adapter for bundled MorphoLex or a caller-obtained MorphoLEX_en.xlsx.
# Only an external workbook requires readxl. Read the resource's
# CC BY-NC-SA 4.0 conditions: https://github.com/hugomailhot/MorphoLex-en
# This bounded recipe reads explicitly selected PRS sheets and target words.
# It extracts recorded canonical parts, not actual substring spans or trees.
read_morpholex_parts <- function(path = NULL, sheets, words) {
  if (!is.character(sheets) || !length(sheets) || anyNA(sheets) || anyDuplicated(sheets) ||
      any(!grepl("^[0-9]+-[0-9]+-[0-9]+$", sheets))) stop("Select unique PRS sheet names explicitly.")
  if (!is.character(words) || !length(words) || anyNA(words) || any(!nzchar(words)))
    stop("words must be nonempty character forms.")
  bundled <- if (is.null(path)) ldfreq::morpholex_data(sheets) else NULL
  if (!is.null(path) && !requireNamespace("readxl", quietly = TRUE))
    stop("Install readxl to read the local workbook.")
  version <- if (is.null(path)) bundled$provenance$source_sha256 else
    digest::digest(file = path, algo = "sha256")
  fields <- c("ELP_ItemID", "Word", "Nmorph", "PRS_signature", "MorphoLexSegm")
  rows <- lapply(sheets, function(sheet) {
    x <- if (is.null(path)) bundled$sheets[[sheet]] else
      as.data.frame(readxl::read_excel(path, sheet = sheet, col_types = "text",
        trim_ws = FALSE, .name_repair = "unique_quiet"))
    if (!all(fields %in% names(x))) stop("Missing required MorphoLex columns in ", sheet)
    x <- x[x$Word %in% words, , drop = FALSE]
    x$source_sheet <- rep(sheet, nrow(x))
    x
  })
  # Preserve differently shaped original sheets without a lossy wide-table bind.
  selected <- lapply(rows, function(x) x[c(fields, "source_sheet")])
  x <- do.call(rbind, selected); rownames(x) <- NULL
  if (anyNA(x) || anyDuplicated(x$ELP_ItemID)) stop("Missing fields or duplicate ELP item IDs; review the workbook.")
  analyses <- data.frame(analysis_id = x$ELP_ItemID, form = x$Word,
    completeness = rep("unanalysed", nrow(x)), segmentation = x$MorphoLexSegm,
    source_sheet = x$source_sheet)
  parts <- data.frame(analysis_id = character(), part_index = integer(), part_id = character(),
    canonical = character(), role = character(), process = character(), boundness = character())
  pattern <- "<([^<>(){}]+)<|\\(([^<>(){}]+)\\)|>([^<>(){}]+)>"
  for (i in seq_len(nrow(x))) {
    seg <- x$MorphoLexSegm[i]
    m <- stringi::stri_match_all_regex(seg, pattern)[[1]]
    remainder <- stringi::stri_replace_all_regex(seg, pattern, "")
    braces <- strsplit(remainder, "", fixed = TRUE)[[1]]
    balanced <- !any(!braces %in% c("{", "}")) &&
      all(cumsum(ifelse(braces == "{", 1L, -1L)) >= 0) &&
      sum(braces == "{") == sum(braces == "}")
    if (!balanced || !nrow(m) || anyNA(m[, 1])) next
    column <- max.col(!is.na(m[, 2:4, drop = FALSE]), ties.method = "first")
    role <- c("prefix", "root", "suffix")[column]
    canonical <- m[cbind(seq_len(nrow(m)), column + 1L)]
    signature <- paste(sum(role == "prefix"), sum(role == "root"), sum(role == "suffix"), sep = ",")
    if (!identical(signature, x$PRS_signature[i]) ||
        !identical(as.character(nrow(m)), x$Nmorph[i]) || !any(role == "root")) next
    analyses$completeness[i] <- "complete"
    parts <- rbind(parts, data.frame(analysis_id = x$ELP_ItemID[i], part_index = seq_len(nrow(m)),
      part_id = paste(role, canonical, sep = ":"), canonical = canonical, role = role,
      process = ifelse(role == "root", "none", "derivation"),
      boundness = ifelse(role == "root", "unknown", "bound")))
  }
  list(analyses = analyses, parts = parts, source_rows = rows,
    requested_words = unique(words), unlisted_words = setdiff(words, x$Word),
    resource = list(resource_id = "MorphoLex-en", resource_version = version,
      language = "en", source_reference = "Sanchez-Gutierrez et al. (2018), doi:10.3758/s13428-017-0981-8; https://github.com/hugomailhot/MorphoLex-en",
      data_license = "CC BY-NC-SA 4.0", analysis_scope = "Reported derivational segmentation; inflection excluded",
      analysis_basis = "Canonical PREF/ROOT/SUFF atoms as recorded; root boundness unknown; no semantic or tree inference",
      selected_sheets = paste(sheets, collapse = "; ")))
}
