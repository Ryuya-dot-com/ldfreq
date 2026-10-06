#!/usr/bin/env Rscript
# Build from the official, already obtained archive; never run its software.
# Usage: Rscript experiments/build-bnccoca.R SOURCE_DIRECTORY [PACKAGE_ROOT]
args <- commandArgs(trailingOnly = TRUE)
if (!length(args) || length(args) > 2L) stop("Supply SOURCE_DIRECTORY [PACKAGE_ROOT].")
root <- if (length(args) == 2L) args[2L] else "."
source_dir <- args[1L]
archive <- file.path(source_dir, "BNC_COCA_25000.zip")
archive_sha <- "ac81c7a60e5c76cd2bbf0c59b0501808f0d4fa026b2936919dd54329a9bb6a69"
stopifnot(digest::digest(file = archive, algo = "sha256") == archive_sha)
unpacked <- tempfile()
dir.create(unpacked)
files <- paste0("basewrd", 1:34, ".txt")
utils::unzip(archive, files = files, exdir = unpacked)
kind <- c(rep("frequency", 25L), rep("placeholder", 5L),
  "proper_names", "marginal_words", "transparent_compounds", "acronyms")
tables <- lapply(seq_along(files), function(i) {
  raw <- readLines(file.path(unpacked, files[i]), encoding = "UTF-8", warn = FALSE)
  line <- which(nzchar(raw))
  raw <- raw[line]
  stopifnot(all(grepl("^\t?[^ \t]+ 0$", raw)))
  head <- !startsWith(raw, "\t")
  stopifnot(head[1L])
  form <- sub(" 0$", "", sub("^\t", "", raw))
  head_row <- which(head)[cumsum(head)]
  id <- sprintf("bnccoca:%02d:%05d", i, line)
  data.frame(record_id = id, form = form, family_id = id[head_row],
    headword = form[head_row], frequency_band = if (i <= 25L) i else NA_integer_,
    list_type = kind[i], source_file = files[i], source_line = line,
    is_headword = head, range_flag = "0", stringsAsFactors = FALSE)
})
catalog <- data.frame(source_file = files, list_type = kind,
  rows = vapply(tables, nrow, integer(1L)),
  families = vapply(tables, function(x) sum(x$is_headword), integer(1L)),
  included = kind != "placeholder",
  sha256 = unname(vapply(file.path(unpacked, files), function(p)
    digest::digest(file = p, algo = "sha256"), character(1L))))
dictionary <- do.call(rbind, tables[1:25])
supplementary <- do.call(rbind, tables[31:34])
rownames(dictionary) <- rownames(supplementary) <- NULL
stopifnot(nrow(dictionary) == 75679L, sum(dictionary$is_headword) == 25000L,
  !anyDuplicated(dictionary$form), nrow(supplementary) == 29798L)
resource <- list(resource_id = "BNC-COCA-Level-6",
  resource_version = paste0("1.0.0; sha256:", archive_sha), language = "en",
  source_reference = paste("Nation, I. S. P. (2017). The BNC/COCA Level 6 word family lists",
    "(Version 1.0.0) [Data file]. Victoria University of Wellington."),
  data_license = "CC BY-SA 4.0",
  license_url = "https://creativecommons.org/licenses/by-sa/4.0/",
  source_url = "https://www.wgtn.ac.nz/lals/resources/paul-nations-resources/vocabulary-analysis-programs",
  family_definition = paste("Source headword/member grouping in basewrd1-25;",
    "Bauer-Nation Level 6 inclusion criteria; 25 frequency/range bands.",
    "No POS or sense disambiguation; supplementary lists excluded."),
  lookup_unit = "surface")
provenance <- list(source_file = basename(archive), source_sha256 = archive_sha,
  source_url = paste0(resource$source_url, "/range/BNC_COCA_25000.zip"),
  terms_url = "https://www.wgtn.ac.nz/lals/resources/paul-nations-resources",
  information_url = paste0("https://www.wgtn.ac.nz/__data/assets/pdf_file/0004/1689349/",
    "Information-on-the-BNC_COCA-word-family-lists-20180705.pdf"),
  retrieved = "2026-10-06", transformation_id = "range-members-v1",
  transformation = paste("UTF-8 source spelling and order retained; tab indentation identifies members.",
    "An initial UTF-8 BOM, where present, is consumed as an encoding marker.",
    "IDs derive from list number and original line number; headwords are also records.",
    "Terminal Range field 0 retained as range_flag, not frequency.",
    "basewrd1-25 form dictionary; basewrd31-34 remain a separate supplementary table.",
    "Five placeholder rows in basewrd26-30, software and Range configuration excluded.",
    "No lowercasing, inferred members, POS tags, affix labels or corrected spellings."))
output <- file.path(root, "inst", "extdata", "bnccoca", "ac81c7a6")
dir.create(output, recursive = TRUE, showWarnings = FALSE)
saveRDS(list(dictionary = dictionary, supplementary = supplementary, catalog = catalog,
  resource = resource, provenance = provenance), file.path(output, "bnccoca.rds"),
  compress = "xz", version = 2L)
notice <- file.path(root, "inst", "licenses", "bnccoca")
dir.create(notice, recursive = TRUE, showWarnings = FALSE)
stopifnot(digest::digest(file = file.path(source_dir, "CC-BY-SA-4.0.txt"), algo = "sha256") ==
  "28a9529c7d0bb4dc51f4bf5c116a3d16ef247a052f7591466768ddf563fd1cf5")
stopifnot(file.copy(file.path(source_dir, "CC-BY-SA-4.0.txt"), notice, overwrite = TRUE))
unlink(unpacked, recursive = TRUE)
print(catalog[c("source_file", "rows", "families", "included")], row.names = FALSE)
cat("RDS bytes:", file.info(file.path(output, "bnccoca.rds"))$size, "\n")
