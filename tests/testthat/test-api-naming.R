test_that("the v1.0.0 API exposes one canonical vocabulary without retired aliases", {
  exports <- getNamespaceExports("ldfreq")
  canonical <- c(
    "nj8_profile",
    "nj8_profile_batch",
    "tubelex_profile",
    "tubelex_profile_batch",
    "lexdiv_overlap_ids",
    "lexdiv_compare_ngrams",
    "lexdiv_build_ngram_reference",
    "lexdiv_sort_concordance",
    "lexdiv_screen_lengths",
    "lexdiv_norm_spec",
    "lexdiv_resource_meta",
    "lexdiv_lemmatize_batch",
    "lexdiv_flemmatize_batch",
    "lexdiv_as_annotations"
  )
  retired <- c(
    "new_jacet8000_profile",
    "new_jacet8000_profile_batch",
    "tubelex_frequency_profile",
    "lexdiv_overlap_measure_ids",
    "lexdiv_ngram_compare",
    "lexdiv_ngram_reference_build",
    "lexdiv_concordance_sort",
    "lexdiv_screen",
    "lexdiv_variant_ids",
    "lexdiv_profile",
    "lexdiv_profile_batch"
  )

  expect_true(all(canonical %in% exports))
  expect_true("lexdiv_mattr_profile" %in% exports)
  expect_false(any(retired %in% exports))
  expect_false(any(startsWith(exports, "new_")))
})

test_that("general exported names remain bounded and catalog names are regular", {
  exports <- getNamespaceExports("ldfreq")
  general <- exports[startsWith(exports, "lexdiv_")]
  semantic_words <- lengths(strsplit(
    sub("^lexdiv_", "", general),
    "_",
    fixed = TRUE
  ))

  expect_true(all(grepl("^[a-z][a-z0-9_]*$", exports)))
  expect_lte(max(semantic_words), 3L)
  expect_true(all(c(
    "lexdiv_metric_ids",
    "lexdiv_overlap_ids",
    "lexdiv_methods"
  ) %in% exports))
})

test_that("renamed resource classes and methods use canonical names", {
  levels <- data.frame(
    NJ8 = c(1L, 1001L),
    Word = c("the", "cat"),
    stringsAsFactors = FALSE
  )
  profile <- nj8_profile(c("the", "unknown"), levels, unit = "surface")

  expect_s3_class(profile, "nj8_profile")
  expect_false(inherits(profile, "new_jacet8000_profile"))
  expect_true(is.function(getS3method(
    "print",
    "nj8_profile_batch",
    optional = TRUE
  )))
  expect_true(is.function(getS3method(
    "plot",
    "tubelex_profile",
    optional = TRUE
  )))
  expect_true(is.function(getS3method(
    "plot",
    "tubelex_profile_batch",
    optional = TRUE
  )))
  expect_null(getS3method("plot", "tubelex_frequency_profile", optional = TRUE))
  expect_true(is.function(getS3method(
    "print", "lexdiv_mattr_profile", optional = TRUE
  )))
  expect_true(is.function(getS3method(
    "plot", "lexdiv_mattr_profile", optional = TRUE
  )))
  expect_null(getS3method("summary", "lexdiv_mattr_profile", optional = TRUE))
})
