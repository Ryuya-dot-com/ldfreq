# Dictionary identity is independent of labels, row order, and storage class.
dictionary_annotate <- function(dictionary, text = "Cats RUN unknown", ...) {
  lexdiv_lemmatize(lexdiv_tokenize(text), method = "textstem",
    dictionary = dictionary, dictionary_id = "fixture", dictionary_version = "1", ...)
}

test_that("explicit dictionaries determine lookup and survive saved reruns", {
  skip_if_not_installed("textstem")
  dict <- data.frame(word = c("cats", "run"), base = c("cat", "run"))
  x <- dictionary_annotate(dict)
  expect_identical(x$tokens$lemma, c("cat", "run", "unknown"))
  expect_identical(x$tokens$lemma,
    unname(textstem::lemmatize_words(x$tokens$surface, dictionary = dict)))
  record <- x$provenance$annotation$dictionary
  expect_identical(record$source, "supplied")
  expect_identical(record$entries, 2)
  expect_identical(record$query_locale, Sys.getlocale("LC_CTYPE"))
  expect_identical(record$unknown_form_policy, "surface")
  expect_match(record$sha256, "^[0-9a-f]{64}$")
  reordered <- dict[2:1, ]; names(reordered) <- c("x", "y")
  expect_identical(dictionary_annotate(reordered)$provenance$annotation$dictionary, record)
  changed <- dict; changed$base[1] <- "feline"
  expect_false(identical(dictionary_annotate(changed)$provenance$annotation$dictionary$sha256,
    record$sha256))
  saved <- tempfile(fileext = ".rds"); on.exit(unlink(saved))
  saveRDS(list(dictionary = dict, prepared = x), saved)
  restored <- readRDS(saved)
  replay <- dictionary_annotate(restored$dictionary)
  expect_identical(restored$prepared, replay)
  expect_identical(dictionary_annotate(dict, text = "")$tokens$lemma, character())
  empty <- dict[FALSE, ]
  expect_identical(dictionary_annotate(empty)$tokens$lemma, c("Cats", "RUN", "unknown"))
  expect_identical(dictionary_annotate(empty)$provenance$annotation$dictionary$entries, 0)
  expect_identical(lexdiv_metrics_text(x, unit = "lemma", metrics = "ttr")$results$value, 1)
})

test_that("dictionary fingerprints use unambiguous UTF-8 byte lengths", {
  # Independently construct the normative payload, including non-ASCII bytes.
  dict <- data.frame(term = c("z", "\u00e9"), lemma = c("a:b\nc", "e"))
  hash <- ldfreq:::.lexprep_dictionary_fingerprint(dict)
  payload <- paste0("sha256-utf8-byte-length-pairs-v1:2:1:z5:a:b\nc2:\u00e91:e")
  expect_identical(hash, digest::digest(charToRaw(enc2utf8(payload)),
    algo = "sha256", serialize = FALSE))
  expect_identical(ldfreq:::.lexprep_dictionary_fingerprint(dict[FALSE, ]),
    digest::digest(charToRaw("sha256-utf8-byte-length-pairs-v1:0:"),
      algo = "sha256", serialize = FALSE))
  expect_false(identical(
    ldfreq:::.lexprep_dictionary_fingerprint(data.frame(term = "ab", lemma = "c")),
    ldfreq:::.lexprep_dictionary_fingerprint(data.frame(term = "a", lemma = "bc"))))
})

test_that("the default dictionary records its actual content and package version", {
  skip_if_not_installed("textstem")
  skip_if_not_installed("lexicon")
  base <- lexdiv_tokenize("Students have jobs second third fourth", case = "lower")
  x <- lexdiv_lemmatize(base, method = "textstem")
  expect_identical(x$tokens$lemma, unname(textstem::lemmatize_words(base$tokens$surface)))
  record <- x$provenance$annotation$dictionary
  expect_identical(record$source, "lexicon")
  expect_identical(record$id, "lexicon::hash_lemmas")
  expect_identical(record$version, as.character(utils::packageVersion("lexicon")))
  expect_identical(record$entries, as.double(nrow(lexicon::hash_lemmas)))
  explicit <- dictionary_annotate(as.data.frame(lexicon::hash_lemmas))
  expect_identical(explicit$provenance$annotation$dictionary$sha256, record$sha256)
})

test_that("invalid dictionary inputs and contradictory arguments fail explicitly", {
  skip_if_not_installed("textstem")
  dict <- data.frame(term = "cats", lemma = "cat")
  invalid <- list(as.matrix(dict), dict[1], cbind(dict, extra = "x"),
    data.frame(term = factor("cats"), lemma = "cat"),
    data.frame(term = NA_character_, lemma = "cat"),
    data.frame(term = "cats", lemma = ""),
    data.frame(term = "cats", lemma = NA_character_),
    data.frame(term = "Cats", lemma = "cat"), rbind(dict, dict),
    data.frame(term = "cats", lemma = I("cat")))
  for (bad in invalid) expect_error(dictionary_annotate(bad), "dictionary")
  x <- lexdiv_tokenize("cats")
  expect_error(lexdiv_lemmatize(x, method = "textstem", dictionary = dict), "dictionary_id")
  expect_error(lexdiv_lemmatize(x, method = "textstem", dictionary = dict,
    dictionary_id = "fixture"), "dictionary_version")
  expect_error(lexdiv_lemmatize(x, method = "textstem", dictionary_id = "fixture"),
    "default dictionary")
  expect_error(lexdiv_lemmatize(x, method = "textstem", dictionary = dict,
    dictionary_id = "/private/dict", dictionary_version = "1"), "path-free")
  for (args in list(list(dictionary = dict), list(dictionary_id = "fixture"),
      list(dictionary_version = "1"))) {
    expect_error(do.call(lexdiv_lemmatize, c(list(x = x, lemmas = "cat",
      backend_id = "fixture", backend_version = "1"), args)), "require method")
  }
})

test_that("new dictionary provenance is validated while legacy objects stay readable", {
  skip_if_not_installed("textstem")
  x <- dictionary_annotate(data.frame(term = "cats", lemma = "cat"))
  invalid <- list(source = "guessed", id = "/private/dict", version = "",
    sha256 = "bad", hash_method = "unknown", entries = -1,
    query_casefold = "unknown", query_locale = NA_character_, unknown_form_policy = "drop")
  for (field in names(invalid)) {
    bad <- x; bad$provenance$annotation$dictionary[[field]] <- invalid[[field]]
    expect_error(lexdiv_metrics_text(bad, metrics = "ttr"), "annotation layer")
  }
  absent <- x; absent$provenance$annotation$dictionary <- NULL
  expect_error(lexdiv_metrics_text(absent, metrics = "ttr"), "annotation layer")
  for (version in c("0.2.0", "0.3.0")) {
    legacy <- absent; legacy$provenance$contract_version <- version
    expect_no_error(lexdiv_metrics_text(legacy, unit = "lemma", metrics = "ttr"))
    updated <- lexdiv_lemmatize(legacy, method = "textstem")
    expect_identical(updated$provenance$contract_version, "0.4.0")
    expect_true(is.list(updated$provenance$annotation$dictionary))
  }
  legacy_english <- lexdiv_tokenize("cats", tokenizer = "english")
  legacy_english$provenance$contract_version <- "0.3.0"
  expect_no_error(lexdiv_metrics_text(legacy_english, metrics = "ttr"))
})

test_that("strict overlap distinguishes dictionary contents and missing legacy evidence", {
  skip_if_not_installed("textstem")
  dict <- data.frame(term = c("cats", "run"), lemma = c("cat", "run"))
  make <- function(d) dictionary_annotate(d, text = "Cats run", upos = c("NOUN", "VERB"),
    upos_backend_id = "fixture-pos", upos_backend_version = "1")
  x <- make(dict); same <- make(dict[2:1, ])
  expect_true(all(lexdiv_content_overlap(x, same)$comparability$matches))
  # Even an unused mapping change must be detected independently of output labels.
  different <- make(rbind(dict, data.frame(term = "extra", lemma = "extra")))
  expect_identical(x$tokens$lemma, different$tokens$lemma)
  expect_error(lexdiv_content_overlap(x, different), "dictionary_sha256")
  expect_warning(lexdiv_content_overlap(x, different, mismatch = "warn"), "dictionary_sha256")
  expect_false(all(lexdiv_content_overlap(x, different, mismatch = "allow")$comparability$matches))
  legacy <- x; legacy$provenance$contract_version <- "0.3.0"
  legacy$provenance$annotation$dictionary <- NULL
  expect_error(lexdiv_content_overlap(legacy, legacy), "dictionary_sha256")
  expect_no_error(lexdiv_content_overlap(legacy, legacy, unit = "surface"))
  locale <- x; locale$provenance$annotation$dictionary$query_locale <- "other-locale"
  expect_error(lexdiv_content_overlap(x, locale), "dictionary_query_locale")
  audit <- lexdiv_compare_annotations(x, different)
  expect_equal(nrow(audit$changes), 0)
  expect_false(identical(audit$provenance, lexdiv_compare_annotations(x, x)$provenance))
})
