#!/usr/bin/env Rscript
# Select exact source rows for the installed demonstration, not a mini inventory.
# Usage: Rscript experiments/build-morphynet-example.R SOURCE_DIRECTORY [PACKAGE_ROOT]
args <- commandArgs(trailingOnly = TRUE)
if (!length(args) || length(args) > 2L) stop("Supply SOURCE_DIRECTORY [PACKAGE_ROOT].")
root <- if (length(args) == 2L) args[2L] else "."
path <- file.path(args[1L], "eng.derivational.v1.tsv")
sha <- "5920edacc1888b14464fc5cd96beea0a721221d56d1dc0e49de22f4c7c537c50"
stopifnot(digest::digest(file = path, algo = "sha256") == sha)
lines <- readLines(path, encoding = "UTF-8", warn = FALSE)
fields <- strsplit(lines, "\t", fixed = TRUE)
words <- c("teacher", "transmitter", "unhappiness", "reusability", "retransmit", "transmission")
selected <- which(vapply(fields, function(x) x[2L] %in% words, logical(1L)))
stopifnot(identical(selected, c(2221L, 6727L, 10258L, 23050L, 33010L,
  206630L, 207429L, 210120L, 221115L)))
output <- file.path(root, "inst", "extdata", "morphynet-example")
dir.create(output, recursive = TRUE, showWarnings = FALSE)
writeLines(lines[selected], file.path(output, "eng.derivational.example.tsv"), useBytes = TRUE)
utils::write.csv(data.frame(example_line = seq_along(selected), original_line = selected,
  original_sha256 = sha), file.path(output, "source-rows.csv"), row.names = FALSE)
license <- file.path(args[1L], "CC-BY-SA-3.0.txt")
stopifnot(digest::digest(file = license, algo = "sha256") ==
  "3f941b3b89cf7b8370ceb83cc76d2120d471b58735d8ca60238a751a48d7f72f")
notice <- file.path(root, "inst", "licenses", "morphynet")
dir.create(notice, recursive = TRUE, showWarnings = FALSE)
stopifnot(file.copy(license, notice, overwrite = TRUE))
cat("Nine unchanged relation rows selected with original source line mapping.\n")
