#!/usr/bin/env Rscript
# Reproduce the bundled rank/entry table from the supplied snapshot, checking
# every entry against JACET's official workbook. Never modify either input.
args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3L) stop("Usage: build-nj8.R NJ8.csv j8_2016.xlsx output.csv")
stopifnot(
  digest::digest(file = args[[1]], algo = "sha256") ==
    "1433dcd94135f86cfdbcbf5bafc209661678f1104f5062041b737834e99d3cf8",
  digest::digest(file = args[[2]], algo = "sha256") ==
    "6ff9e8e7f6893079c6a6ae4287f1fe69083374d2d9919fb4dc297aae086af1a7"
)
snapshot <- read.csv(args[[1]], fileEncoding = "UTF-8-BOM",
                     colClasses = c("integer", "character"), na.strings = character())
official <- suppressMessages(readxl::read_excel(
  args[[2]], sheet = "\u65b0J8", col_types = "text"
))[, 1:2]
names(official) <- c("NJ8", "Word")
official$NJ8 <- as.integer(official$NJ8)
stopifnot(nrow(snapshot) == 7999L, identical(official$NJ8, 1:8000),
          identical(setdiff(official$NJ8, snapshot$NJ8), 6926L))
snapshot$Word[snapshot$NJ8 == 326L] <- "true"
snapshot$Word[snapshot$NJ8 == 2382L] <- "false"
snapshot <- rbind(snapshot, data.frame(NJ8 = 6926L, Word = "nan"))
snapshot <- snapshot[order(snapshot$NJ8), ]
stopifnot(identical(snapshot$NJ8, official$NJ8),
          identical(snapshot$Word, official$Word))
write.csv(snapshot, args[[3]], row.names = FALSE, fileEncoding = "UTF-8", eol = "\n")
cat("Verified all 8,000 rank/entry pairs against the official workbook.\n")
cat("SHA-256:", digest::digest(file = args[[3]], algo = "sha256"), "\n")
