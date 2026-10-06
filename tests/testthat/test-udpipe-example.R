# Authored CoNLL-U for testing the boundary; no model or downloaded corpus.
udpipe_recipe_fixture <- function() {
  skip_if_not_installed("udpipe", "0.8.16")
  e <- new.env(parent = baseenv())
  sys.source(system.file("examples", "udpipe-amod.R", package = "ldfreq", mustWork = TRUE), e)
  segments <- data.frame(document_id = c("doc", "doc", "empty"),
    segment_id = c("s1", "s2", "s1"), parser_id = c("p1", "p2", "p3"),
    text = c(" A naïve bird flies. ", "NA _", "\t "))
  conllu <- paste(c("# newdoc id = p1", "# sent_id = 1", "# text = A naïve bird flies.",
    "1\tA\ta\tDET\tDT\t_\t3\tdet\t_\t_",
    "2\tnaïve\tnaïve\tADJ\tJJ\t_\t3\tamod\t_\t_",
    "3\tbird\tbird\tNOUN\tNN\t_\t4\tnsubj\t_\t_",
    "4\tflies\tfly\tVERB\tVBZ\t_\t0\troot\t_\tSpaceAfter=No",
    "5\t.\t.\tPUNCT\t.\t_\t4\tpunct\t_\t_", "",
    "# newdoc id = p2", "# sent_id = 1", "# text = NA _",
    "1\tNA\tNA\tNOUN\tNN\t_\t0\troot\t_\t_",
    "2\t_\t_\tPUNCT\t_\t_\t1\tpunct\t_\t_", ""), collapse = "\n")
  list(import = e$import_udpipe_sentences,
    annotation = structure(list(x = segments$text, conllu = conllu, errors = rep("", 3)),
      class = "udpipe_connlu"), segments = segments,
    provenance = list(language = "en", analyzer = "udpipe", analyzer_version = "authored-fixture",
      dictionary = "none", dictionary_version = "none", unit = "syntactic-word", normalization = "none",
      model = "none-authored-fixture", model_sha256 = "not-applicable-authored", model_source = "authored",
      model_license = "package-license", tokenizer = "not-run", tagger = "not-run", parser = "not-run"))
}

test_that("saved UDPipe output retains IDs, Unicode source and complete rosters", {
  f <- udpipe_recipe_fixture()
  x <- f$import(f$annotation, f$segments, f$provenance)
  expect_identical(x$segments$text, f$segments$text)
  expect_identical(x$tokens$start, c(2L, 4L, 10L, 15L, 20L, 1L, 4L))
  expect_identical(x$tokens$surface[6:7], c("NA", "_"))
  expect_identical(x$tokens$lemma[6:7], c("NA", NA_character_))
  expect_identical(x$segments$token_count, c(5L, 2L, 0L))
  expect_identical(x$tokens$parser_id, c(rep("p1", 5), "p2", "p2"))
  y <- lexdiv_amod_pairs(x, unit = "lemma")
  expect_identical(y$documents$pairs, c(1L, 0L))
  expect_identical(y$documents$status, c("complete", "empty"))
  expect_identical(y$occurrences$dependent_term, "naïve")
  expect_identical(y$occurrences$head_term, "bird")
  path <- tempfile(); on.exit(unlink(path))
  saveRDS(list(raw = f$annotation, segments = f$segments, provenance = f$provenance), path)
  saved <- readRDS(path)
  expect_identical(f$import(saved$raw, saved$segments, saved$provenance), x)
})

test_that("failure, changed source and unsupported UD structures are explicit", {
  f <- udpipe_recipe_fixture()
  a <- f$annotation; a$errors[3] <- "failed"
  expect_error(f$import(a, f$segments, f$provenance), "p3")
  a <- f$annotation; a$errors <- NULL
  expect_error(f$import(a, f$segments, f$provenance), "complete")
  s <- f$segments; s$text[1] <- trimws(s$text[1])
  expect_error(f$import(f$annotation, s, f$provenance), "ordered source")
  s <- f$segments; s$parser_id[2] <- "p1"
  expect_error(f$import(f$annotation, s, f$provenance), "unique")
  s <- f$segments; s$parser_id[2] <- "p2\n# newdoc"
  expect_error(f$import(f$annotation, s, f$provenance), "parser_id")
  a <- f$annotation; a$conllu <- sub("newdoc id = p1", "newdoc id = other", a$conllu, fixed = TRUE)
  expect_error(f$import(a, f$segments, f$provenance), "Parser IDs")
  a <- f$annotation; a$conllu <- sub("5\t.\t", "\n# sent_id = 2\n5\t.\t", a$conllu, fixed = TRUE)
  expect_error(f$import(a, f$segments, f$provenance), "multiple sentences")
  for (id in c("1-2", "1.1")) {
    a <- f$annotation; a$conllu <- sub("1\tA\t", paste0(id, "\tA\t"), a$conllu, fixed = TRUE)
    expect_error(f$import(a, f$segments, f$provenance), "Multiword-token")
  }
  a <- f$annotation; a$conllu <- sub("amod\t_\t_", "amod\t3:amod\t_", a$conllu, fixed = TRUE)
  expect_error(f$import(a, f$segments, f$provenance), "Enhanced")
  a <- f$annotation; a$conllu <- sub("3\tamod", "3.0\tamod", a$conllu, fixed = TRUE)
  expect_error(f$import(a, f$segments, f$provenance), "Head IDs")
  a <- f$annotation; a$conllu <- sub("2\tnaïve\t", "2\tnaive\t", a$conllu, fixed = TRUE)
  expect_error(f$import(a, f$segments, f$provenance), "align")
  a <- f$annotation; a$conllu <- sub("5\t.\t", "6\t.\t", a$conllu, fixed = TRUE)
  expect_error(f$import(a, f$segments, f$provenance), "consecutive")
  p <- f$provenance; p$model_sha256 <- NULL
  expect_error(f$import(f$annotation, f$segments, p), "model identity")
})

test_that("missing labels stay missing and zero-output inputs must be blank", {
  f <- udpipe_recipe_fixture()
  a <- f$annotation; a$conllu <- sub("3\tamod", "_\tamod", a$conllu, fixed = TRUE)
  y <- lexdiv_amod_pairs(f$import(a, f$segments, f$provenance))
  expect_true(is.na(y$documents$pairs[1]))
  expect_identical(y$documents$status[1], "incomplete_annotation")
  a <- f$annotation; a$conllu <- ""
  expect_error(f$import(a, f$segments, f$provenance), "Unannotated")
  s <- f$segments[3, ]; a$x <- s$text; a$errors <- ""
  x <- f$import(a, s, f$provenance)
  expect_equal(nrow(x$tokens), 0L)
  expect_identical(x$documents$document_id, "empty")
  expect_identical(lexdiv_amod_pairs(x)$documents$status, "empty")
})
