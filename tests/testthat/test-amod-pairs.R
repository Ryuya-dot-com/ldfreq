amod_fixture <- function() {
  segments <- data.frame(document_id = "en", segment_id = "s1", text = "Big red birds fly.")
  data <- data.frame(document_id = "en", segment_id = "s1", token_index = 1:5,
    surface = c("Big", "red", "birds", "fly", "."), lemma = c("big", "red", "bird", "fly", "."),
    upos = c("ADJ", "ADJ", "NOUN", "VERB", "PUNCT"), head = c(3, 3, 4, 0, 4),
    deprel = c("amod", "amod", "nsubj", "root", "punct"))
  provenance <- list(language = "en", analyzer = "authored", analyzer_version = "1",
    dictionary = "none", dictionary_version = "none", unit = "syntactic-word", normalization = "none")
  list(data = data, segments = segments, provenance = provenance)
}

amod_import <- function(f) do.call(lexdiv_import_annotations, f)

test_that("amod pairs preserve non-adjacent endpoints and source context", {
  f <- amod_fixture()
  x <- lexdiv_amod_pairs(amod_import(f), unit = "lemma", context_chars = 2)
  o <- x$occurrences
  expect_identical(o$dependent_term, c("big", "red"))
  expect_identical(o$head_term, c("bird", "bird"))
  expect_identical(o$dependent_start, c(1L, 5L))
  expect_identical(o$dependent_end, c(3L, 7L))
  expect_identical(o$head_start, c(9L, 9L))
  expect_identical(o$head_end, c(13L, 13L))
  expect_identical(o$keyword, c("Big red birds", "red birds"))
  expect_identical(o$pre, c("", "g "))
  expect_identical(o$post, c(" f", " f"))
  expect_equal(o$token_distance, c(2, 1))
  expect_identical(o$direction, rep("dependent_before_head", 2))
  expect_equal(x$counts$n, c(1, 1))
  expect_equal(x$summary$pairs, 2)
  expect_equal(x$summary$types, 2)
  expect_equal(x$summary$token_coverage, 1)
  expect_identical(x$annotations, amod_import(f))
  surface <- lexdiv_amod_pairs(amod_import(f), context_chars = 0)
  expect_identical(surface$occurrences$dependent_term, c("Big", "red"))
  expect_identical(surface$occurrences$head_term, c("birds", "birds"))
  expect_identical(surface$occurrences$pre, rep("", 2))
  expect_identical(surface$occurrences$post, rep("", 2))
})

test_that("the declared ADJ to NOUN feature includes subtypes but not other heads", {
  f <- amod_fixture()
  f$data$deprel[1] <- "amod:att"
  expect_equal(nrow(lexdiv_amod_pairs(amod_import(f))$occurrences), 2)
  for (tag in c("PROPN", "PRON", "VERB")) {
    f$data$upos[3] <- tag
    x <- lexdiv_amod_pairs(amod_import(f))
    expect_equal(x$summary$pairs, 0)
    expect_identical(x$occurrences$direction, character())
  }
  f <- amod_fixture()
  f$data$upos[1] <- "NOUN"
  expect_equal(lexdiv_amod_pairs(amod_import(f))$occurrences$dependent_token_index, 2)
  f$data$head <- c(0, 1, 1, 1, 1)
  f$data$deprel <- c("root", "amod", "dep", "dep", "punct")
  x <- lexdiv_amod_pairs(amod_import(f))
  expect_identical(x$occurrences$direction, "dependent_after_head")
  expect_identical(x$occurrences$keyword, "Big red")
})

test_that("missing units affect types, not syntactic detection; no silent fallback", {
  f <- amod_fixture()
  f$data$lemma[1] <- NA_character_
  x <- lexdiv_amod_pairs(amod_import(f), unit = "lemma")
  expect_equal(x$summary$pairs, 2)
  expect_equal(x$summary$pairs_with_unit, 1)
  expect_equal(x$summary$observed_types, 1)
  expect_true(is.na(x$summary$types))
  expect_identical(x$occurrences$unit_available, c(FALSE, TRUE))
  expect_equal(sum(x$counts$n), 1)
  expect_equal(lexdiv_amod_pairs(amod_import(f))$summary$types, 2)
  f$data$lemma[] <- "same"
  x <- lexdiv_amod_pairs(amod_import(f), unit = "lemma")
  expect_equal(x$summary$types, 1)
  expect_equal(x$counts$n, 2)
})

test_that("missing heads, relations or POS exclude the entire sentence", {
  for (field in c("head", "deprel", "upos")) {
    f <- amod_fixture()
    f$data[[field]][5] <- NA
    x <- lexdiv_amod_pairs(amod_import(f))
    expect_identical(x$segments$status, "incomplete_annotation")
    expect_equal(x$summary$observed_pairs, 0)
    expect_true(is.na(x$summary$pairs))
    expect_true(is.na(x$summary$types))
    expect_equal(x$summary$token_coverage, 0)
    expect_equal(nrow(x$occurrences), 0)
  }
})

test_that("tree contradictions are rejected, including incomplete annotations", {
  f <- amod_fixture()
  bad_head <- list(c(1, 3, 4, 0, 4), c(6, 3, 4, 0, 4), c(2, 1, 4, 0, 4),
    c(0, 3, 4, 0, 4), c(2, 3, 4, 3, 4), c(2, 1, NA, 0, 4))
  for (head in bad_head) {
    f$data$head <- head
    expect_error(lexdiv_amod_pairs(amod_import(f)), "same sentence|cycle|root")
  }
  f <- amod_fixture()
  f$data$deprel[1] <- "root"
  expect_error(lexdiv_amod_pairs(amod_import(f)), "root")
  f$data$head[1] <- NA_real_
  expect_error(lexdiv_amod_pairs(amod_import(f)), "root")
})

test_that("tree acceptance agrees with an independent three-node reachability oracle", {
  f <- amod_fixture()
  f$segments$text <- "a b c"
  f$data <- f$data[1:3, ]
  f$data$surface <- c("a", "b", "c")
  f$data$upos[] <- "NOUN"
  possibilities <- expand.grid(h1 = c(0, 2, 3), h2 = c(0, 1, 3), h3 = c(0, 1, 2))
  expected <- actual <- logical(nrow(possibilities))
  for (i in seq_len(nrow(possibilities))) {
    h <- as.numeric(possibilities[i, ])
    adjacency <- matrix(0, 3, 3)
    idx <- which(h > 0)
    adjacency[cbind(idx, h[idx])] <- 1
    reach <- adjacency + adjacency %*% adjacency + adjacency %*% adjacency %*% adjacency
    expected[i] <- sum(h == 0) == 1 && all(diag(reach) == 0)
    f$data$head <- h
    f$data$deprel <- ifelse(h == 0, "root", "dep")
    actual[i] <- !inherits(try(lexdiv_amod_pairs(amod_import(f)), silent = TRUE), "try-error")
  }
  expect_identical(actual, expected)
})

test_that("input boundaries reject malformed fields, enhanced edges and altered imports", {
  f <- amod_fixture()
  x <- amod_import(f)
  x$tokens$head[1] <- 4
  expect_error(lexdiv_amod_pairs(x), "changed")
  for (value in list(c(3.5, 3, 4, 0, 4), c(Inf, 3, 4, 0, 4), c(-1, 3, 4, 0, 4),
                    c(NaN, 3, 4, 0, 4), as.character(f$data$head))) {
    g <- f
    g$data$head <- value
    expect_error(lexdiv_amod_pairs(amod_import(g)), "head")
  }
  for (field in c("head", "deprel", "upos")) {
    g <- f
    g$data[[field]] <- NULL
    expect_error(lexdiv_amod_pairs(amod_import(g)), "require")
  }
  for (value in c("_", "amdo", "amod:", "ROOT", "root:sub", " ")) {
    g <- f
    g$data$deprel[1] <- value
    expect_error(lexdiv_amod_pairs(amod_import(g)), "deprel")
  }
  g <- f
  g$data$upos[1] <- "JJ"
  expect_error(lexdiv_amod_pairs(amod_import(g)), "UD tags")
  for (field in c("deps", "DEPS")) {
    g <- f
    g$data[[field]] <- "3:amod"
    expect_error(lexdiv_amod_pairs(amod_import(g)), "Enhanced")
    g$data[[field]][] <- "_"
    expect_equal(lexdiv_amod_pairs(amod_import(g))$summary$pairs, 2)
  }
  expect_error(lexdiv_amod_pairs(amod_import(f), unit = "flemma"), "arg")
  expect_error(lexdiv_amod_pairs(amod_import(f), context_chars = -1), "context_chars")
  expect_error(lexdiv_amod_pairs(amod_import(f), max_tokens = 4), "max_tokens")
  f$data$token_index <- c("1-2", "2", "3", "4", "5")
  expect_error(amod_import(f), "token_index")
})

test_that("Unicode source positions, empty inputs and compound IDs remain exact", {
  f <- amod_fixture()
  first <- intToUtf8(c(0x304b, 0x3099))
  emoji <- intToUtf8(0x1f600)
  f$segments$text <- paste0(first, "猫", emoji)
  f$data <- f$data[1:3, ]
  f$data$surface <- c(first, "猫", emoji)
  f$data$upos <- c("ADJ", "NOUN", "SYM")
  f$data$head <- c(2, 0, 2)
  f$data$deprel <- c("amod", "root", "dep")
  x <- lexdiv_amod_pairs(amod_import(f), context_chars = 1)
  expect_equal(x$occurrences$dependent_end, 2)
  expect_equal(x$occurrences$head_start, 3)
  expect_identical(x$occurrences$keyword, paste0(first, "猫"))
  expect_identical(x$occurrences$post, emoji)
  f$data <- f$data[FALSE, ]
  f$segments$text <- ""
  x <- lexdiv_amod_pairs(amod_import(f))
  expect_identical(x$documents$status, "empty")
  expect_equal(x$documents$pairs, 0)
  expect_equal(x$documents$types, 0)
  expect_true(is.na(x$documents$token_coverage))
  expect_identical(x$occurrences$dependent_term, character())
  expect_equal(nrow(x$counts), 0)
  f <- amod_fixture()
  f$data <- rbind(f$data, f$data)
  f$segments <- rbind(f$segments, f$segments)
  f$segments$document_id <- c("a:b", "a")
  f$segments$segment_id <- c("c", "b:c")
  f$data$document_id <- rep(f$segments$document_id, each = 5)
  f$data$segment_id <- rep(f$segments$segment_id, each = 5)
  x <- lexdiv_amod_pairs(amod_import(f))
  expect_equal(x$documents$pairs, c(2, 2))
  expect_equal(x$counts$n, c(2, 2))
  expect_equal(x$summary$types, 2)
})

test_that("installed example detects wrong pairs at equal counts and replays after save", {
  env <- new.env(parent = baseenv())
  sys.source(system.file("examples", "amod-pairs.R", package = "ldfreq", mustWork = TRUE), env)
  x <- env$amod_pairs_example
  d <- x$differences
  expect_identical(d$document_id, c("english", "wrong_head", "japanese", "zero", "unavailable", "partial", "empty"))
  expect_equal(d$reference_pairs, c(2, 2, 1, 0, 1, 2, 0))
  expect_equal(d$predicted_pairs, c(1, 2, 0, 0, NA, NA, 0))
  expect_equal(d$delta_pairs, c(-1, 0, -1, 0, NA, NA, 0))
  expect_equal(d$tp, c(1, 1, 0, 0, NA, NA, 0))
  expect_equal(d$fp, c(0, 1, 0, 0, NA, NA, 0))
  expect_equal(d$fn, c(1, 1, 1, 0, NA, NA, 0))
  expect_equal(d$predicted_coverage, c(1, 1, 1, 1, 0, .5, NA))
  expect_equal(x$predicted$documents$observed_pairs, c(1, 2, 0, 0, 0, 1, 0))
  expect_identical(subset(x$reference$occurrences, document_id == "japanese")$keyword, "赤い鳥")
  path <- tempfile(fileext = ".rds")
  on.exit(unlink(path))
  saveRDS(x, path)
  saved <- readRDS(path)
  for (side in c("predicted", "reference"))
    expect_identical(lexdiv_amod_pairs(saved$inputs[[side]], unit = saved$inputs$unit), x[[side]])
  expect_false(any(x$comparison$outcome %in% c("fp", "fn") & !x$comparison$evaluated))
})
