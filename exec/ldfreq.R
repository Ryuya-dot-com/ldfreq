#!/usr/bin/env Rscript
# Installed entry point; all measurement and serialization live in the package.
suppressPackageStartupMessages(library(ldfreq))
tryCatch({
  args <- commandArgs(trailingOnly = TRUE)
  if (identical(args, "--help") || !length(args)) {
    cat("Rscript ldfreq.R --init recipe.json\n",
      "Rscript ldfreq.R --recipe recipe.json --input folder --output new-folder [--recursive]\n",
      "Input: UTF-8 .txt files. Output: recipe.json, analysis.json, results.csv, methods-en.txt, methods-ja.txt.\n", sep = "")
  } else if (length(args) == 2L && args[[1L]] == "--init") {
    lexdiv_write(lexdiv_recipe(), args[[2L]])
  } else {
    recursive <- "--recursive" %in% args
    if (sum(args == "--recursive") > 1L) stop("Duplicate --recursive option.")
    args <- args[args != "--recursive"]
    if (length(args) != 6L || !setequal(args[c(1L, 3L, 5L)], c("--recipe", "--input", "--output")))
      stop("Use --recipe FILE --input FOLDER --output NEW-FOLDER [--recursive].")
    opts <- stats::setNames(args[c(2L, 4L, 6L)], args[c(1L, 3L, 5L)])
    input <- normalizePath(opts[["--input"]], mustWork = TRUE)
    output <- opts[["--output"]]
    if (!dir.exists(input)) stop("Input must be a directory.")
    if (file.exists(output)) stop("Output already exists: ", output)
    if (!dir.exists(dirname(output))) stop("Output parent directory does not exist.")
    paths <- sort(list.files(input, pattern = "[.]txt$", recursive = recursive,
      ignore.case = TRUE, full.names = FALSE), method = "radix")
    paths <- paths[!dir.exists(file.path(input, paths))]
    if (!length(paths)) stop("No .txt files found.")
    texts <- vapply(paths, function(path) {
      file <- file.path(input, path)
      bytes <- readBin(file, "raw", n = file.info(file)$size)
      if (any(bytes == as.raw(0))) stop("NUL byte in input: ", path)
      text <- rawToChar(bytes)
      if (!validUTF8(text)) stop("Input is not UTF-8: ", path)
      Encoding(text) <- "UTF-8"
      text
    }, character(1))
    record <- lexdiv_run_recipe(texts, lexdiv_read(opts[["--recipe"]]))
    stage <- tempfile("ldfreq-output-", tmpdir = dirname(output))
    if (!dir.create(stage)) stop("Cannot create output staging directory.")
    tryCatch({
      lexdiv_write(record$recipe, file.path(stage, "recipe.json"))
      lexdiv_write(record, file.path(stage, "analysis.json"))
      lexdiv_write(record, file.path(stage, "results.csv"), format = "csv")
      for (lang in c("en", "ja")) writeLines(enc2utf8(lexdiv_methods_text(record, lang)),
        file.path(stage, paste0("methods-", lang, ".txt")), useBytes = TRUE)
      if (file.exists(output) || !file.rename(stage, output)) stop("Cannot publish output directory.")
    }, finally = unlink(stage, recursive = TRUE))
    cat(normalizePath(file.path(output, "analysis.json")), "\n")
  }
}, error = function(e) {
  message(conditionMessage(e))
  quit(save = "no", status = 1L)
})
