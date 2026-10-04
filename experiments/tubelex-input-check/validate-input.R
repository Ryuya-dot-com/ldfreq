#!/usr/bin/env Rscript
# Optional developer verification; requires Python with NLTK and English Punkt.
# R package users and ordinary package checks have no Python dependency.
pkgload::load_all('.', quiet = TRUE)
script <- normalizePath('inst/examples/tubelex-tokenize.py')
work <- tempfile('tubelex-input-')
dir.create(work)
texts <- list(
  first = "I don't think it's John's book.",
  second = "I don’t think it’s John’s book. She bought 12 books.",
  empty = "... !!!"
)
source <- file.path(work, 'texts.json')
output <- file.path(work, 'tokens.json')
jsonlite::write_json(texts, source, auto_unbox = TRUE)
stopifnot(system2('python3', c('-B', '-m', 'doctest', shQuote(script))) == 0L)
stopifnot(system2('python3', shQuote(c(script, source, output))) == 0L)
prepared <- jsonlite::read_json(output, simplifyVector = TRUE)
prepared$documents <- lapply(prepared$documents, function(x) {
  as.character(unlist(x, use.names = FALSE))
})
first <- c('i', 'do', "n't", 'think', 'it', "'s", 'john', "'s", 'book')
stopifnot(
  identical(prepared$documents$first, first),
  identical(prepared$documents$second, c(first, 'she', 'bought', '<num>', 'books')),
  identical(prepared$documents$empty, character()),
  identical(prepared$preprocessing$source_texts_sha256,
            digest::digest(file = source, algo = 'sha256')),
  identical(prepared$preprocessing$script_sha256,
            digest::digest(file = script, algo = 'sha256')),
  length(prepared$preprocessing$punkt_english_files_sha256) == 4L
)
profiles <- tubelex_profile_batch(prepared$documents, normalization = 'identity')
stopifnot(
  identical(names(profiles), names(texts)),
  identical(profiles$first$lookup, tubelex_profile(first, normalization = 'identity')$lookup),
  !profiles$second$lookup$matched[profiles$second$lookup$term == '<num>'],
  identical(profiles$empty$status, 'empty')
)
saved <- file.path(work, 'analysis.rds')
record <- list(profiles = profiles, preprocessing = prepared$preprocessing)
saveRDS(record, saved)
stopifnot(identical(readRDS(saved), record))
# Reject accidental overwrite and duplicate IDs instead of losing input.
stopifnot(system2('python3', shQuote(c(script, source, output)),
                 stdout = FALSE, stderr = FALSE) != 0L)
writeLines('{"same":"one", "same":"two"}', source)
unlink(output)
stopifnot(system2('python3', shQuote(c(script, source, output)),
                 stdout = FALSE, stderr = FALSE) != 0L,
          !file.exists(output))
cat('TUBELEX input recipe: source-rule doctests, two expected token sequences,\n',
    'empty input, provenance hashes, R profiles, save/read, overwrite and\n',
    'duplicate-ID rejection all passed.\n', sep = '')
cat('NLTK:', prepared$preprocessing$nltk_version,
    'Python:', prepared$preprocessing$python_version, '\n')
unlink(work, recursive = TRUE)
