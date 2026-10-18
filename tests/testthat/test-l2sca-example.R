l2sca_example <- function() {
  e <- new.env(parent = globalenv())
  sys.source(system.file("examples", "l2sca-demo.R", package = "ldfreq", mustWork = TRUE), e)
  e
}

test_that("declared structures retain counts, overlapping matches and zero policies", {
  e <- l2sca_example(); x <- e$analysis
  expect_equal(x$components$W, c(5, 4, 5, 5, 4, 4, 3, 6, 6, 0, NA))
  expect_equal(x$components$C, c(2, 1, 2, 1, 1, 0, 1, 2, 1, 0, NA))
  expect_equal(x$components$T, c(2, 1, 1, 1, 1, 0, 1, 1, 1, 0, NA))
  expect_equal(x$components$DC, c(0, 0, 1, 0, 0, 0, 0, 1, 0, 0, NA))
  expect_equal(subset(x$results, measure == "MLT")$value,
    c(2.5, 4, 5, 5, 4, NA, 3, 6, 6, NA, NA))
  expect_equal(subset(x$results, measure == "DC_C")$value,
    c(0, 0, .5, 0, 0, NA, 0, .5, 0, NA, NA))
  expect_equal(subset(x$results, document_id == "manual_fragment_NP")$original_rule_value, c(0, 0, 0))
  expect_true(all(subset(x$results, document_id == "manual_fragment_NP")$status == "zero_denominator"))
  expect_true(all(is.na(subset(x$results, document_id == "failed")$original_rule_value)))
  m <- subset(x$matches, document_id == "manual_coord_clauses" & pattern == "t")
  expect_equal(m$start, c(1, 17)); expect_equal(m$end, c(27, 26))
  expect_equal(m$source_span, c("Maya reads, and Leo writes.", "Leo writes"))
  expect_true(all(m$span_kind == "query_matched_subtree"))
  expect_true(all(x$results$review_status == "not_reviewed"))
  for (s in x$checked[!vapply(x$checked, is.null, logical(1))]) {
    t <- s$source$tokens; text <- s$source$segments$text
    expect_equal(stringi::stri_sub(rep(text, nrow(t)), t$start, t$end), t$surface)
  }
})

test_that("ordered original rosters and complete unchanged outputs are required", {
  e <- l2sca_example(); h <- e$helper; f <- e$fixture
  import <- function(trace = f$trace, docs = f$documents) h$l2sca_import(trace, docs)
  expect_error(import(docs = f$documents[-1, ]), "complete")
  expect_error(import(docs = f$documents[rev(seq_len(nrow(f$documents))), ]), "roster")
  docs <- f$documents; docs$text[1] <- paste0(docs$text[1], " ")
  expect_error(import(docs = docs), "roster")
  docs <- f$documents; docs$document_id[2] <- docs$document_id[1]
  expect_error(import(docs = docs), "unique")
  for (field in c("parser", "queries")) {
    z <- f$trace
    if (field == "parser") z$documents[[1]]$parser$stdout <- "" else
      z$documents[[1]]$queries$c$stdout <- ""
    expect_error(import(z), "changed parser/query")
  }
  z <- f$trace; z$documents[[1]]$queries$c <- NULL
  expect_error(import(z), "six")
  z <- f$trace; z$documents[[1]]$queries <- unname(z$documents[[1]]$queries)
  expect_error(import(z), "query names")
  z <- f$trace; z$provenance$kind <- character()
  expect_error(import(z), "Declare")
  z <- f$trace; z$provenance$kind <- "l2sca-pinned"
  expect_error(import(z), "identity")
  z <- f$trace; z$documents[[1]]$status <- "parser_failed"
  expect_error(import(z), "Inconsistent")
})

test_that("incomplete trees and incompatible node IDs cannot produce numeric scores", {
  e <- l2sca_example(); h <- e$helper; f <- e$fixture
  change <- function(text, query = NULL) {
    z <- f$trace
    output <- list(exit_status = 0L, stdout = text, stderr = "authored", stdout_sha256 = h$.l2sca_text_hash(text))
    if (is.null(query)) z$documents[[1]]$parser <- output else z$documents[[1]]$queries[[query]] <- output
    h$l2sca_import(z, f$documents)
  }
  for (text in c("", "(ROOT (S (NN Maya)))", "(ROOT (X (NN Maya)))", "(ROOT (S (NN Maya))", "oops")) {
    x <- change(text)
    expect_equal(x$components$status[1], "unusable_parse")
    expect_true(all(is.na(x$results$value[1:3])))
    expect_identical(x$trace$documents[[1]]$parser$stdout, text)
  }
  for (text in c("1:2\n1:2", "1:9999", "1:6", "garbage", "")) {
    x <- change(text, "s")
    expect_equal(x$components$status[1], "unusable_parse")
  }
  x <- h$l2sca_import(f$trace, f$documents, max_nodes = 1)
  expect_true(all(is.na(x$results$value)))
  expect_match(x$components$reason[1], "max_nodes")
  z <- f$trace; z$documents[[1]]$status <- "query_failed"; z$documents[[1]]$queries$c$exit_status <- 1L
  x <- h$l2sca_import(z, f$documents)
  expect_equal(x$components$status[1], "query_failed")
  expect_true(all(is.na(x$results$value[1:3])))
  z$documents <- z$documents[11]; docs <- f$documents[11, , drop = FALSE]
  x <- h$l2sca_import(z, docs)
  expect_equal(nrow(x$matches), 0L); expect_true(is.data.frame(x$matches))
  expect_equal(nrow(x$results), 3L)
})

test_that("multiple trees and explicit PTB brackets preserve Unicode code-point spans", {
  e <- l2sca_example(); h <- e$helper; f <- e$fixture
  z <- f$trace; z$documents <- z$documents[1]
  text <- "\u00c9va (\u732b).\nLeo reads."
  penn <- "(ROOT (S (NNP \u00c9va) (-LRB- -LRB-) (NN \u732b) (-RRB- -RRB-) (. .)))\n(ROOT (S (NNP Leo) (VBZ reads) (. .)))"
  command <- function(s) list(exit_status = 0L, stdout = s, stderr = "authored", stdout_sha256 = h$.l2sca_text_hash(s))
  docs <- data.frame(document_id = "unicode", text = text)
  z$documents[[1]] <- list(document_id = "unicode", text = text, text_sha256 = h$.l2sca_text_hash(text),
    parser = command(penn), queries = lapply(list(s = "1:1\n2:1", c = "1:2\n2:2", t = "1:2\n2:2",
      dc = "", fc = "", ft = ""), command), status = "parsed")
  x <- h$l2sca_import(z, docs)
  expect_equal(unname(unlist(x$components[1, c("W", "S", "C", "T", "DC")])), c(4, 2, 2, 2, 0))
  tokens <- x$checked[[1]]$source$tokens
  expect_equal(tokens$surface, c("\u00c9va", "(", "\u732b", ")", ".", "Leo", "reads", "."))
  expect_equal(tokens$start, c(1, 5, 6, 7, 8, 10, 14, 19))
  expect_equal(tokens$surface_rule, c("exact", "PTB_bracket", "exact", "PTB_bracket", rep("exact", 4)))
  expect_equal(subset(x$matches, pattern == "s")$source_span, c("\u00c9va (\u732b).", "Leo reads."))
  # A literal escaped-looking word is preserved before bracket decoding is tried.
  expect_equal(h$.l2sca_surfaces(data.frame(parser_surface = "-LRB-"), "-LRB-")$surface_rule, "exact")
  z$documents[[1]]$parser <- command(gsub("\u00c9va", "Eva", penn, fixed = TRUE))
  expect_equal(h$l2sca_import(z, docs)$components$status, "unusable_parse")
  z$documents[[1]]$text <- "!!!"; docs$text <- "!!!"
  z$documents[[1]]$text_sha256 <- h$.l2sca_text_hash("!!!")
  z$documents[[1]]$parser <- command("(ROOT (FRAG (. !!!)))")
  z$documents[[1]]$queries <- lapply(list(s = "1:1", c = "", t = "", dc = "", fc = "1:2", ft = "1:2"), command)
  x <- h$l2sca_import(z, docs)
  expect_equal(x$components$status, "no_words")
  expect_equal(x$results$original_rule_value, c(0, 0, 0))
  expect_true(all(is.na(x$results$value)))
})

test_that("study decisions preserve observations and records survive JSON and RDS", {
  e <- l2sca_example(); h <- e$helper; x <- e$analysis
  expect_equal(nrow(e$study_long), 36)
  expect_equal(sum(e$study_long$status == "not_submitted"), 3)
  expect_equal(sum(e$study_long$status == "parser_failed"), 3)
  expect_equal(sum(e$study_long$report_status == "withheld_by_review"), 3)
  expect_true(all(is.na(subset(e$study_long, report_status != "reportable")$report_value)))
  expect_equal(nrow(e$model_data), 7)
  expect_false(anyDuplicated(e$model_data$observation_id) > 0)
  path <- tempfile(fileext = ".rds"); on.exit(unlink(path), add = TRUE)
  saveRDS(e$record, path); restored <- readRDS(path)
  expect_identical(restored, e$record); expect_silent(h$l2sca_validate(restored$analysis))
  changed <- x; changed$results$value[1] <- 99
  expect_error(h$l2sca_validate(changed), "changed")
  skip_if_not_installed("jsonlite")
  input <- tempfile(); trace <- tempfile(); on.exit(unlink(c(input, trace)), add = TRUE)
  h$l2sca_write_inputs(e$fixture$documents, input)
  expect_error(h$l2sca_write_inputs(e$fixture$documents, input), "not replaced")
  expect_equal(jsonlite::read_json(input, simplifyVector = TRUE), e$fixture$documents)
  jsonlite::write_json(e$fixture$trace, trace, auto_unbox = TRUE)
  imported <- h$l2sca_import(trace, e$fixture$documents)
  expect_equal(imported$components, x$components)
  expect_equal(imported$results$value, x$results$value)
  expect_equal(imported$matches, x$matches)
})
