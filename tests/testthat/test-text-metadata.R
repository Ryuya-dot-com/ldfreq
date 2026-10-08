test_that("study metadata align by document ID without changing the analysis", {
  texts <- data.frame(essay = c("002", "001", "003"),
    response = c("a b a", "b c", ""), ignored = c(9, 8, 7))
  metadata <- data.frame(writer_id = c("writer-A", NA, "writer-A"),
    document_id = c("001", "003", "002"),
    task = factor(c("first", "second", "first")),
    occasion = c(1L, 2L, 1L), score = c(2.5, NA, 3.5),
    observed = c(TRUE, NA, FALSE), date = as.Date(c("2026-01-01", NA, "2026-02-01")),
    value = c(99, 98, 97), stringsAsFactors = FALSE)
  before <- serialize(list(texts, metadata), NULL)
  default <- lexdiv_metrics_text_batch(texts, id_col = "essay", text_col = "response",
    tokenizer = "english", metrics = c("ttr", "mtld"))
  expect_identical(default, lexdiv_metrics_text_batch(texts,
    id_col = "essay", text_col = "response", tokenizer = "english",
    metrics = c("ttr", "mtld"), metadata = NULL))
  result <- lexdiv_metrics_text_batch(texts, id_col = "essay", text_col = "response",
    tokenizer = "english", metrics = c("ttr", "mtld"), metadata = metadata)
  expect_identical(names(result), c(names(default), "metadata"))
  for (field in names(default)) expect_identical(result[[field]], default[[field]])
  expected <- metadata[c(3, 1, 2), c("document_id", setdiff(names(metadata), "document_id"))]
  rownames(expected) <- NULL
  expect_identical(result$metadata, expected)
  expect_false("ignored" %in% names(result$metadata))
  expect_identical(serialize(list(texts, metadata), NULL), before)
  expect_output(print(result), "3 documents; 7 study fields in \\$metadata")
  invisible(capture.output(returned <- withVisible(print(result))))
  expect_identical(returned$value, result)
  expect_false(returned$visible)
  expect_false(any(grepl("Metadata:", capture.output(print(default)), fixed = TRUE)))

  prepared <- lexdiv_tokenize_batch(texts, id_col = "essay", text_col = "response",
    tokenizer = "english")
  expect_identical(lexdiv_metrics_text_batch(prepared, metrics = c("ttr", "mtld"),
    metadata = metadata), result)
  named <- stats::setNames(texts$response, texts$essay)
  expect_identical(lexdiv_metrics_text_batch(named, tokenizer = "english",
    metrics = c("ttr", "mtld"), metadata = metadata), result)
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path))
  saveRDS(result, path)
  expect_identical(readRDS(path), result)
})

test_that("metadata validation rejects ambiguous rosters and non-scalar columns", {
  texts <- c("001" = "a a", "002" = "b")
  metadata <- data.frame(document_id = c("001", "002"), writer = c("same", "same"))
  run <- function(m) lexdiv_metrics_text_batch(texts, metrics = "ttr", metadata = m)
  expect_error(run(list(document_id = names(texts))), "data frame")
  expect_error(run(metadata["writer"]), "including document_id")
  expect_error(run(metadata[c(1, 1), ]), "unique")
  expect_error(run(metadata[1, , drop = FALSE]), "1 missing ID\\(s\\), 0 extra")
  extra <- rbind(metadata, data.frame(document_id = "003", writer = "same"))
  expect_error(run(extra), "0 missing ID\\(s\\), 1 extra")
  expect_error(run(extra[c(2, 3), ]), "1 missing ID\\(s\\), 1 extra")
  for (ids in list(c(1L, 2L), factor(c("001", "002")), c(NA, "002"), c("", "002"))) {
    bad <- metadata; bad$document_id <- ids
    expect_error(run(bad), "document IDs")
  }
  for (columns in list(c("document_id", "document_id"), c("document_id", ""),
                       c("document_id", NA_character_))) {
    bad <- metadata; names(bad) <- columns
    expect_error(run(bad), "column names")
  }
  bad <- metadata; bad$nested <- I(list("a", c("b", "c")))
  expect_error(run(bad), "atomic value")
  bad$nested <- NULL; bad$matrix <- I(matrix(1:4, nrow = 2))
  expect_error(run(bad), "atomic value")
  reordered <- run(metadata[2:1, ])
  expect_identical(reordered$metadata$document_id, names(texts))
  expect_identical(reordered$metadata$writer, c("same", "same"))
})

test_that("zero documents retain declared metadata types and validation", {
  texts <- stats::setNames(character(), character())
  metadata <- data.frame(document_id = character(), task = factor(levels = c("A", "B")),
    occasion = integer(), date = as.Date(character()))
  result <- lexdiv_metrics_text_batch(texts, metrics = "ttr", metadata = metadata)
  expect_identical(result$metadata, metadata)
  expect_equal(nrow(result$results), 0)
  expect_output(print(result), "0 documents; 3 study fields")
  expect_error(lexdiv_metrics_text_batch(texts, metrics = "ttr",
    metadata = data.frame(document_id = "extra")), "1 extra")
  expect_error(lexdiv_metrics_text_batch(texts, metrics = "ttr",
    metadata = data.frame(id = character())), "including document_id")
})

test_that("UTF-8 metadata IDs match without changing labels or token selections", {
  id <- "\u4f5c\u658701"
  unknown_id <- id; Encoding(unknown_id) <- "unknown"
  prepared <- lexdiv_lemmatize(lexdiv_tokenize("Cats and cats run", tokenizer = "english"),
    lemmas = c("cat", "and", "cat", NA_character_),
    upos = c("NOUN", "CCONJ", "NOUN", "VERB"),
    backend_id = "test", backend_version = "1", upos_backend_id = "test", upos_backend_version = "1")
  empty <- lexdiv_lemmatize(lexdiv_tokenize(""), lemmas = character(), upos = character(),
    backend_id = "test", backend_version = "1")
  inputs <- stats::setNames(list(prepared, empty), c(id, "empty"))
  metadata <- data.frame(document_id = c("empty", unknown_id),
    writer = c(NA_character_, "\u8457\u8005A"), stringsAsFactors = FALSE)
  before <- serialize(metadata, NULL)
  result <- lexdiv_metrics_text_batch(inputs, unit = "lemma", word_inclusion = "content",
    metrics = "ttr", metadata = metadata)
  expect_identical(result$metadata$document_id, c(id, "empty"))
  expect_identical(result$metadata$writer, c("\u8457\u8005A", NA_character_))
  expect_identical(result$results$N, c(2, 0))
  expect_equal(result$results$value, c(.5, NA))
  expect_identical(serialize(metadata, NULL), before)
  metadata$document_id <- c(id, unknown_id)
  expect_error(lexdiv_metrics_text_batch(inputs, metrics = "ttr", metadata = metadata), "unique")
})
