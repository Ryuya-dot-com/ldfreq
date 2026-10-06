#!/usr/bin/env Rscript
# Rebuild the bundled snapshot from an already obtained upstream directory.
# Usage: Rscript experiments/build-morpholex.R SOURCE_DIRECTORY [PACKAGE_ROOT]
args <- commandArgs(trailingOnly = TRUE)
if (!length(args) || length(args) > 2L) stop("Supply SOURCE_DIRECTORY [PACKAGE_ROOT].")
root <- if (length(args) == 2L) args[2L] else "."
source_dir <- args[1L]
hashes <- c(
  "MorphoLEX_en.xlsx" = "5bc425fbb710f3d63cab69e77ee731fa466653ed0ace94937cac6c1fd6de52c6",
  "MorphoLEX_en-Data_Dictionary.pdf" = "af01e0db5e953ad3b7bbc06ea06b3c8a1af6dac60e7600d826a5e079e4068575",
  "LICENSE.md" = "051131b5ef3596dad9bf0cffee19c248ff9751596a86b25c70f0cd82d6f6d713")
for (name in names(hashes)) {
  actual <- digest::digest(file = file.path(source_dir, name), algo = "sha256")
  if (actual != hashes[[name]]) stop("Unexpected source hash: ", name)
}
path <- file.path(source_dir, "MorphoLEX_en.xlsx")
sheet_names <- readxl::excel_sheets(path)
sheets <- setNames(lapply(sheet_names, function(sheet) {
  as.data.frame(readxl::read_excel(path, sheet = sheet, col_types = "text",
    col_names = sheet != "Presentation", trim_ws = FALSE,
    .name_repair = "unique_quiet"))
}), sheet_names)
word_sheets <- sheets[grepl("^[0-9]+-[0-9]+-[0-9]+$", sheet_names)]
ids <- unlist(lapply(word_sheets, `[[`, "ELP_ItemID"), use.names = FALSE)
stopifnot(length(sheets) == 34L, length(ids) == 68624L, !anyNA(ids), !anyDuplicated(ids))
provenance <- list(
  resource_id = "MorphoLex-en", resource_version = unname(hashes[1L]),
  source_url = "https://github.com/hugomailhot/MorphoLex-en",
  source_file = "MorphoLEX_en.xlsx", source_sha256 = unname(hashes[1L]),
  source_reference = paste("Sanchez-Gutierrez, C. H., Mailhot, H., Deacon, S. H., & Wilson, M. A. (2018).",
    "MorphoLex: A derivational morphological database for 70,000 English words.",
    "Behavior Research Methods, 50, 1568-1580. doi:10.3758/s13428-017-0981-8"),
  data_license = "CC BY-NC-SA 4.0",
  license_url = "https://creativecommons.org/licenses/by-nc-sa/4.0/",
  data_dictionary_sha256 = unname(hashes[2L]),
  transformation_id = "all-sheet-character-values-v1",
  transformation = paste("All 34 sheets and their occupied cell regions; blank cells are NA.",
    "Character columns, no whitespace trimming. Presentation has generated column names;",
    "other sheets use their first row as headers. No formatting or formulas retained.",
    "Numeric/logical cells use R text representation; exterior blank margins omitted.",
    "No segmentation corrections, inferred parts, or word filtering."),
  readxl_version = as.character(utils::packageVersion("readxl")),
  sheet_catalog = data.frame(sheet = sheet_names,
    rows = unname(vapply(sheets, nrow, integer(1L))),
    columns = unname(vapply(sheets, ncol, integer(1L))),
    start_row = ifelse(sheet_names == "Presentation", 2L, 1L),
    start_column = ifelse(sheet_names == "Presentation", 3L,
      ifelse(sheet_names == "0-1-0", 4L, 1L))))
output <- file.path(root, "inst", "extdata", "morpholex", "5bc425fb")
notice <- file.path(root, "inst", "licenses", "morpholex")
dir.create(output, recursive = TRUE, showWarnings = FALSE)
dir.create(notice, recursive = TRUE, showWarnings = FALSE)
saveRDS(list(sheets = sheets, provenance = provenance),
  file.path(output, "morpholex_en.rds"), compress = "xz", version = 2L)
stopifnot(file.copy(file.path(source_dir, names(hashes)[2L]), output, overwrite = TRUE),
  file.copy(file.path(source_dir, "LICENSE.md"), file.path(notice, "CC-BY-NC-SA-4.0.md"), overwrite = TRUE))
print(provenance$sheet_catalog, row.names = FALSE)
cat("Word records:", length(ids), "\nRDS bytes:",
  file.info(file.path(output, "morpholex_en.rds"))$size, "\n")
